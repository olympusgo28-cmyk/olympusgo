import '../../social/domain/social_models.dart';
import 'activity.dart';

/// One event inside a tournament: "Men's singles", "Mixed doubles".
class Division {
  const Division({
    required this.id,
    required this.name,
    required this.doubles,
    required this.feeCents,
    required this.capacity,
    this.entries = 0,
    this.waiting = 0,
    this.bands = 'All levels',
  });

  final String id;
  final String name;
  final bool doubles;

  /// Per player for singles, per pair for doubles.
  final int feeCents;
  final int capacity;
  final int entries;
  final int waiting;

  /// "MB–AD".
  final String bands;

  bool get full => entries >= capacity;
  int get left => (capacity - entries).clamp(0, capacity);

  /// "S$15 · MB–AD", "S$30 per pair · LI–AD".
  String get priceLine =>
      'S\$${money(feeCents, decimals: feeCents % 100 != 0)}'
      '${doubles ? ' per pair' : ''} · $bands';
}

enum EntryStatus { paid, waitlist, partnerPending }

/// A player or pair entered in one division.
class Entry {
  const Entry({
    required this.id,
    required this.divisionId,
    required this.names,
    this.club,
    this.rating,
    this.seed,
    this.status = EntryStatus.paid,
    this.mine = false,
    this.checkedIn = false,
    this.group,
    this.firstMatch,
  });

  final String id;
  final String divisionId;

  /// "Ryan Teo", or "Tan and Lee" for a pair.
  final String names;
  final String? club;
  final double? rating;
  final int? seed;
  final EntryStatus status;
  final bool mine;
  final bool checkedIn;
  final String? group;

  /// "Group A, first match 10:20 AM".
  final String? firstMatch;

  Entry copyWith({bool? checkedIn}) => Entry(
    id: id,
    divisionId: divisionId,
    names: names,
    club: club,
    rating: rating,
    seed: seed,
    status: status,
    mine: mine,
    checkedIn: checkedIn ?? this.checkedIn,
    group: group,
    firstMatch: firstMatch,
  );
}

/// The viewer's place in a tournament.
class MyEntry {
  const MyEntry({
    required this.divisionId,
    required this.divisionName,
    this.partner,
    this.group,
    this.seed,
    this.firstMatchAt,
    this.firstCourt,
    required this.paidCents,
    required this.entryCents,
  });

  final String divisionId;
  final String divisionName;
  final PlayerSummary? partner;
  final String? group;
  final int? seed;
  final DateTime? firstMatchAt;
  final String? firstCourt;

  /// What they paid, and the entry fee inside it.
  final int paidCents;
  final int entryCents;

  int get feeCents => paidCents - entryCents;
}

/// A row in a group table.
class GroupRow {
  const GroupRow({
    required this.pos,
    required this.names,
    required this.seed,
    required this.rating,
    this.wins = 0,
    this.losses = 0,
    this.points = 0,
    this.mine = false,
  });

  final int pos;
  final String names;
  final int seed;
  final double rating;
  final int wins;
  final int losses;
  final int points;
  final bool mine;
}

class DrawGroup {
  const DrawGroup(this.name, this.rows);
  final String name;
  final List<GroupRow> rows;
}

class KnockoutMatch {
  const KnockoutMatch(this.a, this.b, this.when, {this.scoreA, this.scoreB});
  final String a;
  final String b;
  final String when;
  final int? scoreA;
  final int? scoreB;
}

class KnockoutRound {
  const KnockoutRound(this.name, this.matches);
  final String name;
  final List<KnockoutMatch> matches;
}

enum MatchState { done, called, next, later }

/// One of the viewer's matches.
class MyMatch {
  const MyMatch({
    required this.opponent,
    required this.at,
    required this.court,
    required this.state,
    this.stage = '',
    this.score,
    this.won,
  });

  /// "Tan and Lee".
  final String opponent;
  final DateTime at;
  final String court;
  final MatchState state;

  /// "Group B", "Semi-final", "3rd place".
  final String stage;

  /// "21–17, 21–19" or "2–1".
  final String? score;
  final bool? won;
}

/// How the viewer's tournament went.
class TournamentResult {
  const TournamentResult({
    required this.division,
    required this.place,
    required this.wins,
    required this.losses,
    required this.podium,
    required this.matches,
    this.ratingFrom,
    this.ratingTo,
    this.points = 0,
    this.entries = 0,
  });

  final String division;
  final int place;
  final int wins;
  final int losses;

  /// First, second and third, by name.
  final List<String> podium;
  final List<MyMatch> matches;
  final double? ratingFrom;
  final double? ratingTo;
  final int points;
  final int entries;
}

/// A suggested doubles partner.
class PartnerPick {
  const PartnerPick(this.player, this.meta);
  final PlayerSummary player;

  /// "MI · 8 Meets together".
  final String meta;
}

/// Everything the tournament page shows beyond the activity itself.
class TournamentInfo {
  const TournamentInfo({
    required this.activity,
    required this.divisions,
    this.host = '',
    this.hostMark = '',
    this.courts = 0,
    this.drawFormat = '',
    this.seeding = 'By main rating',
    this.divisionsText = 'Open',
    this.entryRule = 'Verified players',
    this.maxEvents = 2,
    this.spectatorEventId,
    this.spectatorTitle,
    this.mine,
    this.checkedIn = 0,
    this.finished = false,
    this.myLevel,
  });

  final Activity activity;
  final List<Division> divisions;
  final String host;
  final String hostMark;
  final int courts;
  final String drawFormat;
  final String seeding;

  /// "Open, U17".
  final String divisionsText;
  final String entryRule;

  /// How many events one player may enter.
  final int maxEvents;
  final String? spectatorEventId;
  final String? spectatorTitle;
  final MyEntry? mine;

  /// Entries checked in, for the organizer.
  final int checkedIn;
  final bool finished;

  /// The viewer's level in this sport, for the eligibility check.
  final double? myLevel;

  int get entries => divisions.fold(0, (a, d) => a + d.entries);

  /// The cheapest entry, for "From S$15 per entry".
  int get fromCents => divisions.isEmpty
      ? activity.feeCents
      : divisions.map((d) => d.feeCents).reduce((a, b) => a < b ? a : b);
}
