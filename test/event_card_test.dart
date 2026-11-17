// The Event card (owner, 15 Nov 2026): the same rows as the Tournament card,
// with the going count and price on the people row.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/format.dart';
import 'package:olympus_go/core/theme/og_colors.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/theme/og_type.dart';
import 'package:olympus_go/core/widgets/og_icon.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';
import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:olympus_go/features/play/domain/activity.dart';
import 'package:olympus_go/features/play/presentation/play_card/play_card.dart';

Future<Activity> _event() async {
  final list = await DemoPlayRepository().upcoming(kind: ActivityKind.event);
  return list.first.copyWith(
    title: 'Tampines Open, Finals Day',
    coverTitle: 'Banner words',
    subtitle: null,
    recurrence: null,
    registrationClosesAt: null,
    live: false,
    online: false,
    sponsored: false,
    feeCents: 0,
    audience: 'All ages',
    spotsTaken: 1284,
    // Far ahead, so the dates never read as today.
    startsAt: DateTime(2031, 3, 4, 9),
    endsAt: DateTime(2031, 3, 4, 18),
    proof: const SocialProof(
      mark: 'PR',
      color: 0xFF3E6B8A,
      name: 'Priya Raman',
      text: 'and 3 friends are going',
    ),
  );
}

Future<void> _pump(WidgetTester tester, Activity a, {bool onHome = true}) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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

TextStyle _style(WidgetTester tester, Finder f) =>
    tester.widget<Text>(f).style!;

