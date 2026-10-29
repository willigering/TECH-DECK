import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tech_deck/update/github_release_client.dart';
import 'package:tech_deck/update/update_controller.dart';
import 'package:tech_deck/update/update_http.dart';
import 'package:tech_deck/update/update_models.dart';
import 'package:tech_deck/update/update_platform.dart';
import 'package:tech_deck/update/version_compare.dart';

import 'fakes.dart';

void main() {
  late Directory tmp;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tmp = await Directory.systemTemp.createTemp('td_update');
  });
  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  UpdateController make(
    FakeHttp http, {
    FakePlatform? platform,
    DateTime Function()? clock,
  }) => UpdateController(
    platform: platform ?? FakePlatform(dir: tmp),
    http: http,
    clock: clock,
  );

  group('Versionsvergleich', () {
    test('Tags in allen Schreibweisen', () {
      expect(SemVer.tryParse('v.1.7.11').toString(), '1.7.11');
      expect(
        SemVer.tryParse('v1.7.12')!.compareTo(SemVer.tryParse('1.7.11')!),
        1,
      );
      expect(SemVer.tryParse('1.7.12+23')!.build, 23);
      expect(SemVer.tryParse('1.8.0-beta'), isNull);
    });
    test('Gleiche Version: kein Update', () {
      expect(
        isNewerRelease(
          installedName: '1.7.11',
          installedCode: 22,
          candidateName: '1.7.11',
          candidateCode: 22,
        ),
        isFalse,
      );
    });
    test('Ältere Version: kein Downgrade', () {
      expect(
        isNewerRelease(
          installedName: '1.7.11',
          installedCode: 22,
          candidateName: '1.7.10',
          candidateCode: 21,
        ),
        isFalse,
      );
      // Manipulated label: higher name but lower code.
      expect(
        isNewerRelease(
          installedName: '1.7.11',
          installedCode: 22,
          candidateName: '9.9.9',
          candidateCode: 5,
        ),
        isFalse,
      );
      // Higher code but lower name.
      expect(
        isNewerRelease(
          installedName: '1.7.11',
          installedCode: 22,
          candidateName: '1.0.0',
          candidateCode: 99,
        ),
        isFalse,
      );
    });
    test('Neuere Version', () {
      expect(
        isNewerRelease(
          installedName: '1.7.11',
          installedCode: 22,
          candidateName: '1.7.12',
          candidateCode: 23,
        ),
        isTrue,
      );
    });
  });

  group('Release-Auswahl', () {
    test('Pre-Releases werden ignoriert', () {
      expect(
        selectUpdate(
          release: release(prerelease: true),
          metadata: metadata(),
          installed: makeInstalled(),
        ),
        isNull,
      );
    });
    test('Falsche Paketkennung in Metadaten', () {
      expect(
        () => selectUpdate(
          release: release(),
          metadata: metadata(pkg: 'evil.app'),
          installed: makeInstalled(),
        ),
        throwsA(isA<UpdateException>()),
      );
    });
    test('Tag und Metadaten widersprechen sich', () {
      expect(
        () => selectUpdate(
          release: release(tag: 'v1.7.13'),
          metadata: metadata(),
          installed: makeInstalled(),
        ),
        throwsA(isA<UpdateException>()),
      );
    });
    test('Prüfsumme widerspricht GitHub-Digest', () {
      expect(
        () => selectUpdate(
          release: release(digest: otherCert),
          metadata: metadata(),
          installed: makeInstalled(),
        ),
        throwsA(isA<UpdateException>()),
      );
    });
    test('Inkompatible Signatur wird vorab erkannt', () {
      expect(
        () => selectUpdate(
          release: release(),
          metadata: metadata(certs: [otherCert]),
          installed: makeInstalled(),
        ),
        throwsA(isA<UpdateException>()),
      );
    });
    test('Ungeeignete Android-Version', () {
      expect(
        selectUpdate(
          release: release(),
          metadata: metadata(minSdk: 40),
          installed: makeInstalled(sdk: 30),
        ),
        isNull,
      );
    });
    test('Legacy-Release ohne Metadaten nutzt GitHub-Digest', () {
      final u = selectUpdate(
        release: release(withMeta: false),
        metadata: null,
        installed: makeInstalled(),
      );
      expect(u!.versionCode, 23);
      expect(u.apk.sha256, apkSha);
    });
    test('Passende ABI-Variante wird gewählt', () {
      UpdateApk a(String n, List<String> abis) => UpdateApk(
        name: n,
        url: Uri.parse(apkUrl),
        size: 1,
        sha256: apkSha,
        abis: abis,
      );
      final list = [
        a('x86', ['x86_64']),
        a('v7', ['armeabi-v7a']),
        a('arm64', ['arm64-v8a']),
        a('uni', []),
      ];
      expect(
        pickApkForDevice(list, ['arm64-v8a', 'armeabi-v7a'])!.name,
        'arm64',
      );
      expect(pickApkForDevice([list[0], list[3]], ['arm64-v8a'])!.name, 'uni');
      expect(pickApkForDevice([list[0]], ['arm64-v8a']), isNull);
    });
    test('Release Notes werden sicher als Text dargestellt', () {
      final s = sanitizeReleaseNotes(
        '## Neu\n- **A** <script>x</script>\n[Link](javascript:alert(1))\u202E',
      );
      expect(s, isNot(contains('<')));
      expect(s, isNot(contains('javascript')));
      expect(s, contains('• A'));
    });
    test('Nur HTTPS und offizielle GitHub-Hosts', () {
      expect(isTrustedUpdateUri(Uri.parse(apkUrl)), isTrue);
      expect(isTrustedUpdateUri(Uri.parse('http://github.com/x.apk')), isFalse);
      expect(
        isTrustedUpdateUri(Uri.parse('https://evil.example/x.apk')),
        isFalse,
      );
      expect(
        isTrustedUpdateUri(Uri.parse('https://github.com.evil.example/x.apk')),
        isFalse,
      );
    });
  });

  group('Updateprüfung', () {
    test('Keine Internetverbindung: kein Absturz, keine Anfrage', () async {
      final http = FakeHttp(latest: release(), meta: metadata());
      final c = make(
        http,
        platform: FakePlatform(dir: tmp, net: NetworkKind.none),
      );
      final r = await c.checkNow();
      expect(r.outcome, CheckOutcome.failed);
      expect(http.apiCalls, 0);
      await c.autoCheckOnStart();
      expect(c.promptPending, isFalse);
    });
    test('GitHub nicht erreichbar: kein Absturz', () async {
      final c = make(FakeHttp(fail: true));
      final r = await c.checkNow();
      expect(r.outcome, CheckOutcome.failed);
      expect(c.phase, UpdatePhase.error);
    });
    test('Fehlerhafte GitHub-Antwort / Rate-Limit', () async {
      expect(
        (await make(
          FakeHttp(latest: release(), status: 500),
        ).checkNow()).outcome,
        CheckOutcome.failed,
      );
      expect(
        (await make(
          FakeHttp(latest: release(), status: 403),
        ).checkNow()).outcome,
        CheckOutcome.failed,
      );
    });
    test('Keine neue Version: Meldung', () async {
      final c = make(FakeHttp(latest: null));
      final r = await c.checkNow();
      expect(r.outcome, CheckOutcome.upToDate);
      expect(r.message, 'SYSTEM UP TO DATE – Ausnahmsweise mal nichts kaputt.');
      expect(c.lastSuccess, isNotNull);
    });
    test('Gleiche Version: kein Update', () async {
      final c = make(
        FakeHttp(latest: release(), meta: metadata(code: 23)),
        platform: FakePlatform(
          dir: tmp,
          app: makeInstalled(name: '1.7.12', code: 23),
        ),
      );
      expect((await c.checkNow()).outcome, CheckOutcome.upToDate);
    });
    test(
      'Neue Version verfügbar + automatische Prüfung höchstens alle 24 h',
      () async {
        var now = DateTime(2026, 10, 29, 8);
        final http = FakeHttp(latest: release(), meta: metadata());
        final c = make(http, clock: () => now);
        await c.autoCheckOnStart();
        expect(c.promptPending, isTrue);
        expect(c.update!.versionName, '1.7.12');
        expect(http.apiCalls, 1);

        final c2 = make(http, clock: () => now.add(const Duration(hours: 5)));
        await c2.autoCheckOnStart();
        expect(http.apiCalls, 1, reason: 'throttled');

        final c3 = make(http, clock: () => now.add(const Duration(hours: 25)));
        await c3.autoCheckOnStart();
        expect(http.apiCalls, 2);
        expect(http.lastEtag, '"e1"', reason: 'ETag spart API-Kontingent');
        expect(c3.update, isNotNull, reason: '304 nutzt den Cache');

        // Manual check is always possible.
        await c2.checkNow();
        expect(http.apiCalls, 3);
      },
    );
    test('Automatische Prüfung deaktivierbar', () async {
      final http = FakeHttp(latest: release(), meta: metadata());
      final c = make(http);
      await c.load();
      await c.setAutoCheck(false);
      await c.autoCheckOnStart();
      expect(http.apiCalls, 0);
      final again = make(http);
      await again.load();
      expect(again.autoCheck, isFalse);
      expect(again.wifiOnly, isTrue);
    });
    test('Benutzer lehnt ab: App läuft weiter, nichts gelöscht', () async {
      SharedPreferences.setMockInitialValues({'theme_choice': 'lightGold'});
      final c = make(FakeHttp(latest: release(), meta: metadata()));
      await c.checkNow();
      c.remindLater();
      expect(c.phase, UpdatePhase.idle);
      expect(
        (await SharedPreferences.getInstance()).getString('theme_choice'),
        'lightGold',
      );
    });
  });

  group('Download und Installation', () {
    Future<UpdateController> ready(FakeHttp http, FakePlatform p) async {
      final c = make(http, platform: p);
      await c.checkNow();
      expect(c.update, isNotNull);
      return c;
    }

    List<FileSystemEntity> leftovers() => tmp.listSync();

    test(
      'Erfolgreiches Update: Installer wird geöffnet, Daten bleiben',
      () async {
        SharedPreferences.setMockInitialValues({
          'theme_choice': 'midnightSilver',
          'welcome_do_not_show_again': true,
        });
        final p = FakePlatform(dir: tmp, inspection: inspection());
        final c = await ready(FakeHttp(latest: release(), meta: metadata()), p);
        await c.downloadAndInstall();
        expect(c.phase, UpdatePhase.installing, reason: c.message);
        expect(p.installedPath, endsWith('TECH-DECK-1.7.12+23.apk'));
        expect(File(p.installedPath!).lengthSync(), apkBytes.length);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_choice'), 'midnightSilver');
        expect(prefs.getBool('welcome_do_not_show_again'), isTrue);
      },
    );
    test('Download unterbrochen: saubere Fehlerbehandlung', () async {
      final p = FakePlatform(dir: tmp, inspection: inspection());
      final http = FakeHttp(
        latest: release(),
        meta: metadata(),
        apkStream: () async* {
          yield apkBytes.sublist(0, 1000);
          throw const SocketException('reset');
        },
      );
      final c = await ready(http, p);
      await c.downloadAndInstall();
      expect(c.phase, UpdatePhase.error);
      expect(p.installedPath, isNull);
      expect(leftovers(), isEmpty);
    });
    test('Unvollständiger Download wird erkannt', () async {
      final p = FakePlatform(dir: tmp, inspection: inspection());
      final c = await ready(
        FakeHttp(
          latest: release(),
          meta: metadata(),
          apkStream: () => Stream.value(apkBytes.sublist(0, 100)),
        ),
        p,
      );
      await c.downloadAndInstall();
      expect(c.message, contains('unvollständig'));
      expect(leftovers(), isEmpty);
    });
    test('Abbruch durch Benutzer', () async {
      final p = FakePlatform(dir: tmp, inspection: inspection());
      final gate = StreamController<List<int>>();
      final c = await ready(
        FakeHttp(
          latest: release(),
          meta: metadata(),
          apkStream: () => gate.stream,
        ),
        p,
      );
      final f = c.downloadAndInstall();
      gate.add(apkBytes.sublist(0, 10));
      await Future<void>.delayed(Duration.zero);
      expect(c.phase, UpdatePhase.downloading);
      c.cancelDownload();
      await f;
      expect(c.message, contains('abgebrochen'));
      expect(p.installedPath, isNull);
      expect(leftovers(), isEmpty);
      await gate.close();
    });
    test('APK beschädigt (Prüfsumme): Installation verhindert', () async {
      final p = FakePlatform(dir: tmp, inspection: inspection());
      final bad = List<int>.of(apkBytes)..[10] ^= 0xff;
      final c = await ready(
        FakeHttp(
          latest: release(),
          meta: metadata(),
          apkStream: () => Stream.value(bad),
        ),
        p,
      );
      await c.downloadAndInstall();
      expect(c.message, contains('SHA-256'));
      expect(p.installedPath, isNull);
      expect(leftovers(), isEmpty);
    });
    test('APK beschädigt (nicht lesbar): Installation verhindert', () async {
      final p = FakePlatform(dir: tmp, inspection: null);
      final c = await ready(FakeHttp(latest: release(), meta: metadata()), p);
      await c.downloadAndInstall();
      expect(c.message, contains('beschädigt'));
      expect(p.installedPath, isNull);
      expect(leftovers(), isEmpty);
    });
    test('Falsche Paketkennung in der APK: Installation verhindert', () async {
      final p = FakePlatform(
        dir: tmp,
        inspection: inspection(pkg: 'com.evil.app'),
      );
      final c = await ready(FakeHttp(latest: release(), meta: metadata()), p);
      await c.downloadAndInstall();
      expect(c.message, contains('Paketkennung'));
      expect(p.installedPath, isNull);
    });
    test('APK mit anderem Schlüssel: Installation verhindert', () async {
      final p = FakePlatform(
        dir: tmp,
        inspection: inspection(certs: [otherCert]),
      );
      final c = await ready(FakeHttp(latest: release(), meta: metadata()), p);
      await c.downloadAndInstall();
      expect(c.message, contains('Schlüssel'));
      expect(p.installedPath, isNull);
    });
    test('APK enthält ältere Version: kein Downgrade', () async {
      final p = FakePlatform(dir: tmp, inspection: inspection(code: 21));
      final c = await ready(FakeHttp(latest: release(), meta: metadata()), p);
      await c.downloadAndInstall();
      expect(c.message, contains('Downgrade'));
      expect(p.installedPath, isNull);
    });
    test('Nur WLAN: kein Download über mobile Daten', () async {
      final p = FakePlatform(dir: tmp, inspection: inspection());
      final c = await ready(FakeHttp(latest: release(), meta: metadata()), p);
      p.net = NetworkKind.metered;
      await c.downloadAndInstall();
      expect(c.message, contains('WLAN'));
      await c.setWifiOnly(false);
      await c.downloadAndInstall();
      expect(p.installedPath, isNotNull);
    });
    test('Installationsfreigabe fehlt: Erklärung statt Installation', () async {
      final p = FakePlatform(dir: tmp, inspection: inspection())
        ..installAllowed = false;
      final c = await ready(FakeHttp(latest: release(), meta: metadata()), p);
      await c.downloadAndInstall();
      expect(c.message, contains('Unbekannte Apps'));
      expect(p.installedPath, isNull);
    });
  });
}
