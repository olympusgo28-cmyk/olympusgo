import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/country.dart';

part 'settings_models.freezed.dart';

enum Gender {
  male('male', 'Male'),
  female('female', 'Female'),
  nonBinary('non_binary', 'Non-binary'),
  preferNotToSay('prefer_not_to_say', 'Prefer not to say');

  const Gender(this.id, this.label);
  final String id;
  final String label;

  static Gender fromId(String? id) =>
      values.firstWhere((g) => g.id == id, orElse: () => preferNotToSay);
}

enum ProfileVisibility {
  everyone('everyone', 'Everyone'),
  followers('followers', 'Followers'),
  onlyMe('only_me', 'Only me');

  const ProfileVisibility(this.id, this.label);
  final String id;
  final String label;

  static ProfileVisibility fromId(String? id) =>
      values.firstWhere((v) => v.id == id, orElse: () => followers);
}

/// Fields on the Account centre screen.
@freezed
abstract class AccountDetails with _$AccountDetails {
  const factory AccountDetails({
    @Default('') String fullName,
    @Default('') String username,
    @Default('') String bio,
    @Default(Gender.preferNotToSay) Gender gender,
    String? avatarUrl,
  }) = _AccountDetails;
}

/// Fields on the Personal information screen. Only the owner sees these.
@freezed
abstract class PrivateInfo with _$PrivateInfo {
  const factory PrivateInfo({
    @Default('') String email,
    @Default('') String phone,
    DateTime? birthday,
    @Default(Country.singapore) Country country,

    /// Checked by the review team; needed to run paid tournaments and
    /// receive payouts.
    @Default(false) bool identityVerified,
  }) = _PrivateInfo;
}

@freezed
abstract class NotificationPrefs with _$NotificationPrefs {
  const factory NotificationPrefs({
    @Default(true) bool meetReminders,
    @Default(true) bool courtCalls,
    @Default(true) bool messages,
    @Default(true) bool newFollowers,
    @Default(false) bool offersAndNews,
  }) = _NotificationPrefs;
}

@freezed
abstract class PrivacyPrefs with _$PrivacyPrefs {
  const factory PrivacyPrefs({
    @Default(ProfileVisibility.followers) ProfileVisibility visibility,
    @Default(true) bool showLevel,
    @Default(false) bool findableByPhone,
    @Default(true) bool shareLocationAtMeets,
  }) = _PrivacyPrefs;
}
