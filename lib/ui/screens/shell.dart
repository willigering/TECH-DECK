import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/colors.dart';
import '../../state/deck_controller.dart';
import '../widgets/pcb_background.dart';
import 'info_screen.dart';
import 'settings_screen.dart';
import 'start_screen.dart';
import 'stats_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  Widget _tabNav(Widget child) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PcbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _index,
          children: [
            _tabNav(const StartScreen()),
            _tabNav(const StatsScreen()),
            _tabNav(const SettingsScreen()),
            _tabNav(const InfoScreen()),
          ],
        ),
        bottomNavigationBar: _BottomBar(
          index: _index,
          onChanged: (i) {
            setState(() => _index = i);
            if (i == 1) {
              context.read<DeckController>().load();
            }
          },
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Start'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Statistik'),
    (Icons.settings_outlined, Icons.settings, 'Einstellungen'),
    (Icons.info_outline, Icons.info, 'Info'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TdColors.bgElevated,
        border: Border(top: BorderSide(color: TdColors.goldLine)),
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
    final color = selected ? TdColors.goldBright : TdColors.textDim;
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
                color: TdColors.gold,
                borderRadius: BorderRadius.circular(2),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: TdColors.gold.withValues(alpha: 0.6),
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
                fontFamily: 'Rajdhani',
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
