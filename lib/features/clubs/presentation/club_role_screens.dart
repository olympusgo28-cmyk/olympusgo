import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../application/club_providers.dart';
import '../domain/club_models.dart';

/// The role colours, by name.
const roleColors = [
  (0xFF9A9FA5, 'Grey'),
  (0xFF0E6B4E, 'Green'),
  (0xFF3E6B8A, 'Blue'),
  (0xFF2F3A5F, 'Navy'),
  (0xFFF2C14E, 'Yellow'),
  (0xFFC8553D, 'Orange'),
  (0xFFB42318, 'Red'),
  (0xFF7A4E9C, 'Purple'),
];

String _colourName(int c) =>
    roleColors.where((r) => r.$1 == c).firstOrNull?.$2 ?? 'Custom';

class _ColourPicker extends StatelessWidget {
  const _ColourPicker({required this.value, required this.onPick});

  final int value;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final (c, name) in roleColors)
        Pressable(
          semanticLabel: name,
          selected: c == value,
          onPressed: () => onPick(c),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: Border.all(
                color: c == value ? OgColors.ink : const Color(0xFFFFFFFF),
                width: 3,
              ),
              boxShadow: [BoxShadow(color: context.og.border, spreadRadius: 1)],
            ),
          ),
        ),
    ],
  );
}

/// Pick members from the club, up to 30 at a time.
class _MemberPicker extends ConsumerStatefulWidget {
  const _MemberPicker({
    required this.clubId,
    required this.picked,
    required this.onChanged,
    this.exclude = const {},
  });

  final String clubId;
  final Set<String> picked;
  final ValueChanged<Set<String>> onChanged;
  final Set<String> exclude;

  @override
  ConsumerState<_MemberPicker> createState() => _MemberPickerState();
}

class _MemberPickerState extends ConsumerState<_MemberPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final members = ref.watch(clubMembersProvider(widget.clubId)).value;
    final q = _q.trim().toLowerCase();
    final shown = (members ?? const <ClubMember>[])
        .where((m) => !widget.exclude.contains(m.player.id))
        .where(
          (m) =>
              q.isEmpty ||
              m.player.displayName.toLowerCase().contains(q) ||
              (m.player.username ?? '').toLowerCase().contains(q),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSearchField(
          hint: 'Search members',
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 8),
        if (members == null)
          const CupertinoActivityIndicator()
        else if (shown.isEmpty)
          Text('Nobody matches.', style: OgText.body(14, color: c.textMuted))
        else
          for (final m in shown)
            KitChoiceRow(
              leading: SolidAvatar.forId(
                m.player.id,
                initials: m.player.initials,
                size: 40,
                fontSize: 14,
              ),
              title: m.player.displayName,
              subtitle: m.player.handle,
              multi: true,
              selected: widget.picked.contains(m.player.id),
              onTap: () {
                final next = {...widget.picked};
                if (!next.remove(m.player.id)) {
                  if (next.length >= 30) {
                    showOgToast(context, 'Up to 30 at a time.', error: true);
                    return;
                  }
                  next.add(m.player.id);
                }
                widget.onChanged(next);
              },
            ),
      ],
    );
  }
}

