import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/format.dart';
import '../../../core/providers.dart';
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
import '../domain/academy_models.dart';
import 'academy_screens.dart' show classWhen;

/// Loads a student and their academy, then builds [child].
class _WithStudent extends ConsumerWidget {
  const _WithStudent({
    required this.id,
    required this.title,
    required this.builder,
  });

  final String id;
  final String title;
  final Widget Function(Student s, Academy a, AcademyClass c) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(studentProvider(id));
    final a = s.value == null
        ? null
        : ref.watch(academyProvider(s.value!.academyId)).value;
    if (s.hasError) {
      return KitScaffold(
        header: KitHeader(title: title),
        children: const [KitNote("This isn't loading. Try again.")],
      );
    }
    if (a == null) {
      return KitScaffold(
        header: KitHeader(title: title),
        children: const [CupertinoActivityIndicator()],
      );
    }
    final c = a.classes.firstWhere((x) => x.id == s.value!.classId);
    return builder(s.value!, a, c);
  }
}

String _dow(DateTime d) =>
    const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d.weekday - 1];

// ─── Parent home ───────────────────────────────────────────────────────────

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _WithStudent(
      id: id,
      title: 'Parent home',
      builder: (s, a, cls) => _StudentHome(student: s, academy: a, cls: cls),
    );
  }
}

class _StudentHome extends ConsumerWidget {
  const _StudentHome({
    required this.student,
    required this.academy,
    required this.cls,
  });

  final Student student;
  final Academy academy;
  final AcademyClass cls;

  Future<void> _answer(BuildContext context, WidgetRef ref, bool coming) async {
    HapticFeedback.selectionClick();
    await ref
        .read(academyRepositoryProvider)
        .answerNotice(student.id, coming: coming);
    ref.invalidate(studentProvider(student.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final s = student;
    final first = ref.watch(sessionProfileProvider).value?.firstName ?? '';
    final next = cls.nextAt();
    final invoices = ref.watch(studentInvoicesProvider(s.id)).value ?? const [];
    final due = invoices.where((i) => i.paidOn == null).firstOrNull;
    final note = s.notes.firstOrNull;
    final daysAway = DateTime(next.year, next.month, next.day)
        .difference(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        )
        .inDays;

    Widget card({required Widget child, Color? color, Color? border}) =>
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? c.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border ?? c.border),
          ),
          child: child,
        );

