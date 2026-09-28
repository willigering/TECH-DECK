import 'package:flutter/material.dart';

/// Feste Farbmarkierungen für Kartendecks.
class TopicColor {
  const TopicColor({required this.key, required this.label, required this.color});

  final String key;
  final String label;
  final Color color;
}

abstract final class TopicMarks {
  static const examKey = 'exam';

  static const colors = <TopicColor>[
    TopicColor(key: examKey, label: 'Rot', color: Color(0xFFE53935)),
    TopicColor(key: 'orange', label: 'Orange', color: Color(0xFFFB8C00)),
    TopicColor(key: 'gold', label: 'Gold', color: Color(0xFFFFC107)),
    TopicColor(key: 'green', label: 'Grün', color: Color(0xFF43A047)),
    TopicColor(key: 'teal', label: 'Türkis', color: Color(0xFF00897B)),
    TopicColor(key: 'blue', label: 'Blau', color: Color(0xFF1E88E5)),
    TopicColor(key: 'violet', label: 'Violett', color: Color(0xFF8E24AA)),
    TopicColor(key: 'pink', label: 'Pink', color: Color(0xFFD81B60)),
  ];

  static TopicColor? byKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final c in colors) {
      if (c.key == key) return c;
    }
    return null;
  }

  static Color? colorOf(String? key) => byKey(key)?.color;
}
