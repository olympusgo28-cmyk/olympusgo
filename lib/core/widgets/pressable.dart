import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// iOS-style press feedback: the child dims and shrinks slightly while held,
/// with an optional light haptic on tap. Used under every custom control so
/// they all respond the same way.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.haptic = false,
    this.semanticLabel,
    this.isButton = true,
    this.selected,
    this.dimWhenDisabled = true,
  });

  /// False for a button that is busy rather than unavailable.
  final bool dimWhenDisabled;

  final Widget child;
  final VoidCallback? onPressed;
  final bool haptic;
  final String? semanticLabel;
  final bool isButton;
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: widget.isButton,
      link: !widget.isButton,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled
            ? () {
                if (widget.haptic) HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: !enabled && widget.dimWhenDisabled
              ? 0.45
              : (_down ? 0.7 : 1),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            scale: _down ? 0.97 : 1,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
