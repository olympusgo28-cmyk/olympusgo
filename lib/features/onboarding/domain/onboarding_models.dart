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

  /// "Level 4.0 · Low Intermediate · Plays with 3.0 to 5.0".
  String get summary =>
      'Level ${SkillScale.describe(level)} · Plays with '
      '${playMin.toStringAsFixed(1)} to ${playMax.toStringAsFixed(1)}';
}

/// Everything collected during the 7 onboarding steps, held in memory until
/// it is saved to the player's profile.
@freezed
abstract class OnboardingDraft with _$OnboardingDraft {
  const factory OnboardingDraft({
    @Default('') String fullName,
    DateTime? birthday,
    @Default(Country.singapore) Country country,
    @Default([Sport.badminton, Sport.pickleball]) List<Sport> sports,
    @Default({}) Map<Sport, SportSkill> skills,
    @Default('') String username,
    @Default('') String email,
  }) = _OnboardingDraft;

  const OnboardingDraft._();

  SportSkill skillFor(Sport sport) => skills[sport] ?? SportSkill(sport: sport);
}
