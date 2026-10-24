import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../play/application/play_providers.dart';
import '../../shop/application/shop_providers.dart';
import '../application/club_providers.dart';
import '../data/club_repository.dart';
import '../domain/club_models.dart';
import 'club_widgets.dart';

/// Club chat or team chat: a pinned note, messages and the composer.
class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({super.key, required this.scope});

  final ChatScope scope;

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  var _more = false;

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  ClubRepository get _repo => ref.read(clubRepositoryProvider);

  Future<void> _send() async {
    final text = _draft.text.trim();
    if (text.isEmpty) return;
    _draft.clear();
    HapticFeedback.lightImpact();
    try {
      await _repo.send(widget.scope, text);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _photo() async {
    setState(() => _more = false);
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    try {
      await _repo.sendPhoto(widget.scope, file.path);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _shareMeet() async {
    setState(() => _more = false);
    if (widget.scope.isTeam) {
      final fixtureId = await ref.read(
        nextFixtureIdProvider(widget.scope.id).future,
      );
      if (fixtureId == null) {
        if (mounted) showOgToast(context, 'No fixture to share yet.');
        return;
      }
      final f = await ref.read(fixtureProvider(fixtureId).future);
      await _repo.send(
        widget.scope,
        'Shared the lineup for ${Fmt.day(f.startsAt)}',
      );
      return;
    }
    final sessions = await ref.read(
      clubSessionsProvider(widget.scope.id).future,
    );
    if (!mounted) return;
    if (sessions.isEmpty) {
      showOgToast(context, 'No upcoming Meets to share.');
      return;
    }
    final picked = await showKitSheet<String>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share a Meet', style: OgText.heading(26)),
          const SizedBox(height: 12),
          for (final s in sessions)
            KitNavTile(
              icon: OgIcons.calendarBox,
              title: s.title,
              subtitle: Fmt.dayTimeRange(s.startsAt, s.endsAt),
              padding: EdgeInsets.zero,
              ruleAbove: true,
              onTap: () => Navigator.of(context).pop(s.id),
            ),
        ],
      ),
    );
    if (picked != null) await _repo.send(widget.scope, '', activityId: picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final messages = ref.watch(groupChatProvider(widget.scope));
    final me = ref.watch(currentUserIdProvider).value;
    final header = widget.scope.isTeam
        ? _teamHeader(context)
        : _clubHeader(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            header,
            _Pinned(team: widget.scope.isTeam),
            Expanded(
              child: switch (messages) {
                AsyncData(:final value) => _Thread(
                  messages: value,
                  me: me,
                  scope: widget.scope,
                  controller: _scroll,
                ),
                AsyncError() => const Padding(
                  padding: EdgeInsets.all(16),
                  child: OgErrorText("Chat isn't loading. Try again."),
                ),
                _ => const Center(child: CupertinoActivityIndicator()),
              },
            ),
            if (_more)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                decoration: BoxDecoration(
                  color: c.bg,
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    KitChip(
                      label: widget.scope.isTeam
                          ? 'Share the lineup'
                          : 'Share a Meet',
                      height: 44,
                      onTap: _shareMeet,
                    ),
                    KitChip(label: 'Photo', height: 44, onTap: _photo),
                  ],
                ),
              ),
            _composer(context),
          ],
        ),
      ),
    );
  }

  Widget _clubHeader(BuildContext context) {
    final c = context.og;
    final club = ref.watch(clubProvider(widget.scope.id)).value;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          const KitBack(),
          const SizedBox(width: 10),
          if (club != null) ...[
            ClubMark(club, size: 40, radius: 12, fontSize: 15),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  club?.name ?? 'Club chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OgText.display(17, color: c.text),
                ),
                if (club != null)
                  Text(
                    '${club.memberCount} members',
                    style: OgText.body(13, color: c.textMuted),
                  ),
              ],
            ),
          ),
          KitIconButton(
            icon: OgIcons.dotsVertical,
            label: 'Chat settings',
            onPressed: () => club != null && club.canManage
                ? context.push(Routes.clubModeration(club.id))
                : context.push(Routes.notifications),
          ),
        ],
      ),
    );
  }

  Widget _teamHeader(BuildContext context) {
    final c = context.og;
    final team = ref.watch(teamProvider(widget.scope.id)).value;
    final members = ref.watch(teamMembersProvider(widget.scope.id)).value;
    final players = members?.where((m) => !m.staff).length ?? 0;
    final staff = members?.where((m) => m.staff).length ?? 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          const KitBack(),
          const SizedBox(width: 10),
          if (team != null) ...[
            TeamMark(team, size: 40, radius: 12, fontSize: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team?.name ?? 'Team chat',
                  style: OgText.display(17, color: c.text),
                ),
                Text(
                  'Team chat · $players players, $staff staff',
                  style: OgText.body(13, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final name = widget.scope.isTeam
        ? ref.watch(teamProvider(widget.scope.id)).value?.name
        : ref.watch(clubProvider(widget.scope.id)).value?.name;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          KitIconButton(
            icon: OgIcons.plus,
            label: widget.scope.isTeam
                ? 'Share lineup or photo'
                : 'Share a Meet or photo',
            size: 20,
            strokeWidth: 2.2,
            background: t.tag,
            onPressed: () => setState(() => _more = !_more),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: c.border),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _draft,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                style: OgText.body(15, color: c.text),
                cursorColor: c.primary,
                decoration: InputDecoration(
                  hintText: 'Message ${name ?? ''}'.trim(),
                  hintStyle: OgText.body(15, color: c.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          KitIconButton(
            icon: OgIcons.paperPlane,
            label: 'Send',
            size: 20,
            background: c.primary,
            color: c.onPrimary,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}

class _Pinned extends StatelessWidget {
  const _Pinned({required this.team});

  final bool team;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          OgIcon(
            team ? OgIcons.shieldPlain : OgIcons.thumbtack,
            size: 18,
            color: const Color(0xFFB9832A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: team
                ? Text(
                    'This chat is only for the team. Staff can see all messages, and there are no private messages between adults and students.',
                    style: OgText.body(13, color: context.tones.onTag),
                  )
                : Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Pinned: ',
                          style: OgText.body(
                            13,
                            weight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                        const TextSpan(
                          text: 'Your organizer marks attendance at each Meet. Present players get Passport credit and points.',
                        ),
                      ],
                    ),
                    style: OgText.body(13, color: context.tones.onTag),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({
    required this.messages,
    required this.me,
    required this.scope,
    required this.controller,
  });

  final List<GroupMessage> messages;
  final String? me;
  final ChatScope scope;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final items = <Widget>[];
    String? lastDay;
    for (final m in messages) {
      final day = dayLabel(m.at);
      if (day != lastDay) {
        lastDay = day;
        items.add(
          Row(
            children: [
              Expanded(child: Container(height: 1, color: c.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  day,
                  style: OgText.body(
                    12,
                    weight: FontWeight.w600,
                    color: const Color(0xFF7A8087),
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: c.border)),
            ],
          ),
        );
      }
      items.add(
        m.kind == MessageKind.system
            ? Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: t.track,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(m.body, style: OgText.body(13, color: t.onTag)),
                ),
              )
            : m.sender.id == me
            ? _Mine(message: m)
            : _Theirs(message: m, scope: scope),
      );
    }
    return ListView(
      controller: controller,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      children: [for (final w in kitSpaced(items, 14).reversed) w],
    );
  }
}

String _clock(DateTime at) => Fmt.time(at);

class _Theirs extends StatelessWidget {
  const _Theirs({required this.message, required this.scope});

  final GroupMessage message;
  final ChatScope scope;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final m = message;
    final roleColor = m.roleColor == null ? null : Color(m.roleColor!);
    return Padding(
      padding: const EdgeInsets.only(right: 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlayerFace(m.sender, size: 34),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        m.sender.displayName,
                        style: OgText.body(
                          14,
                          weight: FontWeight.w600,
                          color: m.roleName != null && roleColor != null
                              ? roleColor
                              : c.text,
                        ),
                      ),
                    ),
                    if (m.roleName != null && roleColor != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: roleColor),
                        ),
                        child: Text(
                          m.roleName!,
                          style: OgText.body(
                            11,
                            weight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      _clock(m.at),
                      style: OgText.body(12, color: const Color(0xFF7A8087)),
                    ),
                    if (!m.removed)
                      KitIconButton(
                        icon: OgIcons.flag,
                        label: 'Report this message',
                        size: 16,
                        color: c.borderControl,
                        onPressed: () => context.push(
                          scope.isTeam
                              ? Routes.reportTeamMessage(scope.id, m.id)
                              : Routes.reportClubMessage(scope.id, m.id),
                        ),
                      ),
                  ],
                ),
                if (m.removed)
                  _bubble(
                    context,
                    Text(
                      'Removed by an organizer',
                      style: OgText.body(
                        14,
                        color: c.textMuted,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                    fill: t.soft,
                  )
                else ...[
                  if (m.body.isNotEmpty)
                    _bubble(
                      context,
                      Text(m.body, style: OgText.body(15, height: 1.4)),
                    ),
                  if (m.photo != null) _PhotoBubble(path: m.photo!),
                  if (m.meet != null) _MeetBubble(meet: m.meet!),
                  if (m.kind == MessageKind.lineup && scope.isTeam)
                    _LineupBubble(teamId: scope.id),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, Widget child, {Color? fill}) =>
      Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: fill ?? context.og.bg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: fill == null ? Border.all(color: context.og.border) : null,
        ),
        child: child,
      );
}

class _Mine extends StatelessWidget {
  const _Mine({required this.message});

  final GroupMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final m = message;
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (m.removed)
            Text(
              'Removed by an organizer',
              style: OgText.body(
                14,
                color: c.textMuted,
              ).copyWith(fontStyle: FontStyle.italic),
            )
          else if (m.photo != null)
            _PhotoBubble(path: m.photo!)
          else if (m.meet != null)
            _MeetBubble(meet: m.meet!)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                m.body,
                style: OgText.body(15, height: 1.4, color: c.onPrimary),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            _clock(m.at),
            style: OgText.body(12, color: const Color(0xFF7A8087)),
          ),
        ],
      ),
    );
  }
}

