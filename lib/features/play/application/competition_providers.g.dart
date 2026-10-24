// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competition_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tournamentInfo)
final tournamentInfoProvider = TournamentInfoFamily._();

final class TournamentInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<TournamentInfo>,
          TournamentInfo,
          FutureOr<TournamentInfo>
        >
    with $FutureModifier<TournamentInfo>, $FutureProvider<TournamentInfo> {
  TournamentInfoProvider._({
    required TournamentInfoFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentInfoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentInfoHash();

  @override
  String toString() {
    return r'tournamentInfoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TournamentInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TournamentInfo> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentInfo(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentInfoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentInfoHash() => r'304a1a32c59640ef96f1d366b513c52bc6f4a7e5';

final class TournamentInfoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TournamentInfo>, String> {
  TournamentInfoFamily._()
    : super(
        retry: null,
        name: r'tournamentInfoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TournamentInfoProvider call(String id) =>
      TournamentInfoProvider._(argument: id, from: this);

  @override
  String toString() => r'tournamentInfoProvider';
}

@ProviderFor(tournamentEntries)
final tournamentEntriesProvider = TournamentEntriesFamily._();

final class TournamentEntriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Entry>>,
          List<Entry>,
          FutureOr<List<Entry>>
        >
    with $FutureModifier<List<Entry>>, $FutureProvider<List<Entry>> {
  TournamentEntriesProvider._({
    required TournamentEntriesFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'tournamentEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentEntriesHash();

  @override
  String toString() {
    return r'tournamentEntriesProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Entry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Entry>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return tournamentEntries(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentEntriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentEntriesHash() => r'8e5db02a99da5d39cb50c768ebe7832ed80e4b52';

final class TournamentEntriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Entry>>, (String, String)> {
  TournamentEntriesFamily._()
    : super(
        retry: null,
        name: r'tournamentEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TournamentEntriesProvider call(String id, String division) =>
      TournamentEntriesProvider._(argument: (id, division), from: this);

  @override
  String toString() => r'tournamentEntriesProvider';
}

@ProviderFor(drawGroups)
final drawGroupsProvider = DrawGroupsFamily._();

final class DrawGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DrawGroup>>,
          List<DrawGroup>,
          FutureOr<List<DrawGroup>>
        >
    with $FutureModifier<List<DrawGroup>>, $FutureProvider<List<DrawGroup>> {
  DrawGroupsProvider._({
    required DrawGroupsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'drawGroupsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$drawGroupsHash();

  @override
  String toString() {
    return r'drawGroupsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<DrawGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DrawGroup>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return drawGroups(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is DrawGroupsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$drawGroupsHash() => r'f60e1bd714fd88db683b170b72830f2fa51043bd';

final class DrawGroupsFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<DrawGroup>>, (String, String)> {
  DrawGroupsFamily._()
    : super(
        retry: null,
        name: r'drawGroupsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DrawGroupsProvider call(String id, String division) =>
      DrawGroupsProvider._(argument: (id, division), from: this);

  @override
  String toString() => r'drawGroupsProvider';
}

@ProviderFor(drawKnockout)
final drawKnockoutProvider = DrawKnockoutFamily._();

final class DrawKnockoutProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<KnockoutRound>>,
          List<KnockoutRound>,
          FutureOr<List<KnockoutRound>>
        >
    with
        $FutureModifier<List<KnockoutRound>>,
        $FutureProvider<List<KnockoutRound>> {
  DrawKnockoutProvider._({
    required DrawKnockoutFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'drawKnockoutProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$drawKnockoutHash();

  @override
  String toString() {
    return r'drawKnockoutProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<KnockoutRound>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<KnockoutRound>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return drawKnockout(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is DrawKnockoutProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$drawKnockoutHash() => r'8058ac8b5f649fd450816adc355a102e90146555';

final class DrawKnockoutFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<KnockoutRound>>,
          (String, String)
        > {
  DrawKnockoutFamily._()
    : super(
        retry: null,
        name: r'drawKnockoutProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DrawKnockoutProvider call(String id, String division) =>
      DrawKnockoutProvider._(argument: (id, division), from: this);

  @override
  String toString() => r'drawKnockoutProvider';
}

@ProviderFor(myTournamentMatches)
final myTournamentMatchesProvider = MyTournamentMatchesFamily._();

final class MyTournamentMatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MyMatch>>,
          List<MyMatch>,
          FutureOr<List<MyMatch>>
        >
    with $FutureModifier<List<MyMatch>>, $FutureProvider<List<MyMatch>> {
  MyTournamentMatchesProvider._({
    required MyTournamentMatchesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myTournamentMatchesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myTournamentMatchesHash();

  @override
  String toString() {
    return r'myTournamentMatchesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MyMatch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MyMatch>> create(Ref ref) {
    final argument = this.argument as String;
    return myTournamentMatches(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyTournamentMatchesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myTournamentMatchesHash() =>
    r'c775427f0af53c65cb663c0f2e62060320d38491';

final class MyTournamentMatchesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MyMatch>>, String> {
  MyTournamentMatchesFamily._()
    : super(
        retry: null,
        name: r'myTournamentMatchesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyTournamentMatchesProvider call(String id) =>
      MyTournamentMatchesProvider._(argument: id, from: this);

  @override
  String toString() => r'myTournamentMatchesProvider';
}

@ProviderFor(tournamentResult)
final tournamentResultProvider = TournamentResultFamily._();

final class TournamentResultProvider
    extends
        $FunctionalProvider<
          AsyncValue<TournamentResult?>,
          TournamentResult?,
          FutureOr<TournamentResult?>
        >
    with
        $FutureModifier<TournamentResult?>,
        $FutureProvider<TournamentResult?> {
  TournamentResultProvider._({
    required TournamentResultFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tournamentResultProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tournamentResultHash();

  @override
  String toString() {
    return r'tournamentResultProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TournamentResult?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TournamentResult?> create(Ref ref) {
    final argument = this.argument as String;
    return tournamentResult(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TournamentResultProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tournamentResultHash() => r'266427b1e339b5cd2dbd1b68f213b7b259e6aebe';

final class TournamentResultFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TournamentResult?>, String> {
  TournamentResultFamily._()
    : super(
        retry: null,
        name: r'tournamentResultProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TournamentResultProvider call(String id) =>
      TournamentResultProvider._(argument: id, from: this);

  @override
  String toString() => r'tournamentResultProvider';
}

@ProviderFor(partnerPicks)
final partnerPicksProvider = PartnerPicksFamily._();

final class PartnerPicksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PartnerPick>>,
          List<PartnerPick>,
          FutureOr<List<PartnerPick>>
        >
    with
        $FutureModifier<List<PartnerPick>>,
        $FutureProvider<List<PartnerPick>> {
  PartnerPicksProvider._({
    required PartnerPicksFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'partnerPicksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partnerPicksHash();

  @override
  String toString() {
    return r'partnerPicksProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PartnerPick>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PartnerPick>> create(Ref ref) {
    final argument = this.argument as String;
    return partnerPicks(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartnerPicksProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partnerPicksHash() => r'8a69f1a7c359d16d8950208ace949ffceac18443';

final class PartnerPicksFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PartnerPick>>, String> {
  PartnerPicksFamily._()
    : super(
        retry: null,
        name: r'partnerPicksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PartnerPicksProvider call(String id) =>
      PartnerPicksProvider._(argument: id, from: this);

  @override
  String toString() => r'partnerPicksProvider';
}

@ProviderFor(eventInfo)
final eventInfoProvider = EventInfoFamily._();

final class EventInfoProvider
    extends
        $FunctionalProvider<
          AsyncValue<EventInfo>,
          EventInfo,
          FutureOr<EventInfo>
        >
    with $FutureModifier<EventInfo>, $FutureProvider<EventInfo> {
  EventInfoProvider._({
    required EventInfoFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventInfoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventInfoHash();

  @override
  String toString() {
    return r'eventInfoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<EventInfo> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<EventInfo> create(Ref ref) {
    final argument = this.argument as String;
    return eventInfo(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventInfoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventInfoHash() => r'5e27d93a188f7ebaa41209b9b3047be1c0a50d55';

final class EventInfoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<EventInfo>, String> {
  EventInfoFamily._()
    : super(
        retry: null,
        name: r'eventInfoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventInfoProvider call(String id) =>
      EventInfoProvider._(argument: id, from: this);

  @override
  String toString() => r'eventInfoProvider';
}

@ProviderFor(eventTicket)
final eventTicketProvider = EventTicketFamily._();

final class EventTicketProvider
    extends $FunctionalProvider<AsyncValue<Ticket?>, Ticket?, FutureOr<Ticket?>>
    with $FutureModifier<Ticket?>, $FutureProvider<Ticket?> {
  EventTicketProvider._({
    required EventTicketFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventTicketProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventTicketHash();

  @override
  String toString() {
    return r'eventTicketProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Ticket?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Ticket?> create(Ref ref) {
    final argument = this.argument as String;
    return eventTicket(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventTicketProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventTicketHash() => r'b30f4812c6ed389937213b9db0cfc06bfa000b1d';

final class EventTicketFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Ticket?>, String> {
  EventTicketFamily._()
    : super(
        retry: null,
        name: r'eventTicketProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventTicketProvider call(String id) =>
      EventTicketProvider._(argument: id, from: this);

  @override
  String toString() => r'eventTicketProvider';
}
