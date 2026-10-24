// Runs the real clubs repository against a local Supabase stack (never the
// hosted project). Skipped unless LOCAL_SUPABASE_URL and LOCAL_SUPABASE_KEY
// point at `supabase start` running locally.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/clubs/data/club_repository.dart';
import 'package:olympus_go/features/clubs/data/supabase_club_repository.dart';
import 'package:olympus_go/features/clubs/domain/club_models.dart';
import 'package:olympus_go/features/clubs/domain/club_sport.dart';
import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final skip = url == null || key == null || !url.contains('127.0.0.1')
      ? 'Needs a local Supabase stack'
      : null;

  Future<(SupabaseClient, SupabaseClubRepository)> player(String name) async {
    final client = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final res = await client.auth.signUp(
      email: '$name.$stamp@test.local',
      password: 'test-password-123',
    );
    await client
        .from('profiles')
        .update({
          'username': '${name}_${stamp % 100000}',
          'full_name': '$name Test',
          'onboarding_completed': true,
        })
        .eq('id', res.user!.id);
    await client.from('player_sports').insert({
      'user_id': res.user!.id,
      'sport': 'badminton',
      'level': 4,
      'play_min': 3,
      'play_max': 5,
    });
    return (
      client,
      SupabaseClubRepository(client, SupabasePlayRepository(client)),
    );
  }

  test(
    'a club from creation to chat, against local Supabase',
    () async {
      final (_, owner) = await player('owner');
      final (memberClient, member) = await player('member');

      final id = await owner.createClub(
        const ClubDraft(
          name: 'Local Smashers',
          area: 'Tampines',
          sports: [ClubSport.badminton],
          ranges: {ClubSport.badminton: LevelRange(2, 6)},
        ),
      );
      final mine = await owner.clubs(ClubTab.mine);
      expect(mine.single.club.id, id);
      expect(mine.single.club.isOwner, isTrue);
      expect(mine.single.club.primaryRange.label, 'HB–AD');
      expect(mine.single.club.can(ClubPermission.fees), isTrue);
      expect((await owner.roles(id)).map((r) => r.name), ['Owner', 'Admin']);

      // Join by request, then approval.
      expect(
        (await member.clubs(ClubTab.recommended)).map((c) => c.club.id),
        contains(id),
      );
      await member.join(id, message: 'Hi');
      expect((await member.club(id)).standing, ClubStanding.requested);
      final requests = await owner.requests(id);
      expect(requests.single.message, 'Hi');
      await owner.decideRequest(id, requests.single.id, RequestStatus.approved);
      expect((await member.club(id)).standing, ClubStanding.member);
      expect(await owner.members(id), hasLength(2));

      // Members can't moderate.
      await expectLater(
        member.removeMember(id, (await owner.members(id)).first.player.id),
        throwsA(isA<Exception>()),
      );

      // An Organizer role lets the member host.
      final memberId = memberClient.auth.currentUser!.id;
      final role = await owner.createRole(
        id,
        name: 'Organizer',
        color: 0xFF3E6B8A,
        level: RoleLevel.organizer,
        members: {memberId},
      );
      expect(role.memberCount, 1);
      expect((await member.club(id)).can(ClubPermission.createMeet), isTrue);
      expect((await member.club(id)).myRoleName, 'Organizer');

      // Announcements and chat.
      await owner.announce(
        id,
        title: 'Courts moved',
        body: 'Court 3 this week',
        audience: 'everyone',
        pinned: true,
      );
      expect((await member.announcements(id)).single.title, 'Courts moved');
      await member.send(ChatScope.club(id), 'Hello club');
      final messages = await owner
          .chat(ChatScope.club(id))
          .firstWhere((m) => m.isNotEmpty)
          .timeout(const Duration(seconds: 15));
      expect(messages.single.body, 'Hello club');
      expect(messages.single.sender.displayName, 'member Test');
      expect(messages.single.roleName, 'Organizer');

      // Leaderboard, invite code and audit.
      expect(
        (await owner.leaderboard(id, ClubSport.badminton)).rows,
        hasLength(2),
      );
      final code = (await owner.club(id)).inviteCode!;
      expect(await member.clubIdForCode(code), id);
      expect(await owner.audit(id), isNotEmpty);

      // Teams.
      final team = await owner.createTeam(
        TeamDraft(name: 'Local Team A', players: {memberId}),
      );
      expect((await member.teams(ClubTab.mine)).single.team.id, team);
      expect(await owner.teamMembers(team), hasLength(2));

      // Hand over and delete.
      await owner.transfer(id, memberId);
      expect((await member.club(id)).isOwner, isTrue);
      await member.deleteClub(id);
      expect(await member.clubs(ClubTab.mine), isEmpty);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
