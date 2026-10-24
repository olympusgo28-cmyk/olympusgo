import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../onboarding/domain/sport.dart';
import '../../play/domain/activity.dart';
import '../data/venue_repository.dart';
import '../domain/venue_models.dart';

part 'venue_providers.g.dart';

@riverpod
Future<List<VenueDetail>> venueList(Ref ref) =>
    ref.watch(venueRepositoryProvider).venues();

@riverpod
Future<VenueDetail> venueDetail(Ref ref, String id) =>
    ref.watch(venueRepositoryProvider).venue(id);

/// Start times for one sport, day and length at a venue.
@riverpod
Future<List<CourtSlot>> courtSlots(
  Ref ref,
  String venueId,
  Sport sport,
  DateTime day,
  int hours,
) async {
  final venue = await ref.watch(venueDetailProvider(venueId).future);
  final taken = await ref
      .watch(venueRepositoryProvider)
      .bookingsOn(venueId, sport, day);
  return slotsFor(venue, sport, day, hours, taken);
}

@riverpod
Future<List<CourtBooking>> myCourtBookings(Ref ref) async {
  final me = await ref.watch(currentUserIdProvider.future);
  if (me == null) return const [];
  return ref.watch(venueRepositoryProvider).myBookings();
}

@riverpod
Future<CourtBooking> courtBooking(Ref ref, String id) =>
    ref.watch(venueRepositoryProvider).booking(id);

/// Meets, tournaments and events at a venue in the next 7 days.
@riverpod
Future<List<Activity>> venueActivities(Ref ref, String venueId) async {
  final repo = ref.watch(playRepositoryProvider);
  final lists = await Future.wait([
    for (final k in ActivityKind.values) repo.upcoming(kind: k, limit: 20),
  ]);
  final until = DateTime.now().add(const Duration(days: 7));
  return lists
      .expand((l) => l)
      .where((a) => a.venue.id == venueId && a.startsAt.isBefore(until))
      .toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
}
