import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final bool filled, expand, enabled;
  final double height;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = enabled && onTap != null;
    final radius = BorderRadius.circular(16);
    final fg = filled && active ? cs.onPrimary : cs.primary;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: filled && active
            ? cs.primary
            : cs.surface.withValues(alpha: .72),
        border: Border.all(
          color: active ? cs.primary : cs.outline.withValues(alpha: .45),
          width: 1.2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: cs.primary.withValues(alpha: filled ? .06 : .03),
                  blurRadius: filled ? 8 : 4,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                letterSpacing: .4,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
    return Opacity(
      opacity: active ? 1 : .38,
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
    this.onLongPress,
    this.padding = const EdgeInsets.all(18),
    this.glow = true,
    this.highlight = false,
    this.accent,
  });
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsets padding;
  final bool glow;
  final bool highlight;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final line = accent ?? cs.primary;
    final panel = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: highlight ? Color.alphaBlend(line.withValues(alpha: .09), cs.surface) : cs.surface.withValues(alpha: .92),
        border: Border.all(color: line.withValues(alpha: highlight ? .65 : .24), width: 1.05),
        boxShadow: glow
            ? [BoxShadow(color: line.withValues(alpha: highlight ? .22 : .035), blurRadius: highlight ? 22 : 16)]
            : null,
      ),
      child: child,
    );
    if (onTap == null && onLongPress == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: cs.primary.withValues(alpha: .16),
        boxShadow: [
          BoxShadow(color: cs.primary.withValues(alpha: .03), blurRadius: 8),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value.clamp(0, 1).toDouble()),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) => LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.transparent,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}
