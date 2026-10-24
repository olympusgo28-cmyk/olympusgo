import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../social/domain/social_models.dart';
import '../domain/club_models.dart';

/// A player's solid initials avatar, coloured like the club artboards.
class PlayerFace extends StatelessWidget {
  const PlayerFace(this.player, {super.key, this.size = 44, this.ring});

  final PlayerSummary player;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) => SolidAvatar.forId(
    player.id,
    initials: player.initials,
    size: size,
    ring: ring,
  );
}

/// The club's logo tile.
class ClubMark extends StatelessWidget {
  const ClubMark(
    this.club, {
    super.key,
    this.size = 56,
    this.radius = 18,
    this.fontSize,
    this.border,
  });

  final Club club;
  final double size;
  final double radius;
  final double? fontSize;
  final Color? border;

  @override
  Widget build(BuildContext context) => ClubLogo(
    initials: club.initials,
    color: Color(club.logoColor),
    ink: Color(club.logoInk),
    size: size,
    radius: radius,
    fontSize: fontSize,
    border: border,
  );
}

/// A team's logo tile ("A").
class TeamMark extends StatelessWidget {
  const TeamMark(
    this.team, {
    super.key,
    this.size = 56,
    this.radius = 18,
    this.fontSize,
  });

  final Team team;
  final double size;
  final double radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context) => ClubLogo(
    initials: team.mark,
    color: Color(team.logoColor),
    ink: Color(team.logoInk),
    size: size,
    radius: radius,
    fontSize: fontSize,
  );
}

/// The green level-range tag ("LI–HI").
class LevelTag extends StatelessWidget {
  const LevelTag(this.label, {super.key, this.height = 26});

  final String label;
  final double height;

  @override
  Widget build(BuildContext context) => KitTag(
    label,
    height: height,
    background: context.tones.successFill,
    foreground: context.tones.onSuccessFill,
  );
}

/// The grey level tag beside member names ("MI").
class BandTag extends StatelessWidget {
  const BandTag(this.label, {super.key, this.fontSize = 12});

  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.tones.tag,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: OgText.body(
        fontSize,
        weight: FontWeight.w600,
        color: context.tones.onTag,
      ),
    ),
  );
}

/// One group of chips in a filter sheet.
class FilterGroup {
  const FilterGroup(this.key, this.title, this.options, {this.icons});
  final String key;
  final String title;
  final List<String> options;
  final List<String>? icons;
}

/// The Filters sheet shared by the Group page and the club page: one
/// selection per group, Reset and Show results.
Future<Map<String, String>?> showFilterSheet(
  BuildContext context, {
  required List<FilterGroup> groups,
  required Map<String, String> selected,
}) {
  return showKitSheet<Map<String, String>>(
    context,
    padding: EdgeInsets.zero,
    builder: (context) =>
        _FilterSheet(groups: groups, initial: Map.of(selected)),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.groups, required this.initial});

  final List<FilterGroup> groups;
  final Map<String, String> initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final _sel = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Filters',
                  style: OgText.heading(26, color: c.text),
                ),
              ),
              KitIconButton(
                icon: OgIcons.close,
                label: 'Close',
                size: 20,
                background: context.tones.soft,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: kitSpaced([
                for (final g in widget.groups)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.title,
                        style: OgText.body(15, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < g.options.length; i++)
                            KitChip(
                              label: g.options[i],
                              icon: g.icons?[i],
                              selected: _sel[g.key] == g.options[i],
                              onTap: () => setState(() {
                                HapticFeedback.selectionClick();
                                if (_sel[g.key] == g.options[i]) {
                                  _sel.remove(g.key);
                                } else {
                                  _sel[g.key] = g.options[i];
                                }
                              }),
                            ),
                        ],
                      ),
                    ],
                  ),
              ], 18),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: KitButton.outline(
                  label: 'Reset',
                  onPressed: () => setState(_sel.clear),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: KitButton(
                  label: 'Show results',
                  onPressed: () => Navigator.of(context).pop(_sel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Today", "Yesterday" or "Mon 28 Sep", for grouping logs.
String dayLabel(DateTime at) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const mo = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${wd[at.weekday - 1]} ${at.day} ${mo[at.month - 1]}';
}

/// "2h ago", "yesterday", "3 days ago".
String agoLabel(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 60) return '${d.inMinutes.clamp(1, 59)}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays == 1) return 'yesterday';
  if (d.inDays < 30) return '${d.inDays} days ago';
  return dayLabel(at);
}
