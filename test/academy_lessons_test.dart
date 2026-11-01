import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/academy/application/academy_providers.dart';
import 'package:olympus_go/features/academy/data/assessment_repository.dart';
import 'package:olympus_go/features/academy/data/coach_repository.dart';
import 'package:olympus_go/features/academy/data/lesson_repository.dart';
import 'package:olympus_go/features/academy/domain/lesson_models.dart';
import 'package:olympus_go/features/academy/presentation/academy_screens.dart';
import 'package:olympus_go/features/academy/presentation/assessment_screens.dart';
import 'package:olympus_go/features/academy/presentation/lesson_screens.dart';
import 'package:olympus_go/features/academy/presentation/verification_screens.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/services/application/services_providers.dart';
import 'package:olympus_go/features/services/data/services_repository.dart';
import 'package:olympus_go/features/services/presentation/services_screen.dart';

/// The lesson under test, with the roles and clock each case needs.
class _Lessons extends DemoLessonRepository {
  _Lessons(this.lesson);
  LessonBooking lesson;
  final calls = <String>[];

  @override
  Future<LessonBooking> get(String id) async => lesson;

  @override
  Future<int> cancel(String id) async {
    calls.add('cancel');
    return 0;
  }

  @override
  Future<void> markAttendance(String id, {required bool present}) async {
    calls.add('mark:$present');
  }

  @override
  Future<void> report(String id, String note) async {
    calls.add('report:$note');
  }
}

class _FailingLessons extends DemoLessonRepository {
  @override
  Future<List<LessonBooking>> mine() async =>
      throw const AuthFailure('Check your connection.');
}

class _Services extends DemoServicesRepository {
  _Services({this.none = false, this.failing = false});
  final bool none;
  final bool failing;

  @override
  Future<List<ServicePartner>> partners() async {
    if (failing) throw const AuthFailure('Nope');
    return none ? const [] : super.partners();
  }
}

