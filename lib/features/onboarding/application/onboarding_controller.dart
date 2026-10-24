import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/country.dart';
import '../../../core/providers.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/onboarding_models.dart';
import '../domain/sport.dart';

part 'onboarding_controller.g.dart';

@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void setName(String name) => state = state.copyWith(fullName: name);

  void setBirthday(DateTime date, Country country) =>
      state = state.copyWith(birthday: date, country: country);

  void setParentEmail(String email) =>
      state = state.copyWith(parentEmail: email);

  void toggleSport(Sport sport) {
    final sports = [...state.sports];
    sports.contains(sport) ? sports.remove(sport) : sports.add(sport);
    // Keep the design's order rather than the order tapped.
    sports.sort((a, b) => a.index.compareTo(b.index));
    state = state.copyWith(sports: sports);
  }

  void setSkill(SportSkill skill) =>
      state = state.copyWith(skills: {...state.skills, skill.sport: skill});

  void setUsername(String username) =>
      state = state.copyWith(username: username);

  void setPhone(Country country, String number) =>
      state = state.copyWith(phoneCountry: country, phoneNumber: number);

  /// Saves the answers to the player's profile.
  Future<void> save({required bool complete}) async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) {
      throw const AuthFailure('You were signed out. Log in again to continue.');
    }
    await ref
        .read(profileRepositoryProvider)
        .saveOnboarding(userId, state, complete: complete);
    if (complete) await ref.read(sessionProfileProvider.notifier).reload();
  }
}
