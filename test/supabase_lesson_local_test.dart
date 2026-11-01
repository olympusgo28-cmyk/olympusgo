// Lessons, verification files, assessments and referrals through the real API,
// the real Edge Functions and the Stripe stand-in. Skipped unless
// LOCAL_MONEY_TESTS is set, because it switches payments on for the whole
// stack: run it alone, with `supabase functions serve` running. Never the
// hosted project.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/academy/data/assessment_repository.dart';
import 'package:olympus_go/features/academy/data/coach_repository.dart';
import 'package:olympus_go/features/academy/data/lesson_repository.dart';
import 'package:olympus_go/features/academy/domain/lesson_models.dart';
import 'package:olympus_go/features/play/data/payment_gateway.dart';
import 'package:olympus_go/features/services/data/services_repository.dart';
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
  var seq = 0;

  Future<SupabaseClient> player(
    String name, {
    String birthday = '1990-01-01',
  }) async {
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

  String idOf(SupabaseClient c) => c.auth.currentUser!.id;

  Future<void> licence(SupabaseClient c) =>
      admin.from('coach_licences').insert({
        'user_id': idOf(c),
        'nroc_number': 'NROC-${seq++}',
        'expires_on': DateTime.now()
            .add(const Duration(days: 300))
            .toIso8601String()
            .substring(0, 10),
        'status': 'verified',
        'verified_at': DateTime.now().toUtc().toIso8601String(),
      });

  /// A verified academy: its owner is head coach and has a payout account.
  Future<String> academy(SupabaseClient owner, SupabaseClient coach) async {
    await licence(owner);
    await licence(coach);
    await admin.from('vendors').insert({
      'owner_id': idOf(owner),
      'stripe_account_id': 'acct_${seq++}_${idOf(owner).substring(0, 8)}',
      'status': 'verified',
    });
    final a = await admin
        .from('academies')
        .insert({
          'owner_id': idOf(owner),
          'name': 'Lesson Academy ${seq++}',
          'sport': 'badminton',
          'verification': 'verified',
          'uen': '201912345A',
        })
        .select('id')
        .single();
    final id = a['id'] as String;
    await admin.from('academy_coaches').insert([
      {
        'academy_id': id,
        'user_id': idOf(owner),
        'role': 'Head coach',
        'head': true,
        'accepted_at': DateTime.now().toUtc().toIso8601String(),
      },
      {
        'academy_id': id,
        'user_id': idOf(coach),
        'role': 'Coach',
        'head': false,
        'accepted_at': DateTime.now().toUtc().toIso8601String(),
      },
    ]);
    return id;
  }

  Future<void> link(SupabaseClient parent, SupabaseClient child) =>
      admin.from('guardian_links').insert({
        'child_id': idOf(child),
        'parent_id': idOf(parent),
        'status': 'approved',
        'decided_at': DateTime.now().toUtc().toIso8601String(),
      });

  Future<String> slot(SupabaseClient coach, String academyId, int days) async {
    final lessons = SupabaseLessonRepository(coach);
    await lessons.addSlot(
      academyId,
      at: DateTime.now().add(Duration(days: days)),
      minutes: 60,
      priceCents: 5000,
      venue: 'Court 1',
    );
    final mine = await lessons.mySlots(academyId);
    return mine.last.id;
  }

  /// Books through the same calls the app makes.
  Future<(PaymentHold, String)> book(
    SupabaseClient payer,
    String slotId,
    String studentId, {
    int repeat = 1,
  }) async {
    final lessons = SupabaseLessonRepository(payer);
    final q = await lessons.quote(LessonKind.oneToOne, slotId, null);
    expect(q.enabled, isTrue);
    final (hold, id) = await lessons.reserve(
      LessonKind.oneToOne,
      slotId,
      at: null,
      studentId: studentId,
      key: 'lesson-${idOf(payer)}-${seq++}',
      expectedCents: q.totalCents,
    );
    final gateway = SupabasePaymentGateway(payer);
    await gateway.begin(hold.id!, (await gateway.methods()).first);
    await payer.functions.invoke(
      'stripe-local',
      body: {'action': 'succeed', 'payment_id': hold.id, 'repeat': repeat},
    );
    return (hold, id);
  }

  Future<void> runWorker() async {
    for (var i = 0; i < 40; i++) {
      final res = await HttpClient()
          .postUrl(Uri.parse('$url/functions/v1/money-worker'))
          .then((r) {
            r.headers.set('x-worker-secret', 'local-worker-secret');
            r.headers.set('content-type', 'application/json');
            r.write('{}');
            return r.close();
          });
      expect(res.statusCode, 200);
      final body = await res.transform(utf8.decoder).join();
      if (!body.contains('skipped')) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    fail('The worker lease never came free');
  }

  Future<int> held(String booking) async {
    final accounts = await admin
        .from('ledger_accounts')
        .select('id')
        .eq('kind', 'held')
        .eq('owner_id', booking);
    final ids = [for (final r in accounts) r['id']];
    if (ids.isEmpty) return 0;
    final rows = await admin
        .from('ledger_entries')
        .select('amount_minor')
        .inFilter('account_id', ids);
    return rows.fold<int>(0, (a, r) => a + (r['amount_minor'] as num).toInt());
  }

  setUpAll(() async {
    if (skip != null) return;
    admin = SupabaseClient(url!, service!);
    await admin.from('feature_flags').update({'enabled': true}).inFilter(
      'key',
      ['payments.enabled', 'lessons.checkout'],
    );
  });

  tearDownAll(() async {
    if (skip != null) return;
    await admin.from('feature_flags').update({'enabled': false}).inFilter(
      'key',
      ['payments.enabled', 'lessons.checkout'],
    );
  });

  test(
    'a parent books a one-to-one, 20 replayed webhooks, cancels in time',
    () async {
      final owner = await player('lowner');
      final coach = await player('lcoach');
      final parent = await player('lparent');
      final child = await player('lchild', birthday: '2014-02-01');
      await link(parent, child);
      final id = await academy(owner, coach);
      final s = await slot(coach, id, 3);

      final (hold, booking) = await book(parent, s, idOf(child), repeat: 20);
      final lessons = SupabaseLessonRepository(parent);
      for (var i = 0; i < 40; i++) {
        final b = await lessons.get(booking);
        if (b.step == LessonStep.paid) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      final b = await lessons.get(booking);
      expect(b.step, LessonStep.paid);
      expect(b.totalCents, 5500);
      expect(b.student, 'lchild Test');
      expect(await held(booking), -5000);
      final captures = await admin
          .from('ledger_transactions')
          .select('id')
          .eq('idempotency_key', 'capture:${hold.id}');
      expect(captures, hasLength(1));

      // A child sees their lesson, and it's not theirs to cancel.
      final kid = SupabaseLessonRepository(child);
      expect(await kid.mine(), hasLength(1));
      await expectLater(kid.cancel(booking), throwsA(isA<Object>()));

      // Over the real API, as the parent, with commit-time checks running.
      expect(await lessons.cancel(booking), 5000);
      await runWorker();
      expect(await held(booking), 0);
      expect((await lessons.get(booking)).step, LessonStep.cancelled);
      expect((await lessons.get(booking)).refundedCents, 5000);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a lesson can\'t be marked before it starts',
    () async {
      final owner = await player('rowner');
      final coach = await player('rcoach');
      final adult = await player('radult');
      final id = await academy(owner, coach);
      final s = await slot(coach, id, 3);
      final (_, booking) = await book(adult, s, idOf(adult));
      final lessons = SupabaseLessonRepository(adult);
      for (var i = 0; i < 40; i++) {
        if ((await lessons.get(booking)).step == LessonStep.paid) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      await expectLater(
        SupabaseLessonRepository(coach).markAttendance(booking, present: true),
        throwsA(isA<Object>()),
      );
      expect(
        (await SupabaseLessonRepository(owner).academyLessons(id)),
        hasLength(1),
      );
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test(
    'verification files: only your folder, and only staff read them',
    () async {
      final owner = await player('vowner');
      final other = await player('vother');
      final repo = SupabaseCoachRepository(owner);
      final bytes = Uint8List.fromList(List.filled(64, 7));
      final path = await repo.uploadDocument(bytes, 'licence');
      expect(path, '${idOf(owner)}/licence.jpg');
      // A second photo replaces the first, so nothing is left behind.
      await repo.uploadDocument(bytes, 'licence');

      await expectLater(
        other.storage
            .from('verification-docs')
            .uploadBinary('${idOf(owner)}/mine.jpg', bytes),
        throwsA(isA<Object>()),
      );
      await expectLater(
        other.storage.from('verification-docs').download(path),
        throwsA(isA<Object>()),
      );
      expect(
        await owner.storage.from('verification-docs').list(path: idOf(owner)),
        hasLength(1),
      );
      await expectLater(
        owner.storage
            .from('verification-docs')
            .uploadBinary(
              '${idOf(owner)}/anything.jpg',
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            ),
        throwsA(isA<Object>()),
      );

      await repo.submitLicence(
        number: 'NROC-77',
        expires: DateTime.now().add(const Duration(days: 100)),
        path: path,
      );
      expect((await repo.myLicence()).status, 'submitted');
      await expectLater(
        SupabaseCoachRepository(other).submitLicence(
          number: 'NROC-78',
          expires: DateTime.now().add(const Duration(days: 100)),
          path: path,
        ),
        throwsA(isA<Object>()),
      );
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test(
    'an assessment and a chart, and who can read them',
    () async {
      final owner = await player('aowner');
      final coach = await player('acoach');
      final parent = await player('aparent');
      final child = await player('achild', birthday: '2014-02-01');
      await link(parent, child);
      final id = await academy(owner, coach);
      final cls = await admin
          .from('academy_classes')
          .insert({
            'academy_id': id,
            'name': 'Level 1',
            'weekdays': [1, 2, 3, 4, 5, 6, 7],
            'hour': 10,
            'capacity': 4,
          })
          .select('id')
          .single();
      final student = await admin
          .from('academy_students')
          .insert({
            'academy_id': id,
            'class_id': cls['id'],
            'parent_id': idOf(parent),
            'player_id': idOf(child),
            'name': 'achild Test',
          })
          .select('id')
          .single();

      await SupabaseAssessmentRepository(owner).saveTemplate(
        id,
        name: 'Term skills',
        scaleMax: 5,
        criteria: ['Footwork', 'Serve'],
      );
      final writing = SupabaseAssessmentRepository(coach);
      final t = (await writing.templates(id)).single;
      final today = DateTime.now();
      await writing.save(
        studentId: student['id'] as String,
        templateId: t.id,
        on: today.subtract(const Duration(days: 30)),
        level: 2,
        note: 'A strong start',
        scores: {t.criteria[0].$1: 2, t.criteria[1].$1: 3},
      );
      await writing.save(
        studentId: student['id'] as String,
        templateId: t.id,
        on: today,
        note: '',
        scores: {t.criteria[0].$1: 4, t.criteria[1].$1: 3},
      );

      final seen = await SupabaseAssessmentRepository(parent).list(idOf(child));
      expect(seen, hasLength(2));
      expect(scoreLines(seen).first.points.map((p) => p.$2), [2, 4]);
      expect(
        await SupabaseAssessmentRepository(child).list(idOf(child)),
        hasLength(2),
      );
      expect(
        await SupabaseAssessmentRepository(owner).list(idOf(child)),
        isEmpty,
      );
      final direct = await owner.from('assessments').select('id');
      expect(direct, isEmpty);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test(
    'a referral gives a link and records only that it happened',
    () async {
      final adult = await player('sadult');
      final teen = await player('steen', birthday: '2011-02-01');
      final p = await admin
          .from('service_partners')
          .insert({
            'name': 'Rally Physio ${seq++}',
            'booking_url': 'https://physio.example/book',
            'ref_code': 'OLYMPUS',
            'active': true,
          })
          .select('id')
          .single();
      final repo = SupabaseServicesRepository(adult);
      expect((await repo.partners()).map((x) => x.id), contains(p['id']));
      expect(
        await repo.refer(p['id'] as String),
        'https://physio.example/book?ref=OLYMPUS',
      );
      await expectLater(
        SupabaseServicesRepository(teen).refer(p['id'] as String),
        throwsA(isA<Object>()),
      );
      final rows = await admin
          .from('service_referrals')
          .select()
          .eq('user_id', idOf(adult));
      expect(rows.single.keys.toSet(), {
        'id',
        'user_id',
        'partner_id',
        'ref_code',
        'created_at',
      });
      await admin
          .from('service_partners')
          .update({'active': false})
          .eq('id', p['id'] as String);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
