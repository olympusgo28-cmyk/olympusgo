import '../../social/domain/social_models.dart';

/// What the organizer marked for a player after the Meet.
enum Attendance {
  unmarked('unmarked'),
  present('present'),
  absent('absent');

  const Attendance(this.id);
  final String id;

  static Attendance fromId(String? id) =>
      values.firstWhere((a) => a.id == id, orElse: () => unmarked);
}

/// One person on a Meet's player list or waitlist.
class MeetPlayer {
  const MeetPlayer({
    required this.player,
    this.role = 'Member',
    this.rating,
    this.band,
    this.sessions = 0,
    this.guestOf,
    this.waitlistAt,
    this.attendance = Attendance.unmarked,
    this.isHost = false,
    this.walkIn = false,
    this.paidCash = false,
    this.checkedInAt,
  });

  final PlayerSummary player;

  /// The club role: "Member", "Admin", "Organizer".
  final String role;
  final double? rating;

  /// "MI", "LI".
  final String? band;
  final int sessions;

  /// The name of whoever brought them, for guests.
  final String? guestOf;

  /// Their place in the queue, for the waitlist.
  final int? waitlistAt;
  final Attendance attendance;
  final bool isHost;
  final bool walkIn;
  final bool paidCash;

  /// When they checked themselves in at the venue.
  final DateTime? checkedInAt;

  bool get isGuest => guestOf != null;

  /// "Member · 42 sessions", "Guest of Aaron Ng", "Organizer · playing".
  String get meta => guestOf != null
      ? 'Guest of $guestOf'
      : isHost
      ? 'Organizer · playing'
      : walkIn
      ? '$role · walk-in${paidCash ? ', paid cash' : ''}'
      : '$role · $sessions ${sessions == 1 ? 'session' : 'sessions'}';

  MeetPlayer copyWith({Attendance? attendance, DateTime? checkedInAt}) =>
      MeetPlayer(
        player: player,
        role: role,
        rating: rating,
        band: band,
        sessions: sessions,
        guestOf: guestOf,
        waitlistAt: waitlistAt,
        attendance: attendance ?? this.attendance,
        isHost: isHost,
        walkIn: walkIn,
        paidCash: paidCash,
        checkedInAt: checkedInAt ?? this.checkedInAt,
      );
}

/// What cancelling a Meet costs and who it touches, before it happens.
class CancelPreview {
  const CancelPreview({
    required this.players,
    required this.eachCents,
    required this.cardPayments,
    required this.cardFeeCents,
    required this.laterMeets,
    this.lastMeet,
  });

  /// Players who joined and get refunded.
  final int players;

  /// What each of them paid, platform fee included.
  final int eachCents;

  /// Card payments, whose card fees come off the organizer's earnings.
  final int cardPayments;
  final int cardFeeCents;

  /// Meets in the series from this one on, this one included.
  final int laterMeets;
  final DateTime? lastMeet;
}

/// The stats card after a Meet.
class MeetRecap {
  const MeetRecap({
    required this.games,
    required this.wins,
    required this.losses,
    this.bestGame,
    this.ratingBefore,
    this.ratingAfter,
    this.band,
    this.bestPartner,
    this.partnerWins = 0,
    required this.points,
    required this.session,
    this.clubName,
    this.clubLink,
  });

  final int games;
  final int wins;
  final int losses;

  /// "21–12".
  final String? bestGame;
  final double? ratingBefore;
  final double? ratingAfter;
  final String? band;
  final PlayerSummary? bestPartner;
  final int partnerWins;
  final int points;

  /// Which session this was for the player, all time.
  final int session;
  final String? clubName;
  final String? clubLink;

  double? get ratingChange => ratingBefore == null || ratingAfter == null
      ? null
      : ratingAfter! - ratingBefore!;
}

enum ScoreStatus {
  waiting('waiting'),
  confirmed('confirmed'),
  disputed('disputed');

  const ScoreStatus(this.id);
  final String id;

  static ScoreStatus fromId(String? id) =>
      values.firstWhere((s) => s.id == id, orElse: () => waiting);
}

/// A ranked match score: entered by one side, confirmed by the other.
class MatchScore {
  const MatchScore({
    required this.id,
    required this.activityId,
    required this.activityTitle,
    required this.sideA,
    required this.sideB,
    required this.games,
    required this.enteredBy,
    required this.enteredAt,
    this.court,
    this.status = ScoreStatus.waiting,
    this.reason,
    this.ratingBefore,
    this.ratingAfter,
    this.organizer,
  });

  final String id;
  final String activityId;
  final String activityTitle;

  /// Side A is the side that entered the score.
  final List<PlayerSummary> sideA;
  final List<PlayerSummary> sideB;

  /// Points per game, side A first.
  final List<(int, int)> games;
  final PlayerSummary enteredBy;
  final DateTime enteredAt;
  final String? court;
  final ScoreStatus status;
  final String? reason;

  /// The viewer's rating, before and after this match counts.
  final double? ratingBefore;
  final double? ratingAfter;
  final PlayerSummary? organizer;

  int get winsA => games.where((g) => gameWinner(g.$1, g.$2) == 1).length;
  int get winsB => games.where((g) => gameWinner(g.$1, g.$2) == 2).length;

  MatchScore copyWith({ScoreStatus? status, String? reason}) => MatchScore(
    id: id,
    activityId: activityId,
    activityTitle: activityTitle,
    sideA: sideA,
    sideB: sideB,
    games: games,
    enteredBy: enteredBy,
    enteredAt: enteredAt,
    court: court,
    status: status ?? this.status,
    reason: reason ?? this.reason,
    ratingBefore: ratingBefore,
    ratingAfter: ratingAfter,
    organizer: organizer,
  );
}

/// Who won a badminton game from its final score: 1 or 2, 0 while a side
/// is missing, -1 when the score can't happen. A game is won at 21 with 2
/// clear; from 20 all it goes on to a 2-point lead, capped at 30.
int gameWinner(int? a, int? b) {
  if (a == null || b == null) return 0;
  final hi = a > b ? a : b;
  final lo = a > b ? b : a;
  final won =
      hi == 21 && lo <= 19 ||
      hi > 21 && hi < 30 && hi - lo == 2 ||
      hi == 30 && lo >= 28;
  if (!won) return -1;
  return a > b ? 1 : 2;
}

/// One side has won 2 games, every game typed is a real score, and game 3
/// is only there when the first two were split.
bool matchDecided(List<(int?, int?)> games) {
  if (games.length < 2) return false;
  final r = [for (final g in games) gameWinner(g.$1, g.$2)];
  if (r[0] <= 0 || r[1] <= 0) return false;
  final third =
      games.length > 2 && (games[2].$1 != null || games[2].$2 != null);
  if (r[0] == r[1]) return !third;
  return third && r[2] > 0;
}
