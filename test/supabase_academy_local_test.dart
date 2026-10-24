// Runs the real academy repository against a local Supabase stack (never
// the hosted project). Skipped unless LOCAL_SUPABASE_URL and
// LOCAL_SUPABASE_KEY point at `supabase start` running locally.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/academy/data/academy_repository.dart';
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

  Future<(String, String, SupabaseAcademyRepository)> player(
    String name,
  ) async {
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
    final res = await client.auth.signUp(
      email: email,
      password: 'test-password-123',
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

      final id = await head.createAcademy(
        AcademyDraft(
          name: 'Smash Academy ${DateTime.now().millisecond}',
          blurb: 'Kids classes',
          venues: const ['Our Tampines Hub, Tampines'],
          sport: Sport.badminton,
          documents: const {'biz'},
          coachEmails: [coachEmail, 'nobody@test.local'],
        ),
      );
      var a = await head.academy(id);
      expect(a.myRole, AcademyRole.headCoach);
      expect(a.area, 'Tampines');
      expect(a.verification, 'submitted');
      expect(a.coaches.map((k) => k.name), ['head Test', 'coach Test']);
      expect(a.invitedCoaches, ['nobody@test.local']);
      expect((await coach.academy(id)).myRole, AcademyRole.coach);

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
        student: 'Ethan Ng',
        age: 10,
        note: 'Played at school',
      );
      await expectLater(
        parent.requestEnrol(
          academyId: id,
          classId: classId,
          student: 'Ethan Ng',
        ),
        throwsA(isA<Object>()),
      );
      await expectLater(stranger.requests(id), throwsA(isA<Object>()));
      final reqs = await head.requests(id);
      expect(reqs.single.student, 'Ethan Ng');
      expect(reqs.single.parent, 'parent Test');
      await head.decide(reqs.single.id, RequestState.accepted);
      expect((await head.academy(id)).pendingRequests, 0);

      final kids = await parent.myStudents();
      final ethan = kids.single;
      expect(ethan.name, 'Ethan Ng');
      expect(ethan.age, 10);
      expect(ethan.skills, hasLength(12));
      expect((await parent.academy(id)).myRole, AcademyRole.parent);
      await expectLater(stranger.student(ethan.id), throwsA(isA<Object>()));

      final slots = await parent.trialSlots(id);
      expect(slots, isNotEmpty);
      await parent.bookTrial(id, slots.first, 'Mia Ng');
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
        coach.setFilmingConsent(ethan.id, own: true, train: false),
        throwsA(isA<Object>()),
      );
      await parent.setFilmingConsent(ethan.id, own: true, train: false);
      expect((await parent.student(ethan.id)).filmingConsent, isTrue);

      // Settings.
      await head.updateAcademy(id, billing: Billing.term, makeups: 3);
      a = await head.academy(id);
      expect(a.billing, Billing.term);
      expect(a.makeupsPerMonth, 3);
      await head.setCoach(id, '@$extraName', add: true);
      a = await head.academy(id);
      expect(a.coaches, hasLength(3));
      await head.setCoach(id, a.coaches.last.id, add: false);
      expect((await head.academy(id)).coaches, hasLength(2));
      await expectLater(
        coach.setCoach(id, extraName, add: true),
        throwsA(isA<Object>()),
      );
      expect(await coach.coverCoaches(classId), hasLength(1));

      // Classes fill up.
      await parent.requestEnrol(
        academyId: id,
        classId: classId,
        student: 'Zoe Ng',
      );
      await parent.requestEnrol(
        academyId: id,
        classId: classId,
        student: 'Max Ng',
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
