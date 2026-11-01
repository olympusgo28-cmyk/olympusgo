import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ReorderableListView;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/fitness_providers.dart';
import '../domain/fitness_calc.dart';
import '../domain/fitness_models.dart';
import 'fitness_screens.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(workoutProgramsProvider);
    final blocked = fitnessWaiting(
      v,
      'My programs',
      () => ref.invalidate(workoutProgramsProvider),
    );
    if (blocked != null) return blocked;
    final mine = v.requireValue.where((p) => !p.template).toList();
    return KitScaffold(
      header: const KitHeader(title: 'My programs'),
      bottom: [
        KitButton(
          label: 'New program',
          onPressed: () => context.push(Routes.fitnessProgram('new')),
        ),
      ],
      children: [
        if (mine.isEmpty)
          Text(
            'No programs yet. Build your own or start from a template.',
            style: OgText.body(14, height: 1.4, color: context.og.textMuted),
          ),
        for (final p in mine)
          KitNavTile(
            icon: OgIcons.clipboardList,
            title: p.name,
            subtitle: plural(p.days.length, 'day'),
            padding: EdgeInsets.zero,
            minHeight: 68,
            onTap: () => context.push(Routes.fitnessProgram(p.id)),
          ),
      ],
    );
  }
}

/// Builds or edits a program. A new one can start from a template.
class ProgramBuilderScreen extends ConsumerStatefulWidget {
  const ProgramBuilderScreen({super.key, required this.id});

  /// `new`, or the id of the player's program.
  final String id;

  @override
  ConsumerState<ProgramBuilderScreen> createState() =>
      _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends ConsumerState<ProgramBuilderScreen> {
  final _name = TextEditingController();
  late String _id;
  var _loaded = false;
  var _isNew = true;
  var _count = 3;
  var _day = 0;
  var _busy = false;
  // Holds seven days, so lowering the count and raising it again loses nothing.
  var _days = List<ProgramDay>.generate(7, (i) => const ProgramDay());

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _load(WorkoutProgram p, {required bool copy}) {
    _name.text = p.name;
    _isNew = copy;
    if (!copy) _id = p.id;
    _count = p.days.length.clamp(1, 7);
    _day = 0;
    _days = [
      ...p.days,
      for (var i = p.days.length; i < 7; i++) const ProgramDay(),
    ];
  }

  void _setItems(List<ProgramItem> items) => setState(() {
    final d = _days[_day];
    _days = [..._days]..[_day] = ProgramDay(name: d.name, items: items);
  });

  Future<void> _add() async {
    final e = await context.push<CatalogExercise>(Routes.fitnessExercisePick);
    if (e == null || !mounted) return;
    _setItems([..._days[_day].items, ProgramItem.of(e)]);
  }

  Future<void> _edit(int index) async {
    final items = _days[_day].items;
    final changed = await showKitSheet<ProgramItem?>(
      context,
      builder: (_) => _ItemSheet(items[index]),
    );
    if (changed == null || !mounted) return;
    _setItems([...items]..[index] = changed);
  }

  void _remove(int index) => _setItems([..._days[_day].items]..removeAt(index));

  WorkoutProgram _program() => WorkoutProgram(
    id: _id,
    name: _name.text.trim(),
    days: _days.take(_count).toList(),
  );

  Future<bool> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(fitnessRepositoryProvider).saveProgram(_program());
      ref.invalidate(workoutProgramsProvider);
      _isNew = false;
      return true;
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startDay() async {
    if (!await _save() || !mounted) return;
    final d = _days[_day];
    final started = await ref
        .read(activeSessionProvider.notifier)
        .start(
          name: d.name.isEmpty ? _name.text.trim() : d.name,
          plan: d.items,
          programId: _id,
        );
    if (!mounted) return;
    if (!started) showOgToast(context, 'You have a workout in progress.');
    context.pushReplacement(Routes.fitnessTrain);
  }

  Future<void> _delete() async {
    final yes = await showKitSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KitTitle(
            'Delete this program?',
            lead: 'Workouts you’ve done stay in your log.',
          ),
          const SizedBox(height: 18),
          KitButton(
            label: 'Delete program',
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
      await ref.read(fitnessRepositoryProvider).deleteProgram(_id);
      ref.invalidate(workoutProgramsProvider);
      if (mounted) context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(workoutProgramsProvider);
    final blocked = fitnessWaiting(
      v,
      'My program',
      () => ref.invalidate(workoutProgramsProvider),
    );
    if (blocked != null) return blocked;
    final all = v.requireValue;
    if (!_loaded) {
      _loaded = true;
      _id = newFitnessId();
      final found = all.where((p) => p.id == widget.id).firstOrNull;
      if (found != null) _load(found, copy: false);
    }
    final templates = all.where((p) => p.template).toList();
    final items = _days[_day].items;
    return KitScaffold(
      header: KitHeader(
        title: 'My program',
        trailing: _isNew
            ? null
            : KitIconButton(
                icon: OgIcons.trash,
                label: 'Delete program',
                onPressed: _delete,
              ),
      ),
      bottom: [
        KitButton(
          label: 'Save program',
          loading: _busy,
          onPressed: () async {
            if (await _save() && context.mounted) context.pop();
          },
        ),
        KitButton(
          label: 'Start this day now',
          style: KitButtonStyle.outline,
          onPressed: items.isEmpty ? null : _startDay,
        ),
      ],
      children: [
        KitInput(label: 'Program name', controller: _name, maxLength: 60),
        const KitSection('Days a week'),
        Wrap(
          spacing: 8,
          children: [
            for (var n = 1; n <= 5; n++)
              KitChip(
                label: '$n',
                height: 44,
                selected: n == _count,
                onTap: () => setState(() {
                  _count = n;
                  if (_day >= n) _day = n - 1;
                }),
              ),
          ],
        ),
        if (_count > 1)
          KitUnderlineTabs(
            labels: [for (var i = 1; i <= _count; i++) 'Day $i'],
            selected: _day,
            padding: EdgeInsets.zero,
            onSelect: (i) => setState(() => _day = i),
          ),
        KitSection(
          _days[_day].name.isEmpty
              ? 'Day ${_day + 1}'
              : 'Day ${_day + 1} · ${_days[_day].name}',
        ),
        if (items.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            onReorderItem: (from, to) {
              final list = [...items];
              list.insert(to, list.removeAt(from));
              _setItems(list);
            },
            itemBuilder: (context, i) => ExerciseRow(
              key: ValueKey('${items[i].exerciseId}-$i'),
              mark: items[i].mark,
              title: items[i].exercise,
              line: itemLine(items[i]),
              trailing: KitIconButton(
                icon: OgIcons.close,
                label: 'Remove ${items[i].exercise}',
                onPressed: () => _remove(i),
              ),
              onTap: () => _edit(i),
            ),
          ),
        KitButton(
          label: 'Add an exercise',
          style: KitButtonStyle.outline,
          onPressed: _add,
        ),
        if (_isNew && templates.isNotEmpty) ...[
          const KitSection('Start from a template'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in templates)
                KitChip(
                  label: t.name,
                  height: 44,
                  onTap: () => setState(() => _load(t, copy: true)),
                ),
            ],
          ),
        ],
        const KitNote(
          'Hold and drag an exercise to reorder it. Tap one to change sets, '
          'reps, weight and rest.',
        ),
      ],
    );
  }
}

