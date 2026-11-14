import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/og_colors.dart';
import '../theme/og_layout.dart';
import '../theme/og_tones.dart';
import '../theme/og_type.dart';
import 'og_buttons.dart';
import 'og_icon.dart';
import 'og_screen.dart';

/// How a [SettingsSection] draws its rows.
enum SettingsStyle {
  /// Rows edge to edge on [OgColors.groupedSurface], no dividers, on a page
  /// of [OgColors.groupedBg]. Navigation lists such as Settings.
  menu,

  /// A rounded card with a hairline border and hairlines between rows, inset
  /// from the screen edges. Screens that show the player's own details
  /// (Edit profile, Account information).
  outlined,
}

/// One row of a settings list: an optional icon, the label with an optional
/// subtitle under it, a value on the right, an optional "new" dot, and a
/// chevron when it opens something.
class SettingsRow extends StatefulWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.icon,
    this.subtitle,
    this.value,
    this.showDot = false,
    this.onTap,
    this.emptyText,
    this.isLoading = false,
    this.semanticValue,
    this.semanticHint,
    this.trailingIcon,
  });

  final String label;

  /// An [OgIcons] outline icon, drawn at [OgSize.icon] in the text colour.
  final String? icon;
  final String? subtitle;

  /// Shown on the right on one line, at most 60 % of the row. Null or empty
  /// shows [emptyText] instead.
  final String? value;

  /// A small dot before the chevron for something new.
  final bool showDot;

  /// Null makes the row read-only: no chevron and no press.
  final VoidCallback? onTap;

  /// Shown in the link colour when there is no value ("Add").
  final String? emptyText;

  /// Shows a grey bar where the value goes, at the row's usual height.
  final bool isLoading;

  /// What a screen reader says for the value when the shown text reads
  /// badly, such as a masked number.
  final String? semanticValue;

  /// What a tap does, for a screen reader, when it isn't opening a screen
  /// ("Copies the link").
  final String? semanticHint;

  /// Replaces the chevron on a row that does something in place, such as a
  /// copy icon.
  final String? trailingIcon;

  /// Whether a search for [query] finds this row, by label or subtitle.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return label.toLowerCase().contains(q) ||
        (subtitle?.toLowerCase().contains(q) ?? false);
  }

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _down = false;
  bool _focused = false;

  void _press(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final type = context.type;
    final value = widget.value ?? '';
    final empty = value.isEmpty;
    final shown = empty ? (widget.emptyText ?? '') : value;
    final hasValue = shown.isNotEmpty || widget.isLoading;
    final opens = widget.onTap != null;
    final tappable = opens && !widget.isLoading;
    final valueStyle = empty
        ? type.secondary.copyWith(color: c.link)
        : type.secondary;

    final trailing = [
      if (widget.showDot) ...[
        const SizedBox(width: OgSpace.s2),
        Container(
          width: OgSize.dot,
          height: OgSize.dot,
          decoration: BoxDecoration(color: c.link, shape: BoxShape.circle),
        ),
      ],
      if (opens) ...[
        const SizedBox(width: OgSpace.s2),
        OgIcon(
          widget.trailingIcon ?? OgIcons.chevronRight,
          size: OgSize.iconSmall,
          color: c.borderControl,
        ),
      ],
    ];

    final row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: widget.subtitle == null
            ? OgSize.row
            : OgSize.rowWithSubtitle,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OgSpace.s4,
          vertical: OgSpace.s3,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final stacked =
                !widget.isLoading &&
                shown.isNotEmpty &&
                _stacks(context, box.maxWidth, shown, valueStyle);
            return Row(
              children: [
                if (widget.icon != null) ...[
                  OgIcon(widget.icon!, size: OgSize.icon, color: c.text),
                  const SizedBox(width: OgSpace.s4),
                ],
                // The label never shortens; it wraps if it must.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label, style: type.body),
                      if (widget.subtitle != null)
                        Text(widget.subtitle!, style: type.secondary),
                      if (stacked) ...[
                        const SizedBox(height: OgSpace.s1),
                        Text(shown, style: valueStyle),
                      ],
                    ],
                  ),
                ),
                if (hasValue && !stacked) ...[
                  const SizedBox(width: OgSpace.s3),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: box.maxWidth * OgSize.valueShare,
                    ),
                    child: widget.isLoading
                        ? const _SkeletonLine()
                        : Text(
                            shown,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: valueStyle,
                          ),
                  ),
                ],
                ...trailing,
              ],
            );
          },
        ),
      ),
    );

    final spoken = widget.isLoading
        ? 'Loading'
        : (empty ? shown : (widget.semanticValue ?? value));
    final pressed = context.tones.track;
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: tappable,
      label: [
        widget.label,
        ?widget.subtitle,
        if (widget.showDot) 'New',
      ].join(', '),
      value: spoken.isEmpty ? null : spoken,
      hint: widget.semanticHint,
      onTap: tappable ? widget.onTap : null,
      child: !tappable
          ? row
          // A keyboard or Switch Control can reach it too, with the focus
          // outline from design system rule 6.
          : FocusableActionDetector(
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    widget.onTap!();
                    return null;
                  },
                ),
              },
              onShowFocusHighlight: (on) => setState(() => _focused = on),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _press(true),
                onTapUp: (_) => _press(false),
                onTapCancel: () => _press(false),
                onTap: widget.onTap,
                // A colour change instead of a ripple; instant with reduced
                // motion.
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : OgMotion.press,
                  curve: OgMotion.ease,
                  color: _down ? pressed : pressed.withValues(alpha: 0),
                  foregroundDecoration: _focused
                      ? BoxDecoration(
                          border: Border.all(
                            color: c.focusRing,
                            width: OgSize.focusRing,
                          ),
                        )
                      : null,
                  child: row,
                ),
              ),
            ),
    );
  }

  /// With large text, whether the label and value no longer fit side by
  /// side in [width]; then the value moves under the label.
  bool _stacks(
    BuildContext context,
    double width,
    String value,
    TextStyle valueStyle,
  ) {
    final body = context.type.body;
    final scaler = MediaQuery.textScalerOf(context);
    final size = body.fontSize!;
    if (scaler.scale(size) / size < OgSize.stackTextScale) return false;
    final direction = Directionality.of(context);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    var room = width - OgSpace.s3;
    if (widget.icon != null) room -= OgSize.icon + OgSpace.s4;
    if (widget.showDot) room -= OgSpace.s2 + OgSize.dot;
    if (widget.onTap != null) room -= OgSpace.s2 + OgSize.iconSmall;
    return measure(widget.label, body) + measure(value, valueStyle) > room;
  }
}

