import 'dart:math' as math;

import 'package:flutter/material.dart';


class TdLogo extends StatelessWidget {
  const TdLogo({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * .54,
            height: size * .54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .24),
                  blurRadius: size * .20,
                  spreadRadius: size * .025,
                ),
              ],
            ),
          ),
          Icon(
            Icons.memory_rounded,
            size: size * .62,
            color: accent,
            shadows: [
              Shadow(
                color: accent.withValues(alpha: .58),
                blurRadius: size * .075,
              ),
            ],
          ),
          Icon(
            Icons.school_rounded,
            size: size * .27,
            color: Theme.of(context).colorScheme.surface,
          ),
        ],
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.compact = false, this.showLogo = false});

  final bool compact;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'TECH//DECK',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.w700,
            fontSize: compact ? 22 : 28,
            letterSpacing: compact ? 3 : 5,
            color: Theme.of(context).colorScheme.primary,
            shadows: [
              Shadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.55),
                blurRadius: 22,
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          'LERNE. VERSTEHE. VERBINDE.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: compact ? 9 : 10,
            letterSpacing: compact ? 2.2 : 3.4,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
          ),
        ),
        if (showLogo) ...[
          const SizedBox(height: 10),
          TdLogo(size: compact ? 96 : 176),
        ],
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 13,
            letterSpacing: 2.4,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

class PercentRing extends StatelessWidget {
  const PercentRing({
    super.key,
    required this.percent,
    required this.caption,
    this.size = 168,
  });

  final int percent;
  final String caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(percent / 100, Theme.of(context).colorScheme.primary),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 36,
                  color: Theme.of(context).colorScheme.primary,
                  shadows: [Shadow(color: Theme.of(context).colorScheme.primary, blurRadius: 16)],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.accent);

  final double value;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = accent.withValues(alpha: .16);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = accent;
    canvas.drawCircle(c, r, track);
    final sweep = 2 * math.pi * value.clamp(0, 1);
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glow);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, fill);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value;
}
