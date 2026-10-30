import 'dart:async';
import 'package:flutter/material.dart';

bool isHalloweenSeason(DateTime date) => date.month == 10 && date.day >= 24;

/// Decorative layer only; the existing home layout and hit targets are intact.
class HalloweenBackground extends StatefulWidget {
  const HalloweenBackground({super.key, required this.child, this.now});
  final Widget child;
  final DateTime Function()? now;

  @override
  State<HalloweenBackground> createState() => _HalloweenBackgroundState();
}

class _HalloweenBackgroundState extends State<HalloweenBackground>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime get _now => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final now = _now;
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(midnight.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _schedule();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _schedule();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      if (isHalloweenSeason(_now))
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: ColoredBox(
                color: Color(0xFF070605),
                child: Transform.translate(
                  // Keep the cat's face clear of the fixed brand header.
                  offset: const Offset(0, 110),
                  child: Image.asset(
                    'assets/seasonal/halloween-lumi.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      widget.child,
    ],
  );
}
