// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  username: json['username'] as String?,
  fullName: json['full_name'] as String?,
  bio: json['bio'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'full_name': instance.fullName,
  'bio': instance.bio,
  'avatar_url': instance.avatarUrl,
  'onboarding_completed': instance.onboardingCompleted,
};

_PlayerSport _$PlayerSportFromJson(Map<String, dynamic> json) => _PlayerSport(
  sport: json['sport'] as String,
  level: (json['level'] as num).toDouble(),
  playMin: (json['play_min'] as num).toDouble(),
  playMax: (json['play_max'] as num).toDouble(),
);

Map<String, dynamic> _$PlayerSportToJson(_PlayerSport instance) =>
    <String, dynamic>{
      'sport': instance.sport,
      'level': instance.level,
      'play_min': instance.playMin,
      'play_max': instance.playMax,
    };
