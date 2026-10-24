import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/demo/demo_world.dart';
import '../../../core/domain/country.dart';
import '../../auth/data/auth_repository.dart';
import '../../profile/domain/profile.dart';
import '../domain/social_models.dart';

/// Follows, blocks, reports, saved players and player search.
abstract interface class SocialRepository {
  Future<PlayerDetail> player(String id);
  Future<PlayerSummary?> byUsername(String username);
  Future<PlayerSocial> social(String id);
  Future<List<PlayerSummary>> followers(String id);
  Future<List<PlayerSummary>> following(String id);
  Future<Set<String>> myFollowingIds();
  Future<void> follow(String id);
  Future<void> unfollow(String id);
  Future<List<PlayerSummary>> search(String query);

  /// Players near the viewer's level that they don't follow yet.
  Future<List<SuggestedPlayer>> suggested();
  Future<List<PlayerSummary>> blocked();
  Future<void> block(String id);
  Future<void> unblock(String id);
  Future<void> report(String id, ReportReason reason);
  Future<List<PlayerSummary>> savedPlayers();
  Future<void> setSaved(SavedKind kind, String id, bool saved);

  /// Ids I've saved of one kind.
  Future<Set<String>> savedIds(SavedKind kind);
  Future<void> contactSupport(String message);
}

const _summaryColumns = 'id, username, full_name, avatar_url';

class SupabaseSocialRepository implements SocialRepository {
  SupabaseSocialRepository(this._client);
  final SupabaseClient _client;

  String get _me {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthFailure('Log in again to continue.');
    return id;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const AuthFailure("You can't do that with this player.");
      }
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  Future<List<PlayerSummary>> _profiles(Iterable<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('profiles')
        .select(_summaryColumns)
        .inFilter('id', ids.toList());
    final byId = {
      for (final r in rows) r['id'] as String: PlayerSummary.fromRow(r),
    };
    // Keep the order of [ids] (newest first).
    return [for (final id in ids) ?byId[id]];
  }

  @override
  Future<PlayerDetail> player(String id) => _guard(() async {
    final row = await _client
        .from('profiles')
        .select('$_summaryColumns, bio, country_code, show_level')
        .eq('id', id)
        .single();
    final sports = await _client
        .from('player_sports')
        .select('sport, level, play_min, play_max')
        .eq('user_id', id)
        .order('created_at');
    return PlayerDetail(
      player: PlayerSummary.fromRow(row),
      bio: row['bio'] as String?,
      country: Country.fromCode(row['country_code'] as String?),
      sports: sports.map(PlayerSport.fromJson).toList(),
      social: await social(id),
      showLevel: row['show_level'] as bool? ?? true,
    );
  });

  @override
  Future<PlayerSummary?> byUsername(String username) => _guard(() async {
    final row = await _client
        .from('profiles')
        .select(_summaryColumns)
        .eq('username', username)
        .maybeSingle();
    return row == null ? null : PlayerSummary.fromRow(row);
  });

  @override
  Future<PlayerSocial> social(String id) => _guard(() async {
    final rows =
        await _client.rpc('profile_social', params: {'target': id}) as List;
    final r = rows.first as Map<String, dynamic>;
    return PlayerSocial(
      followers: (r['followers'] as num).toInt(),
      following: (r['following'] as num).toInt(),
      iFollow: r['i_follow'] as bool,
      followsMe: r['follows_me'] as bool,
    );
  });

  @override
  Future<List<PlayerSummary>> followers(String id) => _guard(() async {
    final rows = await _client
        .from('follows')
        .select('follower_id')
        .eq('followee_id', id)
        .order('created_at', ascending: false);
    return _profiles(rows.map((r) => r['follower_id'] as String));
  });

  @override
  Future<List<PlayerSummary>> following(String id) => _guard(() async {
    final rows = await _client
        .from('follows')
        .select('followee_id')
        .eq('follower_id', id)
        .order('created_at', ascending: false);
    return _profiles(rows.map((r) => r['followee_id'] as String));
  });

  @override
  Future<Set<String>> myFollowingIds() => _guard(() async {
    final rows = await _client
        .from('follows')
        .select('followee_id')
        .eq('follower_id', _me);
    return {for (final r in rows) r['followee_id'] as String};
  });

  @override
  Future<void> follow(String id) => _guard(
    () =>
        _client.from('follows').upsert({'follower_id': _me, 'followee_id': id}),
  );

  @override
  Future<void> unfollow(String id) => _guard(
    () => _client
        .from('follows')
        .delete()
        .eq('follower_id', _me)
        .eq('followee_id', id),
  );

  @override
  Future<List<PlayerSummary>> search(String query) => _guard(() async {
    // Strip characters that have meaning in a PostgREST filter.
    final q = query.replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();
    if (q.isEmpty) return const [];
    final rows = await _client
        .from('profiles')
        .select(_summaryColumns)
        .or('username.ilike.%$q%,full_name.ilike.%$q%')
        .neq('id', _me)
        .eq('onboarding_completed', true)
        .limit(20);
    return rows.map(PlayerSummary.fromRow).toList();
  });

