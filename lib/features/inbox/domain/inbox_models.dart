import 'dart:ui' show Color;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'inbox_models.freezed.dart';

/// A notification in the Inbox's Updates list (`public.notifications`).
@freezed
abstract class InboxUpdate with _$InboxUpdate {
  const factory InboxUpdate({
    required String id,
    required String title,
    @Default('') String body,

    /// Two letters (or "!") on the round tile.
    required String mark,
    @Default(0xFF16181B) int color,
    @Default(0xFFC6FF00) int ink,

    /// A square tile, for academies and clubs.
    @Default(false) bool square,

    /// App path the row opens, e.g. `/activities/t-open`.
    String? link,
    required DateTime at,
    @Default(false) bool read,
  }) = _InboxUpdate;
}

/// A club, team or direct chat in the Inbox's Chats list.
class InboxChat {
  const InboxChat({
    required this.title,
    required this.mark,
    required this.route,
    this.preview,
    this.at,
    this.unread = 0,
    this.unreadDot = false,
    this.square = false,
    required this.color,
    required this.ink,
  });

  final String title;
  final String mark;
  final String route;

  /// "Kelvin Ho: Hi all…", or null before the first message.
  final String? preview;
  final DateTime? at;
  final int unread;

  /// Direct chats only know whether something is new, not how much.
  final bool unreadDot;

  /// Square tiles for clubs and teams, round ones for players.
  final bool square;
  final Color color;
  final Color ink;
}
