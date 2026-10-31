import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/topic.dart';
import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import '../widgets/topic_mark_sheet.dart';
import '../widgets/topic_tile.dart';
import 'learn_screen.dart';

enum _QuickFilter { all, favorites, recent, important }

class TopicPickerScreen extends StatefulWidget {
  const TopicPickerScreen({super.key});
  static const routeName = 'topic-picker';

  @override
  State<TopicPickerScreen> createState() => _TopicPickerScreenState();
}

class _TopicPickerScreenState extends State<TopicPickerScreen> {
  final _search = TextEditingController();
  final _expanded = <String>{};
  final _collapsedSearch = <String>{};
  _QuickFilter _filter = _QuickFilter.all;
  Timer? _debounce;
  Set<String>? _matches;
  String _query = '';
  String? _searchError;
  bool _searching = false;
  int _request = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    final request = ++_request;
    setState(() {
      _query = value.trim();
      _matches = null;
      _searchError = null;
      _collapsedSearch.clear();
      _searching = _query.isNotEmpty;
    });
    if (_query.isEmpty) return;
    final deck = context.read<DeckController>();
    _debounce = Timer(const Duration(milliseconds: 180), () async {
      try {
        final matches = await deck.searchTopicIds(value);
        if (!mounted || request != _request) return;
        setState(() {
          _matches = matches;
          _searching = false;
        });
      } catch (_) {
        if (!mounted || request != _request) return;
        setState(() {
          _searching = false;
          _searchError =
              'Karteninhalte konnten nicht durchsucht werden. '
              'Kategorien und Namen werden weiterhin durchsucht.';
        });
      }
    });
  }

  Future<void> _save(Future<void> operation) async {
    try {
      await operation;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Änderung konnte nicht gespeichert werden.'),
        ),
      );
    }
  }

  Widget _tile(DeckController deck, Topic topic) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TopicTile(
      key: ValueKey('deck-${topic.id}'),
      topic: topic,
      onLongPress: () async {
        await showTopicMarkSheet(context, topic);
        if (mounted && _query.isNotEmpty) _searchChanged(_search.text);
      },
      trailing: IconButton(
        tooltip: deck.isFavorite(topic.id)
            ? 'Aus Favoriten entfernen'
            : 'Zu Favoriten hinzufügen',
        onPressed: () => _save(deck.toggleFavorite(topic.id)),
        icon: Icon(
          deck.isFavorite(topic.id)
              ? Icons.bookmark_rounded
              : Icons.bookmark_border_rounded,
        ),
      ),
      onTap: () {
        if (topic.cardCount == 0) return;
        deck.selectTopic(topic.id);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LearnScreen(topicId: topic.id)),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    final cs = Theme.of(context).colorScheme;
    final searching = _query.isNotEmpty;
    final source = switch (_filter) {
      _QuickFilter.favorites => deck.favoriteTopics,
      _QuickFilter.recent => deck.recentTopics,
      _QuickFilter.important =>
        deck.topics.where((t) => t.isImportant).toList(),
      _QuickFilter.all => deck.topics,
    };
    final topics = source
        .where(
          (topic) =>
              !searching ||
              (_matches?.contains(topic.id) ??
                  deck.catalog.matches(
                    topic,
                    deck.categoryFor(topic),
                    _query,
                    '',
                  )),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Zurück',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('THEMA WÄHLEN'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _search,
                      onChanged: _searchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Kategorie, Kartensatz oder Begriff suchen',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Suche löschen',
                                onPressed: () {
                                  _search.clear();
                                  _searchChanged('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: cs.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final entry in [
                            (_QuickFilter.all, 'Alle', Icons.folder_outlined),
                            (
                              _QuickFilter.favorites,
                              'Favoriten (${deck.favoriteTopics.length})',
                              Icons.bookmark_border_rounded,
                            ),
                            (
                              _QuickFilter.recent,
                              'Zuletzt (${deck.recentTopics.length})',
                              Icons.history_rounded,
                            ),
                            (
                              _QuickFilter.important,
                              'Wichtig',
                              Icons.star_outline_rounded,
                            ),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                avatar: Icon(entry.$3, size: 17),
                                label: Text(entry.$2),
                                selected: _filter == entry.$1,
                                onSelected: (_) =>
                                    setState(() => _filter = entry.$1),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lange drücken: Farbe, Wichtig und Kategorie.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: .65),
                      ),
                    ),
                    if (_searching) const LinearProgressIndicator(minHeight: 2),
                    if (_searchError != null)
                      Text(
                        _searchError!,
                        style: TextStyle(fontSize: 12, color: cs.error),
                      ),
                  ],
                ),
              ),
            ),
            if (deck.loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (deck.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Kartensätze konnten nicht geladen werden.\n${deck.error}',
                  ),
                ),
              )
            else if (topics.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GoldPanel(
                    child: Text(
                      deck.topics.isEmpty
                          ? 'Keine Themen vorhanden. Importiere CSV-Dateien unter Einstellungen.'
                          : searching
                          ? 'Keine passenden Kartensätze gefunden.'
                          : _filter == _QuickFilter.favorites
                          ? 'Noch keine Favoriten. Tippe auf das Lesezeichen eines Kartensatzes.'
                          : _filter == _QuickFilter.recent
                          ? 'Hier erscheinen deine nächsten geöffneten Kartensätze.'
                          : 'Keine wichtigen Kartensätze markiert.',
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                sliver: SliverList.list(
                  children: [
                    SectionLabel(
                      searching
                          ? '${topics.length} ${topics.length == 1 ? 'Kartensatz' : 'Kartensätze'} gefunden'
                          : 'THEMA FÜR LERNEN',
                    ),
                    const SizedBox(height: 10),
                    if (_filter != _QuickFilter.all)
                      for (final topic in topics) _tile(deck, topic)
                    else
                      for (final category in deck.catalog.categories)
                        if (topics.any(
                          (t) => deck.categoryFor(t).id == category.id,
                        ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _CategoryAccordion(
                              key: ValueKey('category-${category.id}'),
                              name: category.name,
                              topics: topics
                                  .where(
                                    (t) =>
                                        deck.categoryFor(t).id == category.id,
                                  )
                                  .toList(),
                              expanded: searching
                                  ? !_collapsedSearch.contains(category.id)
                                  : _expanded.contains(category.id),
                              onToggle: () => setState(() {
                                final ids = searching
                                    ? _collapsedSearch
                                    : _expanded;
                                if (!ids.remove(category.id)) {
                                  ids.add(category.id);
                                }
                              }),
                              tile: (topic) => _tile(deck, topic),
                            ),
                          ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAccordion extends StatelessWidget {
  const _CategoryAccordion({
    super.key,
    required this.name,
    required this.topics,
    required this.expanded,
    required this.onToggle,
    required this.tile,
  });
  final String name;
  final List<Topic> topics;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget Function(Topic) tile;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final cs = Theme.of(context).colorScheme;
    final total = topics.fold(0, (sum, topic) => sum + topic.cardCount);
    final content = expanded
        ? Padding(
            // Sub-entries hang indented off a thin guide line so they read
            // as children of the category header above.
            padding: const EdgeInsets.only(top: 8, left: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: cs.primary.withValues(alpha: .35),
                    width: 2,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Column(
                  children: [for (final topic in topics) tile(topic)],
                ),
              ),
            ),
          )
        : const SizedBox(width: double.infinity);
    return Column(
      children: [
        Semantics(
          expanded: expanded,
          // Category headers are tinted with a gold accent bar so they are
          // clearly distinguishable from the deck tiles inside them.
          child: GoldPanel(
            glow: false,
            highlight: true,
            padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
            onTap: onToggle,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  expanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                  size: 24,
                  color: cs.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: .2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${topics.length} ${topics.length == 1 ? 'Kartensatz' : 'Kartensätze'} · $total ${total == 1 ? 'Karte' : 'Karten'}',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? .5 : 0,
                  duration: duration,
                  child: Icon(Icons.expand_more_rounded, color: cs.primary),
                ),
              ],
            ),
          ),
        ),
        if (MediaQuery.disableAnimationsOf(context))
          content
        else
          AnimatedSize(
            duration: duration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: content,
          ),
      ],
    );
  }
}
