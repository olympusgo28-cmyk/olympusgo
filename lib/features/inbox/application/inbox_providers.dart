import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../clubs/application/club_providers.dart';
import '../../clubs/data/club_repository.dart';

import 'dart:ui' show Color;

import '../../../core/widgets/og_kit.dart';
import '../../../core/router/routes.dart';
import '../../social/application/social_providers.dart';
import '../domain/inbox_models.dart';

part 'inbox_providers.g.dart';

@riverpod
Future<List<InboxUpdate>> inboxUpdates(Ref ref) async {
  final me = await ref.watch(currentUserIdProvider.future);
  if (me == null) return const [];
  return ref.watch(updatesRepositoryProvider).updates();
}

/// Club, team and direct chats, newest first.
@riverpod
List<InboxChat> inboxChats(Ref ref) {
  final clubs = ref.watch(clubListProvider(ClubTab.mine)).value ?? const [];
  final teams = ref.watch(teamListProvider(ClubTab.mine)).value ?? const [];
  final dms = ref.watch(conversationsProvider).value ?? const [];
  String? preview(ChatScope scope) {
    final last = ref.watch(groupChatProvider(scope)).value?.lastOrNull;
    if (last == null) return null;
    final body = last.removed
        ? 'Message removed'
        : last.meet != null
        ? 'Shared ${last.meet!.title}'
        : last.photo != null
        ? 'Sent a photo'
        : last.body;
    return '${last.sender.displayName}: $body';
  }

  DateTime? at(ChatScope scope) =>
      ref.watch(groupChatProvider(scope)).value?.lastOrNull?.at;
  final chats = [
    for (final item in clubs)
      InboxChat(
        title: item.club.name,
        mark: item.club.initials,
        route: Routes.clubChat(item.club.id),
        preview: preview(ChatScope.club(item.club.id)),
        at: at(ChatScope.club(item.club.id)),
        unread: item.club.unreadChat,
        square: true,
        color: Color(item.club.logoColor),
        ink: Color(item.club.logoInk),
      ),
    for (final item in teams)
      InboxChat(
        title: item.team.name,
        mark: item.team.mark,
        route: Routes.teamChat(item.team.id),
        preview: preview(ChatScope.team(item.team.id)),
        at: at(ChatScope.team(item.team.id)),
        unread: item.team.unreadChat,
        square: true,
        color: Color(item.team.logoColor),
        ink: Color(item.team.logoInk),
      ),
    for (final m in dms)
      InboxChat(
        title: m.other.displayName,
        mark: m.other.initials,
        route: Routes.chat(m.id),
        preview: m.lastBody,
        at: m.lastAt,
        unreadDot: m.unread,
        color: Faces.forId(m.other.id).$1,
        ink: Faces.forId(m.other.id).$2,
      ),
  ];
  final epoch = DateTime(2000);
  chats.sort((a, b) => (b.at ?? epoch).compareTo(a.at ?? epoch));
  return chats;
}

/// The Inbox tab badge: chats with something new plus unread updates.
@riverpod
int inboxUnread(Ref ref) {
  final chats = ref
      .watch(inboxChatsProvider)
      .where((c) => c.unread > 0 || c.unreadDot)
      .length;
  final updates =
      ref.watch(inboxUpdatesProvider).value?.where((u) => !u.read).length ?? 0;
  return chats + updates;
}
