import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/pressable.dart';
import '../../clubs/application/club_providers.dart';
import '../../shell/main_shell.dart';
import '../../social/application/social_providers.dart';
import '../application/inbox_providers.dart';
import '../domain/inbox_models.dart';

/// "9:15 AM" today, "Yesterday", "Thu" this week, else "3 Oct".
String inboxStamp(DateTime at) {
  final now = DateTime.now();
  final days = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;
  if (days <= 0) return Fmt.time(at);
  if (days == 1) return 'Yesterday';
  if (days < 7) {
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][at.weekday -
        1];
  }
  return Fmt.day(at).split(' ').skip(1).join(' ');
}

enum _Show { all, chats, updates }

/// Inbox: club, team and direct chats, then updates.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  _Show _show = _Show.all;

  Future<void> _refresh() async {
    ref.invalidate(inboxUpdatesProvider);
    ref.invalidate(conversationsProvider);
    ref.invalidate(clubListProvider);
    ref.invalidate(teamListProvider);
  }

  Future<void> _markAllRead() async {
    HapticFeedback.selectionClick();
    await ref.read(updatesRepositoryProvider).markAllRead();
    ref.invalidate(inboxUpdatesProvider);
  }

  Future<void> _open(InboxUpdate u) async {
    if (!u.read) {
      await ref.read(updatesRepositoryProvider).markRead(u.id);
      ref.invalidate(inboxUpdatesProvider);
    }
    if (u.link != null && mounted) context.push(u.link!);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final chats = ref.watch(inboxChatsProvider);
    final updates = ref.watch(inboxUpdatesProvider);
    final anyUnread = updates.value?.any((u) => !u.read) ?? false;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, top + 14, 16, 12),
            decoration: BoxDecoration(
              color: c.bg,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text('Inbox', style: OgText.heading(24)),
                ),
                const SizedBox(height: 12),
                KitSegments(
                  labels: const ['All', 'Chats', 'Updates'],
                  selected: _show.index,
                  onSelect: (i) => setState(() => _show = _Show.values[i]),
                  height: 40,
                  radius: 20,
                  fontSize: 14,
                  track: t.track,
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: _refresh),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    24 + MainTabBar.reservedHeight(context),
                  ),
                  sliver: SliverList.list(
                    children: kitSpaced([
                      if (_show != _Show.updates)
                        _Section(
                          title: 'Chats',
                          children: [
                            if (chats.isEmpty)
                              const _Empty(
                                "No chats yet. Join a club, or open a player's "
                                'profile and tap Message.',
                              ),
                            for (final chat in chats) _ChatRow(chat),
                          ],
                        ),
                      if (_show != _Show.chats)
                        _Section(
                          title: 'Updates',
                          action: KitLink(
                            anyUnread ? 'Mark all read' : 'All read',
                            color: c.text,
                            onPressed: anyUnread ? _markAllRead : null,
                          ),
                          children: switch (updates) {
                            AsyncData(:final value) when value.isEmpty => [
                              const _Empty(
                                'Nothing new. Updates about your Meets, clubs '
                                'and points land here.',
                              ),
                            ],
                            AsyncData(:final value) => [
                              for (final u in value)
                                _UpdateRow(u, onTap: () => _open(u)),
                            ],
                            AsyncError() => [
                              const _Empty(
                                "Updates couldn't load. Pull down to try "
                                'again.',
                              ),
                            ],
                            _ => [
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: CupertinoActivityIndicator(),
                              ),
                            ],
                          },
                        ),
                    ], 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.action});

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: OgText.display(18, height: 1.2, color: c.text),
                ),
              ),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: i < children.length - 1
                        ? Border(bottom: BorderSide(color: t.divider))
                        : null,
                  ),
                  child: children[i],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: OgText.body(14, height: 1.45, color: context.og.textMuted),
      ),
    );
  }
}

/// 48pt initials tile: round for people, rounded square for groups.
class _Mark extends StatelessWidget {
  const _Mark({
    required this.mark,
    required this.color,
    required this.ink,
    this.square = false,
  });

  final String mark;
  final Color color;
  final Color ink;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(square ? 14 : 24),
      ),
      alignment: Alignment.center,
      child: Text(
        mark,
        style: OgText.body(14, weight: FontWeight.w800, color: ink),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow(this.chat);

  final InboxChat chat;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final unread = chat.unread > 0 || chat.unreadDot;
    return Pressable(
      semanticLabel: [
        chat.title,
        if (chat.unread > 0) '${chat.unread} unread',
        if (chat.unreadDot) 'unread',
        ?chat.preview,
        if (chat.at != null) inboxStamp(chat.at!),
      ].join('. '),
      onPressed: () => context.push(chat.route),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            _Mark(
              mark: chat.mark,
              color: chat.color,
              ink: chat.ink,
              square: chat.square,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.preview ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(
                      13,
                      weight: unread ? FontWeight.w600 : FontWeight.w400,
                      color: unread ? c.text : c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (chat.at != null)
                  Text(
                    inboxStamp(chat.at!),
                    style: OgText.body(12, color: c.textMuted),
                  ),
                if (unread) ...[
                  const SizedBox(height: 4),
                  chat.unread > 0
                      ? KitCountBadge(chat.unread, size: 20)
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: t.badge,
                            shape: BoxShape.circle,
                          ),
                        ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow(this.update, {required this.onTap});

  final InboxUpdate update;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final u = update;
    return Pressable(
      semanticLabel: [
        u.title,
        if (!u.read) 'unread',
        if (u.body.isNotEmpty) u.body,
        inboxStamp(u.at),
      ].join('. '),
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _Mark(
              mark: u.mark,
              color: Color(u.color),
              ink: Color(u.ink),
              square: u.square,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.title,
                    style: OgText.body(15, weight: FontWeight.w700),
                  ),
                  if (u.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      u.body,
                      style: OgText.body(13, height: 1.35, color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  inboxStamp(u.at),
                  style: OgText.body(12, color: c.textMuted),
                ),
                if (!u.read) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: OgColors.tangerine,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
