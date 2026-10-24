import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../theme/og_colors.dart';
import '../theme/og_text.dart';

/// Brief confirmation pill near the bottom of the screen ("Link copied").
/// Announced to VoiceOver; fades away on its own.
void showOgToast(BuildContext context, String message, {bool error = false}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final c = context.og;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _Toast(
      message: message,
      color: error ? c.error : c.inverseCard,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    TextDirection.ltr,
  );
  if (error) HapticFeedback.heavyImpact();
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.color,
    required this.onDone,
  });

  final String message;
  final Color color;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _c.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 96;
    return Positioned(
      left: 24,
      right: 24,
      bottom: bottom,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _c,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x331C1F23),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              // The root overlay sits above any Material, so without this the
              // text falls back to the debug underlined style.
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: OgText.body(
                    15,
                    weight: FontWeight.w600,
                    color: OgColors.offWhite,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
