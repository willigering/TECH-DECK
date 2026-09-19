import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../state/deck_controller.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';
import 'topic_picker_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _open(BuildContext context, TopicPickerMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: TopicPickerScreen.routeName),
        builder: (_) => TopicPickerScreen(mode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deck = context.watch<DeckController>();
    final empty = !deck.loading && deck.topics.isEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          children: [
            const BrandHeader(showLogo: true),
            const Spacer(),
            if (deck.loading)
              const CircularProgressIndicator(color: TdColors.gold)
            else ...[
              _ModeButton(
                title: 'LERNEN',
                subtitle: 'Karteikarten durchgehen',
                icon: Icons.menu_book_outlined,
                onTap: empty
                    ? null
                    : () => _open(context, TopicPickerMode.learn),
              ),
              const SizedBox(height: 14),
              _ModeButton(
                title: 'QUIZ',
                subtitle: 'Wissen testen',
                icon: Icons.track_changes_outlined,
                onTap: empty
                    ? null
                    : () => _open(context, TopicPickerMode.quiz),
              ),
              if (empty) ...[
                const SizedBox(height: 22),
                const Text(
                  'Noch keine Themen.\nCSV-Dateien unter Einstellungen importieren.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 16,
                    color: TdColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: GoldPanel(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Row(
          children: [
            Icon(icon, size: 34, color: TdColors.gold),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 20,
                    letterSpacing: 2.4,
                    color: TdColors.gold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 15,
                    color: TdColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
