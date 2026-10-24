import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/game_models.dart';

part 'game_providers.g.dart';

@riverpod
Future<List<Campaign>> campaigns(Ref ref) =>
    ref.watch(gameRepositoryProvider).campaigns();

@riverpod
Future<Campaign> campaign(Ref ref, String id) =>
    ref.watch(gameRepositoryProvider).campaign(id);

@riverpod
Future<Creator> creator(Ref ref, String id) =>
    ref.watch(gameRepositoryProvider).creator(id);

@riverpod
Future<CreatorEarnings> creatorEarnings(Ref ref) =>
    ref.watch(gameRepositoryProvider).creatorEarnings();

@riverpod
Future<CreatorStatus> creatorStatus(Ref ref) =>
    ref.watch(gameRepositoryProvider).creatorStatus();

@riverpod
Future<List<Standing>> leaderboard(
  Ref ref,
  bool local,
  String sport,
  String area,
) => ref
    .watch(gameRepositoryProvider)
    .leaderboard(local: local, sport: sport, area: area);

@riverpod
Future<List<Gear>> myGear(Ref ref) => ref.watch(gameRepositoryProvider).gear();

/// Refreshes the game screens after joining or an attempt.
void refreshGame(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(campaignsProvider);
  invalidate(campaignProvider);
  invalidate(creatorProvider);
  invalidate(creatorStatusProvider);
  invalidate(myGearProvider);
}
