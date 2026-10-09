import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tech_deck/state/deck_controller.dart';
import 'package:tech_deck/state/theme_controller.dart';
import 'package:tech_deck/state/welcome_controller.dart';
import 'package:tech_deck/ui/screens/shell.dart';
import 'package:tech_deck/data/models/overview_card.dart';
import 'package:tech_deck/ui/screens/overview_cards_screen.dart';

class _ReadyDeck extends DeckController {
  @override
  bool get loading => false;
}

void main() {
  testWidgets('Small main screen and Android back follow nested card routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final welcome = WelcomeController();
    await welcome.load();
    await welcome.dismiss(doNotShowAgain: true);
    final deck = _ReadyDeck();
    final theme = ThemeController();
    addTearDown(welcome.dispose);
    addTearDown(deck.dispose);
    addTearDown(theme.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: welcome),
          ChangeNotifierProvider<DeckController>.value(value: deck),
          ChangeNotifierProvider.value(value: theme),
        ],
        child: const MaterialApp(home: MainShell()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ÜBERSICHTSKARTEN'));
    await tester.tap(find.text('ÜBERSICHTSKARTEN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APIPA'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('ÜBERSICHTSKARTEN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Search matches multiple words across title and keywords', () {
    expect(
      overviewCards.where((card) => card.matches('  apipa ARP  ')).length,
      1,
    );
    expect(
      overviewCards.where((card) => card.matches('DNS')).single.title,
      'DNS-Hierarchie',
    );
    expect(overviewCards.where((card) => card.matches('unknown')), isEmpty);
  });

  testWidgets('Search, open image, go back and clear search', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OverviewCardsScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'arp');
    await tester.pumpAndSettle();
    expect(find.text('APIPA'), findsOneWidget);
    expect(find.text('OSI-Modell'), findsNothing);
    await tester.tap(find.text('APIPA'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byTooltip('Ansicht zurücksetzen'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('arp'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'unknown');
    await tester.pumpAndSettle();
    expect(find.text('Keine Übersichtskarten gefunden.'), findsOneWidget);
    await tester.tap(find.byTooltip('Suche löschen'));
    await tester.pumpAndSettle();
    expect(find.text('OSI-Modell'), findsOneWidget);
    expect(find.text('DNS-Hierarchie'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