/// Changes one item's sets, reps or time, weight and rest.
class _ItemSheet extends StatefulWidget {
  const _ItemSheet(this.item);

  final ProgramItem item;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final _sets = TextEditingController(text: '${widget.item.sets}');
  late final _amount = TextEditingController(
    text: '${widget.item.timed ? widget.item.seconds : widget.item.reps}',
  );
  late final _weight = TextEditingController(
    text: widget.item.weightG == null ? '' : kgText(widget.item.weightG!),
  );
  late final _rest = TextEditingController(text: '${widget.item.restSeconds}');
  String? _error;

  @override
  void dispose() {
    _sets.dispose();
    _amount.dispose();
    _weight.dispose();
    _rest.dispose();
    super.dispose();
  }

  void _done() {
    final i = widget.item;
    final sets = int.tryParse(_sets.text.trim());
    final amount = int.tryParse(_amount.text.trim());
    final rest = int.tryParse(_rest.text.trim());
    final text = _weight.text.trim();
    final weight = text.isEmpty ? null : gramsFrom(text);
    if (sets == null ||
        sets < 1 ||
        sets > 20 ||
        amount == null ||
        amount < 1 ||
        amount > (i.timed ? 3600 : 200) ||
        rest == null ||
        rest < 0 ||
        rest > 900 ||
        (text.isNotEmpty && (weight == null || weight > 500000))) {
      setState(() => _error = 'Check the sets, reps, weight and rest.');
      return;
    }
    Navigator.of(context).pop(
      i.change(
        sets: sets,
        reps: i.timed ? null : amount,
        seconds: i.timed ? amount : null,
        weightG: weight,
        noWeight: weight == null,
        restSeconds: rest,
      ),
    );
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
            KitInput(
              label: 'Sets',
              controller: _sets,
              keyboardType: TextInputType.number,
            ),
            KitInput(
              label: i.timed ? 'Seconds' : 'Reps',
              controller: _amount,
              keyboardType: TextInputType.number,
            ),
            if (i.weighted)
              KitInput(
                label: 'Weight, kg',
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            KitInput(
              label: 'Rest, seconds',
              controller: _rest,
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
