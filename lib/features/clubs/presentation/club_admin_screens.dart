import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/share.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../application/club_providers.dart';
import '../domain/club_models.dart';

/// Loads the club, then builds [body].
class WithClub extends ConsumerWidget {
  const WithClub({
    super.key,
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final Widget Function(Club club) body;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(clubProvider(id))) {
        AsyncData(:final value) => body(value),
        AsyncError() => KitScaffold(
          header: KitHeader(title: title),
          children: const [KitNote("This club isn't available any more.")],
        ),
        _ => KitScaffold(
          header: KitHeader(title: title),
          children: const [CupertinoActivityIndicator()],
        ),
      };
}

/// "3 weeks ago", "2 months ago".
String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inDays < 1) return 'today';
  if (d.inDays < 14) return '${d.inDays} ${d.inDays == 1 ? 'day' : 'days'} ago';
  if (d.inDays < 60) return '${d.inDays ~/ 7} weeks ago';
  if (d.inDays < 365) return '${d.inDays ~/ 30} months ago';
  return '${d.inDays ~/ 365} ${d.inDays < 730 ? 'year' : 'years'} ago';
}

/// A tile with a count on the right.
Widget _countTile(
  BuildContext context, {
  required String icon,
  required String title,
  required String sub,
  required VoidCallback onTap,
  String? count,
  bool danger = false,
}) => KitNavTile(
  icon: icon,
  title: title,
  subtitle: sub,
  danger: danger,
  trailing: count == null
      ? null
      : Text(
          count,
          style: OgText.body(
            14,
            weight: FontWeight.w700,
            color: context.og.textMuted,
          ),
        ),
  onTap: onTap,
);

