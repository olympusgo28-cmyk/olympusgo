// The Player card (owner, 15 Nov 2026).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/theme/og_home.dart';
import 'package:olympus_go/core/theme/og_type.dart';
import 'package:olympus_go/core/widgets/og_icon.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';
import 'package:olympus_go/features/onboarding/domain/sport.dart';
import 'package:olympus_go/features/settings/domain/settings_models.dart';
import 'package:olympus_go/features/social/domain/social_models.dart';
import 'package:olympus_go/features/social/presentation/player_card.dart';

const _hannah = PlayerSummary(id: 'p1', fullName: 'Li Wei');

SuggestedPlayer _suggestion({
  Sport? sport = Sport.badminton,
  Gender gender = Gender.female,
  int friends = 3,
  int clubs = 0,
}) => SuggestedPlayer(
  player: _hannah,
  level: 6.2,
  sport: sport,
  gender: gender,
  mutualFriends: friends,
  mutualClubs: clubs,
);

/// The test font is far wider than Inter, so text wraps and the card needs
/// room: it sits in a tall box, or, with [snug], takes its content's height.
Future<void> _pump(
  WidgetTester tester,
  SuggestedPlayer s, {
  bool onHome = false,
  bool snug = false,
}) {
  final card = PlayerCard(suggestion: s, onHome: onHome);
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: OgTheme.light(),
        home: Scaffold(
          body: Center(
            child: snug
                ? IntrinsicHeight(child: card)
                : SizedBox(height: 400, child: card),
          ),
        ),
      ),
    ),
  );
}

