import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/event_models.dart';
import '../domain/tournament_models.dart';

part 'competition_providers.g.dart';

@riverpod
Future<TournamentInfo> tournamentInfo(Ref ref, String id) =>
    ref.watch(tournamentRepositoryProvider).info(id);

@riverpod
Future<List<Entry>> tournamentEntries(Ref ref, String id, String division) =>
    ref.watch(tournamentRepositoryProvider).entries(id, division);

@riverpod
Future<List<DrawGroup>> drawGroups(Ref ref, String id, String division) =>
    ref.watch(tournamentRepositoryProvider).groups(id, division);

@riverpod
Future<List<KnockoutRound>> drawKnockout(Ref ref, String id, String division) =>
    ref.watch(tournamentRepositoryProvider).knockout(id, division);

@riverpod
Future<List<MyMatch>> myTournamentMatches(Ref ref, String id) =>
    ref.watch(tournamentRepositoryProvider).myMatches(id);

@riverpod
Future<TournamentResult?> tournamentResult(Ref ref, String id) =>
    ref.watch(tournamentRepositoryProvider).result(id);

@riverpod
Future<List<PartnerPick>> partnerPicks(Ref ref, String id) =>
    ref.watch(tournamentRepositoryProvider).partners(id);

@riverpod
Future<EventInfo> eventInfo(Ref ref, String id) =>
    ref.watch(eventRepositoryProvider).info(id);

@riverpod
Future<Ticket?> eventTicket(Ref ref, String id) =>
    ref.watch(eventRepositoryProvider).ticket(id);

/// Refreshes tournament and event pages after a change.
void refreshCompetition(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(tournamentInfoProvider);
  invalidate(tournamentEntriesProvider);
  invalidate(myTournamentMatchesProvider);
  invalidate(tournamentResultProvider);
  invalidate(eventInfoProvider);
  invalidate(eventTicketProvider);
}
