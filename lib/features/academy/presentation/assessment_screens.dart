import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/academy_providers.dart';
import '../domain/lesson_models.dart';

Widget? _waiting(AsyncValue<Object?> v, String title, VoidCallback retry) {
  if (v.hasValue) return null;
  return KitScaffold(
    header: KitHeader(title: title),
    children: v.hasError
        ? [
            KitNote(
              v.error is AuthFailure
                  ? (v.error! as AuthFailure).message
                  : 'Can’t load this right now. Check your connection.',
              tone: KitTone.warn,
            ),
            KitButton(label: 'Try again', onPressed: retry),
          ]
        : const [CupertinoActivityIndicator()],
  );
}

// ─── Templates ─────────────────────────────────────────────────────────────

class AssessmentTemplatesScreen extends ConsumerWidget {
  const AssessmentTemplatesScreen({super.key, required this.academyId});

  final String academyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(assessmentTemplatesProvider(academyId));
    final blocked = _waiting(
      v,
      'Assessment templates',
      () => ref.invalidate(assessmentTemplatesProvider(academyId)),
    );
    if (blocked != null) return blocked;
    final list = v.requireValue;
    return KitScaffold(
      header: const KitHeader(title: 'Assessment templates'),
      bottom: [
        KitButton(
          label: 'New template',
          onPressed: () =>
              context.push(Routes.assessmentTemplateNew(academyId)),
        ),
      ],
      children: [
        if (list.isEmpty)
          Text(
            'No templates yet. Make one for what your coaches score.',
            style: OgText.body(14, color: context.og.textMuted),
          ),
        for (final t in list)
          KitCard(
            padding: const EdgeInsets.all(14),
            children: [
              Text(t.name, style: OgText.body(15, weight: FontWeight.w600)),
              Text(
                '${t.criteria.map((c) => c.$2).join(', ')} · out of ${t.scaleMax}',
                style: OgText.body(13, color: context.og.textMuted),
              ),
              KitLink(
                'Stop using',
                onPressed: () async {
                  try {
                    await ref
                        .read(assessmentRepositoryProvider)
                        .archiveTemplate(t.id);
                    ref.invalidate(assessmentTemplatesProvider(academyId));
                  } on AuthFailure catch (e) {
                    if (context.mounted) {
                      showOgToast(context, e.message, error: true);
                    }
                  }
                },
              ),
            ],
          ),
      ],
    );
  }
}

class AssessmentTemplateEditScreen extends ConsumerStatefulWidget {
  const AssessmentTemplateEditScreen({super.key, required this.academyId});

  final String academyId;

  @override
  ConsumerState<AssessmentTemplateEditScreen> createState() =>
      _AssessmentTemplateEditScreenState();
}

