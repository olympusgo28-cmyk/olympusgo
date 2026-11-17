import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../domain/profile.dart';

final ratingCardProvider = FutureProvider.autoDispose
    .family<RatingCard?, String>(
      (ref, sport) => ref.watch(profileRepositoryProvider).rating(sport),
    );

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
    final rating = ref.watch(ratingCardProvider(widget.sport)).value;
    final level =
        rating?.level ??
        ref
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
                style: context.type.caption.copyWith(
                  color: c.highlight,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    level == null
                        ? '—'
                        : '${SkillBand.forLevel(level).code} '
                              '${level.toStringAsFixed(1)}',
                    style: context.type.display.copyWith(
                      color: c.onInverseCard,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (level != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        SkillBand.forLevel(level).label,
                        style: context.type.body.copyWith(
                          color: c.onInverseCard,
                        ),
                      ),
                    ),
                ],
              ),
              if (rating != null && rating.provisional) ...[
                const SizedBox(height: 6),
                Text(
                  'Your level settles after 5 confirmed matches. You have '
                  'played ${rating.matches}.',
                  style: context.type.caption.copyWith(color: c.onInverseCard),
                ),
              ],
              if (rating != null && rating.history.length > 1) ...[
                const SizedBox(height: 14),
                Semantics(
                  label:
                      'Rating over your last ${rating.history.length} '
                      'results',
                  child: SizedBox(
                    height: 72,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _RatingLine(rating.history, c.highlight),
                    ),
                  ),
                ),
              ],
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
                // R-STA-2: a percentage waits for 5 matches.
                (
                  h.winRate == null
                      ? '—'
                      : rating != null && rating.matches < 5
                      ? '${rating.matches} of 5'
                      : '${h.winRate}%',
                  rating != null && rating.matches < 5
                      ? 'matches'
                      : 'games won',
                ),
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
                        Text(value, style: context.type.score),
                        Text(label, style: context.type.caption),
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
                  style: context.type.secondary,
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

class _RatingLine extends CustomPainter {
  const _RatingLine(this.points, this.color);

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final lo = points.reduce((a, b) => a < b ? a : b);
    final hi = points.reduce((a, b) => a > b ? a : b);
    final span = hi - lo == 0 ? 1 : hi - lo;
    final line = Path();
    for (final (i, p) in points.indexed) {
      final x = size.width * i / (points.length - 1);
      final y = size.height * (1 - (p - lo) / span);
      i == 0 ? line.moveTo(x, y) : line.lineTo(x, y);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RatingLine old) => old.points != points;
}