/// The grey bar a loading [SettingsRow] shows in place of its value.
class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine();

  @override
  Widget build(BuildContext context) => const FractionallySizedBox(
    widthFactor: 0.5,
    child: SkeletonBlock(height: OgSize.skeletonLine),
  );
}

/// A grey placeholder while something loads: a bar, or a circle for a photo.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    required this.height,
    this.width,
    this.circle = false,
  });

  final double height;
  final double? width;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.tones.track,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(OgRadius.sm),
    ),
  );
}

/// A group of settings rows with an optional header above and helper text
/// below (with an optional link at its end).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.rows,
    this.label,
    this.helper,
    this.helperLink,
    this.onHelperLink,
    this.style = SettingsStyle.menu,
  });

  /// Usually [SettingsRow]s. Other rows (a switch) show only while nothing
  /// is searched for.
  final List<Widget> rows;
  final String? label;
  final String? helper;
  final String? helperLink;
  final VoidCallback? onHelperLink;
  final SettingsStyle style;

  /// This section with only the rows a search for [query] finds, or null
  /// when none match (or it has no rows at all).
  SettingsSection? filtered(String query) {
    if (rows.isEmpty) return null;
    if (query.trim().isEmpty) return this;
    final kept = [
      for (final r in rows)
        if (r is SettingsRow && r.matches(query)) r,
    ];
    if (kept.isEmpty) return null;
    return SettingsSection(
      rows: kept,
      label: label,
      helper: helper,
      helperLink: helperLink,
      onHelperLink: onHelperLink,
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final header = label == null
        ? null
        : Semantics(
            header: true,
            child: Text(label!, style: context.type.groupLabel),
          );
    final note = helper == null
        ? null
        : _HelperText(helper!, link: helperLink, onLink: onHelperLink);

    if (style == SettingsStyle.menu) {
      return ColoredBox(
        color: c.groupedSurface,
        child: Padding(
          padding: EdgeInsets.only(
            top: header == null ? OgSpace.s2 : 0,
            bottom: note == null ? OgSpace.s2 : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    OgSpace.s4,
                    OgSpace.s4,
                    OgSpace.s4,
                    OgSpace.s2,
                  ),
                  child: header,
                ),
              ...rows,
              if (note != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    OgSpace.s4,
                    OgSpace.s1,
                    OgSpace.s4,
                    OgSpace.s4,
                  ),
                  child: note,
                ),
            ],
          ),
        ),
      );
    }

    // Outlined: the label and helper line up with the text inside the card.
    const margin = EdgeInsets.symmetric(horizontal: OgSpace.s4);
    const text = EdgeInsets.symmetric(horizontal: OgSpace.s8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null)
          Padding(
            padding: text.copyWith(bottom: OgSpace.s2),
            child: header,
          ),
        Padding(
          padding: margin,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(OgRadius.lg),
              border: Border.all(color: c.border, width: OgSize.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: OgSpace.s4,
                      ),
                      child: Container(
                        height: OgSize.hairline,
                        color: c.border,
                      ),
                    ),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
        if (note != null)
          Padding(
            padding: text.copyWith(top: OgSpace.s2),
            child: note,
          ),
      ],
    );
  }
}

