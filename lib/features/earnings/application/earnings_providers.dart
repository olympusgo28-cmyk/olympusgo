import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../data/earnings_repository.dart';

part 'earnings_providers.g.dart';

@riverpod
Future<PointsSummary> pointsSummary(Ref ref) =>
    ref.watch(earningsRepositoryProvider).summary();

@riverpod
Future<PointsInfo> pointsInfo(Ref ref) =>
    ref.watch(earningsRepositoryProvider).points();

@riverpod
Future<List<ReceiptRecord>> receipts(Ref ref) =>
    ref.watch(earningsRepositoryProvider).receipts();

@riverpod
Future<Earnings> earnings(Ref ref) =>
    ref.watch(earningsRepositoryProvider).earnings();

@riverpod
Future<EarningsBreakdown> earningsDetail(Ref ref, String id) =>
    ref.watch(earningsRepositoryProvider).earningsDetail(id);

@riverpod
Future<PayoutAccount> payoutAccount(Ref ref) =>
    ref.watch(earningsRepositoryProvider).payoutAccount();

@riverpod
Future<String?> savedCard(Ref ref) =>
    ref.watch(earningsRepositoryProvider).savedCard();

/// Refreshes these screens after money moves.
void refreshEarnings(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(pointsSummaryProvider);
  invalidate(pointsInfoProvider);
  invalidate(receiptsProvider);
  invalidate(earningsProvider);
  invalidate(payoutAccountProvider);
  invalidate(savedCardProvider);
}
