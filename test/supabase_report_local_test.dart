// Audit S3 (Q269) through the real API and the app's own repositories: three
// outsiders can't report, and so can't hide, a message in a club they aren't
// in, and an account that floods reports is stopped with a clear message.
// Skipped unless LOCAL_SUPABASE_URL and LOCAL_SUPABASE_KEY point at
// `supabase start` running locally.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/clubs/data/club_repository.dart';
import 'package:olympus_go/features/clubs/data/supabase_club_repository.dart';
import 'package:olympus_go/features/clubs/domain/club_models.dart';
import 'package:olympus_go/features/clubs/domain/club_sport.dart';
import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:olympus_go/features/social/data/social_repository.dart';
import 'package:olympus_go/features/social/domain/social_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/local_accounts.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final skip = url == null || key == null || !url.contains('127.0.0.1')
      ? 'Needs a local Supabase stack'
      : null;

  Future<SupabaseClient> player(String name) async {
    final client = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await signUpLocal(
      client,
      email: '$name.$stamp@test.local',
      password: 'test-password-123',
    );
    await client.rpc(
      'set_birthday',
      params: {'p_birthday': '1990-01-01', 'p_country': 'SG'},
    );
    await client
        .from('profiles')
        .update({
          'username': '${name}_${stamp % 100000}',
          'full_name': '$name Test',
          'onboarding_completed': true,
        })
        .eq('id', client.auth.currentUser!.id);
    return client;
  }

  SupabaseClubRepository clubs(SupabaseClient c) =>
      SupabaseClubRepository(c, SupabasePlayRepository(c));

  Matcher failsWith(String message) =>
      throwsA(isA<AuthFailure>().having((e) => e.message, 'message', message));

  test('three outsiders cannot hide a club message they cannot see', () async {
    final ownerClient = await player('owner');
    final owner = clubs(ownerClient);
    final id = await owner.createClub(
      const ClubDraft(
        name: 'Report Test Club',
        area: 'Tampines',
        sports: [ClubSport.badminton],
        ranges: {ClubSport.badminton: LevelRange(2, 6)},
      ),
    );
    await owner.send(ChatScope.club(id), 'See you at 8');
    final sent = await owner
        .chat(ChatScope.club(id))
        .firstWhere((m) => m.isNotEmpty)
        .timeout(const Duration(seconds: 15));
    final target = ReportTarget.message(
      sent.single.id,
      scope: ChatScope.club(id),
    );

    for (final name in ['out1', 'out2', 'out3']) {
      final outsider = clubs(await player(name));
      await expectLater(
        outsider.report(target, ContentReport.harassment, ''),
        failsWith("This can't be reported."),
      );
    }

    final row = await ownerClient
        .from('group_messages')
        .select('removed')
        .eq('id', sent.single.id)
        .single();
    expect(row['removed'], isFalse, reason: 'still showing in the chat');
  }, skip: skip);

  test('a flood of reports is stopped with a clear message', () async {
    final target = await player('target');
    final reporter = SupabaseSocialRepository(await player('flood'));
    final targetId = target.auth.currentUser!.id;
    for (var i = 0; i < 10; i++) {
      await reporter.report(targetId, ReportReason.spam);
    }
    await expectLater(
      reporter.report(targetId, ReportReason.spam),
      failsWith("You've sent a lot of reports. Try again in an hour."),
    );
  }, skip: skip);
}
