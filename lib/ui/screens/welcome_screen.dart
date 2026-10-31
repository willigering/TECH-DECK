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
];
const _details = [
  'Such dir ein Thema aus. Die mitgelieferten Decks warten schon '
      'auf ihren großen Auftritt.',
  'Lies die Frage und überleg dir die Antwort. Dreh die Karte um und '
      'schau nach. Kommt dir bekannt vor? Gut. Hast du’s gewusst? Noch besser.',
  'Du kannst zusätzliche Decks als CSV importieren. So bekommt auch '
      'auch DEIN nächstes Prüfungsthema einen eigenen Kartenstapel.',
];
const _icons = [
  Icons.menu_book_outlined,
  Icons.flip_outlined,
  Icons.file_upload_outlined,
];

/// One-screen layout: no scroll, concise copy on short viewports.
class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, bounds) {
        final short = bounds.maxHeight < 760;
        final tiny = bounds.maxHeight < 500;
        final landscape = bounds.maxWidth > bounds.maxHeight;
        final gap = tiny ? 5.0 : (short ? 9.0 : 14.0);
        final titleStyle = theme.textTheme.titleMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
        );
        final hero = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontSize: tiny ? 17 : 22,
                    ),
                  ),
                ),
                TdLogo(size: tiny ? 32 : (short ? 40 : 52)),
              ],
            ),
            SizedBox(height: gap),
            Text(
              tiny ? 'Wissen rein. Brett raus.' : 'Wissen rein.\nBrett vorm Kopf raus.',
              style: theme.textTheme.titleLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: tiny ? 16 : (short ? 19 : 23),
              ),
            ),
            if (!short) ...[
              SizedBox(height: gap),
              Text(_intro, style: theme.textTheme.bodyMedium),
            ] else if (!tiny) ...[
              SizedBox(height: gap / 2),
              Text('Karte für Karte für deine Prüfung.',
                  style: theme.textTheme.bodyMedium),
            ],
          ],
        );
        final steps = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _titles.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_icons[i], size: tiny ? 17 : 20, color: cs.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_titles[i],
                          style: titleStyle?.copyWith(fontSize: tiny ? 12 : 14)),
                        ...[
                          const SizedBox(height: 2),
                          Text(
                            tiny ? _tinyDetails[i] : (short ? _briefDetails[i] : _details[i]),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
        return Padding(
          padding: EdgeInsets.symmetric(vertical: tiny ? 2 : 8),
          child: landscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: hero),
                    const SizedBox(width: 16),
                    Expanded(child: steps),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    hero,
                    SizedBox(height: gap),
                    steps,
                    if (!short) ...[
                      SizedBox(height: gap),
                      Text(_outro, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

const _briefDetails = [
  'Die Decks warten auf ihren großen Auftritt.',
  'Kommt dir bekannt vor? Gut. Gewusst? Noch besser.',
  'Auch DEIN nächstes Prüfungsthema als CSV.',
];

const _tinyDetails = [
  'Deck auswählen.',
  'Kommt dir bekannt vor? Gut.',
  'Auch DEIN Thema als CSV.',
];
