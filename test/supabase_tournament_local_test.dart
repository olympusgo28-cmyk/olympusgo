// Runs the real tournament repository against a local Supabase stack (never
// the hosted project). Skipped unless LOCAL_SUPABASE_URL and
// LOCAL_SUPABASE_KEY point at `supabase start` running locally.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/clubs/data/supabase_club_repository.dart';
import 'package:olympus_go/features/clubs/domain/club_models.dart';
import 'package:olympus_go/features/clubs/domain/club_sport.dart';
import 'package:olympus_go/features/game/data/game_repository.dart';
import 'package:olympus_go/features/game/domain/game_models.dart';
import 'package:olympus_go/features/play/data/competition_repository.dart';
import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:olympus_go/features/play/domain/tournament_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final skip = url == null || key == null || !url.contains('127.0.0.1')
      ? 'Needs a local Supabase stack'
      : null;

  Future<(SupabaseClient, SupabaseTournamentRepository)> player(
    String name,
    double level,
  ) async {
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
      'level': level,
      'play_min': 1,
      'play_max': 8,
    });
    return (
      client,
      SupabaseTournamentRepository(client, SupabasePlayRepository(client)),
    );
  }

  test(
    'a tournament from entries to results, against local Supabase',
    () async {
      final (hostClient, host) = await player('host', 5);
      final clubId =
          await SupabaseClubRepository(
            hostClient,
            SupabasePlayRepository(hostClient),
          ).createClub(
            const ClubDraft(
              name: 'Draw Club',
              area: 'Tampines',
              sports: [ClubSport.badminton],
              ranges: {ClubSport.badminton: LevelRange(1, 8)},
            ),
          );
      final venue = await hostClient.from('venues').select('id').limit(1);
      final start = DateTime.now().add(const Duration(days: 5)).toUtc();
      final row = await hostClient
          .from('activities')
          .insert({
            'kind': 'tournament',
            'host_id': hostClient.auth.currentUser!.id,
            'club_id': clubId,
            'title': 'Local Open',
            'cover_title': 'Local Open',
            'sports': ['badminton'],
            'format': 'groups_knockout',
            'game_type': 'singles',
            'starts_at': start.toIso8601String(),
            'ends_at': start.add(const Duration(hours: 8)).toIso8601String(),
            'venue_id': venue.first['id'],
            'capacity': 16,
            'courts': 4,
          })
          .select('id')
          .single();
      final id = row['id'] as String;

      final players = [
        for (var i = 0; i < 8; i++) await player('p$i', 1.0 + i),
      ];
      for (final (_, p) in players) {
        await p.register(id, divisionIds: ['main']);
      }
      final (_, top) = players.last;
      expect((await top.info(id)).mine, isNotNull);

      final before = await host.info(id);
      expect(before.divisions.single.entries, 8);
      expect(before.divisions.single.drawn, isFalse);
      await expectLater(top.makeDraw(id, 'main'), throwsA(isA<Object>()));
      expect(await host.makeDraw(id, 'main'), 8);

      final groups = await host.groups(id, 'main');
      expect(groups.map((g) => g.name), ['Group A', 'Group B']);
      expect(groups.every((g) => g.rows.length == 4), isTrue);
      // The top seed (level 8) heads Group A.
      expect(groups.first.rows.map((r) => r.seed), contains(1));

      var ms = await host.matches(id, divisionId: 'main');
      expect(ms.where((m) => m.stage == DrawStage.group), hasLength(12));
      expect(ms.where((m) => m.stage == DrawStage.knockout), hasLength(3));
      expect(ms.where((m) => m.stage == DrawStage.third), hasLength(1));
      expect(ms.every((m) => m.at != null && m.court != null), isTrue);

      final ko = await host.knockout(id, 'main');
      expect(ko.map((r) => r.name), ['Semi-finals', 'Final', '3rd place']);
      expect(ko.first.matches.first.a, 'A1 · winner');
      expect(ko.first.matches.first.b, 'B2 · runner-up');
      expect(ko[1].matches.single.a, 'SF1 winner');

      // Play every group match, then the knockout, as they become ready.
      for (var round = 0; round < 10; round++) {
        ms = await host.matches(id, divisionId: 'main');
        final ready = ms.where((m) => m.ready && !m.done).toList();
        if (ready.isEmpty) break;
        for (final m in ready) {
          await host.callMatch(m.id);
          await host.saveScore(m.id, const [(21, 15), (19, 21), (21, 17)]);
        }
      }
      ms = await host.matches(id, divisionId: 'main');
      expect(ms.every((m) => m.done), isTrue);
      expect((await host.info(id)).finished, isTrue);

      final semis = (await host.knockout(id, 'main')).first.matches;
      expect(semis.every((m) => m.scoreA == 2 && m.scoreB == 1), isTrue);

      // Everyone sees their own matches and where they finished.
      final places = <int>[];
      for (final (_, p) in players) {
        final mine = await p.myMatches(id);
        expect(mine, isNotEmpty);
        expect(mine.every((m) => m.state.name == 'done'), isTrue);
        places.add((await p.result(id))!.place);
      }
      expect(places.where((p) => p == 1), hasLength(1));
      expect(places.where((p) => p == 2), hasLength(1));
      expect(places.where((p) => p == 3), hasLength(1));
      expect(places.where((p) => p == 4), hasLength(1));
      expect(places.where((p) => p == 5), hasLength(4));

      final result = (await top.result(id))!;
      expect(result.podium, hasLength(3));
      expect(result.entries, 8);

      // A score can't change once the next round is played.
      final semi = ms.firstWhere(
        (m) => m.stage == DrawStage.knockout && m.round == 1,
      );
      await expectLater(
        host.saveScore(semi.id, const [(10, 21), (10, 21)]),
        throwsA(isA<Object>()),
      );
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'doubles partners invite, accept and withdraw',
    () async {
      final (hostClient, host) = await player('dhost', 5);
      final clubId =
          await SupabaseClubRepository(
            hostClient,
            SupabasePlayRepository(hostClient),
          ).createClub(
            const ClubDraft(
              name: 'Pairs Club',
              area: 'Bishan',
              sports: [ClubSport.badminton],
              ranges: {ClubSport.badminton: LevelRange(1, 8)},
            ),
          );
      final venue = await hostClient.from('venues').select('id').limit(1);
      final start = DateTime.now().add(const Duration(days: 5)).toUtc();
      final row = await hostClient
          .from('activities')
          .insert({
            'kind': 'tournament',
            'host_id': hostClient.auth.currentUser!.id,
            'club_id': clubId,
            'title': 'Pairs Cup',
            'cover_title': 'Pairs Cup',
            'sports': ['badminton'],
            'format': 'knockout',
            'game_type': 'doubles',
            'division_keys': ['XD'],
            'starts_at': start.toIso8601String(),
            'ends_at': start.add(const Duration(hours: 8)).toIso8601String(),
            'venue_id': venue.first['id'],
            'capacity': 8,
          })
          .select('id')
          .single();
      final id = row['id'] as String;

      final (aClient, a) = await player('pa', 4);
      final (bClient, b) = await player('pb', 6);
      await expectLater(
        a.register(id, divisionIds: ['XD']),
        throwsA(isA<Object>()),
      );
      await a.register(
        id,
        divisionIds: ['XD'],
        partnerId: bClient.auth.currentUser!.id,
      );
      var entries = await host.entries(id, 'XD');
      expect(entries.single.status, EntryStatus.partnerPending);

      final invite = (await b.info(id)).invite!;
      expect(invite.from.id, aClient.auth.currentUser!.id);
      expect(invite.divisionName, 'Mixed doubles');
      await b.answerInvite(id, invite.entryId, accept: true);

      entries = await host.entries(id, 'XD');
      expect(entries.single.status, EntryStatus.paid);
      expect(entries.single.names, 'pa and pb');
      expect(entries.single.rating, 5.0);
      expect(
        (await b.info(id)).mine?.partner?.id,
        aClient.auth.currentUser!.id,
      );

      await host.setCheckedIn(id, entries.single.id, true);
      expect((await host.info(id)).checkedIn, 1);
      expect(
        await host.message(id, to: 'All 1 entrants', text: 'See you there'),
        2,
      );

      await b.withdraw(id, toWallet: true, injury: false);
      expect(await host.entries(id, 'XD'), isEmpty);
      expect((await a.info(id)).mine, isNull);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'event tickets, the door and the live court, against local Supabase',
    () async {
      final (hostClient, host) = await player('ehost', 5);
      final events = SupabaseEventRepository(
        hostClient,
        SupabasePlayRepository(hostClient),
      );
      final clubId =
          await SupabaseClubRepository(
            hostClient,
            SupabasePlayRepository(hostClient),
          ).createClub(
            const ClubDraft(
              name: 'Finals Club',
              area: 'Kallang',
              sports: [ClubSport.badminton],
              ranges: {ClubSport.badminton: LevelRange(1, 8)},
            ),
          );
      final venue = await hostClient.from('venues').select('id').limit(1);
      final start = DateTime.now().add(const Duration(days: 5)).toUtc();
      Future<String> make(Map<String, dynamic> extra) async {
        final row = await hostClient
            .from('activities')
            .insert({
              'host_id': hostClient.auth.currentUser!.id,
              'club_id': clubId,
              'sports': ['badminton'],
              'starts_at': start.toIso8601String(),
              'ends_at': start.add(const Duration(hours: 8)).toIso8601String(),
              'venue_id': venue.first['id'],
              ...extra,
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      final cup = await make({
        'kind': 'tournament',
        'title': 'Finals Cup',
        'cover_title': 'Finals Cup',
        'format': 'knockout',
        'game_type': 'singles',
        'capacity': 8,
      });
      final day = await make({
        'kind': 'event',
        'title': 'Finals Day',
        'cover_title': 'Finals Day',
        'format': 'festival',
        'capacity': 5,
        'linked_id': cup,
      });

      final ps = [for (var i = 0; i < 4; i++) await player('f$i', 2.0 + i)];
      for (final (_, p) in ps) {
        await p.register(cup, divisionIds: ['main']);
      }
      await host.makeDraw(cup, 'main');
      final semi = (await host.matches(cup))
          .firstWhere((m) => m.stage == DrawStage.knockout && m.round == 1);
      await host.callMatch(semi.id);

      // A fan takes 3 tickets, then 2 more: only 2 seats are left after.
      final (fanClient, _) = await player('fan', 3);
      final fan = SupabaseEventRepository(
        fanClient,
        SupabasePlayRepository(fanClient),
      );
      final t = await fan.buy(day, qty: 3);
      expect(t.qty, 3);
      expect(t.code, startsWith('OG-'));
      await expectLater(fan.buy(day, qty: 3), throwsA(isA<Object>()));
      expect((await fan.buy(day, qty: 2)).qty, 5);
      expect(await fan.release(day, qty: 1), 0);
      expect((await fan.ticket(day))!.qty, 4);

      final info = await fan.info(day);
      expect(info.tickets, 4);
      expect(info.partOfTitle, 'Finals Cup');
      expect(info.programme.map((p) => p.title), [
        'Singles semi-final',
        'Singles semi-final',
        'Singles final',
        'Singles 3rd place',
      ]);
      expect(info.programme[2].sub, startsWith('SF1 winner vs SF2 winner'));
      expect(info.live, isNotNull);
      expect(info.live!.label, contains('SEMI-FINAL'));

      await fan.cheer(day, sideA: true);
      await fan.cheer(day, sideA: true);
      await fan.remind(day, info.programme[2].id, true);
      final again = await fan.info(day);
      expect(again.live!.cheersA, 2);
      expect(again.programme[2].reminded, isTrue);

      // At the door.
      final bad = await events.scan(day, 'OG-ZZZZZZ');
      expect(bad.valid, isFalse);
      final ok = await events.scan(day, t.code.toLowerCase());
      expect(ok.valid, isTrue);
      expect(ok.qty, 4);
      expect(ok.usedAt, isNull);
      expect(ok.scanned, 4);
      final twice = await events.scan(day, t.code);
      expect(twice.usedAt, isNotNull);
      expect((await events.info(day)).scannedIn, 4);
      await expectLater(fan.scan(day, t.code), throwsA(isA<Object>()));
      await expectLater(fan.release(day, qty: 1), throwsA(isA<Object>()));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('my gear and the leaderboards, against local Supabase', () async {
    final (client, _) = await player('gear', 4);
    final game = SupabaseGameRepository(client);
    final saved = await game.saveGear(
      const Gear(
        id: '',
        type: GearType.badmintonRacquet,
        brand: 'Yonex',
        model: 'Astrox 99',
        specs: [('Weight', '4U'), ('String', '')],
        priceCents: 28900,
      ),
    );
    expect(saved.id, isNotEmpty);
    expect(saved.specs, [('Weight', '4U')]);
    await game.saveGear(
      Gear(
        id: saved.id,
        type: saved.type,
        brand: 'Yonex',
        model: 'Astrox 100',
        specs: saved.specs,
      ),
    );
    final mine = await game.gear();
    expect(mine.single.name, 'Yonex Astrox 100');
    expect(mine.single.priceCents, isNull);
    // Someone else's gear stays private.
    final (other, _) = await player('other', 4);
    expect(await SupabaseGameRepository(other).gear(), isEmpty);

    final points = await game.leaderboard(
      local: false,
      sport: 'Badminton',
      area: 'All Singapore',
    );
    expect(points.first.sub, startsWith('Champion, '));
    expect(points.first.score, '100');
    final rating = await game.leaderboard(
      local: true,
      sport: 'Badminton',
      area: 'All Singapore',
    );
    expect(rating, isNotEmpty);
    expect(rating.first.sub, contains('match'));
    expect(
      await game.leaderboard(local: true, sport: 'Badminton', area: 'East'),
      isEmpty,
    );
  }, skip: skip);
}
