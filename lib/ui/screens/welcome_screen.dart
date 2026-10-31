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
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    const Expanded(child: _WelcomeContent()),
                    const SizedBox(height: 4),
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
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
                        child: const Text('Na schön, mach mich schlau!'),
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

const _intro = 'Karte für Karte für deine Prüfung. Auch für die Themen, '
    'bei denen du im Unterricht noch überzeugt genickt hast.';
const _outro = 'Kleine Runde reicht. Du musst heute nicht das gesamte '
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
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact = bounds.maxHeight < 620;
        final gap = compact ? 12.0 : 20.0;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('TECH//DECK',
                    maxLines: 1,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'Orbitron',
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                ),
                const TdLogo(size: 42),
              ],
            ),
            SizedBox(height: gap),
            Text('Wissen rein.\nBrett vorm Kopf raus.',
              style: theme.textTheme.titleLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 23,
              ),
            ),
            const SizedBox(height: 10),
            Text(_intro, style: theme.textTheme.bodyMedium),
            SizedBox(height: gap),
            for (var i = 0; i < _titles.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_icons[i], size: 21, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_titles[i],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_details[i], style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: gap),
            Text(_outro, style: theme.textTheme.bodySmall),
          ],
        );
        // Use available space naturally instead of shrinking all typography.
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: content,
          ),
        );
      },
    );
  }
}
