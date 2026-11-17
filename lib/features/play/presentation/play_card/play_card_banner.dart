import 'package:flutter/material.dart';

import '../../../../core/theme/og_tones.dart';
import '../../../../core/theme/og_type.dart';
import '../../../../core/widgets/og_kit.dart';
import '../../domain/activity.dart';
import 'play_card_save_button.dart';

/// What an activity is stored with when nobody picked a cover.
const _defaultCover = 0xFF1C1F23;

/// The banner at the top of a card: the card's full width, 132 points tall,
/// all four corners rounded to 20, the save button 10 points from its top and
/// right. A Meet's banner also carries its cover title; tournaments and events
/// carry none.
class PlayCardBanner extends StatelessWidget {
  const PlayCardBanner({
    super.key,
    required this.activity,
    required this.onHome,
    this.showTitle = false,
  });

  final Activity activity;
  final bool onHome;

  /// Draw the cover title (or the name) on the banner.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final a = activity;
    final (tile, tileInk) = switch (a.kind) {
      ActivityKind.meet => (t.successFill, t.onSuccessFill),
      ActivityKind.tournament => (t.warnFill, t.warnInk),
      ActivityKind.event => (t.dangerFill, t.onDangerFill),
    };
    // An activity nobody gave a cover is stored near-black. On Home its banner
    // takes the kind's own colour instead (the same one as its icon tile).
    final plainCover = onHome && a.coverColor == _defaultCover;
    final color = plainCover ? tile : Color(a.coverColor);
    final ink = plainCover ? tileInk : Color(a.coverInk);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CourtHero(
        color: color,
        height: 132,
        child: Stack(
          children: [
            if (showTitle)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    a.coverTitle ?? a.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.title.copyWith(color: ink),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: PlayCardSaveButton(
                activity: a,
                glass: true,
                onLight: color.computeLuminance() > 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
