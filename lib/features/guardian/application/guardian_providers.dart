import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/guardian_models.dart';

part 'guardian_providers.g.dart';

/// What the signed-in player may do. Null when signed out.
@Riverpod(keepAlive: true)
Future<Restrictions?> restrictions(Ref ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return null;
  // A reloaded profile can mean a finished onboarding or a new parent link.
  ref.watch(sessionProfileProvider);
  return ref.watch(guardianRepositoryProvider).restrictions();
}

@riverpod
Future<List<GuardianLink>> myChildren(Ref ref) =>
    ref.watch(guardianRepositoryProvider).children();

@riverpod
Future<List<GuardianLink>> myParents(Ref ref) =>
    ref.watch(guardianRepositoryProvider).parents();

@riverpod
Future<List<ChildPost>> childPosts(Ref ref, String childId) =>
    ref.watch(guardianRepositoryProvider).childPosts(childId);

@riverpod
Future<bool> childListed(Ref ref, String childId) =>
    ref.watch(guardianRepositoryProvider).childListed(childId);

@riverpod
Future<List<GroupRequest>> childGroupRequests(Ref ref, String childId) =>
    ref.watch(guardianRepositoryProvider).groupRequests(childId);
