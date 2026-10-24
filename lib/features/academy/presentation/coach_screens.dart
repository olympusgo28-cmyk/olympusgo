import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../application/academy_providers.dart';
import '../domain/academy_models.dart';
import 'academy_screens.dart' show AcademyMark, classDays;

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

Widget _loading(String title) => KitScaffold(
  header: KitHeader(title: title),
  children: const [CupertinoActivityIndicator()],
);

// ─── Today ─────────────────────────────────────────────────────────────────

class AcademyTodayScreen extends ConsumerWidget {
  const AcademyTodayScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final a = ref.watch(academyProvider(id)).value;
    if (a == null) return _loading('Academy today');
    final alerts = ref.watch(coachAlertsProvider(id)).value ?? const [];
    final now = DateTime.now();
    // Today's classes, or the next day that has any.
    var day = DateTime(now.year, now.month, now.day);
    var classes = <AcademyClass>[];
    for (var i = 0; i < 7 && classes.isEmpty; i++) {
      final d = day.add(Duration(days: i));
      classes = a.classes.where((x) => x.weekdays.contains(d.weekday)).toList()
        ..sort(
          (x, y) => (x.hour * 60 + x.minute).compareTo(y.hour * 60 + y.minute),
        );
      if (classes.isNotEmpty) day = d;
    }
    final isToday = day.day == now.day && day.month == now.month;
    (Color, Color) tone(String tn) => switch (tn) {
      'red' => (t.dangerFill, t.danger),
      'yellow' => (t.warnFill, t.gold),
      _ => (t.infoFill, t.onInfoFill),
    };
    return KitScaffold(
      header: const KitHeader(title: 'Academy today', crumb: 'Coach home'),
      children: [
        Row(
          children: [
            AcademyMark(academy: a, size: 60),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name, style: OgText.heading(24)),
                  Text(
                    [
                      a.sport.label,
                      a.area,
                      if (a.audience.isNotEmpty) a.audience,
                    ].join(' · '),
                    style: OgText.body(13, color: c.textMuted),
                  ),
                  Text(
                    '${a.students} students · ${a.classes.length} classes · ${a.coaches.length} coaches',
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
              icon: OgIcons.personRequest,
              title: 'Enrolment requests',
              trailing: a.pendingRequests > 0
                  ? KitCountBadge(a.pendingRequests, size: 22)
                  : null,
              onTap: () => context.push(Routes.academyRequests(a.id)),
            ),
            KitNavTile(
              icon: OgIcons.calendarBox,
              title: 'All classes',
              subtitle: '${a.classes.length} classes a week',
              onTap: () => context.push(Routes.academyClasses(a.id)),
            ),
            if (!Env.hasSupabase)
              KitNavTile(
                icon: OgIcons.chatLines,
                title: 'Messages',
                subtitle: 'Parents and students',
                onTap: () => context.push(Routes.academyMessages(a.id)),
              ),
            KitNavTile(
              icon: OgIcons.clipboardList,
              title: 'Curriculum',
              subtitle: 'Lesson plans shared by all coaches',
              onTap: () => context.push(Routes.curriculum(a.id)),
            ),
            if (!Env.hasSupabase)
              KitNavTile(
                icon: OgIcons.wallet,
                title: 'Coach pay',
                subtitle: 'Your classes and what you are paid',
                onTap: () => context.push(Routes.coachPay),
              ),
            KitNavTile(
              icon: OgIcons.paperPlane,
              title: 'Invite students and parents',
              onTap: () => context.push(Routes.inviteStudents(a.id)),
            ),
          ],
        ),
        if (alerts.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Needs you', style: OgText.heading(22)),
              for (final al in alerts)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: tone(al.tone).$1,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 6, right: 12),
                          decoration: BoxDecoration(
                            color: tone(al.tone).$2,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                al.title,
                                style: OgText.body(15, weight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                al.body,
                                style: OgText.body(
                                  13,
                                  height: 1.4,
                                  color: t.onTag,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (al.action != null)
                          KitLink(
                            al.action!,
                            color: c.text,
                            onPressed: () => context.push(
                              al.action == 'Open'
                                  ? Routes.academyRequests(a.id)
                                  : Routes.changeClass(
                                      a.id,
                                      a.classes.first.id,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isToday ? "Today's classes" : 'Next classes',
                    style: OgText.heading(22),
                  ),
                ),
                Text(Fmt.day(day), style: OgText.body(13, color: c.textMuted)),
              ],
            ),
            if (classes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No classes yet. Add classes from All classes.',
                  style: OgText.body(14, color: c.textMuted),
                ),
              ),
            for (final x in classes)
              Pressable(
                semanticLabel: '${x.name}, ${Fmt.clock(x.hour, x.minute)}',
                onPressed: () => context.push(Routes.classSession(a.id, x.id)),
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 78,
                        child: Text(
                          Fmt.clock(x.hour, x.minute),
                          style: OgText.body(15, weight: FontWeight.w800),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${x.name}${x.levelName.isEmpty ? '' : ' · ${x.levelName}'}',
                              style: OgText.body(15, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                x.coach,
                                if (x.court.isNotEmpty) x.court,
                                '${x.enrolled} of ${x.capacity} students',
                              ].join(' · '),
                              style: OgText.body(13, color: c.textMuted),
                            ),
                            if (x.lesson.isNotEmpty)
                              Text(
                                'Week ${x.week} of ${x.termWeeks} · ${x.lesson}',
                                style: OgText.body(13, color: c.link),
                              ),
                          ],
                        ),
                      ),
                      OgIcon(
                        OgIcons.chevronRight,
                        size: 20,
                        color: c.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── All classes ───────────────────────────────────────────────────────────

class AcademyClassesScreen extends ConsumerWidget {
  const AcademyClassesScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final a = ref.watch(academyProvider(id)).value;
    if (a == null) return _loading('Classes');
    final byDay = <String, List<AcademyClass>>{};
    final sorted = [...a.classes]
      ..sort((x, y) {
        final d = x.weekdays.first.compareTo(y.weekdays.first);
        return d != 0
            ? d
            : (x.hour * 60 + x.minute).compareTo(y.hour * 60 + y.minute);
      });
    for (final x in sorted) {
      final key = x.weekdays.length == 1
          ? _weekdays[x.weekdays.first - 1]
          : x.weekdays.map((d) => _weekdays[d - 1]).join(' and ');
      (byDay[key] ??= []).add(x);
    }
    final students = a.classes.fold(0, (n, x) => n + x.enrolled);
    return KitScaffold(
      header: const KitHeader(title: 'Classes'),
      bottom: [
        if (a.myRole == AcademyRole.headCoach)
          KitButton(
            label: 'Add a class',
            onPressed: () => context.push(Routes.classNew(a.id)),
          ),
        if (a.classes.isNotEmpty)
          KitButton.outline(
            label: 'Change a class',
            onPressed: () =>
                context.push(Routes.changeClass(a.id, a.classes.first.id)),
          ),
      ],
      children: [
        Text(
          '${a.classes.length} classes a week · $students students',
          style: OgText.body(14, weight: FontWeight.w600, color: c.textMuted),
        ),
        for (final e in byDay.entries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(e.key, style: OgText.heading(20)),
              for (final x in e.value)
                Pressable(
                  semanticLabel: '${x.name}, ${classDays(x)}',
                  onPressed: () => context.push(Routes.classRoster(a.id, x.id)),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 60),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 76,
                          child: Text(
                            Fmt.clock(x.hour, x.minute),
                            style: OgText.body(14, weight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                x.name,
                                style: OgText.body(15, weight: FontWeight.w700),
                              ),
                              Text(
                                '${x.coach}, ${x.enrolled} students',
                                style: OgText.body(13, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (x.full)
                          KitTag(
                            'Full',
                            height: 22,
                            fontSize: 11,
                            background: t.dangerFill,
                            foreground: t.onDangerFill,
                          ),
                        const SizedBox(width: 6),
                        OgIcon(
                          OgIcons.chevronRight,
                          size: 20,
                          color: c.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        if (a.classes.isEmpty)
          const KitNote('No classes yet. Classes you add show here.'),
      ],
    );
  }
}

// ─── Class session ─────────────────────────────────────────────────────────

class ClassSessionScreen extends ConsumerStatefulWidget {
  const ClassSessionScreen({
    super.key,
    required this.academyId,
    required this.classId,
  });

  final String academyId;
  final String classId;

  @override
  ConsumerState<ClassSessionScreen> createState() => _ClassSessionScreenState();
}

class _ClassSessionScreenState extends ConsumerState<ClassSessionScreen> {
  final _absent = <String>{};
  final _skill = <String, SkillStatus>{};
  final _note = TextEditingController(
    text:
        'Great energy today. Next week we move on, so please practise '
        'split-step at home.',
  );
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(academyRepositoryProvider)
          .saveSession(
            SessionRecord(
              classId: widget.classId,
              absent: {..._absent},
              focusSkill: {..._skill},
              note: _note.text,
            ),
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(classRosterProvider(widget.classId));
      ref.invalidate(studentProvider);
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
    final t = context.tones;
    final a = ref.watch(academyProvider(widget.academyId)).value;
    final roster = ref.watch(classRosterProvider(widget.classId)).value;
    if (a == null || roster == null) return _loading('Class session');
    final x = a.classes.firstWhere((k) => k.id == widget.classId);
    final at = x.nextAt(DateTime.now().subtract(Duration(minutes: x.minutes)));
    final present = roster.length - _absent.length;
    final focusName = roster.isEmpty
        ? null
        : roster.first.skills
              .where((k) => k.id == x.focusSkill)
              .firstOrNull
              ?.name;
    if (_sent) {
      return KitScaffold(
        header: const KitHeader(title: 'Class session'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [KitButton(label: 'Done', onPressed: () => kitPop(context))],
        children: [
          const KitDoneBanner(title: 'Sent'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Each parent got one summary: attendance, this week’s lesson, '
              'their child’s skill update and your note.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    (Color, Color) tone(SkillStatus s) => switch (s) {
      SkillStatus.notYet => (t.tag, t.onTag),
      SkillStatus.practising => (t.warnFill, t.onWarnFill),
      SkillStatus.gotIt => (t.successFill, t.onSuccessFill),
    };
    return KitScaffold(
      header: KitHeader(
        title: '${x.name}${x.levelName.isEmpty ? '' : ' · ${x.levelName}'}',
        titleSize: 19,
        subtitle:
            '${Fmt.day(at)} · ${Fmt.timeRange(at, x.endOf(at))}${x.court.isEmpty ? '' : ' · ${x.court}'}',
      ),
      bottom: [
        KitButton(
          label: roster.isEmpty
              ? 'Save attendance'
              : 'Save and send to ${roster.length} parents',
          loading: _busy,
          onPressed: _send,
        ),
      ],
      children: [
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
                'WEEK ${x.week} OF ${x.termWeeks}',
                style: OgText.body(
                  11,
                  weight: FontWeight.w800,
                  color: t.gold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                x.lesson.isEmpty ? 'No lesson plan yet' : x.lesson,
                style: OgText.heading(26, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Same plan for all Level ${x.level} classes',
                style: OgText.body(13, color: const Color(0xFFC9C9CF)),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(child: Text('Students', style: OgText.heading(22))),
            Text(
              '$present of ${roster.length} present',
              style: OgText.body(13, color: c.textMuted),
            ),
          ],
        ),
        if (focusName != null)
          Text(
            'Tap $focusName to update it for each student.',
            style: OgText.body(13, color: c.textMuted),
          ),
        for (final s in roster)
          Builder(
            builder: (context) {
              final here = !_absent.contains(s.id);
              final current =
                  _skill[s.id] ??
                  s.skills
                      .where((k) => k.id == x.focusSkill)
                      .firstOrNull
                      ?.status;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.border)),
                ),
                child: Row(
                  children: [
                    SolidAvatar.forId(
                      s.id,
                      initials: s.initials,
                      size: 40,
                      fontSize: 13,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          if (s.flag.isNotEmpty)
                            Text(
                              s.flag,
                              style: OgText.body(12, color: c.textMuted),
                            ),
                        ],
                      ),
                    ),
                    if (current != null && here)
                      Pressable(
                        semanticLabel:
                            '$focusName for ${s.name}: ${current.label}',
                        onPressed: () =>
                            setState(() => _skill[s.id] = current.next),
                        child: KitTag(
                          current.label,
                          height: 30,
                          fontSize: 12,
                          background: tone(current).$1,
                          foreground: tone(current).$2,
                        ),
                      ),
                    const SizedBox(width: 8),
                    KitChip(
                      label: here ? 'Present' : 'Absent',
                      height: 34,
                      fontSize: 13,
                      selected: here,
                      onTap: () => setState(
                        () => here ? _absent.add(s.id) : _absent.remove(s.id),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        if (roster.isEmpty) const KitNote('No students in this class yet.'),
        KitTextArea(label: 'Note to parents', controller: _note, lines: 4),
        Text(
          'Each parent gets one summary: attendance, this week’s lesson, '
          'their child’s skill update and your note.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

// ─── Roster ────────────────────────────────────────────────────────────────

class ClassRosterScreen extends ConsumerWidget {
  const ClassRosterScreen({
    super.key,
    required this.academyId,
    required this.classId,
  });

  final String academyId;
  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final a = ref.watch(academyProvider(academyId)).value;
    final roster = ref.watch(classRosterProvider(classId)).value;
    if (a == null || roster == null) return _loading('Students');
    final x = a.classes.firstWhere((k) => k.id == classId);
    return KitScaffold(
      header: KitHeader(
        title: 'Students',
        trailing: a.myRole == AcademyRole.headCoach
            ? KitLink(
                'Edit class',
                onPressed: () => context.push(Routes.classEdit(a.id, x.id)),
              )
            : null,
      ),
      bottom: [
        KitButton(
          label: 'Take attendance',
          onPressed: () =>
              context.push(Routes.classSession(academyId, classId)),
        ),
        KitButton.outline(
          label: 'Invite a student',
          onPressed: () => context.push(Routes.inviteStudents(a.id)),
        ),
      ],
      children: [
        KitTitle(
          x.name,
          size: 26,
          lead:
              '${roster.length} students · ${classDays(x)} ${Fmt.clock(x.hour, x.minute)}',
        ),
        if (roster.isEmpty) const KitNote('No students yet.'),
        for (final s in roster)
          Pressable(
            semanticLabel:
                '${s.name}, ${s.skillsGot} of ${s.skills.length} skills, ${s.attendancePct}% attended',
            onPressed: () => context.push(Routes.studentProgress(s.id)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  SolidAvatar.forId(
                    s.id,
                    initials: s.initials,
                    size: 42,
                    fontSize: 14,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: OgText.body(15, weight: FontWeight.w700),
                        ),
                        Text(
                          [
                            if (s.age != null) 'Age ${s.age}',
                            '${s.skillsGot} of ${s.skills.length} skills',
                          ].join(', '),
                          style: OgText.body(13, color: c.textMuted),
                        ),
                        if (s.flag.isNotEmpty)
                          Text(s.flag, style: OgText.body(12, color: c.link)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${s.attendancePct}%',
                        style: OgText.body(15, weight: FontWeight.w800),
                      ),
                      Text(
                        'attended',
                        style: OgText.body(12, color: c.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Enrolment requests ────────────────────────────────────────────────────

class EnrolRequestsScreen extends ConsumerWidget {
  const EnrolRequestsScreen({super.key, required this.id});

  final String id;

  Future<void> _decide(WidgetRef ref, EnrolRequest r, RequestState s) async {
    HapticFeedback.selectionClick();
    await ref.read(academyRepositoryProvider).decide(r.id, s);
    ref.invalidate(enrolRequestsProvider(id));
    ref.invalidate(academyProvider(id));
    ref.invalidate(coachAlertsProvider(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final list = ref.watch(enrolRequestsProvider(id)).value;
    if (list == null) return _loading('Enrolment requests');
    final left = list.where((r) => r.state == RequestState.pending).length;
    return KitScaffold(
      header: const KitHeader(title: 'Enrolment requests'),
      children: [
        KitTitle(
          left == 0 ? 'All answered' : '$left to answer',
          size: 26,
          lead: 'Reply within 2 working days',
        ),
        if (list.isEmpty) const KitNote('No requests yet.'),
        for (final r in list)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SolidAvatar.forId(
                      r.id,
                      initials: r.student
                          .split(' ')
                          .take(2)
                          .map((w) => w[0])
                          .join(),
                      size: 42,
                      fontSize: 14,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.age == null
                                ? r.student
                                : '${r.student}, age ${r.age}',
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          Text(
                            [
                              r.parent.isEmpty
                                  ? 'Adult'
                                  : 'Parent: ${r.parent}',
                              r.className,
                            ].join(' · '),
                            style: OgText.body(13, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (r.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '“${r.note}”',
                    style: OgText.body(14, height: 1.4, color: t.onTag),
                  ),
                ],
                const SizedBox(height: 12),
                switch (r.state) {
                  RequestState.pending => Row(
                    children: [
                      Expanded(
                        child: KitButton(
                          label: 'Accept',
                          height: 44,
                          fontSize: 15,
                          onPressed: () =>
                              _decide(ref, r, RequestState.accepted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: KitButton(
                          label: 'Decline',
                          height: 44,
                          fontSize: 15,
                          style: KitButtonStyle.dangerOutline,
                          onPressed: () =>
                              _decide(ref, r, RequestState.declined),
                        ),
                      ),
                    ],
                  ),
                  _ => Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.state == RequestState.accepted
                              ? 'Accepted. The first invoice was sent.'
                              : 'Declined. They were told.',
                          style: OgText.body(
                            14,
                            weight: FontWeight.w600,
                            color: r.state == RequestState.accepted
                                ? t.successInk
                                : t.dangerText,
                          ),
                        ),
                      ),
                      KitLink(
                        'Undo',
                        onPressed: () => _decide(ref, r, RequestState.pending),
                      ),
                    ],
                  ),
                },
              ],
            ),
          ),
      ],
    );
  }
}
