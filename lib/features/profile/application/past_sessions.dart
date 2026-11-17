import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/profile.dart';

/// The sessions the player has been to, newest first, across every sport on
/// their Passport. A session in two sports shows once. Classes are left out:
/// Profile lists Meets, events and tournaments.
final myPastSessionsProvider = FutureProvider.autoDispose<List<HistoryItem>>((
  ref,
) async {
  final sports = await ref.watch(mySportsProvider.future);
  final repo = ref.watch(profileRepositoryProvider);
  final histories = await Future.wait([
    for (final s in sports) repo.history(s.sport),
  ]);
  final seen = <String>{};
  final items = [
    for (final h in histories)
      for (final i in h.items)
        if (i.kind != 'class' && seen.add(i.id)) i,
  ]..sort((a, b) => b.at.compareTo(a.at));
  return items;
});
