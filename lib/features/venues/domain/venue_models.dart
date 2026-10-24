import 'package:freezed_annotation/freezed_annotation.dart';

import '../../onboarding/domain/sport.dart';
import '../../play/domain/activity.dart';

part 'venue_models.freezed.dart';

/// Courts of one sport at a venue, with hourly prices.
@freezed
abstract class CourtType with _$CourtType {
  const factory CourtType({
    required Sport sport,
    required int count,
    required int offPeakCents,
    required int peakCents,

    /// "lights till 10 PM", "outdoor".
    @Default('') String note,
  }) = _CourtType;
}

/// A bookable venue, as its page shows it.
@freezed
abstract class VenueDetail with _$VenueDetail {
  const factory VenueDetail({
    required String id,
    required String name,
    required String address,
    @Default('') String distance,
    @Default(7) int opensHour,
    @Default(23) int closesHour,
    @Default([]) List<CourtType> courts,
    @Default([]) List<String> amenities,
    @Default(false) bool verified,
    double? rating,
    @Default(0) int ratingCount,
    @Default(false) bool autoCheckIn,
    @Default(0xFF16181B) int color,
    @Default(0xFFC6FF00) int ink,
  }) = _VenueDetail;

  const VenueDetail._();

  /// "TH" for Tampines Hub.
  String get mark {
    final words = name
        .replaceAll(RegExp(r'[^A-Za-z ]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty && w[0] == w[0].toUpperCase())
        .where((w) => !const {'Our', 'The'}.contains(w))
        .toList();
    return words.take(2).map((w) => w[0]).join();
  }

  Venue get asVenue =>
      Venue(id: id, name: name, address: address, distance: distance);

  Set<Sport> get sports => {for (final c in courts) c.sport};

  CourtType? courtsFor(Sport sport) =>
      courts.where((c) => c.sport == sport).firstOrNull;

  /// Peak: weekdays 6 to 10 PM, weekends all day.
  static bool isPeak(DateTime at) =>
      at.weekday >= DateTime.saturday || (at.hour >= 18 && at.hour < 22);

  int rateCents(Sport sport, DateTime at) {
    final c = courtsFor(sport);
    if (c == null) return 0;
    return isPeak(at) ? c.peakCents : c.offPeakCents;
  }
}

/// One start time on the booking grid.
@freezed
abstract class CourtSlot with _$CourtSlot {
  const factory CourtSlot({
    required DateTime start,
    required int rateCents,
    required bool free,
  }) = _CourtSlot;

  const CourtSlot._();

  bool get peak => VenueDetail.isPeak(start);
}

enum BookingStatus { confirmed, cancelled }

/// A booked court.
@freezed
abstract class CourtBooking with _$CourtBooking {
  const factory CourtBooking({
    required String id,
    required String venueId,
    required String venueName,
    required String venueAddress,
    required Sport sport,
    required String court,
    required DateTime start,
    required DateTime end,
    required int courtCents,
    required int feeCents,

    /// Opens the court door, from 10 minutes before.
    required String doorCode,
    required String code,
    @Default(BookingStatus.confirmed) BookingStatus status,
    @Default(0) int refundCents,
  }) = _CourtBooking;

  const CourtBooking._();

  int get paidCents => courtCents + feeCents;

  /// Free to cancel until 24 hours before.
  DateTime get freeCancelUntil => start.subtract(const Duration(hours: 24));

  bool get canCancelFree => DateTime.now().isBefore(freeCancelUntil);

  /// Back to the Wallet: all of it. To a card: the court price only.
  int refundTo({required bool wallet}) =>
      !canCancelFree ? 0 : (wallet ? paidCents : courtCents);
}
