import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../analysis/application/analysis_providers.dart';
import '../../analysis/presentation/analysis_screens.dart';
import '../../auth/data/auth_repository.dart';
import '../../discover/presentation/coming_screens.dart';
import '../application/fitness_providers.dart';
import '../domain/fitness_calc.dart';
import '../domain/fitness_models.dart';

/// A loading or failed screen, or null once [v] has a value.
Widget? fitnessWaiting(
  AsyncValue<Object?> v,
  String title,
  VoidCallback retry,
) {
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

/// The square tile with an exercise's two letters.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile(this.mark, {super.key});

  final String mark;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.tones.soft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(mark, style: context.type.section),
    ),
  );
}

/// A row with an exercise's tile, its name and a line under it.
class ExerciseRow extends StatelessWidget {
  const ExerciseRow({
    super.key,
    required this.mark,
    required this.title,
    required this.line,
    required this.onTap,
    this.trailing,
  });

  final String mark;
  final String title;
  final String line;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              ExerciseTile(mark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.type.body),
                    const SizedBox(height: 2),
                    Text(line, style: context.type.caption),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.tones.soft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: context.type.score),
            const SizedBox(height: 2),
            Text(label, style: context.type.caption),
          ],
        ),
      ),
    ),
  );
}

class FitnessHomeScreen extends ConsumerWidget {
  const FitnessHomeScreen({super.key});

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    WorkoutProgram p,
    ProgramDay d,
  ) async {
    // If one is already under way, this opens it instead.
    await ref
        .read(activeSessionProvider.notifier)
        .start(
          name: d.name.isEmpty ? p.name : d.name,
          plan: d.items,
          programId: p.id,
        );
    if (context.mounted) await context.push(Routes.fitnessTrain);
  }

  Widget _activeHero(BuildContext context, ActiveWorkout active) => _Hero(
    eyebrow: active.finished ? 'NOT SAVED YET' : 'IN PROGRESS',
    title: active.name,
    line: '${plural(active.done.length, 'set')} done',
    button: active.finished ? 'Save workout' : 'Back to workout',
    onTap: () => context.push(Routes.fitnessTrain),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = ref.watch(fitnessOpenProvider);
    final hasClips = ref.watch(myClipsProvider).value?.isNotEmpty ?? false;
    if (open.value == false) {
      // Clips stay reachable, so they can still be deleted.
      if (hasClips) return const MyClipsScreen();
      return const EmptyCategoryScreen(
        title: 'Fitness',
        message: 'Workouts will be here. None are open yet.',
      );
    }
    final summary = ref.watch(workoutSummaryProvider(30));
    final programs = ref.watch(workoutProgramsProvider);
    final active = ref.watch(activeSessionProvider).value;
    final analysisOpen =
        (ref.watch(analysisStatusProvider).value?.open ?? false) || hasClips;
    final blocked =
        fitnessWaiting(open, 'My workouts', () {
          ref.invalidate(fitnessOpenProvider);
        }) ??
        fitnessWaiting(summary, 'My workouts', () {
          ref.invalidate(workoutSummaryProvider);
        }) ??
        fitnessWaiting(programs, 'My workouts', () {
          ref.invalidate(workoutProgramsProvider);
        });
    if (blocked != null) {
      // No signal must never hide a workout that's waiting on the phone.
      if (active == null) return blocked;
      return KitScaffold(
        header: const KitHeader(title: 'My workouts'),
        children: [
          _activeHero(context, active),
          if (summary.hasError || programs.hasError || open.hasError)
            const KitNote(
              'Can’t load your workouts right now. Check your connection.',
              tone: KitTone.warn,
            ),
          if (summary.hasError || programs.hasError || open.hasError)
            KitButton(
              label: 'Try again',
              style: KitButtonStyle.outline,
              onPressed: () {
                ref.invalidate(fitnessOpenProvider);
                ref.invalidate(workoutSummaryProvider);
                ref.invalidate(workoutProgramsProvider);
              },
            ),
        ],
      );
    }
    final s = summary.requireValue;

    final list = programs.requireValue;
    final program = list.isEmpty ? null : list.first;
    final day = program?.days.where((d) => d.items.isNotEmpty).firstOrNull;

    return KitScaffold(
      header: const KitHeader(title: 'My workouts'),
      children: [
        if (active != null)
          _activeHero(context, active)
        else if (program != null && day != null)
          _Hero(
            eyebrow: program.template ? 'TEMPLATE' : program.name.toUpperCase(),
            title: day.name.isEmpty ? program.name : day.name,
            line:
                '${plural(day.items.length, 'exercise')} · about '
                '${minutesFor(day.items)} minutes · at your own pace',
            button: 'Start workout',
            onTap: () => _start(context, ref, program, day),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Stat(
                '${s.workouts30d}',
                '${s.workouts30d == 1 ? 'workout' : 'workouts'}, 30 days',
              ),
              const SizedBox(width: 10),
              _Stat('${s.weekStreak}', 'week streak'),
              const SizedBox(width: 10),
              _Stat(liftedText(s.liftedWeekG), 'lifted this week'),
            ],
          ),
        ),
        Column(
          children: [
            KitNavTile(
              icon: OgIcons.search,
              title: 'Exercises',
              subtitle: 'By muscle and equipment',
              padding: EdgeInsets.zero,
              minHeight: 68,
              ruleAbove: true,
              onTap: () => context.push(Routes.fitnessExercises),
            ),
            KitNavTile(
              icon: OgIcons.pencil,
              title: 'My programs',
              subtitle: 'Build your own',
              padding: EdgeInsets.zero,
              minHeight: 68,
              ruleAbove: true,
              onTap: () => context.push(Routes.fitnessPrograms),
            ),
            KitNavTile(
              icon: OgIcons.calendar,
              title: 'Workout log',
              subtitle: 'Every set you have done',
              padding: EdgeInsets.zero,
              minHeight: 68,
              ruleAbove: true,
              onTap: () => context.push(Routes.fitnessLog),
            ),
            KitNavTile(
              icon: OgIcons.sliders,
              title: 'Calculators',
              subtitle: s.minor
                  ? 'Plates'
                  : 'One-rep max, plates, body mass index',
              padding: EdgeInsets.zero,
              minHeight: 68,
              ruleAbove: true,
              onTap: () => context.push(Routes.fitnessCalculators),
            ),
            if (analysisOpen)
              KitNavTile(
                icon: OgIcons.video,
                title: 'Analyse my game',
                subtitle: 'Distance, speed and where you moved',
                padding: EdgeInsets.zero,
                minHeight: 68,
                ruleAbove: true,
                onTap: () => context.push(Routes.analysis),
              ),
          ],
        ),
        Text(
          'Your workouts are private to you. Practice here is not timed or '
          'ranked.',
          style: context.type.secondary.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.eyebrow,
    required this.title,
    required this.line,
    required this.button,
    required this.onTap,
  });

  final String eyebrow;
  final String title;
  final String line;
  final String button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.inverseCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            eyebrow,
            style: context.type.caption.copyWith(color: c.highlight),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: context.type.display.copyWith(color: c.onInverseCard),
          ),
          const SizedBox(height: 10),
          Text(
            line,
            style: context.type.body.copyWith(color: c.onInverseCardMuted),
          ),
          const SizedBox(height: 14),
          KitButton(label: button, onPressed: onTap),
        ],
      ),
    );
  }
}

