import 'package:flutter/material.dart';

import '../../domain/activity.dart';
import 'event_card.dart';
import 'meet_card.dart';
import 'tournament_card.dart';

export 'event_card.dart';
export 'meet_card.dart';
export 'play_card_banner.dart';
export 'play_card_frame.dart';
export 'play_card_line.dart';
export 'play_card_proof.dart';
export 'play_card_rows.dart';
export 'play_card_save_button.dart';
export 'play_card_text.dart';
export 'tournament_card.dart';

/// The card for a Meet, tournament or event: it picks [MeetCard],
/// [TournamentCard] or [EventCard] by the activity's kind. Use the individual
/// cards when the kind is known. On Home the card is white with a light
/// border (near-black with a dark one in the dark theme).
class PlayCard extends StatelessWidget {
  const PlayCard({super.key, required this.activity, this.onHome = false});

  final Activity activity;
  final bool onHome;

  @override
  Widget build(BuildContext context) => switch (activity.kind) {
    ActivityKind.meet => MeetCard(activity: activity, onHome: onHome),
    ActivityKind.tournament => TournamentCard(
      activity: activity,
      onHome: onHome,
    ),
    ActivityKind.event => EventCard(activity: activity, onHome: onHome),
  };
}
