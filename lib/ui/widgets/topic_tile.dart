import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../data/models/topic.dart';
import 'gold_button.dart';

class TopicTile extends StatelessWidget {
  const TopicTile({
    super.key,
    required this.topic,
    required this.onTap,
    this.trailing,
    this.showExtension = true,
  });

  final Topic topic;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showExtension;

  String get _label {
    if (showExtension) {
      final src = topic.sourceFilename.trim();
      if (src.isNotEmpty) return src;
    }
    return topic.name;
  }

  @override
  Widget build(BuildContext context) {
    return GoldPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: TdColors.gold,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: TdColors.text,
              ),
            ),
          ),
          Text(
            '${topic.cardCount} ${topic.cardCount == 1 ? 'Karte' : 'Karten'}',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TdColors.gold,
            ),
          ),
          const SizedBox(width: 6),
          trailing ??
              const Icon(
                Icons.chevron_right_rounded,
                color: TdColors.gold,
                size: 22,
              ),
        ],
      ),
    );
  }
}
