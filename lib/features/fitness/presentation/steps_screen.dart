import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/pressable.dart';
import '../../play/presentation/play_card/play_card_text.dart' show thousands;
import '../application/steps_providers.dart';
import '../domain/steps.dart';

/// A ring that fills as [progress] goes from 0 to 1, with [child] in the middle.
class StepRing extends StatelessWidget {
  const StepRing({
    super.key,
    required this.progress,
    required this.size,
    required this.stroke,
    this.child,
  });

  final double progress;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          stroke: stroke,
          track: context.tones.soft,
          fill: c.primary,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.fill,
  });

  final double progress;
  final double stroke;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arc, 0, math.pi * 2, false, base);
    if (progress <= 0) return;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = fill;
    canvas.drawArc(arc, -math.pi / 2, math.pi * 2 * progress, false, p);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.stroke != stroke ||
      old.track != track ||
      old.fill != fill;
}

/// Bars for [values], the last one (today) in the brand colour, with a dashed
/// line at [goal]. [labels] sit under the bars; a null label is left blank.
class StepBars extends StatelessWidget {
  const StepBars({
    super.key,
    required this.values,
    required this.goal,
    required this.labels,
    this.height = 100,
    this.showGoal = true,
  });

  final List<int> values;
  final int goal;
  final List<String?> labels;
  final double height;

