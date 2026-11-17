import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/fitness_providers.dart';
import '../domain/fitness_calc.dart';
import '../domain/fitness_models.dart';
import '../domain/progression.dart';
import '../domain/workout_progress.dart';

/// The set in progress and the rest timer. Each finished set goes to the
/// phone's storage straight away.
class TrainScreen extends ConsumerStatefulWidget {
  const TrainScreen({super.key});

  @override
  ConsumerState<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends ConsumerState<TrainScreen> {
  Timer? _timer;
  var _wasResting = false;
  var _saving = false;
  var _logging = false;
  String? _error;

  /// The exercises whose weight is on its way from last time, so it is asked
  /// for once. The workout itself remembers that it was set.
  final _prefilling = <int>{};

  @override
  void initState() {
    super.initState();
    // The rest's end is kept with the workout, so this only redraws the
    // countdown: leaving and coming back shows the time really left.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _left(ActiveWorkout? w) =>
      w == null || _saving ? 0 : w.restLeft(DateTime.now());

  void _tick() {
    if (!mounted) return;
    final w = ref.read(activeSessionProvider).value;
    final resting = _left(w) > 0;
    // A buzz only when a rest ran out by itself. A skipped rest has no end
    // time any more, and a discarded or finished workout isn't resting.
    final ranOut = w != null && !w.finished && !_saving && w.restUntil != null;
    if (_wasResting && !resting && ranOut) HapticFeedback.mediumImpact();
    if (resting || _wasResting) setState(() {});
    _wasResting = resting;
  }

  void _skipRest() => ref.read(activeSessionProvider.notifier).skipRest();

  void _addRest() =>
      ref.read(activeSessionProvider.notifier).addRest(restAddSeconds);

  /// Starts a weighted exercise at last time's weight when the program plans
  /// none. Once per exercise, before its first set.
  void _prefill(ActiveWorkout w, ExerciseHistory? history) {
    final item = w.current;
    if (item == null || history == null || w.finished) return;
    if (!item.weighted || item.weightG != null || w.setsDone > 0) return;
    // Set already in this workout, by the player or from last time: a weight
    // they cleared stays cleared.
    if (w.weightSet.contains(w.item)) return;
    final weight = lastWeightG(history);
    if (weight == null || !_prefilling.add(w.item)) return;
    final index = w.item;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The session checks again when its turn comes, so a weight typed or
      // a set logged in the meantime is never overwritten.
      ref.read(activeSessionProvider.notifier).prefillWeight(index, weight);
    });
  }

  Future<void> _setDone() async {
    if (_logging || _saving) return;
    _logging = true;
    try {
      // Logged from the workout as it stands when its turn comes, not from
      // what this screen last drew.
      await ref.read(activeSessionProvider.notifier).logCurrent();
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn’t log that set. Try again.');
      return;
    } finally {
      _logging = false;
    }
    if (!mounted || _saving) return;
    _wasResting = _left(ref.read(activeSessionProvider).value) > 0;
    setState(() => _error = null);
  }

  Future<void> _change(int index, ProgramItem item) async {
    final session = ref.read(activeSessionProvider.notifier);
    final changed = await showKitSheet<({int? weightG, int amount})>(
      context,
      builder: (_) => _SetSheet(
        item: item,
        weightG: item.weightG,
        amount: (item.timed ? item.seconds : item.reps)!,
      ),
    );
    if (changed == null) return;
    await session.adjust(
      index,
      item.change(
        reps: item.timed ? null : changed.amount,
        seconds: item.timed ? changed.amount : null,
        weightG: changed.weightG,
        noWeight: changed.weightG == null,
      ),
    );
  }

