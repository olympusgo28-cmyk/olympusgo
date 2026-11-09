import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/share.dart';
import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../../profile/domain/profile.dart';
import 'settings_models.dart';

part 'my_profile.freezed.dart';

/// What Edit profile shows: the player's own public details and sports.
@freezed
abstract class MyProfile with _$MyProfile {
  const MyProfile._();

  const factory MyProfile({
    @Default('') String fullName,
    @Default('') String username,
    @Default('') String bio,
    @Default(Gender.preferNotToSay) Gender gender,
    String? avatarUrl,
    @Default(<PlayerSport>[]) List<PlayerSport> sports,
  }) = _MyProfile;

  factory MyProfile.from(AccountDetails d, List<PlayerSport> sports) =>
      MyProfile(
        fullName: d.fullName,
        username: d.username,
        bio: d.bio,
        gender: d.gender,
        avatarUrl: d.avatarUrl,
        sports: sports,
      );

  /// The bio's first line, for its row.
  String get bioFirstLine => bio.trim().split('\n').first.trim();

  /// "Badminton, Pickleball".
  String get sportsText =>
      sports.map((s) => Sport.fromId(s.sport).label).join(', ');

  /// "Badminton MB · Pickleball LI".
  String get levelsText => sports
      .map(
        (s) =>
            '${Sport.fromId(s.sport).label} '
            '${SkillBand.forLevel(s.level).code}',
      )
      .join(' · ');

  /// The profile's share link, or null without a username.
  String? get link => username.isEmpty ? null : Links.player(username);

  /// [link] as shown: "olympusgo.com/nicholasong".
  String? get linkText => link?.replaceFirst(RegExp('^https?://'), '');

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// No personal details, should this ever reach a log (golden rule 8).
  @override
  String toString() => 'MyProfile(sports: ${sports.length})';
}
