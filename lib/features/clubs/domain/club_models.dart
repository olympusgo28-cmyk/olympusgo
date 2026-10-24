import 'package:freezed_annotation/freezed_annotation.dart';

import '../../social/domain/social_models.dart';
import 'club_sport.dart';

part 'club_models.freezed.dart';

enum ClubVisibility {
  public('public', 'Public', 'Public club'),
  private('private', 'Private', 'Private club'),
  hidden('hidden', 'Hidden', 'Hidden club');

  const ClubVisibility(this.id, this.label, this.title);
  final String id;
  final String label;
  final String title;

  static ClubVisibility fromId(String id) =>
      values.firstWhere((v) => v.id == id);
}

enum JoinMode {
  anyone('anyone'),
  request('request');

  const JoinMode(this.id);
  final String id;

  static JoinMode fromId(String id) => values.firstWhere((v) => v.id == id);
}

/// Where the viewer stands with a club.
enum ClubStanding { outsider, requested, member, banned }

/// What a role lets members do. Everyone can already join Meets, invite
/// friends and rate Meets they attended.
enum ClubPermission {
  createMeet('create_meet', 'Create Meets', 'Host Meets for the club'),
  publicMeet('public_meet', 'Make Meets public', 'Open a Meet to non-members'),
  markAttendance(
    'mark_attendance',
    'Mark attendance',
    'Mark players present and confirm scores',
  ),
  tournament(
    'tournament',
    'Run tournaments',
    'Create and manage club tournaments',
  ),
  events('events', 'Create events', 'Spectator pages, tickets and cheers'),
  approve('approve', 'Approve join requests', 'Accept or decline new members'),
  members('members', 'Manage members', 'Remove members and assign roles'),
  roles('roles', 'Manage roles', 'Create and edit roles'),
  editPage('edit_page', 'Edit club info', 'Change about, rules and details'),
  audit('audit', 'View audit log', 'See who changed what in the club'),
  fees('fees', 'Manage fees and payouts', 'Only the owner can grant this');

  const ClubPermission(this.id, this.label, this.hint);
  final String id;
  final String label;
  final String hint;

  static ClubPermission? fromId(String id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }

  static const organizer = {createMeet, publicMeet, markAttendance};
  static const admin = {
    ...organizer,
    tournament,
    approve,
    members,
    roles,
    editPage,
  };
}

/// How much a new role can do, from the create-role slider.
enum RoleLevel {
  label('Label'),
  member('Member'),
  organizer('Organizer'),
  admin('Admin');

  const RoleLevel(this.title);
  final String title;

  Set<ClubPermission> get permissions => switch (this) {
    label || member => const {},
    organizer => ClubPermission.organizer,
    admin => ClubPermission.admin,
  };
}

/// One sport a club plays, with its level range.
@freezed
abstract class ClubSportLevel with _$ClubSportLevel {
  const factory ClubSportLevel({
    required ClubSport sport,
    @Default(LevelRange.all()) LevelRange range,
  }) = _ClubSportLevel;
}

/// Everything a club page shows. Colours are ARGB ints so they come straight
/// from the database.
@freezed
abstract class Club with _$Club {
  const factory Club({
    required String id,
    required String name,
    @Default('') String description,
    @Default([]) List<String> rules,
    @Default('') String area,
    String? homeVenue,
    @Default([]) List<ClubSportLevel> sports,
    @Default(ClubVisibility.public) ClubVisibility visibility,
    @Default(JoinMode.request) JoinMode joinMode,
    @Default(0) int memberCount,
    double? rating,
    @Default(0) int ratingCount,
    @Default([0, 0, 0, 0, 0]) List<int> ratingSpread,
    @Default(0xFF1C1F23) int logoColor,
    @Default(0xFFF2C14E) int logoInk,
    @Default(0xFFE8590C) int coverColor,
    DateTime? createdAt,
    @Default(0) int meetsPerWeek,
    @Default(ClubStanding.outsider) ClubStanding standing,
    @Default(false) bool isOwner,
    @Default({}) Set<ClubPermission> myPermissions,
    String? myRoleName,
    @Default(0) int pendingRequests,
    @Default(0) int unreadChat,
    @Default(0) int roleCount,
    @Default(0) int banCount,
    @Default(0) int activeInvites,
    @Default({}) Map<String, String> playRules,
    String? inviteCode,
  }) = _Club;

