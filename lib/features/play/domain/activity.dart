import 'package:freezed_annotation/freezed_annotation.dart';

import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../../social/domain/social_models.dart';

part 'activity.freezed.dart';

enum ActivityKind {
  meet('meet', 'Meet'),
  tournament('tournament', 'Tournament'),
  event('event', 'Event');

  const ActivityKind(this.id, this.label);
  final String id;
  final String label;

  static ActivityKind fromId(String id) => values.firstWhere((k) => k.id == id);
}

enum GameType {
  singles('singles', 'Singles'),
  doubles('doubles', 'Doubles'),
  mixed('mixed', 'Mixed'),

  /// Rotating partners, any format.
  social('social', 'Social');

  const GameType(this.id, this.label);
  final String id;
  final String label;

  static GameType? fromId(String? id) =>
      values.where((g) => g.id == id).firstOrNull;
}

/// The format choices per kind, as the create screens list them.
enum ActivityFormat {
  openPlay('open_play', 'Open play'),
  roundRobin('round_robin', 'Round robin'),
  kingOfTheCourt('king_of_the_court', 'King of the court'),
  ladder('ladder', 'Ladder'),
  knockout('knockout', 'Knockout'),
  groupsKnockout('groups_knockout', 'Groups and knockout'),
  festival('festival', 'Festival'),
  clinic('clinic', 'Clinic'),
  social('social', 'Social'),
  fundraiser('fundraiser', 'Fundraiser');

  const ActivityFormat(this.id, this.label);
  final String id;
  final String label;

  static ActivityFormat fromId(String id) =>
      values.firstWhere((f) => f.id == id);

  static const meetFormats = [openPlay, roundRobin, kingOfTheCourt, ladder];
  static const tournamentFormats = [knockout, roundRobin, groupsKnockout];
  static const eventTypes = [festival, clinic, social, fundraiser];
}

/// Where the viewer stands with an activity.
enum MyStatus { none, joined, waitlist, requested }

@freezed
abstract class Venue with _$Venue {
  const factory Venue({
    required String id,
    required String name,
    required String address,
    @Default('') String distance,
  }) = _Venue;
}

/// The "who is going" line on a play card: a face (or club mark), a bold
/// name and the rest of the sentence.
@freezed
abstract class SocialProof with _$SocialProof {
  const factory SocialProof({
    required String mark,
    required int color,
    @Default(0xFFFFFFFF) int ink,
    required String name,
    required String text,
    String? playerId,
  }) = _SocialProof;
}

/// A Meet, tournament or event, as shown in lists and on its detail page.
@freezed
abstract class Activity with _$Activity {
  const factory Activity({
    required String id,
    required ActivityKind kind,
    required String title,
    String? description,
    required List<Sport> sports,
    GameType? gameType,
    required ActivityFormat format,
    double? levelMin,
    double? levelMax,
    required DateTime startsAt,
    required DateTime endsAt,
    required Venue venue,
    String? court,
    required int capacity,
    @Default(0) int spotsTaken,
    @Default(0) int waitlistCount,
    @Default(0) int feeCents,
    @Default(false) bool allowGuests,
    @Default(false) bool approvalRequired,
    DateTime? registrationClosesAt,
    required PlayerSummary host,
    @Default(0) int hostMeetCount,
    @Default(MyStatus.none) MyStatus myStatus,
    @Default(0) int myWaitlistPosition,
    @Default(false) bool iAmHost,

    /// The organizer holds a spot too, rather than organizing only.
    @Default(true) bool hostPlaying,
    @Default([]) List<PlayerSummary> going,

    /// Set when a club runs this session.
    String? clubId,

    /// Ranked sessions count toward ratings and leaderboards.
    @Default(false) bool ranked,
    @Default(0) int men,
    @Default(0) int women,

    /// "Every Tue and Fri".
    String? recurrence,

    /// The line under the date ("Men's doubles final on Court 1 now").
    String? subtitle,

    /// Tournaments and events carry a cover: a colour and a title on it.
    String? coverTitle,
    @Default(0xFF16181B) int coverColor,
    @Default(0xFFFFFFFF) int coverInk,

    /// "Regional" on tournament cards.
    String? tier,

    /// Events streaming now, and events also shown online.
    @Default(false) bool live,
    @Default(false) bool online,
    @Default(0) int watching,

    /// "All ages" on event cards.
    String? audience,
    SocialProof? proof,

    /// On a free Meet, players pay the S\$2 platform fee themselves.
    @Default(false) bool playersPayFee,
    @Default(false) bool levelAsNumbers,
    @Default(0) int minPlayers,

    /// A tournament's events, by key (MS, WS, MD, WD, XD).
    @Default([]) List<String> divisionKeys,

    /// The event showing this tournament, or the tournament an event shows.
    String? linkedId,
  }) = _Activity;

  const Activity._();

