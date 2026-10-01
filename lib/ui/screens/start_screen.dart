import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import '../widgets/word_safe_text.dart';
import 'topic_picker_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: TopicPickerScreen.routeName),
        builder: (_) => const TopicPickerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    final empty = !deck.loading && deck.topics.isEmpty;
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandHeader(compact: true, showLogo: true),
                      const SizedBox(height: 24),
                      WordSafeText(
                        text: 'Wissen rein.\nBrett vorm Kopf raus.',
                        style: theme.textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      WordSafeText(
                        text:
                            'Willkommen bei TECH//DECK. Hier lernst du Karte '
                            'für Karte für deine Prüfung. Auch die Sachen, bei '
                            'denen du im Unterricht noch überzeugt genickt hast.',
                        style: theme.textTheme.bodyLarge!,
                      ),
                      const SizedBox(height: 28),
                      const GoldPanel(
                        glow: false,
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _WelcomeStep(
                              icon: Icons.menu_book_outlined,
                              title: 'Deck wählen',
                              text:
                                  'Such dir ein Thema aus. Die mitgelieferten '
                                  'Decks warten schon auf ihren großen Auftritt.',
                            ),
                            SizedBox(height: 24),
                            _WelcomeStep(
                              icon: Icons.flip_outlined,
                              title: 'Erst denken. Dann drehen.',
                              text:
                                  'Lies die Frage und überleg dir die Antwort. '
                                  'Dreh die Karte um und schau nach. Kommt dir '
                                  'bekannt vor? Gut. Hast du’s gewusst? Noch besser.',
                            ),
                            SizedBox(height: 24),
                            _WelcomeStep(
                              icon: Icons.file_upload_outlined,
                              title: 'Eigene Karten mitbringen',
                              text:
                                  'Du kannst zusätzliche Decks als CSV '
                                  'importieren. So bekommt auch dein nächstes '
                                  'Prüfungsthema einen eigenen Kartenstapel.',
                            ),
                            SizedBox(height: 24),
                            _WelcomeStep(
                              icon: Icons.palette_outlined,
                              title: 'Mach’s dir passend',
                              text:
                                  'Wähle in den Einstellungen dein '
                                  'Lieblingsdesign. Lernen darf wenigstens '
                                  'gut aussehen.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      WordSafeText(
                        text:
                            'Kleine Runde reicht. Du musst heute nicht '
                            'das gesamte Internet verstehen.',
                        style: theme.textTheme.bodyMedium!,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (deck.loading) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 12),
                    ],
                    if (empty) ...[
                      Text(
                        'Noch keine Themen. Lernkarten unter Einstellungen '
                        'importieren.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                    ],
                    GoldButton(
                      label: 'Na gut, ich lerne.',
                      icon: Icons.arrow_forward_rounded,
                      onTap: deck.loading || empty
                          ? null
                          : () => _open(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WordSafeText(
                text: title,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              WordSafeText(text: text, style: theme.textTheme.bodyMedium!),
            ],
          ),
        ),
      ],
    );
  }
}