class _PhotoBubble extends StatelessWidget {
  const _PhotoBubble({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final image = path.startsWith('http')
        ? Image.network(path, width: 220, fit: BoxFit.cover)
        : Image.file(File(path), width: 220, fit: BoxFit.cover);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 280),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Semantics(label: 'Photo', image: true, child: image),
      ),
    );
  }
}

class _MeetBubble extends StatelessWidget {
  const _MeetBubble({required this.meet});

  final SharedMeet meet;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    const dows = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Container(
      width: 250,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: c.inverseCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      dows[meet.startsAt.weekday - 1],
                      style: OgText.body(
                        10,
                        weight: FontWeight.w600,
                        color: context.tones.gold,
                      ),
                    ),
                    Text(
                      '${meet.startsAt.day}',
                      style: OgText.display(
                        18,
                        height: 1,
                        color: c.onInverseCard,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meet.title,
                      style: OgText.body(15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meet.detail,
                      style: OgText.body(13, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          KitButton(
            label: 'Join Meet',
            height: 40,
            radius: 20,
            fontSize: 14,
            onPressed: () => context.push(Routes.activity(meet.activityId)),
          ),
        ],
      ),
    );
  }
}

class _LineupBubble extends ConsumerWidget {
  const _LineupBubble({required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final fixtureId = ref.watch(nextFixtureIdProvider(teamId)).value;
    final fixture = fixtureId == null
        ? null
        : ref.watch(fixtureProvider(fixtureId)).value;
    if (fixture == null) return const SizedBox.shrink();
    final singles = fixture.slots.where((s) => s.kind == 'S').length;
    final doubles = fixture.slots.where((s) => s.kind == 'D').length;
    final reserves = fixture.slots
        .where((s) => s.isReserve)
        .fold(0, (n, s) => n + s.size);
    return Pressable(
      semanticLabel: 'Lineup, view lineup',
      onPressed: () => context.push(Routes.teamRoster(teamId)),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.tones.infoFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OgIcon(
                  OgIcons.clipboardList,
                  size: 18,
                  strokeWidth: 1.9,
                  color: context.tones.onInfoFill,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Lineup · vs ${fixture.opponent}',
                    style: OgText.body(14, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${Fmt.day(fixture.startsAt)} · $singles singles, $doubles doubles, $reserves reserves',
              style: OgText.body(13, color: c.textMuted),
            ),
            const SizedBox(height: 6),
            Text(
              'View lineup',
              style: OgText.body(14, weight: FontWeight.w600, color: c.link),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Moderation ────────────────────────────────────────────────────────────

/// "Chat · organizer tools": delete messages and report serious cases.
class ChatModerationScreen extends ConsumerStatefulWidget {
  const ChatModerationScreen({super.key, required this.clubId});

  final String clubId;

  @override
  ConsumerState<ChatModerationScreen> createState() =>
      _ChatModerationScreenState();
}

class _ChatModerationScreenState extends ConsumerState<ChatModerationScreen> {
  String? _open;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final scope = ChatScope.club(widget.clubId);
    final me = ref.watch(currentUserIdProvider).value;
    final messages = (ref.watch(groupChatProvider(scope)).value ?? [])
        .where((m) => m.kind != MessageKind.system && m.sender.id != me)
        .toList()
        .reversed
        .take(12)
        .toList()
        .reversed;
    Future<void> remove(GroupMessage m, bool removed) async {
      await ref
          .read(clubRepositoryProvider)
          .removeMessage(scope, m.id, removed);
      setState(() => _open = null);
      if (removed) HapticFeedback.mediumImpact();
    }

    return KitScaffold(
      header: const KitHeader(title: 'Chat · organizer tools', titleSize: 22),
      children: [
        const KitNote(
          'You run this chat, so you are the first to act. Delete what breaks the rules and report serious cases to us.',
          tone: KitTone.warn,
        ),
        Column(
          children: kitSpaced([
            for (final m in messages)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlayerFace(m.sender, size: 44),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    m.sender.displayName,
                                    style: OgText.body(
                                      14,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _clock(m.at),
                                  style: OgText.body(12, color: c.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: m.removed ? t.soft : c.bg,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                border: m.removed
                                    ? null
                                    : Border.all(color: c.border),
                              ),
                              child: Text(
                                m.removed
                                    ? 'Removed by ${m.removedBy ?? 'an organizer'} (organizer)'
                                    : (m.body.isNotEmpty
                                          ? m.body
                                          : (m.meet != null
                                                ? 'Shared ${m.meet!.title}'
                                                : 'Shared a photo')),
                                style: m.removed
                                    ? OgText.body(
                                        14,
                                        color: c.textMuted,
                                      ).copyWith(fontStyle: FontStyle.italic)
                                    : OgText.body(15, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (m.removed)
                        KitLink('Undo', onPressed: () => remove(m, false))
                      else
                        KitChip(
                          label: 'Manage',
                          height: 44,
                          selected: _open == m.id,
                          onTap: () => setState(
                            () => _open = _open == m.id ? null : m.id,
                          ),
                        ),
                    ],
                  ),
                  if (_open == m.id && !m.removed)
                    Padding(
                      padding: const EdgeInsets.only(left: 54, top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          KitChip(
                            label: 'Delete for everyone',
                            height: 44,
                            background: t.danger,
                            foreground: Colors.white,
                            onTap: () => remove(m, true),
                          ),
                          KitChip(
                            label: 'Member',
                            height: 44,
                            onTap: () => context.push(
                              Routes.clubMember(widget.clubId, m.sender.id),
                            ),
                          ),
                          KitChip(
                            label: 'Report to Olympus',
                            height: 44,
                            onTap: () => context.push(
                              Routes.reportClubMessage(widget.clubId, m.id),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ], 14),
        ),
        const KitNote(
          'The member sees “Removed by an organizer” and is told which club rule it broke. Deleting here does not report the member. Use Report to Olympus for harassment, personal details, intimate images or child safety.',
        ),
        KitLink(
          'Read the community rules',
          onPressed: () => context.push(Routes.communityRules),
        ),
      ],
    );
  }
}

// ─── Announcements ─────────────────────────────────────────────────────────

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key, required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(clubProvider(clubId)).value;
    final list = ref.watch(clubAnnouncementsProvider(clubId));
    final canPost = club?.can(ClubPermission.editPage) ?? false;
    return KitScaffold(
      header: const KitHeader(title: 'Announcements'),
      bottom: [
        if (canPost)
          KitButton(
            label: 'New announcement',
            onPressed: () => context.push(Routes.clubAnnounce(clubId)),
          ),
        KitButton.outline(
          label: 'Open club chat',
          onPressed: () => context.push(Routes.clubChat(clubId)),
        ),
      ],
      children: [
        ...switch (list) {
          AsyncData(:final value) when value.isEmpty => [
            const KitNote('No announcements yet.'),
          ],
          AsyncData(:final value) => [
            for (final a in value) _AnnouncementCard(a: a),
          ],
          AsyncError() => [
            const OgErrorText("Announcements aren't loading. Try again."),
          ],
          _ => [const CupertinoActivityIndicator()],
        },
        const KitNote(
          'Only the owner and admins can post. Members are notified and can react, but replies go to club chat.',
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.a});

  final Announcement a;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final dark = a.pinned;
    final fg = dark ? c.onInverseCard : c.text;
    final when = dayLabel(a.at);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? c.inverseCard : c.bg,
        borderRadius: BorderRadius.circular(20),
        border: dark ? null : Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${a.author}, ${a.authorRole}',
                  style: OgText.body(15, weight: FontWeight.w600, color: fg),
                ),
              ),
              if (a.pinned) ...[
                KitTag(
                  'Pinned',
                  background: c.highlight,
                  foreground: OgColors.charcoal900,
                ),
                const SizedBox(width: 8),
              ],
              Text(when, style: OgText.body(13, color: c.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            a.title,
            style: OgText.body(
              17,
              weight: FontWeight.w600,
              height: 1.3,
              color: fg,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            a.body,
            style: OgText.body(
              15,
              height: 1.45,
              color: dark ? const Color(0xFFD9D9D2) : context.tones.onTag,
            ),
          ),
        ],
      ),
    );
  }
}

/// "New announcement" (admins), then the "Posted" confirmation.
class NewAnnouncementScreen extends ConsumerStatefulWidget {
  const NewAnnouncementScreen({super.key, required this.clubId});

  final String clubId;

  @override
  ConsumerState<NewAnnouncementScreen> createState() =>
      _NewAnnouncementScreenState();
}

class _NewAnnouncementScreenState extends ConsumerState<NewAnnouncementScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _to = 'All members';
  var _pin = false;
  var _busy = false;
  var _sent = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(clubRepositoryProvider)
          .announce(
            widget.clubId,
            title: _title.text.trim(),
            body: _body.text.trim(),
            audience: _to!,
            pinned: _pin,
          );
      ref.invalidate(clubAnnouncementsProvider(widget.clubId));
      HapticFeedback.mediumImpact();
      setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = ref.watch(clubProvider(widget.clubId)).value;
    final roles = ref.watch(clubRolesProvider(widget.clubId)).value ?? [];
    final count = club?.memberCount ?? 0;
    final audiences = [
      'All members',
      'Admins only',
      for (final r in roles)
        if (!r.isOwner && r.name != 'Admin' && !r.isLabel) r.name,
    ];
    final told = _to == 'Admins only'
        ? roles
              .where((r) => r.name == 'Admin' || r.isOwner)
              .fold(0, (n, r) => n + r.memberCount)
        : count;
    if (_sent) {
      return KitScaffold(
        header: const KitHeader(title: 'New announcement'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Back to announcements',
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Posted'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: KitTitle(
              '$told member${told == 1 ? '' : 's'} told',
              size: 26,
              lead: 'It is at the top of Announcements and on the club page.',
            ),
          ),
        ],
      );
    }
    final ready = _title.text.trim().isNotEmpty && _to != null;
    return KitScaffold(
      header: const KitHeader(title: 'New announcement'),
      bottom: [
        KitButton(
          label: 'Post announcement',
          loading: _busy,
          onPressed: ready ? _post : null,
        ),
      ],
      children: [
        KitInput(
          label: 'Title',
          controller: _title,
          hint: 'What is changing?',
          maxLength: 80,
        ),
        KitTextArea(label: 'Message', controller: _body, lines: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const KitSection('Send to'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in audiences)
                  KitChip(
                    label: a,
                    selected: _to == a,
                    onTap: () => setState(() => _to = a),
                  ),
              ],
            ),
          ],
        ),
        KitConfirmBox(
          label: 'Pin to the top of the club page',
          checked: _pin,
          onChanged: (v) => setState(() => _pin = v),
        ),
        KitNote(
          '$told member${told == 1 ? '' : 's'} get a notification. You can edit or delete it later.',
        ),
      ],
    );
  }
}

