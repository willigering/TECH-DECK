import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'apk_downloader.dart';
import 'github_release_client.dart';
import 'update_http.dart';
import 'update_models.dart';
import 'update_platform.dart';

enum UpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  verifying,
  installing,
  error,
}

/// Coordinates checking, downloading and installing. Every failure ends in
/// [UpdatePhase.error] with a message; nothing here may throw into the UI.
class UpdateController extends ChangeNotifier {
  UpdateController({
    UpdatePlatform? platform,
    this._http,
    DateTime Function()? clock,
  }) : platform = platform ?? MethodChannelUpdatePlatform(),
       _clock = clock ?? DateTime.now;

  static const kAutoCheck = 'update_auto_check';
  static const kWifiOnly = 'update_wifi_only';
  static const kLastSuccess = 'update_last_success_ms';
  static const kLastAttempt = 'update_last_attempt_ms';
  static const kEtag = 'update_latest_etag';
  static const kCachedRelease = 'update_latest_release_json';
  static const kCachedMetadata = 'update_latest_metadata_json';
  static const autoInterval = Duration(hours: 24);
  static const failedRetryInterval = Duration(hours: 6);

  final UpdatePlatform platform;
  final DateTime Function() _clock;
  UpdateHttp? _http;
  UpdateHttp get http => _http ??= IoUpdateHttp();

  bool autoCheck = true;
  bool wifiOnly = true;
  DateTime? lastSuccess;
  InstalledApp? installed;
  UpdatePhase phase = UpdatePhase.idle;
  UpdateInfo? update;
  String? message;
  int received = 0;
  int total = 0;
  bool _loaded = false;
  bool _busy = false;
  CancelToken? _cancel;
  StreamSubscription<(InstallEvent, String?)>? _installSub;

  /// Set when an automatic check found something the user has not seen yet.
  bool promptPending = false;

