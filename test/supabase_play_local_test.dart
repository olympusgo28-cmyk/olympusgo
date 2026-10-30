// Runs against a local Supabase stack (never the hosted project), through the
// real API and the real resolve-login function. Skipped unless
// LOCAL_SUPABASE_URL and LOCAL_SUPABASE_KEY point at `supabase start`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/local_accounts.dart';

import 'package:olympus_go/features/play/data/play_repository.dart';
import 'package:olympus_go/features/play/domain/meet_ops.dart';

import 'package:olympus_go/features/auth/data/biometric_vault.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The phone's Keychain isn't there in a test.
class _NoVault extends BiometricVault {
  @override
  Future<void> saveToken(String userId, String token) async {}
}

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

  Future<SupabaseClient> player(
    String name, {
    String birthday = '1990-01-01',
  }) async {
    final c = client();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await signUpLocal(
      c,
      email: '$name.$stamp@test.local',
      password: 'test-password-123',
    );
    await c.rpc(
      'set_birthday',
      params: {'p_birthday': birthday, 'p_country': 'SG'},
    );
    await c
        .from('profiles')
        .update({
          'username': '${name}_${stamp % 10000000}',
          'full_name': '$name Test',
          'onboarding_completed': true,
        })
        .eq('id', c.auth.currentUser!.id);
    return c;
  }

  Future<String> meet(
    SupabaseClient host, {
    int capacity = 10,
    int minPlayers = 2,
  }) async {
    final venue = await host.from('venues').select('id').limit(1).single();
    final start = DateTime.now().toUtc().add(const Duration(days: 2));
    final row = await host
        .from('activities')
        .insert({
          'kind': 'meet',
          'host_id': host.auth.currentUser!.id,
          'title': 'Race test',
          'sports': ['badminton'],
          'game_type': 'doubles',
          'format': 'open_play',
          'starts_at': start.toIso8601String(),
          'ends_at': start.add(const Duration(hours: 2)).toIso8601String(),
          'venue_id': venue['id'],
          'capacity': capacity,
          'min_players': minPlayers,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  test(
    'R-MET-4 20 parallel joins on 10 spots give exactly 10 and 10 in order',
    () async {
      final host = await player('racehost');
      final id = await meet(host);
      final players = [for (var i = 0; i < 20; i++) await player('racer$i')];

      final results = await Future.wait([
        for (final p in players)
          p.rpc('join_activity', params: {'activity': id}),
      ]);

      expect(results.where((r) => r == 'joined'), hasLength(10));
      expect(results.where((r) => r == 'waitlist'), hasLength(10));

      final card = await host
          .from('activity_cards')
          .select('spots_taken, waitlist_count')
          .eq('id', id)
          .single();
      expect(card['spots_taken'], 10);
      expect(card['waitlist_count'], 10);

      // Places in the queue are 1 to 10 with no gaps or ties.
      final waiting = [
        for (final (i, p) in players.indexed)
          if (results[i] == 'waitlist') p,
      ];
      final places = <int>[];
      for (final p in waiting) {
        final row = await p
            .from('activity_cards')
            .select('my_waitlist_position')
            .eq('id', id)
            .single();
        places.add(row['my_waitlist_position'] as int);
      }
      places.sort();
      expect(places, List.generate(10, (i) => i + 1));

      // Leaving promotes the first in the queue, and only them.
      final positions = {
        for (final p in waiting)
          p:
              (await p
                      .from('activity_cards')
                      .select('my_waitlist_position')
                      .eq('id', id)
                      .single())['my_waitlist_position']
                  as int,
      };
      final next = positions.entries.firstWhere((e) => e.value == 1).key;
      final joined = players[results.indexOf('joined')];
      await joined.rpc('leave_activity', params: {'activity': id});
      final after = await next
          .from('activity_cards')
          .select('my_status')
          .eq('id', id)
          .single();
      expect(after['my_status'], 'joined');
      final full = await host
          .from('activity_cards')
          .select('spots_taken, waitlist_count')
          .eq('id', id)
          .single();
      expect(full['spots_taken'], 10);
      expect(full['waitlist_count'], 9);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'P1-09 sign up by mobile, host, a second account joins, Game is on',
    () async {
      final vault = _NoVault();
      Future<SupabaseClient> mobile(String phone) async {
        final c = client();
        final auth = SupabaseAuthRepository(c, vault);
        await auth.sendCode(phone, signUp: true);
        await auth.verifyCode(phone, '123456');
        return c;
      }

      final host = await mobile('+6580000003');
      final guest = await mobile('+6580000004');
      expect(host.auth.currentUser, isNotNull);
      expect(guest.auth.currentUser!.id, isNot(host.auth.currentUser!.id));

      // Running this test twice finds the same accounts, which is the point
      // of a mobile being the account: it signs in rather than duplicates.
      for (final c in [host, guest]) {
        await c.rpc(
          'set_birthday',
          params: {'p_birthday': '1990-01-01', 'p_country': 'SG'},
        );
      }

      final id = await meet(host, capacity: 4, minPlayers: 1);
      expect(
        await guest.rpc('join_activity', params: {'activity': id}),
        'joined',
      );
      final card = await guest
          .from('activity_cards')
          .select('game_is_on')
          .eq('id', id)
          .single();
      expect(card['game_is_on'], isTrue);
    },
    skip: skip,
  );

  test(
    'the live API refuses a restricted child, and linking lifts it',
    () async {
      final child = await player('child', birthday: '2016-01-01');
      final parent = await player('parent');

      Future<void> refused(Future<Object?> Function() call) => expectLater(
        call(),
        throwsA(
          isA<PostgrestException>().having(
            (e) => e.message,
            'message',
            'Ask a parent to link your account first.',
          ),
        ),
      );

      await refused(() => child.rpc('shop_cart'));
      await refused(() => child.rpc('suggested_players'));
      await refused(() => child.from('products').select());
      await refused(() => child.from('activity_cards').select());
      final status = await child.rpc('my_restrictions') as Map;
      expect(status['restricted'], isTrue);

      final code = await child.rpc('guardian_code_create') as Map;
      final link = await parent.rpc(
        'guardian_code_redeem',
        params: {'p_code': code['code']},
      ) as Map;
      await parent.rpc(
        'guardian_link_decide',
        params: {'p_link': link['link_id'], 'p_approve': true},
      );

      final after = await child.rpc('my_restrictions') as Map;
      expect(after['restricted'], isFalse);
      expect(after['can_scan'], isFalse);
      await child.from('activity_cards').select().limit(1);
    },
    skip: skip,
  );

  test('P3-04 two players confirm one score at once and the rating moves once', () async {
    final service = SupabaseClient(
      url!,
      Platform.environment['LOCAL_SUPABASE_SERVICE_KEY']!,
    );
    final host = await player('ratehost');
    final id = await meet(host);
    final a = await player('ratea');
    final b = await player('rateb');
    final c = await player('ratec');
    final d = await player('rated');
    for (final p in [a, b, c, d]) {
      await p.rpc('join_activity', params: {'activity': id});
    }
    await service
        .from('activities')
        .update({
          'starts_at': DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
          'ranked': true,
        })
        .eq('id', id);
    await service
        .from('activity_participants')
        .update({'attendance': 'present'})
        .eq('activity_id', id);

    final repo = SupabasePlayRepository(a);
    final key =
        '11111111-2222-4333-8444-${DateTime.now().microsecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}';
    Future<MatchScore> send() => repo.submitScore(
      id,
      partners: [b.auth.currentUser!.id],
      opponents: [c.auth.currentUser!.id, d.auth.currentUser!.id],
      games: const [(21, 12), (21, 15)],
      clientKey: key,
    );
    final sent = await send();
    expect((await send()).id, sent.id, reason: 'a retry finds the same one');

    final results = await Future.wait([
      for (final p in [c, d])
        p
            .rpc('answer_score', params: {'score': sent.id, 'ok': true})
            .then((_) => true, onError: (_) => false),
    ]);
    expect(results.where((ok) => ok), hasLength(1));

    final events = await service
        .from('rating_events')
        .select('user_id')
        .eq('user_id', a.auth.currentUser!.id);
    expect(events, hasLength(1));

    final after = await repo.score(sent.id);
    expect(after.ratingAfter, greaterThan(after.ratingBefore!));
    final recap = await repo.recap(id);
    expect(recap.wins, 1);
    expect(recap.ratingAfter, after.ratingAfter);
  }, skip: skip);

  test(
    'P3-06 six parallel entries on three places give exactly three',
    () async {
      final service = SupabaseClient(
        url!,
        Platform.environment['LOCAL_SUPABASE_SERVICE_KEY']!,
      );
      final host = await player('drawhost');
      final id = await meet(host, capacity: 3);
      await service
          .from('activities')
          .update({
            'kind': 'tournament',
            'format': 'knockout',
            'game_type': 'singles',
            'status': 'published',
          })
          .eq('id', id);
      final players = [for (var i = 0; i < 6; i++) await player('entry$i')];
      await Future.wait([
        for (final p in players)
          p.rpc(
            'tournament_register',
            params: {
              'p_activity': id,
              'p_divisions': ['main'],
            },
          ),
      ]);
      final rows = await service
          .from('tournament_entries')
          .select('status')
          .eq('activity_id', id);
      expect(rows.where((r) => r['status'] == 'entered'), hasLength(3));
      expect(rows.where((r) => r['status'] == 'waitlist'), hasLength(3));
    },
    skip: skip,
  );
}
