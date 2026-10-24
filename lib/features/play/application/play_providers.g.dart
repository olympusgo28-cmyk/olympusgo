// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sports shown as chips on Play, with each sport's options.

@ProviderFor(PlaySports)
final playSportsProvider = PlaySportsProvider._();

/// Sports shown as chips on Play, with each sport's options.
final class PlaySportsProvider
    extends $AsyncNotifierProvider<PlaySports, List<PlaySportPref>> {
  /// Sports shown as chips on Play, with each sport's options.
  PlaySportsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playSportsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playSportsHash();

  @$internal
  @override
  PlaySports create() => PlaySports();
}

String _$playSportsHash() => r'848d10653c97723474e97d41b961cb9ec45b3d15';

/// Sports shown as chips on Play, with each sport's options.

abstract class _$PlaySports extends $AsyncNotifier<List<PlaySportPref>> {
  FutureOr<List<PlaySportPref>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PlaySportPref>>, List<PlaySportPref>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PlaySportPref>>, List<PlaySportPref>>,
              AsyncValue<List<PlaySportPref>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The Play hub's filters, per tab.

@ProviderFor(HubFilters)
final hubFiltersProvider = HubFiltersProvider._();

/// The Play hub's filters, per tab.
final class HubFiltersProvider
    extends $NotifierProvider<HubFilters, Map<HubTab, Map<String, String>>> {
  /// The Play hub's filters, per tab.
  HubFiltersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hubFiltersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hubFiltersHash();

  @$internal
  @override
  HubFilters create() => HubFilters();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<HubTab, Map<String, String>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<HubTab, Map<String, String>>>(
        value,
      ),
    );
  }
}

String _$hubFiltersHash() => r'5cdbb59409669579159ef1d8b5e5619de7553bfc';

/// The Play hub's filters, per tab.

