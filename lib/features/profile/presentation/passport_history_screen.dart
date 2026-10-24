import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../domain/profile.dart';

final _historyProvider = FutureProvider.autoDispose
    .family<PassportHistory, String>(
      (ref, sport) => ref.watch(profileRepositoryProvider).history(sport),
    );

/// Every past session in one sport, and how games went.
class PassportHistoryScreen extends ConsumerStatefulWidget {
  const PassportHistoryScreen({super.key, required this.sport});

  final String sport;

  @override
  ConsumerState<PassportHistoryScreen> createState() =>
      _PassportHistoryScreenState();
}

class _PassportHistoryScreenState extends ConsumerState<PassportHistoryScreen> {
  static const _filters = ['All', 'Meets', 'Tournaments', 'Classes'];
  var _filter = 0;

  bool _shown(HistoryItem i) => switch (_filter) {
    1 => i.kind == 'meet',
    2 => i.kind == 'tournament',
    3 => i.kind == 'class',
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final sport = Sport.fromId(widget.sport);
    final level = ref
        .watch(mySportsProvider)
        .value
        ?.where((s) => s.sport == widget.sport)
        .firstOrNull
        ?.level;
    final h = ref.watch(_historyProvider(widget.sport)).value;
    return KitScaffold(
      header: const KitHeader(title: 'Sessions and rating'),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.inverseCard,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${sport.label} rating'.toUpperCase(),
                style: OgText.body(
                  12,
                  weight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: c.highlight,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    level?.toStringAsFixed(1) ?? '—',
                    style: OgText.display(48, color: c.onInverseCard),
                  ),
                  const SizedBox(width: 10),
                  if (level != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        SkillBand.forLevel(level).label,
                        style: OgText.body(
                          16,
                          weight: FontWeight.w700,
                          color: c.onInverseCard,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (h == null)
          const CupertinoActivityIndicator()
        else ...[
          Row(
            children: [
              for (final (i, (value, label)) in [
                ('${h.sessions}', 'sessions'),
                ('${h.rankedGames}', 'ranked games'),
                (h.winRate == null ? '—' : '${h.winRate}%', 'games won'),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: context.tones.soft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(value, style: OgText.heading(22)),
                        Text(label, style: OgText.body(13, color: c.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          KitSegments(
            labels: _filters,
            selected: _filter,
            fontSize: 13,
            onSelect: (i) => setState(() => _filter = i),
          ),
          if (h.items.where(_shown).isEmpty)
            DashedBox(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  h.items.isEmpty
                      ? 'No ${sport.label.toLowerCase()} sessions yet. Join a Meet and it shows here.'
                      : 'Nothing here yet.',
                  style: OgText.body(14, color: c.textMuted),
                ),
              ),
            )
          else
            KitCard(
              children: [
                for (final i in h.items.where(_shown))
                  KitNavTile(
                    icon: _icon(i.kind),
                    title: i.title,
                    subtitle: '${Fmt.day(i.at)} · ${_line(i)}',
                    onTap: i.kind == 'class'
                        ? null
                        : () => context.push(Routes.activity(i.id)),
                    chevron: i.kind != 'class',
                  ),
              ],
            ),
        ],
        const KitNote(
          'Your rating moves only after ranked scores are confirmed. Casual Meets and classes count as sessions but do not change it.',
        ),
      ],
    );
  }

  static String _icon(String kind) => switch (kind) {
    'tournament' => OgIcons.trophyTeam,
    'class' => OgIcons.mortarboard,
    'event' => OgIcons.ticket,
    _ => OgIcons.racquet,
  };

  static String _line(HistoryItem i) {
    final kind = switch (i.kind) {
      'tournament' => 'Tournament',
      'event' => 'Event',
      'class' => 'Class',
      _ => 'Meet',
    };
    if (i.played == 0) return i.ranked ? '$kind, no confirmed scores' : kind;
    return '$kind, won ${i.won} of ${i.played} '
        '${i.played == 1 ? 'game' : 'games'}';
  }
}
