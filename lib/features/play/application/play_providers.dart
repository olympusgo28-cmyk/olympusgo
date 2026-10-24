import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../onboarding/domain/sport.dart';
import '../domain/activity.dart';
import '../domain/hub.dart';
import '../domain/meet_ops.dart';

part 'play_providers.g.dart';

/// Sports shown as chips on Play, with each sport's options.
@Riverpod(keepAlive: true)
class PlaySports extends _$PlaySports {
  @override
  Future<List<PlaySportPref>> build() async {
    final me = await ref.watch(currentUserIdProvider.future);
    if (me == null) return const [];
    final saved = await ref.watch(playRepositoryProvider).playSports();
    if (saved.isNotEmpty) return saved;
    // First visit: start from the sports on the player's Passport.
    final mine = await ref.watch(mySportsProvider.future);
    return [
      for (final s in mine)
        PlaySportPref(
          sport: Sport.fromId(s.sport),
          levelMin: s.playMin.floorToDouble(),
          levelMax: s.playMax.ceilToDouble().clamp(1, 8),
        ),
    ];
  }

  Future<void> _save(List<PlaySportPref> next) async {
    state = AsyncData(next);
    await ref.read(playRepositoryProvider).savePlaySports(next);
  }

  Future<void> setSports(List<Sport> sports) {
    final current = state.value ?? const [];
    return _save([
      for (final s in sports)
        current.where((p) => p.sport == s).firstOrNull ??
            PlaySportPref(sport: s),
    ]);
  }

  /// Saves a sport's options, adding it if it's new.
  Future<void> savePref(PlaySportPref pref) {
    final current = state.value ?? const <PlaySportPref>[];
    return _save(
      current.any((p) => p.sport == pref.sport)
          ? [for (final p in current) p.sport == pref.sport ? pref : p]
          : [...current, pref],
    );
  }

  /// "All" on Play: no sport narrows the list.
  Future<void> clear() => _save(const []);

  Future<void> remove(Sport sport) => _save([
    ...(state.value ?? const <PlaySportPref>[]).where((p) => p.sport != sport),
  ]);
}

/// The Play hub's filters, per tab.
@Riverpod(keepAlive: true)
class HubFilters extends _$HubFilters {
  @override
  Map<HubTab, Map<String, String>> build() => const {};

  void set(HubTab tab, String key, String value) => state = {
    ...state,
    tab: {...?state[tab], key: value},
  };

  void reset(HubTab tab) => state = {...state}..remove(tab);
}

/// Upcoming activities on a Play tab, soonest first, after its filters and
/// the picked sports.
@riverpod
Future<List<Activity>> hubActivities(Ref ref, HubTab tab) async {
  final picked = await ref.watch(playSportsProvider.future);
  final filters = ref.watch(hubFiltersProvider)[tab] ?? const {};
  final repo = ref.watch(playRepositoryProvider);
  final kinds = tab.kind == null ? ActivityKind.values : [tab.kind!];
  final lists = await Future.wait([
    for (final k in kinds) repo.browse(kind: k),
  ]);
  return lists
      .expand((l) => l)
      .where((a) => hubMatches(a, tab, filters, picked))
      .toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
}

@riverpod
Future<Activity> activityDetail(Ref ref, String id) =>
    ref.watch(playRepositoryProvider).activity(id);

@riverpod
Future<List<Activity>> mySchedule(Ref ref) async {
  final me = await ref.watch(currentUserIdProvider.future);
  if (me == null) return const [];
  return ref.watch(playRepositoryProvider).mySchedule();
}

@riverpod
Future<List<Activity>> hosting(Ref ref) async {
  final me = await ref.watch(currentUserIdProvider.future);
  if (me == null) return const [];
  return ref.watch(playRepositoryProvider).hosting();
}

/// Meets coming up, for Home and Discover.
@riverpod
Future<List<Activity>> upcomingMeets(Ref ref) =>
    ref.watch(playRepositoryProvider).upcoming(limit: 3);

/// Home's sideways rows: what's coming up of one kind.
@riverpod
Future<List<Activity>> upcomingOfKind(Ref ref, ActivityKind kind) =>
    ref.watch(playRepositoryProvider).upcoming(kind: kind, limit: 6);

@riverpod
Future<List<Venue>> venueSearch(Ref ref, String query) =>
    ref.watch(playRepositoryProvider).venues(query);

/// Who is going and who is waiting.
@riverpod
Future<List<MeetPlayer>> meetPlayers(Ref ref, String id) =>
    ref.watch(playRepositoryProvider).players(id);

@riverpod
Future<List<MeetPlayer>> walkInCandidates(Ref ref, String id) =>
    ref.watch(playRepositoryProvider).walkInCandidates(id);

@riverpod
Future<CancelPreview> cancelPreview(Ref ref, String id) =>
    ref.watch(playRepositoryProvider).cancelPreview(id);

@riverpod
Future<MeetRecap> meetRecap(Ref ref, String id) =>
    ref.watch(playRepositoryProvider).recap(id);