/// The catalogue. With [pick] on, tapping an exercise returns it.
class ExerciseCatalogScreen extends ConsumerStatefulWidget {
  const ExerciseCatalogScreen({super.key, this.pick = false});

  final bool pick;

  @override
  ConsumerState<ExerciseCatalogScreen> createState() =>
      _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends ConsumerState<ExerciseCatalogScreen> {
  static const _tabs = ['All', 'Legs', 'Core', 'Upper'];
  var _tab = 0;
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(exercisesProvider);
    final blocked = fitnessWaiting(
      v,
      'Exercises',
      () => ref.invalidate(exercisesProvider),
    );
    if (blocked != null) return blocked;
    final q = _query.trim().toLowerCase();
    final rows = [
      for (final e in v.requireValue)
        if ((_tab == 0 || e.group == _tabs[_tab].toLowerCase()) &&
            (q.isEmpty || '${e.name} ${e.sub}'.toLowerCase().contains(q)))
          e,
    ];
    return KitScaffold(
      header: KitHeader(title: widget.pick ? 'Add an exercise' : 'Exercises'),
      children: [
        KitSearchField(
          hint: 'Search exercises',
          soft: true,
          onChanged: (t) => setState(() => _query = t),
        ),
        KitUnderlineTabs(
          labels: _tabs,
          selected: _tab,
          padding: EdgeInsets.zero,
          onSelect: (i) => setState(() => _tab = i),
        ),
        if (rows.isEmpty)
          Column(
            children: [
              const SizedBox(height: 24),
              Text('No exercise matches', style: context.type.title),
              const SizedBox(height: 6),
              const KitMuted('Try a muscle name, like calves.'),
            ],
          ),
        for (final e in rows)
          ExerciseRow(
            mark: e.mark,
            title: e.name,
            line: e.sub,
            onTap: () => widget.pick
                ? context.pop(e)
                : context.push(Routes.fitnessExercise(e.id)),
          ),
      ],
    );
  }
}

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(exercisesProvider);
    final blocked = fitnessWaiting(
      v,
      'Exercise',
      () => ref.invalidate(exercisesProvider),
    );
    if (blocked != null) return blocked;
    final e = v.requireValue.where((x) => x.id == id).firstOrNull;
    if (e == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Exercise'),
        children: [KitNote('This exercise isn’t available.')],
      );
    }
    final history = ref.watch(exerciseHistoryProvider(id)).value;
    final minor = ref.watch(workoutSummaryProvider(30)).value?.minor ?? true;
    final best = history?.best;
    final oneRep = switch (best) {
      PersonalBest(weightG: final g?, reps: final r?) => oneRepMaxG(g, r),
      _ => null,
    };
    return KitScaffold(
      header: const KitHeader(title: 'Exercise'),
      children: [
        Row(
          children: [
            ExerciseTile(e.mark),
            const SizedBox(width: 12),
            Expanded(child: Text(e.name, style: context.type.title)),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final m in e.muscles) KitTag(m), KitTag(e.equipment)],
        ),
        const KitSection('How to do it'),
        for (final (i, step) in e.steps.indexed)
          Text(
            '${i + 1}. $step',
            style: context.type.body.copyWith(height: 1.45),
          ),
        if (history != null && history.times > 0) ...[
          const KitSection('Your records'),
          Column(
            children: [
              if (best != null)
                KitKeyValue(
                  'Best set',
                  '${bestText(reps: best.reps, seconds: best.seconds, weightG: best.weightG)}, '
                      '${Fmt.day(best.at)}',
                ),
              if (oneRep != null && !minor)
                KitKeyValue(
                  'Estimated one-rep max',
                  '${(oneRep + 500) ~/ 1000} kg',
                ),
              KitKeyValue('Times done', '${history.times}'),
            ],
          ),
        ],
        if (e.tip.isNotEmpty || e.safety.isNotEmpty)
          KitNote([e.tip, e.safety].where((t) => t.isNotEmpty).join(' ')),
      ],
    );
  }
}