class _AssessmentTemplateEditScreenState
    extends ConsumerState<AssessmentTemplateEditScreen> {
  final _name = TextEditingController();
  final _lines = [TextEditingController(), TextEditingController()];
  int _scale = 5;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    for (final c in _lines) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(assessmentRepositoryProvider)
          .saveTemplate(
            widget.academyId,
            name: _name.text,
            scaleMax: _scale,
            criteria: [
              for (final c in _lines)
                if (c.text.trim().isNotEmpty) c.text.trim(),
            ],
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(assessmentTemplatesProvider(widget.academyId));
      if (mounted) kitPop(context);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => KitScaffold(
    header: const KitHeader(title: 'New template'),
    bottom: [
      KitButton(label: 'Save template', loading: _busy, onPressed: _save),
    ],
    children: [
      KitInput(
        label: 'Name',
        controller: _name,
        hint: 'Term skills',
        maxLength: 60,
      ),
      KitSegments(
        labels: const ['Out of 5', 'Out of 10'],
        selected: _scale == 5 ? 0 : 1,
        onSelect: (i) => setState(() => _scale = i == 0 ? 5 : 10),
      ),
      for (var i = 0; i < _lines.length; i++)
        KitInput(
          label: 'Thing to score ${i + 1}',
          controller: _lines[i],
          maxLength: 60,
        ),
      if (_lines.length < 20)
        KitButton.outline(
          label: 'Add another',
          onPressed: () => setState(() => _lines.add(TextEditingController())),
        ),
      const KitNote(
        'Once a coach has used a template, what it scores is fixed, so '
        'progress compares like with like. An academy level never changes a '
        'Play rating.',
      ),
    ],
  );
}

// ─── Assessing ─────────────────────────────────────────────────────────────

/// A coach scores a student, or corrects their own assessment when [editId]
/// is set.
class AssessStudentScreen extends ConsumerStatefulWidget {
  const AssessStudentScreen({super.key, required this.studentId, this.editId});

  final String studentId;
  final String? editId;

  @override
  ConsumerState<AssessStudentScreen> createState() =>
      _AssessStudentScreenState();
}

class _AssessStudentScreenState extends ConsumerState<AssessStudentScreen> {
  final _note = TextEditingController();
  final _scores = <String, int>{};
  String? _templateId;
  int? _level;
  DateTime _on = DateTime.now();
  bool _busy = false;
  bool _filled = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(String playerId, int lines) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(assessmentRepositoryProvider)
          .save(
            id: widget.editId,
            studentId: widget.editId == null ? widget.studentId : null,
            templateId: widget.editId == null ? _templateId : null,
            on: _on,
            level: _level,
            note: _note.text,
            scores: _scores,
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(playerAssessmentsProvider(playerId));
      if (mounted) kitPop(context);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final student = ref.watch(studentProvider(widget.studentId));
    final blocked = _waiting(
      student,
      'Assess',
      () => ref.invalidate(studentProvider(widget.studentId)),
    );
    if (blocked != null) return blocked;
    final s = student.requireValue;
    final templates = ref.watch(assessmentTemplatesProvider(s.academyId));
    final blockedT = _waiting(
      templates,
      'Assess',
      () => ref.invalidate(assessmentTemplatesProvider(s.academyId)),
    );
    if (blockedT != null) return blockedT;
    final past = ref.watch(playerAssessmentsProvider(s.playerId)).value;
    final editing = past?.where((a) => a.id == widget.editId).firstOrNull;
    if (editing != null && !_filled) {
      _filled = true;
      _templateId = editing.templateId;
      _level = editing.level;
      _on = editing.on;
      _note.text = editing.note;
      for (final x in editing.scores) {
        _scores[x.criterionId] = x.score;
      }
    }
    final list = templates.requireValue;
    final t = list.where((x) => x.id == _templateId).firstOrNull;
    // A correction scores what was first scored, even on a retired template.
    final lines =
        t?.criteria ??
        [
          for (final x in editing?.scores ?? const <AssessmentScore>[])
            (x.criterionId, x.label),
        ];
    final scale = t?.scaleMax ?? editing?.scores.firstOrNull?.max ?? 5;
    final ready =
        lines.isNotEmpty && lines.every((l) => _scores.containsKey(l.$1));
    return KitScaffold(
      header: KitHeader(
        title: editing == null ? 'Assess' : 'Correct assessment',
      ),
      bottom: [
        KitButton(
          label: 'Save assessment',
          loading: _busy,
          onPressed: ready ? () => _save(s.playerId, lines.length) : null,
        ),
      ],
      children: [
        KitTitle(
          s.name,
          size: 26,
          lead: 'Seen by ${s.firstName}, their parent and you.',
        ),
        if (widget.editId == null) ...[
          if (list.isEmpty)
            Text(
              'Your head coach needs to make a template first.',
              style: OgText.body(14, color: c.textMuted),
            ),
          for (final x in list)
            KitChoiceRow(
              title: x.name,
              subtitle: 'Out of ${x.scaleMax}',
              selected: _templateId == x.id,
              onTap: () => setState(() {
                _templateId = x.id;
                _scores.clear();
              }),
            ),
        ],
        for (final (id, label) in lines)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: OgText.body(15, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var n = 0; n <= scale; n++)
                    KitChip(
                      label: '$n',
                      height: 44,
                      selected: _scores[id] == n,
                      onTap: () => setState(() => _scores[id] = n),
                    ),
                ],
              ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Academy level (optional)',
              style: OgText.body(15, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var n = 1; n <= 9; n++)
                  KitChip(
                    label: '$n',
                    height: 44,
                    selected: _level == n,
                    onTap: () =>
                        setState(() => _level = _level == n ? null : n),
                  ),
              ],
            ),
          ],
        ),
        KitTextArea(label: 'Note', optional: true, controller: _note),
        const KitNote('An academy level never changes a Play rating.'),
      ],
    );
  }
}