Container _box(WidgetTester tester) => tester.widget<Container>(
  find
      .descendant(of: find.byType(PlayerCard), matching: find.byType(Container))
      .first,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Card', () {
    testWidgets('132 wide, 22 rounded, padded 10 / 16 / 10 / 14', (
      tester,
    ) async {
      await _pump(tester, _suggestion());
      final box = _box(tester);
      expect(tester.getSize(find.byType(PlayerCard)).width, 132);
      expect(
        (box.decoration! as BoxDecoration).borderRadius,
        BorderRadius.circular(22),
      );
      expect(box.padding, const EdgeInsets.fromLTRB(10, 16, 10, 14));
    });

    testWidgets(
      'white, no border, a soft shadow below, on Home and elsewhere',
      (tester) async {
        for (final onHome in [true, false]) {
          await _pump(tester, _suggestion(), onHome: onHome);
          final d = _box(tester).decoration! as BoxDecoration;
          final home = tester.element(find.byType(PlayerCard)).home;
          expect(d.border, isNull, reason: 'onHome: $onHome');
          expect(d.color, home.surface, reason: 'onHome: $onHome');
          final shadow = d.boxShadow!.single;
          expect(shadow.color, home.shadow);
          expect(shadow.offset.dy, greaterThan(0), reason: 'below the card');
          expect(shadow.offset.dx, 0);
        }
      },
    );

    testWidgets('the light card is white', (tester) async {
      await _pump(tester, _suggestion());
      final d = _box(tester).decoration! as BoxDecoration;
      expect(d.color, const Color(0xFFFFFFFF));
    });

    testWidgets('has no level badge and no Follow button', (tester) async {
      await _pump(tester, _suggestion());
      expect(find.text('6.2'), findsNothing);
      expect(find.text('Follow'), findsNothing);
      expect(find.text('Following'), findsNothing);
    });
  });

  group('Rows', () {
    testWidgets('avatar is 60 and centred', (tester) async {
      await _pump(tester, _suggestion());
      final avatar = tester.getRect(find.byType(SolidAvatar));
      expect(avatar.size, const Size(60, 60));
      expect(
        avatar.center.dx,
        tester.getRect(find.byType(PlayerCard)).center.dx,
      );
    });

    testWidgets(
      'the sport icon is its own row, in a 24 disc under the avatar',
      (tester) async {
        await _pump(tester, _suggestion());
        final icon = tester
            .widgetList<OgIcon>(find.byType(OgIcon))
            .firstWhere((i) => i.markup == Sport.badminton.icon);
        expect(icon.size, 14);
        final disc = tester.getRect(
          find
              .ancestor(
                of: find.byWidget(icon),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(disc.size, const Size(24, 24));
        final avatar = tester.getRect(find.byType(SolidAvatar));
        // A row of its own: 8 points under the avatar, not overlapping it.
        expect(disc.top - avatar.bottom, 8);
        expect(disc.center.dx, avatar.center.dx);

        // With no sport the row (and its gap) is left out.
        await _pump(tester, _suggestion(sport: null));
        expect(find.byType(OgIcon), findsNothing);
      },
    );

    testWidgets('name: Inter 15 Medium, centred', (tester) async {
      await _pump(tester, _suggestion());
      final text = tester.widget<Text>(find.text('Li Wei'));
      expect(text.style!.fontSize, 15);
      expect(text.style!.fontWeight, FontWeight.w500);
      expect(text.style!.fontFamily, contains('Inter'));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets(
      'note: gender and mutual counts, 11 regular, one line, muted, centred',
      (tester) async {
        await _pump(tester, _suggestion(friends: 3, clubs: 1));
        final note = find.text('Female · 3 mutual friends · 1 mutual club');
        expect(note, findsOneWidget);
        final text = tester.widget<Text>(note);
        expect(text.style!.fontSize, 11);
        expect(text.style!.fontWeight, FontWeight.w400);
        expect(text.style!.color, tester.element(note).type.caption.color);
        expect(text.textAlign, TextAlign.center);
        expect(text.maxLines, 1);
      },
    );

    testWidgets('note: one friend is singular; no gender is left out', (
      tester,
    ) async {
      await _pump(
        tester,
        _suggestion(gender: Gender.preferNotToSay, friends: 1),
      );
      expect(find.text('1 mutual friend'), findsOneWidget);
    });

    testWidgets('note: "Suggested for you" when there is nothing else', (
      tester,
    ) async {
      await _pump(
        tester,
        _suggestion(gender: Gender.preferNotToSay, friends: 0),
      );
      expect(find.text('Suggested for you'), findsOneWidget);
    });
  });

  group('Spacing', () {
    testWidgets('rows are 8 apart, then flexible space, 14 at the bottom', (
      tester,
    ) async {
      await _pump(
        tester,
        _suggestion(gender: Gender.male, friends: 0),
        snug: true,
      );
      final avatar = tester.getRect(find.byType(SolidAvatar));
      final icon = _iconDisc(tester);
      final name = tester.getRect(find.text('Li Wei'));
      final note = tester.getRect(find.text('Male'));
      final card = tester.getRect(find.byType(PlayerCard));
      expect(icon.top - avatar.bottom, 8);
      expect(name.top - icon.bottom, 8);
      expect(note.top - name.bottom, 8);
      // 8 points, no flexible space left over, then the 14-point padding.
      expect(card.bottom - note.bottom, 8 + 14);
      expect(avatar.top - card.top, 16);
    });

    testWidgets('with no sport, the name is 8 under the avatar', (
      tester,
    ) async {
      await _pump(
        tester,
        _suggestion(sport: null, gender: Gender.male, friends: 0),
        snug: true,
      );
      final avatar = tester.getRect(find.byType(SolidAvatar));
      final name = tester.getRect(find.text('Li Wei'));
      expect(name.top - avatar.bottom, 8);
    });
  });
}

Rect _iconDisc(WidgetTester tester) {
  final icon = tester
      .widgetList<OgIcon>(find.byType(OgIcon))
      .firstWhere((i) => i.markup == Sport.badminton.icon);
  return tester.getRect(
    find
        .ancestor(of: find.byWidget(icon), matching: find.byType(Container))
        .first,
  );
}
