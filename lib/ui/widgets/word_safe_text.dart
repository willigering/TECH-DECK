import 'package:flutter/material.dart';
import 'package:hyphenatorx/hyphenatorx.dart';
import 'package:hyphenatorx/languages/language_de_1996.dart';

/// German hyphenation with a fixed font size and explicit line-end hyphens.
class WordSafeText extends StatelessWidget {
  const WordSafeText({super.key, required this.text, required this.style});
  final String text;
  final TextStyle style;
  static final _german = Hyphenator(Language_de_1996());

  // Explicit component boundaries supplement German syllable patterns.
  static const _compoundFamilies = <String, List<String>>{
    'datenschutz': ['behörd', 'beauftragt', 'grundverordnung', 'gesetz', 'pflicht', 'regel', 'verletzung', 'konzept', 'maßnahme'],
    'informations': ['sicherheit', 'system', 'technik'],
    'netzwerk': ['adapter', 'adresse', 'anschluss', 'dienst', 'gerät', 'karte', 'protokoll', 'schnittstelle', 'sicherheit', 'verbindung'],
    'betriebssystem': ['kernel', 'komponente', 'funktion', 'version'],
    'zugriffs': ['kontrolle', 'recht', 'schutz', 'berechtigung'],
    'zugangs': ['kontrolle', 'schutz', 'berechtigung'],
    'daten': ['bank', 'schutz', 'sicherung', 'träger', 'übertragung', 'verarbeitung', 'verschlüsselung'],
    'speicher': ['adresse', 'bereich', 'kapazität', 'verwaltung'],
    'sicherheits': ['beauftragt', 'konzept', 'maßnahme', 'richtlinie', 'lücke'],
  };

  static List<int> preferredBreaks(String word) {
    final lower = word.toLowerCase();
    final result = <int>[];
    for (final family in _compoundFamilies.entries) {
      if (lower.startsWith(family.key) &&
          family.value.any((part) => lower.substring(family.key.length).startsWith(part))) {
        result.add(family.key.length);
      }
    }
    return result..sort();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      double width(String value) {
        final painter = TextPainter(
          text: TextSpan(text: value, style: effectiveStyle),
          textDirection: direction,
          textScaler: scaler,
        )..layout();
        final result = painter.width;
        painter.dispose();
        return result;
      }

      final lines = <String>[];
      for (final paragraph in text.split('\n')) {
        var line = '';
        for (final word in paragraph.trim().split(RegExp(r'\s+'))) {
          if (word.isEmpty) continue;
          final candidate = line.isEmpty ? word : '$line $word';
          if (width(candidate) <= constraints.maxWidth) {
            line = candidate;
            continue;
          }
          // Prefer moving a complete word onto the next line.
          if (line.isNotEmpty) {
            lines.add(line);
            line = '';
          }
          var remainder = word;
          while (width(remainder) > constraints.maxWidth) {
            final preferred = preferredBreaks(remainder)
                .where((position) => width('${remainder.substring(0, position)}-') <= constraints.maxWidth)
                .toList();
            if (preferred.isNotEmpty) {
              final position = preferred.last;
              lines.add('${remainder.substring(0, position)}-');
              remainder = remainder.substring(position);
              continue;
            }
            final parts = _german.syllablesWord(remainder);
            var splitAt = 0;
            var prefix = '';
            for (var i = 0; i < parts.length - 1; i++) {
              prefix += parts[i];
              if (width('$prefix-') <= constraints.maxWidth) splitAt = i + 1;
            }
            // Unknown or indivisible terms stay intact and can scroll.
            if (splitAt == 0) break;
            lines.add('${parts.take(splitAt).join()}-');
            remainder = parts.skip(splitAt).join();
          }
          line = remainder;
        }
        lines.add(line);
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Text(
            lines.join('\n'),
            softWrap: false,
            textAlign: TextAlign.center,
            style: effectiveStyle,
          ),
        ),
      );
    });
  }
}
