import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../../../core/theme/og_colors.dart';
import '../../../../core/theme/og_type.dart';
import '../../../../core/widgets/og_icon.dart';
import '../../domain/activity.dart';
import 'play_card_banner.dart';
import 'play_card_frame.dart';
import 'play_card_line.dart';
import 'play_card_proof.dart';
import 'play_card_save_button.dart';

/// The Meet card (owner, 15 Nov 2026): sport icon with "Meet · Casual" or
/// "Meet · Ranked"; title; date, time and one-time or recurring; venue and
/// address; players, skill range and price; the court row when a court is
/// booked; then a friend who joined. It has an outline. A Meet with a cover
/// title also gets a banner, and the heart moves onto it.
class MeetCard extends StatelessWidget {
  const MeetCard({super.key, required this.activity, this.onHome = false});

  final Activity activity;
  final bool onHome;

  /// "Court booked · 2 courts", "Court booked · 1 court", or "Court booked"
  /// when the host gave no count. Null when the court isn't booked: the card
  /// says nothing then (owner, 15 Nov 2026; Q270 n).
  static String? courtLine(Activity a) {
    if (!a.courtBooked) return null;
    final n = a.courts;
    if (n == null) return 'Court booked';
    return 'Court booked · $n ${n == 1 ? 'court' : 'courts'}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final a = activity;
    final hasBanner = a.coverTitle != null;
    final sport = a.sports.isEmpty ? null : a.sports.first;
    final dateTime =
        '${Fmt.dayShortYear(a.startsAt)} · '
        '${Fmt.timeRange(a.startsAt, a.endsAt)}';
    final players = [
      '${a.spotsTaken}/${a.capacity} players',
      a.bands,
      a.isFree ? 'Free' : 'S\$${money(a.feeCents)} / person',
    ].join(' · ');
    final courts = courtLine(a);

    return PlayCardFrame(
      activity: a,
      onHome: onHome,
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasBanner)
            PlayCardBanner(activity: a, onHome: onHome, showTitle: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row: the sport's icon, then "Meet · Casual" or
                // "Meet · Ranked".
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      OgIcon(
                        sport?.icon ?? OgIcons.racquet,
                        size: 24,
                        color: c.text,
                        strokeWidth: 1.8,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${a.kind.label} · ${a.ranked ? 'Ranked' : 'Casual'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.body,
                        ),
                      ),
                      // Cards with a banner have the heart on the banner.
                      if (!hasBanner)
                        Transform.translate(
                          offset: const Offset(8, 0),
                          child: PlayCardSaveButton(activity: a),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Title row.
                Text(
                  a.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.section,
                ),
                const SizedBox(height: 12),
                // Date row: date and time, then one-time or recurring.
                PlayCardLine(
                  OgIcons.calendarBox,
                  dateTime,
                  a.recurrence == null
                      ? 'One-time'
                      : 'Recurring · ${a.recurrence}',
                  tight: onHome,
                ),
                const SizedBox(height: 12),
                // Venue row.
                PlayCardLine(
                  OgIcons.mapPin,
                  a.online ? '${a.venue.name} and online' : a.venue.name,
                  a.venue.address,
                  tight: onHome,
                ),
                const SizedBox(height: 12),
                // Player row.
                PlayCardIconRow(OgIcons.group, players),
                // Court row, only when the host has booked the court.
                if (courts != null) ...[
                  const SizedBox(height: 12),
                  PlayCardIconRow(OgIcons.court, courts),
                ],
                // Friend row: "is going" reads "joined".
                PlayCardFriendRow(
                  proof: a.proof == null ? null : playCardJoined(a.proof!),
                  onHome: onHome,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
