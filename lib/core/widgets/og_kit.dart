import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../navigation/breadcrumbs.dart';
import '../router/routes.dart';
import '../theme/og_colors.dart';
import '../theme/og_text.dart';
import '../theme/og_tones.dart';
import 'og_icon.dart';
import 'pressable.dart';

/// Building blocks for the club, team, shop and creator artboards (phase 3+).
/// These screens share one layout language: a bordered header with an arrow,
/// 54px buttons with 16px corners, grey notes, check lists and chips.

// ─── Header ────────────────────────────────────────────────────────────────

enum KitLead { back, close, none }

/// The top bar: 44px arrow (or ✕), a title and an optional trailing action.
class KitHeader extends StatelessWidget {
  const KitHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.lead = KitLead.back,
    this.leading,
    this.trailing,
    this.center = true,
    this.border = true,
    this.titleSize = 24,
    this.onBack,
    this.crumb,
  });

  final String title;

  /// The name in the trail and on back buttons, when [title] is generic
  /// ("Venue" on a venue's page).
  final String? crumb;
  final String? subtitle;
  final KitLead lead;

  /// Replaces the arrow, for "Cancel" text buttons.
  final Widget? leading;
  final Widget? trailing;
  final bool center;
  final bool border;
  final double titleSize;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    Crumbs.name(context, crumb ?? title);
    final below = Crumbs.below(context);
    final lead =
        leading ??
        switch (this.lead) {
          KitLead.none => null,
          KitLead.back => KitBack(onPressed: onBack, below: below),
          KitLead.close => KitIconButton(
            icon: OgIcons.close,
            label: 'Close',
            onPressed: onBack ?? () => kitPop(context),
          ),
        };
    final titles = Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: center ? TextAlign.center : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OgText.display(titleSize, height: 1.2, color: c.text),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OgText.body(13, color: c.textMuted),
          ),
      ],
    );
    // The trail shows from two screens deep; one would repeat the back label.
    final trail = this.lead == KitLead.back && below.length >= 2;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, trail ? 0 : 8),
      decoration: BoxDecoration(
        color: c.bg,
        border: border
            ? Border(bottom: BorderSide(color: c.border))
            : const Border(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: subtitle == null ? 48 : 56,
            // Centres the title on the screen when it fits beside a long
            // back label, as iOS does.
            child: NavigationToolbar(
              leading: lead,
              middle: titles,
              trailing: trailing,
              centerMiddle: center,
              middleSpacing: 8,
            ),
          ),
          if (trail) KitTrail(below: below, current: crumb ?? title),
        ],
      ),
    );
  }
}

/// Back arrow with the previous screen's name ("‹ Smash Academy").
class KitBack extends StatelessWidget {
  const KitBack({super.key, this.onPressed, this.below, this.color});

  final VoidCallback? onPressed;

  /// The screens underneath, when the caller has them already.
  final List<Crumb>? below;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.og.text;
    final name = (below ?? Crumbs.below(context)).lastOrNull?.title;
    // Long names don't fit beside a title; iOS says "Back" then too.
    final prev = name == null || name.length > 18 ? null : name;
    return Pressable(
      semanticLabel: prev == null ? 'Back' : 'Back to $prev',
      onPressed: onPressed ?? () => kitPop(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
          maxWidth: 150,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              child: Center(
                child: OgIcon(OgIcons.arrowBack, size: 22, color: fg),
              ),
            ),
            if (prev != null)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    prev,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(15, weight: FontWeight.w600, color: fg),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [KitBack] on a pill, for screens with a coloured header.
class KitBackPill extends StatelessWidget {
  const KitBackPill({
    super.key,
    this.background = Colors.white,
    this.color = OgColors.ink,
  });

  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.only(left: 6, right: 8),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(22),
    ),
    child: KitBack(color: color),
  );
}

/// "Academy › Smash Academy › Juniors L2": each earlier screen is a link
/// back to it; the current screen ends the trail.
class KitTrail extends StatelessWidget {
  const KitTrail({super.key, required this.below, required this.current});

