// Runs the real safety repository against a local Supabase stack (never the
// hosted project). Skipped unless LOCAL_SUPABASE_URL and LOCAL_SUPABASE_KEY
// point at `supabase start` running locally.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/domain/country.dart';
import 'package:olympus_go/features/clubs/data/club_repository.dart';
import 'package:olympus_go/features/clubs/data/supabase_club_repository.dart';
import 'package:olympus_go/features/clubs/domain/club_models.dart';
import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:olympus_go/features/safety/data/safety_repository.dart';
import 'package:olympus_go/features/safety/domain/safety_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final skip = url == null || key == null || !url.contains('127.0.0.1')
      ? 'Needs a local Supabase stack'
      : null;

  SupabaseClient client() => SupabaseClient(
    url!,
    key!,
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
  );

  test(
    'reports and legal notices, against local Supabase',
    () async {
      // A legal notice needs no account.
      final anonymous = SupabaseSafetyRepository(client());
      final ref = await anonymous.sendLegalNotice(
        const LegalNotice(
          role: 'The person affected',
          name: 'Test Person',
          email: 'person@test.local',
          country: Country.singapore,
          location: 'A club chat',
          reasons: ['Stalking'],
          details: 'Someone keeps following me after games.',
        ),
      );
      expect(ref, matches(RegExp(r'^OLY-\d{4}-\d{4}$')));

      // A signed-in player reports a club and sees it in My reports.
      final c = client();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      await c.auth.signUp(
        email: 'reporter.$stamp@test.local',
        password: 'test-password-123',
      );
      final clubs = SupabaseClubRepository(c, SupabasePlayRepository(c));
      final club = await clubs.createClub(
        const ClubDraft(name: 'Reported Club', area: 'Bedok'),
      );
      await clubs.report(
        ReportTarget.club(club),
        ContentReport.scam,
        'Fake fees',
      );
      final safety = SupabaseSafetyRepository(c);
      final mine = await safety.myReports();
      expect(mine.single.what, 'Club · Reported Club');
      expect(mine.single.reason, 'Scam or fraud');
      expect(mine.single.state, ReportState.inReview);
      expect(mine.single.decideBy, isNotNull);
      // A second look only after a decision.
      await expectLater(
        safety.askSecondLook(mine.single.id),
        throwsA(isA<Exception>()),
      );
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
