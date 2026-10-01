import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tech_deck/core/theme.dart';
import 'package:tech_deck/state/deck_controller.dart';
import 'package:tech_deck/state/theme_controller.dart';
import 'package:tech_deck/state/welcome_controller.dart';
import 'package:tech_deck/ui/screens/shell.dart';
import 'package:tech_deck/ui/screens/start_screen.dart';
import 'package:tech_deck/ui/screens/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final body = FontLoader(
      'Roboto',
    )..addFont(rootBundle.load('packages/hyphenatorx/test/Roboto-Regular.ttf'));
    final brand = FontLoader('Orbitron')
      ..addFont(rootBundle.load('assets/fonts/Orbitron-Bold.ttf'));
    await Future.wait([body.load(), brand.load()]);
  });

  test(
    'First launch, saved opt-out, manual reopening and opting back in',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = WelcomeController();
      await first.load();
      expect(first.visible, isTrue);
      expect(first.doNotShowAgain, isTrue);
      await first.dismiss(doNotShowAgain: true);
      expect(first.visible, isFalse);

      final next = WelcomeController();
      await next.load();
      expect(next.visible, isFalse);
      next.show();
      expect(next.visible, isTrue);
      await next.dismiss(doNotShowAgain: false);

      final optedIn = WelcomeController();
      await optedIn.load();
      expect(optedIn.visible, isTrue);
      expect(optedIn.doNotShowAgain, isFalse);
      first.dispose();
      next.dispose();
      optedIn.dispose();
    },
  );

  for (final viewport in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(568, 320), 1.0),
    (const Size(844, 390), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(768, 1024), 1.0),
  ]) {
    for (final choice in TdThemeChoice.values) {
      testWidgets('One welcome page: $viewport, $choice', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final welcome = WelcomeController();
        await welcome.load();
        addTearDown(welcome.dispose);
        tester.view.physicalSize = viewport.$1;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        bool? selection;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: welcome,
            child: MaterialApp(
              theme: TdTheme.forChoice(choice),
              home: MediaQuery(
                data: MediaQueryData(
                  size: viewport.$1,
                  padding: const EdgeInsets.only(top: 24, bottom: 16),
                  textScaler: TextScaler.linear(viewport.$2),
                ),
                child: WelcomeScreen(onContinue: (value) => selection = value),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(Scrollable), findsNothing);
        expect(find.text('Deck wählen'), findsOneWidget);
        expect(find.text('Mach’s dir passend'), findsOneWidget);
        expect(find.text('Nicht wieder anzeigen'), findsOneWidget);
        expect(
          tester.getRect(find.byType(FilledButton)).bottom,
          lessThanOrEqualTo(viewport.$1.height - 16),
        );
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        await tester.tap(find.text('Na gut, ich lerne.'));
        expect(selection, isFalse);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Main screen stays mounted and loading behind welcome', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final welcome = WelcomeController();
    await welcome.load();
    final deck = DeckController();
    final theme = ThemeController();
    addTearDown(welcome.dispose);
    addTearDown(deck.dispose);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: welcome),
          ChangeNotifierProvider.value(value: deck),
          ChangeNotifierProvider.value(value: theme),
        ],
        child: MaterialApp(
          theme: TdTheme.forChoice(TdThemeChoice.darkGold),
          home: const MainShell(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(deck.loading, isTrue);
    await tester.tap(find.text('Na gut, ich lerne.'));
    await tester.pump();
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(StartScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.tap(find.text('Einstellungen'));
    await tester.pump();
    await tester.tap(find.text('WILLKOMMEN ANZEIGEN'));
    await tester.pump();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await tester.tap(find.text('Na gut, ich lerne.'));
    await tester.pump();
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