  final List<Crumb> below;
  final String current;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    Widget sep() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OgIcon(OgIcons.chevronRight, size: 14, color: c.textMuted),
    );
    return Semantics(
      container: true,
      label: 'Breadcrumbs',
      child: SizedBox(
        height: 40,
        // Starts scrolled to the end, so the nearest screens show first;
        // a short trail still sits on the left.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: box.maxWidth),
              child: Row(
                children: [
                  for (final cr in below) ...[
                    Pressable(
                      semanticLabel: 'Go to ${cr.title}',
                      onPressed: () => Crumbs.popTo(cr),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          cr.title,
                          style: OgText.body(
                            13,
                            weight: FontWeight.w600,
                            color: c.link,
                          ),
                        ),
                      ),
                    ),
                    sep(),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      current,
                      style: OgText.body(
                        13,
                        weight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pops the current screen, or goes Home when there is nothing to pop.
void kitPop(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(Routes.home);

/// A 44px round icon button.
class KitIconButton extends StatelessWidget {
  const KitIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.background,
    this.color,
    this.size = 22,
    this.strokeWidth = 2,
    this.border = false,
    this.fill = false,
  });

  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? color;
  final double size;
  final double strokeWidth;
  final bool border;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      semanticLabel: label,
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: border ? Border.all(color: c.border) : null,
        ),
        alignment: Alignment.center,
        child: OgIcon(
          icon,
          size: size,
          color: color ?? c.text,
          strokeWidth: strokeWidth,
          fill: fill,
        ),
      ),
    );
  }
}

// ─── Page ──────────────────────────────────────────────────────────────────

/// A full screen: header, scrolling body with 20px gutters, and an optional
/// bottom action bar. Children are spaced by [gap].
class KitScaffold extends StatelessWidget {
  const KitScaffold({
    super.key,
    this.header,
    required this.children,
    this.bottom,
    this.gap = 18,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
    this.background,
    this.overlay,
  });

  final Widget? header;
  final List<Widget> children;
  final List<Widget>? bottom;
  final double gap;
  final EdgeInsets padding;
  final Color? background;

  /// Drawn above everything, for in-page sheets.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      backgroundColor: background ?? context.og.bg,
      body: SafeArea(
        bottom: bottom == null,
        child: Column(
          children: [
            ?header,
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: kitSpaced(children, gap),
                  ),
                ),
              ),
            ),
            if (bottom != null) KitBottomBar(children: bottom!),
          ],
        ),
      ),
    );
    // The page is light (or dark) all the way up, so set the status bar
    // text to match rather than keep a coloured hero's style.
    final body = AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: overlay == null ? page : Stack(children: [page, overlay!]),
    );
    return body;
  }
}

/// Puts [gap] between widgets, like the design's flex `gap`.
List<Widget> kitSpaced(List<Widget> children, double gap) => [
  for (var i = 0; i < children.length; i++) ...[
    if (i > 0) SizedBox(height: gap),
    children[i],
  ],
];

/// The bar of actions pinned under the content.
class KitBottomBar extends StatelessWidget {
  const KitBottomBar({super.key, required this.children, this.gap = 10});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final bottom = math.max(26.0, MediaQuery.of(context).padding.bottom + 8);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
      decoration: BoxDecoration(
        color: context.og.bg,
        border: Border(top: BorderSide(color: context.og.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: kitSpaced(children, gap),
      ),
    );
  }
}

// ─── Buttons ───────────────────────────────────────────────────────────────

enum KitButtonStyle {
  primary,
  outline,
  danger,

  /// White with red text, for Remove and Leave beside a primary action.
  dangerOutline,
  dark,
  disabled,
  gold,
}

