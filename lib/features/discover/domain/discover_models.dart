import 'package:freezed_annotation/freezed_annotation.dart';

import '../../onboarding/domain/sport.dart';
import '../../play/domain/activity.dart';

part 'discover_models.freezed.dart';

/// What the Find screen is asking for.
@freezed
abstract class DiscoverFilter with _$DiscoverFilter {
  const factory DiscoverFilter({
    Sport? sport,
    DateTime? day,

    /// Start of the time of day, as an hour, with [hourTo].
    int? hourFrom,
    int? hourTo,
    double? maxKm,
  }) = _DiscoverFilter;
}

/// A Meet found near you, with how far away it is if your area is known.
@freezed
abstract class FoundSession with _$FoundSession {
  const factory FoundSession({
    required Activity activity,
    double? km,
    double? latitude,
    double? longitude,
    @Default(false) bool fitsMe,
  }) = _FoundSession;
}
