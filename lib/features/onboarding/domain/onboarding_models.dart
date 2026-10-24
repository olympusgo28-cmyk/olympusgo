import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/country.dart';
import 'sport.dart';

part 'onboarding_models.freezed.dart';

/// Level and the range of players someone likes to play with, per sport.
@freezed
abstract class SportSkill with _$SportSkill {
  const factory SportSkill({
    required Sport sport,
    @Default(4.0) double level,
    @Default(3.0) double playMin,
    @Default(5.0) double playMax,
  }) = _SportSkill;

  const SportSkill._();

  /// "Level 4.0 · Low Intermediate". The play range is set inside.
  String get summary => 'Level ${SkillScale.describe(level)}';
}

/// Everything collected during the 7 onboarding steps, held in memory until
/// it is saved to the player's profile.
@freezed
abstract class OnboardingDraft with _$OnboardingDraft {
  const factory OnboardingDraft({
    @Default('') String fullName,
    DateTime? birthday,
    @Default(Country.singapore) Country country,
    String? parentEmail,
    @Default([Sport.badminton, Sport.pickleball]) List<Sport> sports,
    @Default({}) Map<Sport, SportSkill> skills,
    @Default('') String username,
    @Default(Country.singapore) Country phoneCountry,
    @Default('') String phoneNumber,
  }) = _OnboardingDraft;

  const OnboardingDraft._();

  SportSkill skillFor(Sport sport) => skills[sport] ?? SportSkill(sport: sport);

  /// Age in whole years today, or null before a birthday is entered.
  int? get age {
    final b = birthday;
    if (b == null) return null;
    final now = DateTime.now();
    var years = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      years--;
    }
    return years;
  }

  String get fullPhone =>
      '${phoneCountry.dialCode}${phoneNumber.replaceAll(RegExp(r'\D'), '')}';
}