/// Everyone, then the club's roles top to bottom.
class ManageRolesScreen extends ConsumerStatefulWidget {
  const ManageRolesScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends ConsumerState<ManageRolesScreen> {
  bool _reorder = false;
  List<ClubRole>? _order;

  Future<void> _saveOrder() async {
    final order = _order;
    setState(() => _reorder = false);
    if (order == null) return;
    try {
      await ref.read(clubRepositoryProvider).reorderRoles(widget.id, [
        for (final r in order) r.id,
      ]);
      refreshClub(ref.invalidate, widget.id);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final roles = ref.watch(clubRolesProvider(widget.id)).value;
    final sorted = [...?roles]
      ..sort((a, b) => a.position.compareTo(b.position));
    final list = _order ?? sorted;
    final owner = list.where((r) => r.isOwner).toList();
    final custom = list.where((r) => !r.isOwner).toList();
    Widget roleRow(ClubRole r, {int? index}) => Pressable(
      semanticLabel: '${r.name}, ${r.memberCount} members',
      onPressed: _reorder || r.isOwner
          ? null
          : () => context.push(Routes.clubRole(widget.id, r.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Color(r.color),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: OgText.body(15, weight: FontWeight.w700)),
                  Text(
                    r.isOwner
                        ? 'All permissions · can’t be changed'
                        : r.isLabel
                        ? 'Label'
                        : '${r.permissions.length} permissions',
                    style: OgText.body(13, color: c.textMuted),
                  ),
                ],
              ),
            ),
            if (_reorder && index != null) ...[
              KitIconButton(
                icon: OgIcons.chevronUp,
                label: 'Move ${r.name} up',
                size: 18,
                onPressed: index == 0
                    ? () {}
                    : () => setState(() {
                        final l = [...custom];
                        final x = l.removeAt(index);
                        l.insert(index - 1, x);
                        _order = [...owner, ...l];
                      }),
              ),
              KitIconButton(
                icon: OgIcons.chevronDown,
                label: 'Move ${r.name} down',
                size: 18,
                onPressed: index == custom.length - 1
                    ? () {}
                    : () => setState(() {
                        final l = [...custom];
                        final x = l.removeAt(index);
                        l.insert(index + 1, x);
                        _order = [...owner, ...l];
                      }),
              ),
            ] else ...[
              OgIcon(OgIcons.people, size: 16, color: c.textMuted),
              const SizedBox(width: 4),
              Text(
                '${r.memberCount}',
                style: OgText.body(13, color: c.textMuted),
              ),
              if (!r.isOwner) ...[
                const SizedBox(width: 6),
                OgIcon(OgIcons.chevronRight, size: 16, color: c.textMuted),
              ],
            ],
          ],
        ),
      ),
    );
    return KitScaffold(
      header: const KitHeader(title: 'Roles'),
      bottom: [
        KitButton(
          label: 'Create role',
          icon: OgIcons.plus,
          onPressed: () => context.push(Routes.clubRoleNew(widget.id)),
        ),
      ],
      children: [
        const KitTitle(
          'Club roles',
          lead: 'Use roles to group members and give them permissions.',
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.people,
              title: 'Everyone',
              subtitle: 'Default permissions for all members',
              onTap: () => showKitSheet<void>(
                context,
                builder: (sheet) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: kitSpaced([
                    Text('Everyone', style: OgText.heading(22)),
                    const Text('Every member can already:'),
                    const KitCheckList([
                      'Join the club’s Meets, tournaments and events',
                      'Invite friends to the club',
                      'Rate Meets they attended',
                      'Read and write in the club chat',
                    ]),
                    const KitNote(
                      'To let members do more, give them a role such as Organizer or Admin.',
                    ),
                    KitButton(
                      label: 'Done',
                      onPressed: () => Navigator.of(sheet).pop(),
                    ),
                    const SizedBox(height: 8),
                  ], 14),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text('Roles – ${list.length}', style: OgText.heading(20)),
            ),
            KitLink(
              _reorder ? 'Done' : 'Reorder',
              onPressed: _reorder
                  ? _saveOrder
                  : () => setState(() {
                      _reorder = true;
                      _order = sorted;
                    }),
            ),
          ],
        ),
        if (roles == null)
          const CupertinoActivityIndicator()
        else
          KitCard(
            children: [
              for (final r in owner) roleRow(r),
              for (final (i, r) in custom.indexed) roleRow(r, index: i),
            ],
          ),
        Text(
          'The Owner role can’t be changed. Members show the colour of their '
          'highest role in this list.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Three steps: name and colour, how much it can do, who has it.
class CreateRoleScreen extends ConsumerStatefulWidget {
  const CreateRoleScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<CreateRoleScreen> createState() => _CreateRoleScreenState();
}

class _CreateRoleScreenState extends ConsumerState<CreateRoleScreen> {
  static const _cards = [
    (
      'Just a tag. Great for recognising members, like Founding Member or '
          'Veteran.',
      '',
      ['Shows on their profile', 'Colours their name in member lists'],
      '',
    ),
    (
      'The basics every club member gets.',
      '',
      ['Join Meets', 'Invite friends', 'Rate Meets they attended'],
      '',
    ),
    (
      'People who run Meets for the club.',
      'Everything members can do, and:',
      [
        'Create Meets',
        'Mark attendance and confirm scores',
        'Make Meets public',
      ],
      '',
    ),
    (
      'Trusted leaders who help you run the club.',
      'Everything organizers can do, and:',
      [
        'Approve join requests',
        'Manage members and roles',
        'Edit club info',
        'Run tournaments',
      ],
      'Fees and payouts always stay with the owner.',
    ),
  ];

  int _step = 0;
  final _name = TextEditingController();
  int _color = 0xFFF2C14E;
  RoleLevel _level = RoleLevel.organizer;
  Set<String> _members = {};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(clubRepositoryProvider)
          .createRole(
            widget.id,
            name: _name.text.trim(),
            color: _color,
            level: _level,
            members: _members,
          );
      HapticFeedback.mediumImpact();
      refreshClub(ref.invalidate, widget.id);
      if (!mounted) return;
      showOgToast(context, '${_name.text.trim()} created');
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
    final t = context.tones;
    final name = _name.text.trim();
    final card = _cards[_level.index];
    return KitScaffold(
      key: ValueKey(_step),
      header: KitHeader(
        title: 'Create role',
        subtitle: 'Step ${_step + 1} of 3',
        onBack: _step == 0 ? null : () => setState(() => _step--),
      ),
      bottom: [
        if (_step == 0)
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) => KitButton(
              label: 'Next',
              onPressed: _name.text.trim().length < 2
                  ? null
                  : () => setState(() => _step = 1),
            ),
          )
        else if (_step == 1) ...[
          KitButton(
            label: 'Select ${_level.title}',
            onPressed: () => setState(() => _step = 2),
          ),
          KitButton(
            label: 'Skip this step',
            style: KitButtonStyle.outline,
            onPressed: () => setState(() {
              _level = RoleLevel.member;
              _step = 2;
            }),
          ),
        ] else
          KitButton(label: 'Finish', loading: _busy, onPressed: _finish),
      ],
      children: switch (_step) {
        0 => [
          const KitTitle(
            'Create a new role',
            lead:
                'Give the role a name and colour. You can change these later.',
          ),
          KitInput(
            label: 'Role name',
            controller: _name,
            hint: 'e.g. Court Captain, Coach, Treasurer, Founding Member',
            maxLength: 30,
          ),
          Text('Role colour', style: OgText.body(15, weight: FontWeight.w700)),
          _ColourPicker(
            value: _color,
            onPick: (v) => setState(() => _color = v),
          ),
          Text(
            'Members show the colour of their highest role.',
            style: OgText.body(13, color: c.textMuted),
          ),
        ],
        1 => [
          const KitTitle(
            'Set up permissions',
            lead: 'How much can this role do? You can fine-tune permissions later.',
          ),
          KitSegments(
            labels: [for (final l in RoleLevel.values) l.title],
            selected: _level.index,
            onSelect: (i) => setState(() => _level = RoleLevel.values[i]),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.tag,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_level.title, style: OgText.heading(22)),
                const SizedBox(height: 4),
                Text(
                  card.$1,
                  style: OgText.body(14, height: 1.4, color: t.onTag),
                ),
                if (card.$2.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    card.$2,
                    style: OgText.body(14, weight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 8),
                KitCheckList(card.$3),
                if (card.$4.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(card.$4, style: OgText.body(13, color: t.onTag)),
                ],
              ],
            ),
          ),
        ],
        _ => [
          KitTitle(
            'Add members',
            lead:
                'Give ${name.isEmpty ? 'this role' : name} to club members. '
                'Members can have more than one role. Add up to 30 at a time.',
          ),
          _MemberPicker(
            clubId: widget.id,
            picked: _members,
            onChanged: (v) => setState(() => _members = v),
          ),
        ],
      },
    );
  }
}