class WorkoutLogScreen extends ConsumerStatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen> {
  static const _ranges = <(String, int?)>[
    ('7 days', 7),
    ('30 days', 30),
    ('All time', null),
  ];
  var _range = 1;

  Future<void> _delete(WorkoutEntry w) async {
    final yes = await showKitSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitTitle(
            'Delete this workout?',
            lead: '${w.name}, ${Fmt.day(w.startedAt)}. This can’t be undone.',
          ),
          const SizedBox(height: 18),
          KitButton(
            label: 'Delete workout',
            style: KitButtonStyle.danger,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          const SizedBox(height: 10),
          KitButton(
            label: 'Keep it',
            style: KitButtonStyle.outline,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await ref.read(fitnessRepositoryProvider).deleteWorkout(w.id);
      ref.invalidate(workoutSummaryProvider);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _ranges[_range].$2;
    final v = ref.watch(workoutSummaryProvider(days));
    final blocked = fitnessWaiting(
      v,
      'Workout log',
      () => ref.invalidate(workoutSummaryProvider),
    );
    if (blocked != null) return blocked;
    final s = v.requireValue;
    return KitScaffold(
      header: const KitHeader(title: 'Workout log'),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final (i, r) in _ranges.indexed)
              KitChip(
                label: r.$1,
                height: 44,
                selected: i == _range,
                onTap: () => setState(() => _range = i),
              ),
          ],
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Stat('${s.workouts}', s.workouts == 1 ? 'workout' : 'workouts'),
              const SizedBox(width: 10),
              _Stat(timeText(s.seconds), 'time'),
              const SizedBox(width: 10),
              _Stat(liftedText(s.liftedG), 'lifted'),
            ],
          ),
        ),
        if (s.recent.isEmpty)
          Text(
            'No workouts yet. Start one from My workouts.',
            style: context.type.secondary.copyWith(height: 1.4),
          ),
        for (final w in s.recent)
          KitNavTile(
            icon: OgIcons.calendar,
            title: w.name,
            subtitle:
                '${Fmt.day(w.startedAt)} · ${timeText(w.seconds)} · '
                '${plural(w.exercises, 'exercise')}',
            trailing: Text(
              w.liftedG > 0 ? liftedText(w.liftedG) : 'Bodyweight',
              style: context.type.body,
            ),
            padding: EdgeInsets.zero,
            minHeight: 68,
            chevron: false,
            onTap: () => _delete(w),
          ),
        if (s.bests.isNotEmpty) ...[
          const KitSection('Personal bests'),
          Column(
            children: [
              for (final b in s.bests)
                KitKeyValue(
                  '${b.exercise}, ${Fmt.day(b.at)}',
                  bestText(
                    reps: b.reps,
                    seconds: b.seconds,
                    weightG: b.weightG,
                  ),
                ),
            ],
          ),
        ],
        const KitNote(
          'Your Meets, classes and tournaments are listed in Sessions and '
          'rating, not here.',
        ),
        KitButton(
          label: 'Sessions and rating',
          style: KitButtonStyle.outline,
          onPressed: () => context.push(Routes.passport),
        ),
      ],
    );
  }
}

