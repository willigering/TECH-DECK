import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/welcome_controller.dart';
import '../widgets/brand.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.onContinue});
  final ValueChanged<bool> onContinue;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late bool _doNotShowAgain;

  @override
  void initState() {
    super.initState();
    _doNotShowAgain = context.read<WelcomeController>().doNotShowAgain;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    const Expanded(child: _WelcomeContent()),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _doNotShowAgain,
                          onChanged: (value) =>
                              setState(() => _doNotShowAgain = value ?? true),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _doNotShowAgain = !_doNotShowAgain,
                            ),
                            child: Text(
                              'Nicht wieder anzeigen',
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => widget.onContinue(_doNotShowAgain),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Na gut, ich lerne.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _intro =
    'Willkommen bei TECH//DECK. Hier lernst du Karte für Karte '
    'für deine Prüfung. Auch die Sachen, bei denen du im Unterricht '
    'noch überzeugt genickt hast.';
const _outro =
    'Kleine Runde reicht. Du musst heute nicht das gesamte '
    'Internet verstehen.';
const _titles = [
  'Deck wählen',
  'Erst denken. Dann drehen.',
  'Eigene Karten mitbringen',
  'Mach’s dir passend',
];
const _details = [
  'Such dir ein Thema aus. Die mitgelieferten Decks warten schon '
      'auf ihren großen Auftritt.',
  'Lies die Frage und überleg dir die Antwort. Dreh die Karte um und '
      'schau nach. Kommt dir bekannt vor? Gut. Hast du’s gewusst? Noch besser.',
  'Du kannst zusätzliche Decks als CSV importieren. So bekommt auch '
      'dein nächstes Prüfungsthema einen eigenen Kartenstapel.',
  'Wähle in den Einstellungen dein Lieblingsdesign. Lernen darf '
      'wenigstens gut aussehen.',
];
const _shortDetails = [
  'Thema wählen. Die Decks warten schon.',
  'Überlegen, dann aufdecken. Gewusst? Noch besser.',
  'CSV-Decks in den Einstellungen importieren.',
  'Design in den Einstellungen wählen.',
];
const _icons = [
  Icons.menu_book_outlined,
  Icons.flip_outlined,
  Icons.file_upload_outlined,
  Icons.palette_outlined,
];

/// Measure complete paragraphs before choosing one uniform typography size.
/// Short screens use concise copy and landscape uses two columns, never scroll.
class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 500;
        final showLogo = constraints.maxHeight >= 300;
        final width = wide
            ? (constraints.maxWidth - 28) / 2
            : constraints.maxWidth;
        double measure(String text, TextStyle style, double availableWidth) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout(maxWidth: availableWidth);
          final height = painter.height;
          painter.dispose();
          return height;
        }

        TextStyle bodyStyle(double size) =>
            theme.textTheme.bodyMedium!.copyWith(fontSize: size, height: 1.25);
        TextStyle titleStyle(double size) => bodyStyle(size).copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        );
        TextStyle headlineStyle(double size) => bodyStyle(size).copyWith(
          fontSize: size + 5,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        );
        double gap(double size) => size >= 14 ? 16 : 10;
        double requiredHeight(double size, bool compact) {
          final spacing = gap(size);
          final intro = compact ? 'Karte für Karte für deine Prüfung.' : _intro;
          final hero =
              measure(
                'TECH//DECK',
                titleStyle(size + 3).copyWith(fontFamily: 'Orbitron'),
                width,
              ) +
              (showLogo ? 48 : 0) +
              spacing +
              measure(
                compact
                    ? 'Wissen rein.\nBrett raus.'
                    : 'Wissen rein.\nBrett vorm Kopf raus.',
                headlineStyle(size),
                width,
              ) +
              8 +
              measure(intro, bodyStyle(size), width);
          var steps = 0.0;
          for (var i = 0; i < 4; i++) {
            steps +=
                measure(_titles[i], titleStyle(size), width - 34) +
                4 +
                measure(
                  (compact ? _shortDetails : _details)[i],
                  bodyStyle(size),
                  width - 34,
                );
          }
          steps += 3 * spacing;
          final outro = measure(_outro, bodyStyle(size), width);
          return wide
              ? (hero > steps ? hero : steps) + spacing + outro
              : hero + spacing + steps + spacing + outro;
        }

        var size = 16.0;
        var compact = false;
        var found = false;
        for (final useCompact in [false, true]) {
          for (var candidate = 16.0; candidate >= 12; candidate -= .5) {
            if (requiredHeight(candidate, useCompact) <=
                constraints.maxHeight) {
              size = candidate;
              compact = useCompact;
              found = true;
              break;
            }
          }
          if (found) break;
        }
        // Small landscape windows or large system text: retain every section.
        if (!found) {
          compact = true;
          size = 12;
          while (size > 4 &&
              requiredHeight(size, compact) > constraints.maxHeight) {
            size -= .5;
          }
        }

        final spacing = gap(size);
        final hero = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TECH//DECK',
              style: titleStyle(size + 3).copyWith(fontFamily: 'Orbitron'),
            ),
            if (showLogo) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: TdLogo(size: 40)),
            ],
            SizedBox(height: spacing),
            Text(
              compact
                  ? 'Wissen rein.\nBrett raus.'
                  : 'Wissen rein.\nBrett vorm Kopf raus.',
              style: headlineStyle(size),
            ),
            const SizedBox(height: 8),
            Text(
              compact ? 'Karte für Karte für deine Prüfung.' : _intro,
              style: bodyStyle(size),
            ),
          ],
        );
        final steps = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_icons[i], size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_titles[i], style: titleStyle(size)),
                        const SizedBox(height: 4),
                        Text(
                          (compact ? _shortDetails : _details)[i],
                          style: bodyStyle(size),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: hero),
                  const SizedBox(width: 28),
                  Expanded(child: steps),
                ],
              )
            else ...[
              hero,
              SizedBox(height: spacing),
              steps,
            ],
            SizedBox(height: spacing),
            Text(_outro, style: bodyStyle(size)),
          ],
        );
      },
    );
  }
}
