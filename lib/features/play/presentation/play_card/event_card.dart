import 'package:flutter/material.dart';

import '../../domain/activity.dart';
import 'play_card_banner.dart';
import 'play_card_frame.dart';
import 'play_card_rows.dart';
import 'play_card_text.dart';

/// The Event card (owner, 15 Nov 2026): the same rows as the Tournament card,
/// with the going count and price on the people row ("1,284 going • Free").
/// The banner carries the save button only: no cover title, no Sponsored pill.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.activity, this.onHome = false});

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
                '${thousands(a.spotsTaken)} going • ${playCardEntryPrice(a)}',
          ),
        ],
      ),
    );
  }
}