abstract class _$HubFilters
    extends $Notifier<Map<HubTab, Map<String, String>>> {
  Map<HubTab, Map<String, String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<HubTab, Map<String, String>>,
              Map<HubTab, Map<String, String>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<HubTab, Map<String, String>>,
                Map<HubTab, Map<String, String>>
              >,
              Map<HubTab, Map<String, String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Upcoming activities on a Play tab, soonest first, after its filters and
/// the picked sports.

@ProviderFor(hubActivities)
final hubActivitiesProvider = HubActivitiesFamily._();

/// Upcoming activities on a Play tab, soonest first, after its filters and
/// the picked sports.

final class HubActivitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Activity>>,
          List<Activity>,
          FutureOr<List<Activity>>
        >
    with $FutureModifier<List<Activity>>, $FutureProvider<List<Activity>> {
  /// Upcoming activities on a Play tab, soonest first, after its filters and
  /// the picked sports.
  HubActivitiesProvider._({
    required HubActivitiesFamily super.from,
    required HubTab super.argument,
  }) : super(
         retry: null,
         name: r'hubActivitiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hubActivitiesHash();

  @override
  String toString() {
    return r'hubActivitiesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Activity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Activity>> create(Ref ref) {
    final argument = this.argument as HubTab;
    return hubActivities(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HubActivitiesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hubActivitiesHash() => r'bd98ad21e669c4fe8a64a9ab48033de43630dd17';

/// Upcoming activities on a Play tab, soonest first, after its filters and
/// the picked sports.

final class HubActivitiesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Activity>>, HubTab> {
  HubActivitiesFamily._()
    : super(
        retry: null,
        name: r'hubActivitiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Upcoming activities on a Play tab, soonest first, after its filters and
  /// the picked sports.

  HubActivitiesProvider call(HubTab tab) =>
      HubActivitiesProvider._(argument: tab, from: this);

  @override
  String toString() => r'hubActivitiesProvider';
}

@ProviderFor(activityDetail)
final activityDetailProvider = ActivityDetailFamily._();

final class ActivityDetailProvider
    extends
        $FunctionalProvider<AsyncValue<Activity>, Activity, FutureOr<Activity>>
    with $FutureModifier<Activity>, $FutureProvider<Activity> {
  ActivityDetailProvider._({
    required ActivityDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'activityDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activityDetailHash();

  @override
  String toString() {
    return r'activityDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Activity> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Activity> create(Ref ref) {
    final argument = this.argument as String;
    return activityDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActivityDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activityDetailHash() => r'ced5b3201e1aac2fd61ee468ed0903d696fab857';

final class ActivityDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Activity>, String> {
  ActivityDetailFamily._()
    : super(
        retry: null,
        name: r'activityDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActivityDetailProvider call(String id) =>
      ActivityDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'activityDetailProvider';
}

@ProviderFor(mySchedule)
final myScheduleProvider = MyScheduleProvider._();

final class MyScheduleProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Activity>>,
          List<Activity>,
          FutureOr<List<Activity>>
        >
    with $FutureModifier<List<Activity>>, $FutureProvider<List<Activity>> {
  MyScheduleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myScheduleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myScheduleHash();

  @$internal
  @override
  $FutureProviderElement<List<Activity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Activity>> create(Ref ref) {
    return mySchedule(ref);
  }
}

String _$myScheduleHash() => r'bc04f9b3baf78a8a091ad919ca021546c292ccea';

@ProviderFor(hosting)
final hostingProvider = HostingProvider._();

final class HostingProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Activity>>,
          List<Activity>,
          FutureOr<List<Activity>>
        >
    with $FutureModifier<List<Activity>>, $FutureProvider<List<Activity>> {
  HostingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hostingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hostingHash();

  @$internal
  @override
  $FutureProviderElement<List<Activity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Activity>> create(Ref ref) {
    return hosting(ref);
  }
}

String _$hostingHash() => r'4398e12b0c03440f12c7e393df0342d86e8491a0';

/// Meets coming up, for Home and Discover.

@ProviderFor(upcomingMeets)
final upcomingMeetsProvider = UpcomingMeetsProvider._();

/// Meets coming up, for Home and Discover.

final class UpcomingMeetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Activity>>,
          List<Activity>,
          FutureOr<List<Activity>>
        >
    with $FutureModifier<List<Activity>>, $FutureProvider<List<Activity>> {
  /// Meets coming up, for Home and Discover.
  UpcomingMeetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upcomingMeetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upcomingMeetsHash();

  @$internal
  @override
  $FutureProviderElement<List<Activity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Activity>> create(Ref ref) {
    return upcomingMeets(ref);
  }
}

String _$upcomingMeetsHash() => r'bd0cbbcb0d39e87a7d0b4fe95e28679ba50ad4f1';

/// Home's sideways rows: what's coming up of one kind.

@ProviderFor(upcomingOfKind)
final upcomingOfKindProvider = UpcomingOfKindFamily._();

/// Home's sideways rows: what's coming up of one kind.

final class UpcomingOfKindProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Activity>>,
          List<Activity>,
          FutureOr<List<Activity>>
        >
    with $FutureModifier<List<Activity>>, $FutureProvider<List<Activity>> {
  /// Home's sideways rows: what's coming up of one kind.
  UpcomingOfKindProvider._({
    required UpcomingOfKindFamily super.from,
    required ActivityKind super.argument,
  }) : super(
         retry: null,
         name: r'upcomingOfKindProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$upcomingOfKindHash();

  @override
  String toString() {
    return r'upcomingOfKindProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Activity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Activity>> create(Ref ref) {
    final argument = this.argument as ActivityKind;
    return upcomingOfKind(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingOfKindProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$upcomingOfKindHash() => r'beaf73e30d06d6cbe906d23ba8c2de857ddea748';

/// Home's sideways rows: what's coming up of one kind.

final class UpcomingOfKindFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Activity>>, ActivityKind> {
  UpcomingOfKindFamily._()
    : super(
        retry: null,
        name: r'upcomingOfKindProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Home's sideways rows: what's coming up of one kind.

  UpcomingOfKindProvider call(ActivityKind kind) =>
      UpcomingOfKindProvider._(argument: kind, from: this);

  @override
  String toString() => r'upcomingOfKindProvider';
}

@ProviderFor(venueSearch)
final venueSearchProvider = VenueSearchFamily._();

final class VenueSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Venue>>,
          List<Venue>,
          FutureOr<List<Venue>>
        >
    with $FutureModifier<List<Venue>>, $FutureProvider<List<Venue>> {
  VenueSearchProvider._({
    required VenueSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'venueSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$venueSearchHash();

  @override
  String toString() {
    return r'venueSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Venue>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Venue>> create(Ref ref) {
    final argument = this.argument as String;
    return venueSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VenueSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$venueSearchHash() => r'b3b5a8c39ee4747801679d8e5198a595c5952a39';

final class VenueSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Venue>>, String> {
  VenueSearchFamily._()
    : super(
        retry: null,
        name: r'venueSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VenueSearchProvider call(String query) =>
      VenueSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'venueSearchProvider';
}

/// Who is going and who is waiting.

@ProviderFor(meetPlayers)
final meetPlayersProvider = MeetPlayersFamily._();

/// Who is going and who is waiting.

final class MeetPlayersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MeetPlayer>>,
          List<MeetPlayer>,
          FutureOr<List<MeetPlayer>>
        >
    with $FutureModifier<List<MeetPlayer>>, $FutureProvider<List<MeetPlayer>> {
  /// Who is going and who is waiting.
  MeetPlayersProvider._({
    required MeetPlayersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'meetPlayersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$meetPlayersHash();

  @override
  String toString() {
    return r'meetPlayersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MeetPlayer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MeetPlayer>> create(Ref ref) {
    final argument = this.argument as String;
    return meetPlayers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetPlayersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$meetPlayersHash() => r'c74e863cbeccd08b918f880760f4deaa6ba5a6dc';

/// Who is going and who is waiting.

final class MeetPlayersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MeetPlayer>>, String> {
  MeetPlayersFamily._()
    : super(
        retry: null,
        name: r'meetPlayersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Who is going and who is waiting.

  MeetPlayersProvider call(String id) =>
      MeetPlayersProvider._(argument: id, from: this);

  @override
  String toString() => r'meetPlayersProvider';
}

@ProviderFor(walkInCandidates)
final walkInCandidatesProvider = WalkInCandidatesFamily._();

final class WalkInCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MeetPlayer>>,
          List<MeetPlayer>,
          FutureOr<List<MeetPlayer>>
        >
    with $FutureModifier<List<MeetPlayer>>, $FutureProvider<List<MeetPlayer>> {
  WalkInCandidatesProvider._({
    required WalkInCandidatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'walkInCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$walkInCandidatesHash();

  @override
  String toString() {
    return r'walkInCandidatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MeetPlayer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MeetPlayer>> create(Ref ref) {
    final argument = this.argument as String;
    return walkInCandidates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WalkInCandidatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walkInCandidatesHash() => r'451c4399f14b9c856d03c12aa6822af4e71926e7';

final class WalkInCandidatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MeetPlayer>>, String> {
  WalkInCandidatesFamily._()
    : super(
        retry: null,
        name: r'walkInCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WalkInCandidatesProvider call(String id) =>
      WalkInCandidatesProvider._(argument: id, from: this);

  @override
  String toString() => r'walkInCandidatesProvider';
}

@ProviderFor(cancelPreview)
final cancelPreviewProvider = CancelPreviewFamily._();

final class CancelPreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<CancelPreview>,
          CancelPreview,
          FutureOr<CancelPreview>
        >
    with $FutureModifier<CancelPreview>, $FutureProvider<CancelPreview> {
  CancelPreviewProvider._({
    required CancelPreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cancelPreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cancelPreviewHash();

  @override
  String toString() {
    return r'cancelPreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CancelPreview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CancelPreview> create(Ref ref) {
    final argument = this.argument as String;
    return cancelPreview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CancelPreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cancelPreviewHash() => r'1738274bac9d4e2a8911b1e01b205669f0223bca';

final class CancelPreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CancelPreview>, String> {
  CancelPreviewFamily._()
    : super(
        retry: null,
        name: r'cancelPreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CancelPreviewProvider call(String id) =>
      CancelPreviewProvider._(argument: id, from: this);

  @override
  String toString() => r'cancelPreviewProvider';
}

@ProviderFor(meetRecap)
final meetRecapProvider = MeetRecapFamily._();

final class MeetRecapProvider
    extends
        $FunctionalProvider<
          AsyncValue<MeetRecap>,
          MeetRecap,
          FutureOr<MeetRecap>
        >
    with $FutureModifier<MeetRecap>, $FutureProvider<MeetRecap> {
  MeetRecapProvider._({
    required MeetRecapFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'meetRecapProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$meetRecapHash();

  @override
  String toString() {
    return r'meetRecapProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MeetRecap> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MeetRecap> create(Ref ref) {
    final argument = this.argument as String;
    return meetRecap(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetRecapProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$meetRecapHash() => r'94516ddcc0341058cf09b258f4f7179f76c93377';

final class MeetRecapFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MeetRecap>, String> {
  MeetRecapFamily._()
    : super(
        retry: null,
        name: r'meetRecapProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MeetRecapProvider call(String id) =>
      MeetRecapProvider._(argument: id, from: this);

  @override
  String toString() => r'meetRecapProvider';
}

@ProviderFor(matchScore)
final matchScoreProvider = MatchScoreFamily._();

final class MatchScoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<MatchScore>,
          MatchScore,
          FutureOr<MatchScore>
        >
    with $FutureModifier<MatchScore>, $FutureProvider<MatchScore> {
  MatchScoreProvider._({
    required MatchScoreFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchScoreProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchScoreHash();

  @override
  String toString() {
    return r'matchScoreProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MatchScore> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MatchScore> create(Ref ref) {
    final argument = this.argument as String;
    return matchScore(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchScoreProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchScoreHash() => r'907449c8d20bb52dcf8163764c47834893f5a9aa';

final class MatchScoreFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MatchScore>, String> {
  MatchScoreFamily._()
    : super(
        retry: null,
        name: r'matchScoreProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MatchScoreProvider call(String id) =>
      MatchScoreProvider._(argument: id, from: this);

  @override
  String toString() => r'matchScoreProvider';
}

/// The create flow's answers, kept while moving between steps.

@ProviderFor(ActivityDraftController)
final activityDraftControllerProvider = ActivityDraftControllerProvider._();

/// The create flow's answers, kept while moving between steps.
final class ActivityDraftControllerProvider
    extends $NotifierProvider<ActivityDraftController, ActivityDraft> {
  /// The create flow's answers, kept while moving between steps.
  ActivityDraftControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityDraftControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityDraftControllerHash();

  @$internal
  @override
  ActivityDraftController create() => ActivityDraftController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActivityDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActivityDraft>(value),
    );
  }
}

String _$activityDraftControllerHash() =>
    r'be192ba1630ef712529a80577b24f70ecd8948b0';

/// The create flow's answers, kept while moving between steps.

abstract class _$ActivityDraftController extends $Notifier<ActivityDraft> {
  ActivityDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ActivityDraft, ActivityDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActivityDraft, ActivityDraft>,
              ActivityDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
