import 'dart:convert';

import 'update_http.dart';
import 'update_models.dart';
import 'version_compare.dart';

/// Result of the raw GitHub query, before device-specific selection.
class ReleaseLookup {
  const ReleaseLookup({this.notModified = false, this.release, this.etag});
  final bool notModified;
  final Map<String, dynamic>? release;
  final String? etag;
}

/// Reads `releases/latest`, which by GitHub's definition never returns drafts
/// or pre-releases. Uses ETags so unchanged answers do not count against the
/// unauthenticated 60 requests/hour limit.
class GitHubReleaseClient {
  GitHubReleaseClient(
    this.http, {
    this.owner = kUpdateRepoOwner,
    this.repo = kUpdateRepoName,
  });

  final UpdateHttp http;
  final String owner;
  final String repo;

  Uri get latestUri =>
      Uri.https('api.github.com', '/repos/$owner/$repo/releases/latest');

  Future<ReleaseLookup> fetchLatest({String? etag}) async {
    final res = await http.getText(
      latestUri,
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        if (etag != null && etag.isNotEmpty) 'If-None-Match': etag,
      },
    );
    if (res.statusCode == 304) {
      return ReleaseLookup(notModified: true, etag: etag);
    }
    if (res.statusCode == 404) {
      // No stable release published yet.
      return const ReleaseLookup();
    }
    if (res.statusCode == 403 || res.statusCode == 429) {
      throw const UpdateException(
        'GitHub-API-Limit erreicht. Später erneut versuchen.',
      );
    }
    if (res.statusCode != 200) {
      throw UpdateException('GitHub antwortet mit Status ${res.statusCode}.');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw const UpdateException('Ungültige GitHub-Antwort.');
    }
    return ReleaseLookup(release: decoded, etag: res.headers['etag']);
  }

  Future<Map<String, dynamic>?> fetchMetadata(Uri url) async {
    final res = await http.getText(url, maxBytes: 64 * 1024);
    if (res.statusCode != 200) {
      throw UpdateException(
        'Update-Metadaten nicht lesbar (${res.statusCode}).',
      );
    }
    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }
}

final _sha256Re = RegExp(r'^[0-9a-f]{64}$');
final _apkNameRe = RegExp(
  r'^TECH-DECK-(\d+\.\d+\.\d+)\+(\d+)(?:-([a-z0-9_-]+))?\.apk$',
);

String? _digestOf(Map<String, dynamic> asset) {
  final d = asset['digest'];
  if (d is String && d.startsWith('sha256:')) {
    final hex = d.substring(7).toLowerCase();
    if (_sha256Re.hasMatch(hex)) return hex;
  }
  return null;
}

