import 'package:flutter/material.dart';

import '../../domain/activity.dart';
import 'play_card_banner.dart';
import 'play_card_frame.dart';
import 'play_card_rows.dart';
import 'play_card_text.dart';

/// The Tournament card (owner, 15 Nov 2026): a banner with the save button
/// only (no cover title), then the title, date, venue, people ("LI–AD • 4/8
/// going • Free") and friend rows. No header row and no outline.
class TournamentCard extends StatelessWidget {
  const TournamentCard({
    super.key,
    required this.activity,
    this.onHome = false,
  });

  final Activity activity;
  final bool onHome;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    return PlayCardFrame(
      activity: a,
      onHome: onHome,
      outlined: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlayCardBanner(activity: a, onHome: onHome),
          PlayCardRows(
            activity: a,
            onHome: onHome,
            people:
                '${a.bands} • ${a.spotsTaken}/${a.capacity} going • '
                '${playCardEntryPrice(a)}',
          ),
        ],
      ),
    );
  }
}