/// Everything an admin can change, grouped as in the design.
class ClubSettingsScreen extends ConsumerWidget {
  const ClubSettingsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => WithClub(
    id: id,
    title: 'Club settings',
    body: (club) {
      final can = club.myPermissions;
      final owner = club.isOwner;
      final reward = ref.watch(clubRewardProvider(id)).value;
      final done =
          reward?.meets
              .where((m) => m.paidPresent >= reward.minPlayers)
              .length ??
          0;
      return KitScaffold(
        header: KitHeader(title: 'Club settings', subtitle: club.name),
        children: [
          Text('Settings', style: OgText.heading(20)),
          KitCard(
            children: [
              if (owner || can.contains(ClubPermission.editPage))
                _countTile(
                  context,
                  icon: OgIcons.pencil,
                  title: 'Overview',
                  sub: 'Name, images, venue, club type, rules',
                  onTap: () => context.push(Routes.clubOverview(id)),
                ),
              if (owner || can.contains(ClubPermission.editPage))
                _countTile(
                  context,
                  icon: OgIcons.racquet,
                  title: 'Sport interest',
                  sub: 'Sports and skill level range for each',
                  count: '${club.sports.length}',
                  onTap: () =>
                      context.push(Routes.clubOverview(id, tab: 'sports')),
                ),
              _countTile(
                context,
                icon: OgIcons.giftBox,
                title: 'Club reward',
                sub: reward == null
                    ? 'Meets that count toward the reward'
                    : '${(reward.target - done).clamp(0, reward.target)} more Meets unlock ${reward.prize}',
                count: reward == null ? null : '$done of ${reward.target}',
                onTap: () => context.push(Routes.clubReward(id)),
              ),
              if (owner || can.contains(ClubPermission.members))
                _countTile(
                  context,
                  icon: OgIcons.chatSquare,
                  title: 'Chat moderation',
                  sub: 'Delete messages, remove members, report',
                  onTap: () => context.push(Routes.clubModeration(id)),
                ),
              if (owner || can.contains(ClubPermission.audit))
                _countTile(
                  context,
                  icon: OgIcons.clipboardAudit,
                  title: 'Audit log',
                  sub: 'Who changed what in the club',
                  onTap: () => context.push(Routes.clubAudit(id)),
                ),
            ],
          ),
          Text('User management', style: OgText.heading(20)),
          KitCard(
            children: [
              _countTile(
                context,
                icon: OgIcons.people,
                title: 'Members',
                sub: 'View, remove and assign roles',
                count: '${club.memberCount}',
                onTap: () => context.push(Routes.clubMembers(id)),
              ),
              if (owner || can.contains(ClubPermission.roles))
                _countTile(
                  context,
                  icon: OgIcons.roleShield,
                  title: 'Roles',
                  sub: 'Create roles and set permissions',
                  count: '${club.roleCount}',
                  onTap: () => context.push(Routes.clubRoles(id)),
                ),
              if (owner || can.contains(ClubPermission.approve))
                _countTile(
                  context,
                  icon: OgIcons.personRequest,
                  title: 'Join requests',
                  sub: 'Approve or decline new members',
                  count: '${club.pendingRequests}',
                  onTap: () => context.push(Routes.clubRequests(id)),
                ),
              _countTile(
                context,
                icon: OgIcons.link,
                title: 'Invites',
                sub: 'Invite links and pending invites',
                count: club.activeInvites == 0
                    ? null
                    : '${club.activeInvites} active',
                onTap: () => context.push(Routes.clubInvite(id)),
              ),
              if (owner || can.contains(ClubPermission.members))
                _countTile(
                  context,
                  icon: OgIcons.ban,
                  title: 'Bans',
                  sub: 'Players blocked from this club',
                  count: '${club.banCount}',
                  onTap: () => context.push(Routes.clubBans(id)),
                ),
            ],
          ),
          KitCard(
            children: [
              _countTile(
                context,
                icon: OgIcons.leave,
                title: 'Leave club',
                sub: 'You keep your rating and session history',
                danger: true,
                onTap: () => context.push(Routes.clubLeave(id)),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// Members grouped by their highest role, with search.
class ClubMembersScreen extends ConsumerStatefulWidget {
  const ClubMembersScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ClubMembersScreen> createState() => _ClubMembersScreenState();
}

class _ClubMembersScreenState extends ConsumerState<ClubMembersScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) => WithClub(
    id: widget.id,
    title: 'Members',
    body: (club) {
      final c = context.og;
      final members = ref.watch(clubMembersProvider(widget.id)).value;
      final roles = ref.watch(clubRolesProvider(widget.id)).value ?? const [];
      final q = _q.trim().toLowerCase();
      final shown = (members ?? const <ClubMember>[])
          .where(
            (m) =>
                q.isEmpty ||
                m.player.displayName.toLowerCase().contains(q) ||
                (m.player.username ?? '').toLowerCase().contains(q),
          )
          .toList();
      // Highest role first: roles are listed top to bottom by position.
      final ordered = [...roles]
        ..sort((a, b) => a.position.compareTo(b.position));
      ClubRole? top(ClubMember m) =>
          ordered.where((r) => m.roleIds.contains(r.id)).firstOrNull;
      final groups = <String, List<ClubMember>>{};
      final colors = <String, int>{};
      for (final m in shown) {
        final r = top(m);
        final key = r?.name ?? 'Everyone';
        groups.putIfAbsent(key, () => []).add(m);
        colors[key] = r?.color ?? 0xFF7A8088;
      }
      final keys = [
        for (final r in ordered)
          if (groups.containsKey(r.name)) r.name,
        if (groups.containsKey('Everyone')) 'Everyone',
      ];
      final canRoles =
          club.isOwner || club.myPermissions.contains(ClubPermission.roles);
      return KitScaffold(
        header: KitHeader(
          title: 'Members · ${club.memberCount}',
          trailing: canRoles
              ? KitLink(
                  'Roles',
                  onPressed: () => context.push(Routes.clubRoles(widget.id)),
                )
              : null,
        ),
        children: [
          KitSearchField(
            hint: 'Search members',
            onChanged: (v) => setState(() => _q = v),
          ),
          if (members == null)
            const CupertinoActivityIndicator()
          else if (shown.isEmpty)
            Text(
              'Nobody matches. Check the spelling or clear the search.',
              style: OgText.body(14, color: c.textMuted),
            )
          else
            for (final k in keys)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(colors[k]!),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          k.toUpperCase(),
                          style: OgText.body(
                            12,
                            weight: FontWeight.w800,
                            color: c.textMuted,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        '${groups[k]!.length}',
                        style: OgText.body(12, color: c.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  KitCard(
                    children: [
                      for (final m in groups[k]!)
                        Pressable(
                          semanticLabel: m.player.displayName,
                          onPressed: () => context.push(
                            Routes.clubMember(widget.id, m.player.id),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                SolidAvatar.forId(
                                  m.player.id,
                                  initials: m.player.initials,
                                  size: 40,
                                  fontSize: 14,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    m.player.displayName,
                                    style: OgText.body(
                                      15,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (m.rating != null)
                                  Text(
                                    '${m.band!.code} ${m.rating!.toStringAsFixed(1)}',
                                    style: OgText.body(
                                      13,
                                      weight: FontWeight.w700,
                                      color: c.textMuted,
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                OgIcon(
                                  OgIcons.chevronRight,
                                  size: 16,
                                  color: c.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
        ],
      );
    },
  );
}

/// One member: stats, role, message, remove and ban.
class ClubMemberScreen extends ConsumerStatefulWidget {
  const ClubMemberScreen({super.key, required this.id, required this.userId});

  final String id;
  final String userId;

  @override
  ConsumerState<ClubMemberScreen> createState() => _ClubMemberScreenState();
}

class _ClubMemberScreenState extends ConsumerState<ClubMemberScreen> {
  bool _saved = false;

  Future<void> _setRole(String? roleId) async {
    try {
      await ref
          .read(clubRepositoryProvider)
          .setMemberRole(widget.id, widget.userId, roleId);
      HapticFeedback.selectionClick();
      refreshClub(ref.invalidate, widget.id);
      if (mounted) setState(() => _saved = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _remove(ClubMember m) async {
    final first = m.player.displayName.split(' ').first;
    final ok = await showKitSheet<bool>(
      context,
      builder: (sheet) => _Confirm(
        title: 'Remove ${m.player.displayName}?',
        body:
            '$first leaves the club and its chat. Upcoming Meets they joined '
            'are cancelled and refunded in full. They can ask to join again.',
        action: 'Remove from club',
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref
          .read(clubRepositoryProvider)
          .removeMember(widget.id, widget.userId);
      refreshClub(ref.invalidate, widget.id);
      if (!mounted) return;
      showOgToast(context, '${m.player.displayName} removed');
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _ban(ClubMember m) async {
    final reason = await showKitSheet<String>(
      context,
      builder: (_) => _BanSheet(name: m.player.displayName),
    );
    if (reason == null || !mounted) return;
    try {
      await ref
          .read(clubRepositoryProvider)
          .banMember(widget.id, widget.userId, reason);
      refreshClub(ref.invalidate, widget.id);
      if (!mounted) return;
      showOgToast(context, '${m.player.displayName} banned');
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) => WithClub(
    id: widget.id,
    title: 'Member',
    body: (club) {
      final c = context.og;
      final t = context.tones;
      final m = ref
          .watch(clubMembersProvider(widget.id))
          .value
          ?.where((m) => m.player.id == widget.userId)
          .firstOrNull;
      final roles = ref.watch(clubRolesProvider(widget.id)).value ?? const [];
      if (m == null) {
        return const KitScaffold(
          header: KitHeader(title: 'Member'),
          children: [CupertinoActivityIndicator()],
        );
      }
      final canManage =
          club.isOwner || club.myPermissions.contains(ClubPermission.members);
      final assignable = roles.where((r) => !r.isOwner).toList()
        ..sort((a, b) => b.position.compareTo(a.position));
      final current = assignable
          .where((r) => m.roleIds.contains(r.id))
          .firstOrNull;
      final first = m.player.displayName.split(' ').first;
      final me = ref.watch(currentUserIdProvider).value;
      Widget stat(String big, String small) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: t.tag,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(big, style: OgText.heading(22)),
              Text(small, style: OgText.body(12, color: t.onTag)),
            ],
          ),
        ),
      );
      return KitScaffold(
        header: const KitHeader(title: 'Member'),
        children: [
          Row(
            children: [
              SolidAvatar.forId(
                m.player.id,
                initials: m.player.initials,
                size: 64,
                fontSize: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.player.displayName, style: OgText.heading(24)),
                    Text(
                      [
                        if (m.rating != null)
                          '${m.band!.code} ${m.rating!.toStringAsFixed(1)}',
                        if (m.joinedAt != null) 'Joined ${ago(m.joinedAt!)}',
                      ].join(' · '),
                      style: OgText.body(14, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              stat('${m.meetsPlayed}', 'Meets played'),
              const SizedBox(width: 8),
              stat('${m.noShows}', m.noShows == 1 ? 'No-show' : 'No-shows'),
              const SizedBox(width: 8),
              stat('S\$${m.paidCents ~/ 100}', 'Paid to club'),
            ],
          ),
          if (canManage) ...[
            Text('Role', style: OgText.heading(20)),
            Column(
              children: [
                KitChoiceRow(
                  title: 'Everyone',
                  subtitle: 'Join Meets, chat, invite friends',
                  selected: current == null,
                  onTap: () => _setRole(null),
                ),
                for (final r in assignable)
                  KitChoiceRow(
                    title: r.name,
                    subtitle: r.permissions.isEmpty
                        ? 'A label, no extra permissions'
                        : r.permissions.take(2).map((p) => p.label).join(', '),
                    selected: current?.id == r.id,
                    onTap: () => _setRole(r.id),
                  ),
              ],
            ),
            if (_saved)
              Text(
                'Saved',
                style: OgText.body(
                  13,
                  weight: FontWeight.w700,
                  color: t.successInk,
                ),
              ),
          ],
          KitCard(
            children: [
              KitNavTile(
                icon: OgIcons.chatRound,
                title: 'Message $first',
                subtitle: 'Opens a direct message',
                onTap: () => context.push(Routes.messagePlayer(m.player.id)),
              ),
              if (canManage && m.player.id != me) ...[
                KitNavTile(
                  icon: OgIcons.leave,
                  title: 'Remove from club',
                  subtitle: '$first can ask to join again',
                  danger: true,
                  onTap: () => _remove(m),
                ),
                KitNavTile(
                  icon: OgIcons.ban,
                  title: 'Ban from club',
                  subtitle: '$first cannot see the club or ask to join',
                  danger: true,
                  onTap: () => _ban(m),
                ),
              ],
            ],
          ),
          if (canManage)
            Text(
              'Role changes save right away and are written to the audit log.',
              style: OgText.body(13, color: c.textMuted),
            ),
        ],
      );
    },
  );
}

/// A yes or no sheet for a destructive step.
class _Confirm extends StatelessWidget {
  const _Confirm({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final String action;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: OgText.heading(24)),
      const SizedBox(height: 8),
      Text(
        body,
        style: OgText.body(15, height: 1.45, color: context.og.textMuted),
      ),
      const SizedBox(height: 20),
      KitButton(
        label: action,
        style: KitButtonStyle.danger,
        onPressed: () => Navigator.of(context).pop(true),
      ),
      const SizedBox(height: 10),
      KitButton(
        label: 'Cancel',
        style: KitButtonStyle.outline,
        onPressed: () => Navigator.of(context).pop(false),
      ),
    ],
  );
}

class _BanSheet extends StatefulWidget {
  const _BanSheet({required this.name});

  final String name;

  @override
  State<_BanSheet> createState() => _BanSheetState();
}

class _BanSheetState extends State<_BanSheet> {
  String? _reason;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ban ${widget.name}?', style: OgText.heading(24)),
        const SizedBox(height: 8),
        Text(
          'They are removed, refunded for upcoming Meets, and cannot see the '
          'club or ask to join again.',
          style: OgText.body(15, height: 1.45, color: context.og.textMuted),
        ),
        const SizedBox(height: 14),
        Text(
          'Reason, shown to other Admins',
          style: OgText.body(15, weight: FontWeight.w700),
        ),
        for (final r in const [
          'No-shows',
          'Unpaid fees',
          'Abusive behaviour',
          'Other',
        ])
          KitChoiceRow(
            title: r,
            selected: _reason == r,
            onTap: () => setState(() => _reason = r),
          ),
        const SizedBox(height: 16),
        KitButton(
          label: _reason == null ? 'Pick a reason to ban' : 'Ban from club',
          style: KitButtonStyle.danger,
          onPressed: _reason == null
              ? null
              : () => Navigator.of(context).pop(_reason),
        ),
        const SizedBox(height: 10),
        KitButton(
          label: 'Cancel',
          style: KitButtonStyle.outline,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// New members waiting to be let in.
class JoinRequestsScreen extends ConsumerWidget {
  const JoinRequestsScreen({super.key, required this.id});

  final String id;

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    JoinRequest r,
    RequestStatus status,
  ) async {
    try {
      await ref.read(clubRepositoryProvider).decideRequest(id, r.id, status);
      HapticFeedback.selectionClick();
      refreshClub(ref.invalidate, id);
      if (context.mounted) {
        showOgToast(
          context,
          status == RequestStatus.approved
              ? '${r.player.displayName} is in'
              : 'Request declined',
        );
      }
    } on AuthFailure catch (e) {
      if (context.mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final list = ref.watch(joinRequestsProvider(id)).value;
    final pending =
        list?.where((r) => r.status == RequestStatus.pending).toList() ??
        const [];
    return KitScaffold(
      header: const KitHeader(title: 'Join requests'),
      children: [
        if (list == null)
          const CupertinoActivityIndicator()
        else if (pending.isEmpty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('No one is waiting', style: OgText.heading(20)),
                  const SizedBox(height: 6),
                  Text(
                    'New requests show here. Members are told when you '
                    'approve them.',
                    style: OgText.body(14, color: c.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          for (final r in pending)
            KitCard(
              padding: const EdgeInsets.all(14),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        SolidAvatar.forId(
                          r.player.id,
                          initials: r.player.initials,
                          size: 44,
                          fontSize: 15,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.player.displayName,
                                style: OgText.body(15, weight: FontWeight.w700),
                              ),
                              Text(
                                [
                                  if (r.rating != null)
                                    'Rating ${r.rating!.toStringAsFixed(1)}',
                                  '${r.sessions} sessions',
                                  if (r.mutual > 0) '${r.mutual} mutual',
                                  'asked ${ago(r.createdAt)}',
                                ].join(' · '),
                                style: OgText.body(13, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (r.belowRange || r.provisional) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (r.belowRange)
                            KitTag(
                              'Below the club range',
                              background: t.warnFill,
                              foreground: t.onWarnFill,
                            ),
                          if (r.provisional)
                            KitTag(
                              'Provisional rating',
                              background: t.tag,
                              foreground: t.onTag,
                            ),
                        ],
                      ),
                    ],
                    if (r.message.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        '“${r.message}”',
                        style: OgText.body(14, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: KitButton(
                            label: 'Decline',
                            style: KitButtonStyle.outline,
                            height: 46,
                            onPressed: () => _decide(
                              context,
                              ref,
                              r,
                              RequestStatus.declined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KitButton(
                            label: 'Approve',
                            height: 46,
                            onPressed: () => _decide(
                              context,
                              ref,
                              r,
                              RequestStatus.approved,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
      ],
    );
  }
}

/// Who changed what, newest first, by category.
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  AuditCategory? _only;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final all = ref.watch(clubAuditProvider(widget.id)).value;
    final shown = (all ?? const <AuditEntry>[])
        .where((e) => _only == null || e.category == _only)
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'Audit log'),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              KitChip(
                label: 'All',
                selected: _only == null,
                onTap: () => setState(() => _only = null),
              ),
              for (final cat in AuditCategory.values) ...[
                const SizedBox(width: 8),
                KitChip(
                  label: cat.label,
                  selected: _only == cat,
                  onTap: () => setState(() => _only = cat),
                ),
              ],
            ],
          ),
        ),
        if (all == null)
          const CupertinoActivityIndicator()
        else if (shown.isEmpty)
          Text('Nothing here yet.', style: OgText.body(14, color: c.textMuted))
        else
          KitCard(
            children: [
              for (final e in shown)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: e.actor,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' ${e.action}'),
                          ],
                        ),
                        style: OgText.body(15),
                      ),
                      if (e.detail.isNotEmpty)
                        Text(
                          e.detail,
                          style: OgText.body(13, color: c.textMuted),
                        ),
                      Text(
                        '${e.category.label} · ${Fmt.dayTimeComma(e.at)}',
                        style: OgText.body(12, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Banned players, with undo.
class ClubBansScreen extends ConsumerStatefulWidget {
  const ClubBansScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ClubBansScreen> createState() => _ClubBansScreenState();
}

class _ClubBansScreenState extends ConsumerState<ClubBansScreen> {
  final _unbanned = <String>{};

  Future<void> _unban(ClubBan b) async {
    try {
      await ref.read(clubRepositoryProvider).unban(widget.id, b.player.id);
      HapticFeedback.selectionClick();
      setState(() => _unbanned.add(b.player.id));
      ref.invalidate(clubProvider(widget.id));
      ref.invalidate(clubAuditProvider(widget.id));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _undo(ClubBan b) async {
    try {
      await ref
          .read(clubRepositoryProvider)
          .banMember(widget.id, b.player.id, b.reason);
      setState(() => _unbanned.remove(b.player.id));
      ref.invalidate(clubProvider(widget.id));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final bans = ref.watch(clubBansProvider(widget.id)).value;
    return KitScaffold(
      header: const KitHeader(title: 'Bans'),
      children: [
        const KitTitle(
          'Banned players',
          lead:
              'A banned player cannot see the club, join its Meets or ask to '
              'join again.',
        ),
        if (bans == null)
          const CupertinoActivityIndicator()
        else if (bans.isEmpty)
          Text('Nobody is banned.', style: OgText.body(14, color: c.textMuted))
        else
          KitCard(
            children: [
              for (final b in bans)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          SolidAvatar.forId(
                            b.player.id,
                            initials: b.player.initials,
                            size: 40,
                            fontSize: 14,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.player.displayName,
                                  style: OgText.body(
                                    15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Banned by ${b.bannedBy} · ${Fmt.day(b.at)}',
                                  style: OgText.body(13, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                          _unbanned.contains(b.player.id)
                              ? KitLink('Undo', onPressed: () => _undo(b))
                              : KitButton(
                                  label: 'Unban',
                                  expand: false,
                                  height: 40,
                                  radius: 20,
                                  fontSize: 14,
                                  padding: 14,
                                  style: KitButtonStyle.outline,
                                  onPressed: () => _unban(b),
                                ),
                        ],
                      ),
                      if (_unbanned.contains(b.player.id)) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Unbanned. They can ask to join again.',
                          style: OgText.body(13, color: t.successInk),
                        ),
                      ] else if (b.reason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Reason: ${b.reason}',
                          style: OgText.body(13, color: c.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        KitNote(
          'To ban someone, open Members, pick the player and choose Ban. '
          'Every ban and unban is written to the audit log.',
          child: Align(
            alignment: Alignment.centerLeft,
            child: KitLink(
              'Members',
              underline: true,
              onPressed: () => context.push(Routes.clubMembers(widget.id)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Invite people you play with, or share the invite link.
class ClubInviteScreen extends ConsumerStatefulWidget {
  const ClubInviteScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ClubInviteScreen> createState() => _ClubInviteScreenState();
}

class _ClubInviteScreenState extends ConsumerState<ClubInviteScreen> {
  final _picked = <String>{};
  String _q = '';
  bool _busy = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref.read(clubRepositoryProvider).invite(widget.id, _picked);
      HapticFeedback.mediumImpact();
      refreshClub(ref.invalidate, widget.id);
      if (!mounted) return;
      showOgToast(
        context,
        '${_picked.length} ${_picked.length == 1 ? 'invite' : 'invites'} sent',
      );
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WithClub(
    id: widget.id,
    title: 'Invite',
    body: (club) {
      final c = context.og;
      final people = ref.watch(inviteCandidatesProvider).value;
      final q = _q.trim().toLowerCase();
      final shown = (people ?? const <InviteCandidate>[])
          .where(
            (p) => q.isEmpty || p.player.displayName.toLowerCase().contains(q),
          )
          .toList();
      final link = club.inviteCode == null
          ? Links.club(club.id)
          : Links.clubInvite(club.inviteCode!);
      return KitScaffold(
        header: KitHeader(title: 'Invite', subtitle: club.name),
        bottom: [
          KitButton(
            label: _picked.isEmpty
                ? 'Pick people to invite'
                : 'Send ${_picked.length} ${_picked.length == 1 ? 'invite' : 'invites'}',
            loading: _busy,
            onPressed: _picked.isEmpty ? null : _send,
          ),
        ],
        children: [
          KitCard(
            padding: const EdgeInsets.all(14),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Invite link',
                    style: OgText.body(15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    link.replaceFirst('https://', ''),
                    style: OgText.body(14, color: c.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: KitButton(
                          label: 'Copy',
                          style: KitButtonStyle.outline,
                          height: 44,
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: link));
                            if (context.mounted) {
                              showOgToast(context, 'Link copied');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: KitButton(
                          label: 'Share',
                          height: 44,
                          onPressed: () => shareLink(
                            context,
                            'Join ${club.name} on OlympusGO',
                            link,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Text('People you play with', style: OgText.heading(20)),
          KitSearchField(
            hint: 'Search players',
            onChanged: (v) => setState(() => _q = v),
          ),
          if (people == null)
            const CupertinoActivityIndicator()
          else if (shown.isEmpty)
            Text(
              'Nobody matches. Check the spelling or clear the search.',
              style: OgText.body(14, color: c.textMuted),
            )
          else
            Column(
              children: [
                for (final p in shown)
                  KitChoiceRow(
                    leading: SolidAvatar.forId(
                      p.player.id,
                      initials: p.player.initials,
                      size: 40,
                      fontSize: 14,
                    ),
                    title: p.player.displayName,
                    subtitle: [
                      if (p.meetsTogether > 0)
                        '${p.meetsTogether} Meets together',
                      if (p.club.isNotEmpty) p.club,
                    ].join(' · '),
                    tag: p.rating?.toStringAsFixed(1),
                    multi: true,
                    selected: _picked.contains(p.player.id),
                    onTap: () => setState(() {
                      if (!_picked.remove(p.player.id)) {
                        _picked.add(p.player.id);
                      }
                    }),
                  ),
              ],
            ),
        ],
      );
    },
  );
}

/// Hand the club to an Admin.
class ClubTransferScreen extends ConsumerStatefulWidget {
  const ClubTransferScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ClubTransferScreen> createState() => _ClubTransferScreenState();
}

class _ClubTransferScreenState extends ConsumerState<ClubTransferScreen> {
  String? _to;
  bool _busy = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref.read(clubRepositoryProvider).transfer(widget.id, _to!);
      HapticFeedback.mediumImpact();
      refreshClub(ref.invalidate, widget.id);
      if (!mounted) return;
      showOgToast(context, 'Transfer request sent');
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final members = ref.watch(clubMembersProvider(widget.id)).value;
    final roles = ref.watch(clubRolesProvider(widget.id)).value ?? const [];
    final adminIds = {
      for (final r in roles)
        if (r.level == RoleLevel.admin && !r.isOwner) r.id,
    };
    final admins = (members ?? const <ClubMember>[])
        .where((m) => m.roleIds.any(adminIds.contains))
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'Transfer ownership'),
      bottom: [
        KitButton(
          label: 'Send transfer request',
          loading: _busy,
          onPressed: _to == null ? null : _send,
        ),
        KitButton(
          label: 'Cancel',
          style: KitButtonStyle.outline,
          onPressed: () => context.pop(),
        ),
      ],
      children: [
        const KitTitle(
          'Pick the new owner',
          lead:
              'Only Admins can take over. They get a request and must accept '
              'within 7 days.',
        ),
        if (members == null)
          const CupertinoActivityIndicator()
        else if (admins.isEmpty)
          const KitNote(
            'Nobody has the Admin role yet. Give someone the Admin role in '
            'Members first.',
            tone: KitTone.warn,
          )
        else
          Column(
            children: [
              for (final m in admins)
                KitChoiceRow(
                  leading: SolidAvatar.forId(
                    m.player.id,
                    initials: m.player.initials,
                    size: 40,
                    fontSize: 14,
                  ),
                  title: m.player.displayName,
                  subtitle: 'Admin · ${m.meetsPlayed} Meets',
                  selected: _to == m.player.id,
                  onTap: () => setState(() => _to = m.player.id),
                ),
            ],
          ),
        Text(
          'After they accept, you become an Admin. Payouts and the club '
          'reward move to the new owner once their identity is verified.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Leave the club: what you keep and what you lose.
class ClubLeaveScreen extends ConsumerStatefulWidget {
  const ClubLeaveScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ClubLeaveScreen> createState() => _ClubLeaveScreenState();
}

class _ClubLeaveScreenState extends ConsumerState<ClubLeaveScreen> {
  bool _understood = false;
  bool _busy = false;

  Future<void> _leave(Club club) async {
    setState(() => _busy = true);
    try {
      await ref.read(clubRepositoryProvider).leave(widget.id);
      HapticFeedback.mediumImpact();
      refreshClub(ref.invalidate, widget.id);
      if (!mounted) return;
      showOgToast(context, 'You left ${club.name}');
      context.go(Routes.clubs);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WithClub(
    id: widget.id,
    title: 'Leave club',
    body: (club) {
      final c = context.og;
      final mine =
          ref
              .watch(clubSessionsProvider(widget.id))
              .value
              ?.where((a) => a.myStatus.name == 'joined')
              .length ??
          0;
      return KitScaffold(
        header: const KitHeader(title: 'Leave club'),
        bottom: [
          KitButton(
            label: 'Leave club',
            style: KitButtonStyle.danger,
            loading: _busy,
            onPressed: club.isOwner || (mine > 0 && !_understood)
                ? null
                : () => _leave(club),
          ),
          KitButton(
            label: 'Stay in club',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          KitTitle(
            'Leave ${club.name}?',
            lead: 'You can ask to join again at any time.',
          ),
          Text('You keep', style: OgText.heading(20)),
          const KitCheckList([
            'Your rating and Passport history',
            'Points you already earned',
            'Your match results on past leaderboards',
          ]),
          Text('You lose', style: OgText.heading(20)),
          KitCheckList([
            'Club chat and member prices',
            'Your spot on this season’s club leaderboard',
            if (mine > 0)
              '$mine upcoming ${mine == 1 ? 'Meet' : 'Meets'} you joined. '
                  '${mine == 1 ? 'It is' : 'They are'} cancelled and refunded '
                  'in full, fee included.',
          ], crossed: true),
          if (club.isOwner)
            KitNote(
              'You own this club. Transfer ownership first, then you can '
              'leave.',
              tone: KitTone.warn,
              child: Align(
                alignment: Alignment.centerLeft,
                child: KitLink(
                  'Transfer ownership',
                  underline: true,
                  onPressed: () => context.push(Routes.clubTransfer(widget.id)),
                ),
              ),
            )
          else if (club.myRoleName != null)
            Text(
              'You are ${club.myRoleName} here. Your role is removed when you '
              'leave.',
              style: OgText.body(14, color: c.textMuted),
            ),
          if (mine > 0 && !club.isOwner)
            KitConfirmBox(
              label:
                  'I understand my $mine upcoming ${mine == 1 ? 'Meet' : 'Meets'} '
                  'will be cancelled',
              checked: _understood,
              onChanged: (v) => setState(() => _understood = v),
            ),
        ],
      );
    },
  );
}

/// Delete the club for everyone, typing its name to confirm.
class ClubDeleteScreen extends ConsumerStatefulWidget {
  const ClubDeleteScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ClubDeleteScreen> createState() => _ClubDeleteScreenState();
}

class _ClubDeleteScreenState extends ConsumerState<ClubDeleteScreen> {
  final _name = TextEditingController();
  bool _understood = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _delete(Club club) async {
    setState(() => _busy = true);
    try {
      await ref.read(clubRepositoryProvider).deleteClub(widget.id);
      HapticFeedback.mediumImpact();
      ref.invalidate(clubListProvider);
      if (!mounted) return;
      showOgToast(context, '${club.name} deleted');
      context.go(Routes.clubs);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WithClub(
    id: widget.id,
    title: 'Delete club',
    body: (club) {
      final sessions =
          ref.watch(clubSessionsProvider(widget.id)).value ?? const [];
      final reward = ref.watch(clubRewardProvider(widget.id)).value;
      return KitScaffold(
        header: const KitHeader(title: 'Delete club'),
        bottom: [
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) => KitButton(
              label: 'Delete club',
              style: KitButtonStyle.danger,
              loading: _busy,
              onPressed:
                  _understood && _name.text.trim() == club.name && club.isOwner
                  ? () => _delete(club)
                  : null,
            ),
          ),
          KitButton(
            label: 'Cancel',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          KitTitle(
            'Delete ${club.name}?',
            lead:
                'This cannot be undone. All ${club.memberCount} members are '
                'told by notification.',
          ),
          if (!club.isOwner)
            const KitNote(
              'Only the owner can delete the club.',
              tone: KitTone.warn,
            ),
          Text('What is removed', style: OgText.heading(20)),
          KitCheckList([
            '${sessions.length} upcoming ${sessions.length == 1 ? 'session' : 'sessions'}',
            'Club chat, photos and files',
            'Leaderboards, roles and the audit log',
            if (reward != null) 'Club reward progress',
          ], crossed: true),
          const KitNote(
            'Players with paid spots are refunded in full, fees included. '
            'Members keep their ratings, Passport history and points.',
          ),
          KitInput(
            label: 'Type the club name to confirm',
            controller: _name,
            hint: club.name,
          ),
          KitConfirmBox(
            label: 'I understand this deletes the club for everyone',
            checked: _understood,
            onChanged: (v) => setState(() => _understood = v),
          ),
        ],
      );
    },
  );
}
