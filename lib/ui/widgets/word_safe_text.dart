import 'package:flutter/material.dart';

/// Wrap only between words; exceptionally wide words scale to fit intact.
class WordSafeText extends StatelessWidget {
  const WordSafeText({super.key, required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in text.split('\n'))
            if (line.trim().isEmpty)
              SizedBox(height: (style.fontSize ?? 20) * (style.height ?? 1.35))
            else
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final word in line.trim().split(RegExp(r'\s+')))
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('$word ', softWrap: false, style: style),
                      ),
                    ),
                ],
              ),
        ],
      ),
    );
  }
}
