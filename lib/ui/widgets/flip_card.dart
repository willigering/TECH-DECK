import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'word_safe_text.dart';

class FlipStudyCard extends StatefulWidget {
  const FlipStudyCard({
    super.key,
    required this.question,
    required this.answer,
    required this.flipped,
    required this.onFlip,
  });

  final String question;
  final String answer;
  final bool flipped;
  final VoidCallback onFlip;

  @override
  State<FlipStudyCard> createState() => _FlipStudyCardState();
}

class _FlipStudyCardState extends State<FlipStudyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.flipped ? 1 : 0,
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(covariant FlipStudyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question ||
        oldWidget.answer != widget.answer) {
      _controller.value = widget.flipped ? 1 : 0;
      return;
    }
    if (widget.flipped != oldWidget.flipped) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = widget.flipped ? 1 : 0;
        return;
      }
      if (widget.flipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = widget.flipped ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onFlip();
      },
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final value = _anim.value;
          final isBack = value > 0.5;
          final angle = value * math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0009)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _Face(body: widget.answer, back: true),
                  )
                : _Face(body: widget.question, back: false),
          );
        },
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.body, required this.back});

  final String body;
  final bool back;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .96),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: back ? .18 : .12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          child: WordSafeText(
            text: body,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              fontSize: back ? 20 : 26,
              height: 1.35,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
