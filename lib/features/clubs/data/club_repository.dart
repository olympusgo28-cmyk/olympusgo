import '../../play/domain/activity.dart';
import '../domain/club_models.dart';
import '../domain/club_sport.dart';

/// Which list a clubs or teams tab shows.
enum ClubTab { mine, recommended, fresh }

/// A club chat or a team chat.
class ChatScope {
  const ChatScope.club(this.id) : isTeam = false;
  const ChatScope.team(this.id) : isTeam = true;

  final String id;
  final bool isTeam;

  @override
  bool operator ==(Object other) =>
      other is ChatScope && other.id == id && other.isTeam == isTeam;

  @override
  int get hashCode => Object.hash(id, isTeam);
}

/// Something reported from a club screen.
class ReportTarget {
  const ReportTarget.message(this.id, {required this.scope})
    : isClub = false,
      isActivity = false;
  const ReportTarget.club(this.id)
    : isClub = true,
      isActivity = false,
      scope = null;

  /// A tournament or event.
  const ReportTarget.activity(this.id)
    : isClub = false,
      isActivity = true,
      scope = null;

  final String id;
  final bool isClub;
  final bool isActivity;
  final ChatScope? scope;
}

/// Clubs, their members and roles, club and team chat, and teams.
abstract interface class ClubRepository {
  // Browse.
  Future<List<ClubListItem>> clubs(ClubTab tab);
  Future<List<TeamListItem>> teams(ClubTab tab);

  // One club.
  Future<Club> club(String id);

  /// The club an invite code belongs to, or null if it is wrong or expired.
  Future<String?> clubIdForCode(String code);
  Future<List<Activity>> sessions(String clubId);

  /// Joins straight away, or sends a request when the club asks for one.
  Future<void> join(String clubId, {String message = ''});
  Future<void> cancelRequest(String clubId);
  Future<void> leave(String clubId);

  // Members, roles and moderation.
  Future<List<ClubMember>> members(String clubId);
  Future<List<ClubRole>> roles(String clubId);

  /// Gives [userId] one permission role (or none, for Everyone).
  Future<void> setMemberRole(String clubId, String userId, String? roleId);
  Future<void> removeMember(String clubId, String userId);
  Future<void> banMember(String clubId, String userId, String reason);
  Future<List<ClubBan>> bans(String clubId);
  Future<void> unban(String clubId, String userId);
  Future<List<JoinRequest>> requests(String clubId);
  Future<void> decideRequest(
    String clubId,
    String requestId,
    RequestStatus status,
  );
  Future<List<AuditEntry>> audit(String clubId);
  Future<ClubRole> createRole(
    String clubId, {
    required String name,
    required int color,
    required RoleLevel level,
    required Set<String> members,
  });
  Future<void> updateRole(String clubId, ClubRole role);
  Future<void> deleteRole(String clubId, String roleId);
  Future<void> reorderRoles(String clubId, List<String> roleIds);
  Future<void> setRoleMembers(String clubId, String roleId, Set<String> ids);

  // Announcements and chat.
  Future<List<Announcement>> announcements(String clubId);
  Future<void> announce(
    String clubId, {
    required String title,
    required String body,
    required String audience,
    required bool pinned,
  });
  Stream<List<GroupMessage>> chat(ChatScope scope);
  Future<void> send(ChatScope scope, String body, {String? activityId});
  Future<void> sendPhoto(ChatScope scope, String filePath);
  Future<void> removeMessage(ChatScope scope, String messageId, bool removed);
  Future<void> report(ReportTarget target, ContentReport reason, String note);

  // Club info and settings.
  Future<ClubLeaderboard> leaderboard(String clubId, ClubSport sport);
  Future<ClubReward> reward(String clubId);
  Future<void> updateClub(Club club);
  Future<void> transfer(String clubId, String toUserId);
  Future<void> deleteClub(String clubId);
  Future<String> createClub(ClubDraft draft);
  Future<List<InviteCandidate>> inviteCandidates();
  Future<void> invite(String clubId, Set<String> userIds);

  // Teams.
  Future<Team> team(String id);
  Future<List<TeamSession>> teamSessions(String teamId);
  Future<List<TeamResult>> teamResults(String teamId);
  Future<List<TeamMember>> teamMembers(String teamId);

  /// The next fixture's id, or null when none is scheduled.
  Future<String?> nextFixtureId(String teamId);
  Future<Fixture> fixture(String fixtureId);
  Future<void> setAvailability(String fixtureId, Availability availability);
  Future<void> saveLineup(
    String fixtureId,
    Map<String, List<String?>> lineup, {
    required bool publish,
  });
  Future<List<InviteCandidate>> teamCandidates(String teamId);
  Future<void> addTeamPlayers(String teamId, Set<String> userIds);
  Future<String> createTeam(TeamDraft draft);
  Future<void> updateTeam(Team team);
  Future<void> leaveTeam(String teamId);
  Future<void> deleteTeam(String teamId);
}
