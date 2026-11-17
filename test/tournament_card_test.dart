// The Tournament card (owner, 15 Nov 2026): no cover title, no header row,
// no outline.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/theme/og_colors.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/og_icon.dart';
import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:olympus_go/features/play/domain/activity.dart';
import 'package:olympus_go/features/play/presentation/play_card/play_card.dart';

Future<Activity> _tournament() async {
  final list = await DemoPlayRepository().upcoming(
    kind: ActivityKind.tournament,
  );
  return list.first.copyWith(
    title: 'Smashers Ladder Night',
    coverTitle: 'Banner words',
    tier: 'Regional',
    ranked: true,
  );
}

Future<void> _pump(WidgetTester tester, Activity a) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: OgTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(child: PlayCard(activity: a)),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Tournament card', () {
    testWidgets('the banner has no cover title', (tester) async {
      await _pump(tester, await _tournament());
      expect(find.text('Banner words'), findsNothing);
      // The name appears once, in the title row, not on the banner as well.
      expect(find.text('Smashers Ladder Night'), findsOneWidget);
    });

    testWidgets('the banner is the card\'s width with four rounded corners', (
      tester,
    ) async {
      await _pump(tester, await _tournament());
      final banner = find.byType(ClipRRect).first;
      final card = tester.getRect(find.byType(PlayCard));
      final r = tester.getRect(banner);
      expect(r.left, card.left);
      expect(r.right, card.right);
      expect(
        tester.widget<ClipRRect>(banner).borderRadius,
        BorderRadius.circular(20),
      );
    });

    testWidgets('the heart is always white; only the fill changes tone', (
      tester,
    ) async {
      Color? heartColor() => tester
          .widgetList<OgIcon>(find.byType(OgIcon))
          .where((i) => i.markup == OgIcons.heart)
          .first
          .color;
      BoxDecoration button() => tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.shape == BoxShape.circle);

      final dark = (await _tournament()).copyWith(coverColor: 0xFF2F3A5F);
      await _pump(tester, dark);
      expect(heartColor(), Colors.white);
      expect(button().color, Colors.white.withValues(alpha: 0.22));
      expect(button().border, isNull, reason: 'edge is the fill');

      final light = (await _tournament()).copyWith(coverColor: 0xFFF9E7B0);
      await _pump(tester, light);
      expect(heartColor(), Colors.white, reason: 'white on a light banner too');
      expect(button().color, OgColors.ink.withValues(alpha: 0.10));
      expect(button().border, isNull, reason: 'edge is the fill');
    });

    testWidgets('the heart sits where it does on the Event banner', (
      tester,
    ) async {
      final a = await _tournament();
      await _pump(tester, a);
      final banner = tester.getRect(find.byType(ClipRRect).first);
      final heart = tester.getRect(find.bySemanticsLabel('Save ${a.title}'));
      // The 44-point tap area is 10 points from the banner's top and right.
      expect(heart.top - banner.top, 10);
      expect(banner.right - heart.right, 10);
    });

    testWidgets('there is no header row', (tester) async {
      await _pump(tester, await _tournament());
      expect(find.text('Tournament'), findsNothing);
      expect(find.text('Regional'), findsNothing, reason: 'no tier chip');
      expect(find.text('Ranked'), findsNothing);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('the card has no outline', (tester) async {
      await _pump(tester, await _tournament());
      final card = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(PlayCard),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((card.decoration! as BoxDecoration).border, isNull);
    });

    testWidgets('the banner keeps the save heart and the rows follow it', (
      tester,
    ) async {
      final a = await _tournament();
      await _pump(tester, a);
      final heart = find.bySemanticsLabel('Save ${a.title}');
      expect(heart, findsOneWidget);
      final ys = [
        tester.getTopLeft(heart).dy,
        tester.getTopLeft(find.text(a.title)).dy,
        tester.getTopLeft(find.text(a.venue.name)).dy,
        tester.getTopLeft(find.textContaining('going')).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
    });
  });
}
