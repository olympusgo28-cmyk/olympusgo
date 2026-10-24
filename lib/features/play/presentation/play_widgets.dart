import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/cupertino_sheets.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/pressable.dart';
import '../../onboarding/domain/sport.dart';
import '../domain/activity.dart';

/// A Meet, tournament or event in a list.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.statusPill,
    this.availability,
    this.eyebrow,
  });

  final Activity activity;
  final VoidCallback onTap;

  /// Overrides the price pill, e.g. "Joined" or "Waitlist" on My schedule.
  final ({String label, bool strong})? statusPill;

  /// Overrides the third line, e.g. "You are in".
  final String? availability;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final a = activity;
    final full = a.kind == ActivityKind.meet && a.isFull;
    final pill =
        statusPill ??
        (full
            ? (label: 'Full', strong: false)
            : (label: a.priceLabel, strong: true));
    final strongSolid = statusPill?.strong ?? false;

    Widget line(String icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          OgIcon(icon, size: 20, color: c.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: OgText.body(14, color: c.textMuted)),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Pressable(
        onPressed: onTap,
        semanticLabel:
            '${a.title}. ${eyebrow ?? a.eyebrow}. ${Fmt.dayTime(a.startsAt)}. ${a.venue.name}. ${availability ?? a.availability}. ${pill.label}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      eyebrow ?? a.eyebrow,
                      style: OgText.body(
                        13,
                        weight: FontWeight.w600,
                        color: c.link,
                      ),
                    ),
                  ),
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: strongSolid
                          ? c.primary
                          : (pill.strong ? c.primaryTint : c.surface),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      pill.label,
                      style: OgText.body(
                        13,
                        weight: FontWeight.w600,
                        color: strongSolid
                            ? c.onPrimary
                            : (pill.strong ? c.link : c.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                a.title,
                style: OgText.body(18, weight: FontWeight.w600, color: c.text),
              ),
              const SizedBox(height: 4),
              line(OgIcons.calendar, Fmt.dayTime(a.startsAt)),
              line(OgIcons.pinSmall, a.venue.name),
              line(OgIcons.people, availability ?? a.availability),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled group of single-choice chips ("When", "Game type").
class ChipChoice<T> extends StatelessWidget {
  const ChipChoice({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.top = 20,
    this.labelSize = 15,
  });

  final String label;
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final double top;
  final double labelSize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: OgText.body(
            labelSize,
            weight: FontWeight.w600,
            color: context.og.text,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, text) in options)
              OgChip(
                label: text,
                selected: value == selected,
                onTap: () => onSelected(value),
              ),
          ],
        ),
      ],
    ),
  );
}

/// A 52px select with a small label above, opening a native picker.
class LabeledSelect<T> extends StatelessWidget {
  const LabeledSelect({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.text,
    required this.onChanged,
    this.mutedLabel = false,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) text;
  final ValueChanged<T> onChanged;
  final bool mutedLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: OgText.body(
            14,
            weight: FontWeight.w600,
            color: mutedLabel ? c.textMuted : c.text,
          ),
        ),
        const SizedBox(height: 6),
        OgSelectField(
          value: text(value),
          semanticLabel: label,
          height: 52,
          fontSize: 17,
          onTap: () async {
            final picked = await showOgListPicker<T>(
              context: context,
              title: label,
              items: items,
              selected: value,
              label: text,
            );
            if (picked != null) onChanged(picked);
          },
        ),
      ],
    );
  }
}

/// Level from / to pair of selects.
class LevelRangeSelects extends StatelessWidget {
  const LevelRangeSelects({
    super.key,
    required this.min,
    required this.max,
    required this.onChanged,
    this.fromLabel = 'From',
    this.toLabel = 'To',
    this.mutedLabel = true,
  });

  final double min;
  final double max;
  final void Function(double min, double max) onChanged;
  final String fromLabel;
  final String toLabel;
  final bool mutedLabel;

  static const _levels = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: LabeledSelect<double>(
          label: fromLabel,
          mutedLabel: mutedLabel,
          value: min,
          items: _levels,
          text: (v) => v.toStringAsFixed(1),
          onChanged: (v) => onChanged(v, v > max ? v : max),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: LabeledSelect<double>(
          label: toLabel,
          mutedLabel: mutedLabel,
          value: max,
          items: _levels,
          text: (v) => v.toStringAsFixed(1),
          onChanged: (v) => onChanged(v < min ? v : min, v),
        ),
      ),
    ],
  );
}

