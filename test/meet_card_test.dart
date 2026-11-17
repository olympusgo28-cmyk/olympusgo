// The Meet card, shared across Home and Play (owner, 15 Nov 2026).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/home/home_rows.dart';
import 'package:olympus_go/features/onboarding/domain/sport.dart';
import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:olympus_go/features/play/domain/activity.dart';
import 'package:olympus_go/features/play/presentation/play_card/play_card.dart';

Future<Activity> _meet() async {
  final list = await DemoPlayRepository().upcoming(kind: ActivityKind.meet);
  return list.first.copyWith(
    sports: [Sport.badminton],
    ranked: false,
    recurrence: null,
    subtitle: null,
    coverTitle: null,
    feeCents: 800,
    courtBooked: false,
    courts: null,
    spotsTaken: 3,
    capacity: 8,
    startsAt: DateTime(2026, 11, 17, 19),
    endsAt: DateTime(2026, 11, 17, 21),
    proof: const SocialProof(
      mark: 'MW',
      color: 0xFF2F3A5F,
      name: 'Mei Wong',
      text: 'is going',
    ),
  );
}

Future<void> _pump(WidgetTester tester, Activity a, {bool onHome = true}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: OgTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlayCard(activity: a, onHome: onHome),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Meet card rows', () {
    testWidgets('header: the sport icon, then "Meet · Casual"', (tester) async {
      await _pump(tester, await _meet());
      expect(find.text('Meet · Casual'), findsOneWidget);
      expect(find.text('Badminton'), findsNothing, reason: 'no sport name');
      expect(find.text('Badminton · Meet'), findsNothing);
    });

    testWidgets('a ranked meet says Ranked in the header', (tester) async {
      final a = (await _meet()).copyWith(ranked: true);
      await _pump(tester, a);
      expect(find.text('Meet · Ranked'), findsOneWidget);
    });

    testWidgets('date row: date with year, then the time range', (
      tester,
    ) async {
      await _pump(tester, await _meet());
      expect(find.text('Tue, 17 Nov 26 · 7:00 – 9:00 PM'), findsOneWidget);
    });

    testWidgets('a one-time meet says so; a recurring one gives its pattern', (
      tester,
    ) async {
      await _pump(tester, await _meet());
      expect(find.text('One-time'), findsOneWidget);

      final recurring = (await _meet()).copyWith(
        recurrence: 'Every Tue and Fri',
      );
      await _pump(tester, recurring);
      expect(find.text('Recurring · Every Tue and Fri'), findsOneWidget);
    });

    testWidgets('player row: count, skill range, price per person', (
      tester,
    ) async {
      final a = await _meet();
      await _pump(tester, a);
      expect(
        find.text('3/8 players · ${a.bands} · S\$8.00 / person'),
        findsOneWidget,
      );
    });

    testWidgets('a free meet says Free', (tester) async {
      final a = (await _meet()).copyWith(feeCents: 0);
      await _pump(tester, a);
      expect(find.textContaining('· Free'), findsOneWidget);
    });

    testWidgets('court row: booked, with the number of courts', (tester) async {
      final a = (await _meet()).copyWith(courtBooked: true, courts: 2);
      await _pump(tester, a);
      expect(find.text('Court booked · 2 courts'), findsOneWidget);
    });

    testWidgets('court row: one court has no "s"', (tester) async {
      final a = (await _meet()).copyWith(courtBooked: true, courts: 1);
      await _pump(tester, a);
      expect(find.text('Court booked · 1 court'), findsOneWidget);
    });

    testWidgets('court row: booked with no count says only Court booked', (
      tester,
    ) async {
      final a = (await _meet()).copyWith(courtBooked: true);
      await _pump(tester, a);
      expect(find.text('Court booked'), findsOneWidget);
    });

    testWidgets('no court row when the court is not booked', (tester) async {
      final a = (await _meet()).copyWith(courts: 2);
      await _pump(tester, a);
      expect(find.textContaining('Court'), findsNothing);
      expect(find.textContaining('courts'), findsNothing);
    });

    testWidgets('court row sits between the player and friend rows', (
      tester,
    ) async {
      final a = (await _meet()).copyWith(courtBooked: true, courts: 2);
      await _pump(tester, a);
      final players = tester.getTopLeft(find.textContaining('players')).dy;
      final court = tester.getTopLeft(find.text('Court booked · 2 courts')).dy;
      final friend = tester.getTopLeft(find.text('Mei Wong joined')).dy;
      expect(players < court && court < friend, isTrue);
    });

    testWidgets('friend row: the friend and "joined"', (tester) async {
      await _pump(tester, await _meet());
      expect(find.text('Mei Wong joined'), findsOneWidget);
      expect(find.text('Mei Wong is going'), findsNothing);
    });

    testWidgets('several friends: "and N friends joined"', (tester) async {
      final a = (await _meet()).copyWith(
        proof: const SocialProof(
          mark: 'MW',
          color: 0xFF2F3A5F,
          name: 'Mei Wong',
          text: 'and 2 friends are going',
        ),
      );
      await _pump(tester, a);
      expect(find.text('Mei Wong and 2 friends joined'), findsOneWidget);
    });
  });

  group('Meets row', () {
    testWidgets('every Meet card in the row has the tallest card\'s height', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: OgTheme.light(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: ActivityShelf(
                  kind: ActivityKind.meet,
                  title: 'Meets',
                  home: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cards = find.byType(PlayCard);
      final heights = [
        for (var i = 0; i < cards.evaluate().length; i++)
          tester.getSize(cards.at(i)).height,
      ];
      expect(heights.length, greaterThan(1));
      expect(heights.toSet().length, 1, reason: 'heights: $heights');
    });
  });
}
