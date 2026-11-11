// My schedule's Lessons tab (owner, 9 Nov 2026): lessons left Settings for
// the schedule, beside Joined and Hosting.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/academy/application/academy_providers.dart';
import 'package:olympus_go/features/academy/domain/lesson_models.dart';
import 'package:olympus_go/features/academy/presentation/lesson_screens.dart';
import 'package:olympus_go/features/play/application/play_providers.dart';
import 'package:olympus_go/features/play/presentation/meet_action_screens.dart';

LessonBooking _lesson(
  String id,
  DateTime at, {
  String title = 'One-to-one · Coach Ravi',
  LessonStep step = LessonStep.paid,
}) => LessonBooking(
  id: id,
  kind: LessonKind.oneToOne,
  title: title,
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
  canPay: true,
  canTeach: false,
);

Future<void> _pump(
  WidgetTester tester, {
  List<LessonBooking> lessons = const [],
  bool openOnLessons = false,
}) async {
  tester.view.physicalSize = const Size(820, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myScheduleProvider.overrideWith((_) async => const []),
        hostingProvider.overrideWith((_) async => const []),
        myLessonsProvider.overrideWith((_) async => lessons),
      ],
      child: MaterialApp(
        theme: OgTheme.light(),
        home: ScheduleScreen(lessons: openOnLessons),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final soon = DateTime.now().add(const Duration(days: 3));

  testWidgets('three tabs, each with its count', (tester) async {
    await _pump(tester, lessons: [_lesson('l1', soon), _lesson('l2', soon)]);
    expect(find.text('Joined · 0'), findsOneWidget);
    expect(find.text('Hosting · 0'), findsOneWidget);
    expect(find.text('Lessons · 2'), findsOneWidget);
  });

  testWidgets('the Lessons tab lists lesson bookings', (tester) async {
    await _pump(tester, lessons: [_lesson('l1', soon)]);
    expect(find.byType(MyLessonsList), findsNothing);
    await tester.tap(find.text('Lessons · 1'));
    await tester.pumpAndSettle();
    expect(find.byType(MyLessonsList), findsOneWidget);
    expect(find.text('One-to-one · Coach Ravi'), findsOneWidget);
  });

  testWidgets('only lessons still to come count, like Joined and Hosting', (
    tester,
  ) async {
    await _pump(
      tester,
      openOnLessons: true,
      lessons: [
        _lesson('l1', soon, title: 'Coming up'),
        _lesson(
          'l2',
          DateTime.now().subtract(const Duration(days: 3)),
          title: 'Last week',
        ),
        _lesson('l3', soon, title: 'Refunded', step: LessonStep.refunded),
        _lesson(
          'l4',
          soon,
          title: 'Awaiting payment',
          step: LessonStep.pending,
        ),
      ],
    );
    expect(find.text('Lessons · 2'), findsOneWidget);
    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Awaiting payment'), findsOneWidget);
    expect(find.text('Last week'), findsNothing);
    expect(find.text('Refunded'), findsNothing);
  });

  testWidgets('with only past lessons it says none are coming up', (
    tester,
  ) async {
    await _pump(
      tester,
      openOnLessons: true,
      lessons: [
        _lesson('l2', DateTime.now().subtract(const Duration(days: 3))),
      ],
    );
    expect(find.text('Lessons · 0'), findsOneWidget);
    expect(find.text('No lessons coming up.'), findsOneWidget);
  });

  testWidgets('it can open straight on Lessons, and says when there are none', (
    tester,
  ) async {
    await _pump(tester, openOnLessons: true);
    expect(find.byType(MyLessonsList), findsOneWidget);
    expect(find.textContaining('Nothing booked yet'), findsOneWidget);
  });
}