/// Helper text in the caption role, with an optional link at the end in the
/// link colour.
class _HelperText extends StatefulWidget {
  const _HelperText(this.text, {this.link, this.onLink});

  final String text;
  final String? link;
  final VoidCallback? onLink;

  @override
  State<_HelperText> createState() => _HelperTextState();
}

class _HelperTextState extends State<_HelperText> {
  final _tap = TapGestureRecognizer();

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = context.type.caption;
    if (widget.link == null) return Text(widget.text, style: caption);
    _tap.onTap = widget.onLink;
    return Text.rich(
      TextSpan(
        style: caption,
        children: [
          TextSpan(text: '${widget.text} '),
          TextSpan(
            text: widget.link,
            style: caption.copyWith(color: context.og.link),
            recognizer: _tap,
          ),
        ],
      ),
    );
  }
}

/// Settings groups separated by a band of the page colour. With a
/// [query], only matching rows show, empty groups hide, and "No results"
/// shows when nothing matches.
class SettingsList extends StatelessWidget {
  const SettingsList({super.key, required this.sections, this.query = ''});

  final List<SettingsSection> sections;
  final String query;

  @override
  Widget build(BuildContext context) {
    final shown = [for (final s in sections) ?s.filtered(query)];
    if (shown.isEmpty) {
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.all(OgSpace.s8),
          child: Text(
            'No results',
            textAlign: TextAlign.center,
            style: context.type.secondary,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: OgSize.groupGap),
          shown[i],
        ],
      ],
    );
  }
}

/// A rounded search field for a settings list, in the group colour so it
/// stands out on the grey page.
class SettingsSearchBar extends StatelessWidget {
  const SettingsSearchBar({
    super.key,
    required this.onChanged,
    this.controller,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      constraints: const BoxConstraints(minHeight: OgSize.searchBar),
      padding: const EdgeInsets.symmetric(horizontal: OgSpace.s3),
      decoration: BoxDecoration(
        color: c.groupedSurface,
        borderRadius: BorderRadius.circular(OgRadius.md),
      ),
      child: Row(
        children: [
          OgIcon(OgIcons.search, size: OgSize.iconSmall, color: c.textMuted),
          const SizedBox(width: OgSpace.s2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              textInputAction: TextInputAction.search,
              style: context.type.body,
              cursorColor: c.primary,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: context.type.tertiary,
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

/// Full width on a phone; from [OgSize.wide] up, centred at
/// [OgSize.readableWidth].
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < OgSize.wide) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: OgSize.readableWidth),
        child: child,
      ),
    );
  }
}

/// A screen's details didn't load: why, and Try again.
class SettingsLoadError extends StatelessWidget {
  const SettingsLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: OgSpace.s4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OgErrorText(message),
        const SizedBox(height: OgSpace.s4),
        OgButton.outline(label: 'Try again', onPressed: onRetry),
      ],
    ),
  );
}
