// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(campaigns)
final campaignsProvider = CampaignsProvider._();

final class CampaignsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Campaign>>,
          List<Campaign>,
          FutureOr<List<Campaign>>
        >
    with $FutureModifier<List<Campaign>>, $FutureProvider<List<Campaign>> {
  CampaignsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'campaignsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$campaignsHash();

  @$internal
  @override
  $FutureProviderElement<List<Campaign>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Campaign>> create(Ref ref) {
    return campaigns(ref);
  }
}

String _$campaignsHash() => r'4efe5219ef92dd29be2e71eac4beccad93c18a2d';

@ProviderFor(campaign)
final campaignProvider = CampaignFamily._();

final class CampaignProvider
    extends
        $FunctionalProvider<AsyncValue<Campaign>, Campaign, FutureOr<Campaign>>
    with $FutureModifier<Campaign>, $FutureProvider<Campaign> {
  CampaignProvider._({
    required CampaignFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'campaignProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$campaignHash();

  @override
  String toString() {
    return r'campaignProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Campaign> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Campaign> create(Ref ref) {
    final argument = this.argument as String;
    return campaign(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CampaignProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$campaignHash() => r'e53a4372695ad00d4b3ab1f50c0ec61e05f7daea';

final class CampaignFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Campaign>, String> {
  CampaignFamily._()
    : super(
        retry: null,
        name: r'campaignProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CampaignProvider call(String id) =>
      CampaignProvider._(argument: id, from: this);

  @override
  String toString() => r'campaignProvider';
}

@ProviderFor(creator)
final creatorProvider = CreatorFamily._();

final class CreatorProvider
    extends $FunctionalProvider<AsyncValue<Creator>, Creator, FutureOr<Creator>>
    with $FutureModifier<Creator>, $FutureProvider<Creator> {
  CreatorProvider._({
    required CreatorFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'creatorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$creatorHash();

  @override
  String toString() {
    return r'creatorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Creator> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Creator> create(Ref ref) {
    final argument = this.argument as String;
    return creator(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CreatorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$creatorHash() => r'ec81f44e8808eb675a35984a0f8872f8fba4b322';

final class CreatorFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Creator>, String> {
  CreatorFamily._()
    : super(
        retry: null,
        name: r'creatorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CreatorProvider call(String id) =>
      CreatorProvider._(argument: id, from: this);

  @override
  String toString() => r'creatorProvider';
}

@ProviderFor(creatorEarnings)
final creatorEarningsProvider = CreatorEarningsProvider._();

final class CreatorEarningsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CreatorEarnings>,
          CreatorEarnings,
          FutureOr<CreatorEarnings>
        >
    with $FutureModifier<CreatorEarnings>, $FutureProvider<CreatorEarnings> {
  CreatorEarningsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creatorEarningsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creatorEarningsHash();

  @$internal
  @override
  $FutureProviderElement<CreatorEarnings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CreatorEarnings> create(Ref ref) {
    return creatorEarnings(ref);
  }
}

String _$creatorEarningsHash() => r'dd3ac34526a6c71c89e8afb6d2170af5631105ec';

@ProviderFor(creatorStatus)
final creatorStatusProvider = CreatorStatusProvider._();

final class CreatorStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<CreatorStatus>,
          CreatorStatus,
          FutureOr<CreatorStatus>
        >
    with $FutureModifier<CreatorStatus>, $FutureProvider<CreatorStatus> {
  CreatorStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creatorStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creatorStatusHash();

  @$internal
  @override
  $FutureProviderElement<CreatorStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CreatorStatus> create(Ref ref) {
    return creatorStatus(ref);
  }
}

String _$creatorStatusHash() => r'ab200e893cea41d4a4ada0cf18892d7f693bdb45';

@ProviderFor(leaderboard)
final leaderboardProvider = LeaderboardFamily._();

final class LeaderboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Standing>>,
          List<Standing>,
          FutureOr<List<Standing>>
        >
    with $FutureModifier<List<Standing>>, $FutureProvider<List<Standing>> {
  LeaderboardProvider._({
    required LeaderboardFamily super.from,
    required (bool, String, String) super.argument,
  }) : super(
         retry: null,
         name: r'leaderboardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leaderboardHash();

  @override
  String toString() {
    return r'leaderboardProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Standing>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Standing>> create(Ref ref) {
    final argument = this.argument as (bool, String, String);
    return leaderboard(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaderboardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leaderboardHash() => r'397763a1eeb1b9c150ed039c5e5bc15e44884d8d';

final class LeaderboardFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Standing>>,
          (bool, String, String)
        > {
  LeaderboardFamily._()
    : super(
        retry: null,
        name: r'leaderboardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LeaderboardProvider call(bool local, String sport, String area) =>
      LeaderboardProvider._(argument: (local, sport, area), from: this);

  @override
  String toString() => r'leaderboardProvider';
}

@ProviderFor(myGear)
final myGearProvider = MyGearProvider._();

final class MyGearProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Gear>>,
          List<Gear>,
          FutureOr<List<Gear>>
        >
    with $FutureModifier<List<Gear>>, $FutureProvider<List<Gear>> {
  MyGearProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myGearProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myGearHash();

  @$internal
  @override
  $FutureProviderElement<List<Gear>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Gear>> create(Ref ref) {
    return myGear(ref);
  }
}

String _$myGearHash() => r'5d63febdbdff144c1c08372a3762789b9e3e9b15';

@ProviderFor(myVouchers)
final myVouchersProvider = MyVouchersProvider._();

final class MyVouchersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GameVoucher>>,
          List<GameVoucher>,
          FutureOr<List<GameVoucher>>
        >
    with
        $FutureModifier<List<GameVoucher>>,
        $FutureProvider<List<GameVoucher>> {
  MyVouchersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myVouchersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myVouchersHash();

  @$internal
  @override
  $FutureProviderElement<List<GameVoucher>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GameVoucher>> create(Ref ref) {
    return myVouchers(ref);
  }
}

String _$myVouchersHash() => r'833406c67daae7f28a46accb63dc3b957bd4095a';

@ProviderFor(myBadges)
final myBadgesProvider = MyBadgesProvider._();

final class MyBadgesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GameBadge>>,
          List<GameBadge>,
          FutureOr<List<GameBadge>>
        >
    with $FutureModifier<List<GameBadge>>, $FutureProvider<List<GameBadge>> {
  MyBadgesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myBadgesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myBadgesHash();

  @$internal
  @override
  $FutureProviderElement<List<GameBadge>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GameBadge>> create(Ref ref) {
    return myBadges(ref);
  }
}

String _$myBadgesHash() => r'c20ba9375f4446807fab24f328454798af3b5481';

@ProviderFor(organizerRewards)
final organizerRewardsProvider = OrganizerRewardsProvider._();

final class OrganizerRewardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<OrganizerRewards>,
          OrganizerRewards,
          FutureOr<OrganizerRewards>
        >
    with $FutureModifier<OrganizerRewards>, $FutureProvider<OrganizerRewards> {
  OrganizerRewardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'organizerRewardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$organizerRewardsHash();

  @$internal
  @override
  $FutureProviderElement<OrganizerRewards> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OrganizerRewards> create(Ref ref) {
    return organizerRewards(ref);
  }
}

String _$organizerRewardsHash() => r'4d0126415fd1540eb994565af09d19de53c4517a';
