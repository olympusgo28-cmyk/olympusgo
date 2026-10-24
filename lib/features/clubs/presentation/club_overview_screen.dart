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
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../../play/presentation/play_screen.dart' show BandRangePicker;
import '../application/club_providers.dart';
import '../domain/club_models.dart';
import '../domain/club_sport.dart';
import 'club_admin_screens.dart' show WithClub;

/// Edit the club: About, Rules, Sports and (for the owner) Ownership.
class ClubOverviewScreen extends ConsumerStatefulWidget {
  const ClubOverviewScreen({super.key, required this.id, this.tab = 'about'});

  final String id;
  final String tab;

  @override
  ConsumerState<ClubOverviewScreen> createState() => _ClubOverviewScreenState();
}

class _ClubOverviewScreenState extends ConsumerState<ClubOverviewScreen> {
  static const _tabs = ['About', 'Rules', 'Sports', 'Ownership'];
  static const _ruleKinds = [
    ('meet', 'Meet'),
    ('tournament', 'Tournament'),
    ('event', 'Event'),
  ];

  late int _tab = switch (widget.tab) {
    'rules' => 1,
    'sports' => 2,
    'ownership' => 3,
    _ => 0,
  };
  Club? _draft;
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _rules = TextEditingController();
  final _play = <String, TextEditingController>{};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _rules.dispose();
    for (final c in _play.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Club club) {
    if (_draft != null) return;
    _draft = club;
    _name.text = club.name;
    _desc.text = club.description;
    _rules.text = [for (final (i, r) in club.rules.indexed) '${i + 1}. $r']
        .join('\n');
    for (final (k, _) in _ruleKinds) {
      _play[k] = TextEditingController(text: club.playRules[k] ?? '');
    }
  }

