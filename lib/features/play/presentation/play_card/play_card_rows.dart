import 'package:flutter/material.dart';

import '../../../../core/theme/og_type.dart';
import '../../../../core/widgets/og_icon.dart';
import '../../domain/activity.dart';
import 'play_card_line.dart';
import 'play_card_proof.dart';
import 'play_card_text.dart';

/// The rows under a tournament's or event's banner, 16 points from each side
/// and 14 below the banner: title (Inter 17 Medium); date row; venue row;
/// people row ([people]); friend row. Rows are 12 points apart and the last is
/// 16 from the bottom edge.
class PlayCardRows extends StatelessWidget {
  const PlayCardRows({
    super.key,
    required this.activity,
    required this.onHome,
    required this.people,
  });

  final Activity activity;
  final bool onHome;

  /// The people row's one line, for example "4/8 going • Free".
  final String people;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            a.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.type.section,
          ),
          const SizedBox(height: 12),
          PlayCardLine(
            OgIcons.calendarBox,
            playCardDateLine(a),
            playCardDateNote(a),
            tight: onHome,
          ),
          const SizedBox(height: 12),
          PlayCardLine(
            OgIcons.mapPin,
            a.online ? '${a.venue.name} and online' : a.venue.name,
            a.venue.address,
            tight: onHome,
          ),
          const SizedBox(height: 12),
          PlayCardIconRow(OgIcons.group, people),
          PlayCardFriendRow(proof: a.proof, onHome: onHome),
        ],
      ),
    );
  }
}
