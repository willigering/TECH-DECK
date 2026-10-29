import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'update_models.dart';

enum NetworkKind { none, wifi, metered }

enum InstallEvent { pendingUser, success, failure }

/// Android side of the updater (see MainActivity.kt). Replaceable in tests.
abstract class UpdatePlatform {
  bool get isSupported;
  Future<InstalledApp?> installedApp();
  Future<NetworkKind> networkKind();
  Future<String> updateDirectory();
  Future<int> freeSpace();
  Future<ApkInspection?> inspectApk(String path);
  Future<bool> canRequestInstall();
  Future<void> openInstallPermissionSettings();
  Future<void> installApk(String path);
  Stream<(InstallEvent, String?)> get installEvents;
}

class MethodChannelUpdatePlatform implements UpdatePlatform {
  MethodChannelUpdatePlatform() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'installStatus') return;
      final args = Map<String, dynamic>.from(call.arguments as Map);
      final ev = switch (args['status']) {
        'pendingUser' => InstallEvent.pendingUser,
        'success' => InstallEvent.success,
        _ => InstallEvent.failure,
      };
      _events.add((ev, args['message'] as String?));
    });
  }

  static const _channel = MethodChannel('com.willigering.tech_deck/updater');
  final _events = StreamController<(InstallEvent, String?)>.broadcast();

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Stream<(InstallEvent, String?)> get installEvents => _events.stream;

  List<String> _strings(Object? v) => v is List
      ? [
          for (final e in v)
            if (e is String) e.toLowerCase(),
        ]
      : const [];

  @override
  Future<InstalledApp?> installedApp() async {
    final m = await _channel.invokeMapMethod<String, dynamic>(
      'getInstalledInfo',
    );
    if (m == null) return null;
    return InstalledApp(
      packageName: m['packageName'] as String,
      versionName: (m['versionName'] as String?) ?? '0.0.0',
      versionCode: (m['versionCode'] as num).toInt(),
      sdkInt: (m['sdkInt'] as num).toInt(),
      abis: _strings(m['abis']),
      signingCertSha256: _strings(m['signingCertSha256']),
    );
  }

  @override
  Future<NetworkKind> networkKind() async =>
      switch (await _channel.invokeMethod<String>('getNetworkType')) {
        'wifi' => NetworkKind.wifi,
        'metered' => NetworkKind.metered,
        _ => NetworkKind.none,
      };

  @override
  Future<String> updateDirectory() async =>
      (await _channel.invokeMethod<String>('getUpdateDirectory'))!;

  @override
  Future<int> freeSpace() async =>
      (await _channel.invokeMethod<num>('getFreeSpace'))?.toInt() ?? 0;

  @override
  Future<ApkInspection?> inspectApk(String path) async {
    final m = await _channel.invokeMapMethod<String, dynamic>('inspectApk', {
      'path': path,
    });
    if (m == null) return null;
    return ApkInspection(
      packageName: m['packageName'] as String,
      versionName: (m['versionName'] as String?) ?? '',
      versionCode: (m['versionCode'] as num).toInt(),
      minSdk: (m['minSdk'] as num?)?.toInt() ?? 0,
      signingCertSha256: _strings(m['signingCertSha256']),
    );
  }

  @override
  Future<bool> canRequestInstall() async =>
      await _channel.invokeMethod<bool>('canRequestInstall') ?? false;

  @override
  Future<void> openInstallPermissionSettings() =>
      _channel.invokeMethod('openInstallPermissionSettings');

  @override
  Future<void> installApk(String path) =>
      _channel.invokeMethod('installApk', {'path': path});
}
