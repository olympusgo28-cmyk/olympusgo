import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/share.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../wallet/presentation/wallet_screens.dart' show cash, MoneyRow;
import '../application/academy_providers.dart';
import '../domain/academy_models.dart';
import '../domain/academy_more.dart';
import 'academy_screens.dart' show classDays;

/// Loads the academy, then builds [body].
class _WithAcademy extends ConsumerWidget {
  const _WithAcademy({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final Widget Function(Academy a) body;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(academyProvider(id))) {
        AsyncData(:final value) => body(value),
        AsyncError() => KitScaffold(
          header: KitHeader(title: title),
          children: const [KitNote("This academy isn't available any more.")],
        ),
        _ => KitScaffold(
          header: KitHeader(title: title),
          children: const [CupertinoActivityIndicator()],
        ),
      };
}

/// The head coach's settings for the academy.
class AcademySettingsScreen extends StatelessWidget {
  const AcademySettingsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => _WithAcademy(
    id: id,
    title: 'Academy settings',
    body: (a) {
      final c = context.og;
      final t = context.tones;
      final head = a.myRole == AcademyRole.headCoach;
      return KitScaffold(
        header: const KitHeader(title: 'Academy settings'),
        children: [
          Row(
            children: [
              ClubLogo(
                initials: a.initials,
                color: Color(a.color),
                ink: Color(a.ink),
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(a.name, style: OgText.heading(22)),
                        ),
                        if (a.verified) ...[
                          const SizedBox(width: 6),
                          KitTag(
                            'Verified',
                            height: 22,
                            fontSize: 11,
                            background: t.successFill,
                            foreground: t.onSuccessFill,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${a.coaches.length} coaches · ${a.students} students · ${a.classes.length} classes',
                      style: OgText.body(13, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          KitCard(
            children: [
              KitNavTile(
                icon: OgIcons.pencil,
                title: 'Details',
                subtitle: 'Name, photos, ages and venues',
                onTap: () => context.push(Routes.academy(a.id)),
              ),
              KitNavTile(
                icon: OgIcons.racquet,
                title: 'Sport and levels',
                subtitle:
                    '${a.sport.label}, ${{for (final x in a.classes) x.level}.length} levels',
                onTap: () => context.push(Routes.curriculum(a.id)),
              ),
              KitNavTile(
                icon: OgIcons.walletCard,
                title: 'Billing and make-ups',
                subtitle:
                    '${a.billing.label}, ${a.makeupsPerMonth} make-ups each month',
                chevron: false,
                onTap: () {},
              ),
              KitNavTile(
                icon: OgIcons.shieldTick,
                title: 'Verification',
                subtitle: a.verified
                    ? 'Business licence checked'
                    : 'Not verified yet',
                chevron: false,
                onTap: () {},
              ),
              KitNavTile(
                icon: OgIcons.people,
                title: 'Coaches',
                subtitle:
                    '${a.coaches.length} coaches${a.coaches.every((x) => x.nroc) ? ', all NROC licensed' : ''}',
                chevron: false,
                onTap: () {},
              ),
              KitNavTile(
                icon: OgIcons.personRequest,
                title: 'Enrolment requests',
                subtitle: a.pendingRequests == 0
                    ? 'Nobody is waiting'
                    : '${a.pendingRequests} waiting',
                onTap: () => context.push(Routes.academyRequests(a.id)),
              ),
              KitNavTile(
                icon: OgIcons.discover,
                title: 'Public page',
                subtitle: 'What parents and players see',
                onTap: () => context.push(Routes.academy(a.id)),
              ),
              KitNavTile(
                icon: OgIcons.wallet,
                title: 'Coach pay',
                subtitle: 'Your classes and what you are paid',
                onTap: () => context.push(Routes.coachPay),
              ),
            ],
          ),
          if (head)
            KitCard(
              children: [
                KitNavTile(
                  icon: OgIcons.trash,
                  title: 'Close academy',
                  subtitle: 'Stop classes and refund unused lessons',
                  danger: true,
                  onTap: () => context.push(Routes.academyClose(a.id)),
                ),
              ],
            ),
        ],
      );
    },
  );
}

/// Parents and students who wrote to the academy.
class AcademyMessagesScreen extends ConsumerStatefulWidget {
  const AcademyMessagesScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AcademyMessagesScreen> createState() =>
      _AcademyMessagesScreenState();
}

class _AcademyMessagesScreenState extends ConsumerState<AcademyMessagesScreen> {
  String _q = '';
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final all = ref.watch(academyMessagesProvider(widget.id)).value;
    final q = _q.trim().toLowerCase();
    final shown = (all ?? const <MessageThread>[])
        .where((m) => _tab == 0 || (_tab == 1 ? m.unread > 0 : !m.parent))
        .where((m) => q.isEmpty || m.name.toLowerCase().contains(q))
        .toList();
    String when(DateTime at) {
      final d = DateTime.now().difference(at);
      if (d.inHours < 24 && at.day == DateTime.now().day) return Fmt.time(at);
      if (d.inDays < 2) return 'Yesterday';
      return const [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][at.weekday - 1];
    }

    return KitScaffold(
      header: const KitHeader(title: 'Messages'),
      bottom: [
        KitButton(
          label: 'Message all parents',
          onPressed: () => showOgToast(
            context,
            'Open a class and choose Message parents to write to a whole class.',
          ),
        ),
      ],
      children: [
        KitSearchField(
          hint: 'Search parents and students',
          onChanged: (v) => setState(() => _q = v),
        ),
        KitSegments(
          labels: const ['All', 'Unread', 'Students'],
          selected: _tab,
          onSelect: (i) => setState(() => _tab = i),
        ),
        if (all == null)
          const CupertinoActivityIndicator()
        else if (shown.isEmpty)
          Text(
            'Nothing matches. Check the spelling or clear the search.',
            style: OgText.body(14, color: c.textMuted),
          )
        else
          KitCard(
            children: [
              for (final m in shown)
                Pressable(
                  semanticLabel: '${m.name}, ${m.last}',
                  onPressed: () => showOgToast(
                    context,
                    'Academy chats open with the next release. Reply by phone for now.',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        SolidAvatar.forId(
                          m.id,
                          initials: m.initials,
                          size: 44,
                          fontSize: 15,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.name,
                                      style: OgText.body(
                                        15,
                                        weight: m.unread > 0
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    when(m.at),
                                    style: OgText.body(12, color: c.textMuted),
                                  ),
                                ],
                              ),
                              Text(
                                m.last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: OgText.body(13, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (m.unread > 0) ...[
                          const SizedBox(width: 8),
                          KitCountBadge(m.unread, size: 22),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        Text(
          'To message a whole class at once, open the class and choose Message parents.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Close the academy for good.
class AcademyCloseScreen extends ConsumerStatefulWidget {
  const AcademyCloseScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AcademyCloseScreen> createState() => _AcademyCloseScreenState();
}

class _AcademyCloseScreenState extends ConsumerState<AcademyCloseScreen> {
  final _name = TextEditingController();
  bool _understood = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _close(Academy a) async {
    setState(() => _busy = true);
    try {
      await ref.read(academyRepositoryProvider).closeAcademy(a.id);
      HapticFeedback.mediumImpact();
      ref.invalidate(academyListProvider);
      if (!mounted) return;
      showOgToast(context, '${a.name} is closed. Parents are told.');
      context.go(Routes.academies);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WithAcademy(
    id: widget.id,
    title: 'Close academy',
    body: (a) {
      final refund = a.classes.fold(
        0,
        (s, x) => s + x.enrolled * x.feeCents ~/ 4,
      );
      return KitScaffold(
        header: const KitHeader(title: 'Close academy'),
        bottom: [
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) => KitButton(
              label: 'Close academy',
              style: KitButtonStyle.danger,
              loading: _busy,
              onPressed: _understood && _name.text.trim() == a.name
                  ? () => _close(a)
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
            'Close ${a.name}?',
            lead: 'This ends every class and cannot be undone.',
          ),
          Text('What happens', style: OgText.heading(20)),
          KitCheckList([
            '${a.classes.length} classes stop after today',
            '${a.students} students and their parents are told',
            'Unused lessons this month are refunded, about ${cash(refund)}',
            'Coaches lose access to class tools',
          ]),
          const KitNote(
            'Students keep their progress reports and level history in their Passport.',
          ),
          KitInput(
            label: 'Type the academy name to confirm',
            controller: _name,
            hint: a.name,
          ),
          KitConfirmBox(
            label: 'I understand all classes end and lessons are refunded',
            checked: _understood,
            onChanged: (v) => setState(() => _understood = v),
          ),
        ],
      );
    },
  );
}

/// A cover coach, a new time, or a cancellation; parents are told.
class ChangeClassScreen extends ConsumerStatefulWidget {
  const ChangeClassScreen({super.key, required this.id, required this.classId});

  final String id;
  final String classId;

  @override
  ConsumerState<ChangeClassScreen> createState() => _ChangeClassScreenState();
}

class _ChangeClassScreenState extends ConsumerState<ChangeClassScreen> {
  String _mode = 'coach';
  String? _coach;
  int _dayShift = 1;
  final _notice = TextEditingController();
  bool _edited = false;
  bool _busy = false;
  int? _told;

  @override
  void dispose() {
    _notice.dispose();
    super.dispose();
  }

  String _draft(AcademyClass x, DateTime at) {
    final name = x.name;
    final when = '${Fmt.day(at)}, ${Fmt.timeRange(at, x.endOf(at))}';
    final moved = at.add(Duration(days: _dayShift));
    return switch (_mode) {
      'coach' =>
        'Hi, ${x.coach} can’t take $name this week. ${_coach ?? 'Another coach'} will take it at the usual time, $when${x.court.isEmpty ? '' : ' on ${x.court}'}, following the same lesson plan. See you there!',
      'time' =>
        'Hi, $name on ${Fmt.day(at)} is moving to ${Fmt.day(moved)}, ${Fmt.timeRange(moved, x.endOf(moved))}. Please tap Confirm, or Can’t make it to get a make-up credit.',
      _ =>
        'Hi, $name on ${Fmt.day(at)} is cancelled. Your child has a make-up credit to use within 30 days. Sorry for the short notice.',
    };
  }

  Future<void> _send(AcademyClass x, DateTime at) async {
    setState(() => _busy = true);
    try {
      final n = await ref
          .read(academyRepositoryProvider)
          .changeClass(
            x.id,
            mode: _mode,
            coach: _coach,
            at: _mode == 'time' ? at.add(Duration(days: _dayShift)) : null,
            notice: _notice.text.trim(),
          );
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _told = n);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WithAcademy(
    id: widget.id,
    title: 'Change a class',
    body: (a) {
      final c = context.og;
      final t = context.tones;
      final x =
          a.classes.where((x) => x.id == widget.classId).firstOrNull ??
          a.classes.first;
      final at = x.nextAt();
      final coaches =
          ref.watch(coverCoachesProvider(x.id)).value ?? const <CoverCoach>[];
      if (_coach == null && coaches.isNotEmpty) {
        _coach = coaches.firstWhere((k) => !k.blocked).name;
      }
      if (!_edited) _notice.text = _draft(x, at);
      if (_told case final n?) {
        return KitScaffold(
          header: const KitHeader(title: 'Change a class'),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          bottom: [KitButton(label: 'Done', onPressed: () => context.pop())],
          children: [
            const KitDoneBanner(title: 'Parents told'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sent to $n parents as an app notification. Parents who haven’t opened it after 2 hours get an SMS.'
                '${_mode == 'cancel' ? ' Every student has a make-up credit, valid for 30 days.' : ''}',
                style: OgText.body(15, height: 1.45, color: c.textMuted),
              ),
            ),
          ],
        );
      }
      return KitScaffold(
        header: const KitHeader(title: 'Change a class'),
        bottom: [
          KitButton(
            label: 'Send to ${x.enrolled} parents',
            loading: _busy,
            onPressed: () => _send(x, at),
          ),
        ],
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 64,
                decoration: BoxDecoration(
                  color: t.tag,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      const [
                        'MON',
                        'TUE',
                        'WED',
                        'THU',
                        'FRI',
                        'SAT',
                        'SUN',
                      ][at.weekday - 1],
                      style: OgText.body(
                        11,
                        weight: FontWeight.w800,
                        color: t.onTag,
                      ),
                    ),
                    Text('${at.day}', style: OgText.heading(20)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(x.name, style: OgText.heading(18)),
                    Text(
                      '${Fmt.timeRange(at, x.endOf(at))}${x.court.isEmpty ? '' : ' · ${x.court}'} · ${x.enrolled} students',
                      style: OgText.body(13, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text('What changes?', style: OgText.heading(20)),
          KitSegments(
            labels: const ['New coach', 'New time', 'Cancel'],
            selected: const ['coach', 'time', 'cancel'].indexOf(_mode),
            onSelect: (i) => setState(() {
              _mode = const ['coach', 'time', 'cancel'][i];
              _edited = false;
            }),
          ),
          if (_mode == 'coach') ...[
            Column(
              children: [
                for (final k in coaches)
                  Opacity(
                    opacity: k.blocked ? 0.5 : 1,
                    child: KitChoiceRow(
                      leading: SolidAvatar.forId(
                        k.name,
                        initials: k.initials,
                        size: 40,
                        fontSize: 14,
                      ),
                      title: k.name,
                      subtitle: k.free,
                      selected: _coach == k.name,
                      onTap: k.blocked
                          ? () {}
                          : () => setState(() {
                              _coach = k.name;
                              _edited = false;
                            }),
                    ),
                  ),
              ],
            ),
            Text(
              'Same time and court. The cover coach gets this week’s lesson plan, the roster and each student’s skills.',
              style: OgText.body(13, height: 1.4, color: c.textMuted),
            ),
          ] else if (_mode == 'time') ...[
            Text('New date', style: OgText.body(15, weight: FontWeight.w700)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in const [1, 2, 3, 7])
                  KitChip(
                    label: Fmt.day(at.add(Duration(days: d))),
                    selected: _dayShift == d,
                    onTap: () => setState(() {
                      _dayShift = d;
                      _edited = false;
                    }),
                  ),
              ],
            ),
            KitKeyValue(
              'New time',
              Fmt.timeRange(
                at.add(Duration(days: _dayShift)),
                x.endOf(at.add(Duration(days: _dayShift))),
              ),
            ),
            KitKeyValue(
              'Court',
              '${x.court.isEmpty ? 'Usual court' : x.court} · free',
            ),
            Text(
              'Parents confirm if their child can come. Anyone who can’t gets a make-up credit automatically.',
              style: OgText.body(13, height: 1.4, color: c.textMuted),
            ),
          ] else
            KitNote(
              'All ${x.enrolled} students get a make-up credit, valid for 30 days. They can book any class teaching the same lesson.',
              tone: KitTone.warn,
            ),
          Text(
            'Notice to parents · ${x.enrolled} parents',
            style: OgText.heading(20),
          ),
          KitTextArea(
            label: 'Message',
            controller: _notice,
            lines: 5,
            onChanged: (_) => _edited = true,
          ),
          Text(
            'Sent as an app notification. Parents who haven’t opened it after 2 hours get an SMS.',
            style: OgText.body(13, color: c.textMuted),
          ),
        ],
      );
    },
  );
}

/// The coach's pay for last month.
class CoachPayScreen extends ConsumerWidget {
  const CoachPayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final p = ref.watch(coachPayProvider).value;
    if (p == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Coach pay'),
        children: [CupertinoActivityIndicator()],
      );
    }
    Widget tile(String big, String small) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: t.tag,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(big, style: OgText.heading(20)),
            Text(small, style: OgText.body(12, color: t.onTag)),
          ],
        ),
      ),
    );
    return KitScaffold(
      header: const KitHeader(title: 'Coach pay'),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OgColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p.month.toUpperCase()} PAY',
                style: OgText.body(
                  12,
                  weight: FontWeight.w800,
                  color: t.gold,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                cash(p.totalCents),
                style: OgText.heading(44, color: const Color(0xFFFFFFFF)),
              ),
              Text(
                'Paid on ${Fmt.day(p.paidOn)} to your payout account.',
                style: OgText.body(14, color: const Color(0xFFC9C6BC)),
              ),
            ],
          ),
        ),
        Row(
          children: [
            tile('${p.classes}', 'classes'),
            const SizedBox(width: 8),
            tile('S\$${p.rateCents ~/ 100}', 'per class'),
            const SizedBox(width: 8),
            tile('${p.covers}', 'covers'),
          ],
        ),
        Text('This month', style: OgText.heading(20)),
        KitCard(
          children: [
            for (final (title, sub, cents) in p.lines)
              MoneyRow(title: title, sub: sub, amount: cash(cents)),
          ],
        ),
        Text(
          'Your rate is set by the academy owner. Trial classes and make-up classes count as normal classes.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.walletCard,
              title: 'Payout account',
              onTap: () => context.push(Routes.payoutAccount),
            ),
          ],
        ),
        if (p.past.isNotEmpty) ...[
          Text('Past months', style: OgText.heading(20)),
          KitCard(
            children: [
              for (final (m, cents) in p.past)
                MoneyRow(title: m, sub: 'Paid', amount: cash(cents)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Shared curriculum: where each class is, and the weeks of a level.
class CurriculumScreen extends ConsumerStatefulWidget {
  const CurriculumScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends ConsumerState<CurriculumScreen> {
  int _level = 2;
  int _open = 5;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final weeks = ref.watch(curriculumProvider(widget.id, _level)).value;
    final classes =
        ref.watch(curriculumClassesProvider(widget.id, _level)).value ??
        const [];
    const levels = {
      1: 'L1 · First Rallies',
      2: 'L2 · Rally Builders',
      3: 'L3 · Match Play',
    };
    return KitScaffold(
      header: const KitHeader(title: 'Curriculum'),
      children: [
        Text(
          'Shared by all coaches',
          style: OgText.body(14, color: c.textMuted),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final e in levels.entries) ...[
                KitChip(
                  label: e.value,
                  selected: _level == e.key,
                  onTap: () => setState(() => _level = e.key),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Text('Where each class is', style: OgText.heading(20)),
        KitCard(
          children: [
            for (final p in classes)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SolidAvatar.forId(
                      p.name,
                      initials: p.initials,
                      size: 36,
                      fontSize: 12,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: OgText.body(14, weight: FontWeight.w700),
                          ),
                          Text(
                            p.sub,
                            style: OgText.body(12, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    KitTag(
                      p.behind ? '1 WEEK BEHIND' : 'ON TRACK',
                      height: 22,
                      fontSize: 10,
                      background: p.behind ? t.warnFill : t.successFill,
                      foreground: p.behind ? t.onWarnFill : t.onSuccessFill,
                    ),
                  ],
                ),
              ),
          ],
        ),
        Text(
          'Level $_level · ${weeks?.length ?? 10} weeks',
          style: OgText.heading(20),
        ),
        if (weeks == null)
          const CupertinoActivityIndicator()
        else
          KitCard(
            children: [
              for (final w in weeks)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Pressable(
                      semanticLabel: 'Week ${w.week}, ${w.topic}',
                      onPressed: () =>
                          setState(() => _open = _open == w.week ? 0 : w.week),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: w.week == 5 ? c.primary : t.tag,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${w.week}',
                                style: OgText.body(
                                  13,
                                  weight: FontWeight.w800,
                                  color: w.week == 5 ? c.onPrimary : t.onTag,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.topic,
                                    style: OgText.body(
                                      14,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    w.skills,
                                    style: OgText.body(12, color: c.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (w.week == 5)
                              KitTag(
                                'This week',
                                height: 22,
                                fontSize: 11,
                                background: t.gold,
                                foreground: t.onGold,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_open == w.week)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(54, 0, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (w.drills.isEmpty)
                              Text(
                                'No drills planned yet.',
                                style: OgText.body(13, color: c.textMuted),
                              )
                            else
                              for (final d in w.drills)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          d.name,
                                          style: OgText.body(13),
                                        ),
                                      ),
                                      Text(
                                        '${d.minutes} min',
                                        style: OgText.body(
                                          13,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            if (w.version.isNotEmpty)
                              Text(
                                w.version,
                                style: OgText.body(12, color: c.textMuted),
                              ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: KitLink(
                                'Edit plan',
                                underline: true,
                                onPressed: () => context.push(
                                  Routes.lessonPlan(widget.id, _level, w.week),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        Text(
          'When you edit a week, every coach teaching Level $_level sees the new plan in their class and gets a short “what changed” note.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Edit a week's lesson plan: drills, minutes, and drills from videos.
class LessonPlanEditScreen extends ConsumerStatefulWidget {
  const LessonPlanEditScreen({
    super.key,
    required this.id,
    required this.level,
    required this.week,
  });

  final String id;
  final int level;
  final int week;

  @override
  ConsumerState<LessonPlanEditScreen> createState() =>
      _LessonPlanEditScreenState();
}

class _LessonPlanEditScreenState extends ConsumerState<LessonPlanEditScreen> {
  List<Drill>? _drills;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _addVideos() async {
    final picked = await showKitSheet<List<Drill>>(
      context,
      builder: (_) => const _DrillPicker(),
    );
    if (picked != null) setState(() => _drills = [..._drills!, ...picked]);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(academyRepositoryProvider)
          .saveLessonPlan(
            widget.id,
            widget.level,
            widget.week,
            drills: _drills!,
            note: _note.text.trim(),
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(curriculumProvider);
      if (!mounted) return;
      showOgToast(context, 'Plan saved. Other coaches are told what changed.');
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
    final weeks = ref.watch(curriculumProvider(widget.id, widget.level)).value;
    final w = weeks?.where((w) => w.week == widget.week).firstOrNull;
    if (w == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Edit plan'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final drills = _drills ??= [...w.drills];
    final total = drills.fold(0, (a, d) => a + d.minutes);
    return KitScaffold(
      header: const KitHeader(title: 'Edit plan'),
      bottom: [KitButton(label: 'Save plan', loading: _busy, onPressed: _save)],
      children: [
        Text(
          'Level ${widget.level}, Week ${w.week} · ${w.topic}',
          style: OgText.heading(20),
        ),
        KitKeyValue('Skills this week', w.skills),
        Row(
          children: [
            Expanded(child: Text('Drills', style: OgText.heading(20))),
            Text(
              '$total min',
              style: OgText.body(
                14,
                weight: FontWeight.w700,
                color: total > 90 ? context.tones.onDangerFill : c.textMuted,
              ),
            ),
          ],
        ),
        KitCard(
          children: [
            for (final (i, d) in drills.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.name,
                        style: OgText.body(14, weight: FontWeight.w600),
                      ),
                    ),
                    KitQty(
                      value: d.minutes,
                      label: 'minutes',
                      onLess: d.minutes <= 5
                          ? null
                          : () => setState(
                              () => drills[i] = Drill(
                                d.name,
                                d.minutes - 5,
                                tag: d.tag,
                                video: d.video,
                              ),
                            ),
                      onMore: () => setState(
                        () => drills[i] = Drill(
                          d.name,
                          d.minutes + 5,
                          tag: d.tag,
                          video: d.video,
                        ),
                      ),
                    ),
                    KitIconButton(
                      icon: OgIcons.trash,
                      label: 'Remove ${d.name}',
                      size: 18,
                      onPressed: () => setState(() => drills.removeAt(i)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        KitButton(
          label: 'Add drills from the video library',
          icon: OgIcons.plus,
          style: KitButtonStyle.outline,
          onPressed: _addVideos,
        ),
        if (total > 90)
          Text(
            'The plan is longer than the 90-minute class.',
            style: OgText.body(13, color: context.tones.onDangerFill),
          ),
        KitTextArea(
          label: 'Note for the other coaches',
          optional: true,
          controller: _note,
          hint: 'Lucas and Maya need the grip check before the feed drill.',
        ),
      ],
    );
  }
}

class _DrillPicker extends ConsumerStatefulWidget {
  const _DrillPicker();

  @override
  ConsumerState<_DrillPicker> createState() => _DrillPickerState();
}

class _DrillPickerState extends ConsumerState<_DrillPicker> {
  String _tag = 'All';
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(drillVideosProvider).value ?? const <Drill>[];
    final shown = all.where((d) => _tag == 'All' || d.tag == _tag).toList();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Drill videos', style: OgText.heading(22)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in const [
                'All',
                'Footwork',
                'Serve',
                'Smash',
                'Net',
              ])
                KitChip(
                  label: t,
                  selected: _tag == t,
                  onTap: () => setState(() => _tag = t),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final d in shown)
            KitChoiceRow(
              leading: Container(
                width: 52,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: OgColors.ink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  d.video,
                  style: OgText.body(
                    11,
                    weight: FontWeight.w700,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
              title: d.name,
              subtitle: '${d.tag} · ${d.minutes} min',
              multi: true,
              selected: _picked.contains(d.name),
              onTap: () => setState(
                () => _picked.contains(d.name)
                    ? _picked.remove(d.name)
                    : _picked.add(d.name),
              ),
            ),
          const SizedBox(height: 14),
          KitButton(
            label: _picked.isEmpty
                ? 'Tap videos to add them'
                : 'Add ${_picked.length} to the plan',
            onPressed: _picked.isEmpty
                ? null
                : () => Navigator.of(context).pop([
                    for (final d in all)
                      if (_picked.contains(d.name)) d,
                  ]),
          ),
        ],
      ),
    );
  }
}

/// Invite students to a class by link or text message.
class InviteStudentsScreen extends ConsumerStatefulWidget {
  const InviteStudentsScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<InviteStudentsScreen> createState() =>
      _InviteStudentsScreenState();
}

class _InviteStudentsScreenState extends ConsumerState<InviteStudentsScreen> {
  String? _class;
  final _mobile = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _send(String classId) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(academyRepositoryProvider)
          .inviteParent(classId, _mobile.text);
      HapticFeedback.mediumImpact();
      _mobile.clear();
      ref.invalidate(pendingInvitesProvider(classId));
      if (mounted) showOgToast(context, 'Invite sent by text message.');
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WithAcademy(
    id: widget.id,
    title: 'Invite students',
    body: (a) {
      final c = context.og;
      final cls =
          a.classes.where((x) => x.id == _class).firstOrNull ?? a.classes.first;
      final pending =
          ref.watch(pendingInvitesProvider(cls.id)).value ?? const [];
      final link = Links.academyClass(a.id, cls.id);
      return KitScaffold(
        header: const KitHeader(title: 'Invite students'),
        bottom: [KitButton(label: 'Done', onPressed: () => context.pop())],
        children: [
          const KitTitle(
            'Add students to a class',
            lead: 'Parents get a link. The student joins once the parent accepts and pays the first month.',
          ),
          Text('Class', style: OgText.heading(20)),
          Column(
            children: [
              for (final x in a.classes)
                KitChoiceRow(
                  title: x.name,
                  subtitle: classDays(x),
                  tag: x.full
                      ? 'Full'
                      : '${x.spotsLeft} ${x.spotsLeft == 1 ? 'spot' : 'spots'}',
                  selected: cls.id == x.id,
                  onTap: () => setState(() => _class = x.id),
                ),
            ],
          ),
          KitCard(
            padding: const EdgeInsets.all(14),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Invite link for ${cls.name}',
                    style: OgText.body(15, weight: FontWeight.w700),
                  ),
                  Text(
                    '${link.replaceFirst('https://', '')} · valid 7 days',
                    style: OgText.body(13, color: c.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: KitButton(
                          label: 'Copy',
                          height: 44,
                          style: KitButtonStyle.outline,
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
                            'Join ${cls.name} at ${a.name}',
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
          Text('Or send to a parent’s mobile', style: OgText.heading(20)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: KitInput(
                  label: 'Mobile',
                  controller: _mobile,
                  hint: '9123 4567',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: KitButton(
                  label: 'Send',
                  expand: false,
                  loading: _busy,
                  onPressed: () => _send(cls.id),
                ),
              ),
            ],
          ),
          if (pending.isNotEmpty) ...[
            Text('Waiting for an answer', style: OgText.heading(20)),
            KitCard(
              children: [
                for (final (who, sent) in pending)
                  MoneyRow(title: who, sub: sent, amount: ''),
              ],
            ),
          ],
        ],
      );
    },
  );
}

/// A student's attendance this term.
class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final s = ref.watch(studentProvider(studentId)).value;
    final lines = ref.watch(attendanceProvider(studentId)).value;
    if (s == null || lines == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Attendance'),
        children: [CupertinoActivityIndicator()],
      );
    }
    int count(String state) => lines.where((l) => l.state == state).length;
    Widget tile(int n, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: t.tag,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text('$n', style: OgText.heading(22)),
            Text(label, style: OgText.body(12, color: t.onTag)),
          ],
        ),
      ),
    );
    return KitScaffold(
      header: const KitHeader(title: 'Attendance'),
      bottom: [
        KitButton(
          label: 'Book a make-up class',
          onPressed: () => context.push(Routes.studentMakeup(studentId)),
        ),
        KitButton(
          label: 'See progress',
          style: KitButtonStyle.outline,
          onPressed: () => context.push(Routes.studentProgress(studentId)),
        ),
      ],
      children: [
        KitTitle(s.name),
        Row(
          children: [
            tile(count('Present'), 'present'),
            const SizedBox(width: 8),
            tile(count('Absent'), 'absent'),
            const SizedBox(width: 8),
            tile(count('Make-up'), 'make-up used'),
          ],
        ),
        Text('This term', style: OgText.heading(20)),
        KitCard(
          children: [
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Fmt.day(l.at),
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          Text(
                            l.lesson,
                            style: OgText.body(13, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    KitTag(
                      l.state,
                      background: switch (l.state) {
                        'Present' => t.successFill,
                        'Absent' => t.dangerFill,
                        _ => t.tag,
                      },
                      foreground: switch (l.state) {
                        'Present' => t.onSuccessFill,
                        'Absent' => t.onDangerFill,
                        _ => t.onTag,
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
        Text(
          'Miss a class with 24 hours’ notice and you get 1 make-up credit. Credits last 30 days.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// A coach's note to one parent about today's skills.
class ParentNoteScreen extends ConsumerStatefulWidget {
  const ParentNoteScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<ParentNoteScreen> createState() => _ParentNoteScreenState();
}

class _ParentNoteScreenState extends ConsumerState<ParentNoteScreen> {
  final _marks = <String, SkillStatus>{};
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send(Student s) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(academyRepositoryProvider)
          .sendParentNote(s.id, skills: _marks, note: _note.text.trim());
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      showOgToast(context, 'Sent to ${s.firstName}’s parent');
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
    final s = ref.watch(studentProvider(widget.studentId)).value;
    if (s == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Note for parents'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final skills = s.skills
        .where((k) => k.status != SkillStatus.gotIt)
        .take(3)
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'Note for parents'),
      bottom: [
        KitButton(
          label: 'Send to ${s.firstName}’s parent',
          loading: _busy,
          onPressed: () => _send(s),
        ),
      ],
      children: [
        Row(
          children: [
            SolidAvatar.forId(
              s.id,
              initials: s.initials,
              size: 48,
              fontSize: 16,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(s.name, style: OgText.heading(20))),
          ],
        ),
        Text('Today’s skills', style: OgText.heading(20)),
        for (final k in skills)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(k.name, style: OgText.body(15, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              KitSegments(
                labels: [
                  for (final st in SkillStatus.values.reversed) st.label,
                ],
                selected: SkillStatus.values.reversed.toList().indexOf(
                  _marks[k.id] ?? k.status,
                ),
                fontSize: 13,
                onSelect: (i) => setState(
                  () => _marks[k.id] = SkillStatus.values.reversed.toList()[i],
                ),
              ),
            ],
          ),
        Text('Add a line', style: OgText.body(15, weight: FontWeight.w700)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final line in const [
              'Great effort',
              'Practise at home',
              'Bring a water bottle',
              'Ready for the next level',
            ])
              KitChip(
                label: line,
                onTap: () => setState(
                  () => _note.text = _note.text.trim().isEmpty
                      ? '$line.'
                      : '${_note.text.trim()} $line.',
                ),
              ),
          ],
        ),
        KitTextArea(
          label: 'Your note',
          controller: _note,
          hint: '${s.firstName} moved to the net much faster today.',
        ),
        Text(
          '${s.firstName}’s parent sees this in the app right after you send it. Other parents do not.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// A parent's filming consent: two separate choices.
class FilmingConsentScreen extends ConsumerStatefulWidget {
  const FilmingConsentScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<FilmingConsentScreen> createState() =>
      _FilmingConsentScreenState();
}

class _FilmingConsentScreenState extends ConsumerState<FilmingConsentScreen> {
  bool? _own;
  bool _train = false;
  bool _busy = false;
  DateTime? _signed;

  Future<void> _save(Student s) async {
    final own = _own ?? s.filmingConsent;
    if (own || _train) {
      final ok =
          !Env.hasSupabase ||
          await ref
              .read(biometricVaultProvider)
              .authenticate('Sign filming consent');
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(academyRepositoryProvider)
          .setFilmingConsent(s.id, own: own, train: _train);
      HapticFeedback.mediumImpact();
      ref.invalidate(studentProvider(s.id));
      if (mounted) setState(() => _signed = DateTime.now());
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
    final s = ref.watch(studentProvider(widget.studentId)).value;
    if (s == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Filming consent'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final own = _own ?? s.filmingConsent;
    final name = s.firstName;
    final facts = [
      (
        'What is recorded',
        'Video of the court during $name’s class only. No audio. Never changing rooms or waiting areas.',
      ),
      (
        'What it is used for',
        'Counting rallies and showing $name’s movement so the coach can explain what to work on.',
      ),
      (
        'Who can see it',
        'You, $name’s coaches and the head coach. Other parents and students cannot.',
      ),
      (
        'How long it is kept',
        'Clips are deleted after 90 days. The numbers in the progress report stay.',
      ),
    ];
    final outcome = own
        ? '$name’s classes will be filmed for the progress report${_train ? ', and blurred clips may help improve the camera system.' : '. Clips will not be used for model training.'}'
        : '$name still joins every class. Clips are not analysed or kept, and progress is tracked by the coach only.';
    return KitScaffold(
      header: const KitHeader(title: 'Filming consent'),
      bottom: [
        KitButton(
          label: _signed != null
              ? 'Saved'
              : (own || _train
                    ? 'Confirm with Face ID'
                    : 'Save without filming'),
          loading: _busy,
          onPressed: _signed != null ? () => context.pop() : () => _save(s),
        ),
      ],
      children: [
        Row(
          children: [
            SolidAvatar.forId(
              s.id,
              initials: s.initials,
              size: 48,
              fontSize: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${s.name}${s.age == null ? '' : ', age ${s.age}'}',
                style: OgText.heading(20),
              ),
            ),
            KitTag('Phase 2', background: t.tag, foreground: t.onTag),
          ],
        ),
        const KitNote(
          'Camera filming starts with Phase 2. Your choice is saved now and applies when filming begins.',
          tone: KitTone.info,
        ),
        Text('What you are agreeing to', style: OgText.heading(20)),
        for (final (i, (title, text)) in facts.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${i + 1}',
                  style: OgText.body(
                    12,
                    weight: FontWeight.w800,
                    color: c.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: OgText.body(15, weight: FontWeight.w700),
                    ),
                    Text(
                      text,
                      style: OgText.body(13, height: 1.4, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        Text('Your choices', style: OgText.heading(20)),
        Text(
          'Two separate choices. You can say yes to one and no to the other.',
          style: OgText.body(13, color: c.textMuted),
        ),
        SwitchRow(
          compact: true,
          title: 'Film $name for their own progress',
          subtitle: 'Needed for camera stats in the progress report. Personal analytics.',
          value: own,
          onChanged: (v) => setState(() {
            _own = v;
            _signed = null;
          }),
        ),
        SwitchRow(
          compact: true,
          title: 'Use $name’s clips to improve the camera system',
          subtitle: 'Faces are blurred first. Saying no changes nothing about classes or reports. Optional.',
          value: _train,
          onChanged: (v) => setState(() {
            _train = v;
            _signed = null;
          }),
        ),
        KitNote(outcome, tone: own ? KitTone.info : KitTone.soft),
        Text(
          'Change or withdraw any time in Settings > Privacy. Withdrawing deletes stored clips within 7 days.',
          style: OgText.body(13, height: 1.4, color: c.textMuted),
        ),
        if (_signed != null)
          Text(
            'Signed by you, parent · ${Fmt.dayTimeComma(_signed!)}',
            style: OgText.body(
              13,
              weight: FontWeight.w700,
              color: t.successInk,
            ),
          ),
      ],
    );
  }
}