/// "Label ....... Value >" row that opens a picker screen.
class PickerRow extends StatelessWidget {
  const PickerRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      onPressed: onTap,
      semanticLabel: '$label, $value',
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border, width: 2)),
        ),
        child: Row(
          children: [
            Text(label, style: OgText.body(16, color: c.textMuted)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: OgText.body(16, weight: FontWeight.w600, color: c.text),
              ),
            ),
            const SizedBox(width: 10),
            OgIcon(
              OgIcons.chevronRight,
              size: 20,
              color: c.text,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}

/// Title, subtitle and a trailing radio or checkbox (sport, venue, payment).
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.multi = false,
    this.minHeight = 64,
    this.titleSize = 17,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool multi;
  final double minHeight;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      inMutuallyExclusiveGroup: !multi,
      checked: selected,
      button: true,
      label: [title, ?subtitle].join(', '),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border, width: 2)),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: OgText.body(
                          titleSize,
                          weight: FontWeight.w600,
                          color: c.text,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: OgText.body(14, color: c.textMuted),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: multi && selected ? c.primary : c.surfaceRaised,
                    borderRadius: BorderRadius.circular(multi ? 8 : 12),
                    border: Border.all(
                      color: selected ? c.primary : c.borderControl,
                      width: selected && !multi ? 7 : 2,
                    ),
                  ),
                  child: multi && selected
                      ? Center(
                          child: OgIcon(
                            OgIcons.check,
                            size: 14,
                            color: c.onPrimary,
                            strokeWidth: 3.5,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sport row subtitles, as on the create screens.
String sportFormats(Sport s) => switch (s) {
  Sport.badminton => 'Singles, doubles, mixed',
  Sport.pickleball => 'Doubles, mixed',
  Sport.padel => 'Doubles',
  _ => 'Singles, doubles',
};

/// The month grid used by the date pickers. Past days are greyed out.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.rangeEnd,
    this.firstDay,
  });

  final DateTime? selected;

  /// For ranges: highlighted together with [selected].
  final DateTime? rangeEnd;
  final ValueChanged<DateTime> onSelected;
  final DateTime? firstDay;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _month = DateTime(
    (widget.selected ?? DateTime.now()).year,
    (widget.selected ?? DateTime.now()).month,
  );

  bool _same(DateTime a, DateTime? b) =>
      b != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final today = DateTime.now();
    final first =
        widget.firstDay ?? DateTime(today.year, today.month, today.day);
    final lead = DateTime(_month.year, _month.month, 1).weekday - 1;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final canGoBack = DateTime(
      _month.year,
      _month.month,
    ).isAfter(DateTime(first.year, first.month));

    Widget arrow(String icon, String label, bool enabled, int delta) =>
        Pressable(
          onPressed: enabled
              ? () => setState(
                  () => _month = DateTime(_month.year, _month.month + delta),
                )
              : null,
          semanticLabel: label,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: OgIcon(
                icon,
                size: 20,
                color: c.textMuted,
                strokeWidth: 2.5,
              ),
            ),
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${Fmt.monthsLong[_month.month - 1]} ${_month.year}',
                style: OgText.body(18, weight: FontWeight.w600, color: c.text),
              ),
            ),
            arrow(OgIcons.back, 'Previous month', canGoBack, -1),
            arrow(OgIcons.chevronRight, 'Next month', true, 1),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: OgText.body(13, color: c.textMuted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var week = 0; week * 7 < lead + days; week++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: () {
                        final n = week * 7 + i - lead + 1;
                        if (n < 1 || n > days) {
                          return const SizedBox(height: 44);
                        }
                        final date = DateTime(_month.year, _month.month, n);
                        final past = date.isBefore(first);
                        final on =
                            _same(date, widget.selected) ||
                            _same(date, widget.rangeEnd);
                        final between =
                            widget.rangeEnd != null &&
                            widget.selected != null &&
                            date.isAfter(widget.selected!) &&
                            date.isBefore(widget.rangeEnd!);
                        return Semantics(
                          button: true,
                          selected: on,
                          enabled: !past,
                          label: Fmt.day(date),
                          child: GestureDetector(
                            onTap: past
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    widget.onSelected(date);
                                  },
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: on
                                    ? c.primary
                                    : (between ? c.primaryTint : null),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: ExcludeSemantics(
                                child: Text(
                                  '$n',
                                  style: OgText.body(
                                    16,
                                    weight: FontWeight.w600,
                                    color: on
                                        ? c.onPrimary
                                        : (past ? OgColors.grey400 : c.text),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bottom sheet styled like the design: 28px top corners and a grabber.
Future<T?> showOgSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: context.og.bg,
    barrierColor: const Color(0x801C1F23),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.og.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          builder(context),
        ],
      ),
    ),
  );
}
