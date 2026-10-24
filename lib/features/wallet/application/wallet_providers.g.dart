// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(walletSummary)
final walletSummaryProvider = WalletSummaryProvider._();

final class WalletSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<WalletSummary>,
          WalletSummary,
          FutureOr<WalletSummary>
        >
    with $FutureModifier<WalletSummary>, $FutureProvider<WalletSummary> {
  WalletSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletSummaryHash();

  @$internal
  @override
  $FutureProviderElement<WalletSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WalletSummary> create(Ref ref) {
    return walletSummary(ref);
  }
}

String _$walletSummaryHash() => r'8064b3d8d9e687ce11715d5761f2466b39da5b1f';

@ProviderFor(walletActivity)
final walletActivityProvider = WalletActivityProvider._();

final class WalletActivityProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<WalletEntry>>,
          List<WalletEntry>,
          FutureOr<List<WalletEntry>>
        >
    with
        $FutureModifier<List<WalletEntry>>,
        $FutureProvider<List<WalletEntry>> {
  WalletActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletActivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletActivityHash();

  @$internal
  @override
  $FutureProviderElement<List<WalletEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<WalletEntry>> create(Ref ref) {
    return walletActivity(ref);
  }
}

String _$walletActivityHash() => r'1b47d9801ab9767ae7c98cccb371d1491f927e79';

@ProviderFor(pointsInfo)
final pointsInfoProvider = PointsInfoProvider._();

final class PointsInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PointsInfo>,
          PointsInfo,
          FutureOr<PointsInfo>
        >
    with $FutureModifier<PointsInfo>, $FutureProvider<PointsInfo> {
  PointsInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pointsInfoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pointsInfoHash();

  @$internal
  @override
  $FutureProviderElement<PointsInfo> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PointsInfo> create(Ref ref) {
    return pointsInfo(ref);
  }
}

String _$pointsInfoHash() => r'b0f7d72d068f763637040d625d9d122ec19d2408';

@ProviderFor(receipts)
final receiptsProvider = ReceiptsProvider._();

final class ReceiptsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReceiptRecord>>,
          List<ReceiptRecord>,
          FutureOr<List<ReceiptRecord>>
        >
    with
        $FutureModifier<List<ReceiptRecord>>,
        $FutureProvider<List<ReceiptRecord>> {
  ReceiptsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptsHash();

  @$internal
  @override
  $FutureProviderElement<List<ReceiptRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ReceiptRecord>> create(Ref ref) {
    return receipts(ref);
  }
}

String _$receiptsHash() => r'22bba093b4242b303cb3904f4ebaa3451f8f370f';

@ProviderFor(earnings)
final earningsProvider = EarningsProvider._();

final class EarningsProvider
    extends
        $FunctionalProvider<AsyncValue<Earnings>, Earnings, FutureOr<Earnings>>
    with $FutureModifier<Earnings>, $FutureProvider<Earnings> {
  EarningsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'earningsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$earningsHash();

  @$internal
  @override
  $FutureProviderElement<Earnings> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Earnings> create(Ref ref) {
    return earnings(ref);
  }
}

String _$earningsHash() => r'0c66eada42d144e500e32cc985a211406b38c1ea';

@ProviderFor(earningsDetail)
final earningsDetailProvider = EarningsDetailFamily._();

final class EarningsDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<EarningsBreakdown>,
          EarningsBreakdown,
          FutureOr<EarningsBreakdown>
        >
    with
        $FutureModifier<EarningsBreakdown>,
        $FutureProvider<EarningsBreakdown> {
  EarningsDetailProvider._({
    required EarningsDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'earningsDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$earningsDetailHash();

  @override
  String toString() {
    return r'earningsDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<EarningsBreakdown> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EarningsBreakdown> create(Ref ref) {
    final argument = this.argument as String;
    return earningsDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EarningsDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$earningsDetailHash() => r'2f63ecd065512f6ce01db93d2b0a2f3ef5dd35de';

final class EarningsDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<EarningsBreakdown>, String> {
  EarningsDetailFamily._()
    : super(
        retry: null,
        name: r'earningsDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EarningsDetailProvider call(String id) =>
      EarningsDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'earningsDetailProvider';
}

@ProviderFor(payoutAccount)
final payoutAccountProvider = PayoutAccountProvider._();

final class PayoutAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<PayoutAccount>,
          PayoutAccount,
          FutureOr<PayoutAccount>
        >
    with $FutureModifier<PayoutAccount>, $FutureProvider<PayoutAccount> {
  PayoutAccountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'payoutAccountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$payoutAccountHash();

  @$internal
  @override
  $FutureProviderElement<PayoutAccount> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PayoutAccount> create(Ref ref) {
    return payoutAccount(ref);
  }
}

String _$payoutAccountHash() => r'4d5ae82b674d321e6590f7dd676d9e71d2416cff';
