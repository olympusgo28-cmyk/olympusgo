import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/og_colors.dart';
import '../theme/og_text.dart';
import 'og_icon.dart';
import 'pressable.dart';

/// Small uppercase label above a group ("ACCOUNT", "RECENT").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.top = 24, this.size = 14});

  final String text;
  final double top;
  final double size;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: OgText.body(
          size,
          weight: FontWeight.w600,
          letterSpacing: size * 0.06,
          color: context.og.textMuted,
        ),
      ),
    ),
  );
}

/// Group of rows with a 2px rule on top, as on the Settings screen.
class RowGroup extends StatelessWidget {
  const RowGroup({
    super.key,
    required this.children,
    this.top = 8,
    this.dividers = false,
    this.topBorder = true,
  });

  final List<Widget> children;
  final double top;

  /// Form switch lists (create flows) have only the rules between rows.
  final bool topBorder;

  /// Draw a rule under every row (switch lists) instead of only on top.
  final bool dividers;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      margin: EdgeInsets.only(top: top),
      decoration: topBorder
          ? BoxDecoration(
              border: Border(top: BorderSide(color: c.border, width: 2)),
            )
          : null,
      child: Column(
        children: [
          for (final child in children)
            dividers
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: c.border, width: 2),
                      ),
                    ),
                    child: child,
                  )
                : child,
        ],
      ),
    );
  }
}

/// Settings row: tinted round icon, title, subtitle, chevron.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      onPressed: onTap,
      semanticLabel: '$title. $subtitle',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.primaryTint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(icon, color: c.link),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: OgText.body(
                      17,
                      weight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: OgText.body(14, height: 1.35, color: c.textMuted),
                  ),
                ],
              ),
            ),
            OgIcon(
              OgIcons.chevronRight,
              size: 22,
              color: c.text,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}

/// Title, subtitle and an iOS switch in the brand colour.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.leading,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;

  /// The tighter form style used in the create flows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: compact ? 64 : 68),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: leading == null
                        ? OgText.body(
                            compact ? 16 : 17,
                            weight: FontWeight.w600,
                            color: c.text,
                          )
                        : OgText.display(18, height: 1.2, color: c.text),
                  ),
                  Text(
                    subtitle,
                    style: OgText.body(14, height: 1.35, color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            CupertinoSwitch(
              value: value,
              activeTrackColor: c.primary,
              inactiveTrackColor: c.borderControl,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordered pill search field.
class OgSearchField extends StatelessWidget {
  const OgSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.height = 52,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double height;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: c.borderControl, width: 2),
      ),
      child: Row(
        children: [
          OgIcon(OgIcons.search, size: height < 52 ? 20 : 22, color: c.text),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: OgText.body(16, color: c.text),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: OgText.body(16, color: c.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped segmented control (Following/Followers, Saved tabs).
class PillTabs extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.height = 44,
    this.fontSize = 18,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2 + 6),
        border: Border.all(color: c.border, width: 2),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == index,
                label: labels[i],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (i != index) HapticFeedback.selectionClick();
                    onChanged(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: height,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == index ? c.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(height / 2 + 2),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        labels[i],
                        style: OgText.display(
                          fontSize,
                          height: 1.2,
                          color: i == index ? c.onPrimary : c.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A row for a person or item in a list: leading avatar, two lines, trailing.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.minHeight = 72,
    this.semanticLabel,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double minHeight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final row = Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border, width: 2)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: OgText.body(
                    16,
                    weight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(14, color: c.textMuted),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
    if (onTap == null) return row;
    return Pressable(
      onPressed: onTap,
      semanticLabel: semanticLabel ?? title,
      child: row,
    );
  }
}

/// Outlined chip (sport filters on Search).
class OgChip extends StatelessWidget {
  const OgChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.height = 40,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: 2,
            ),
          ),
          child: ExcludeSemantics(
            child: Text(
              label,
              style: OgText.body(
                fontSize,
                weight: FontWeight.w600,
                color: selected ? c.onPrimary : c.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Radio option row, for single-choice lists such as report reasons.
class RadioRow extends StatelessWidget {
  const RadioRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border, width: 2)),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.surfaceRaised,
                    border: Border.all(
                      color: selected ? c.primary : c.borderControl,
                      width: selected ? 7 : 2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label, style: OgText.body(16, color: c.text)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Label ........ value" row (receipts, check-in details).
class KeyValueRow extends StatelessWidget {
  const KeyValueRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border, width: 2)),
      ),
      child: Row(
        children: [
          Text(label, style: OgText.body(16, color: c.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: OgText.body(16, weight: FontWeight.w600, color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}

/// Multi-line bordered text input (bio, support message).
class OgTextArea extends StatelessWidget {
  const OgTextArea({
    super.key,
    required this.label,
    required this.controller,
    this.maxLength = 150,
    this.minLines = 3,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final int maxLength;
  final int minLines;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: OgText.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines + 2,
          maxLength: maxLength,
          textCapitalization: TextCapitalization.sentences,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: OgText.body(16, height: 1.35, color: c.text),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: OgText.body(16, color: c.textMuted),
            counterText: '',
            filled: true,
            fillColor: c.surfaceRaised,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            enabledBorder: border(c.borderControl, 2),
            focusedBorder: border(c.primary, 3),
          ),
        ),
      ],
    );
  }
}

/// Small pill follow button: filled "Follow", outlined "Following".
class FollowButton extends StatelessWidget {
  const FollowButton({
    super.key,
    required this.following,
    required this.onPressed,
    this.followLabel = 'Follow',
    this.minWidth = 0,
  });

  final bool following;
  final VoidCallback onPressed;
  final String followLabel;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final label = following ? 'Following' : followLabel;
    return Pressable(
      onPressed: onPressed,
      haptic: true,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        constraints: BoxConstraints(minWidth: minWidth),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: following ? c.surfaceRaised : c.primary,
          borderRadius: BorderRadius.circular(20),
          border: following ? Border.all(color: c.text, width: 2) : null,
        ),
        child: Text(
          label,
          style: OgText.display(
            15,
            height: 1.2,
            color: following ? c.text : c.onPrimary,
          ),
        ),
      ),
    );
  }
}