Rect _iconRect(WidgetTester tester, String markup) => tester.getRect(
  find.byWidgetPredicate((w) => w is OgIcon && w.markup == markup),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Banner', () {
    testWidgets('full card width, 132 tall, four corners rounded to 20', (
      tester,
    ) async {
      await _pump(tester, await _event());
      final card = tester.getRect(find.byType(PlayCard));
      final banner = find.byType(ClipRRect).first;
      final r = tester.getRect(banner);
      expect(r.left, card.left);
      expect(r.right, card.right);
      expect(r.top, card.top);
      expect(r.height, 132);
      expect(
        tester.widget<ClipRRect>(banner).borderRadius,
        BorderRadius.circular(20),
      );
    });

    testWidgets('has no cover title and no Sponsored pill', (tester) async {
      final a = (await _event()).copyWith(sponsored: true);
      await _pump(tester, a);
      expect(find.text('Banner words'), findsNothing);
      expect(find.text('Sponsored'), findsNothing);
    });

    testWidgets('the card has no outline', (tester) async {
      await _pump(tester, await _event());
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

    testWidgets('save button: 10 from the top and right, 44 tap area', (
      tester,
    ) async {
      final a = await _event();
      await _pump(tester, a);
      final banner = tester.getRect(find.byType(ClipRRect).first);
      final heart = tester.getRect(find.bySemanticsLabel('Save ${a.title}'));
      expect(heart.size, const Size(44, 44));
      expect(heart.top - banner.top, 10);
      expect(banner.right - heart.right, 10);
    });

    testWidgets('the heart is white and 20; only the fill changes tone', (
      tester,
    ) async {
      BoxDecoration button() => tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.shape == BoxShape.circle);
      OgIcon heart() => tester
          .widgetList<OgIcon>(find.byType(OgIcon))
          .firstWhere((i) => i.markup == OgIcons.heart);

      final dark = (await _event()).copyWith(coverColor: 0xFF2F3A5F);
      await _pump(tester, dark);
      expect(heart().color, Colors.white);
      expect(heart().size, 20);
      expect(button().color, Colors.white.withValues(alpha: 0.22));
      expect(button().border, isNull);

      final light = (await _event()).copyWith(coverColor: 0xFFF9E7B0);
      await _pump(tester, light);
      expect(heart().color, Colors.white);
      expect(button().color, OgColors.ink.withValues(alpha: 0.10));
    });
  });

  group('Rows', () {
    testWidgets('title: Inter 17 Medium, one line', (tester) async {
      final a = await _event();
      await _pump(tester, a);
      final title = _style(tester, find.text(a.title));
      expect(title.fontSize, 17);
      expect(title.fontWeight, FontWeight.w500);
      expect(title.fontFamily, contains('Inter'));
      expect(tester.widget<Text>(find.text(a.title)).maxLines, 1);
    });

    testWidgets('date row: start and end time, 15 regular, with an icon', (
      tester,
    ) async {
      final a = await _event();
      await _pump(tester, a);
      final line = Fmt.dayTimeRange(a.startsAt, a.endsAt);
      expect(find.text(line), findsOneWidget);
      final style = _style(tester, find.text(line));
      expect(style.fontSize, 15);
      expect(style.fontWeight, FontWeight.w400);
      final icon = _iconRect(tester, OgIcons.calendarBox);
      expect(icon.size, const Size(18, 18));
      expect(tester.getRect(find.text(line)).left - icon.right, 10);
    });

    testWidgets('a date range when it runs several days', (tester) async {
      final a = (await _event()).copyWith(endsAt: DateTime(2031, 3, 6, 18));
      await _pump(tester, a);
      expect(find.text(Fmt.dayRange(a.startsAt, a.endsAt)), findsOneWidget);
    });

    testWidgets('second line: note, else repeat pattern, else registration', (
      tester,
    ) async {
      final a = await _event();
      final closes = DateTime(2031, 3, 1, 12);
      await _pump(
        tester,
        a.copyWith(
          subtitle: 'Doors open at 8',
          recurrence: 'Every Tue',
          registrationClosesAt: closes,
        ),
      );
      expect(find.text('Doors open at 8'), findsOneWidget);
      expect(find.text('Every Tue'), findsNothing);

      await _pump(
        tester,
        a.copyWith(recurrence: 'Every Tue', registrationClosesAt: closes),
      );
      expect(find.text('Every Tue'), findsOneWidget);

      await _pump(tester, a.copyWith(registrationClosesAt: closes));
      final reg = find.text('Registration closes ${Fmt.day(closes)}');
      expect(reg, findsOneWidget);
      final style = _style(tester, reg);
      expect(style.fontSize, 13);
      expect(style.fontWeight, FontWeight.w400);
    });

    testWidgets('venue row: name 15 regular, address 13 muted, with a pin', (
      tester,
    ) async {
      final a = await _event();
      await _pump(tester, a);
      final name = _style(tester, find.text(a.venue.name));
      expect(name.fontSize, 15);
      expect(name.fontWeight, FontWeight.w400);
      final address = _style(tester, find.text(a.venue.address));
      expect(address.fontSize, 13);
      expect(address.fontWeight, FontWeight.w400);
      expect(address.color, isNot(name.color));
      final pin = _iconRect(tester, OgIcons.mapPin);
      expect(pin.size, const Size(18, 18));
      expect(tester.getRect(find.text(a.venue.name)).left - pin.right, 10);
    });

    testWidgets('an event that is also online says "and online"', (
      tester,
    ) async {
      final a = (await _event()).copyWith(online: true);
      await _pump(tester, a);
      expect(find.text('${a.venue.name} and online'), findsOneWidget);
    });

    testWidgets('people row: going count and price, 13 regular muted', (
      tester,
    ) async {
      final a = await _event();
      await _pump(tester, a);
      final row = find.text('1,284 going • Free');
      expect(row, findsOneWidget);
      final style = _style(tester, row);
      expect(style.fontSize, 13);
      expect(style.fontWeight, FontWeight.w400);
      final ctx = tester.element(find.byType(PlayCard));
      expect(style.color, ctx.type.caption.color);
      expect(_iconRect(tester, OgIcons.group).size, const Size(18, 18));
      expect(find.textContaining('All ages'), findsNothing);

      await _pump(tester, a.copyWith(feeCents: 800));
      expect(find.textContaining('going • S\$'), findsOneWidget);
      expect(find.textContaining('/ entry'), findsOneWidget);
    });

    testWidgets('friend row: avatar 28, "are going", 13 regular', (
      tester,
    ) async {
      await _pump(tester, await _event());
      final avatar = tester.getRect(find.byType(SolidAvatar));
      expect(avatar.size, const Size(28, 28));
      final text = find.textContaining('are going');
      expect(text, findsOneWidget);
      final style = tester.widget<Text>(text).style!;
      expect(style.fontSize, 13);
      expect(style.fontWeight, FontWeight.w400);
    });

    testWidgets('on Home the friend row is left out when no one is going', (
      tester,
    ) async {
      // With a note under the date, so both layouts keep that line.
      final a = (await _event()).copyWith(proof: null, recurrence: 'Every Tue');
      await _pump(tester, a);
      expect(find.byType(SolidAvatar), findsNothing);
      final home = tester.getSize(find.byType(PlayCard)).height;
      // Elsewhere an empty 28-point strip (and its 12-point gap) stays.
      await _pump(tester, a, onHome: false);
      expect(tester.getSize(find.byType(PlayCard)).height - home, 40);
    });
  });

  group('Spacing', () {
    testWidgets('14, 12, 12, 12, 12 between the rows, 16 at the bottom', (
      tester,
    ) async {
      final a = (await _event()).copyWith(recurrence: 'Every Tue');
      await _pump(tester, a);
      final banner = tester.getRect(find.byType(ClipRRect).first);
      final title = tester.getRect(find.text(a.title));
      final date = tester.getRect(
        find.text(Fmt.dayTimeRange(a.startsAt, a.endsAt)),
      );
      final sub = tester.getRect(find.text('Every Tue'));
      final pin = _iconRect(tester, OgIcons.mapPin);
      final address = tester.getRect(find.text(a.venue.address));
      final people = tester.getRect(find.textContaining('going •'));
      final avatar = tester.getRect(find.byType(SolidAvatar));
      final card = tester.getRect(find.byType(PlayCard));

      expect(title.top - banner.bottom, 14);
      expect(date.top - title.bottom, 12);
      // The pin sits 1 point below the venue row's top.
      expect(pin.top - 1 - sub.bottom, 12);
      expect(people.top - address.bottom, 12);
      expect(avatar.top - people.bottom, 12);
      expect(card.bottom - avatar.bottom, 16);
    });

    testWidgets('side padding is 16', (tester) async {
      final a = await _event();
      await _pump(tester, a);
      final card = tester.getRect(find.byType(PlayCard));
      expect(tester.getRect(find.text(a.title)).left - card.left, 16);
    });
  });
}
