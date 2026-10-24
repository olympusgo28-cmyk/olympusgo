import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../auth/data/auth_repository.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../domain/profile.dart';

abstract interface class ProfileRepository {
  Future<Profile?> fetch(String userId);
  Future<List<PlayerSport>> sports(String userId);
  Future<bool> usernameAvailable(String username);

  /// Session count, ranks and badges for the Profile tab.
  Future<ProfileSummary> summary(String userId);

  /// Replaces the player's Passport sports and their own levels.
  Future<void> saveSports(String userId, List<PlayerSport> sports);

  /// Saves the onboarding answers. [complete] marks onboarding done.
  Future<void> saveOnboarding(
    String userId,
    OnboardingDraft draft, {
    required bool complete,
  });
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);
  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Profile error: ${e.code} ${e.message}');
      if (e.code == '23505') {
        throw const AuthFailure(
          'That username was just taken. Try another one.',
        );
      }
      if (e.code == '23514' && e.message.contains('birthday')) {
        throw AuthFailure(e.message);
      }
      throw const AuthFailure(
        'Something went wrong saving your details. Try again.',
      );
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  @override
  Future<Profile?> fetch(String userId) => _guard(() async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  });

  @override
  Future<List<PlayerSport>> sports(String userId) => _guard(() async {
    final rows = await _client
        .from('player_sports')
        .select('sport, level, play_min, play_max')
        .eq('user_id', userId)
        .order('created_at');
    return rows.map(PlayerSport.fromJson).toList();
  });

  @override
  Future<void> saveSports(String userId, List<PlayerSport> sports) =>
      _guard(() async {
        final keep = [for (final s in sports) s.sport];
        await _client
            .from('player_sports')
            .delete()
            .eq('user_id', userId)
            .not('sport', 'in', '(${keep.join(',')})');
        if (sports.isEmpty) return;
        await _client.from('player_sports').upsert([
          for (final s in sports)
            {
              'user_id': userId,
              'sport': s.sport,
              'level': s.level,
              'play_min': s.playMin,
              'play_max': s.playMax,
            },
        ]);
      });

  @override
  Future<ProfileSummary> summary(String userId) => _guard(() async {
    // Ranks, areas and badges arrive with leaderboards; sessions are real.
    final played = await _client
        .from('activity_participants')
        .select('activity_id, activities!inner(starts_at)')
        .eq('user_id', userId)
        .eq('status', 'joined')
        .lt('activities.starts_at', DateTime.now().toUtc().toIso8601String())
        .count(CountOption.exact);
    return ProfileSummary(sessions: played.count);
  });

  @override
  Future<bool> usernameAvailable(String username) => _guard(() async {
    final res = await _client.rpc(
      'username_available',
      params: {'name': username},
    );
    return res == true;
  });

  @override
  Future<void> saveOnboarding(
    String userId,
    OnboardingDraft d, {
    required bool complete,
  }) => _guard(() async {
    await _client
        .from('profiles')
        .update({
          'full_name': d.fullName.trim(),
          if (d.username.isNotEmpty) 'username': d.username,
          'onboarding_completed': complete,
        })
        .eq('id', userId);

    final private = await _client
        .from('account_private')
        .select('birthday')
        .eq('id', userId)
        .single();
    await _client
        .from('account_private')
        .update({
          // Birthday is locked once saved; only send it the first time.
          if (private['birthday'] == null && d.birthday != null)
            'birthday': d.birthday!.toIso8601String().substring(0, 10),
          'country_code': d.country.code,
          // Blank means no parent; the column takes an address or nothing.
          'parent_email': (d.parentEmail?.trim().isEmpty ?? true)
              ? null
              : d.parentEmail!.trim(),
        })
        .eq('id', userId);

    final chosen = d.sports.map((s) => s.id).toList();
    await _client
        .from('player_sports')
        .delete()
        .eq('user_id', userId)
        .not('sport', 'in', '(${chosen.join(',')})');
    await _client.from('player_sports').upsert([
      for (final s in d.sports)
        {
          'user_id': userId,
          'sport': s.id,
          'level': d.skillFor(s).level,
          'play_min': d.skillFor(s).playMin,
          'play_max': d.skillFor(s).playMax,
        },
    ]);
  });
}

/// In-memory profile store for demo mode.
class DemoProfileRepository implements ProfileRepository {
  /// The demo player's profile; settings screens edit it in place.
  Profile? profile = Env.demoSignedIn
      ? const Profile(
          id: '00000000-0000-0000-0000-000000000001',
          username: 'aaronng',
          fullName: 'Aaron Ng',
          bio: 'Doubles on weeknights. Happy to rotate with beginners.',
          onboardingCompleted: true,
        )
      : null;

  Profile? get _profile => profile;
  set _profile(Profile? value) => profile = value;
  List<PlayerSport> _sports = Env.demoSignedIn
      ? const [
          PlayerSport(
            sport: 'badminton',
            level: 5.4,
            playMin: 4.0,
            playMax: 6.5,
          ),
          PlayerSport(
            sport: 'pickleball',
            level: 3.0,
            playMin: 2.5,
            playMax: 4.0,
          ),
        ]
      : const [];

  @override
  Future<Profile?> fetch(String userId) async =>
      _profile ?? Profile(id: userId);

  @override
  Future<List<PlayerSport>> sports(String userId) async => _sports;

  @override
  Future<void> saveSports(String userId, List<PlayerSport> sports) async =>
      _sports = sports;

  @override
  Future<ProfileSummary> summary(String userId) async => const ProfileSummary(
    sessions: 43,
    clubRank: 4,
    localRank: 12,
    area: 'Tampines',
    badgeCount: 6,
    sessionsShownTo: 'Circle',
    badges: [
      ProfileBadge(mark: '40', name: '40 sessions'),
      ProfileBadge(
        mark: 'QF',
        name: 'Quarter-finalist, Bedok Open',
        color: 0xFFFBE7B0,
        ink: 0xFF5A4300,
      ),
      ProfileBadge(
        mark: 'TS',
        name: 'Top supporter',
        color: 0xFFF6DFD8,
        ink: 0xFF8A2E1C,
      ),
      ProfileBadge(
        mark: '8w',
        name: '8-week streak',
        color: 0xFFDCEEE6,
        ink: 0xFF0A4F3A,
      ),
    ],
  );

  @override
  Future<bool> usernameAvailable(String username) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return RegExp(r'^[A-Za-z0-9_]{3,30}$').hasMatch(username) &&
        !{'admin', 'olympusgo', 'maya_tan'}.contains(username.toLowerCase());
  }

  @override
  Future<void> saveOnboarding(
    String userId,
    OnboardingDraft d, {
    required bool complete,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _profile = Profile(
      id: userId,
      fullName: d.fullName.trim(),
      username: d.username.isEmpty ? null : d.username,
      onboardingCompleted: complete,
    );
    _sports = [
      for (final s in d.sports)
        PlayerSport(
          sport: s.id,
          level: d.skillFor(s).level,
          playMin: d.skillFor(s).playMin,
          playMax: d.skillFor(s).playMax,
        ),
    ];
  }
}
