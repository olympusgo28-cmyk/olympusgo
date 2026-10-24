import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// A player's public profile (`public.profiles`).
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    String? username,
    @JsonKey(name: 'full_name') String? fullName,
    String? bio,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'onboarding_completed')
    @Default(false)
    bool onboardingCompleted,
  }) = _Profile;

  const Profile._();

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  String get firstName => (fullName ?? '').trim().split(' ').first;

  String get initials {
    final parts = (fullName ?? username ?? '?')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// A sport on a player's Passport (`public.player_sports`).
@freezed
abstract class PlayerSport with _$PlayerSport {
  const factory PlayerSport({
    required String sport,
    required double level,
    @JsonKey(name: 'play_min') required double playMin,
    @JsonKey(name: 'play_max') required double playMax,
  }) = _PlayerSport;

  factory PlayerSport.fromJson(Map<String, dynamic> json) =>
      _$PlayerSportFromJson(json);
}

/// A badge on the Profile ("40 sessions", "8-week streak").
@freezed
abstract class ProfileBadge with _$ProfileBadge {
  const factory ProfileBadge({
    required String mark,
    required String name,
    @Default(0xFFFFE8CC) int color,
    @Default(0xFF7A3B00) int ink,
  }) = _ProfileBadge;
}

/// The numbers and highlights on a player's own Profile.
@freezed
abstract class ProfileSummary with _$ProfileSummary {
  const factory ProfileSummary({
    /// Past sessions played.
    @Default(0) int sessions,

    /// Rank in their best club's leaderboard, when they have one.
    int? clubRank,

    /// Rank among players nearby, and where.
    int? localRank,
    String? area,
    @Default([]) List<ProfileBadge> badges,

    /// All badges earned; [badges] holds the latest few.
    @Default(0) int badgeCount,

    /// Who sees their next sessions: "Circle", "Followers", "Only me".
    @Default('Followers') String sessionsShownTo,
  }) = _ProfileSummary;
}
