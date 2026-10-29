import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:tech_deck/update/update_http.dart';
import 'package:tech_deck/update/update_models.dart';
import 'package:tech_deck/update/update_platform.dart';

const cert = 'ace2efc26d7a0bf082af006c4006459b26199f51af2192eae46c1dddb4cd2e34';
const otherCert =
    '1111111111111111111111111111111111111111111111111111111111111111';

InstalledApp makeInstalled({
  String name = '1.7.11',
  int code = 22,
  int sdk = 34,
}) => InstalledApp(
  packageName: kUpdatePackageName,
  versionName: name,
  versionCode: code,
  sdkInt: sdk,
  abis: const ['arm64-v8a', 'armeabi-v7a'],
  signingCertSha256: const [cert],
);

final apkBytes = List<int>.generate(4096, (i) => i % 251);
String get apkSha => sha256.convert(apkBytes).toString();

const apkUrl =
    'https://github.com/willigering/TECH-DECK/releases/download/v1.7.12/TECH-DECK-1.7.12+23.apk';
const metaUrl =
    'https://github.com/willigering/TECH-DECK/releases/download/v1.7.12/techdeck-update.json';

Map<String, dynamic> release({
  String tag = 'v1.7.12',
  bool prerelease = false,
  bool withMeta = true,
  String? digest,
}) => {
  'tag_name': tag,
  'draft': false,
  'prerelease': prerelease,
  'html_url': 'https://github.com/willigering/TECH-DECK/releases/tag/$tag',
  'body': '## Neu\n- Neue Lernkarten\n- <b>Fehlerbehebungen</b>',
  'assets': [
    {
      'name': 'TECH-DECK-1.7.12+23.apk',
      'size': apkBytes.length,
      'digest': 'sha256:${digest ?? apkSha}',
      'browser_download_url': apkUrl,
    },
    if (withMeta)
      {
        'name': kUpdateMetadataAsset,
        'size': 300,
        'browser_download_url': metaUrl,
      },
  ],
};

Map<String, dynamic> metadata({
  int code = 23,
  String name = '1.7.12',
  String pkg = kUpdatePackageName,
  int minSdk = 24,
  String? sha,
  List<String> certs = const [cert],
}) => {
  'schema': 1,
  'packageName': pkg,
  'versionName': name,
  'versionCode': code,
  'minSdk': minSdk,
  'signingCertSha256': certs,
  'apks': [
    {
      'name': 'TECH-DECK-1.7.12+23.apk',
      'size': apkBytes.length,
      'sha256': sha ?? apkSha,
      'abis': <String>[],
    },
  ],
};

class FakeHttp implements UpdateHttp {
  FakeHttp({
    this.latest,
    this.meta,
    this.fail = false,
    this.status = 200,
    this.apkStream,
  });
  Map<String, dynamic>? latest;
  Map<String, dynamic>? meta;
  bool fail;
  int status;
  Stream<List<int>> Function()? apkStream;
  int apiCalls = 0;
  String? lastEtag;

  @override
  Future<HttpTextResponse> getText(
    Uri uri, {
    Map<String, String> headers = const {},
    int maxBytes = 0,
  }) async {
    if (fail) throw const SocketException('offline');
    if (uri.host == 'api.github.com') {
      apiCalls++;
      lastEtag = headers['If-None-Match'];
      if (lastEtag == '"e1"') return const HttpTextResponse(304, '', {});
      if (latest == null) return const HttpTextResponse(404, '{}', {});
      return HttpTextResponse(status, jsonEncode(latest), {'etag': '"e1"'});
    }
    return HttpTextResponse(200, jsonEncode(meta), const {});
  }

  @override
  Future<HttpStreamResponse> getStream(Uri uri) async {
    if (fail) throw const SocketException('offline');
    final s =
        apkStream?.call() ??
        Stream.fromIterable([
          apkBytes.sublist(0, 2000),
          apkBytes.sublist(2000),
        ]);
    return HttpStreamResponse(200, -1, s);
  }

  @override
  void cancelAll() {}
}

class FakePlatform implements UpdatePlatform {
  FakePlatform({
    InstalledApp? app,
    this.net = NetworkKind.wifi,
    this.inspection,
    required this.dir,
  }) : app = app ?? makeInstalled();
  InstalledApp app;
  NetworkKind net;
  ApkInspection? inspection;
  final Directory dir;
  String? installedPath;
  bool installAllowed = true;
  final events = StreamController<(InstallEvent, String?)>.broadcast();

  @override
  bool get isSupported => true;
  @override
  Future<InstalledApp?> installedApp() async => app;
  @override
  Future<NetworkKind> networkKind() async => net;
  @override
  Future<String> updateDirectory() async => dir.path;
  @override
  Future<int> freeSpace() async => 1 << 32;
  @override
  Future<ApkInspection?> inspectApk(String path) async => inspection;
  @override
  Future<bool> canRequestInstall() async => installAllowed;
  @override
  Future<void> openInstallPermissionSettings() async {}
  @override
  Future<void> installApk(String path) async => installedPath = path;
  @override
  Stream<(InstallEvent, String?)> get installEvents => events.stream;
}

ApkInspection inspection({
  String pkg = kUpdatePackageName,
  int code = 23,
  List<String> certs = const [cert],
  int minSdk = 24,
}) => ApkInspection(
  packageName: pkg,
  versionName: '1.7.12',
  versionCode: code,
  minSdk: minSdk,
  signingCertSha256: certs,
);
