import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../data/wallet_repository.dart';

part 'wallet_providers.g.dart';

@riverpod
Future<WalletSummary> walletSummary(Ref ref) =>
    ref.watch(walletRepositoryProvider).summary();

@riverpod
Future<List<WalletEntry>> walletActivity(Ref ref) =>
    ref.watch(walletRepositoryProvider).activity();

@riverpod
Future<PointsInfo> pointsInfo(Ref ref) =>
    ref.watch(walletRepositoryProvider).points();

@riverpod
Future<List<ReceiptRecord>> receipts(Ref ref) =>
    ref.watch(walletRepositoryProvider).receipts();

@riverpod
Future<Earnings> earnings(Ref ref) =>
    ref.watch(walletRepositoryProvider).earnings();

@riverpod
Future<EarningsBreakdown> earningsDetail(Ref ref, String id) =>
    ref.watch(walletRepositoryProvider).earningsDetail(id);

@riverpod
Future<PayoutAccount> payoutAccount(Ref ref) =>
    ref.watch(walletRepositoryProvider).payoutAccount();

/// Refreshes the Wallet screens after money moves.
void refreshWallet(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(walletSummaryProvider);
  invalidate(walletActivityProvider);
  invalidate(pointsInfoProvider);
  invalidate(receiptsProvider);
  invalidate(earningsProvider);
  invalidate(payoutAccountProvider);
}