  Future<void> _save() async {
    final d = _draft!;
    final rules = [
      for (final line in _rules.text.split('\n'))
        if (line.trim().isNotEmpty)
          line.trim().replaceFirst(RegExp(r'^\d+[.)]\s*'), ''),
    ];
    setState(() => _busy = true);
    try {
      await ref
          .read(clubRepositoryProvider)
          .updateClub(
            d.copyWith(
              name: _name.text.trim().isEmpty ? d.name : _name.text.trim(),
              description: _desc.text.trim(),
              rules: rules,
              playRules: {
                for (final e in _play.entries)
                  if (e.value.text.trim().isNotEmpty)
                    e.key: e.value.text.trim(),
              },
            ),
          );
      HapticFeedback.mediumImpact();
      refreshClub(ref.invalidate, widget.id);
      if (mounted) showOgToast(context, 'Saved');
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WithClub(
    id: widget.id,
    title: 'Overview',
    body: (club) {
      _load(club);
      final d = _draft!;
      final tabs = club.isOwner ? _tabs : _tabs.take(3).toList();
      final tab = _tab.clamp(0, tabs.length - 1);
      return KitScaffold(
        header: KitHeader(
          title: 'Overview',
          trailing: KitLink('Save', onPressed: _busy ? null : _save),
        ),
        children: [
          KitUnderlineTabs(
            labels: tabs,
            selected: tab,
            spread: true,
            padding: EdgeInsets.zero,
            onSelect: (i) => setState(() => _tab = i),
          ),
          ...switch (tab) {
            0 => _about(d),
            1 => _rulesTab(),
            2 => _sports(d),
            _ => _ownership(club),
          },
        ],
      );
    },
  );

  List<Widget> _about(Club d) {
    final c = context.og;
    return [
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CourtHero(
          color: Color(d.coverColor),
          height: 120,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClubLogo(
                  initials: d.initials,
                  color: Color(d.logoColor),
                  ink: Color(d.logoInk),
                  size: 56,
                ),
                const Spacer(),
                KitButton(
                  label: 'Change cover',
                  expand: false,
                  height: 38,
                  radius: 19,
                  fontSize: 13,
                  padding: 12,
                  style: KitButtonStyle.outline,
                  onPressed: () => showOgToast(
                    context,
                    'Cover photos come with photo uploads.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      KitInput(label: 'Club name', controller: _name, maxLength: 40),
      KitTextArea(
        label: 'Description',
        controller: _desc,
        hint: 'Who the club is for, how often it plays, what to expect',
        lines: 4,
      ),
      Text('Club type', style: OgText.heading(20)),
      Column(
        children: [
          for (final (v, sub) in const [
            (ClubVisibility.public, 'Anyone can find the club and see inside.'),
            (
              ClubVisibility.private,
              'Anyone can find it, only members see inside.',
            ),
            (ClubVisibility.hidden, 'Not in search. Invite link only.'),
          ])
            KitChoiceRow(
              title: v.label,
              subtitle: sub,
              selected: d.visibility == v,
              onTap: () => setState(() => _draft = d.copyWith(visibility: v)),
            ),
        ],
      ),
      Text(
        'Changes are saved when you tap Save.',
        style: OgText.body(13, color: c.textMuted),
      ),
    ];
  }

  List<Widget> _rulesTab() {
    final c = context.og;
    return [
      KitTextArea(
        label: 'Club rules',
        controller: _rules,
        hint:
            '1. Cancellation deadline\n2. Court fee split\n3. Shuttle and '
            'equipment policy',
        lines: 5,
      ),
      Text('Default play rules', style: OgText.heading(20)),
      Text(
        'Added to every new session of that type. Organizers can change them '
        'per session.',
        style: OgText.body(13, height: 1.4, color: c.textMuted),
      ),
      for (final (k, label) in _ruleKinds)
        KitTextArea(label: label, controller: _play[k], lines: 3),
    ];
  }

  List<Widget> _sports(Club d) {
    final c = context.og;
    final have = {for (final s in d.sports) s.sport};
    return [
      Row(
        children: [
          Expanded(child: Text('Sports', style: OgText.heading(20))),
          Text(
            '${d.sports.length} of 5',
            style: OgText.body(13, color: c.textMuted),
          ),
        ],
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in ClubSport.values)
            KitChip(
              label: s.label,
              icon: s.icon,
              selected: have.contains(s),
              onTap: () => setState(() {
                final list = [...d.sports];
                if (have.contains(s)) {
                  if (list.length > 1) list.removeWhere((x) => x.sport == s);
                } else if (list.length < 5) {
                  list.add(ClubSportLevel(sport: s));
                }
                _draft = d.copyWith(sports: list);
              }),
            ),
        ],
      ),
      Text('Skill level range', style: OgText.heading(20)),
      for (final (i, s) in d.sports.indexed)
        KitCard(
          padding: const EdgeInsets.all(14),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.sport.label,
                        style: OgText.body(16, weight: FontWeight.w700),
                      ),
                    ),
                    if (i == 0)
                      KitTag(
                        'Primary',
                        background: context.tones.gold,
                        foreground: context.tones.onGold,
                      )
                    else
                      KitLink(
                        'Make primary',
                        onPressed: () => setState(() {
                          final list = [...d.sports]..removeAt(i);
                          _draft = d.copyWith(sports: [s, ...list]);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                BandRangePicker(
                  lo: s.range.min,
                  hi: s.range.max,
                  onChanged: (lo, hi) => setState(() {
                    final list = [...d.sports];
                    list[i] = s.copyWith(range: LevelRange(lo, hi));
                    _draft = d.copyWith(sports: list);
                  }),
                ),
              ],
            ),
          ],
        ),
      Text(
        'New sessions start with these ranges. The primary sport shows on the '
        'club card.',
        style: OgText.body(13, height: 1.4, color: c.textMuted),
      ),
    ];
  }

  List<Widget> _ownership(Club club) {
    final c = context.og;
    final me = ref.watch(currentUserIdProvider).value;
    final mine = ref
        .watch(clubMembersProvider(widget.id))
        .value
        ?.where((m) => m.player.id == me)
        .firstOrNull;
    return [
      Text(
        'Only the owner sees this tab.',
        style: OgText.body(13, color: c.textMuted),
      ),
      KitCard(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              SolidAvatar.forId(
                me ?? 'me',
                initials: mine?.player.initials ?? 'Me',
                size: 44,
                fontSize: 15,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mine?.player.displayName ?? 'You',
                      style: OgText.body(15, weight: FontWeight.w700),
                    ),
                    Text(
                      club.createdAt == null
                          ? 'Owner'
                          : 'Owner since ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][club.createdAt!.month - 1]} ${club.createdAt!.year}',
                      style: OgText.body(13, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      KitCard(
        children: [
          KitNavTile(
            icon: OgIcons.roleShield,
            title: 'Transfer ownership',
            subtitle: 'Pick an admin to take over',
            onTap: () => context.push(Routes.clubTransfer(widget.id)),
          ),
          KitNavTile(
            icon: OgIcons.trash,
            title: 'Delete club',
            subtitle: 'Removes Meets, chat and leaderboard for everyone',
            danger: true,
            onTap: () => context.push(Routes.clubDelete(widget.id)),
          ),
        ],
      ),
    ];
  }
}