  Future<void> _finish() async {
    _wasResting = false;
    setState(() {
      _saving = true;
      _error = null;
    });
    final session = ref.read(activeSessionProvider.notifier);
    try {
      await session.finish();
      if (!mounted) return;
      showOgToast(context, 'Workout saved');
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn’t save that. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _discard() async {
    final yes = await showKitSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KitTitle(
            'Discard this workout?',
            lead: 'The sets you’ve done won’t be saved.',
          ),
          const SizedBox(height: 18),
          KitButton(
            label: 'Discard workout',
            style: KitButtonStyle.danger,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          const SizedBox(height: 10),
          KitButton(
            label: 'Keep going',
            style: KitButtonStyle.outline,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
    if (yes != true) return;
    await ref.read(activeSessionProvider.notifier).discard();
    if (mounted) context.pop();
  }

  Widget _tile(String value, String label) {
    return Expanded(
      child: MergeSemantics(
        child: Column(
          children: [
            Text(value, style: context.type.score),
            Text(label, style: context.type.caption),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final v = ref.watch(activeSessionProvider);
    final w = v.value;
    if (w == null) {
      return KitScaffold(
        header: const KitHeader(title: 'Workout'),
        children: [
          if (v.isLoading)
            const CupertinoActivityIndicator()
          else
            const KitNote('No workout in progress.'),
        ],
      );
    }
    final item = w.finished ? null : w.current;
    final setsDoneHere = w.setsDone;
    final resting = item == null ? 0 : _left(w);
    // Read for every exercise done or under way: "last time" needs the
    // current one, and a new best needs each one's saved best.
    final histories = <String, AsyncValue<ExerciseHistory>>{
      for (final id in {
        ...w.done.map((s) => s.exerciseId),
        if (item != null) item.exerciseId,
      })
        id: ref.watch(exerciseHistoryProvider(id)),
    };
    final known = <String, ExerciseHistory>{
      for (final e in histories.entries)
        if (e.value.hasValue) e.key: e.value.requireValue,
    };
    final here = item == null ? null : histories[item.exerciseId];
    _prefill(w, here?.value);
    // A suggestion only before the exercise's first set, and only from a
    // history that was read. Under-18s get none: the server sends no numbers.
    // A history that failed to refresh may still hold an old value: like
    // "last time", the suggestion is left out then.
    final hereValue = here == null || here.hasError ? null : here.value;
    final suggestion = item != null && setsDoneHere == 0 && hereValue != null
        ? suggestNext(item, hereValue)
        : null;
    final bests = newBests(w.done, known);
    String nameOf(String id) =>
        w.plan.where((i) => i.exerciseId == id).firstOrNull?.exercise ?? '';
    final justSet =
        w.done.isNotEmpty &&
            isNewBest(w.done, w.done.length - 1, known[w.done.last.exerciseId])
        ? w.done.last
        : null;
    return KitScaffold(
      header: KitHeader(
        title: w.name,
        trailing: KitIconButton(
          icon: OgIcons.trash,
          label: 'Discard workout',
          onPressed: _discard,
        ),
      ),
      bottom: [
        if (_error != null) KitNote(_error!, tone: KitTone.warn),
        if (item != null && resting == 0 && !_saving)
          KitButton(label: 'Set done', onPressed: _setDone),
        if (resting > 0) ...[
          KitButton(label: 'Skip rest', onPressed: _skipRest),
          KitButton(
            label: 'Add $restAddSeconds seconds',
            style: KitButtonStyle.outline,
            onPressed: _addRest,
          ),
        ],
        if (w.done.isNotEmpty)
          KitButton(
            label: w.finished ? 'Try saving again' : 'Finish workout',
            style: item == null
                ? KitButtonStyle.primary
                : KitButtonStyle.outline,
            loading: _saving,
            onPressed: _finish,
          ),
      ],
      children: [
        if (item == null) ...[
          KitTitle(
            w.finished ? 'Not saved yet' : 'All sets done',
            lead: w.finished
                ? 'Your workout is safe on this phone. When you have a '
                      'connection, try saving again.'
                : '${plural(w.done.length, 'set')} logged. Finish to save it.',
          ),
          if (bests.isNotEmpty) ...[
            Text(
              bests.length == 1 ? '1 new best' : '${bests.length} new bests',
              style: context.type.section,
            ),
            for (final b in bests)
              Text(
                '${nameOf(b.exerciseId)}: '
                '${bestText(reps: b.reps, seconds: b.seconds, weightG: b.weightG)}',
                style: context.type.body,
              ),
          ],
        ] else ...[
          Text(
            'EXERCISE ${w.item + 1} OF ${w.plan.length} · '
            'SET ${setsDoneHere + 1} OF ${item.sets}',
            style: context.type.caption,
          ),
          Text(item.exercise, style: context.type.display),
          if (here != null) _LastTime(history: here),
          if (suggestion != null)
            _Suggest(
              suggestion: suggestion,
              onUse: () => ref
                  .read(activeSessionProvider.notifier)
                  .applySuggestion(
                    w.item,
                    from: item,
                    weightG: suggestion.weightG,
                    reps: suggestion.reps,
                    seconds: suggestion.seconds,
                  ),
            ),
          Row(
            children: [
              if (item.weighted)
                _tile(
                  item.weightG == null ? '—' : '${kgText(item.weightG!)} kg',
                  'weight',
                ),
              _tile(
                '${item.timed ? item.seconds : item.reps}',
                item.timed ? 'seconds' : 'reps',
              ),
              _tile(clockText(item.restSeconds), 'rest after'),
            ],
          ),
          KitButton(
            label: 'Change weight or reps',
            style: KitButtonStyle.outline,
            onPressed: () => _change(w.item, item),
          ),
          if (justSet != null)
            Semantics(
              liveRegion: true,
              child: Text(
                'New best: ${nameOf(justSet.exerciseId)}, '
                '${bestText(reps: justSet.reps, seconds: justSet.seconds, weightG: justSet.weightG)}',
                style: context.type.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          if (resting > 0)
            Semantics(
              label: 'Rest, $resting seconds left',
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.inverseCard,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REST',
                        style: context.type.caption.copyWith(
                          color: c.highlight,
                        ),
                      ),
                      Text(
                        clockText(resting),
                        style: context.type.score.copyWith(
                          color: c.onInverseCard,
                        ),
                      ),
                      Text(
                        'Next: set ${setsDoneHere + 1} of ${item.sets}',
                        style: context.type.body.copyWith(
                          color: c.onInverseCardMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          for (var s = 1; s <= item.sets; s++)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: s == setsDoneHere + 1 ? context.tones.soft : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: Text('Set $s', style: context.type.body)),
                  Text(
                    s <= setsDoneHere
                        ? 'Done'
                        : (s == setsDoneHere + 1 ? 'Now' : 'Next'),
                    style: context.type.caption,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// What the player did last time on this exercise. Left out if it can't be
/// read: the workout carries on without it.
class _LastTime extends StatelessWidget {
  const _LastTime({required this.history});

  final AsyncValue<ExerciseHistory> history;

  @override
  Widget build(BuildContext context) {
    if (history.hasError) return const SizedBox.shrink();
    if (!history.hasValue) {
      return Semantics(
        label: 'Loading last time',
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 180,
            height: 13,
            decoration: BoxDecoration(
              color: context.tones.soft,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
    }
    final text = lastTimeText(history.requireValue);
    return Text(
      text == null ? 'First time doing this.' : 'Last time: $text',
      style: context.type.caption,
    );
  }
}

/// A suggested next weight, reps or time, with its reason. "Use" takes it for
/// this workout only. It is a suggestion: nothing changes without the tap.
class _Suggest extends StatelessWidget {
  const _Suggest({required this.suggestion, required this.onUse});

  final Suggestion suggestion;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: context.tones.soft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                suggestion.text,
                style: context.type.caption.copyWith(
                  color: context.og.text,
                  height: 1.4,
                ),
              ),
            ),
            if (suggestion.usable) ...[
              const SizedBox(width: 10),
              KitButton(
                label: 'Use',
                style: KitButtonStyle.outline,
                height: 44,
                expand: false,
                onPressed: onUse,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Changes the weight and reps for the rest of this exercise.
class _SetSheet extends StatefulWidget {
  const _SetSheet({
    required this.item,
    required this.weightG,
    required this.amount,
  });

  final ProgramItem item;
  final int? weightG;
  final int amount;

  @override
  State<_SetSheet> createState() => _SetSheetState();
}

class _SetSheetState extends State<_SetSheet> {
  late final _weight = TextEditingController(
    text: widget.weightG == null ? '' : kgText(widget.weightG!),
  );
  late final _amount = TextEditingController(text: '${widget.amount}');
  String? _error;

  @override
  void dispose() {
    _weight.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _done() {
    final i = widget.item;
    final text = _weight.text.trim();
    // No weight and 0 kg are the same thing: neither is a weight lifted.
    final typed = text.isEmpty ? null : gramsFrom(text);
    final weight = typed == 0 ? null : typed;
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null ||
        amount < 1 ||
        amount > (i.timed ? 3600 : 200) ||
        (text.isNotEmpty && (typed == null || typed > 500000))) {
      setState(() => _error = 'Check the weight and reps.');
      return;
    }
    Navigator.of(context).pop((weightG: weight, amount: amount));
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.item;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...kitSpaced([
            KitTitle(i.exercise),
            if (i.weighted)
              KitInput(
                label: 'Weight, kg',
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            KitInput(
              label: i.timed ? 'Seconds' : 'Reps',
              controller: _amount,
              keyboardType: TextInputType.number,
            ),
            if (_error != null) KitNote(_error!, tone: KitTone.warn),
            KitButton(label: 'Done', onPressed: _done),
          ], 14),
          SizedBox(height: 26 + MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