  bool get isSupported => platform.isSupported;
  double get progress => total <= 0 ? 0 : received / total;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      autoCheck = p.getBool(kAutoCheck) ?? true;
      wifiOnly = p.getBool(kWifiOnly) ?? true;
      final ms = p.getInt(kLastSuccess);
      lastSuccess = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      if (platform.isSupported) {
        installed = await platform.installedApp();
        _installSub ??= platform.installEvents.listen(_onInstallEvent);
      }
    } catch (_) {
      // Updater stays inert; the app is unaffected.
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setAutoCheck(bool v) async {
    autoCheck = v;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(kAutoCheck, v);
  }

  Future<void> setWifiOnly(bool v) async {
    wifiOnly = v;
    notifyListeners();
    await (await SharedPreferences.getInstance()).setBool(kWifiOnly, v);
  }

  /// Called once after start. Never blocks the UI; at most once per 24 h.
  Future<void> autoCheckOnStart() async {
    try {
      if (!_loaded) await load();
      if (!autoCheck || !isSupported || installed == null) return;
      final p = await SharedPreferences.getInstance();
      final now = _clock();
      final lastOk = p.getInt(kLastSuccess);
      final lastTry = p.getInt(kLastAttempt);
      if (lastOk != null &&
          now.difference(DateTime.fromMillisecondsSinceEpoch(lastOk)) <
              autoInterval) {
        return;
      }
      if (lastTry != null &&
          now.difference(DateTime.fromMillisecondsSinceEpoch(lastTry)) <
              failedRetryInterval) {
        return;
      }
      if (await platform.networkKind() == NetworkKind.none) return;
      final r = await checkNow(manual: false);
      if (r.outcome == CheckOutcome.updateAvailable) {
        promptPending = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Manual or automatic check. Always returns a result, never throws.
  Future<CheckResult> checkNow({bool manual = true}) async {
    if (_busy) return const CheckResult(CheckOutcome.skipped);
    _busy = true;
    if (!_loaded) await load();
    phase = UpdatePhase.checking;
    message = null;
    notifyListeners();
    try {
      if (!isSupported) {
        return _finish(
          const CheckResult(
            CheckOutcome.skipped,
            message: 'Updates sind nur unter Android verfügbar.',
          ),
        );
      }
      final inst = installed ?? await platform.installedApp();
      installed = inst;
      if (inst == null) {
        throw const UpdateException('Installierte Version unbekannt.');
      }
      if (await platform.networkKind() == NetworkKind.none) {
        throw const UpdateException('Keine Internetverbindung.');
      }
      final p = await SharedPreferences.getInstance();
      await p.setInt(kLastAttempt, _clock().millisecondsSinceEpoch);
      final client = GitHubReleaseClient(http);
      final cachedJson = p.getString(kCachedRelease);
      final lookup = await client.fetchLatest(
        etag: cachedJson == null ? null : p.getString(kEtag),
      );
      Map<String, dynamic>? release;
      Map<String, dynamic>? metadata;
      if (lookup.notModified && cachedJson != null) {
        release = jsonDecode(cachedJson) as Map<String, dynamic>;
        final m = p.getString(kCachedMetadata);
        metadata = m == null ? null : jsonDecode(m) as Map<String, dynamic>;
      } else if (lookup.release != null) {
        release = lookup.release;
        metadata = await _metadataFor(client, release!);
        await p.setString(kCachedRelease, jsonEncode(release));
        if (metadata != null) {
          await p.setString(kCachedMetadata, jsonEncode(metadata));
        } else {
          await p.remove(kCachedMetadata);
        }
        if (lookup.etag != null) await p.setString(kEtag, lookup.etag!);
      }
      UpdateInfo? found;
      if (release != null) {
        found = selectUpdate(
          release: release,
          metadata: metadata,
          installed: inst,
        );
      }
      final now = _clock();
      lastSuccess = now;
      await p.setInt(kLastSuccess, now.millisecondsSinceEpoch);
      if (found == null) {
        update = null;
        return _finish(
          const CheckResult(
            CheckOutcome.upToDate,
            message: 'SYSTEM UP TO DATE – Ausnahmsweise mal nichts kaputt.',
          ),
        );
      }
      update = found;
      return _finish(CheckResult(CheckOutcome.updateAvailable, update: found));
    } on UpdateException catch (e) {
      return _finish(CheckResult(CheckOutcome.failed, message: e.message));
    } catch (_) {
      return _finish(
        const CheckResult(
          CheckOutcome.failed,
          message:
              'Updateprüfung fehlgeschlagen. GitHub ist gerade nicht erreichbar.',
        ),
      );
    } finally {
      _busy = false;
    }
  }

  Future<Map<String, dynamic>?> _metadataFor(
    GitHubReleaseClient client,
    Map<String, dynamic> release,
  ) async {
    final assets = release['assets'];
    if (assets is! List) return null;
    for (final a in assets.whereType<Map<String, dynamic>>()) {
      if (a['name'] == kUpdateMetadataAsset) {
        final url = Uri.tryParse('${a['browser_download_url']}');
        if (url == null || !isTrustedUpdateUri(url)) {
          throw const UpdateException('Unsichere Metadaten-URL.');
        }
        return client.fetchMetadata(url);
      }
    }
    return null;
  }

  CheckResult _finish(CheckResult r) {
    phase = switch (r.outcome) {
      CheckOutcome.updateAvailable => UpdatePhase.available,
      CheckOutcome.upToDate => UpdatePhase.upToDate,
      CheckOutcome.failed => UpdatePhase.error,
      CheckOutcome.skipped => UpdatePhase.idle,
    };
    message = r.message;
    notifyListeners();
    return r;
  }

  /// "SPÄTER ERINNERN": nothing is stored except the normal 24 h throttle.
  void remindLater() {
    promptPending = false;
    if (phase == UpdatePhase.available) phase = UpdatePhase.idle;
    notifyListeners();
  }

  void consumePrompt() => promptPending = false;

  /// Downloads, verifies and hands the APK to Android's installer.
  Future<void> downloadAndInstall() async {
    final u = update;
    final inst = installed;
    if (u == null || inst == null || _busy) return;
    _busy = true;
    _cancel = CancelToken();
    received = 0;
    total = u.apk.size;
    message = null;
    phase = UpdatePhase.downloading;
    notifyListeners();
    Directory? dir;
    try {
      final net = await platform.networkKind();
      if (net == NetworkKind.none) {
        throw const UpdateException('Keine Internetverbindung.');
      }
      if (wifiOnly && net != NetworkKind.wifi) {
        throw const UpdateException(
          'Download nur über WLAN erlaubt. In den Einstellungen unter SOFTWARE UPDATES änderbar.',
        );
      }
      dir = Directory(await platform.updateDirectory());
      final file = await ApkDownloader(http).download(
        apk: u.apk,
        dir: dir,
        freeBytes: await platform.freeSpace(),
        cancel: _cancel,
        onProgress: (r, t) {
          received = r;
          total = t;
          notifyListeners();
        },
      );
      phase = UpdatePhase.verifying;
      notifyListeners();
      try {
        verifyDownloadedApk(
          apk: await platform.inspectApk(file.path),
          installed: inst,
          update: u,
        );
      } catch (_) {
        await ApkDownloader.cleanup(dir);
        rethrow;
      }
      if (!await platform.canRequestInstall()) {
        await platform.openInstallPermissionSettings();
        throw const UpdateException(
          'Bitte erlaube TECH//DECK in den Android-Einstellungen „Unbekannte Apps installieren“ und tippe danach erneut auf JETZT AKTUALISIEREN.',
        );
      }
      phase = UpdatePhase.installing;
      notifyListeners();
      await platform.installApk(file.path);
    } on UpdateException catch (e) {
      phase = UpdatePhase.error;
      message = e.message;
    } catch (e) {
      phase = UpdatePhase.error;
      message = 'Update fehlgeschlagen: $e';
      if (dir != null) await ApkDownloader.cleanup(dir);
    } finally {
      _busy = false;
      _cancel = null;
      notifyListeners();
    }
  }

  void cancelDownload() {
    _cancel?.cancel();
    http.cancelAll();
    _http = null;
  }

  void _onInstallEvent((InstallEvent, String?) e) {
    switch (e.$1) {
      case InstallEvent.pendingUser:
        phase = UpdatePhase.installing;
      case InstallEvent.success:
        phase = UpdatePhase.idle;
      case InstallEvent.failure:
        phase = UpdatePhase.error;
        message =
            'Installation abgebrochen oder abgelehnt${e.$2 == null ? '' : ': ${e.$2}'}.';
        _cleanupQuietly();
    }
    notifyListeners();
  }

  Future<void> _cleanupQuietly() async {
    try {
      await ApkDownloader.cleanup(Directory(await platform.updateDirectory()));
    } catch (_) {}
  }

  @override
  void dispose() {
    _installSub?.cancel();
    super.dispose();
  }
}