// ─── Report a message or club ──────────────────────────────────────────────

/// "Report a message" and "Report a club or event".
class ReportContentScreen extends ConsumerStatefulWidget {
  const ReportContentScreen.message({
    super.key,
    required ChatScope this.scope,
    required String this.messageId,
  }) : clubId = null,
       activityId = null,
       videoId = null,
       live = false;

  const ReportContentScreen.club({super.key, required String this.clubId})
    : scope = null,
      messageId = null,
      activityId = null,
      videoId = null,
      live = false;

  /// A tournament or event.
  const ReportContentScreen.activity({
    super.key,
    required String this.activityId,
  }) : scope = null,
       messageId = null,
       clubId = null,
       videoId = null,
       live = false;

  /// A shop video, or a live stream.
  const ReportContentScreen.video({
    super.key,
    required String this.videoId,
    this.live = false,
  }) : scope = null,
       messageId = null,
       clubId = null,
       activityId = null;

  final ChatScope? scope;
  final String? messageId;
  final String? clubId;
  final String? activityId;
  final String? videoId;
  final bool live;

  @override
  ConsumerState<ReportContentScreen> createState() =>
      _ReportContentScreenState();
}

class _ReportContentScreenState extends ConsumerState<ReportContentScreen> {
  ContentReport? _why;
  var _hide = true;
  var _busy = false;
  var _sent = false;
  final _note = TextEditingController();

