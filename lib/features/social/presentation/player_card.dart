import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_home.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/pressable.dart';
import '../domain/social_models.dart';

/// The Player card (owner, 15 Nov 2026): 132 points wide, 22-point rounded
/// corners, 10 points of padding at the sides, 16 at the top and 14 at the
/// bottom. It is white (charcoal in dark mode) with no border and a soft
/// shadow below, on Home and elsewhere. A shelf holding it leaves room under
/// the cards so the shadow is not clipped.
///
/// Rows, from the top, 8 points apart: the avatar (60 points); the sport
/// icon (14 points in a 24-point disc, left out when there is no sport); the
/// title, the name (Inter 15 Medium, centred); the note (Inter 11 regular,
/// muted, centred, one line: gender and mutual counts, else "Suggested for
/// you"); then flexible space. Tapping opens the player's page. There is no
/// Follow button.
class PlayerCard extends StatelessWidget {
  const PlayerCard({super.key, required this.suggestion, this.onHome = false});

  final SuggestedPlayer suggestion;
  final bool onHome;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final h = context.home;
    final p = suggestion;
    // White (charcoal in dark mode), no border, with a soft shadow below, on
    // Home and elsewhere (owner, 15 Nov 2026). On Home the sport disc and the
    // name take the heading colour.
    final tile = h.surface;
    final strong = onHome ? h.heading : c.inverseCard;
    final onStrong = onHome ? h.surface : c.onInverseCard;
    return Pressable(
      semanticLabel: '${p.player.displayName}, ${p.note}',
      onPressed: () => context.push(Routes.player(p.player.id)),
      child: Container(
        width: 132,
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
        decoration: BoxDecoration(
          color: tile,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: h.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar row: 60 points, centred.
            SolidAvatar.forId(
              p.player.id,
              initials: p.player.initials,
              size: 60,
            ),
            // Sport icon row: the sport's icon, 14 points, in a 24-point disc,
            // 8 points under the avatar. Left out when there is no sport.
            if (p.sport != null) ...[
              const SizedBox(height: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: strong,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: OgIcon(
                  p.sport!.icon,
                  size: 14,
                  color: onStrong,
                  strokeWidth: 1.8,
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Title row: the name.
            Text(
              p.player.displayName,
              textAlign: TextAlign.center,
              style: context.type.body.copyWith(
                fontWeight: FontWeight.w500,
                color: onHome ? h.heading : null,
              ),
            ),
            const SizedBox(height: 8),
            // Note row: Inter 11 regular, muted, on one line.
            Text(
              p.note,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.caption.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 8),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
