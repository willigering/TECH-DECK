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
                    const Expanded(
                      child: SingleChildScrollView(
                        primary: false,
                        child: _WelcomeContent(),
                      ),
                    ),
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
                              style: theme.textTheme.bodyMedium,
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
                        child: const Text('Na gut, ich lerne.'),
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
const _icons = [
  Icons.menu_book_outlined,
  Icons.flip_outlined,
  Icons.file_upload_outlined,
  Icons.palette_outlined,
];

/// Readable, scrollable introduction with the brand symbol in the top-right.
class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'TECH//DECK',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'Orbitron',
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const TdLogo(size: 56),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Wissen rein.\\nBrett vorm Kopf raus.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          Text(_intro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 28),
          for (var i = 0; i < _titles.length; i++) ...[
            if (i > 0) const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icons[i], size: 24, color: cs.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titles[i],
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_details[i], style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 28),
          Text(_outro, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