  /// The goal line is for whole days; an hour never reaches the goal.
  final bool showGoal;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final peak = values.isEmpty ? 0 : values.reduce(math.max);
    final top = math.max(showGoal ? goal : 0, peak).toDouble();
    final gap = values.length > 14 ? 2.0 : 8.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height + 18,
          child: Stack(
            children: [
              if (showGoal && top > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 18 + height * (1 - goal / top),
                  child: CustomPaint(
                    painter: _DashPainter(c.borderControl),
                    size: const Size.fromHeight(1),
                  ),
                ),
              if (showGoal && top > 0)
                Positioned(
                  right: 0,
                  top: 18 + height * (1 - goal / top) - 17,
                  child: Text('Goal', style: context.type.caption),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < values.length; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      Expanded(
                        child: Container(
                          height: top == 0
                              ? 3
                              : math.max(3.0, height * values[i] / top),
                          decoration: BoxDecoration(
                            color: i == values.length - 1
                                ? c.primary
                                : context.tones.divider,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                              bottom: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                child: Text(
                  labels[i] ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: context.type.caption.copyWith(
                    fontWeight: i == labels.length - 1
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: i == labels.length - 1 ? c.text : c.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + 4, size.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// The Steps card on My workouts: a ring, today's count and the goal, and the
/// last seven days. With no permission it asks; with no health store it is not
/// shown. Tapping opens the Steps screen.
class StepsCard extends ConsumerWidget {
  const StepsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(stepsAccessProvider);
    return access.when(
      loading: () => const _CardShell(child: _SkeletonRow()),
      error: (_, _) => _CardShell(
        child: _Message(
          title: 'Can’t read your steps right now',
          line: 'Check that Health is on, then try again.',
          button: 'Try again',
          onPressed: () => ref.invalidate(stepsAccessProvider),
        ),
      ),
      data: (a) => switch (a) {
        StepsAccess.unavailable => const SizedBox.shrink(),
        StepsAccess.notAsked => _CardShell(
          child: _Message(
            title: 'Count your steps',
            line:
                'See today’s steps and how your week is going. They stay on '
                'this phone.',
            button: 'Allow step counting',
            onPressed: () => ref.read(stepsAccessProvider.notifier).request(),
          ),
        ),
        StepsAccess.denied => _CardShell(
          child: _Message(
            title: 'Steps are off',
            line:
                'Turn them on in Health Connect, under App permissions, to count '
                'your steps.',
            button: 'Open Settings',
            onPressed: () =>
                ref.read(stepsAccessProvider.notifier).openSettings(),
          ),
        ),
        StepsAccess.allowed => _AllowedCard(ref: ref),
      },
    );
  }
}

class _AllowedCard extends StatelessWidget {
  const _AllowedCard({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final steps = ref.watch(stepsProvider);
    return steps.when(
      loading: () => const _CardShell(child: _SkeletonRow()),
      error: (_, _) => _CardShell(
        child: _Message(
          title: 'Can’t read your steps right now',
          line: 'Check that Health is on, then try again.',
          button: 'Try again',
          onPressed: () => ref.invalidate(stepsProvider),
        ),
      ),
      data: (s) {
        if (s == null) return const SizedBox.shrink();
        return Pressable(
          semanticLabel: s.none
              ? 'Steps. No steps yet today. Open Steps'
              : 'Steps. ${thousands(s.today)} today, goal '
                    '${thousands(s.goal)}. Open Steps',
          onPressed: () => context.push(Routes.fitnessSteps),
          child: _CardShell(
            accent: true,
            child: Column(
              children: [
                Row(
                  children: [
                    StepRing(
                      progress: s.progress,
                      size: 76,
                      stroke: 9,
                      child: Text(
                        '${s.percent}%',
                        style: context.type.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          color: c.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Steps today', style: context.type.caption),
                          Text(
                            s.none ? '0' : thousands(s.today),
                            style: context.type.display,
                          ),
                          Text(
                            s.reached
                                ? 'Goal reached'
                                : 'Goal ${thousands(s.goal)}',
                            style: context.type.caption,
                          ),
                        ],
                      ),
                    ),
                    OgIcon(
                      OgIcons.chevronRight,
                      size: 20,
                      strokeWidth: 2,
                      color: c.borderControl,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MiniWeek(days: s.inRange(StepsRange.week), goal: s.goal),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Seven small bars, today in the brand colour.
class _MiniWeek extends StatelessWidget {
  const _MiniWeek({required this.days, required this.goal});

  final List<StepsDay> days;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final peak = days.fold<int>(goal, (a, d) => math.max(a, d.steps));
    return ExcludeSemantics(
      child: SizedBox(
        height: 26,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < days.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: peak == 0
                      ? 3
                      : math.max(3.0, 26 * days[i].steps / peak),
                  decoration: BoxDecoration(
                    color: i == days.length - 1
                        ? c.primary
                        : context.tones.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.accent = false});

  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent ? c.primary : c.border,
          width: accent ? 1.5 : 1,
        ),
      ),
      child: child,
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final soft = context.tones.soft;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Semantics(
      label: 'Loading your steps',
      child: Row(
        children: [
          StepRing(progress: 0, size: 76, stroke: 9),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(80, 13),
              const SizedBox(height: 8),
              bar(130, 28),
              const SizedBox(height: 8),
              bar(70, 13),
            ],
          ),
        ],
      ),
    );
  }
}

/// A title, a line and a button: asking for permission, or saying why steps
/// are not showing.
class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.line,
    required this.button,
    required this.onPressed,
  });

  final String title;
  final String line;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: context.type.section),
        const SizedBox(height: 4),
        Text(line, style: context.type.secondary),
        const SizedBox(height: 12),
        KitButton.outline(label: button, height: 44, onPressed: onPressed),
      ],
    );
  }
}

/// The Steps screen: today's ring, a Day, Week or Month view, the average and
/// the best day, the daily goal, and a note that steps stay on the phone.
class StepsScreen extends ConsumerStatefulWidget {
  const StepsScreen({super.key});

  @override
  ConsumerState<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends ConsumerState<StepsScreen> {
  StepsRange _range = StepsRange.week;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Steps keep counting while the app is away; read them again on return.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.invalidate(stepsProvider);
        ref.invalidate(stepHoursProvider);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(stepsAccessProvider);
    return KitScaffold(
      header: const KitHeader(title: 'Steps'),
      children: [
        access.when(
          loading: () => const _ScreenSkeleton(),
          error: (_, _) => _ScreenMessage(
            title: 'Can’t read your steps right now',
            line: 'Check that Health is on, then try again.',
            button: 'Try again',
            onPressed: () => ref.invalidate(stepsAccessProvider),
          ),
          data: (a) => switch (a) {
            StepsAccess.unavailable => const _ScreenMessage(
              title: 'Steps aren’t available on this phone',
              line: 'This phone has no Health app to read steps from.',
            ),
            StepsAccess.notAsked => _ScreenMessage(
              title: 'Count your steps',
              line:
                  'See today’s steps and how your week is going. They stay '
                  'on this phone and nobody else can see them.',
              button: 'Allow step counting',
              onPressed: () => ref.read(stepsAccessProvider.notifier).request(),
            ),
            StepsAccess.denied => _ScreenMessage(
              title: 'Steps are off',
              line:
                  'Turn them on in Health Connect, under App permissions, to count '
                  'your steps.',
              button: 'Open Settings',
              onPressed: () =>
                  ref.read(stepsAccessProvider.notifier).openSettings(),
            ),
            StepsAccess.allowed => _body(context),
          },
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final steps = ref.watch(stepsProvider);
    return steps.when(
      loading: () => const _ScreenSkeleton(),
      error: (_, _) => _ScreenMessage(
        title: 'Can’t read your steps right now',
        line: 'Check that Health is on, then try again.',
        button: 'Try again',
        onPressed: () => ref.invalidate(stepsProvider),
      ),
      data: (s) {
        if (s == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(summary: s),
            if (s.days.every((d) => d.steps == 0)) ...[
              const SizedBox(height: 10),
              Text(
                'No steps showing? Check that OlympusGO can read steps in '
                'Settings, Health, Data Access.',
                textAlign: TextAlign.center,
                style: context.type.caption.copyWith(height: 1.45),
              ),
            ],
            const SizedBox(height: 18),
            PillTabs(
              labels: [for (final r in StepsRange.values) r.label],
              index: _range.index,
              onChanged: (i) => setState(() => _range = StepsRange.values[i]),
            ),
            const SizedBox(height: 16),
            _chart(context, s),
            const SizedBox(height: 18),
            _numbers(context, s),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: context.og.border),
                ),
              ),
              child: KitNavTile(
                icon: OgIcons.sliders,
                title: 'Daily goal',
                subtitle: '${thousands(s.goal)} steps',
                padding: EdgeInsets.zero,
                minHeight: 68,
                onTap: () => showStepGoalSheet(context, ref, s.goal),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Steps come from this phone and stay on it. Nobody else can see '
              'them.',
              style: context.type.caption.copyWith(height: 1.45),
            ),
          ],
        );
      },
    );
  }

  Widget _chart(BuildContext context, StepsSummary s) {
    switch (_range) {
      case StepsRange.day:
        final hours = ref.watch(stepHoursProvider(_today));
        return hours.when(
          loading: () => const SizedBox(height: 124),
          error: (_, _) => _ScreenMessage(
            title: 'Can’t read your steps right now',
            line: 'Try again in a moment.',
            button: 'Try again',
            onPressed: () => ref.invalidate(stepHoursProvider),
          ),
          data: (h) => Semantics(
            label: 'Steps by hour today',
            child: StepBars(
              values: h,
              goal: s.goal,
              showGoal: false,
              labels: [
                for (var i = 0; i < 24; i++)
                  switch (i) {
                    0 => '12am',
                    6 => '6am',
                    12 => '12pm',
                    18 => '6pm',
                    _ => null,
                  },
              ],
            ),
          ),
        );
      case StepsRange.week:
        final days = s.inRange(StepsRange.week);
        return Semantics(
          label: 'Steps for the last 7 days',
          child: StepBars(
            values: [for (final d in days) d.steps],
            goal: s.goal,
            labels: [for (final d in days) _initial(d.day)],
          ),
        );
      case StepsRange.month:
        final days = s.inRange(StepsRange.month);
        return Semantics(
          label: 'Steps for the last 30 days',
          child: StepBars(
            values: [for (final d in days) d.steps],
            goal: s.goal,
            labels: [
              for (var i = 0; i < days.length; i++)
                if (i == 0 || i == days.length - 1 || i % 7 == 0)
                  '${days[i].day.day}'
                else
                  null,
            ],
          ),
        );
    }
  }

  static String _initial(DateTime d) =>
      const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];

  Widget _numbers(BuildContext context, StepsSummary s) {
    final best = s.best(_range);
    final average = s.average(_range);
    Widget tile(String value, String label) => Expanded(
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
              Text(value, style: context.type.display),
              const SizedBox(height: 2),
              Text(label, style: context.type.caption),
            ],
          ),
        ),
      ),
    );
    final bestLabel = best == null
        ? 'best day'
        : 'best day, ${Fmt.day(best.day).split(' ').first}';
    if (_range == StepsRange.day) {
      // One day has no average or best day of its own.
      return Row(
        children: [
          tile(thousands(s.today), 'steps today'),
          const SizedBox(width: 10),
          tile(thousands(s.average(StepsRange.week)), 'daily average, 7 days'),
        ],
      );
    }
    return Row(
      children: [
        tile(thousands(average), 'daily average'),
        const SizedBox(width: 10),
        tile(best == null ? '—' : thousands(best.steps), bestLabel),
      ],
    );
  }
}

/// Today's ring, the count under it, when it was read, and a line if it is
/// empty.
class _Hero extends StatelessWidget {
  const _Hero({required this.summary});

  final StepsSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Column(
      children: [
        Semantics(
          label: s.none
              ? 'No steps yet today. Goal ${thousands(s.goal)}'
              : '${thousands(s.today)} of ${thousands(s.goal)} steps today',
          child: ExcludeSemantics(
            child: StepRing(
              progress: s.progress,
              size: 170,
              stroke: 14,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(thousands(s.today), style: context.type.score),
                  Text(
                    s.reached
                        ? 'Goal reached'
                        : 'of ${thousands(s.goal)} steps',
                    style: context.type.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.none ? 'No steps yet today' : 'Updated ${Fmt.time(s.asOf)}',
          style: context.type.caption,
        ),
      ],
    );
  }
}

class _ScreenSkeleton extends StatelessWidget {
  const _ScreenSkeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading your steps',
    child: Center(child: StepRing(progress: 0, size: 170, stroke: 14)),
  );
}

class _ScreenMessage extends StatelessWidget {
  const _ScreenMessage({
    required this.title,
    required this.line,
    this.button,
    this.onPressed,
  });

  final String title;
  final String line;
  final String? button;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: context.type.title)),
        const SizedBox(height: 8),
        Text(line, style: context.type.secondary.copyWith(height: 1.45)),
        if (button != null) ...[
          const SizedBox(height: 18),
          KitButton(label: button!, onPressed: onPressed),
        ],
      ],
    ),
  );
}