// ─── History and improvement ───────────────────────────────────────────────

/// One thing assessed over time.
class ScoreSparkline extends StatelessWidget {
  const ScoreSparkline({super.key, required this.line});

  final ScoreLine line;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final first = line.points.first.$2;
    final last = line.points.last.$2;
    final words = line.points.length == 1
        ? '$last out of ${line.max}'
        : 'Started at $first, now $last, out of ${line.max}';
    return Semantics(
      label: '${line.label}. $words',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.label,
                  style: OgText.body(14, weight: FontWeight.w600),
                ),
              ),
              Text('$last / ${line.max}', style: OgText.body(14)),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: CustomPaint(
              painter: _LinePainter(
                line,
                ink: OgColors.orange300,
                rule: c.border,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(words, style: OgText.body(12, color: c.textMuted)),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.line, {required this.ink, required this.rule});

  final ScoreLine line;
  final Color ink;
  final Color rule;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = rule
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      base,
    );
    final n = line.points.length;
    Offset at(int i) => Offset(
      n == 1 ? size.width / 2 : size.width * i / (n - 1),
      size.height - 4 - (size.height - 8) * line.points[i].$2 / line.max,
    );
    final stroke = Paint()
      ..color = ink
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < n; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(path, stroke);
    final dot = Paint()..color = ink;
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(at(i), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.line != line || old.ink != ink;
}

class AssessmentHistoryScreen extends ConsumerWidget {
  const AssessmentHistoryScreen({
    super.key,
    required this.playerId,
    this.studentId,
  });

  final String playerId;

  /// Set when a coach came from a student, so they can correct their own.
  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final v = ref.watch(playerAssessmentsProvider(playerId));
    final blocked = _waiting(
      v,
      'Assessments',
      () => ref.invalidate(playerAssessmentsProvider(playerId)),
    );
    if (blocked != null) return blocked;
    final all = v.requireValue;
    final groups = <String, List<Assessment>>{};
    for (final a in all) {
      (groups[a.templateId] ??= []).add(a);
    }
    return KitScaffold(
      header: const KitHeader(title: 'Assessments'),
      children: [
        if (all.isEmpty)
          Text(
            'No assessments yet. They show up here once a coach writes one.',
            style: OgText.body(14, color: c.textMuted),
          ),
        for (final g in groups.values) ...[
          Text(g.last.template, style: OgText.heading(20)),
          for (final line in scoreLines(g)) ScoreSparkline(line: line),
          for (final a in g.reversed)
            KitCard(
              padding: const EdgeInsets.all(14),
              children: [
                Text(
                  '${Fmt.day(a.on)} · ${a.coach}',
                  style: OgText.body(14, weight: FontWeight.w600),
                ),
                Text(
                  [
                    a.academy,
                    if (a.level != null) 'Academy level ${a.level}',
                    if (a.edited) 'Edited',
                  ].join(' · '),
                  style: OgText.body(13, color: c.textMuted),
                ),
                if (a.note.isNotEmpty)
                  Text(a.note, style: OgText.body(14, height: 1.4)),
                if (a.mine && studentId != null)
                  KitLink(
                    'Correct this',
                    onPressed: () =>
                        context.push(Routes.assess(studentId!, edit: a.id)),
                  ),
              ],
            ),
        ],
        const KitNote('An academy level is separate from your Play rating.'),
      ],
    );
  }
}
