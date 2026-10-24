import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/breadcrumbs.dart';
import '../../../core/format.dart';
import '../../../core/share.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pay_sheet.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../play/domain/activity.dart' show money;
import '../application/academy_providers.dart';
import '../data/academy_repository.dart';
import '../domain/academy_models.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Sat", "Tue and Thu".
String classDays(AcademyClass c) =>
    c.weekdays.map((d) => _days[d - 1]).join(' and ');

/// "Sat 9:00 – 10:30 AM".
String classWhen(AcademyClass c) {
  final start = DateTime(2000, 1, 1, c.hour, c.minute);
  return '${classDays(c)} ${Fmt.timeRange(start, c.endOf(start))}';
}

/// "S$180 / month".
String classFee(Academy a, AcademyClass c) =>
    'S\$${money(c.feeCents, decimals: c.feeCents % 100 != 0)} / ${a.billing.unit}';

/// Rounded square logo with the academy's initials.
class AcademyMark extends StatelessWidget {
  const AcademyMark({super.key, required this.academy, this.size = 56});

  final Academy academy;
  final double size;

  @override
  Widget build(BuildContext context) => ClubLogo(
    initials: academy.initials,
    color: Color(academy.color),
    ink: Color(academy.ink),
    size: size,
    radius: size * 0.3,
  );
}

// ─── Category ──────────────────────────────────────────────────────────────

class AcademiesScreen extends ConsumerStatefulWidget {
  const AcademiesScreen({super.key});

  @override
  ConsumerState<AcademiesScreen> createState() => _AcademiesScreenState();
}

class _AcademiesScreenState extends ConsumerState<AcademiesScreen> {
  String _q = '';
  String _who = 'Anyone';

