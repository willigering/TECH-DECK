import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tech_deck/state/deck_navigation_store.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'theme_choice': 'midnightSilver',
      'update_auto_check': false,
      'study_progress_existing': 'untouched',
    }),
  );

  test(
    'Favorites, categories, recency survive a fresh store; existing preferences remain',
    () async {
      final first = DeckNavigationStore();
      await first.load();
      first.favorites.add('stable-topic-id');
      first.categories['stable-topic-id'] = 'security';
      for (var i = 0; i < 7; i++) {
        await first.recordOpened('topic-$i');
      }
      await first.recordOpened('topic-4');
      final restored = DeckNavigationStore();
      await restored.load();
      expect(restored.favorites, {'stable-topic-id'});
      expect(restored.categories, {'stable-topic-id': 'security'});
      expect(restored.recent, [
        'topic-4',
        'topic-6',
        'topic-5',
        'topic-3',
        'topic-2',
      ]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_choice'), 'midnightSilver');
      expect(prefs.getBool('update_auto_check'), isFalse);
      expect(prefs.getString('study_progress_existing'), 'untouched');
    },
  );

  test('Rapid writes retain the final state', () async {
    final store = DeckNavigationStore();
    await store.load();
    store.favorites.add('one');
    final first = store.save();
    store.favorites.remove('one');
    store.favorites.add('two');
    final second = store.save();
    await Future.wait([first, second]);
    final restored = DeckNavigationStore();
    await restored.load();
    expect(restored.favorites, {'two'});
  });

  test(
    'Damaged optional navigation does not block existing app preferences',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(DeckNavigationStore.storageKey, '{broken');
      final restored = DeckNavigationStore();
      await restored.load();
      expect(restored.favorites, isEmpty);
      expect(prefs.getString('theme_choice'), 'midnightSilver');
    },
  );
}