class CalculatorsScreen extends ConsumerStatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  ConsumerState<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends ConsumerState<CalculatorsScreen> {
  var _which = 'One-rep max';
  final _weight = TextEditingController(text: '70');
  final _reps = TextEditingController(text: '5');
  final _bar = TextEditingController(text: '20');
  final _height = TextEditingController(text: '172');

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _bar.dispose();
    _height.dispose();
    super.dispose();
  }

  Widget _result(String label, String value, String line) {
    final c = context.og;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.inverseCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.type.caption.copyWith(color: c.onInverseCardMuted),
          ),
          Text(value, style: context.type.score.copyWith(color: c.highlight)),
          if (line.isNotEmpty)
            Text(
              line,
              style: context.type.caption.copyWith(
                color: c.onInverseCardMuted,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  KitInput _input(String label, TextEditingController c) => KitInput(
    label: label,
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: (_) => setState(() {}),
  );

  Widget _oneRep() {
    final weight = gramsFrom(_weight.text);
    final reps = int.tryParse(_reps.text.trim());
    final est = weight == null || reps == null
        ? null
        : oneRepMaxG(weight, reps);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kitSpaced([
        _input('Weight lifted, kg', _weight),
        _input('Reps', _reps),
        if (est == null)
          const KitNote('Enter a weight and up to 12 reps.')
        else
          _result(
            'Estimated one-rep max',
            '${(est + 500) ~/ 1000} kg',
            'Work sets at 80% would be ${(est * 8 + 5000) ~/ 10000} kg.',
          ),
      ], 18),
    );
  }

  Widget _plates() {
    final target = gramsFrom(_weight.text);
    final bar = gramsFrom(_bar.text);
    if (target == null || bar == null || target < bar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: kitSpaced([
          _input('Target weight, kg', _weight),
          _input('Bar weight, kg', _bar),
          const KitNote('The target has to be at least the bar’s weight.'),
        ], 18),
      );
    }
    final p = platesPerSide(target, bar);
    final text = p.plates.isEmpty
        ? 'Just the bar'
        : '${p.plates.map(kgText).join(' + ')} kg';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kitSpaced([
        _input('Target weight, kg', _weight),
        _input('Bar weight, kg', _bar),
        _result(
          'Each side',
          text,
          p.left > 0
              ? '${kgText(p.left)} kg short on each side. No plate is that '
                    'small.'
              : '',
        ),
      ], 18),
    );
  }

  Widget _bmi() {
    final height = int.tryParse(_height.text.trim());
    final weight = gramsFrom(_weight.text);
    final bmi = height == null || weight == null
        ? null
        : bmiText(height, weight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kitSpaced([
        _input('Height, cm', _height),
        _input('Weight, kg', _weight),
        if (bmi == null)
          const KitNote('Enter your height and weight.')
        else
          _result('Body mass index', bmi, 'This is a rough guide.'),
      ], 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Until the server answers, this counts as a minor's view.
    final minor = ref.watch(workoutSummaryProvider(30)).value?.minor ?? true;
    final names = minor
        ? const ['Plates']
        : const ['One-rep max', 'Plates', 'Body mass index'];
    final which = names.contains(_which) ? _which : names.first;
    return KitScaffold(
      header: const KitHeader(title: 'Calculators'),
      children: [
        const KitSection('Calculator'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in names)
              KitChip(
                label: n,
                height: 44,
                selected: n == which,
                onTap: () => setState(() => _which = n),
              ),
          ],
        ),
        switch (which) {
          'One-rep max' => _oneRep(),
          'Plates' => _plates(),
          _ => _bmi(),
        },
        const KitNote(
          'Calculators give estimates. Ask a coach or doctor before starting '
          'a new training load.',
        ),
      ],
    );
  }
}
