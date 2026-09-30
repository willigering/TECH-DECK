import 'package:flutter/material.dart';

import '../../core/topic_marks.dart';
import '../../data/models/topic.dart';
import 'gold_button.dart';

class TopicTile extends StatelessWidget {
  const TopicTile({
    super.key,
    required this.topic,
    required this.onTap,
    this.onLongPress,
    this.trailing,
    this.showExtension = false,
  });

  final Topic topic;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool showExtension;

  IconData get _icon {
    final name = topic.name.toLowerCase();
    if (name.contains('klausur') || name.contains('prüfung')) {
      return Icons.school_outlined;
    }
    if (name.contains('hardware')) return Icons.memory_outlined;
    if (name.contains('betriebssystem')) return Icons.computer_outlined;
    if (name.contains('netzwerk') ||
        name.contains('ipv4') ||
        name.contains('ipv6')) {
      return Icons.lan_outlined;
    }
    if (name.contains('sicherheit')) return Icons.shield_outlined;
    if (name.contains('datenbank') || name.contains('sql')) {
      return Icons.storage_outlined;
    }
    if (name.contains('programmierung') || name.contains('skripting')) {
      return Icons.code_rounded;
    }
    if (name.contains('virtualisierung') || name.contains('cloud')) {
      return Icons.cloud_outlined;
    }
    if (name.contains('web')) return Icons.language_outlined;
    if (name.contains('backup') ||
        name.contains('monitoring') ||
        name.contains('logging')) {
      return Icons.backup_outlined;
    }
    if (name.contains('service')) return Icons.support_agent_outlined;
    if (name.contains('datenschutz') || name.contains('recht')) {
      return Icons.gavel_outlined;
    }
    return Icons.menu_book_outlined;
  }

  String get _label {
    if (showExtension) {
      final src = topic.sourceFilename.trim();
      if (src.isNotEmpty) return src;
    }
    return topic.name;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mark = TopicMarks.colorOf(topic.colorKey);
    final accent = mark ?? cs.primary;
    return GoldPanel(
      onTap: onTap,
      onLongPress: onLongPress,
      accent: mark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (mark != null) ...[
            Container(
              width: 4,
              height: 38,
              decoration: BoxDecoration(
                color: mark,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Icon(_icon, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 17,
                fontWeight: topic.isImportant
                    ? FontWeight.w700
                    : FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          if (topic.isImportant) ...[
            Icon(Icons.star_rounded, color: accent, size: 20),
            const SizedBox(width: 6),
          ],
          Text(
            '${topic.cardCount} ${topic.cardCount == 1 ? 'Karte' : 'Karten'}',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          const SizedBox(width: 6),
          trailing ??
              Icon(Icons.chevron_right_rounded, color: accent, size: 22),
        ],
      ),
    );
  }
}