  /// The platform fee each player pays on top of [feeCents].
  int get platformCents =>
      feeCents > 0 ? platformFee(feeCents) : (playersPayFee ? 200 : 0);

  /// What one spot costs, platform fee included.
  int get totalCents => feeCents + platformCents;

  bool get isFree => totalCents == 0;

  /// The organizer's own spot: no session fee, just the platform fee.
  int get hostSpotCents => feeCents > 0 ? platformFee(feeCents) : 200;
  bool get isFull => spotsTaken >= capacity;
  int get spotsLeft => (capacity - spotsTaken).clamp(0, capacity);

  /// "Badminton · Doubles", "Festival", "Tournament".
  String get eyebrow => switch (kind) {
    ActivityKind.event => format.label,
    _ => [
      sports.first.label,
      if (gameType != null) gameType!.label,
    ].join(' · '),
  };

  /// Fee pill: "S$ 8", "Free", "Full".
  /// What a spot costs, platform fee included.
  String get priceLabel => isFree
      ? 'Free'
      : 'S\$ ${money(totalCents, decimals: totalCents % 100 != 0)}';

  /// The third line on a card.
  String get availability => switch (kind) {
    ActivityKind.tournament => '$capacity teams · $spotsLeft left',
    ActivityKind.event => isFree ? 'Free ticket' : '$spotsLeft tickets left',
    ActivityKind.meet =>
      isFull
          ? 'Full · waitlist open'
          : '$spotsLeft spot${spotsLeft == 1 ? '' : 's'} left',
  };

  /// "LI–HI" (or "3.0–5.9") from the level range, "All levels" when open.
  String get bands {
    if (levelMin == null || levelMax == null) return 'All levels';
    if (levelAsNumbers) {
      return '${levelMin!.toStringAsFixed(1)}–${levelMax!.toStringAsFixed(1)}';
    }
    return LevelRange(
      SkillBand.forLevel(levelMin!).index,
      SkillBand.forLevel(levelMax!).index,
    ).label;
  }

  /// Several days, like most tournaments.
  bool get multiDay =>
      endsAt.difference(startsAt).inHours >= 24 ||
      endsAt.day != startsAt.day && endsAt.difference(startsAt).inHours > 12;

  String? get levelRange => levelMin == null || levelMax == null
      ? null
      : '${levelMin!.toStringAsFixed(1)} to ${levelMax!.toStringAsFixed(1)}';
}

/// "8", "8.00", "86.40".
String money(int cents, {bool decimals = true}) =>
    decimals ? (cents / 100).toStringAsFixed(2) : (cents ~/ 100).toString();

/// The platform fee on anything paid: 10%, minimum S\$2.
int platformFee(int cents) {
  if (cents <= 0) return 0;
  final tenth = (cents * 0.1).round();
  return tenth < 200 ? 200 : tenth;
}

/// Banner colours to pick from, with the ink each one uses.
const bannerColors = [
  (0xFF16181B, 0xFFF2C14E),
  (0xFF2F3A5F, 0xFFFFFFFF),
  (0xFF0E6B4E, 0xFFFFFFFF),
  (0xFFE8590C, 0xFFFFFFFF),
  (0xFFC8553D, 0xFFFFFFFF),
  (0xFF7A4E9C, 0xFFFFFFFF),
];

int bannerInk(int color) => bannerColors
    .firstWhere((b) => b.$1 == color, orElse: () => (color, 0xFFFFFFFF))
    .$2;

/// A completed payment, for the receipt.
@freezed
abstract class Receipt with _$Receipt {
  const factory Receipt({
    required String activityId,
    @Default(ActivityKind.meet) ActivityKind activityKind,
    required String receiptNo,
    required String activityTitle,
    required DateTime activityStartsAt,
    required String paidWith,
    required int feeCents,
    required int platformFeeCents,
    required String email,
  }) = _Receipt;

  const Receipt._();
  int get totalCents => feeCents + platformFeeCents;
}

/// Filters on the Play list, per kind.
@freezed
abstract class PlayFilters with _$PlayFilters {
  const factory PlayFilters({
    @Default('any') String when, // any, today, week, weekend, month
    GameType? gameType,
    @Default(1.0) double levelMin,
    @Default(8.0) double levelMax,
    @Default('any')
    String fee, // any, free, under, over (meet); tournament bands
    @Default('anywhere') String distance,
    ActivityFormat? format,
    @Default('open') String registration,
  }) = _PlayFilters;
}

/// One sport chip in Play and its options sheet.
@freezed
abstract class PlaySportPref with _$PlaySportPref {
  const factory PlaySportPref({
    required Sport sport,
    GameType? gameType,
    @Default(1.0) double levelMin,
    @Default(8.0) double levelMax,
  }) = _PlaySportPref;
}

