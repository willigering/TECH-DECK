import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/topic_marks.dart';
import '../../data/models/topic.dart';
import '../../state/deck_controller.dart';

Future<void> showTopicMarkSheet(BuildContext context, Topic topic) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _TopicMarkSheet(topicId: topic.id),
  );
}

class _TopicMarkSheet extends StatelessWidget {
  const _TopicMarkSheet({required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    final topic = deck.topicById(topicId);
    if (topic == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Thema nicht gefunden.')),
      );
    }
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.name,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                letterSpacing: 1.6,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: topic.isImportant,
              activeThumbColor: cs.primary,
              title: const Text(
                'Als wichtig markieren',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Wichtige Decks stehen oben und tragen einen Stern.',
              ),
              onChanged: (value) {
                HapticFeedback.selectionClick();
                deck.setTopicMark(topic.id, isImportant: value);
              },
            ),
            const SizedBox(height: 8),
            Text(
              'FARBE',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                letterSpacing: 2.2,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ColorDot(
                  selected: topic.colorKey == null,
                  color: cs.outline,
                  empty: true,
                  tooltip: 'Keine Farbe',
                  onTap: () => deck.setTopicMark(topic.id, clearColor: true),
                ),
                for (final c in TopicMarks.colors)
                  _ColorDot(
                    selected: topic.colorKey == c.key,
                    color: c.color,
                    tooltip: c.label,
                    onTap: () => deck.setTopicMark(topic.id, colorKey: c.key),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.selected,
    required this.color,
    required this.onTap,
    required this.tooltip,
    this.empty = false,
  });

  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: empty ? Colors.transparent : color,
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.onSurface : color,
              width: selected ? 3 : 2,
            ),
          ),
          child: empty
              ? Icon(
                  Icons.block,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: .55),
                )
              : selected
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
