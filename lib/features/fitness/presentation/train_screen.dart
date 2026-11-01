import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/fitness_providers.dart';
import '../domain/fitness_calc.dart';
import '../domain/fitness_models.dart';

/// The set in progress and the rest timer. Each finished set goes to the
/// phone's storage straight away.
class TrainScreen extends ConsumerStatefulWidget {
  const TrainScreen({super.key});

  @override
  ConsumerState<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends ConsumerState<TrainScreen> {
  Timer? _timer;
  DateTime? _restUntil;
  var _resting = 0;
  var _saving = false;
  var _logging = false;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _rest(int seconds) {
    _timer?.cancel();
    if (seconds <= 0) {
      setState(() => _resting = 0);
      return;
    }
    // Counted from the clock, so a paused app still rests the right time.
    _restUntil = DateTime.now().add(Duration(seconds: seconds));
    setState(() => _resting = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = _restUntil!.difference(DateTime.now()).inSeconds + 1;
      if (left <= 0) {
        t.cancel();
        HapticFeedback.mediumImpact();
        setState(() => _resting = 0);
      } else {
        setState(() => _resting = left);
      }
    });
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() => _resting = 0);
  }

  Future<void> _setDone(ProgramItem item) async {
    if (_logging || _saving) return;
    _logging = true;
    try {
      await ref
          .read(activeSessionProvider.notifier)
          .log(
            LoggedSet(
              exerciseId: item.exerciseId,
              reps: item.timed ? null : item.reps,
              seconds: item.timed ? item.seconds : null,
              weightG: item.weighted ? item.weightG : null,
            ),
          );
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn’t log that set. Try again.');
      return;
    } finally {
      _logging = false;
    }
    if (!mounted || _saving) return;
    final after = ref.read(activeSessionProvider).value;
    setState(() => _error = null);
    _rest(after == null || after.complete ? 0 : item.restSeconds);
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
    _timer?.cancel();
    setState(() {
      _saving = true;
      _resting = 0;
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
    _timer?.cancel();
    await ref.read(activeSessionProvider.notifier).discard();
    if (mounted) context.pop();
  }

  Widget _tile(String value, String label) {
    final c = context.og;
    return Expanded(
      child: MergeSemantics(
        child: Column(
          children: [
            Text(value, style: OgText.heading(34, color: c.text)),
            Text(label, style: OgText.body(13, color: c.textMuted)),
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
        if (item != null && _resting == 0 && !_saving)
          KitButton(label: 'Set done', onPressed: () => _setDone(item)),
        if (_resting > 0) KitButton(label: 'Skip rest', onPressed: _skipRest),
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
        ] else ...[
          Text(
            'EXERCISE ${w.item + 1} OF ${w.plan.length} · '
            'SET ${setsDoneHere + 1} OF ${item.sets}',
            style: OgText.body(13, weight: FontWeight.w700, color: c.textMuted),
          ),
          Text(item.exercise, style: OgText.heading(34, color: c.text)),
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
          if (_resting > 0)
            Semantics(
              label: 'Rest, $_resting seconds left',
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
                        style: OgText.body(
                          13,
                          weight: FontWeight.w700,
                          color: c.highlight,
                        ),
                      ),
                      Text(
                        clockText(_resting),
                        style: OgText.heading(54, color: c.onInverseCard),
                      ),
                      Text(
                        'Next: set ${setsDoneHere + 1} of ${item.sets}',
                        style: OgText.body(14, color: c.onInverseCardMuted),
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
                  Expanded(
                    child: Text(
                      'Set $s',
                      style: OgText.body(15, color: c.text),
                    ),
                  ),
                  Text(
                    s <= setsDoneHere
                        ? 'Done'
                        : (s == setsDoneHere + 1 ? 'Now' : 'Next'),
                    style: OgText.body(13, color: c.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ],
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
    final weight = text.isEmpty ? null : gramsFrom(text);
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null ||
        amount < 1 ||
        amount > (i.timed ? 3600 : 200) ||
        (text.isNotEmpty && (weight == null || weight > 500000))) {
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
