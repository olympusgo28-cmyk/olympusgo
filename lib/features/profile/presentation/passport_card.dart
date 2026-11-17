import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/pressable.dart';
import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../domain/profile.dart';

const _muted = Color(0xFFC9C6BC);

/// The Passport card (owner, 16 Nov 2026: it moved from Profile to the sport
/// profile): a dark card with the sport's name, the level and its band, three
/// numbers (sessions, club rank, clubs) and a link to the leaderboards.
///
/// [isMainSport] adds the "MAIN SPORT" pill.
class PassportCard extends StatelessWidget {
  const PassportCard({
    super.key,
    required this.sport,
    required this.sessions,
    required this.clubRank,
    required this.clubs,
    required this.localRank,
    required this.area,
    this.isMainSport = false,
  });

  final PlayerSport sport;
  final int sessions;
  final int? clubRank;
  final int clubs;
  final int? localRank;
  final String? area;
  final bool isMainSport;

  @override
  Widget build(BuildContext context) {
    final band = SkillBand.forLevel(sport.level);
    final label = Sport.fromId(sport.sport).label;
    Widget stat(String big, String small) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              big,
              style: context.type.section.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(small, style: context.type.caption.copyWith(color: _muted)),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      label:
          'Passport, $label ${sport.level.toStringAsFixed(1)}, ${band.label}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OgColors.ink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'PASSPORT · ${label.toUpperCase()}',
                    style: context.type.caption.copyWith(
                      color: _muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (isMainSport)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2C14E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'MAIN SPORT',
                      style: context.type.caption.copyWith(
                        color: const Color(0xFF3A2C00),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  sport.level.toStringAsFixed(1),
                  style: context.type.score.copyWith(
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '${band.label} · ${band.code}',
                    style: context.type.body.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                stat('$sessions', 'sessions'),
                const SizedBox(width: 8),
                stat(clubRank == null ? '–' : '#$clubRank', 'club rank'),
                const SizedBox(width: 8),
                stat('$clubs', clubs == 1 ? 'club' : 'clubs'),
              ],
            ),
            const SizedBox(height: 14),
            Pressable(
              semanticLabel: 'See leaderboards',
              onPressed: () => context.push(Routes.leaderboards),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localRank == null
                            ? 'See leaderboards'
                            : 'Local #$localRank${area == null ? '' : ' in $area'} · See leaderboards',
                        style: context.type.body.copyWith(color: Colors.white),
                      ),
                    ),
                    Text(
                      '›',
                      style: context.type.body.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
