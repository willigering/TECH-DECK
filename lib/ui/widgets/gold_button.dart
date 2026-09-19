import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';

class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
    this.expand = true,
    this.enabled = true,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool filled;
  final bool expand;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onTap != null;
    final radius = BorderRadius.circular(16);
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: filled && active
            ? TdColors.gold
            : Colors.black.withValues(alpha: 0.45),
        border: Border.all(
          color: active ? TdColors.gold : TdColors.goldDim.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: TdColors.gold.withValues(alpha: filled ? 0.38 : 0.18),
                  blurRadius: filled ? 18 : 12,
                  spreadRadius: filled ? 0.4 : 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: filled && active ? Colors.black : TdColors.gold,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 13,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
                color: filled && active ? Colors.black : TdColors.gold,
              ),
            ),
          ),
        ],
      ),
    );

    return Opacity(
      opacity: active ? 1 : 0.38,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: active
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!();
                }
              : null,
          borderRadius: radius,
          child: child,
        ),
      ),
    );
  }
}

class GoldPanel extends StatelessWidget {
  const GoldPanel({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.glow = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xE6050505),
        border: Border.all(color: TdColors.gold, width: 1.05),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: TdColors.gold.withValues(alpha: 0.16),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: panel,
      ),
    );
  }
}

class GoldProgressBar extends StatelessWidget {
  const GoldProgressBar({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: TdColors.goldDeep,
        boxShadow: [
          BoxShadow(
            color: TdColors.gold.withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 6,
          backgroundColor: Colors.transparent,
          color: TdColors.gold,
        ),
      ),
    );
  }
}
