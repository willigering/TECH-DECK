import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tech_deck/core/theme.dart';
import 'package:tech_deck/data/models/flashcard.dart';
import 'package:tech_deck/data/models/topic.dart';
import 'package:tech_deck/data/repositories/deck_repository.dart';
import 'package:tech_deck/state/deck_controller.dart';
import 'package:tech_deck/state/theme_controller.dart';
import 'package:tech_deck/ui/screens/topic_picker_screen.dart';

class PickerRepository extends DeckRepository {
  List<Topic> topics = [
    Topic(
      id: 'network',
      name: 'IPv4, IPv6 und Subnetting mit vollständigem Kartensatznamen',
      sourceFilename: 'netz.csv',
      sortOrder: 0,
      importedAt: DateTime(2026),
      cardCount: 12,
    ),
    Topic(
      id: 'custom',
      name: 'Eigene Lernkartei',
      sourceFilename: 'eigen.csv',
      sortOrder: 1,
      importedAt: DateTime(2026),
      cardCount: 3,
      isImportant: true,
    ),
  ];
  @override
  Future<void> ensureBundledTopics() async {}
  @override
  Future<List<Topic>> loadTopics() async => topics;
  @override
  Future<List<Flashcard>> loadCards(String topicId) async => [
    Flashcard(
      id: 'card',
      topicId: topicId,
      question: 'Was ist DHCP?',
      answer: 'Adressvergabe',
    ),
  ];
  @override
  Future<Map<String, String>> loadTopicSearchIndex() async => {
    'custom': 'Verschlüsselung öffentlicher Schlüssel',
  };
  @override
  Future<void> updateTopicMark(
    String topicId, {
    String? colorKey,
    bool clearColor = false,
    bool? isImportant,
  }) async {
    topics = [
      for (final t in topics)
        t.id != topicId
            ? t
            : t.copyWith(
                colorKey: colorKey,
                clearColor: clearColor,
                isImportant: isImportant,
              ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<DeckController> mount(
    WidgetTester tester, {
    double scale = 1,
    Size size = const Size(390, 844),
    TdThemeChoice theme = TdThemeChoice.darkGold,
    bool reducedMotion = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final deck = DeckController(repository: PickerRepository());
    await tester.runAsync(deck.load);
    addTearDown(deck.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: deck,
        child: MaterialApp(
          theme: TdTheme.forChoice(theme),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(scale),
              disableAnimations: reducedMotion,
            ),
            child: const TopicPickerScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return deck;
  }

  testWidgets(
    'Accordion opens and closes; complete name, totals and favorites work',
    (tester) async {
      final deck = await mount(tester);
      expect(find.text('1 Kartensatz · 12 Karten'), findsOneWidget);
      expect(find.byKey(const ValueKey('deck-network')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Netzwerke & Protokolle'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Netzwerke & Protokolle'));
      await tester.pumpAndSettle();
      expect(find.text(deck.topics.first.name), findsOneWidget);
      expect(find.text('12 Karten'), findsOneWidget);
      await tester.tap(find.byTooltip('Zu Favoriten hinzufügen'));
      await tester.pumpAndSettle();
      expect(deck.isFavorite('network'), isTrue);
      await tester.scrollUntilVisible(
        find.text('Netzwerke & Protokolle'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Netzwerke & Protokolle'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('deck-network')), findsNothing);
      await tester.tap(find.text('Favoriten (1)'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('deck-network')), findsOneWidget);
      expect(find.byKey(const ValueKey('deck-custom')), findsNothing);
      await tester.tap(find.byTooltip('Aus Favoriten entfernen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Noch keine Favoriten.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Search category, content and no results; clear restores accordion',
    (tester) async {
      await mount(tester);
      await tester.enterText(find.byType(TextField), 'öffentlicher schlüssel');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('deck-custom')), findsOneWidget);
      expect(find.byKey(const ValueKey('deck-network')), findsNothing);
      await tester.enterText(find.byType(TextField), 'Netzwerke');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('deck-network')), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'nirgendwo');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(
        find.text('Keine passenden Kartensätze gefunden.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Suche löschen'));
      await tester.pumpAndSettle();
      expect(find.text('Netzwerke & Protokolle'), findsOneWidget);
      expect(find.byKey(const ValueKey('deck-network')), findsNothing);
    },
  );

  testWidgets(
    'Long press retains color and important controls; recency returns from learning',
    (tester) async {
      final deck = await mount(tester);
      await tester.scrollUntilVisible(
        find.text('Netzwerke & Protokolle'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Netzwerke & Protokolle'));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const ValueKey('deck-network')));
      await tester.pumpAndSettle();
      expect(find.text('Als wichtig markieren'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(deck.topicById('network')!.isImportant, isTrue);
      await tester.tap(find.byTooltip('Grün'));
      await tester.pumpAndSettle();
      expect(deck.topicById('network')!.colorKey, 'green');
      await tester.tapAt(const Offset(10, 100));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('deck-network')));
      await tester.pumpAndSettle();
      expect(deck.recentTopics.single.id, 'network');
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Zuletzt (1)'));
      await tester.tap(find.text('Zuletzt (1)'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('deck-network')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Imported deck can be assigned to a category through long press',
    (tester) async {
      final deck = await mount(tester);
      await tester.enterText(find.byType(TextField), 'Eigene Lernkartei');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const ValueKey('deck-custom')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Automatisch zuordnen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Netzwerke & Protokolle').last);
      await tester.pumpAndSettle();
      expect(deck.categoryFor(deck.topicById('custom')!).id, 'networks');
      await tester.tapAt(const Offset(10, 100));
      await tester.pumpAndSettle();
      expect(find.text('Netzwerke & Protokolle'), findsOneWidget);
      expect(find.byKey(const ValueKey('deck-custom')), findsOneWidget);
    },
  );

  for (final theme in TdThemeChoice.values) {
    for (final viewport in [
      (const Size(320, 568), 1.0),
      (const Size(568, 320), 1.0),
      (const Size(320, 568), 2.0),
    ]) {
      testWidgets('Picker fits $theme / $viewport with reduced motion', (
        tester,
      ) async {
        await mount(
          tester,
          theme: theme,
          size: viewport.$1,
          scale: viewport.$2,
          reducedMotion: true,
        );
        await tester.scrollUntilVisible(
          find.text('Netzwerke & Protokolle'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Netzwerke & Protokolle'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.hasRunningAnimations, isFalse);
      });
    }
  }
}