/// 54px action button. Disabled buttons keep their label and turn grey,
/// as the artboards show ("Pick a reason to ban").
class KitButton extends StatelessWidget {
  const KitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = KitButtonStyle.primary,
    this.height = 54,
    this.radius = 16,
    this.fontSize = 16,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.padding = 18,
  });

  const KitButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 54,
    this.radius = 16,
    this.fontSize = 16,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.padding = 18,
  }) : style = KitButtonStyle.outline;

  final String label;
  final VoidCallback? onPressed;
  final KitButtonStyle style;
  final double height;
  final double radius;
  final double fontSize;
  final String? icon;
  final bool loading;
  final bool expand;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final off = onPressed == null || style == KitButtonStyle.disabled;
    final (bg, fg, side) = off
        ? (t.disabledFill, t.onDisabledFill, null)
        : switch (style) {
            KitButtonStyle.primary => (c.primary, c.onPrimary, null),
            KitButtonStyle.outline => (
              c.bg,
              c.text,
              BorderSide(color: c.border, width: 1.5),
            ),
            KitButtonStyle.danger => (t.danger, Colors.white, null),
            KitButtonStyle.dangerOutline => (
              c.bg,
              t.dangerText,
              BorderSide(color: c.borderControl, width: 1.5),
            ),
            KitButtonStyle.dark => (c.inverseCard, c.onInverseCard, null),
            KitButtonStyle.gold => (t.gold, t.onGold, null),
            KitButtonStyle.disabled => (t.disabledFill, t.onDisabledFill, null),
          };
    final content = loading
        ? CupertinoActivityIndicator(color: fg)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                OgIcon(icon!, size: 18, color: fg, strokeWidth: 2.4),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OgText.body(
                    fontSize,
                    weight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          );
    return Pressable(
      semanticLabel: label,
      onPressed: off || loading ? null : onPressed,
      dimWhenDisabled: false,
      child: Container(
        height: height,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: padding),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: side == null ? null : Border.fromBorderSide(side),
        ),
        alignment: Alignment.center,
        child: ExcludeSemantics(child: content),
      ),
    );
  }
}

