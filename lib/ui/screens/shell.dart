import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/deck_controller.dart';
import '../../state/welcome_controller.dart';
import '../widgets/pcb_background.dart';
import 'instructions_screen.dart';
import 'settings_screen.dart';
import 'start_screen.dart';
import 'welcome_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _mainNavigatorKey = GlobalKey<NavigatorState>();

  Widget _tabNav(Widget child, {Key? key}) => Navigator(
    key: key,
    onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child),
  );

  @override
  Widget build(BuildContext context) {
    final welcome = context.watch<WelcomeController>();
    return Stack(
      children: [
        PcbBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: IndexedStack(
              index: _index,
              children: [
                _tabNav(const StartScreen(), key: _mainNavigatorKey),
                _tabNav(const SettingsScreen()),
                _tabNav(const InstructionsScreen()),
              ],
            ),
            bottomNavigationBar: _BottomBar(
              index: _index,
              onChanged: (i) {
                setState(() => _index = i);
                if (i == 1) context.read<DeckController>().load();
              },
            ),
          ),
        ),
        if (welcome.loading)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(child: CircularProgressIndicator()),
            ),
          )
        else if (welcome.visible)
          Positioned.fill(
            child: WelcomeScreen(
              onContinue: (doNotShowAgain) async {
                setState(() => _index = 0);
                _mainNavigatorKey.currentState?.popUntil(
                  (route) => route.isFirst,
                );
                try {
                  await welcome.dismiss(doNotShowAgain: doNotShowAgain);
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Die Auswahl konnte nicht gespeichert werden. '
                        'Du kannst trotzdem weiterlernen.',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Lernkarten'),
    (Icons.settings_outlined, Icons.settings, 'Einstellungen'),
    (Icons.help_outline_rounded, Icons.help_rounded, 'Anleitung'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .18),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: index == i ? _items[i].$2 : _items[i].$1,
                    label: _items[i].$3,
                    selected: index == i,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurface.withValues(alpha: .48);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 18 : 0,
              height: 2,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.0),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
