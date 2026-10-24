import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/breadcrumbs.dart';
import '../theme/og_colors.dart';
import '../theme/og_text.dart';
import 'og_buttons.dart';
import 'og_kit.dart';

/// Layout used by every full-screen flow step in the design: 24px side
/// padding, content from the top, actions pinned to the bottom. It scrolls
/// when the keyboard or a large text size needs more room, so nothing clips.
class OgFlowScreen extends StatelessWidget {
  const OgFlowScreen({
    super.key,
    required this.children,
    this.bottom = const [],
    this.background,
    this.dark = false,
    this.padTop = 56,
    this.padBottom = 32,
    this.fillGap = true,
    this.asPage = false,
  });

  /// Shows the page in the current design: a header bar with the title,
  /// back label and breadcrumbs, taken from a leading [OgBackButton] and
  /// [OgHeading] in [children].
  final bool asPage;

  /// False when [children] contain their own [Expanded] that should take the
  /// free space instead of the gap above [bottom].
  final bool fillGap;

  final List<Widget> children;
  final List<Widget> bottom;
  final Color? background;

  /// Dark screens (splash, "You're in") get light status bar text.
  final bool dark;
  final double padTop;
  final double padBottom;

  Widget _page(BuildContext context) {
    final c = context.og;
    final rest = [...children];
    VoidCallback? onBack;
    if (rest.isNotEmpty && rest.first is OgBackButton) {
      onBack = (rest.removeAt(0) as OgBackButton).onPressed;
    }
    while (rest.isNotEmpty &&
        rest.first is SizedBox &&
        (rest.first as SizedBox).child == null) {
      rest.removeAt(0);
    }
    var title = '';
    String? lead;
    Widget? leading;
    if (rest.isNotEmpty && rest.first is OgHeading) {
      final h = rest.removeAt(0) as OgHeading;
      title = h.title;
      lead = h.lead;
      leading = h.leading;
    }
    return KitScaffold(
      header: KitHeader(title: title, onBack: onBack),
      gap: 0,
      background: background,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      bottom: bottom.isEmpty ? null : bottom,
      children: [
        if (leading != null) ...[leading, const SizedBox(height: 12)],
        if (lead != null) ...[
          Text(lead, style: OgText.body(15, height: 1.45, color: c.textMuted)),
          const SizedBox(height: 8),
        ],
        ...rest,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (asPage) return _page(context);
    final c = context.og;
    final mq = MediaQuery.of(context);
    final top = math.max(padTop, mq.padding.top + 4);
    final bottomPad = math.max(padBottom, mq.padding.bottom + 8);
    final isDark = dark || Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: background ?? c.bg,
        body: Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, top, 24, bottomPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...children,
                        if (fillGap) const Spacer(),
                        if (bottom.isNotEmpty) const SizedBox(height: 12),
                        ...bottom,
                      ],
                    ),
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

/// Title, optional progress bar, and intro paragraph block.
class OgHeading extends StatelessWidget {
  const OgHeading({
    super.key,
    required this.title,
    this.lead,
    this.step,
    this.topGap = 24,
    this.leading,
  });

  final String title;
  final String? lead;

  /// 1-based onboarding step out of 7, shown as a segmented bar.
  final int? step;
  final double topGap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    Crumbs.name(context, title);
    final titleText = Semantics(
      header: true,
      child: Text(title, style: OgText.h1.copyWith(color: c.text)),
    );
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (leading != null)
            Row(
              children: [
                leading!,
                const SizedBox(width: 14),
                Expanded(child: titleText),
              ],
            )
          else
            titleText,
          if (step != null) ...[
            const SizedBox(height: 12),
            StepProgress(step: step!),
          ],
          if (lead != null) ...[
            const SizedBox(height: 12),
            Text(lead!, style: OgText.lead(c.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// Segmented onboarding progress bar.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, this.total = 7});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      label: 'Step $step of $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 6,
                decoration: BoxDecoration(
                  color: i < step ? c.primary : c.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Inline error line with an icon, per the design system's error rule.
class OgErrorText extends StatelessWidget {
  const OgErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: c.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: OgText.body(
                  14,
                  weight: FontWeight.w600,
                  color: c.error,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round charcoal badge with an orange icon (recovery sent, parent approval).
class OgIconBadge extends StatelessWidget {
  const OgIconBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: OgColors.charcoal900,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
