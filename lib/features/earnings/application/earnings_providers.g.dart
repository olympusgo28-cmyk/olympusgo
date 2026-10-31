// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pointsSummary)
final pointsSummaryProvider = PointsSummaryProvider._();

final class PointsSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<PointsSummary>,
          PointsSummary,
          FutureOr<PointsSummary>
        >
    with $FutureModifier<PointsSummary>, $FutureProvider<PointsSummary> {
  PointsSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pointsSummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pointsSummaryHash();

  @$internal
  @override
  $FutureProviderElement<PointsSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PointsSummary> create(Ref ref) {
    return pointsSummary(ref);
  }
}

String _$pointsSummaryHash() => r'981132831507d29e1107032d1b095c160faf528d';

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

String _$pointsInfoHash() => r'b6ac8c3d8e16fb83ad235bed34e9a37740661a13';

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

String _$receiptsHash() => r'52899386a91b11ada56f2457551a6445a73dcccd';

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

String _$earningsHash() => r'f97520ba86e766da98cb0d5d37674f3477be968e';

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

String _$earningsDetailHash() => r'c4243c952a959c3b2632e3b658855c80a6d915c5';

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

String _$payoutAccountHash() => r'fc3647e6579653b9de2af7ba8b978f78de2bb0ba';

@ProviderFor(savedCard)
final savedCardProvider = SavedCardProvider._();

final class SavedCardProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  SavedCardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedCardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedCardHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return savedCard(ref);
  }
}

String _$savedCardHash() => r'b3aa16261eab6ebf1b9828a6261e30fe69875628';
