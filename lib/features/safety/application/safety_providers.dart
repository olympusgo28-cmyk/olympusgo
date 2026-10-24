import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/safety_models.dart';

part 'safety_providers.g.dart';

@riverpod
Future<List<SafetyReport>> myReports(Ref ref) =>
    ref.watch(safetyRepositoryProvider).myReports();

@riverpod
Future<SafetyReport> safetyReport(Ref ref, String id) =>
    ref.watch(safetyRepositoryProvider).report(id);

@riverpod
Future<RemovalNotice> removalNotice(Ref ref, String id) =>
    ref.watch(safetyRepositoryProvider).removal(id);
