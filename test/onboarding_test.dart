import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/domain/country.dart';
import 'package:olympus_go/features/auth/presentation/validators.dart';
import 'package:olympus_go/features/onboarding/application/onboarding_controller.dart';
import 'package:olympus_go/features/onboarding/domain/onboarding_models.dart';
import 'package:olympus_go/features/onboarding/domain/sport.dart';

void main() {
  group('OnboardingDraft.age', () {
    test('is null before a birthday is entered', () {
      expect(const OnboardingDraft().age, isNull);
    });

    test('counts a birthday later this year as not yet reached', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final draft = OnboardingDraft(
        birthday: DateTime(now.year - 18, tomorrow.month, tomorrow.day),
      );
      expect(draft.age, 17);
    });
  });

  test('fullPhone joins dial code and digits only', () {
    const draft = OnboardingDraft(
      phoneCountry: Country.malaysia,
      phoneNumber: '12 345 6789',
    );
    expect(draft.fullPhone, '+60123456789');
  });

  test('toggleSport keeps the design order and can remove a sport', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(onboardingControllerProvider.notifier);

    notifier.toggleSport(Sport.cycling);
    notifier.toggleSport(Sport.tennis);
    notifier.toggleSport(Sport.badminton);

    expect(container.read(onboardingControllerProvider).sports, [
      Sport.pickleball,
      Sport.tennis,
      Sport.cycling,
    ]);
  });

  test('skill scale runs 1.0 to 8.0 in whole levels, each with a name', () {
    expect(SkillScale.levels, [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]);
    expect(SkillScale.describe(4.0), '4.0 · Low Intermediate');
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('alex@'), isNotNull);
      expect(Validators.email('alex@example.com'), isNull);
    });

    test('username', () {
      expect(Validators.username('al'), isNotNull);
      expect(Validators.username('alex plays'), isNotNull);
      expect(Validators.username('alex_plays'), isNull);
    });

    test('mobile', () {
      expect(Validators.mobile('123'), isNotNull);
      expect(Validators.mobile('91234567'), isNull);
    });
  });
}
