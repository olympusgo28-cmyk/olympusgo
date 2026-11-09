import 'package:flutter/cupertino.dart';

import '../theme/og_colors.dart';
import 'og_icon.dart';
import 'og_kit.dart';
import 'pressable.dart';
import '../../core/theme/og_type.dart';

enum OgButtonStyle { primary, outline }

/// Pill button from the design: 56px tall, 20px Baloo 2 label.
class OgButton extends StatelessWidget {
  const OgButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = OgButtonStyle.primary,
    this.loading = false,
    this.height = 56,
    this.icon,
    this.expand = true,
    this.outlineColor,
  });

  const OgButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 56,
    this.icon,
    this.expand = true,
    this.outlineColor,
  }) : style = OgButtonStyle.outline;

  final String label;
  final VoidCallback? onPressed;
  final OgButtonStyle style;
  final bool loading;
  final double height;
  final String? icon;
  final bool expand;

  /// Overrides the outline colour (the Scan screen uses bright orange).
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final primary = style == OgButtonStyle.primary;
    final fg = primary ? c.onPrimary : (outlineColor ?? c.text);
    final content = loading
        ? CupertinoActivityIndicator(color: fg)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                OgIcon(icon!, size: 20, color: fg, strokeWidth: 2.2),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: context.type.button.copyWith(color: fg, height: 1.2),
                ),
              ),
            ],
          );
    return Pressable(
      onPressed: loading ? null : onPressed,
      dimWhenDisabled: !loading,
      haptic: primary,
      semanticLabel: label,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // The darker orange: white 15 Regular needs 4.5:1 (Q257).
          color: primary ? c.primarySmall : null,
          borderRadius: BorderRadius.circular(height / 2),
          border: primary
              ? null
              : Border.all(color: outlineColor ?? c.text, width: 2),
        ),
        child: ExcludeSemantics(child: content),
      ),
    );
  }
}

/// Outlined row button with a leading icon, used for the alternative
/// sign-in methods ("Unlock with Face ID", "Log in with phone").
class OgMethodButton extends StatelessWidget {
  const OgMethodButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: c.text, width: 2),
        ),
        child: Row(
          children: [
            OgIcon(icon, size: 22, color: c.text),
            const SizedBox(width: 12),
            // Shrinks rather than spilling over at large text sizes.
            Flexible(
              child: ExcludeSemantics(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Underlined orange text link with a 44px tap target.
class OgTextLink extends StatelessWidget {
  const OgTextLink(
    this.label, {
    super.key,
    required this.onPressed,
    this.color,
    this.align = Alignment.center,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Alignment align;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.og.link;
    return Pressable(
      onPressed: onPressed,
      isButton: false,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: align,
        child: ExcludeSemantics(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: context.type.button.copyWith(
              color: fg,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}

/// The 44×44 back chevron in the top-left of every flow screen.
class OgBackButton extends StatelessWidget {
  const OgBackButton({super.key, this.onPressed, this.color});

  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Transform.translate(
        offset: const Offset(-10, 0),
        child: KitBack(onPressed: onPressed, color: color),
      ),
    );
  }
}
