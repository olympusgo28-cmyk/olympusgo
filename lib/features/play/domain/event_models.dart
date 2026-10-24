import 'activity.dart';

/// A slot on an event's programme.
class ProgrammeItem {
  const ProgrammeItem({
    required this.id,
    required this.time,
    required this.title,
    required this.sub,
    this.plain = false,
    this.reminded = false,
  });

  final String id;

  /// "2:40 PM".
  final String time;
  final String title;
  final String sub;

  /// Not a match, so nothing to follow ("Prize giving").
  final bool plain;
  final bool reminded;

  ProgrammeItem copyWith({bool? reminded}) => ProgrammeItem(
    id: id,
    time: time,
    title: title,
    sub: sub,
    plain: plain,
    reminded: reminded ?? this.reminded,
  );
}

/// The match on the live court, with the crowd's cheers.
class LiveCourt {
  const LiveCourt({
    required this.label,
    required this.sideA,
    required this.sideB,
    required this.gamesA,
    required this.gamesB,
    this.cheersA = 0,
    this.cheersB = 0,
  });

  /// "COURT 1 · MEN'S DOUBLES FINAL".
  final String label;
  final String sideA;
  final String sideB;
  final List<int> gamesA;
  final List<int> gamesB;
  final int cheersA;
  final int cheersB;
}

/// Gear a finalist uses, sold in the shop.
class GearPick {
  const GearPick({
    required this.name,
    required this.priceCents,
    required this.player,
    required this.racket,
  });

  final String name;
  final int priceCents;
  final String player;

  /// A racket or a pair of shoes, for the picture.
  final bool racket;
}

class EventClub {
  const EventClub(this.mark, this.name, this.color, this.ink);
  final String mark;
  final String name;
  final int color;
  final int ink;
}

/// Everything the event page shows beyond the activity itself.
class EventInfo {
  const EventInfo({
    required this.activity,
    required this.about,
    required this.programme,
    this.programmeDay = '',
    this.clubs = const [],
    this.partOfId,
    this.partOfTitle,
    this.live,
    this.gear = const [],
    this.tickets = 0,
    this.paidCents = 0,
    this.refundBy,
    this.scannedIn = 0,
  });

  final Activity activity;
  final String about;
  final List<ProgrammeItem> programme;

  /// "Sun 25 Oct".
  final String programmeDay;
  final List<EventClub> clubs;

  /// The tournament this event shows, if any.
  final String? partOfId;
  final String? partOfTitle;
  final LiveCourt? live;
  final List<GearPick> gear;

  /// The viewer's tickets and what they paid.
  final int tickets;
  final int paidCents;
  final DateTime? refundBy;

  /// Tickets scanned at the door, for the organizer.
  final int scannedIn;

  bool get linked => partOfId != null;
}

/// The viewer's ticket, shown at the door.
class Ticket {
  const Ticket({
    required this.eventId,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.venue,
    required this.qty,
    required this.paidCents,
    required this.code,
    this.refundBy,
  });

  final String eventId;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String venue;
  final int qty;
  final int paidCents;

  /// The booking code in the QR.
  final String code;
  final DateTime? refundBy;

  int get points => qty * 4;
}

/// What the door scanner found.
class ScanResult {
  const ScanResult({
    required this.valid,
    required this.qty,
    required this.bookedBy,
    required this.title,
    required this.scanned,
    required this.capacity,
    this.usedAt,
  });

  final bool valid;
  final int qty;
  final String bookedBy;
  final String title;
  final int scanned;
  final int capacity;

  /// When it was used, if it was scanned before.
  final DateTime? usedAt;
}