  const Club._();

  String get initials => clubInitials(name);
  ClubSport? get primarySport => sports.isEmpty ? null : sports.first.sport;
  LevelRange get primaryRange =>
      sports.isEmpty ? const LevelRange.all() : sports.first.range;
  String get sportLabels => sports.map((s) => s.sport.label).join(', ');
  bool get isMember => standing == ClubStanding.member;
  bool can(ClubPermission p) => isOwner || myPermissions.contains(p);
  bool get canManage => isOwner || myPermissions.isNotEmpty;
}

/// A row in the clubs list, with the line under its name.
@freezed
abstract class ClubListItem with _$ClubListItem {
  const factory ClubListItem({required Club club, @Default('') String note}) =
      _ClubListItem;
}

@freezed
abstract class ClubRole with _$ClubRole {
  const factory ClubRole({
    required String id,
    required String name,
    @Default(0xFF7A8088) int color,
    @Default(RoleLevel.member) RoleLevel level,
    @Default({}) Set<ClubPermission> permissions,
    @Default(0) int memberCount,
    @Default(true) bool showBadge,
    @Default(false) bool isOwner,
    @Default(0) int position,
  }) = _ClubRole;

  const ClubRole._();
  bool get isLabel => level == RoleLevel.label;
}

@freezed
abstract class ClubMember with _$ClubMember {
  const factory ClubMember({
    required PlayerSummary player,
    double? rating,
    @Default([]) List<String> roleIds,
    DateTime? joinedAt,
    @Default(0) int meetsPlayed,
    @Default(0) int noShows,
    @Default(0) int paidCents,
  }) = _ClubMember;

  const ClubMember._();
  SkillBand? get band => rating == null ? null : SkillBand.forLevel(rating!);
}

enum RequestStatus { pending, approved, declined }

@freezed
abstract class JoinRequest with _$JoinRequest {
  const factory JoinRequest({
    required String id,
    required PlayerSummary player,
    required DateTime createdAt,
    double? rating,
    @Default(0) int sessions,
    @Default(0) int mutual,
    @Default(false) bool provisional,
    @Default(false) bool belowRange,
    @Default('') String message,
    @Default(RequestStatus.pending) RequestStatus status,
  }) = _JoinRequest;
}

@freezed
abstract class ClubBan with _$ClubBan {
  const factory ClubBan({
    required PlayerSummary player,
    required String bannedBy,
    required DateTime at,
    @Default('') String reason,
  }) = _ClubBan;
}

enum AuditCategory {
  members('members', 'Members'),
  roles('roles', 'Roles'),
  meets('meets', 'Meets'),
  club('club', 'Club');

  const AuditCategory(this.id, this.label);
  final String id;
  final String label;

  static AuditCategory fromId(String id) =>
      values.firstWhere((v) => v.id == id);
}

@freezed
abstract class AuditEntry with _$AuditEntry {
  const factory AuditEntry({
    required String id,
    required AuditCategory category,
    required String actor,
    required String action,
    @Default('') String detail,
    required DateTime at,
  }) = _AuditEntry;
}

@freezed
abstract class Announcement with _$Announcement {
  const factory Announcement({
    required String id,
    required String author,
    required String authorRole,
    required String title,
    required String body,
    @Default(false) bool pinned,
    required DateTime at,
  }) = _Announcement;
}

enum MessageKind { text, meet, lineup, photo, system }

/// A Meet shared into a group chat.
@freezed
abstract class SharedMeet with _$SharedMeet {
  const factory SharedMeet({
    required String activityId,
    required String title,
    required DateTime startsAt,
    required String detail,
  }) = _SharedMeet;
}