/// A bold orange text action ("Report this club", "Undo").
class KitLink extends StatelessWidget {
  const KitLink(
    this.label, {
    super.key,
    required this.onPressed,
    this.color,
    this.size = 14,
    this.underline = false,
    this.minHeight = 44,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final bool underline;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.og.link;
    return Pressable(
      semanticLabel: label,
      onPressed: onPressed,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: 1,
          child: ExcludeSemantics(
            child: Text(
              label,
              style: OgText.body(
                size,
                weight: FontWeight.w600,
                color: fg,
                decoration: underline ? TextDecoration.underline : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chips and tags ────────────────────────────────────────────────────────

/// 40px filter chip; selected chips turn charcoal.
class KitChip extends StatelessWidget {
  const KitChip({
    super.key,
    required this.label,
    this.selected = false,
    required this.onTap,
    this.icon,
    this.trailingIcon,
    this.height = 40,
    this.fontSize = 14,
    this.background,
    this.foreground,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? icon;
  final String? trailingIcon;
  final double height;
  final double fontSize;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final bg = background ?? (selected ? c.text : c.bg);
    final fg = foreground ?? (selected ? c.bg : c.text);
    return Pressable(
      semanticLabel: label,
      selected: selected,
      onPressed: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: background ?? (selected ? c.text : c.border),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              OgIcon(icon!, size: 18, color: fg, strokeWidth: 1.9),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: OgText.body(fontSize, weight: FontWeight.w600, color: fg),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 6),
              OgIcon(trailingIcon!, size: 16, color: fg, strokeWidth: 2.2),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small rounded tag ("Private", "LI–HI", "Pinned").
class KitTag extends StatelessWidget {
  const KitTag(
    this.label, {
    super.key,
    this.background,
    this.foreground,
    this.height = 26,
    this.fontSize = 12,
    this.radius,
  });

  final String label;
  final Color? background;
  final Color? foreground;
  final double height;
  final double fontSize;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height < 24 ? 8 : 10),
      decoration: BoxDecoration(
        color: background ?? t.soft,
        borderRadius: BorderRadius.circular(radius ?? height / 2),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          style: OgText.body(
            fontSize,
            weight: FontWeight.w600,
            color: foreground ?? context.og.text,
          ),
        ),
      ),
    );
  }
}

/// Red count bubble for unread messages and requests.
class KitCountBadge extends StatelessWidget {
  const KitCountBadge(this.count, {super.key, this.size = 24});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      padding: EdgeInsets.symmetric(horizontal: size < 22 ? 6 : 7),
      decoration: BoxDecoration(
        color: context.tones.badge,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: OgText.body(
          size < 22 ? 11 : 13,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Notes and lists ───────────────────────────────────────────────────────

enum KitTone { soft, warn, success, info, white }

/// A grey (or tinted) explanation box with 14px corners.
class KitNote extends StatelessWidget {
  const KitNote(this.text, {super.key, this.tone = KitTone.soft, this.child});

  final String text;
  final KitTone tone;

  /// Rich content in place of [text].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final (bg, fg) = switch (tone) {
      KitTone.soft => (t.soft, c.text),
      KitTone.warn => (t.warnFill, t.onWarnFill),
      KitTone.success => (t.successFill, t.onSuccessFill),
      KitTone.info => (t.infoFill, t.onInfoFill),
      KitTone.white => (c.bg, c.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: tone == KitTone.white ? Border.all(color: c.border) : null,
      ),
      child: DefaultTextStyle(
        style: OgText.body(14, height: 1.45, color: fg),
        child: child ?? Text(text),
      ),
    );
  }
}

/// A Baloo section heading ("You keep", "What members get").
class KitSection extends StatelessWidget {
  const KitSection(this.title, {super.key, this.size = 22, this.trailing});

  final String title;
  final double size;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: OgText.heading(size, color: context.og.text),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// A big title with a muted line under it.
class KitTitle extends StatelessWidget {
  const KitTitle(this.title, {super.key, this.lead, this.size = 30});

  final String title;
  final String? lead;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: OgText.heading(size, color: c.text)),
        ),
        if (lead != null) ...[
          const SizedBox(height: 6),
          Text(lead!, style: OgText.body(15, height: 1.45, color: c.textMuted)),
        ],
      ],
    );
  }
}

/// Ticked (or crossed) lines, as in "You keep" and "You lose".
class KitCheckList extends StatelessWidget {
  const KitCheckList(this.items, {super.key, this.crossed = false});

  final List<String> items;
  final bool crossed;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kitSpaced([
        for (final item in items)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: OgIcon(
                  crossed ? OgIcons.close : OgIcons.tick,
                  size: 18,
                  strokeWidth: 2.4,
                  color: crossed ? t.danger : t.successInk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: OgText.body(15, height: 1.4, color: context.og.text),
                ),
              ),
            ],
          ),
      ], 10),
    );
  }
}