  bool _fits(Academy a) {
    final q = _q.trim().toLowerCase();
    if (q.isNotEmpty &&
        !'${a.name} ${a.area} ${a.sport.label}'.toLowerCase().contains(q)) {
      return false;
    }
    return switch (_who) {
      'Kids' => a.audience.contains('ages'),
      'Adults' =>
        a.audience.contains('adult') ||
            a.classes.any((c) => c.ages == 'adults'),
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    Crumbs.name(context, 'Academy');
    final top = MediaQuery.of(context).padding.top;
    final list = ref.watch(academyListProvider);
    final kids = ref.watch(myStudentsProvider).value ?? const [];
    final coaching = (list.value ?? const <Academy>[])
        .where((a) => a.isCoach)
        .toList();
    final shown = (list.value ?? const <Academy>[]).where(_fits).toList();
    return Scaffold(
      backgroundColor: c.bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  CourtHero(
                    color: const Color(0xFF2F3A5F),
                    height: 150 + top,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 12,
                          top: top + 14,
                          child: const KitBackPill(
                            background: Color(0x24FFFFFF),
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          left: 20,
                          bottom: 38,
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Academy',
                              style: OgText.heading(44, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -26),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2417171A),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: KitSearchField(
                        hint: 'Search academies and areas',
                        onChanged: (v) => setState(() => _q = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              sliver: SliverList.list(
                children: kitSpaced([
                  for (final s in kids)
                    KitNavTile(
                      icon: OgIcons.mortarboard,
                      title: s.name,
                      subtitle: 'Your child · open classes, fees and progress',
                      tile: t.successFill,
                      ink: t.onSuccessFill,
                      padding: EdgeInsets.zero,
                      onTap: () => context.push(Routes.studentHome(s.id)),
                    ),
                  for (final a in coaching)
                    KitNavTile(
                      icon: OgIcons.clipboardList,
                      title: 'You coach at ${a.name}',
                      subtitle: 'Open the coach home',
                      tile: OgColors.ink,
                      ink: OgColors.lime,
                      padding: EdgeInsets.zero,
                      onTap: () => context.push(Routes.academyToday(a.id)),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: t.soft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Run an academy?',
                                style: OgText.body(16, weight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Business licence, NROC coaches',
                                style: OgText.body(13, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        KitButton(
                          label: 'Create',
                          expand: false,
                          height: 44,
                          fontSize: 15,
                          style: KitButtonStyle.dark,
                          onPressed: () {
                            ref
                                .read(academyDraftControllerProvider.notifier)
                                .reset();
                            context.push(Routes.newAcademy);
                          },
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Academies near you',
                          style: OgText.heading(22),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final w in const ['Anyone', 'Kids', 'Adults'])
                        KitChip(
                          label: w,
                          selected: _who == w,
                          onTap: () => setState(() => _who = w),
                        ),
                    ],
                  ),
                  ...switch (list) {
                    AsyncError() => [
                      const KitNote("Academies aren't loading. Try again."),
                    ],
                    AsyncData() when shown.isEmpty => [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Column(
                          children: [
                            Text(
                              'No academy matches',
                              style: OgText.heading(24),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Check the spelling or try an area name.',
                              style: OgText.body(14, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                    AsyncData() => [for (final a in shown) _AcademyRow(a)],
                    _ => [const CupertinoActivityIndicator()],
                  },
                ], 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcademyRow extends StatelessWidget {
  const _AcademyRow(this.academy);

  final Academy academy;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final a = academy;
    final from = a.fromCents;
    final sub = [
      if (a.rating != null)
        '${a.rating!.toStringAsFixed(1)} (${a.ratingCount})',
      '${a.coaches.length} NROC coaches',
      a.audience,
    ].join(', ');
    return Pressable(
      semanticLabel: '${a.name}. $sub',
      onPressed: () => context.push(Routes.academy(a.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            AcademyMark(academy: a),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.name,
                          style: OgText.body(17, weight: FontWeight.w700),
                        ),
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
                  const SizedBox(height: 2),
                  Text(sub, style: OgText.body(13, color: c.textMuted)),
                  if (from != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'From S\$${money(from, decimals: false)} a ${a.billing.unit}',
                      style: OgText.body(
                        13,
                        weight: FontWeight.w700,
                        color: c.link,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            OgIcon(OgIcons.chevronRight, size: 20, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── Public page ───────────────────────────────────────────────────────────

class AcademyPageScreen extends ConsumerWidget {
  const AcademyPageScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final a = ref.watch(academyProvider(id)).value;
    if (a == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Academy'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final students = a.classes.fold(0, (n, x) => n + x.enrolled);
    final kids = (ref.watch(myStudentsProvider).value ?? const [])
        .where((k) => k.academyId == a.id)
        .toList();
    final top = MediaQuery.of(context).padding.top;
    Crumbs.name(context, a.name);
    Widget whiteButton(String icon, String label, VoidCallback onTap) =>
        KitIconButton(
          icon: icon,
          label: label,
          background: Colors.white,
          color: OgColors.ink,
          size: 20,
          strokeWidth: 1.9,
          onPressed: onTap,
        );
    Widget link(String icon, String label, String sub, VoidCallback? onTap) =>
        Pressable(
          semanticLabel: '$label. $sub',
          onPressed: onTap,
          dimWhenDisabled: false,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                OgIcon(icon, size: 22, strokeWidth: 1.8, color: c.text),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: OgText.body(15, weight: FontWeight.w600),
                      ),
                      Text(sub, style: OgText.body(13, color: c.textMuted)),
                    ],
                  ),
                ),
                if (onTap != null)
                  OgIcon(OgIcons.chevronRight, size: 20, color: c.textMuted),
              ],
            ),
          ),
        );
    // Same banner, identity card and back pill as the club page.
    final identity = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F17171A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                AcademyMark(academy: a, size: 76),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(a.name, style: OgText.heading(28)),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [a.sport.label, a.area].join(', '),
                        style: OgText.body(13, color: c.textMuted),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (a.rating != null) ...[
                            Text(
                              '${a.rating!.toStringAsFixed(1)} (${a.ratingCount})',
                              style: OgText.body(13, weight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (a.verified)
                            KitTag(
                              'Verified',
                              height: 22,
                              fontSize: 11,
                              background: t.successFill,
                              foreground: t.onSuccessFill,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          link(
            OgIcons.group,
            '${a.students > 0 ? a.students : students} students',
            '${a.classes.length} classes · ${a.coaches.length} NROC coaches',
            null,
          ),
          for (final k in kids)
            link(
              OgIcons.mortarboard,
              k.name,
              'Your child · classes, fees and progress',
              () => context.push(Routes.studentHome(k.id)),
            ),
          if (a.isCoach)
            link(
              OgIcons.clipboardList,
              'You coach here',
              'Open the coach home',
              () => context.push(Routes.academyToday(a.id)),
            ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: c.bg,
      bottomNavigationBar: KitBottomBar(
        children: [
          KitButton(
            label: 'Ask to enrol',
            onPressed: () => context.push(Routes.academyEnrol(a.id)),
          ),
          KitButton.outline(
            label: 'Book a trial class',
            onPressed: () => context.push(Routes.academyTrial(a.id)),
          ),
        ],
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // The card overlaps the banner by 64. It sits in the same Stack,
            // so its real height sizes the box and nothing paints over it.
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  CourtHero(color: Color(a.coverColor), height: 200 + top),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 200 + top - 64, 20, 20),
                    child: identity,
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: top + 12,
                    child: Row(
                      children: [
                        const KitBackPill(),
                        const Spacer(),
                        Builder(
                          builder: (context) => whiteButton(
                            OgIcons.shareTray,
                            'Share',
                            () =>
                                shareLink(context, a.name, Links.academy(a.id)),
                          ),
                        ),
                        if (a.isCoach) ...[
                          const SizedBox(width: 8),
                          whiteButton(
                            OgIcons.cog,
                            'Academy settings',
                            () => context.push(Routes.academySettings(a.id)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.list(
                children: kitSpaced([
                  if (a.blurb.isNotEmpty)
                    Text(a.blurb, style: OgText.body(15, height: 1.5)),
                  if (a.classes.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Classes', style: OgText.heading(22)),
                        const SizedBox(height: 8),
                        for (final x in a.classes)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: c.border)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              x.name,
                                              style: OgText.body(
                                                15,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          KitTag(
                                            'Level ${x.level}',
                                            height: 20,
                                            fontSize: 11,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          classWhen(x),
                                          if (x.ages.isNotEmpty) x.ages,
                                        ].join(' · '),
                                        style: OgText.body(
                                          13,
                                          color: c.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      classFee(a, x),
                                      style: OgText.body(
                                        14,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      x.full
                                          ? 'Full, join the waitlist'
                                          : '${x.spotsLeft} ${x.spotsLeft == 1 ? 'spot' : 'spots'} left',
                                      style: OgText.body(
                                        12,
                                        weight: FontWeight.w600,
                                        color: x.full ? t.dangerText : c.link,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Coaches', style: OgText.heading(22)),
                      const SizedBox(height: 8),
                      for (final co in a.coaches)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SolidAvatar.forId(
                                co.name,
                                initials: co.initials,
                                size: 44,
                                fontSize: 14,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      co.name,
                                      style: OgText.body(
                                        15,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${co.role}${co.nroc ? ' · NROC licensed' : ''}',
                                      style: OgText.body(
                                        13,
                                        color: c.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (co.nroc)
                                KitTag(
                                  'NROC',
                                  height: 22,
                                  fontSize: 11,
                                  background: OgColors.ink,
                                  foreground: OgColors.lime,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  KitCheckList([
                    if (a.verified) 'Business licence checked by Olympus',
                    '${a.billing.label} billing, ${a.makeupsPerMonth} make-up classes each month',
                    'Academy levels are separate from your player rating',
                    'Filming needs a parent’s consent for under-18s',
                  ]),
                ], 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ask to enrol ──────────────────────────────────────────────────────────

class AcademyEnrolScreen extends ConsumerStatefulWidget {
  const AcademyEnrolScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AcademyEnrolScreen> createState() => _AcademyEnrolScreenState();
}

class _AcademyEnrolScreenState extends ConsumerState<AcademyEnrolScreen> {
  String? _who;
  String? _classId;
  String _note = '';
  bool _busy = false;
  bool _sent = false;

  Future<void> _send(Academy a) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(academyRepositoryProvider)
          .requestEnrol(
            academyId: a.id,
            classId: _classId!,
            student: _who!,
            note: _note,
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(academyProvider(a.id));
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final a = ref.watch(academyProvider(widget.id)).value;
    final kids = ref.watch(myStudentsProvider).value ?? const [];
    if (a == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Ask to enrol'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final cls = a.classes.where((x) => x.id == _classId).firstOrNull;
    if (_sent) {
      return KitScaffold(
        header: const KitHeader(title: 'Ask to enrol'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Back to the academy',
            onPressed: () => kitPop(context),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Request sent'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'For $_who, ${cls!.name}. ${a.name} answers within 2 working '
              'days. You pay the first ${a.billing.unit} only after they accept.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    final names = <String>{for (final k in kids) k.name, 'Myself'};
    return KitScaffold(
      header: const KitHeader(title: 'Ask to enrol'),
      bottom: [
        KitButton(
          label: 'Send request',
          loading: _busy,
          onPressed: _who == null || _classId == null ? null : () => _send(a),
        ),
        KitButton.outline(label: 'Cancel', onPressed: () => kitPop(context)),
      ],
      children: [
        KitTitle(
          'Who is joining?',
          size: 28,
          lead:
              '${a.name} replies within 2 working days. You pay only after '
              'they accept.',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Student', style: OgText.body(15, weight: FontWeight.w700)),
            for (final n in names)
              KitChoiceRow(
                title: n,
                subtitle: n == 'Myself'
                    ? 'Adult'
                    : 'Your child${kids.firstWhere((k) => k.name == n).age == null ? '' : ' · age ${kids.firstWhere((k) => k.name == n).age}'}',
                selected: _who == n,
                onTap: () => setState(() => _who = n),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Class', style: OgText.body(15, weight: FontWeight.w700)),
            for (final x in a.classes)
              KitChoiceRow(
                title: x.name,
                subtitle: '${classWhen(x)} · ${classFee(a, x)}',
                tag: x.full ? 'Waitlist' : '${x.spotsLeft} left',
                selected: _classId == x.id,
                onTap: () => setState(() => _classId = x.id),
              ),
          ],
        ),
        KitTextArea(
          label: 'Anything the coach should know?',
          optional: true,
          hint: 'Experience, health notes, days that don’t work',
          onChanged: (v) => _note = v,
        ),
      ],
    );
  }
}

// ─── Trial class ───────────────────────────────────────────────────────────

class TrialClassScreen extends ConsumerStatefulWidget {
  const TrialClassScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TrialClassScreen> createState() => _TrialClassScreenState();
}

class _TrialClassScreenState extends ConsumerState<TrialClassScreen> {
  String? _who;
  MakeupSlot? _slot;
  bool _busy = false;
  bool _done = false;

  Future<void> _pay(Academy a) async {
    final s = _slot!;
    final fee = academyFee(trialCents);
    final method = await showPaySheet(
      context,
      kicker: 'Trial class',
      title: s.className,
      subtitle: '${Fmt.dayTimeComma(s.at)} · ${s.coach} · for $_who',
      lines: [
        ('Trial class', 'S\$${money(trialCents)}'),
        ('Platform fee', 'S\$${money(fee)}'),
      ],
      totalCents: trialCents + fee,
      payee: a.name,
      notes: [
        'Full refund if you cancel 24 hours before the class.',
        'The S\$${money(trialCents)} comes off the first ${a.billing.unit} if you enrol within 7 days.',
      ],
    );
    if (method == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(academyRepositoryProvider).bookTrial(a.id, s, _who!);
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _done = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final a = ref.watch(academyProvider(widget.id)).value;
    final kids = ref.watch(myStudentsProvider).value ?? const [];
    final slots = ref.watch(trialSlotsProvider(widget.id)).value;
    if (a == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Trial class'),
        children: [CupertinoActivityIndicator()],
      );
    }
    if (_done) {
      final s = _slot!;
      return KitScaffold(
        header: const KitHeader(title: 'Trial class'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Back to the academy',
            onPressed: () => kitPop(context),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Trial booked'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.className}, ${Fmt.dayTimeComma(s.at)}',
                  style: OgText.heading(24),
                ),
                const SizedBox(height: 4),
                Text(
                  '${s.coach} is expecting $_who.',
                  style: OgText.body(15, height: 1.45, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final who = [for (final k in kids) k.name, 'Myself'];
    return KitScaffold(
      header: const KitHeader(title: 'Trial class'),
      bottom: [
        KitButton(
          label: _slot == null ? 'Pick a class' : 'Continue to pay',
          loading: _busy,
          onPressed: _slot == null || _who == null ? null : () => _pay(a),
        ),
      ],
      children: [
        KitTitle(
          'Try one class first',
          size: 28,
          lead:
              'One paid trial per child. If you enrol within 7 days, the trial '
              'fee comes off the first ${a.billing.unit}.',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Who is it for?',
              style: OgText.body(15, weight: FontWeight.w700),
            ),
            for (final n in who)
              KitChoiceRow(
                title: n,
                selected: _who == n,
                onTap: () => setState(() => _who = n),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pick a class',
              style: OgText.body(15, weight: FontWeight.w700),
            ),
            if (slots == null)
              const CupertinoActivityIndicator()
            else if (slots.isEmpty)
              Text(
                'No class has space in the next two weeks.',
                style: OgText.body(14, color: c.textMuted),
              ),
            for (final s in slots ?? const <MakeupSlot>[])
              KitChoiceRow(
                title: '${s.className}, ${Fmt.day(s.at)}',
                subtitle:
                    '${Fmt.time(s.at)} · ${s.coach} · ${s.spots} ${s.spots == 1 ? 'spot' : 'spots'}',
                tag: 'S\$${money(trialCents, decimals: false)}',
                selected: _slot == s,
                onTap: () => setState(() => _slot = s),
              ),
          ],
        ),
        const KitNote(
          'Bring court shoes and water. Rackets are lent free for the trial.',
        ),
      ],
    );
  }
}