/// Everything the create flows collect before publishing.
@freezed
abstract class ActivityDraft with _$ActivityDraft {
  const factory ActivityDraft({
    @Default(ActivityKind.meet) ActivityKind kind,
    @Default([Sport.badminton]) List<Sport> sports,
    @Default('') String title,
    @Default('') String description,
    GameType? gameType,
    ActivityFormat? format,
    @Default(3.0) double levelMin,
    @Default(5.0) double levelMax,
    DateTime? date,
    DateTime? endDate,
    @Default(19) int hour,
    @Default(30) int minute,
    @Default(120) int durationMinutes,
    Venue? venue,
    @Default(12) int capacity,
    @Default(3) int courts,
    @Default(false) bool approvalRequired,
    @Default(true) bool chargeFee,
    @Default(800) int feeCents,
    @Default(true) bool allowGuests,
    @Default('Best of 3 to 21') String scoring,
    @Default(true) bool seedByLevel,
    @Default(false) bool umpireScores,
    @Default(true) bool allowRefunds,
    DateTime? registrationCloses,

    /// Set when the session is created from a club page.
    String? clubId,

    /// The banner: a short title on a colour. Tournaments must have one.
    String? coverTitle,
    @Default(0xFF16181B) int coverColor,

    // Meets.

    /// How often it runs: once, weekly or every other week.
    @Default(Repeat.once) Repeat repeat,

    /// Weekdays it runs on (1 is Monday), when it repeats.
    @Default(<int>[]) List<int> repeatDays,
    @Default(8) int repeatCount,

    /// Below this many sign-ups a day before, the host decides to cancel.
    @Default(4) int minPlayers,

    /// Off: every level can join.
    @Default(true) bool restrictLevel,

    /// Show the level as "3.0–5.9" instead of "LI–HI".
    @Default(false) bool levelAsNumbers,
    @Default(false) bool ranked,

    /// A free Meet still has the S\$2 platform fee: false means the host
    /// pays it for each player.
    @Default(false) bool playersPayFee,
    @Default(false) bool hostInvitesOnly,
    @Default(false) bool listPublicly,

    // Tournaments.

    /// Club, Regional or National.
    @Default('Regional') String tier,

    /// Teams enter with a roster instead of players and pairs.
    @Default(false) bool teamEntry,

    /// The events inside it, by key: MS, WS, MD, WD, XD.
    @Default(<String>['MS', 'WS', 'MD', 'XD']) List<String> divisionKeys,
    @Default(<String>['Open']) List<String> ageDivisions,

    /// Below this many entries at close, an event is cancelled and refunded.
    @Default(8) int minEntries,
    @Default(true) bool verifiedOnly,
    @Default(true) bool matchCheckIn,
    @Default(true) bool waitlistWhenFull,

    /// The event that shows this tournament (or the tournament an event
    /// shows).
    String? linkedId,

    // Events.
    @Default(false) bool online,

    /// Set when changing a published activity rather than creating one.
    String? editingId,
  }) = _ActivityDraft;

  const ActivityDraft._();

  bool get editing => editingId != null;

  DateTime? get startsAt => date == null
      ? null
      : DateTime(date!.year, date!.month, date!.day, hour, minute);

  /// Every start time this draft makes: one, or [repeatCount] of a series.
  List<DateTime> get occurrences {
    final first = startsAt;
    if (first == null) return const [];
    if (repeat == Repeat.once || repeatDays.isEmpty) return [first];
    final step = repeat == Repeat.biweekly ? 14 : 7;
    final out = <DateTime>[];
    // Week by week from the first date's Monday, on each picked day.
    final monday = first.subtract(Duration(days: first.weekday - 1));
    for (var w = 0; out.length < repeatCount && w < 120; w += step) {
      for (final d in [...repeatDays]..sort()) {
        final day = monday.add(Duration(days: w + d - 1));
        final at = DateTime(day.year, day.month, day.day, hour, minute);
        if (!at.isBefore(first) && out.length < repeatCount) out.add(at);
      }
    }
    return out;
  }

  /// "Every Tue and Fri", "Every other Sat".
  String? get recurrenceLabel {
    if (repeat == Repeat.once || repeatDays.isEmpty) return null;
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = [
      for (final d in [...repeatDays]..sort()) names[d - 1],
    ];
    final joined = days.length == 1
        ? days.first
        : '${days.sublist(0, days.length - 1).join(', ')} and ${days.last}';
    return '${repeat == Repeat.biweekly ? 'Every other' : 'Every'} $joined';
  }
}

/// A tournament event key and its name: MS is "Men's singles".
const divisionNames = {
  'MS': "Men's singles",
  'WS': "Women's singles",
  'MD': "Men's doubles",
  'WD': "Women's doubles",
  'XD': 'Mixed doubles',
};

enum Repeat {
  once('Once'),
  weekly('Weekly'),
  biweekly('Every 2 weeks');

  const Repeat(this.label);
  final String label;
}
