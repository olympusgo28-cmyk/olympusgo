import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/features/clubs/application/club_providers.dart';
import 'package:olympus_go/features/clubs/data/club_repository.dart';
import 'package:olympus_go/features/clubs/domain/club_models.dart';
import 'package:olympus_go/features/play/presentation/create_screens.dart';

/// Activities are hosted by a club: no club with a hosting role means the
/// player is sent to start a group, and roles limit what can be created.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> open(WidgetTester tester, List<ClubListItem> mine) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => showCreateMenu(context),
              child: const Text('open'),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clubListProvider(ClubTab.mine).overrideWith((_) async => mine),
        ],
        child: MaterialApp.router(theme: OgTheme.light(), routerConfig: router),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('no hosting club asks to start a group', (tester) async {
    await open(tester, const [
      // A plain member can't host anything.
      ClubListItem(
        club: Club(
          id: 'c1',
          name: 'Member Club',
          standing: ClubStanding.member,
        ),
      ),
    ]);
    expect(find.text('Start a group first'), findsOneWidget);
    expect(find.text('Start a group'), findsOneWidget);
    expect(find.text('Meet'), findsNothing);
  });

  testWidgets('only the kinds the role allows are offered', (tester) async {
    await open(tester, const [
      ClubListItem(
        club: Club(
          id: 'c2',
          name: 'Organizer Club',
          standing: ClubStanding.member,
          myPermissions: {ClubPermission.createMeet},
        ),
      ),
    ]);
    expect(find.text('Hosted by Organizer Club'), findsOneWidget);
    expect(find.text('Meet'), findsOneWidget);
    expect(find.text('Tournament'), findsNothing);
    expect(find.text('Event'), findsNothing);
  });
}
