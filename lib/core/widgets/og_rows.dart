import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/og_colors.dart';
import 'og_fields.dart';
import 'og_icon.dart';
import 'pressable.dart';
import '../../core/theme/og_type.dart';

/// Small uppercase label above a group ("ACCOUNT", "RECENT").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.top = 24});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top),
    child: Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: context.type.caption.copyWith(letterSpacing: 0.8),
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
                  Text(title, style: context.type.body),
                  Text(
                    subtitle,
                    style: context.type.secondary.copyWith(height: 1.35),
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
                        ? context.type.body
                        : context.type.body.copyWith(height: 1.2),
                  ),
                  Text(
                    subtitle,
                    style: context.type.secondary.copyWith(height: 1.35),
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
              style: context.type.body,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: context.type.tertiary,
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
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

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
                      color: i == index ? c.primarySmall : Colors.transparent,
                      borderRadius: BorderRadius.circular(height / 2 + 2),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        labels[i],
                        style: context.type.button.copyWith(
                          color: i == index ? c.onPrimary : c.text,
                          height: 1.2,
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
                Text(title, style: context.type.body),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.secondary,
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
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final double height;

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
            color: selected ? c.primarySmall : Colors.transparent,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: selected ? c.primarySmall : c.border,
              width: 2,
            ),
          ),
          child: ExcludeSemantics(
            child: Text(
              label,
              style: context.type.button.copyWith(
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
                Expanded(child: Text(label, style: context.type.body)),
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
          Text(label, style: context.type.body),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.type.secondary,
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
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final int maxLength;
  final int minLines;
  final String? hint;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: minLines + 2,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.sentences,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: context.type.body.copyWith(height: 1.35),
      decoration: ogOutlinedDecoration(
        context,
        label: label,
        hint: hint,
      ).copyWith(counterText: '', alignLabelWithHint: true),
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
          color: following ? c.surfaceRaised : c.primarySmall,
          borderRadius: BorderRadius.circular(20),
          border: following ? Border.all(color: c.text, width: 2) : null,
        ),
        child: Text(
          label,
          style: context.type.button.copyWith(
            color: following ? c.text : c.onPrimary,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
