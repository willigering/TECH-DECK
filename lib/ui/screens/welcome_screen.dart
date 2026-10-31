import 'dart:math' as math;

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
          child: LayoutBuilder(
            builder: (context, viewport) {
              // Horizontal margin grows slightly on wider displays.
              final side = viewport.maxWidth >= 600 ? 40.0 : 24.0;
              // Minimum gaps tighten a little on shorter displays so that
              // typical phones need no scrolling; text size never shrinks.
              final density = ((viewport.maxHeight - 560) / 300).clamp(
                0.4,
                1.0,
              );
              const maxContent = 480.0;
              final inset = math.max(
                side,
                (viewport.maxWidth - maxContent) / 2,
              );
              final vertical = viewport.maxHeight < 720 ? 14.0 : 20.0;
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  // At least one full screen tall: spare height is shared
                  // between the flexible gaps; if the content is taller
                  // (small displays, large font sizes) the page scrolls.
                  constraints: BoxConstraints(minHeight: viewport.maxHeight),
                  child: IntrinsicHeight(
                    child: Center(
                      child: ConstrainedBox(
                        // On tablets keep the composition phone-like
                        // instead of stretching it over the whole height.
                        constraints: BoxConstraints(
                          maxHeight: viewport.maxWidth >= 600
                              ? 860
                              : double.infinity,
                        ),
                        child: Padding(
                          // Width is limited via padding (not a max-width
                          // box) so intrinsic text measurement matches the
                          // real line width.
                          padding: EdgeInsets.fromLTRB(
                            inset,
                            vertical,
                            inset,
                            vertical,
                          ),
                          child: _WelcomeContent(
                            density: density,
                            footer: _footer(theme),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _footer(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _doNotShowAgain = !_doNotShowAgain),
          child: SizedBox(
            // Explicit height: the checkbox's 48 px tap target is not reported
            // by intrinsic measurement.
            height: 48,
            child: Row(
              children: [
                Checkbox(
                  value: _doNotShowAgain,
                  onChanged: (value) =>
                      setState(() => _doNotShowAgain = value ?? true),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Nicht wieder anzeigen',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => widget.onContinue(_doNotShowAgain),
          child: const Text(
            'Na schön, mach mich schlau!',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

const _headline = ['Wissen rein.', 'Brett vorm Kopf raus.'];
const _intro =
    'Karte für Karte für deine Prüfung. Auch für die Themen, '
    'bei denen du im Unterricht noch überzeugt genickt hast.';
const _outro =
    'Kleine Runde reicht. Du musst heute nicht das gesamte '
    'Internet verstehen.';
const _titles = [
  'Deck wählen',
  'Erst denken. Dann drehen.',
  'Eigene Karten mitbringen',
];
const _details = [
  'Such dir ein Thema aus. Die Decks warten schon auf ihren großen Auftritt.',
  'Überleg dir die Antwort, dann dreh die Karte um. Kommt dir bekannt vor? '
      'Gut. Hast du’s gewusst? Noch besser.',
  'Importiere eigene CSV-Decks. So bekommt auch DEIN nächstes Prüfungsthema '
      'einen eigenen Kartenstapel.',
];
const _icons = [
  Icons.menu_book_outlined,
  Icons.flip_outlined,
  Icons.file_upload_outlined,
];

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({required this.density, required this.footer});
  final double density;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final body = theme.textTheme.bodyMedium?.color ?? cs.onSurface;
    final detailStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.4,
      color: body.withValues(alpha: .82),
    );
    // A gap with a fixed minimum plus a flexible share of the spare height.
    Widget gap(double min, int flex) => Flexible(
      flex: flex,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: min * density),
        child: const SizedBox.expand(),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'TECH//DECK',
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Orbitron',
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: 1,
                ),
              ),
            ),
            const TdLogo(size: 44),
          ],
        ),
        gap(20, 3),
        // Two explicit lines: the headline can never show an escaped "\n".
        for (final line in _headline)
          Text(
            line,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 26,
              height: 1.2,
            ),
          ),
        const SizedBox(height: 14),
        Text(
          _intro,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 15.5,
            height: 1.45,
          ),
        ),
        gap(22, 3),
        for (var i = 0; i < _titles.length; i++) ...[
          if (i > 0) gap(16, 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(_icons[i], size: 24, color: cs.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titles[i],
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_details[i], style: detailStyle),
                  ],
                ),
              ),
            ],
          ),
        ],
        gap(20, 3),
        Text(_outro, style: detailStyle),
        gap(16, 2),
        footer,
      ],
    );
  }
}