/// Turns a GitHub release (+ optional metadata JSON) into a validated
/// [UpdateInfo] for this device, or explains why not.
///
/// Throws [UpdateException] for malformed/manipulated data. Returns null when
/// the release is simply not newer / not suitable.
UpdateInfo? selectUpdate({
  required Map<String, dynamic> release,
  required Map<String, dynamic>? metadata,
  required InstalledApp installed,
}) {
  if (release['draft'] == true || release['prerelease'] == true) return null;
  final tag = release['tag_name'];
  if (tag is! String) throw const UpdateException('Release ohne Tag.');
  final tagVersion = SemVer.tryParse(tag);
  if (tagVersion == null) throw UpdateException('Unbekanntes Tag-Format: $tag');

  final rawAssets = release['assets'];
  final assets = <String, Map<String, dynamic>>{
    if (rawAssets is List)
      for (final a in rawAssets.whereType<Map<String, dynamic>>())
        if (a['name'] is String) a['name'] as String: a,
  };

  String versionName;
  int versionCode;
  int minSdk;
  List<String> certs;
  final candidates = <UpdateApk>[];

  if (metadata != null) {
    if (metadata['schema'] != 1) {
      throw const UpdateException('Unbekanntes Metadaten-Schema.');
    }
    if (metadata['packageName'] != installed.packageName) {
      throw const UpdateException('Falsche Paketkennung in den Metadaten.');
    }
    final vn = metadata['versionName'];
    final vc = metadata['versionCode'];
    final ms = metadata['minSdk'];
    if (vn is! String || vc is! int || ms is! int) {
      throw const UpdateException('Unvollständige Metadaten.');
    }
    if (SemVer.tryParse(vn)?.compareTo(tagVersion) != 0) {
      throw const UpdateException(
        'Tag und Metadaten-Version widersprechen sich.',
      );
    }
    versionName = vn;
    versionCode = vc;
    minSdk = ms;
    certs = [
      for (final c in (metadata['signingCertSha256'] as List? ?? const []))
        if (c is String && _sha256Re.hasMatch(c.toLowerCase())) c.toLowerCase(),
    ];
    for (final m
        in (metadata['apks'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()) {
      final name = m['name'];
      final sha = (m['sha256'] as String?)?.toLowerCase();
      final size = m['size'];
      if (name is! String ||
          sha == null ||
          !_sha256Re.hasMatch(sha) ||
          size is! int) {
        throw const UpdateException(
          'Fehlerhafter APK-Eintrag in den Metadaten.',
        );
      }
      final asset = assets[name];
      if (asset == null) continue;
      if (asset['size'] != size) {
        throw UpdateException('Größe von $name passt nicht.');
      }
      final ghDigest = _digestOf(asset);
      if (ghDigest != null && ghDigest != sha) {
        throw UpdateException('Prüfsumme von $name widerspricht GitHub.');
      }
      final url = Uri.tryParse('${asset['browser_download_url']}');
      if (url == null || !isTrustedUpdateUri(url)) {
        throw UpdateException('Unsichere Download-URL für $name.');
      }
      candidates.add(
        UpdateApk(
          name: name,
          url: url,
          size: size,
          sha256: sha,
          abis: [
            for (final a in (m['abis'] as List? ?? const []))
              if (a is String) a,
          ],
        ),
      );
    }
  } else {
    // Legacy release without metadata (e.g. v.1.7.11): rely on GitHub's own
    // asset digest; version from the asset name is only provisional and is
    // re-checked against the real APK manifest after the download.
    versionName = tagVersion.toString();
    versionCode = -1;
    minSdk = 0;
    certs = const [];
    for (final entry in assets.entries) {
      final m = _apkNameRe.firstMatch(entry.key);
      if (m == null) continue;
      final sha = _digestOf(entry.value);
      final size = entry.value['size'];
      final url = Uri.tryParse('${entry.value['browser_download_url']}');
      if (sha == null ||
          size is! int ||
          url == null ||
          !isTrustedUpdateUri(url)) {
        continue;
      }
      if (SemVer.tryParse(m.group(1))?.compareTo(tagVersion) != 0) continue;
      versionCode = int.parse(m.group(2)!);
      candidates.add(
        UpdateApk(
          name: entry.key,
          url: url,
          size: size,
          sha256: sha,
          abis: m.group(3) == null
              ? const []
              : [m.group(3)!.replaceAll('_', '-')],
        ),
      );
    }
    if (candidates.isEmpty) return null;
  }

  if (!isNewerRelease(
    installedName: installed.versionName,
    installedCode: installed.versionCode,
    candidateName: versionName,
    candidateCode: versionCode,
  )) {
    return null;
  }
  if (minSdk > installed.sdkInt) return null;
  if (certs.isNotEmpty &&
      installed.signingCertSha256.isNotEmpty &&
      !certs.any(installed.signingCertSha256.contains)) {
    throw const UpdateException(
      'Release ist mit einem anderen Schlüssel signiert und kann diese Installation nicht ersetzen.',
    );
  }

  final apk = pickApkForDevice(candidates, installed.abis);
  if (apk == null) return null;

  final body = release['body'];
  return UpdateInfo(
    tag: tag,
    versionName: versionName,
    versionCode: versionCode,
    minSdk: minSdk,
    releaseNotes: sanitizeReleaseNotes(body is String ? body : ''),
    apk: apk,
    signingCertSha256: certs,
    htmlUrl: Uri.tryParse('${release['html_url']}'),
  );
}

/// Prefers the ABI split matching the device's primary ABI, then any supported
/// ABI, then a universal APK.
UpdateApk? pickApkForDevice(List<UpdateApk> apks, List<String> deviceAbis) {
  for (final abi in deviceAbis) {
    for (final apk in apks) {
      if (apk.abis.length == 1 && apk.abis.first == abi) return apk;
    }
  }
  for (final apk in apks) {
    if (apk.abis.isEmpty) return apk;
    if (apk.abis.length > 1 && apk.abis.any(deviceAbis.contains)) return apk;
  }
  return null;
}

/// Release notes are shown as plain text only: markdown/HTML markers and
/// control characters are stripped, length is bounded.
String sanitizeReleaseNotes(String raw) {
  var s = raw.replaceAll(RegExp(r'<[^>]*>'), '');
  s = s.replaceAll(
    RegExp(
      r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F\u202A-\u202E\u2066-\u2069]',
    ),
    '',
  );
  s = s.replaceAllMapped(
    RegExp(r'!?\[([^\]]*)\]\([^)]*\)'),
    (m) => m.group(1)!,
  );
  s = s.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
  s = s.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '• ');
  s = s.replaceAll(RegExp(r'[*_`]{1,3}'), '');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  if (s.length > 1500) s = '${s.substring(0, 1500).trimRight()} …';
  return s;
}
