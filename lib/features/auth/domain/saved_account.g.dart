// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedAccount _$SavedAccountFromJson(Map<String, dynamic> json) =>
    _SavedAccount(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      maskedIdentifier: json['maskedIdentifier'] as String,
    );

Map<String, dynamic> _$SavedAccountToJson(_SavedAccount instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'maskedIdentifier': instance.maskedIdentifier,
    };