@riverpod
Future<MatchScore> matchScore(Ref ref, String id) =>
    ref.watch(playRepositoryProvider).score(id);

/// Refreshes every list after joining, leaving or publishing. Pass
/// `ref.invalidate` from a widget or a provider.
void refreshPlay(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(hubActivitiesProvider);
  invalidate(activityDetailProvider);
  invalidate(myScheduleProvider);
  invalidate(hostingProvider);
  invalidate(upcomingMeetsProvider);
  invalidate(upcomingOfKindProvider);
  invalidate(meetPlayersProvider);
  invalidate(walkInCandidatesProvider);
  invalidate(cancelPreviewProvider);
}

/// The create flow's answers, kept while moving between steps.
@Riverpod(keepAlive: true)
class ActivityDraftController extends _$ActivityDraftController {
  @override
  ActivityDraft build() => const ActivityDraft();

  /// Starts a fresh draft. [clubId] is set when creating from a club page.
  void start(ActivityKind kind, {String? clubId}) {
    final now = DateTime.now();
    // The coming Friday, or a week on if today is Friday.
    final nextFriday = now.add(
      Duration(days: (DateTime.friday - now.weekday - 1) % 7 + 1),
    );
    state = switch (kind) {
      ActivityKind.meet => ActivityDraft(
        kind: kind,
        gameType: GameType.doubles,
        format: ActivityFormat.roundRobin,
        date: nextFriday,
        hour: 20,
        minute: 0,
        feeCents: 600,
        repeatDays: [nextFriday.weekday],
      ),
      ActivityKind.event => ActivityDraft(
        kind: kind,
        format: ActivityFormat.festival,
        capacity: 100,
        chargeFee: false,
        feeCents: 0,
        hour: 10,
        minute: 0,
        date: nextFriday.add(const Duration(days: 1)),
      ),
      ActivityKind.tournament => ActivityDraft(
        kind: kind,
        gameType: GameType.doubles,
        format: ActivityFormat.groupsKnockout,
        levelMax: 6,
        capacity: 32,
        courts: 6,
        feeCents: 1500,
        hour: 9,
        minute: 0,
        date: now.add(const Duration(days: 25)),
        endDate: now.add(const Duration(days: 26)),
        registrationCloses: DateTime(now.year, now.month, now.day + 18, 23, 45),
      ),
    }.copyWith(clubId: clubId);
  }

  void edit(ActivityDraft Function(ActivityDraft) change) =>
      state = change(state);

  /// Loads a published activity to change it with the create screens.
  void startEdit(Activity a) {
    final meet = a.kind == ActivityKind.meet;
    state = ActivityDraft(
      editingId: a.id,
      kind: a.kind,
      sports: a.sports,
      title: a.title,
      description: a.description ?? '',
      gameType: a.gameType,
      format: a.format,
      levelMin: a.levelMin ?? 3.0,
      levelMax: a.levelMax ?? 5.0,
      restrictLevel: a.levelMin != null,
      date: DateTime(a.startsAt.year, a.startsAt.month, a.startsAt.day),
      endDate: a.kind == ActivityKind.tournament
          ? DateTime(a.endsAt.year, a.endsAt.month, a.endsAt.day)
          : null,
      hour: a.startsAt.hour,
      minute: a.startsAt.minute,
      durationMinutes: a.endsAt.difference(a.startsAt).inMinutes.clamp(30, 720),
      venue: a.venue,
      capacity: a.capacity,
      approvalRequired: a.approvalRequired,
      chargeFee: a.feeCents > 0,
      feeCents: a.feeCents,
      allowGuests: a.allowGuests,
      registrationCloses: a.registrationClosesAt,
      clubId: a.clubId,
      coverTitle: a.coverTitle,
      coverColor: a.coverColor,
      repeatDays: [a.startsAt.weekday],
      minPlayers: meet ? a.minPlayers : 4,
      levelAsNumbers: a.levelAsNumbers,
      ranked: a.ranked,
      playersPayFee: a.playersPayFee,
      tier: a.tier ?? 'Regional',
      divisionKeys: a.divisionKeys.isEmpty
          ? const ['MS', 'WS', 'MD', 'XD']
          : a.divisionKeys,
      teamEntry: a.kind == ActivityKind.tournament && a.divisionKeys.isEmpty,
      online: a.online,
      linkedId: a.linkedId,
    );
  }

  /// Publishes a new activity, or saves changes to the one being edited.
  Future<String> publish() async {
    final repo = ref.read(playRepositoryProvider);
    if (state.editingId case final id?) {
      await repo.update(id, state);
      refreshPlay(ref.invalidate);
      return id;
    }
    // Activities are hosted by a club; the Create menu always sets one.
    if (state.clubId == null) {
      throw const AuthFailure('Pick a club to host this first.');
    }
    final id = await repo.publish(state);
    refreshPlay(ref.invalidate);
    return id;
  }
}