    return KitScaffold(
      header: KitHeader(
        title: 'Hi $first',
        subtitle: '${academy.name} · Parent',
        crumb: s.firstName,
      ),
      gap: 14,
      children: [
        Row(
          children: [
            SolidAvatar.forId(
              s.id,
              initials: s.initials,
              size: 44,
              fontSize: 15,
            ),
            const SizedBox(width: 10),
            Text(s.name, style: OgText.body(17, weight: FontWeight.w700)),
          ],
        ),
        if (s.notice != null)
          card(
            color: t.warnFill,
            border: t.warnFill,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CLASS MOVED · SENT BY ${cls.coach.toUpperCase()}',
                  style: OgText.body(
                    11,
                    weight: FontWeight.w800,
                    color: t.onWarnFill,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.notice!,
                  style: OgText.body(
                    15,
                    weight: FontWeight.w700,
                    color: t.onWarnFill,
                  ),
                ),
                const SizedBox(height: 10),
                if (s.noticeComing == null) ...[
                  Text(
                    'Can ${s.firstName} make it?',
                    style: OgText.body(14, color: t.onWarnFill),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: KitButton(
                          label: "Yes, coming",
                          height: 44,
                          fontSize: 14,
                          style: KitButtonStyle.dark,
                          onPressed: () => _answer(context, ref, true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: KitButton.outline(
                          label: "Can't make it",
                          height: 44,
                          fontSize: 14,
                          onPressed: () => _answer(context, ref, false),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    s.noticeComing!
                        ? 'Got it. ${cls.coach} knows ${s.firstName} is coming.'
                        : 'Got it. ${s.firstName} has a new make-up credit for this class. ${cls.coach} has been told.',
                    style: OgText.body(14, height: 1.4, color: t.onWarnFill),
                  ),
              ],
            ),
          ),
        Pressable(
          semanticLabel: 'Next class, ${Fmt.dayTimeComma(next)}',
          onPressed: () => context.push(Routes.studentClass(s.id)),
          child: card(
            color: OgColors.ink,
            border: OgColors.ink,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Next class',
                      style: OgText.body(
                        13,
                        weight: FontWeight.w600,
                        color: const Color(0xFFC9C9CF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    KitTag(
                      daysAway == 0
                          ? 'Today'
                          : daysAway == 1
                          ? 'Tomorrow'
                          : 'In $daysAway days',
                      height: 20,
                      fontSize: 11,
                      background: OgColors.lime,
                      foreground: OgColors.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${Fmt.day(next)}, ${Fmt.timeRange(next, cls.endOf(next))}',
                  style: OgText.heading(22, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    cls.name,
                    cls.coach,
                    if (cls.court.isNotEmpty) cls.court,
                  ].join(' · '),
                  style: OgText.body(13, color: const Color(0xFFC9C9CF)),
                ),
                const SizedBox(height: 12),
                Text(
                  'WEEK ${cls.week}',
                  style: OgText.body(
                    11,
                    weight: FontWeight.w800,
                    color: t.gold,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '${cls.lesson}. Bring a water bottle and court shoes.',
                  style: OgText.body(14, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        if (s.makeupCredits > 0)
          card(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.makeupCredits} make-up ${s.makeupCredits == 1 ? 'credit' : 'credits'}',
                        style: OgText.body(16, weight: FontWeight.w700),
                      ),
                      if (s.creditUseBy != null)
                        Text(
                          'Use by ${Fmt.day(s.creditUseBy!)} · book any Level ${cls.level} class',
                          style: OgText.body(13, color: c.textMuted),
                        ),
                    ],
                  ),
                ),
                KitButton(
                  label: 'Book',
                  expand: false,
                  height: 44,
                  fontSize: 15,
                  onPressed: () => context.push(Routes.studentMakeup(s.id)),
                ),
              ],
            ),
          ),
        if (note != null)
          card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SolidAvatar.forId(
                      note.coach,
                      initials: note.coach
                          .split(' ')
                          .last
                          .substring(0, 2)
                          .toUpperCase(),
                      size: 36,
                      fontSize: 12,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From ${note.coach}',
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          Text(
                            'After ${Fmt.day(note.at)} · ${note.lesson}',
                            style: OgText.body(12, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    KitTag(
                      note.present ? 'Present' : 'Absent',
                      height: 22,
                      fontSize: 11,
                    ),
                    if (note.got != null)
                      KitTag(
                        'Got it: ${note.got}',
                        height: 22,
                        fontSize: 11,
                        background: t.successFill,
                        foreground: t.onSuccessFill,
                      ),
                    if (note.practising != null)
                      KitTag(
                        'Practising: ${note.practising}',
                        height: 22,
                        fontSize: 11,
                        background: t.warnFill,
                        foreground: t.onWarnFill,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(note.text, style: OgText.body(14, height: 1.45)),
              ],
            ),
          ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.trophyCup,
              title: 'Progress',
              subtitle:
                  'Level ${cls.level}${cls.levelName.isEmpty ? '' : ' · ${cls.levelName}'} · ${s.skillsGot} of ${s.skills.length} skills · attendance ${s.attendancePct}%',
              onTap: () => context.push(Routes.studentProgress(s.id)),
            ),
            KitNavTile(
              icon: OgIcons.clipboardList,
              title: 'Attendance',
              subtitle:
                  '${s.attended} of ${s.held} classes · ${s.makeupCredits} make-up ${s.makeupCredits == 1 ? 'credit' : 'credits'}',
              onTap: () => context.push(Routes.studentAttendance(s.id)),
            ),
            KitNavTile(
              icon: OgIcons.calendarBox,
              title: 'Class details',
              subtitle:
                  'Week ${cls.week} of ${cls.termWeeks} · ${academy.billing.label.toLowerCase()} billing',
              onTap: () => context.push(Routes.studentClass(s.id)),
            ),
            KitNavTile(
              icon: OgIcons.walletCard,
              title: 'Fees and invoices',
              subtitle: due == null
                  ? 'All paid'
                  : '${due.title} S\$${money(due.totalCents)}, due ${Fmt.day(due.due)}',
              onTap: () => context.push(Routes.studentFees(s.id)),
            ),
            KitNavTile(
              icon: OgIcons.shieldTick,
              title: 'Filming consent',
              subtitle: s.filmingConsent
                  ? 'Given'
                  : 'Not given yet · needed before any class is filmed',
              onTap: () => context.push(Routes.filmingConsent(s.id)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Class details ─────────────────────────────────────────────────────────

class StudentClassScreen extends ConsumerWidget {
  const StudentClassScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _WithStudent(
      id: id,
      title: 'Class details',
      builder: (s, a, cls) {
        final c = context.og;
        final t = context.tones;
        final weeks = ref.watch(studentLessonsProvider(s.id)).value ?? const [];
        Widget stat(String big, String small) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(big, style: OgText.heading(24)),
                Text(
                  small,
                  textAlign: TextAlign.center,
                  style: OgText.body(12, color: c.textMuted),
                ),
              ],
            ),
          ),
        );
        return KitScaffold(
          header: const KitHeader(title: 'Class details'),
          bottom: [
            KitButton(
              label: 'Book a make-up class',
              onPressed: s.makeupCredits > 0
                  ? () => context.push(Routes.studentMakeup(s.id))
                  : null,
            ),
          ],
          children: [
            KitTitle(
              '${cls.name}${cls.levelName.isEmpty ? '' : ', ${cls.levelName}'}',
              size: 26,
              lead: [
                classWhen(cls),
                [
                  if (cls.court.isNotEmpty) cls.court,
                  'with ${cls.coach}',
                ].join(' '),
              ].join('\n'),
            ),
            Row(
              children: [
                stat('${cls.week - 1} of ${cls.week - 1}', 'Classes attended'),
                const SizedBox(width: 8),
                stat('${cls.termWeeks - cls.week + 1}', 'Classes left'),
                const SizedBox(width: 8),
                stat('${s.makeupCredits}', 'Make-ups left'),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('This term', style: OgText.heading(22)),
                const SizedBox(height: 8),
                for (final w in weeks)
                  Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${w.week}',
                            style: OgText.body(
                              14,
                              weight: FontWeight.w700,
                              color: c.textMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            w.title,
                            style: OgText.body(
                              15,
                              weight: w.week == cls.week
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (w.attended)
                          KitTag(
                            'Attended',
                            height: 22,
                            fontSize: 11,
                            background: t.successFill,
                            foreground: t.onSuccessFill,
                          )
                        else if (w.week == cls.week)
                          KitTag(
                            'Next class',
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
            KitCheckList(const [
              'Racket, or borrow one from the academy',
              'Non-marking court shoes',
              'Water bottle and a small towel',
            ]),
          ],
        );
      },
    );
  }
}

// ─── Fees ──────────────────────────────────────────────────────────────────

class StudentFeesScreen extends ConsumerStatefulWidget {
  const StudentFeesScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends ConsumerState<StudentFeesScreen> {
  bool _auto = true;
  bool _busy = false;

  Future<void> _pay(Student s, Academy a, AcademyClass cls, Invoice inv) async {
    final method = await showPaySheet(
      context,
      kicker: 'Academy fee',
      title: '${inv.title} for ${s.firstName}',
      subtitle: '${cls.name} · due ${Fmt.day(inv.due)}',
      lines: [
        (
          '${cls.name}, ${a.billing.label.toLowerCase()}',
          'S\$${money(inv.feeCents)}',
        ),
        ('Platform fee, 10%', 'S\$${money(inv.platformCents)}'),
      ],
      totalCents: inv.totalCents,
      payee: a.name,
      notes: const ['A receipt is sent to your email.'],
    );
    if (method == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(academyRepositoryProvider).payInvoice(inv.id, method.id);
      HapticFeedback.mediumImpact();
      ref.invalidate(studentInvoicesProvider(s.id));
      if (mounted) showOgToast(context, 'Paid S\$${money(inv.totalCents)}');
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _WithStudent(
      id: widget.id,
      title: 'Fees',
      builder: (s, a, cls) {
        final c = context.og;
        final invoices =
            ref.watch(studentInvoicesProvider(s.id)).value ?? const [];
        final due = invoices.where((i) => i.paidOn == null).firstOrNull;
        final past = invoices.where((i) => i.paidOn != null).toList();
        return KitScaffold(
          header: const KitHeader(title: 'Fees'),
          bottom: [
            if (due != null)
              KitButton(
                label: 'Pay ${due.title.toLowerCase()}',
                loading: _busy,
                onPressed: () => _pay(s, a, cls, due),
              )
            else
              KitButton.outline(
                label: 'Back to ${s.firstName}’s classes',
                onPressed: () => kitPop(context),
              ),
          ],
          children: [
            if (due != null) ...[
              Text(
                '${due.title} for ${s.firstName}, due ${Fmt.day(due.due)}',
                style: OgText.body(14, color: c.textMuted),
              ),
              Text('S\$${money(due.totalCents)}', style: OgText.heading(44)),
              Column(
                children: [
                  KitKeyValue(
                    '${cls.name}, ${a.billing.label.toLowerCase()}',
                    'S\$${money(due.feeCents)}',
                  ),
                  KitKeyValue(
                    'Platform fee, 10%',
                    'S\$${money(due.platformCents)}',
                  ),
                ],
              ),
              KitChoiceRow(
                title: 'Pay automatically each month',
                subtitle:
                    'Charged on the 1st. You get a reminder 3 days before.',
                multi: true,
                selected: _auto,
                onTap: () => setState(() => _auto = !_auto),
              ),
            ] else if (Env.hasSupabase)
              KitNote(
                'Pay ${a.name} directly for now: S\$${money(cls.feeCents)} '
                '${a.billing == Billing.perClass ? 'a class' : 'a ${a.billing.unit}'}. '
                'Paying in the app is coming.',
                tone: KitTone.info,
              )
            else
              const KitNote('Nothing to pay right now.', tone: KitTone.success),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Past invoices', style: OgText.heading(22)),
                const SizedBox(height: 8),
                if (past.isEmpty)
                  Text('None yet.', style: OgText.body(14, color: c.textMuted)),
                for (final i in past)
                  KitKeyValue(
                    i.title,
                    'S\$${money(i.totalCents)}, paid ${Fmt.day(i.paidOn!)}',
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─── Make-up ───────────────────────────────────────────────────────────────

class BookMakeupScreen extends ConsumerStatefulWidget {
  const BookMakeupScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<BookMakeupScreen> createState() => _BookMakeupScreenState();
}

class _BookMakeupScreenState extends ConsumerState<BookMakeupScreen> {
  MakeupSlot? _slot;
  bool _busy = false;
  bool _done = false;

  Future<void> _book(Student s) async {
    setState(() => _busy = true);
    try {
      await ref.read(academyRepositoryProvider).bookMakeup(s.id, _slot!);
      HapticFeedback.mediumImpact();
      ref.invalidate(studentProvider(s.id));
      if (mounted) setState(() => _done = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _WithStudent(
      id: widget.id,
      title: 'Book a make-up',
      builder: (s, a, cls) {
        final c = context.og;
        final t = context.tones;
        final slots = ref.watch(makeupSlotsProvider(s.id)).value;
        if (_done) {
          final sl = _slot!;
          return KitScaffold(
            header: const KitHeader(title: 'Book a make-up'),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
            bottom: [
              KitButton(label: 'Done', onPressed: () => kitPop(context)),
            ],
            children: [
              const KitDoneBanner(title: 'Make-up booked'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${s.firstName} joins ${sl.className} on ${Fmt.dayTimeComma(sl.at)} '
                  'with ${sl.coach}. ${sl.coach} has been told.',
                  style: OgText.body(15, height: 1.45, color: c.textMuted),
                ),
              ),
            ],
          );
        }
        return KitScaffold(
          header: const KitHeader(title: 'Book a make-up'),
          bottom: [
            KitButton(
              label: _slot == null ? 'Pick a class' : 'Book this class',
              loading: _busy,
              onPressed: _slot == null || s.makeupCredits < 1
                  ? null
                  : () => _book(s),
            ),
          ],
          children: [
            Text(
              [
                s.firstName,
                '${s.makeupCredits} ${s.makeupCredits == 1 ? 'credit' : 'credits'}',
                if (s.creditUseBy != null) 'use by ${Fmt.day(s.creditUseBy!)}',
              ].join(' · '),
              style: OgText.body(
                14,
                weight: FontWeight.w600,
                color: c.textMuted,
              ),
            ),
            Text(
              'Level ${cls.level} classes with space',
              style: OgText.heading(22),
            ),
            if (slots == null)
              const CupertinoActivityIndicator()
            else if (slots.isEmpty)
              const KitNote('No class has space in the next two weeks.'),
            for (final sl in slots ?? const <MakeupSlot>[])
              Pressable(
                semanticLabel:
                    '${sl.className}, ${Fmt.dayTimeComma(sl.at)}, ${sl.coach}. ${sl.spots} spots',
                selected: _slot == sl,
                onPressed: () => setState(() => _slot = sl),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _slot == sl ? OgColors.tangerineLine : c.border,
                      width: _slot == sl ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Column(
                          children: [
                            Text(
                              _dow(sl.at),
                              style: OgText.body(
                                11,
                                weight: FontWeight.w700,
                                color: c.link,
                              ),
                            ),
                            Text('${sl.at.day}', style: OgText.heading(26)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${Fmt.time(sl.at)} · ${sl.className}',
                              style: OgText.body(15, weight: FontWeight.w700),
                            ),
                            Text(
                              '${sl.coach} · ${sl.lesson}',
                              style: OgText.body(13, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      KitTag(
                        '${sl.spots} ${sl.spots == 1 ? 'spot' : 'spots'}',
                        height: 22,
                        fontSize: 11,
                        background: t.successFill,
                        foreground: t.onSuccessFill,
                      ),
                    ],
                  ),
                ),
              ),
            const KitNote(
              'Book at least 24 hours before. Cancel up to 24 hours before and '
              'the credit comes back. Credits expire 30 days after the missed '
              'class.',
            ),
          ],
        );
      },
    );
  }
}

// ─── Progress ──────────────────────────────────────────────────────────────

class StudentProgressScreen extends ConsumerWidget {
  const StudentProgressScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _WithStudent(
      id: id,
      title: 'Progress',
      builder: (s, a, cls) {
        final c = context.og;
        final t = context.tones;
        final groups = <String, List<Skill>>{};
        for (final k in s.skills) {
          (groups[k.group] ??= []).add(k);
        }
        final left = s.skills.length - s.skillsGot;
        Widget stat(String label, String big, String small) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: OgText.body(
                    11,
                    weight: FontWeight.w800,
                    color: c.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(big, style: OgText.heading(24)),
                Text(small, style: OgText.body(12, color: c.textMuted)),
              ],
            ),
          ),
        );
        (Color, Color) tone(SkillStatus st) => switch (st) {
          SkillStatus.notYet => (t.tag, t.onTag),
          SkillStatus.practising => (t.warnFill, t.onWarnFill),
          SkillStatus.gotIt => (t.successFill, t.onSuccessFill),
        };
        return KitScaffold(
          header: const KitHeader(title: 'Progress'),
          bottom: a.isCoach
              ? [
                  KitButton(
                    label: 'Note for ${s.firstName}’s parent',
                    onPressed: () => context.push(Routes.parentNote(s.id)),
                  ),
                ]
              : null,
          children: [
            Row(
              children: [
                SolidAvatar.forId(
                  s.id,
                  initials: s.initials,
                  size: 56,
                  fontSize: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: OgText.heading(24)),
                      Text(
                        [
                          if (s.age != null) 'Age ${s.age}',
                          cls.name,
                          cls.coach,
                        ].join(' · '),
                        style: OgText.body(13, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OgColors.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${cls.level}${cls.levelName.isEmpty ? '' : ' · ${cls.levelName}'}',
                    style: OgText.body(13, color: const Color(0xFFC9C9CF)),
                  ),
                  Text(
                    '${s.skillsGot} of ${s.skills.length} skills',
                    style: OgText.heading(30, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: s.skills.isEmpty
                          ? 0
                          : s.skillsGot / s.skills.length,
                      minHeight: 8,
                      color: OgColors.lime,
                      backgroundColor: const Color(0x33FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    left == 0
                        ? 'Ready for Level ${cls.level + 1}'
                        : '$left more skills to be ready for Level ${cls.level + 1}',
                    style: OgText.body(13, color: Colors.white),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                stat(
                  'ATTENDANCE',
                  '${s.attendancePct}%',
                  '${s.attended} of ${s.held}',
                ),
                const SizedBox(width: 8),
                stat(
                  'PRACTISING',
                  '${s.skills.where((k) => k.status == SkillStatus.practising).length}',
                  'skills now',
                ),
              ],
            ),
            for (final g in groups.entries)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(g.key, style: OgText.body(15, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  for (final k in g.value)
                    Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(k.name, style: OgText.body(15)),
                                if (k.week.isNotEmpty)
                                  Text(
                                    k.week,
                                    style: OgText.body(12, color: c.textMuted),
                                  ),
                              ],
                            ),
                          ),
                          KitTag(
                            k.status.label,
                            height: 24,
                            fontSize: 12,
                            background: tone(k.status).$1,
                            foreground: tone(k.status).$2,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (s.notes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Coach notes', style: OgText.heading(22)),
                  for (final n in s.notes)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: t.soft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${n.coach} · ${Fmt.day(n.at)}',
                              style: OgText.body(13, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(n.text, style: OgText.body(14, height: 1.45)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
