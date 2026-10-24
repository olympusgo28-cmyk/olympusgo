import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../application/social_providers.dart';
import '../domain/social_models.dart';

/// A one-to-one conversation.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  void _markRead() =>
      ref.read(chatRepositoryProvider).markRead(widget.conversationId);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    HapticFeedback.lightImpact();
    _text.clear();
    try {
      await ref.read(chatRepositoryProvider).send(widget.conversationId, body);
    } on AuthFailure catch (e) {
      _text.text = body;
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final mq = MediaQuery.of(context);
    final me = ref.watch(currentUserIdProvider).value;
    final partner = ref.watch(chatPartnerProvider(widget.conversationId)).value;
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));
    ref.listen(
      chatMessagesProvider(widget.conversationId),
      (_, _) => _markRead(),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          math.max(56, mq.padding.top + 4),
          24,
          math.max(24, mq.viewInsets.bottom > 0 ? 12 : mq.padding.bottom + 4),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border, width: 2)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 34, child: OgBackButton()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Pressable(
                      onPressed: partner == null
                          ? null
                          : () => context.push(Routes.player(partner.id)),
                      semanticLabel: partner?.displayName,
                      child: Row(
                        children: [
                          Avatar(
                            initials: partner?.initials ?? '',
                            tone: partner == null
                                ? AvatarTone.green
                                : AvatarTone.forId(partner.id),
                            imageUrl: partner?.avatarUrl,
                            size: 40,
                            fontSize: 15,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  partner?.displayName ?? '',
                                  style: OgText.body(
                                    16,
                                    weight: FontWeight.w600,
                                    color: c.text,
                                  ),
                                ),
                                Text(
                                  partner?.handle ?? '',
                                  style: OgText.body(13, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Pressable(
                    onPressed: partner == null
                        ? null
                        : () => context.push(Routes.reportPlayer(partner.id)),
                    semanticLabel: 'More',
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: OgIcon(OgIcons.more, color: c.text)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (messages) {
                AsyncData(:final value) when value.isEmpty => Center(
                  child: Text(
                    'Say hi to ${partner?.displayName ?? 'them'}.',
                    style: OgText.body(15, color: c.textMuted),
                  ),
                ),
                AsyncData(:final value) => ListView.builder(
                  reverse: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(top: 16, bottom: 4),
                  itemCount: value.length,
                  itemBuilder: (context, i) {
                    final m = value[value.length - 1 - i];
                    final prev = i == value.length - 1
                        ? null
                        : value[value.length - 2 - i];
                    final newDay =
                        prev == null || !_sameDay(prev.createdAt, m.createdAt);
                    return Column(
                      children: [
                        if (newDay)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _dayLabel(m.createdAt),
                              style: OgText.body(13, color: c.textMuted),
                            ),
                          ),
                        _Bubble(message: m, mine: m.senderId == me),
                      ],
                    );
                  },
                ),
                AsyncError() => Center(
                  child: Text(
                    "Can't load messages.",
                    style: OgText.body(15, color: c.textMuted),
                  ),
                ),
                _ => const Center(child: CupertinoActivityIndicator()),
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    minLines: 1,
                    maxLines: 4,
                    style: OgText.body(16, color: c.text),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Message',
                      hintStyle: OgText.body(16, color: c.textMuted),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(
                          color: c.borderControl,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(color: c.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onPressed: _send,
                  semanticLabel: 'Send',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: OgIcon(OgIcons.send, color: c.onPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return 'Today';
    if (_sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 270),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? c.primary : c.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 6),
            bottomRight: Radius.circular(mine ? 6 : 20),
          ),
        ),
        child: Text(
          message.body,
          style: OgText.body(
            16,
            height: 1.35,
            color: mine ? c.onPrimary : c.text,
          ),
        ),
      ),
    );
  }
}

/// Relative time for the Inbox: "2m", "1h", "Yesterday", "Sat".
String inboxTime(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 2) return 'Yesterday';
  if (diff.inDays < 7) {
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][at.weekday -
        1];
  }
  return '${at.day}/${at.month}';
}
