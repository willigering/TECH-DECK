import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Play release has no APK installer or GitHub update transport', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, isNot(contains('REQUEST_INSTALL_PACKAGES')));
    expect(manifest, isNot(contains('android.permission.INTERNET')));
    expect(manifest, isNot(contains('ACCESS_NETWORK_STATE')));
    final activity = File(
      'android/app/src/main/kotlin/com/willigering/tech_deck/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, isNot(contains('PackageInstaller')));
    expect(activity, isNot(contains('MethodChannel')));
    expect(Directory('lib/update').existsSync(), isFalse);
    for (final f in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final source = f.readAsStringSync();
      expect(source, isNot(contains('UpdateController')), reason: f.path);
      expect(source, isNot(contains('api.github.com')), reason: f.path);
      expect(source, isNot(contains('HttpClient')), reason: f.path);
    }
  });
}
