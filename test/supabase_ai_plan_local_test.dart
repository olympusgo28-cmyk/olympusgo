// AI plans through the real API and Edge Function, with the stand-in planner.
// Skipped unless LOCAL_MONEY_TESTS is set, because it needs `supabase functions
// serve` running. Never the hosted project, and it never calls the model.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/fitness/data/fitness_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/local_accounts.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final service = Platform.environment['LOCAL_SUPABASE_SERVICE_KEY'];
  final skip =
      url == null ||
          key == null ||
          service == null ||
          !url.contains('127.0.0.1') ||
          Platform.environment['LOCAL_MONEY_TESTS'] == null
      ? 'Needs a local stack, its functions and LOCAL_MONEY_TESTS'
      : null;

  late SupabaseClient admin;
  const flags = ['fitness.enabled', 'fitness.ai_plans'];

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
        .inFilter('key', flags);
  });

  tearDownAll(() async {
    if (skip != null) return;
    await admin
        .from('feature_flags')
        .update({'enabled': false})
        .inFilter('key', flags);
  });

  String stamp() => 'key-${DateTime.now().microsecondsSinceEpoch}';

  test('no agreement, no plan', () async {
    final repo = SupabaseFitnessRepository(await player('ai1', '1990-01-01'));
    expect((await repo.aiStatus()).agreed, isFalse);
    await expectLater(
      repo.askPlan(key: stamp(), goal: 'speed', days: 3),
      throwsA(
        isA<AiPlanRefused>().having(
          (e) => e.message,
          'message',
          contains('Agree'),
        ),
      ),
    );
  }, skip: skip);

  test('an adult gets one plan for one key', () async {
    final repo = SupabaseFitnessRepository(await player('ai2', '1990-01-01'));
    await repo.setAiConsent(true);
    final status = await repo.aiStatus();
    expect(status.open, isTrue);
    expect(status.agreed, isTrue);
    expect(status.left, 3);

    final k = stamp();
    final id = await repo.askPlan(key: k, goal: 'speed', days: 3);
    expect(await repo.askPlan(key: k, goal: 'speed', days: 3), id);
    expect((await repo.aiStatus()).left, 2);

    final mine = (await repo.programs()).where((p) => p.fromAi).toList();
    expect(mine, hasLength(1));
    expect(mine.single.id, id);
    expect(mine.single.days, hasLength(3));
    for (final day in mine.single.days) {
      expect(day.items, isNotEmpty);
      expect(day.items.every((i) => i.weightG == null), isTrue);
    }

    await repo.setAiConsent(false);
    await expectLater(
      repo.askPlan(key: stamp(), goal: 'speed', days: 3),
      throwsA(
        isA<AiPlanRefused>().having(
          (e) => e.message,
          'message',
          contains('Agree'),
        ),
      ),
    );
  }, skip: skip);

  test('a teen is refused, and a bad goal is too', () async {
    final teen = await player('ai3', '2011-01-01');
    final child = teen.auth.currentUser!.id;
    final parent = await player('ai3p', '1980-01-01');
    await admin.from('guardian_links').insert({
      'child_id': child,
      'parent_id': parent.auth.currentUser!.id,
      'status': 'approved',
    });
    final repo = SupabaseFitnessRepository(teen);
    expect((await repo.aiStatus()).open, isFalse);
    await expectLater(
      repo.setAiConsent(true),
      throwsA(
        isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('adults'),
        ),
      ),
    );
    await expectLater(
      repo.askPlan(key: stamp(), goal: 'speed', days: 3),
      throwsA(
        isA<AiPlanRefused>().having(
          (e) => e.message,
          'message',
          contains('adults'),
        ),
      ),
    );

    final adult = SupabaseFitnessRepository(await player('ai4', '1990-01-01'));
    await adult.setAiConsent(true);
    await expectLater(
      adult.askPlan(key: stamp(), goal: 'lose weight', days: 3),
      throwsA(isA<AiPlanRefused>()),
    );
  }, skip: skip);

  test('signed out gets nowhere', () async {
    final c = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await expectLater(
      c.functions.invoke(
        'ai-plan',
        body: {'client_key': stamp(), 'goal': 'speed', 'days': 3},
      ),
      throwsA(isA<FunctionException>().having((e) => e.status, 'status', 401)),
    );
  }, skip: skip);
}
