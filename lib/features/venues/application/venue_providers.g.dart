// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(venueList)
final venueListProvider = VenueListProvider._();

final class VenueListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VenueDetail>>,
          List<VenueDetail>,
          FutureOr<List<VenueDetail>>
        >
    with
        $FutureModifier<List<VenueDetail>>,
        $FutureProvider<List<VenueDetail>> {
  VenueListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'venueListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$venueListHash();

  @$internal
  @override
  $FutureProviderElement<List<VenueDetail>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<VenueDetail>> create(Ref ref) {
    return venueList(ref);
  }
}

String _$venueListHash() => r'19e98b310aa7cfbb3a0fb648498bb30e67877c49';

@ProviderFor(venueDetail)
final venueDetailProvider = VenueDetailFamily._();

final class VenueDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<VenueDetail>,
          VenueDetail,
          FutureOr<VenueDetail>
        >
    with $FutureModifier<VenueDetail>, $FutureProvider<VenueDetail> {
  VenueDetailProvider._({
    required VenueDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'venueDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$venueDetailHash();

  @override
  String toString() {
    return r'venueDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<VenueDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<VenueDetail> create(Ref ref) {
    final argument = this.argument as String;
    return venueDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VenueDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$venueDetailHash() => r'b690bc4baa14b19ba1f65353f8b79c05da54920a';

final class VenueDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<VenueDetail>, String> {
  VenueDetailFamily._()
    : super(
        retry: null,
        name: r'venueDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VenueDetailProvider call(String id) =>
      VenueDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'venueDetailProvider';
}

/// Start times for one sport, day and length at a venue.

@ProviderFor(courtSlots)
final courtSlotsProvider = CourtSlotsFamily._();

/// Start times for one sport, day and length at a venue.

final class CourtSlotsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CourtSlot>>,
          List<CourtSlot>,
          FutureOr<List<CourtSlot>>
        >
    with $FutureModifier<List<CourtSlot>>, $FutureProvider<List<CourtSlot>> {
  /// Start times for one sport, day and length at a venue.
  CourtSlotsProvider._({
    required CourtSlotsFamily super.from,
    required (String, Sport, DateTime, int) super.argument,
  }) : super(
         retry: null,
         name: r'courtSlotsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$courtSlotsHash();

  @override
  String toString() {
    return r'courtSlotsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<CourtSlot>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourtSlot>> create(Ref ref) {
    final argument = this.argument as (String, Sport, DateTime, int);
    return courtSlots(ref, argument.$1, argument.$2, argument.$3, argument.$4);
  }

  @override
  bool operator ==(Object other) {
    return other is CourtSlotsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courtSlotsHash() => r'fede1c975a86cf941685463f6638f82ea0f505c4';

/// Start times for one sport, day and length at a venue.

final class CourtSlotsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<CourtSlot>>,
          (String, Sport, DateTime, int)
        > {
  CourtSlotsFamily._()
    : super(
        retry: null,
        name: r'courtSlotsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Start times for one sport, day and length at a venue.

  CourtSlotsProvider call(
    String venueId,
    Sport sport,
    DateTime day,
    int hours,
  ) => CourtSlotsProvider._(argument: (venueId, sport, day, hours), from: this);

  @override
  String toString() => r'courtSlotsProvider';
}

@ProviderFor(myCourtBookings)
final myCourtBookingsProvider = MyCourtBookingsProvider._();

final class MyCourtBookingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CourtBooking>>,
          List<CourtBooking>,
          FutureOr<List<CourtBooking>>
        >
    with
        $FutureModifier<List<CourtBooking>>,
        $FutureProvider<List<CourtBooking>> {
  MyCourtBookingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myCourtBookingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myCourtBookingsHash();

  @$internal
  @override
  $FutureProviderElement<List<CourtBooking>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourtBooking>> create(Ref ref) {
    return myCourtBookings(ref);
  }
}

String _$myCourtBookingsHash() => r'c34538ae87e1985c215f93348ff80c09e7c956b7';

@ProviderFor(courtBooking)
final courtBookingProvider = CourtBookingFamily._();

final class CourtBookingProvider
    extends
        $FunctionalProvider<
          AsyncValue<CourtBooking>,
          CourtBooking,
          FutureOr<CourtBooking>
        >
    with $FutureModifier<CourtBooking>, $FutureProvider<CourtBooking> {
  CourtBookingProvider._({
    required CourtBookingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'courtBookingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$courtBookingHash();

  @override
  String toString() {
    return r'courtBookingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CourtBooking> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CourtBooking> create(Ref ref) {
    final argument = this.argument as String;
    return courtBooking(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CourtBookingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courtBookingHash() => r'222a0c2c8f17ce29f3a7345cebb570e36b7039c5';

final class CourtBookingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CourtBooking>, String> {
  CourtBookingFamily._()
    : super(
        retry: null,
        name: r'courtBookingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CourtBookingProvider call(String id) =>
      CourtBookingProvider._(argument: id, from: this);

  @override
  String toString() => r'courtBookingProvider';
}

/// Meets, tournaments and events at a venue in the next 7 days.

@ProviderFor(venueActivities)
final venueActivitiesProvider = VenueActivitiesFamily._();

/// Meets, tournaments and events at a venue in the next 7 days.

final class VenueActivitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Activity>>,
          List<Activity>,
          FutureOr<List<Activity>>
        >
    with $FutureModifier<List<Activity>>, $FutureProvider<List<Activity>> {
  /// Meets, tournaments and events at a venue in the next 7 days.
  VenueActivitiesProvider._({
    required VenueActivitiesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'venueActivitiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$venueActivitiesHash();

  @override
  String toString() {
    return r'venueActivitiesProvider'
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
    final argument = this.argument as String;
    return venueActivities(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VenueActivitiesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$venueActivitiesHash() => r'93fc8157a20f43cd9e257a9795bcfb4a84eff59a';

/// Meets, tournaments and events at a venue in the next 7 days.

final class VenueActivitiesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Activity>>, String> {
  VenueActivitiesFamily._()
    : super(
        retry: null,
        name: r'venueActivitiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Meets, tournaments and events at a venue in the next 7 days.

  VenueActivitiesProvider call(String venueId) =>
      VenueActivitiesProvider._(argument: venueId, from: this);

  @override
  String toString() => r'venueActivitiesProvider';
}