/// A message in a club or team chat.
@freezed
abstract class GroupMessage with _$GroupMessage {
  const factory GroupMessage({
    required String id,
    required PlayerSummary sender,
    @Default('') String body,
    @Default(MessageKind.text) MessageKind kind,
    String? roleName,
    int? roleColor,
    SharedMeet? meet,

    /// A shared photo: a storage URL, or a local file path in demo mode.
    String? photo,
    @Default(false) bool removed,
    String? removedBy,
    required DateTime at,
  }) = _GroupMessage;
}

@freezed
abstract class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required PlayerSummary player,
    required String score,
    @Default('') String sub,

    /// "up 2", "down 1", "same" or "new".
    @Default('same') String move,
  }) = _LeaderboardEntry;
}

@freezed
abstract class ClubLeaderboard with _$ClubLeaderboard {
  const factory ClubLeaderboard({
    required String period,
    @Default([]) List<LeaderboardEntry> rows,
    LeaderboardEntry? me,
    int? myRank,
    @Default('') String myNote,
  }) = _ClubLeaderboard;
}

@freezed
abstract class RewardMeet with _$RewardMeet {
  const factory RewardMeet({
    required String title,
    required DateTime at,
    required int paidPresent,
  }) = _RewardMeet;
}

@freezed
abstract class ClubReward with _$ClubReward {
  const factory ClubReward({
    @Default(4) int target,
    @Default(6) int minPlayers,
    @Default('S\$20 shuttle voucher') String prize,
    @Default([]) List<RewardMeet> meets,
    @Default([]) List<(String, String)> past,
  }) = _ClubReward;

  const ClubReward._();
  int get done => meets.where((m) => m.paidPresent >= minPlayers).length;
}

/// A player you have played with, offered when inviting.
@freezed
abstract class InviteCandidate with _$InviteCandidate {
  const factory InviteCandidate({
    required PlayerSummary player,
    double? rating,
    @Default(0) int meetsTogether,
    @Default('') String club,
    @Default('') String age,
  }) = _InviteCandidate;
}

/// Answers from the four create-club steps.
@freezed
abstract class ClubDraft with _$ClubDraft {
  const factory ClubDraft({
    @Default('') String name,
    @Default('') String description,
    String? venueId,
    String? venueName,
    @Default('') String area,
    @Default(ClubVisibility.public) ClubVisibility visibility,
    @Default(JoinMode.request) JoinMode joinMode,
    @Default([]) List<ClubSport> sports,
    @Default({}) Map<ClubSport, LevelRange> ranges,
    @Default({}) Set<String> invite,
  }) = _ClubDraft;
}

// ─── Teams ─────────────────────────────────────────────────────────────────

enum TeamRole { player, staff, owner }

enum Availability {
  available('available', 'Available'),
  unavailable('unavailable', 'Unavailable'),
  maybe('maybe', 'Not sure yet'),
  noReply('no_reply', 'No reply');

  const Availability(this.id, this.label);
  final String id;
  final String label;

  static Availability fromId(String id) =>
      values.firstWhere((v) => v.id == id, orElse: () => noReply);
}

@freezed
abstract class SubTeam with _$SubTeam {
  const factory SubTeam({
    required String name,
    @Default('') String rule,
    @Default(false) bool enabled,
    @Default(0) int players,
  }) = _SubTeam;
}

@freezed
abstract class Team with _$Team {
  const factory Team({
    required String id,
    required String name,
    @Default('') String represents,
    @Default(ClubSport.badminton) ClubSport sport,
    @Default('') String season,
    @Default(0xFFE8590C) int logoColor,
    @Default(0xFFFFFFFF) int logoInk,
    @Default([]) List<SubTeam> subTeams,
    @Default([]) List<Club> linkedClubs,
    @Default(0) int playerCount,
    @Default(0) int reserveCount,
    @Default(0) int staffCount,
    @Default(TeamRole.player) TeamRole myRole,
    @Default(0) int unreadChat,
  }) = _Team;

  const Team._();

  /// "School Team A" → "A".
  String get mark {
    final words = name.trim().split(RegExp(r'\s+'));
    return words.last.isEmpty ? '?' : words.last[0].toUpperCase();
  }

  bool get isStaff => myRole != TeamRole.player;
}

