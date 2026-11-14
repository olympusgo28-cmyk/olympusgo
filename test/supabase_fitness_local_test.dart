// Fitness through the real API, as a signed-in phone reaches it: the request
// gate, the rate rules and the JSON the repository reads. Never the hosted
// project.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/fitness/data/fitness_repository.dart';
import 'package:olympus_go/features/fitness/domain/fitness_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/local_accounts.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final service = Platform.environment['LOCAL_SUPABASE_SERVICE_KEY'];
  final skip = url == null || key == null || service == null
      ? 'Needs a local stack'
      : (!url.contains('127.0.0.1') ? 'Local stack only' : null);

  late SupabaseClient admin;

  Future<SupabaseClient> player(String name, String birthday) async {
    final c = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await signUpLocal(
      c,
      email: '$name.$stamp@test.local',
      password: 'test-password-123',
    );
    await c.rpc(
      'set_birthday',
      params: {'p_birthday': birthday, 'p_country': 'SG'},
    );
    await c
        .from('profiles')
        .update({
          'username': '${name}_${stamp % 10000000}',
          'full_name': '$name Test',
          'onboarding_completed': true,
        })
        .eq('id', c.auth.currentUser!.id);
    return c;
  }

  setUpAll(() async {
    if (skip != null) return;
    admin = SupabaseClient(
      url!,
      service!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await admin
        .from('feature_flags')
        .update({'enabled': true})
        .eq('key', 'fitness.enabled');
  });

  tearDownAll(() async {
    if (skip != null) return;
    await admin
        .from('feature_flags')
        .update({'enabled': false})
        .eq('key', 'fitness.enabled');
  });

  test('a player builds a program, logs a workout and sees it', () async {
    final c = await player('fit', '1990-01-01');
    final repo = SupabaseFitnessRepository(c);
    expect(await repo.open(), isTrue);

    final list = await repo.exercises();
    expect(list.length, greaterThanOrEqualTo(40));
    final squat = list.firstWhere((e) => e.name == 'Back squat');
    final plank = list.firstWhere((e) => e.name == 'Plank');
    expect(plank.timed, isTrue);

    final all = await repo.programs();
    expect(all.where((p) => p.template), hasLength(3));

    const id = 'f1000000-0000-4000-8000-000000000000';
    final unique = id.replaceFirst(
      'f1000000',
      (DateTime.now().microsecondsSinceEpoch % 0xffffffff)
          .toRadixString(16)
          .padLeft(8, '0'),
    );
    await repo.saveProgram(
      WorkoutProgram(
        id: unique,
        name: 'Legs',
        days: [
          ProgramDay(
            name: 'Day 1',
            items: [
              ProgramItem.of(squat).change(weightG: 72500),
              ProgramItem.of(plank),
            ],
          ),
        ],
      ),
    );
    final mine = (await repo.programs()).firstWhere((p) => p.id == unique);
    expect(mine.days.single.items.first.weightG, 72500);
    expect(mine.days.single.items.last.timed, isTrue);

    final w =
        ActiveWorkout(
              key: 'key-$unique',
              name: 'Day 1',
              startedAt: DateTime.now().subtract(const Duration(minutes: 40)),
              programId: unique,
              plan: mine.days.single.items,
            )
            .logged(
              LoggedSet(exerciseId: squat.id, reps: 5, weightG: 72500),
              DateTime.now(),
            )
            .ended(DateTime.now());
    await repo.saveWorkout(w);
    await repo.saveWorkout(w);

    final s = await repo.summary();
    expect(s.minor, isFalse);
    expect(s.workouts, 1);
    expect(s.weekStreak, 1);
    expect(s.liftedG, 362500);
    expect(s.recent.single.exercises, 1);
    expect(s.bests.single.exercise, 'Back squat');

    final h = await repo.history(squat.id);
    expect(h.times, 1);
    expect(h.best?.weightG, 72500);

    await repo.deleteWorkout(s.recent.single.id);
    expect((await repo.summary()).workouts, 0);
  }, skip: skip);

  test('a child with no parent is refused at the gate', () async {
    final c = await player('kid', '2015-01-01');
    final repo = SupabaseFitnessRepository(c);
    await expectLater(
      repo.exercises(),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('parent'),
        ),
      ),
    );
  }, skip: skip);
}
