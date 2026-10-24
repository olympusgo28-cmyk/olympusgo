import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/country.dart';
import '../../profile/domain/profile.dart';

part 'social_models.freezed.dart';

/// Enough about a player to show them in a list.
@freezed
abstract class PlayerSummary with _$PlayerSummary {
  const factory PlayerSummary({
    required String id,
    String? username,
    String? fullName,
    String? avatarUrl,
  }) = _PlayerSummary;

  const PlayerSummary._();

  factory PlayerSummary.fromRow(Map<String, dynamic> row) => PlayerSummary(
    id: row['id'] as String,
    username: row['username'] as String?,
    fullName: row['full_name'] as String?,
    avatarUrl: row['avatar_url'] as String?,
  );

  String get displayName => fullName ?? username ?? 'Player';
  String get handle => username == null ? '' : '@$username';

  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// Follower counts and the follow relationship with the viewer.
@freezed
abstract class PlayerSocial with _$PlayerSocial {
  const factory PlayerSocial({
    @Default(0) int followers,
    @Default(0) int following,
    @Default(false) bool iFollow,
    @Default(false) bool followsMe,
  }) = _PlayerSocial;
}

/// Everything shown on another player's profile.
@freezed
abstract class PlayerDetail with _$PlayerDetail {
  const factory PlayerDetail({
    required PlayerSummary player,
    String? bio,
    @Default(Country.singapore) Country country,
    @Default([]) List<PlayerSport> sports,
    @Default(PlayerSocial()) PlayerSocial social,
    @Default(0) int played,
    @Default(true) bool showLevel,
  }) = _PlayerDetail;
}

/// A player worth following, with their level and a line about them.
@freezed
abstract class SuggestedPlayer with _$SuggestedPlayer {
  const factory SuggestedPlayer({
    required PlayerSummary player,
    double? level,
    @Default('') String note,
  }) = _SuggestedPlayer;
}

enum ReportReason {
  spam('spam', 'Spam or fake account'),
  harassment('harassment', 'Harassment or bullying'),
  inappropriate('inappropriate', 'Inappropriate photos or messages'),
  cheating('cheating', 'Cheating or false scores'),
  other('other', 'Something else');

  const ReportReason(this.id, this.label);
  final String id;
  final String label;
}

enum SavedKind { meet, player, club }

/// A one-to-one conversation in the Inbox.
@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required PlayerSummary other,
    String? lastBody,
    DateTime? lastAt,
    @Default(false) bool unread,
  }) = _Conversation;
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String senderId,
    required String body,
    required DateTime createdAt,
  }) = _ChatMessage;
}
