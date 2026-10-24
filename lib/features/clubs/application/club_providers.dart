import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../data/club_repository.dart';
import '../../play/domain/activity.dart';
import '../domain/club_models.dart';
import '../domain/club_sport.dart';

part 'club_providers.g.dart';

@riverpod
Future<List<ClubListItem>> clubList(Ref ref, ClubTab tab) =>
    ref.watch(clubRepositoryProvider).clubs(tab);

@riverpod
Future<List<TeamListItem>> teamList(Ref ref, ClubTab tab) =>
    ref.watch(clubRepositoryProvider).teams(tab);

@riverpod
Future<Club> club(Ref ref, String id) =>
    ref.watch(clubRepositoryProvider).club(id);

@riverpod
Future<String?> clubIdForCode(Ref ref, String code) =>
    ref.watch(clubRepositoryProvider).clubIdForCode(code);

@riverpod
Future<List<Activity>> clubSessions(Ref ref, String clubId) =>
    ref.watch(clubRepositoryProvider).sessions(clubId);

@riverpod
Future<List<ClubMember>> clubMembers(Ref ref, String clubId) =>
    ref.watch(clubRepositoryProvider).members(clubId);

@riverpod
Future<List<ClubRole>> clubRoles(Ref ref, String clubId) =>
    ref.watch(clubRepositoryProvider).roles(clubId);

@riverpod
Future<List<JoinRequest>> joinRequests(Ref ref, String clubId) =>
    ref.watch(clubRepositoryProvider).requests(clubId);

@riverpod
Future<List<ClubBan>> clubBans(Ref ref, String clubId) =>
    ref.watch(clubRepositoryProvider).bans(clubId);

@riverpod
Future<List<AuditEntry>> clubAudit(Ref ref, String clubId) =>
    ref.watch(clubRepositoryProvider).audit(clubId);

@riverpod
Future<List<Announcement>> clubAnnouncements(Ref ref, String clubId) =>
    ref.watch(clubRepositoryProvider).announcements(clubId);

@riverpod
Stream<List<GroupMessage>> groupChat(Ref ref, ChatScope scope) =>
    ref.watch(clubRepositoryProvider).chat(scope);

@riverpod
Future<ClubLeaderboard> clubLeaderboard(
  Ref ref,
  String clubId,
  ClubSport sport,
) => ref.watch(clubRepositoryProvider).leaderboard(clubId, sport);

@riverpod
Future<ClubReward> clubReward(Ref ref, String clubId) =>
    ref.watch(clubRepositoryProvider).reward(clubId);

@riverpod
Future<List<InviteCandidate>> inviteCandidates(Ref ref) =>
    ref.watch(clubRepositoryProvider).inviteCandidates();

@riverpod
Future<Team> team(Ref ref, String id) =>
    ref.watch(clubRepositoryProvider).team(id);

@riverpod
Future<List<TeamSession>> teamSessions(Ref ref, String teamId) =>
    ref.watch(clubRepositoryProvider).teamSessions(teamId);

@riverpod
Future<List<TeamResult>> teamResults(Ref ref, String teamId) =>
    ref.watch(clubRepositoryProvider).teamResults(teamId);

@riverpod
Future<List<TeamMember>> teamMembers(Ref ref, String teamId) =>
    ref.watch(clubRepositoryProvider).teamMembers(teamId);

@riverpod
Future<String?> nextFixtureId(Ref ref, String teamId) =>
    ref.watch(clubRepositoryProvider).nextFixtureId(teamId);

@riverpod
Future<Fixture> fixture(Ref ref, String fixtureId) =>
    ref.watch(clubRepositoryProvider).fixture(fixtureId);

@riverpod
Future<List<InviteCandidate>> teamCandidates(Ref ref, String teamId) =>
    ref.watch(clubRepositoryProvider).teamCandidates(teamId);

/// Refreshes everything a club screen shows after a change.
void refreshClub(void Function(ProviderOrFamily) invalidate, String clubId) {
  invalidate(clubProvider(clubId));
  invalidate(clubListProvider);
  invalidate(clubMembersProvider(clubId));
  invalidate(clubRolesProvider(clubId));
  invalidate(joinRequestsProvider(clubId));
  invalidate(clubBansProvider(clubId));
  invalidate(clubAuditProvider(clubId));
  invalidate(clubAnnouncementsProvider(clubId));
  invalidate(clubSessionsProvider(clubId));
}

/// Refreshes a team's screens after a change.
void refreshTeam(void Function(ProviderOrFamily) invalidate, String teamId) {
  invalidate(teamProvider(teamId));
  invalidate(teamListProvider);
  invalidate(teamMembersProvider(teamId));
  invalidate(teamSessionsProvider(teamId));
  invalidate(fixtureProvider);
  invalidate(teamCandidatesProvider(teamId));
}

/// The create-club answers, kept while moving between the four steps.
@Riverpod(keepAlive: true)
class ClubDraftController extends _$ClubDraftController {
  @override
  ClubDraft build() => const ClubDraft();

  void reset() => state = const ClubDraft();

  void edit(ClubDraft Function(ClubDraft) change) => state = change(state);

  Future<String> create() async {
    final id = await ref.read(clubRepositoryProvider).createClub(state);
    ref.invalidate(clubListProvider);
    return id;
  }
}

/// The create-team answers, kept while moving between the three steps.
@Riverpod(keepAlive: true)
class TeamDraftController extends _$TeamDraftController {
  @override
  TeamDraft build() => const TeamDraft();

  void reset() => state = const TeamDraft();

  void edit(TeamDraft Function(TeamDraft) change) => state = change(state);

  Future<String> create() async {
    final id = await ref.read(clubRepositoryProvider).createTeam(state);
    ref.invalidate(teamListProvider);
    return id;
  }
}