LessonBooking _booking({
  required DateTime at,
  LessonStep step = LessonStep.paid,
  bool canPay = true,
  bool canTeach = false,
}) => LessonBooking(
  id: 'l1',
  kind: LessonKind.oneToOne,
  title: 'One-to-one · Coach Ravi',
  academyId: 'a1',
  academy: 'Smash Academy',
  coach: 'Coach Ravi',
  student: 'Mia Ng',
  startsAt: at,
  endsAt: at.add(const Duration(hours: 1)),
  step: step,
  totalCents: 5500,
  priceCents: 5000,
  feeCents: 500,
  freeCancelUntil: at.subtract(const Duration(hours: 24)),
  canPay: canPay,
  canTeach: canTeach,
);

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<dynamic> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp.router(
        theme: OgTheme.light(),
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => screen),
            GoRoute(
              path: '/:rest(.*)',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('lesson page', () {
    testWidgets('before the wait is over, cancelling gives the price back', (
      tester,
    ) async {
      final repo = _Lessons(
        _booking(at: DateTime.now().add(const Duration(days: 3))),
      );
      await _pump(
        tester,
        const LessonDetailScreen(id: 'l1'),
        overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
      );
      expect(find.text('Booked'), findsOneWidget);
      expect(find.text('Report a problem'), findsNothing);
      await tester.tap(find.text('Cancel lesson'));
      await tester.pumpAndSettle();
      expect(find.textContaining('S\$50.00 back'), findsOneWidget);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['cancel']);
    });

    testWidgets('inside 24 hours it says nothing comes back', (tester) async {
      await _pump(
        tester,
        const LessonDetailScreen(id: 'l1'),
        overrides: [
          lessonRepositoryProvider.overrideWithValue(
            _Lessons(
              _booking(at: DateTime.now().add(const Duration(hours: 3))),
            ),
          ),
        ],
      );
      await tester.tap(find.text('Cancel lesson'));
      await tester.pumpAndSettle();
      expect(find.textContaining('won’t get anything back'), findsOneWidget);
    });

    testWidgets('after the start the payer can report a problem', (
      tester,
    ) async {
      await _pump(
        tester,
        const LessonDetailScreen(id: 'l1'),
        overrides: [
          lessonRepositoryProvider.overrideWithValue(
            _Lessons(
              _booking(at: DateTime.now().subtract(const Duration(minutes: 5))),
            ),
          ),
        ],
      );
      expect(find.text('Report a problem'), findsOneWidget);
      expect(find.text('Cancel lesson'), findsNothing);
    });

    testWidgets('the coach marks attendance, once it has started', (
      tester,
    ) async {
      final repo = _Lessons(
        _booking(
          at: DateTime.now().subtract(const Duration(minutes: 5)),
          canPay: false,
          canTeach: true,
        ),
      );
      await _pump(
        tester,
        const LessonDetailScreen(id: 'l1'),
        overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.tap(find.text('Mia Ng came'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['mark:true']);
    });

    testWidgets('a child reading their lesson has nothing to press', (
      tester,
    ) async {
      await _pump(
        tester,
        const LessonDetailScreen(id: 'l1'),
        overrides: [
          lessonRepositoryProvider.overrideWithValue(
            _Lessons(
              _booking(
                at: DateTime.now().add(const Duration(days: 3)),
                canPay: false,
              ),
            ),
          ),
        ],
      );
      expect(find.text('Cancel lesson'), findsNothing);
      expect(find.text('Report a problem'), findsNothing);
    });

    testWidgets('a settled lesson can’t be cancelled', (tester) async {
      await _pump(
        tester,
        const LessonDetailScreen(id: 'l1'),
        overrides: [
          lessonRepositoryProvider.overrideWithValue(
            _Lessons(
              _booking(
                at: DateTime.now().add(const Duration(days: 3)),
                step: LessonStep.released,
              ),
            ),
          ),
        ],
      );
      expect(find.text('Cancel lesson'), findsNothing);
    });
  });

  group('my lessons', () {
    testWidgets('empty', (tester) async {
      await _pump(tester, const MyLessonsScreen());
      expect(find.textContaining('Nothing booked yet'), findsOneWidget);
    });

    testWidgets('a failure offers a retry', (tester) async {
      await _pump(
        tester,
        const MyLessonsScreen(),
        overrides: [
          lessonRepositoryProvider.overrideWithValue(_FailingLessons()),
        ],
      );
      expect(find.text('Check your connection.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  testWidgets('a one-to-one needs a person and a time', (tester) async {
    final repo = DemoLessonRepository();
    await repo.addSlot(
      'a-smash',
      at: DateTime(2027, 1, 5, 10),
      minutes: 60,
      priceCents: 5000,
      venue: 'Court 1',
    );
    await _pump(
      tester,
      const OneToOneScreen(academyId: 'a-smash'),
      overrides: [lessonRepositoryProvider.overrideWithValue(repo)],
    );
    expect(find.textContaining('Coach Ravi'), findsWidgets);
    expect(find.text('S\$55.00'), findsOneWidget);
  });

  group('choosing who to enrol', () {
    Widget choices(AsyncValue<List<EnrolPlayer>> players) => Scaffold(
      body: PlayerChoices(players: players, selected: null, onSelect: (_) {}),
    );

    testWidgets('yourself or a linked child, and no way to type a name', (
      tester,
    ) async {
      await _pump(
        tester,
        choices(
          const AsyncData([
            EnrolPlayer(id: 'p', name: 'Aaron Ng', self: true),
            EnrolPlayer(id: 'c', name: 'Mia Ng', age: 9),
          ]),
        ),
      );
      expect(find.text('Myself'), findsOneWidget);
      expect(find.textContaining('age 9'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Link a child to your account'), findsOneWidget);
    });

    testWidgets('a minor is told a parent does this', (tester) async {
      await _pump(tester, choices(const AsyncData([])));
      expect(find.text('A parent needs to do this for you.'), findsOneWidget);
    });
  });

  group('verification', () {
    testWidgets('the owner has to give a photo before sending', (tester) async {
      await _pump(tester, const AcademyVerifyScreen(id: 'a1'));
      expect(find.text('Get verified'), findsOneWidget);
      expect(find.textContaining('Parents can’t find you'), findsOneWidget);
      expect(find.text('Send for review'), findsOneWidget);
    });

    testWidgets('a coach invitation asks first', (tester) async {
      await _pump(tester, const CoachInviteScreen(academyId: 'a-smash'));
      expect(find.text('Coach at Smash Academy?'), findsOneWidget);
      expect(find.text('Yes, I coach here'), findsOneWidget);
    });

    testWidgets('an invitation that has gone says so', (tester) async {
      await _pump(tester, const CoachInviteScreen(academyId: 'gone'));
      expect(find.text('This invitation has ended.'), findsOneWidget);
    });

    testWidgets('a coach page shows the verified licence', (tester) async {
      await _pump(
        tester,
        const CoachPageScreen(id: 'c1'),
        overrides: [
          coachRepositoryProvider.overrideWithValue(DemoCoachRepository()),
        ],
      );
      expect(find.text('NROC licence verified'), findsOneWidget);
      expect(find.text('Smash Academy'), findsOneWidget);
    });
  });

  group('assessments', () {
    test('scores become a line per thing assessed, oldest first', () async {
      final all = await DemoAssessmentRepository().list('p');
      final lines = scoreLines(all);
      expect(lines.map((l) => l.label), ['Footwork', 'Serve']);
      expect(lines.first.points.map((p) => p.$2), [2, 4]);
      expect(lines.first.max, 5);
    });

    testWidgets('the chart can be read without seeing it', (tester) async {
      await _pump(tester, const AssessmentHistoryScreen(playerId: 'p'));
      expect(find.text('Term skills'), findsOneWidget);
      expect(find.text('Started at 2, now 4, out of 5'), findsOneWidget);
      expect(find.byType(ScoreSparkline), findsNWidgets(2));
      expect(
        find.text('An academy level is separate from your Play rating.'),
        findsOneWidget,
      );
    });

    testWidgets('only the assigning coach gets to correct', (tester) async {
      await _pump(
        tester,
        const AssessmentHistoryScreen(playerId: 'p', studentId: 's'),
      );
      expect(find.text('Correct this'), findsOneWidget);
    });

    testWidgets('a parent has nothing to correct', (tester) async {
      await _pump(tester, const AssessmentHistoryScreen(playerId: 'p'));
      expect(find.text('Correct this'), findsNothing);
    });

    testWidgets('templates list what they score', (tester) async {
      await _pump(tester, const AssessmentTemplatesScreen(academyId: 'a'));
      expect(find.text('Term skills'), findsOneWidget);
      expect(find.textContaining('Footwork, Serve'), findsOneWidget);
    });
  });

  group('services', () {
    testWidgets('partners, and leaving says where you’re going', (
      tester,
    ) async {
      await _pump(tester, const ServicesScreen());
      expect(find.text('Rally Physio'), findsOneWidget);
      expect(find.textContaining('doesn’t see what'), findsOneWidget);
      final button = find.text('Request a booking');
      expect(
        tester
            .getSize(
              find
                  .ancestor(of: button, matching: find.byType(GestureDetector))
                  .first,
            )
            .height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Leave OlympusGO?'), findsOneWidget);
    });

    testWidgets('no partners yet', (tester) async {
      await _pump(
        tester,
        const ServicesScreen(),
        overrides: [
          servicesRepositoryProvider.overrideWithValue(_Services(none: true)),
        ],
      );
      expect(find.text('None are open yet.'), findsOneWidget);
    });

    testWidgets('a failure offers a retry', (tester) async {
      await _pump(
        tester,
        const ServicesScreen(),
        overrides: [
          servicesRepositoryProvider.overrideWithValue(
            _Services(failing: true),
          ),
        ],
      );
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