/// One role: name, colour, badge, then permissions, members and delete.
class RoleEditScreen extends ConsumerStatefulWidget {
  const RoleEditScreen({super.key, required this.id, required this.roleId});

  final String id;
  final String roleId;

  @override
  ConsumerState<RoleEditScreen> createState() => _RoleEditScreenState();
}

class _RoleEditScreenState extends ConsumerState<RoleEditScreen> {
  TextEditingController? _name;

  @override
  void dispose() {
    _name?.dispose();
    super.dispose();
  }

  Future<void> _save(ClubRole r) async {
    try {
      await ref.read(clubRepositoryProvider).updateRole(widget.id, r);
      refreshClub(ref.invalidate, widget.id);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final role = ref
        .watch(clubRolesProvider(widget.id))
        .value
        ?.where((r) => r.id == widget.roleId)
        .firstOrNull;
    if (role == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Role'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final name = _name ??= TextEditingController(text: role.name);
    return KitScaffold(
      header: KitHeader(title: role.name),
      children: [
        Text('Role', style: OgText.heading(20)),
        Focus(
          onFocusChange: (has) {
            if (!has &&
                name.text.trim().isNotEmpty &&
                name.text.trim() != role.name) {
              _save(role.copyWith(name: name.text.trim()));
            }
          },
          child: KitInput(label: 'Role name', controller: name, maxLength: 30),
        ),
        Text(
          'Role colour · ${_colourName(role.color)}',
          style: OgText.body(15, weight: FontWeight.w700),
        ),
        _ColourPicker(
          value: role.color,
          onPick: (v) => _save(role.copyWith(color: v)),
        ),
        SwitchRow(
          compact: true,
          title: 'Show role badge',
          subtitle: "Shows this role next to members' names",
          value: role.showBadge,
          onChanged: (v) => _save(role.copyWith(showBadge: v)),
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.shieldTick,
              title: 'Permissions',
              subtitle: '${role.permissions.length} on',
              onTap: () => context.push(
                Routes.clubRolePermissions(widget.id, widget.roleId),
              ),
            ),
            KitNavTile(
              icon: OgIcons.people,
              title: 'Members',
              subtitle: '${role.memberCount}',
              onTap: () => context.push(
                Routes.clubRoleMembers(widget.id, widget.roleId),
              ),
            ),
            KitNavTile(
              icon: OgIcons.trash,
              title: 'Delete role',
              subtitle: 'Members go back to Everyone',
              danger: true,
              onTap: () =>
                  context.push(Routes.clubRoleDelete(widget.id, widget.roleId)),
            ),
          ],
        ),
        Text(
          'Changes save right away and are written to the audit log.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Presets, then each permission by group.
class RolePermissionsScreen extends ConsumerStatefulWidget {
  const RolePermissionsScreen({
    super.key,
    required this.id,
    required this.roleId,
  });

  final String id;
  final String roleId;

  @override
  ConsumerState<RolePermissionsScreen> createState() =>
      _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends ConsumerState<RolePermissionsScreen> {
  static const _groups = [
    (
      'Play',
      [
        ClubPermission.createMeet,
        ClubPermission.publicMeet,
        ClubPermission.markAttendance,
        ClubPermission.tournament,
        ClubPermission.events,
      ],
    ),
    (
      'Members',
      [ClubPermission.approve, ClubPermission.members, ClubPermission.roles],
    ),
    (
      'Club',
      [ClubPermission.editPage, ClubPermission.audit, ClubPermission.fees],
    ),
  ];
  static const _presets = {
    'None': <ClubPermission>{},
    'Organizer': ClubPermission.organizer,
    'Admin': ClubPermission.admin,
  };

  Set<ClubPermission>? _on;
  bool _busy = false;

  Future<void> _save(ClubRole role) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(clubRepositoryProvider)
          .updateRole(widget.id, role.copyWith(permissions: _on!));
      HapticFeedback.mediumImpact();
      refreshClub(ref.invalidate, widget.id);
      if (!mounted) return;
      showOgToast(context, 'Permissions saved');
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
    final role = ref
        .watch(clubRolesProvider(widget.id))
        .value
        ?.where((r) => r.id == widget.roleId)
        .firstOrNull;
    if (role == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Permissions'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final on = _on ??= {...role.permissions};
    bool same(Set<ClubPermission> a) =>
        a.length == on.length && a.containsAll(on);
    return KitScaffold(
      header: KitHeader(
        title: 'Permissions',
        subtitle: role.name,
        trailing: KitLink('Save', onPressed: _busy ? null : () => _save(role)),
      ),
      children: [
        Text(
          'Start from a preset',
          style: OgText.body(15, weight: FontWeight.w700),
        ),
        Row(
          children: [
            for (final e in _presets.entries) ...[
              KitChip(
                label: e.key,
                selected: same(e.value),
                onTap: () => setState(() => _on = {...e.value}),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        Text(
          'Everyone can already join Meets, invite friends and rate Meets they '
          'attended.',
          style: OgText.body(13, height: 1.4, color: c.textMuted),
        ),
        for (final (title, perms) in _groups)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: OgText.heading(20)),
              const SizedBox(height: 4),
              for (final p in perms)
                Opacity(
                  opacity: p == ClubPermission.fees ? 0.5 : 1,
                  child: SwitchRow(
                    compact: true,
                    title: p.label,
                    subtitle: p.hint,
                    value: on.contains(p),
                    onChanged: (v) {
                      if (p == ClubPermission.fees) return;
                      setState(() => v ? on.add(p) : on.remove(p));
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Who has a role; add or remove them.
class RoleMembersScreen extends ConsumerWidget {
  const RoleMembersScreen({super.key, required this.id, required this.roleId});

  final String id;
  final String roleId;

  Future<void> _set(
    BuildContext context,
    WidgetRef ref,
    Set<String> ids,
  ) async {
    try {
      await ref.read(clubRepositoryProvider).setRoleMembers(id, roleId, ids);
      refreshClub(ref.invalidate, id);
    } on AuthFailure catch (e) {
      if (context.mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final role = ref
        .watch(clubRolesProvider(id))
        .value
        ?.where((r) => r.id == roleId)
        .firstOrNull;
    final members = ref.watch(clubMembersProvider(id)).value;
    if (role == null || members == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Members'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final having = members.where((m) => m.roleIds.contains(roleId)).toList();
    final ids = {for (final m in having) m.player.id};
    return KitScaffold(
      header: KitHeader(
        title: role.name,
        subtitle: 'Members · ${having.length}',
      ),
      bottom: [
        KitButton(
          label: 'Add members',
          icon: OgIcons.plus,
          onPressed: () async {
            final added = await showKitSheet<Set<String>>(
              context,
              builder: (_) => _AddMembersSheet(
                clubId: id,
                roleName: role.name,
                exclude: ids,
              ),
            );
            if (added != null && added.isNotEmpty && context.mounted) {
              await _set(context, ref, {...ids, ...added});
            }
          },
        ),
      ],
      children: [
        if (having.isEmpty)
          Text(
            'Nobody has this role yet.',
            style: OgText.body(14, color: c.textMuted),
          )
        else
          KitCard(
            children: [
              for (final m in having)
                Padding(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.player.displayName,
                              style: OgText.body(15, weight: FontWeight.w700),
                            ),
                            Text(
                              m.player.handle,
                              style: OgText.body(13, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      KitIconButton(
                        icon: OgIcons.closeSmall,
                        label:
                            'Remove ${m.player.displayName} from ${role.name}',
                        size: 18,
                        onPressed: () =>
                            _set(context, ref, {...ids}..remove(m.player.id)),
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

class _AddMembersSheet extends StatefulWidget {
  const _AddMembersSheet({
    required this.clubId,
    required this.roleName,
    required this.exclude,
  });

  final String clubId;
  final String roleName;
  final Set<String> exclude;

  @override
  State<_AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<_AddMembersSheet> {
  Set<String> _picked = {};

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Add to ${widget.roleName}',
                style: OgText.heading(22),
              ),
            ),
            KitLink('Add', onPressed: () => Navigator.of(context).pop(_picked)),
          ],
        ),
        Text(
          'Select up to 30 · ${_picked.length} selected',
          style: OgText.body(13, color: context.og.textMuted),
        ),
        const SizedBox(height: 10),
        _MemberPicker(
          clubId: widget.clubId,
          picked: _picked,
          exclude: widget.exclude,
          onChanged: (v) => setState(() => _picked = v),
        ),
      ],
    ),
  );
}

/// Delete a role; its members go back to Everyone.
class RoleDeleteScreen extends ConsumerStatefulWidget {
  const RoleDeleteScreen({super.key, required this.id, required this.roleId});

  final String id;
  final String roleId;

  @override
  ConsumerState<RoleDeleteScreen> createState() => _RoleDeleteScreenState();
}

class _RoleDeleteScreenState extends ConsumerState<RoleDeleteScreen> {
  bool _busy = false;

  Future<void> _delete(ClubRole role) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(clubRepositoryProvider)
          .deleteRole(widget.id, widget.roleId);
      HapticFeedback.mediumImpact();
      refreshClub(ref.invalidate, widget.id);
      if (!mounted) return;
      showOgToast(context, '${role.name} deleted');
      context.go(Routes.clubRoles(widget.id));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final role = ref
        .watch(clubRolesProvider(widget.id))
        .value
        ?.where((r) => r.id == widget.roleId)
        .firstOrNull;
    final having =
        ref
            .watch(clubMembersProvider(widget.id))
            .value
            ?.where((m) => m.roleIds.contains(widget.roleId))
            .toList() ??
        const [];
    if (role == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Delete role'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final names = having.map((m) => m.player.displayName).toList();
    return KitScaffold(
      header: const KitHeader(title: 'Delete role'),
      bottom: [
        KitButton(
          label: 'Delete role',
          style: KitButtonStyle.danger,
          loading: _busy,
          onPressed: () => _delete(role),
        ),
        KitButton(
          label: 'Cancel',
          style: KitButtonStyle.outline,
          onPressed: () => context.pop(),
        ),
      ],
      children: [
        KitTitle(
          'Delete ${role.name}?',
          lead:
              '${having.length} ${having.length == 1 ? 'member has' : 'members have'} this role.',
        ),
        Text('What happens', style: OgText.heading(20)),
        KitCheckList([
          if (names.isNotEmpty)
            '${names.length <= 2 ? names.join(' and ') : '${names.length} members'} '
                '${names.length == 1 ? 'goes' : 'go'} back to the Everyone role',
          'Permissions this role gave are removed right away',
          'The change is written to the audit log',
        ]),
        Text(
          'Meets they already created stay as they are. An Admin can still '
          'edit them.',
          style: OgText.body(14, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}
