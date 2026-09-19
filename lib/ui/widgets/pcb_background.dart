import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/colors.dart';

/// Mainboard-Hintergrund: parallele Bus-Leitungen, Chips, Vias.
/// Keine wandernden Punkte – nur ein minimales Schimmern.
class PcbBackground extends StatefulWidget {
  const PcbBackground({super.key, required this.child});

  final Widget child;

  @override
  State<PcbBackground> createState() => _PcbBackgroundState();
}

class _PcbBackgroundState extends State<PcbBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: TdColors.bg),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _shimmer,
            builder: (context, _) {
              return CustomPaint(
                painter: _BoardPainter(t: _shimmer.value),
                isComplex: true,
              );
            },
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 8 || size.height < 8) return;
    final board = _layout(size);
    final shimmer = 0.78 + 0.22 * (0.5 + 0.5 * sin(t * 2 * pi));

    _drawBuses(canvas, board, shimmer);
    _drawChips(canvas, board, shimmer);
    _drawVias(canvas, board, shimmer);
  }

  void _drawBuses(Canvas canvas, _Board board, double shimmer) {
    final bus = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..color = TdColors.gold.withValues(alpha: 0.16 * shimmer)
      ..strokeWidth = 1.15;
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..color = TdColors.gold.withValues(alpha: 0.08 * shimmer)
      ..strokeWidth = 0.7;

    for (final path in board.thin) {
      canvas.drawPath(path, thin);
    }
    for (final path in board.buses) {
      canvas.drawPath(path, bus);
    }
  }

  void _drawChips(Canvas canvas, _Board board, double shimmer) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..color = TdColors.gold.withValues(alpha: 0.22 * shimmer)
      ..strokeWidth = 1.1;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = TdColors.gold.withValues(alpha: 0.035);
    final pad = Paint()
      ..style = PaintingStyle.fill
      ..color = TdColors.gold.withValues(alpha: 0.28 * shimmer);

    for (final chip in board.chips) {
      canvas.drawRRect(chip.rect, fill);
      canvas.drawRRect(chip.rect, outline);
      for (final p in chip.pads) {
        canvas.drawRect(p, pad);
      }
    }
  }

  void _drawVias(Canvas canvas, _Board board, double shimmer) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = TdColors.gold.withValues(alpha: 0.22 * shimmer);
    final core = Paint()
      ..style = PaintingStyle.fill
      ..color = TdColors.gold.withValues(alpha: 0.10 * shimmer);
    for (final v in board.vias) {
      canvas.drawCircle(v, 2.4, ring);
      canvas.drawCircle(v, 1.0, core);
    }
  }

  static Size? _cachedSize;
  static _Board? _cached;

  _Board _layout(Size size) {
    if (_cached != null && _cachedSize == size) return _cached!;

    final buses = <Path>[];
    final thin = <Path>[];
    final vias = <Offset>[];
    final chips = <_Chip>[];

    final left = size.width * 0.06;
    final right = size.width * 0.94;
    final top = size.height * 0.07;
    final bottom = size.height * 0.93;

    // Parallele horizontale Busse (wie Adress-/Datenbus).
    const busRows = [0.16, 0.34, 0.52, 0.70, 0.86];
    for (final rel in busRows) {
      final y = size.height * rel;
      for (var lane = 0; lane < 4; lane++) {
        final yy = y + lane * 3.2;
        final path = Path()
          ..moveTo(left, yy)
          ..lineTo(right, yy);
        if (lane == 0 || lane == 3) {
          buses.add(path);
        } else {
          thin.add(path);
        }
      }
    }

    // Vertikale Busse an den Rändern.
    const busCols = [0.10, 0.28, 0.50, 0.72, 0.90];
    for (final rel in busCols) {
      final x = size.width * rel;
      for (var lane = 0; lane < 3; lane++) {
        final xx = x + lane * 3.0;
        final path = Path()
          ..moveTo(xx, top)
          ..lineTo(xx, bottom);
        if (lane == 1) {
          buses.add(path);
        } else {
          thin.add(path);
        }
      }
    }

    // 90°-Abzweigungen (Stubs) von Bussen zu Chips.
    void stub(double x0, double y0, double x1, double y1, {bool thick = true}) {
      final path = Path()
        ..moveTo(x0, y0)
        ..lineTo(x1, y0)
        ..lineTo(x1, y1);
      (thick ? buses : thin).add(path);
      vias.add(Offset(x1, y0));
    }

    stub(
      size.width * 0.10,
      size.height * 0.16,
      size.width * 0.18,
      size.height * 0.22,
    );
    stub(
      size.width * 0.90,
      size.height * 0.34,
      size.width * 0.80,
      size.height * 0.28,
    );
    stub(
      size.width * 0.28,
      size.height * 0.52,
      size.width * 0.36,
      size.height * 0.42,
    );
    stub(
      size.width * 0.72,
      size.height * 0.70,
      size.width * 0.64,
      size.height * 0.60,
    );
    stub(
      size.width * 0.50,
      size.height * 0.86,
      size.width * 0.42,
      size.height * 0.78,
      thick: false,
    );
    stub(
      size.width * 0.10,
      size.height * 0.70,
      size.width * 0.20,
      size.height * 0.62,
    );

    chips.add(
      _makeChip(
        Rect.fromCenter(
          center: Offset(size.width * 0.22, size.height * 0.28),
          width: size.width * 0.22,
          height: size.height * 0.10,
        ),
      ),
    );
    chips.add(
      _makeChip(
        Rect.fromCenter(
          center: Offset(size.width * 0.78, size.height * 0.38),
          width: size.width * 0.20,
          height: size.height * 0.12,
        ),
      ),
    );
    chips.add(
      _makeChip(
        Rect.fromCenter(
          center: Offset(size.width * 0.50, size.height * 0.62),
          width: size.width * 0.34,
          height: size.height * 0.11,
        ),
      ),
    );
    chips.add(
      _makeChip(
        Rect.fromCenter(
          center: Offset(size.width * 0.24, size.height * 0.80),
          width: size.width * 0.18,
          height: size.height * 0.08,
        ),
      ),
    );

    // Kreuzungs-Vias auf dem Raster.
    for (final relY in busRows) {
      for (final relX in busCols) {
        vias.add(Offset(size.width * relX, size.height * relY));
      }
    }

    final board = _Board(buses: buses, thin: thin, vias: vias, chips: chips);
    _cachedSize = size;
    _cached = board;
    return board;
  }

  _Chip _makeChip(Rect box) {
    final rect = RRect.fromRectAndRadius(box, const Radius.circular(3));
    final pads = <Rect>[];
    const padW = 3.2;
    const padH = 6.0;
    final count = max(4, (box.width / 14).floor());
    final gap = box.width / (count + 1);
    for (var i = 1; i <= count; i++) {
      final x = box.left + gap * i - padW / 2;
      pads.add(Rect.fromLTWH(x, box.top - 3, padW, padH));
      pads.add(Rect.fromLTWH(x, box.bottom - 3, padW, padH));
    }
    return _Chip(rect: rect, pads: pads);
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => oldDelegate.t != t;
}

class _Board {
  const _Board({
    required this.buses,
    required this.thin,
    required this.vias,
    required this.chips,
  });

  final List<Path> buses;
  final List<Path> thin;
  final List<Offset> vias;
  final List<_Chip> chips;
}

class _Chip {
  const _Chip({required this.rect, required this.pads});

  final RRect rect;
  final List<Rect> pads;
}