  @override
  Future<List<SuggestedPlayer>> suggested() => _guard(() async {
    final rows = await _client.rpc('suggested_players') as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        SuggestedPlayer(
          player: PlayerSummary.fromRow(r),
          level: (r['level'] as num?)?.toDouble(),
          note: '${r['sessions']} sessions',
        ),
    ];
  });

  @override
  Future<List<PlayerSummary>> blocked() => _guard(() async {
    // Blocked profiles are hidden from normal reads, so use the RPC.
    final rows = await _client.rpc('my_blocked_players') as List;
    return rows
        .cast<Map<String, dynamic>>()
        .map(PlayerSummary.fromRow)
        .toList();
  });

  @override
  Future<void> block(String id) => _guard(() async {
    await _client.from('blocks').upsert({'blocker_id': _me, 'blocked_id': id});
    await _client
        .from('follows')
        .delete()
        .eq('follower_id', _me)
        .eq('followee_id', id);
  });

  @override
  Future<void> unblock(String id) => _guard(
    () => _client
        .from('blocks')
        .delete()
        .eq('blocker_id', _me)
        .eq('blocked_id', id),
  );

  @override
  Future<void> report(String id, ReportReason reason) => _guard(
    () => _client.from('player_reports').insert({
      'reporter_id': _me,
      'reported_id': id,
      'reason': reason.id,
    }),
  );

  @override
  Future<List<PlayerSummary>> savedPlayers() => _guard(() async {
    final rows = await _client
        .from('saved_items')
        .select('item_id')
        .eq('user_id', _me)
        .eq('kind', 'player')
        .order('created_at', ascending: false);
    return _profiles(rows.map((r) => r['item_id'] as String));
  });

  @override
  Future<Set<String>> savedIds(SavedKind kind) => _guard(() async {
    final rows = await _client
        .from('saved_items')
        .select('item_id')
        .eq('user_id', _me)
        .eq('kind', kind.name);
    return {for (final r in rows) r['item_id'] as String};
  });

  @override
  Future<void> setSaved(SavedKind kind, String id, bool saved) =>
      _guard(() async {
        final row = {'user_id': _me, 'kind': kind.name, 'item_id': id};
        if (saved) {
          await _client.from('saved_items').upsert(row);
        } else {
          await _client
              .from('saved_items')
              .delete()
              .eq('user_id', _me)
              .eq('kind', kind.name)
              .eq('item_id', id);
        }
      });

  @override
  Future<void> contactSupport(String message) => _guard(
    () => _client.from('support_requests').insert({
      'user_id': _me,
      'message': message,
    }),
  );
}

class DemoSocialRepository implements SocialRepository {
  final _w = DemoWorld.instance;

  Future<void> _tick() => Future.delayed(const Duration(milliseconds: 250));

  List<PlayerSummary> _list(Iterable<String> ids) => [
    for (final id in ids) ?_w.players[id],
  ];

  @override
  Future<PlayerDetail> player(String id) async {
    await _tick();
    return _w.detail(
      id,
      iFollow: _w.following.contains(id),
      followsMe: _w.followers.contains(id),
    );
  }

  @override
  Future<PlayerSummary?> byUsername(String username) async =>
      _w.players.values.where((p) => p.username == username).firstOrNull;

  @override
  Future<PlayerSocial> social(String id) async => id == DemoWorld.me
      ? PlayerSocial(
          followers: _w.followers.length,
          following: _w.following.length,
        )
      : (await player(id)).social;

  @override
  Future<List<PlayerSummary>> followers(String id) async => _list(_w.followers);

  @override
  Future<List<PlayerSummary>> following(String id) async => _list(_w.following);

  @override
  Future<Set<String>> myFollowingIds() async => {..._w.following};

  @override
  Future<void> follow(String id) async => _w.following.add(id);

  @override
  Future<void> unfollow(String id) async => _w.following.remove(id);

  @override
  Future<List<PlayerSummary>> search(String query) async {
    await _tick();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return const [];
    return _w.players.values
        .where((p) => !_w.blocked.contains(p.id))
        .where(
          (p) =>
              p.displayName.toLowerCase().contains(q) ||
              (p.username ?? '').contains(q) ||
              q == 'badminton',
        )
        .take(8)
        .toList();
  }

  @override
  Future<List<SuggestedPlayer>> suggested() async {
    await _tick();
    const people = [
      (
        PlayerSummary(
          id: 'cp-hannah',
          username: 'hannahgoh',
          fullName: 'Hannah Goh',
        ),
        6.2,
        'Hosts 3 Meets a week',
      ),
      (
        PlayerSummary(
          id: 'cp-priyar',
          username: 'priyaraman',
          fullName: 'Priya Raman',
        ),
        5.1,
        '18 sessions',
      ),
      (
        PlayerSummary(
          id: 'cp-sitil',
          username: 'sitilim',
          fullName: 'Siti Lim',
        ),
        5.0,
        '25 sessions',
      ),
      (
        PlayerSummary(
          id: 'cp-meiling',
          username: 'meiling',
          fullName: 'Mei Ling',
        ),
        5.4,
        '12 sessions',
      ),
    ];
    for (final p in people) {
      _w.register(p.$1, badminton: p.$2);
    }
    return [
      for (final p in people)
        if (!_w.following.contains(p.$1.id))
          SuggestedPlayer(player: p.$1, level: p.$2, note: p.$3),
    ];
  }

  @override
  Future<List<PlayerSummary>> blocked() async => _list(_w.blocked);

  @override
  Future<void> block(String id) async {
    _w.blocked.add(id);
    _w.following.remove(id);
  }

  @override
  Future<void> unblock(String id) async => _w.blocked.remove(id);

  @override
  Future<void> report(String id, ReportReason reason) => _tick();

  @override
  Future<List<PlayerSummary>> savedPlayers() async => _list(_w.savedPlayers);

  Set<String> _saved(SavedKind kind) => switch (kind) {
    SavedKind.player => _w.savedPlayers,
    SavedKind.meet => _w.savedMeets,
    SavedKind.club => _w.savedClubs,
  };

  @override
  Future<Set<String>> savedIds(SavedKind kind) async => {..._saved(kind)};

  @override
  Future<void> setSaved(SavedKind kind, String id, bool saved) async =>
      saved ? _saved(kind).add(id) : _saved(kind).remove(id);

  @override
  Future<void> contactSupport(String message) => _tick();
}
