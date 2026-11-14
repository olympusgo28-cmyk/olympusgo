import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/discover_models.dart';

part 'discover_providers.g.dart';

@riverpod
Future<List<FoundSession>> foundSessions(Ref ref, DiscoverFilter filter) =>
    ref.watch(discoverRepositoryProvider).sessions(filter);