/// A section: Baloo heading then its content, 8px apart.
class KitBlock extends StatelessWidget {
  const KitBlock({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSection(title, trailing: trailing),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Muted label left, bold value right, with a rule above (44px tall).
class KitKeyValue extends StatelessWidget {
  const KitKeyValue(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Text(label, style: OgText.body(15, color: c.textMuted)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: OgText.body(15, weight: FontWeight.w600, color: c.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Selection rows ────────────────────────────────────────────────────────

/// Square tick box (multi) or radio ring (single), 24px.
class KitTickBox extends StatelessWidget {
  const KitTickBox({
    super.key,
    required this.on,
    this.multi = false,
    this.radius,
    this.offColor,
  });

  final bool on;
  final bool multi;
  final double? radius;
  final Color? offColor;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final off = offColor ?? const Color(0xFFC9C9CF);
    if (!multi) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: on ? c.primary : off, width: on ? 7 : 2),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: on ? c.primary : c.bg,
        borderRadius: BorderRadius.circular(radius ?? 8),
        border: Border.all(color: on ? c.primary : off, width: 2),
      ),
      alignment: Alignment.center,
      child: on
          ? OgIcon(OgIcons.tick, size: 14, strokeWidth: 3.2, color: c.onPrimary)
          : null,
    );
  }
}

/// A 64px choice row with a rule above: title, hint, optional tag and box.
class KitChoiceRow extends StatelessWidget {
  const KitChoiceRow({
    super.key,
    required this.title,
    this.subtitle,
    this.tag,
    this.leading,
    required this.selected,
    required this.onTap,
    this.multi = false,
  });

  final String title;
  final String? subtitle;
  final String? tag;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      selected: selected,
      semanticLabel: [title, ?subtitle, ?tag].join(', '),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: OgText.body(
                        15,
                        weight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: OgText.body(13, color: c.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (tag != null && tag!.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  tag!,
                  style: OgText.body(
                    13,
                    weight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
              ],
              const SizedBox(width: 12),
              KitTickBox(on: selected, multi: multi),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bordered "I understand…" confirmation box.
class KitConfirmBox extends StatelessWidget {
  const KitConfirmBox({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      semanticLabel: label,
      selected: checked,
      onPressed: () {
        HapticFeedback.selectionClick();
        onChanged(!checked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              KitTickBox(on: checked, multi: true),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: OgText.body(
                    15,
                    weight: FontWeight.w600,
                    height: 1.35,
                    color: c.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tabs ──────────────────────────────────────────────────────────────────

/// Text tabs with a 3px orange underline under the selected one.
class KitUnderlineTabs extends StatelessWidget {
  const KitUnderlineTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.spread = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  /// Equal-width tabs instead of tight ones.
  final bool spread;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    Widget tab(int i) {
      final on = i == selected;
      return Pressable(
        semanticLabel: labels[i],
        selected: on,
        onPressed: () {
          HapticFeedback.selectionClick();
          onSelect(i);
        },
        child: Container(
          height: 48,
          constraints: const BoxConstraints(minWidth: 44),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: on ? c.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            labels[i],
            style: OgText.body(
              15,
              weight: on ? FontWeight.w700 : FontWeight.w600,
              color: on ? c.text : c.textMuted,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      padding: padding,
      child: spread
          ? Row(
              children: [
                for (var i = 0; i < labels.length; i++) Expanded(child: tab(i)),
              ],
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) const SizedBox(width: 22),
                    tab(i),
                  ],
                ],
              ),
            ),
    );
  }
}

/// Grey segmented control with a white raised selection.
class KitSegments extends StatelessWidget {
  const KitSegments({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
    this.height = 44,
    this.radius = 16,
    this.fontSize = 15,
    this.track,
    this.children,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final double height;
  final double radius;
  final double fontSize;
  final Color? track;

  /// Custom segment content (icons), one per label.
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track ?? context.tones.soft,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Pressable(
                semanticLabel: labels[i],
                selected: i == selected,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onSelect(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: height,
                  decoration: BoxDecoration(
                    color: i == selected ? c.bg : Colors.transparent,
                    borderRadius: BorderRadius.circular(radius - 3),
                    boxShadow: i == selected
                        ? const [
                            BoxShadow(
                              color: Color(0x2617171A),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child:
                      children?[i] ??
                      Text(
                        labels[i],
                        style: OgText.body(
                          fontSize,
                          weight: FontWeight.w600,
                          color: i == selected ? c.text : c.textMuted,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Faces and logos ───────────────────────────────────────────────────────

/// Solid avatar colours from the club artboards (white initials).
abstract final class Faces {
  static const palette = [
    0xFFC8553D,
    0xFF1C1F23,
    0xFF0E6B4E,
    0xFFE0A82E,
    0xFF2F3A5F,
    0xFF3E6B8A,
    0xFF7A4E9C,
    0xFFB9832A,
  ];

  /// Fixed colours for the design's sample people.
  static final overrides = <String, (int, int)>{};

  /// (background, ink) for any player id.
  static (Color, Color) forId(String id) {
    final fixed = overrides[id];
    if (fixed != null) return (Color(fixed.$1), Color(fixed.$2));
    final bg = palette[id.codeUnits.fold(0, (a, b) => a + b) % palette.length];
    return (Color(bg), Colors.white);
  }
}

/// Round initials avatar on a solid colour.
class SolidAvatar extends StatelessWidget {
  const SolidAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.ink = Colors.white,
    this.size = 44,
    this.fontSize,
    this.ring,
  });

  SolidAvatar.forId(
    String id, {
    super.key,
    required this.initials,
    this.size = 44,
    this.fontSize,
    this.ring,
  }) : color = Faces.forId(id).$1,
       ink = Faces.forId(id).$2;

  final String initials;
  final Color color;
  final Color ink;
  final double size;
  final double? fontSize;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: ring == null ? null : Border.all(color: ring!, width: 3),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: OgText.body(
            fontSize ?? (size >= 56 ? 17 : (size >= 40 ? 14 : 12)),
            weight: FontWeight.w600,
            color: ink,
          ),
        ),
      ),
    );
  }
}

/// A club or team logo: Baloo initials on a rounded square.
class ClubLogo extends StatelessWidget {
  const ClubLogo({
    super.key,
    required this.initials,
    required this.color,
    required this.ink,
    this.size = 56,
    this.radius = 18,
    this.fontSize,
    this.border,
  });

  final String initials;
  final Color color;
  final Color ink;
  final double size;
  final double radius;
  final double? fontSize;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: border == null ? null : Border.all(color: border!, width: 3),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: OgText.heading(fontSize ?? size * 0.4, color: ink),
        ),
      ),
    );
  }
}

// ─── Cards and rows ────────────────────────────────────────────────────────

/// A bordered card (18px corners) whose rows are split by hairlines.
class KitCard extends StatelessWidget {
  const KitCard({
    super.key,
    required this.children,
    this.radius = 18,
    this.padding,
    this.color,
  });

  final List<Widget> children;
  final double radius;
  final EdgeInsets? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: context.tones.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Settings-style row: tinted icon tile, title, hint, trailing and chevron.
class KitNavTile extends StatelessWidget {
  const KitNavTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.tile,
    this.ink,
    this.tileRadius = 12,
    this.tileSize = 40,
    this.danger = false,
    this.chevron = true,
    this.minHeight = 64,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.ruleAbove = false,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? tile;
  final Color? ink;
  final double tileRadius;
  final double tileSize;
  final bool danger;
  final bool chevron;
  final double minHeight;
  final EdgeInsets padding;

  /// Draws the rule above instead of relying on a [KitCard].
  final bool ruleAbove;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final titleColor = danger ? t.dangerText : c.text;
    return Pressable(
      semanticLabel: [title, ?subtitle].join(', '),
      onPressed: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: padding,
        decoration: ruleAbove
            ? BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              )
            : null,
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  color: tile ?? t.soft,
                  borderRadius: BorderRadius.circular(tileRadius),
                ),
                alignment: Alignment.center,
                child: OgIcon(
                  icon,
                  size: 22,
                  strokeWidth: 1.8,
                  color: ink ?? c.text,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: OgText.body(
                        16,
                        weight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: OgText.body(13, color: c.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (chevron) ...[
                const SizedBox(width: 8),
                OgIcon(OgIcons.chevronRight, size: 20, color: c.borderControl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Muted count text for a [KitNavTile] trailing slot.
class KitMuted extends StatelessWidget {
  const KitMuted(this.text, {super.key, this.size = 14});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: OgText.body(size, color: context.og.textMuted));
}

// ─── Fields ────────────────────────────────────────────────────────────────

/// A labelled 52px input with 14px corners.
class KitInput extends StatelessWidget {
  const KitInput({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.onChanged,
    this.maxLength,
    this.counter = false,
    this.initialValue,
    this.keyboardType,
    this.autofocus = false,
    this.focusBorder = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final bool counter;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool autofocus;

  /// Orange outline, for the field the step is about.
  final bool focusBorder;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: OgText.body(15, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        _KitField(
          controller: controller,
          hint: hint,
          onChanged: onChanged,
          maxLength: maxLength,
          initialValue: initialValue,
          keyboardType: keyboardType,
          autofocus: autofocus,
          height: 52,
          border: focusBorder ? c.primary : c.border,
          borderWidth: focusBorder ? 1.5 : 1,
          semanticLabel: label,
        ),
        if (counter && controller != null)
          ValueListenableBuilder(
            valueListenable: controller!,
            builder: (context, value, _) => Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${value.text.length}/$maxLength',
                  style: OgText.body(13, color: c.textMuted),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A labelled multi-line field.
class KitTextArea extends StatelessWidget {
  const KitTextArea({
    super.key,
    required this.label,
    this.optional = false,
    this.controller,
    this.hint,
    this.lines = 3,
    this.initialValue,
    this.onChanged,
    this.background,
  });

  final String label;
  final bool optional;
  final TextEditingController? controller;
  final String? hint;
  final int lines;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: OgText.body(15, weight: FontWeight.w600),
            children: [
              if (optional)
                TextSpan(
                  text: ' (optional)',
                  style: OgText.body(
                    15,
                    weight: FontWeight.w500,
                    color: c.textMuted,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _KitField(
          controller: controller,
          hint: hint,
          lines: lines,
          initialValue: initialValue,
          onChanged: onChanged,
          border: c.border,
          fontSize: 15,
          background: background,
          semanticLabel: label,
        ),
      ],
    );
  }
}

class _KitField extends StatelessWidget {
  const _KitField({
    this.controller,
    this.hint,
    this.onChanged,
    this.maxLength,
    this.initialValue,
    this.keyboardType,
    this.autofocus = false,
    this.height,
    this.lines = 1,
    required this.border,
    this.borderWidth = 1,
    this.fontSize = 16,
    this.background,
    required this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool autofocus;
  final double? height;
  final int lines;
  final Color border;
  final double borderWidth;
  final double fontSize;
  final Color? background;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: border, width: borderWidth),
    );
    final field = TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      onChanged: onChanged,
      autofocus: autofocus,
      keyboardType: lines > 1 ? TextInputType.multiline : keyboardType,
      minLines: lines,
      maxLines: lines > 1 ? lines + 3 : 1,
      maxLength: maxLength,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: OgText.body(fontSize, height: 1.45, color: c.text),
      cursorColor: c.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: OgText.body(fontSize, color: c.textMuted),
        counterText: '',
        filled: true,
        fillColor: background ?? c.bg,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: lines > 1 ? 12 : 14,
        ),
        enabledBorder: outline,
        border: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
    );
    return Semantics(
      textField: true,
      label: semanticLabel,
      child: height == null ? field : SizedBox(height: height, child: field),
    );
  }
}

/// Search box: a bordered 48px field, or a soft grey one.
class KitSearchField extends StatelessWidget {
  const KitSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.soft = false,
    this.focusBorder = false,
    this.controller,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final bool soft;
  final bool focusBorder;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: soft ? context.tones.soft : c.bg,
        borderRadius: BorderRadius.circular(14),
        border: soft
            ? null
            : Border.all(
                color: focusBorder ? c.primary : c.border,
                width: focusBorder ? 1.5 : 1,
              ),
      ),
      child: Row(
        children: [
          OgIcon(
            OgIcons.searchCircle,
            size: soft ? 18 : 20,
            color: c.textMuted,
            strokeWidth: soft ? 2 : 1.8,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              textInputAction: TextInputAction.search,
              style: OgText.body(soft ? 15 : 16, color: c.text),
              cursorColor: c.primary,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: OgText.body(soft ? 15 : 16, color: c.textMuted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Decoration ────────────────────────────────────────────────────────────

/// A coloured banner with the court-line drawing from the artboards.
class CourtHero extends StatelessWidget {
  const CourtHero({
    super.key,
    required this.color,
    required this.height,
    this.child,
    this.style = CourtLines.corner,
  });

  final Color color;
  final double height;
  final Widget? child;
  final CourtLines style;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: color,
      child: ClipRect(
        child: CustomPaint(
          painter: _CourtPainter(style),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

enum CourtLines {
  /// A court corner on the right (club page, Group page).
  corner,

  /// The small corner on club tiles in Home's Clubs row.
  tile,

  /// A full half-court across the banner (private club, team page).
  half,
}

class _CourtPainter extends CustomPainter {
  const _CourtPainter(this.style);
  final CourtLines style;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 390;
    final h = size.height;
    switch (style) {
      case CourtLines.corner:
        final p = Paint()
          ..color = const Color(0x47FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(Rect.fromLTWH(250 * s, -40, 220 * s, h + 80), p);
        // The service line sits at 55% of the banner in every artboard.
        final mid = h * 0.55;
        canvas.drawLine(Offset(250 * s, mid), Offset(470 * s, mid), p);
        canvas.drawLine(Offset(360 * s, -40), Offset(360 * s, h + 40), p);
      case CourtLines.tile:
        final p = Paint()
          ..color = const Color(0x2EFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        final k = size.width / 208;
        canvas.drawRect(Rect.fromLTWH(96 * k, -20, 150 * k, 150), p);
        canvas.drawLine(Offset(96 * k, 56), Offset(246 * k, 56), p);
        canvas.drawLine(Offset(171 * k, -20), Offset(171 * k, 130), p);
      case CourtLines.half:
        final p = Paint()
          ..color = const Color(0x4DFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRect(
          Rect.fromLTRB(40 * s, 30, size.width - 40 * s, h + 40),
          p,
        );
        canvas.drawLine(
          Offset(40 * s, 110),
          Offset(size.width - 40 * s, 110),
          p,
        );
        canvas.drawLine(
          Offset(size.width / 2, 110),
          Offset(size.width / 2, h + 40),
          p,
        );
    }
  }

  @override
  bool shouldRepaint(_CourtPainter old) => old.style != style;
}

/// A rounded box with a dashed outline ("Edit" category, upload slots).
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    this.radius = 22,
    this.color,
    this.strokeWidth = 1.5,
  });

  final Widget child;
  final double radius;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashPainter(
      radius,
      color ?? const Color(0xFFC9C9CF),
      strokeWidth,
    ),
    child: child,
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.radius, this.color, this.width);
  final double radius;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(width / 2),
          Radius.circular(radius),
        ),
      );
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color || old.radius != radius;
}

// ─── Sheets ────────────────────────────────────────────────────────────────

/// Bottom sheet with 26px top corners and a 40×4 grabber.
Future<T?> showKitSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  Color? background,
  EdgeInsets padding = const EdgeInsets.fromLTRB(20, 10, 20, 0),
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: background ?? context.og.bg,
    barrierColor: context.tones.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 88,
      ),
      child: Padding(
        padding: padding.copyWith(
          bottom: math.max(26, MediaQuery.of(context).padding.bottom + 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.og.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(child: builder(context)),
          ],
        ),
      ),
    ),
  );
}

/// The success banner shown after sending ("Report sent", "Posted").
class KitDoneBanner extends StatelessWidget {
  const KitDoneBanner({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return CourtHero(
      color: c.inverseCard,
      height: 220,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.highlight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(
                OgIcons.tick,
                size: 32,
                strokeWidth: 3,
                color: OgColors.charcoal900,
              ),
            ),
            const SizedBox(height: 10),
            Text(title, style: OgText.heading(50, color: c.onInverseCard)),
          ],
        ),
      ),
    );
  }
}

/// − count + for quantities.
class KitQty extends StatelessWidget {
  const KitQty({
    super.key,
    required this.value,
    required this.onLess,
    required this.onMore,
    this.label = 'quantity',
  });

  final int value;

  /// Null when it can't go lower (or higher).
  final VoidCallback? onLess;
  final VoidCallback? onMore;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    Widget button(IconData icon, String what, VoidCallback? tap) => Pressable(
      semanticLabel: what,
      onPressed: tap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.borderControl, width: 1.5),
        ),
        child: Icon(icon, size: 18, color: tap == null ? c.textMuted : c.text),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(CupertinoIcons.minus, 'Lower $label', onLess),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: OgText.heading(18),
          ),
        ),
        button(CupertinoIcons.plus, 'Raise $label', onMore),
      ],
    );
  }
}