@freezed
abstract class TeamListItem with _$TeamListItem {
  const factory TeamListItem({
    required Team team,
    @Default('') String meta,
    @Default('') String note,
    @Default('') String tag,
  }) = _TeamListItem;
}

@freezed
abstract class TeamMember with _$TeamMember {
  const factory TeamMember({
    required PlayerSummary player,
    double? rating,
    @Default('') String club,

    /// "Captain" or "Vice-captain".
    String? captain,
    @Default(Availability.noReply) Availability availability,
    @Default(false) bool reserve,
    @Default(false) bool staff,
    @Default('') String staffTitle,
  }) = _TeamMember;

  const TeamMember._();
  SkillBand? get band => rating == null ? null : SkillBand.forLevel(rating!);
}

@freezed
abstract class TeamSession with _$TeamSession {
  const factory TeamSession({
    required String id,
    required String title,
    required DateTime startsAt,
    DateTime? endsAt,
    @Default('') String venue,
    @Default(false) bool fixture,
    @Default(0) int attending,
    @Default(0) int squad,
  }) = _TeamSession;
}

@freezed
abstract class TeamResult with _$TeamResult {
  const factory TeamResult({
    required String opponent,
    required DateTime at,
    @Default('') String competition,
    required bool won,
    required String score,
  }) = _TeamResult;
}

/// One lineup position: singles takes one player, doubles two.
@freezed
abstract class LineupSlot with _$LineupSlot {
  const factory LineupSlot({
    required String key,
    required String label,
    @Default(1) int size,
  }) = _LineupSlot;

  const LineupSlot._();
  bool get isReserve => key.startsWith('R');
  String get kind => key.substring(0, 1);
}

@freezed
abstract class Fixture with _$Fixture {
  const factory Fixture({
    required String id,
    required String teamId,
    required String teamName,
    required String opponent,
    required DateTime startsAt,
    @Default('') String competition,
    @Default('') String venue,
    DateTime? lineupLocksAt,
    @Default([]) List<String> notes,
    @Default('') String setBy,
    @Default('') String lineupRule,
    @Default(Availability.noReply) Availability myAvailability,
    @Default([]) List<LineupSlot> slots,
    @Default({}) Map<String, List<String?>> lineup,
    @Default(false) bool published,
  }) = _Fixture;
}

/// Answers from the three create-team steps.
@freezed
abstract class TeamDraft with _$TeamDraft {
  const factory TeamDraft({
    @Default('') String name,
    @Default('') String represents,
    @Default({'Under 15', 'Under 17'}) Set<String> subTeams,
    String? ownSubTeam,
    @Default(ClubSport.badminton) ClubSport sport,
    @Default([]) List<String> staff,
    @Default({}) Set<String> players,
  }) = _TeamDraft;
}

/// Reasons on the report screens for messages and clubs.
enum ContentReport {
  harassment(
    'harassment',
    'Harassment or bullying',
    'Insults, threats, unwanted contact',
    false,
  ),
  personalDetails(
    'personal_details',
    'Personal details shared',
    'Address, phone, school or workplace posted without consent',
    true,
  ),
  stalking('stalking', 'Stalking', 'Following or tracking someone', true),
  intimateImage(
    'intimate_image',
    'Sexual or intimate image',
    'Shared without consent, or unwanted',
    true,
  ),
  childSafety(
    'child_safety',
    'Child safety',
    'Anything that puts an under-18 at risk',
    true,
  ),
  hate(
    'hate',
    'Hate or violence',
    'Threats, or attacks on race or religion',
    false,
  ),
  scam('scam', 'Scam or fraud', 'Fake offer, asks for money or codes', false),
  other('other', 'Something else', 'Tell us in your own words', false);

  const ContentReport(this.id, this.label, this.hint, this.urgent);
  final String id;
  final String label;
  final String hint;
  final bool urgent;

  static const forMessage = [
    harassment,
    personalDetails,
    stalking,
    intimateImage,
    childSafety,
    hate,
    scam,
    other,
  ];

  static const forClub = [
    scam,
    harassment,
    childSafety,
    hate,
    personalDetails,
    other,
  ];
}

/// "Tampines Smashers" → "TS".
String clubInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first[0].toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}