/// A bottom sheet to pick the daily goal: 1,000 to 50,000 in steps of 500.
Future<void> showStepGoalSheet(
  BuildContext context,
  WidgetRef ref,
  int current,
) => showKitSheet<void>(context, builder: (_) => _GoalSheet(initial: current));

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({required this.initial});

  final int initial;

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  late int _goal = clampStepGoal(widget.initial);

  void _nudge(int by) =>
      setState(() => _goal = clampStepGoal(_goal + by * stepGoalStep));

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    Widget button(String label, String icon, VoidCallback? onTap) => Pressable(
      semanticLabel: label,
      onPressed: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: c.borderControl, width: 1.5),
        ),
        alignment: Alignment.center,
        child: OgIcon(icon, size: 22, color: c.text, strokeWidth: 2),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Daily goal', style: context.type.section),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            button(
              'Lower goal',
              OgIcons.minus,
              _goal > minStepGoal ? () => _nudge(-1) : null,
            ),
            const SizedBox(width: 24),
            Column(
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(thousands(_goal), style: context.type.score),
                ),
                Text('steps a day', style: context.type.caption),
              ],
            ),
            const SizedBox(width: 24),
            button(
              'Raise goal',
              OgIcons.plus,
              _goal < maxStepGoal ? () => _nudge(1) : null,
            ),
          ],
        ),
        const SizedBox(height: 24),
        KitButton(
          label: 'Save goal',
          onPressed: () async {
            final nav = Navigator.of(context);
            await ref.read(stepGoalProvider.notifier).set(_goal);
            if (nav.mounted) nav.pop();
          },
        ),
      ],
    );
  }
}
