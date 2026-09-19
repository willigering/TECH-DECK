import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/colors.dart';

class TdLogo extends StatelessWidget {
  const TdLogo({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    this.compact = false,
    this.showLogo = false,
  });

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
            color: TdColors.gold,
            shadows: [
              Shadow(
                color: TdColors.gold.withValues(alpha: 0.55),
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
            color: TdColors.textMuted,
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
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 13,
            letterSpacing: 2.4,
            color: TdColors.gold,
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
        painter: _RingPainter(percent / 100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 36,
                  color: TdColors.gold,
                  shadows: [
                    Shadow(color: TdColors.gold, blurRadius: 16),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TdColors.textMuted,
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
  _RingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = TdColors.goldDeep;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = TdColors.gold.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = TdColors.gold;
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