  bool get _isMessage => widget.messageId != null;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(clubRepositoryProvider);
      await repo.report(
        _isMessage
            ? ReportTarget.message(widget.messageId!, scope: widget.scope!)
            : widget.videoId != null
            ? ReportTarget.video(widget.videoId!, live: widget.live)
            : widget.activityId != null
            ? ReportTarget.activity(widget.activityId!)
            : ReportTarget.club(widget.clubId!),
        _why!,
        _note.text.trim(),
      );
      if (_isMessage && _hide) {
        await repo.removeMessage(widget.scope!, widget.messageId!, true);
      }
      HapticFeedback.mediumImpact();
      setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isMessage
        ? 'Report a message'
        : widget.videoId != null
        ? 'Report a video or live'
        : 'Report a club or event';
    if (_sent) {
      return KitScaffold(
        header: KitHeader(title: title, titleSize: 22),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(label: 'Done', onPressed: () => context.pop()),
          KitButton.outline(
            label: 'See my reports',
            onPressed: () => context.push(Routes.myReports),
          ),
        ],
        children: const [
          KitDoneBanner(title: 'Report sent'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: KitTitle(
              'Thank you',
              size: 26,
              lead: 'We review every report within 24 hours, and urgent ones first. You will see the result in My reports. If someone is in danger, call 999 (111 in New Zealand).',
            ),
          ),
        ],
      );
    }
    final reasons = _isMessage
        ? ContentReport.forMessage
        : widget.videoId != null
        ? ContentReport.forVideo
        : ContentReport.forClub;
    return KitScaffold(
      header: KitHeader(title: title, titleSize: 22),
      bottom: [
        KitButton(
          label: _why == null ? 'Pick what is wrong' : 'Send report',
          loading: _busy,
          onPressed: _why == null ? null : _send,
        ),
      ],
      children: [
        _isMessage
            ? _messageCard(context)
            : widget.videoId != null
            ? _videoCard(context)
            : widget.activityId != null
            ? _activityCard(context)
            : _clubCard(context),
        KitTitle(
          'What is wrong with it?',
          lead: _isMessage
              ? 'Reports are private. They are not told who reported.'
              : widget.videoId != null
              ? 'Reports are private. The creator is not told who reported.'
              : 'Reports are private. The organizer is not told who reported.',
        ),
        Column(
          children: [
            for (final r in reasons)
              KitChoiceRow(
                title: r.label,
                subtitle: r.hint,
                tag: r.urgent ? 'Urgent' : null,
                selected: _why == r,
                onTap: () => setState(() => _why = r),
              ),
          ],
        ),
        KitTextArea(label: 'Tell us more', optional: true, controller: _note),
        KitConfirmBox(
          label: _isMessage
              ? 'Hide this message from me now'
              : widget.videoId != null
              ? 'Do not show me this video again'
              : widget.activityId != null
              ? 'Hide this from my results'
              : 'Hide this club from my results',
          checked: _hide,
          onChanged: (v) => setState(() => _hide = v),
        ),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    Widget lead,
    String eyebrow,
    String title,
    String sub,
  ) {
    final c = context.og;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tones.soft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          lead,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: OgText.body(
                    12,
                    weight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: c.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(title, style: OgText.body(15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: OgText.body(13, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard(BuildContext context) {
    final scope = widget.scope!;
    final m = (ref.watch(groupChatProvider(scope)).value ?? [])
        .where((m) => m.id == widget.messageId)
        .firstOrNull;
    final where = scope.isTeam
        ? ref.watch(teamProvider(scope.id)).value?.name
        : ref.watch(clubProvider(scope.id)).value?.name;
    if (m == null) return const SizedBox.shrink();
    return _card(
      context,
      PlayerFace(m.sender, size: 44),
      'Message in ${where ?? 'chat'}${scope.isTeam ? '' : ' chat'}',
      '${m.sender.displayName}, ${_clock(m.at)}',
      m.body.isEmpty ? 'A shared item' : '“${m.body}”',
    );
  }

  Widget _videoCard(BuildContext context) {
    if (widget.live) {
      final l = ref
          .watch(shopLivesProvider)
          .value
          ?.where((l) => l.id == widget.videoId)
          .firstOrNull;
      if (l == null) return const SizedBox.shrink();
      return _card(
        context,
        SolidAvatar.forId(l.id, initials: l.shopMark),
        'Live',
        l.title,
        '${l.host} · ${l.shop}',
      );
    }
    final v = ref
        .watch(shopVideosProvider)
        .value
        ?.where((v) => v.id == widget.videoId)
        .firstOrNull;
    if (v == null) return const SizedBox.shrink();
    return _card(
      context,
      SolidAvatar.forId(v.id, initials: v.creatorMark),
      'Video',
      v.title,
      v.creator,
    );
  }

  Widget _activityCard(BuildContext context) {
    final a = ref.watch(activityDetailProvider(widget.activityId!)).value;
    if (a == null) return const SizedBox.shrink();
    return _card(
      context,
      SolidAvatar.forId(a.id, initials: clubInitials(a.title)),
      a.kind.label,
      a.title,
      '${Fmt.day(a.startsAt)} · ${a.venue.name}',
    );
  }

  Widget _clubCard(BuildContext context) {
    final club = ref.watch(clubProvider(widget.clubId!)).value;
    if (club == null) return const SizedBox.shrink();
    return _card(
      context,
      ClubMark(club, size: 44, radius: 22, fontSize: 14),
      'Club',
      club.name,
      '${club.memberCount} members · ${club.area}',
    );
  }
}
