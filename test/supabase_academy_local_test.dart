// Runs the real academy repository against a local Supabase stack (never
// the hosted project). Skipped unless LOCAL_SUPABASE_URL and
// LOCAL_SUPABASE_KEY point at `supabase start` running locally.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/local_accounts.dart';

import 'package:olympus_go/features/academy/data/academy_repository.dart';
import 'package:olympus_go/features/academy/data/coach_repository.dart';
import 'package:olympus_go/features/academy/domain/academy_models.dart';
import 'package:olympus_go/features/academy/domain/academy_more.dart';
import 'package:olympus_go/features/onboarding/domain/sport.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final skip = url == null || key == null || !url.contains('127.0.0.1')
      ? 'Needs a local Supabase stack'
      : null;

  final service = Platform.environment['LOCAL_SUPABASE_SERVICE_KEY'];
  SupabaseClient admin() => SupabaseClient(
    url!,
    service!,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final clients = <String, SupabaseClient>{};

  Future<(String, String, SupabaseAcademyRepository)> player(
    String name, {
    String birthday = '1990-01-01',
  }) async {
    final client = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final email = '$name.$stamp@test.local';
    final res = await signUpLocal(
      client,
      email: email,
      password: 'test-password-123',
    );
    await client.rpc(
      'set_birthday',
      params: {'p_birthday': birthday, 'p_country': 'SG'},
    );
    final username = '${name}_${stamp % 100000}';
    await client
        .from('profiles')
        .update({
          'username': username,
          'full_name': '$name Test',
          'onboarding_completed': true,
        })
        .eq('id', res.user!.id);
    clients[name] = client;
    return (email, username, SupabaseAcademyRepository(client));
  }

  test(
    'an academy from creation to a coach note, against local Supabase',
    () async {
      final (_, _, head) = await player('head');
      final (coachEmail, _, coach) = await player('coach');
      final (_, extraName, _) = await player('extra');
      final (_, _, parent) = await player('parent');
      final (_, _, stranger) = await player('stranger');
      final (_, _, _) = await player('ethan', birthday: '2016-03-01');
      final (_, _, _) = await player('zoe', birthday: '2016-04-01');
      final (_, _, _) = await player('max', birthday: '2016-05-01');
      String idOf(String name) => clients[name]!.auth.currentUser!.id;
      final staff = admin();

      // Only a linked child can be enrolled, so their age is real.
      for (final kid in ['ethan', 'zoe', 'max']) {
        await staff.from('guardian_links').insert({
          'child_id': idOf(kid),
          'parent_id': idOf('parent'),
          'status': 'approved',
          'decided_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      final id = await head.createAcademy(
        AcademyDraft(
          name: 'Smash Academy ${DateTime.now().millisecond}',
          blurb: 'Kids classes',
          venues: const ['Our Tampines Hub, Tampines'],
          sport: Sport.badminton,
          coachEmails: [coachEmail, 'nobody@test.local'],
        ),
      );
      var a = await head.academy(id);
      expect(a.myRole, AcademyRole.headCoach);
      expect(a.area, 'Tampines');
      expect(a.verification, 'none');
      expect(a.coaches.map((k) => k.name), ['head Test']);
      expect(a.invitedCoaches, hasLength(2));

      // An unverified academy isn't listed, and a coach has to agree.
      await expectLater(parent.academy(id), throwsA(isA<Object>()));
      final coaching = SupabaseCoachRepository(clients['coach']!);
      expect((await coaching.coachInvites()).single.$1, id);
      await coaching.answerInvite(id, accept: true);
      expect((await coach.academy(id)).myRole, AcademyRole.coach);

      // Staff's checks, done here with the service key.
      final expires = DateTime.now().add(const Duration(days: 300));
      for (final who in ['head', 'coach']) {
        await staff.from('coach_licences').insert({
          'user_id': idOf(who),
          'nroc_number': 'NROC-$who',
          'expires_on': expires.toIso8601String().substring(0, 10),
          'status': 'verified',
          'verified_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
      await staff
          .from('academies')
          .update({'verification': 'verified', 'uen': '201912345A'})
          .eq('id', id);

      // Only the head coach adds classes.
      final headId = a.coaches.first.id;
      final today = DateTime.now().weekday;
      final cls = AcademyClass(
        id: '',
        academyId: id,
        name: 'Juniors Level 1',
        level: 1,
        weekdays: [today, today % 7 + 1],
        hour: 9,
        feeCents: 16000,
        capacity: 2,
        coach: '',
        coachId: headId,
      );
      await expectLater(coach.saveClass(id, cls), throwsA(isA<Object>()));
      final classId = await head.saveClass(id, cls);
      a = await parent.academy(id);
      expect(a.myRole, AcademyRole.none);
      final x = a.classes.single;
      expect(x.coach, 'head Test');
      expect(x.week, 1);
      expect(x.lesson, 'Grip, ready position and split-step');
      expect(x.focusSkill, 'fw1');

      // A parent asks to enrol a child; the head coach accepts.
      await parent.requestEnrol(
        academyId: id,
        classId: classId,
        playerId: idOf('ethan'),
        note: 'Played at school',
      );
      await expectLater(
        parent.requestEnrol(
          academyId: id,
          classId: classId,
          playerId: idOf('ethan'),
        ),
        throwsA(isA<Object>()),
      );
      await expectLater(
        stranger.requestEnrol(
          academyId: id,
          classId: classId,
          playerId: idOf('ethan'),
        ),
        throwsA(isA<Object>()),
      );
      expect(
        (await parent.myPlayers()).map((p) => p.name),
        containsAll(['parent Test', 'ethan Test']),
      );
      await expectLater(stranger.requests(id), throwsA(isA<Object>()));
      final reqs = await head.requests(id);
      expect(reqs.single.student, 'ethan Test');
      expect(reqs.single.parent, 'parent Test');
      await head.decide(reqs.single.id, RequestState.accepted);
      expect((await head.academy(id)).pendingRequests, 0);

      final kids = await parent.myStudents();
      final ethan = kids.single;
      expect(ethan.name, 'ethan Test');
      expect(ethan.age, inInclusiveRange(9, 11));
      expect(ethan.playerId, idOf('ethan'));
      expect(ethan.skills, hasLength(12));
      expect((await parent.academy(id)).myRole, AcademyRole.parent);
      await expectLater(stranger.student(ethan.id), throwsA(isA<Object>()));

      final slots = await parent.trialSlots(id);
      expect(slots, isNotEmpty);
      await parent.bookTrial(id, slots.first, idOf('zoe'));
      expect((await head.requests(id)).first.note, startsWith('Trial on'));

      // The coach runs today's class.
      final roster = await coach.roster(classId);
      expect(roster.single.id, ethan.id);
      await coach.saveSession(
        SessionRecord(
          classId: classId,
          focusSkill: {ethan.id: SkillStatus.gotIt},
          note: 'Great split-step today.',
        ),
      );
      var s = await parent.student(ethan.id);
      expect(s.skills.first.status, SkillStatus.gotIt);
      expect(s.skills.first.week, 'Week 1');
      expect(s.notes.single.text, 'Great split-step today.');
      expect(s.held, 1);
      expect(s.attendancePct, 100);
      expect((await parent.lessons(ethan.id)).first.attended, isTrue);
      expect((await head.academy(id)).classes.single.week, 2);
      expect((await parent.attendance(ethan.id)).single.state, 'Present');

      // A change to the class, and a make-up credit for missing it.
      expect(
        await head.changeClass(
          classId,
          mode: 'move',
          notice: 'Saturday is now 10:30 AM.',
        ),
        1,
      );
      expect(
        (await parent.student(ethan.id)).notice,
        'Saturday is now 10:30 AM.',
      );
      expect(await head.alerts(id), isNotEmpty);
      await parent.answerNotice(ethan.id, coming: false);
      s = await parent.student(ethan.id);
      expect(s.makeupCredits, 1);
      final makeups = await parent.makeupSlots(ethan.id);
      expect(makeups, isNotEmpty);
      await parent.bookMakeup(ethan.id, makeups.first);
      expect((await parent.student(ethan.id)).makeupCredits, 0);
      await expectLater(
        parent.bookMakeup(ethan.id, makeups.first),
        throwsA(isA<Object>()),
      );

      // Curriculum, invites, notes and consent.
      final weeks = await coach.curriculum(id, 1);
      expect(weeks, hasLength(10));
      await coach.saveLessonPlan(
        id,
        1,
        5,
        drills: const [Drill('Net kill feed', 15)],
      );
      final edited = (await coach.curriculum(id, 1))[4];
      expect(edited.drills.single.name, 'Net kill feed');
      expect(edited.version, 'Edited by coach Test');
      expect(await stranger.curriculum(id, 1), isEmpty);

      await coach.inviteParent(classId, '9123 4567');
      await expectLater(
        coach.inviteParent(classId, '12'),
        throwsA(isA<Object>()),
      );
      expect(
        (await coach.pendingInvites(classId)).single.$1,
        contains('9123 4567'),
      );

      await coach.sendParentNote(
        ethan.id,
        skills: {'st1': SkillStatus.practising},
        note: 'Work on the forehand clear.',
      );
      s = await parent.student(ethan.id);
      expect(s.skills[3].status, SkillStatus.practising);
      expect(s.notes.first.text, 'Work on the forehand clear.');

      await expectLater(
        coach.setFilmingConsent(ethan.id, own: true),
        throwsA(isA<Object>()),
      );
      await parent.setFilmingConsent(ethan.id, own: true);
      expect((await parent.student(ethan.id)).filmingConsent, isTrue);

      // Settings.
      await head.updateAcademy(id, billing: Billing.term, makeups: 3);
      a = await head.academy(id);
      expect(a.billing, Billing.term);
      expect(a.makeupsPerMonth, 3);
      await head.setCoach(id, '@$extraName', add: true);
      a = await head.academy(id);
      expect(a.coaches, hasLength(2));
      await head.setCoach(id, idOf('extra'), add: false);
      expect(
        await SupabaseCoachRepository(clients['extra']!).coachInvites(),
        isEmpty,
      );
      await expectLater(
        coach.setCoach(id, extraName, add: true),
        throwsA(isA<Object>()),
      );
      expect(await coach.coverCoaches(classId), hasLength(1));

      // Classes fill up.
      await parent.requestEnrol(
        academyId: id,
        classId: classId,
        playerId: idOf('zoe'),
      );
      await parent.requestEnrol(
        academyId: id,
        classId: classId,
        playerId: idOf('max'),
      );
      final pending = (await head.requests(id))
          .where(
            (r) =>
                r.state == RequestState.pending && !r.note.startsWith('Trial'),
          )
          .toList();
      await head.decide(pending[0].id, RequestState.accepted);
      await expectLater(
        head.decide(pending[1].id, RequestState.accepted),
        throwsA(isA<Object>()),
      );

      await head.closeAcademy(id);
      expect((await parent.academies()).map((a) => a.id), isNot(contains(id)));
      expect(await parent.myStudents(), isEmpty);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
