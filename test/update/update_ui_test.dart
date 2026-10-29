import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tech_deck/core/theme.dart';
import 'package:tech_deck/state/theme_controller.dart';
import 'package:tech_deck/ui/widgets/update_dialog.dart';
import 'package:tech_deck/ui/widgets/update_settings_section.dart';
import 'package:tech_deck/update/update_controller.dart';

import 'fakes.dart';

void main() {
  testWidgets('Updatehinweis erscheint und SPÄTER ERINNERN schließt ihn', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final dir = Directory.systemTemp.createTempSync('td_ui');
    final c = UpdateController(
      platform: FakePlatform(dir: dir),
      http: FakeHttp(latest: release(), meta: metadata()),
    );
    await tester.runAsync(() => c.checkNow());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: c,
        child: MaterialApp(
          theme: TdTheme.forChoice(TdThemeChoice.darkGold),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => showUpdateDialog(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('SYSTEM UPDATE AVAILABLE'), findsOneWidget);
    expect(find.text('1.7.11'), findsOneWidget);
    expect(find.text('1.7.12'), findsOneWidget);
    expect(find.text('JETZT AKTUALISIEREN'), findsOneWidget);
    expect(find.textContaining('Neue Lernkarten'), findsOneWidget);
    await tester.tap(find.text('SPÄTER ERINNERN'));
    await tester.pumpAndSettle();
    expect(find.text('SYSTEM UPDATE AVAILABLE'), findsNothing);
    expect(
      find.text('open'),
      findsOneWidget,
      reason: 'App funktioniert weiter',
    );
    dir.deleteSync(recursive: true);
  });

  testWidgets('Einstellungsbereich SOFTWARE UPDATES', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final dir = Directory.systemTemp.createTempSync('td_ui');
    final c = UpdateController(
      platform: FakePlatform(dir: dir),
      http: FakeHttp(latest: null),
    );
    await tester.runAsync(() => c.load());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: c,
        child: MaterialApp(
          theme: TdTheme.forChoice(TdThemeChoice.darkGold),
          home: const Scaffold(
            body: SingleChildScrollView(child: UpdateSettingsSection()),
          ),
        ),
      ),
    );
    expect(find.text('SOFTWARE UPDATES'), findsOneWidget);
    expect(find.text('Automatisch nach Updates suchen'), findsOneWidget);
    expect(find.text('Nur über WLAN herunterladen'), findsOneWidget);
    expect(
      find.textContaining('Installierte Version: 1.7.11 · Build 22'),
      findsOneWidget,
    );
    expect(find.text('Letzte Updateprüfung: Noch nie'), findsOneWidget);
    await tester.runAsync(() => c.checkNow());
    await tester.pump();
    expect(find.textContaining('Letzte Updateprüfung: '), findsOneWidget);
    expect(find.text('Letzte Updateprüfung: Noch nie'), findsNothing);
    dir.deleteSync(recursive: true);
  });
}
