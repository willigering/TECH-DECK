import 'dart:math' as math;

import 'package:flutter/material.dart';


class TdLogo extends StatelessWidget {
  const TdLogo({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _TdLogoPainter(Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _TdLogoPainter extends CustomPainter {
  const _TdLogoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(s / 100, s / 100);

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = color;
    const c = Offset(50, 50);
    const r = 32.5;

    canvas.drawCircle(c, r, line);

    const angles = [-110,-98,-86,-74,-62,-24,-12,0,12,24,62,74,86,98,110,156,168,180,192,204];
    for (final deg in angles) {
      final a = deg * math.pi / 180;
      final p1 = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      final p2 = Offset(c.dx + math.cos(a) * 40.5, c.dy + math.sin(a) * 40.5);
      canvas.drawLine(p1, p2, line);
      canvas.drawCircle(p2, 1.35, dot);
    }

    Path brain(bool left) {
      final x = left ? 1.0 : -1.0;
      Offset p(double dx, double dy) => Offset(50 - x * dx, dy);
      return Path()
        ..moveTo(p(4,31).dx,p(4,31).dy)
        ..cubicTo(p(10,27).dx,p(10,27).dy,p(14,31).dx,p(14,31).dy,p(14,36).dx,p(14,36).dy)
        ..cubicTo(p(22,34).dx,p(22,34).dy,p(25,40).dx,p(25,40).dy,p(23,45).dx,p(23,45).dy)
        ..cubicTo(p(29,49).dx,p(29,49).dy,p(26,57).dx,p(26,57).dy,p(22,58).dx,p(22,58).dy)
        ..cubicTo(p(25,65).dx,p(25,65).dy,p(19,70).dx,p(19,70).dy,p(14,67).dx,p(14,67).dy)
        ..cubicTo(p(14,74).dx,p(14,74).dy,p(7,76).dx,p(7,76).dy,p(4,70).dx,p(4,70).dy)
        ..close();
    }
    canvas.drawPath(brain(true), line);
    canvas.drawPath(brain(false), line);
    canvas.drawLine(const Offset(46,32), const Offset(46,69), line);
    canvas.drawLine(const Offset(54,32), const Offset(54,69), line);

    void trace(List<Offset> pts) {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i=1;i<pts.length;i++) {
        final prev=pts[i-1], cur=pts[i];
        p.quadraticBezierTo((prev.dx+cur.dx)/2, prev.dy, cur.dx, cur.dy);
      }
      canvas.drawPath(p,line);
      canvas.drawCircle(pts.first,1.25,dot);
      canvas.drawCircle(pts.last,1.25,dot);
    }
    trace(const [Offset(42,38),Offset(38,40),Offset(37,44),Offset(41,46)]);
    trace(const [Offset(34,48),Offset(37,52),Offset(42,52)]);
    trace(const [Offset(42,59),Offset(38,60),Offset(37,64)]);
    trace(const [Offset(58,38),Offset(62,40),Offset(63,44),Offset(59,46)]);
    trace(const [Offset(66,48),Offset(63,52),Offset(58,52)]);
    trace(const [Offset(58,59),Offset(62,60),Offset(63,64)]);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TdLogoPainter oldDelegate) => oldDelegate.color != color;
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
