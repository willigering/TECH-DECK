import 'package:flutter/material.dart';
import 'package:hyphenatorx/hyphenatorx.dart';
import 'package:hyphenatorx/languages/language_de_1996.dart';

/// German hyphenation with a fixed font size and explicit line-end hyphens.
class WordSafeText extends StatelessWidget {
  const WordSafeText({super.key, required this.text, required this.style});
  final String text;
  final TextStyle style;
  static final _german = Hyphenator(Language_de_1996());

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
