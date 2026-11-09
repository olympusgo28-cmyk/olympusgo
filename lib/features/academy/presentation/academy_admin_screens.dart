import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:og_money/og_money.dart';

import '../../../core/format.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/cupertino_sheets.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../../play/domain/activity.dart' show money;
import '../application/academy_providers.dart';
import '../domain/academy_models.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Adds a weekly class, or edits one: name, level, days and time, fee,
/// size and coach.
class AcademyClassEditScreen extends ConsumerStatefulWidget {
  const AcademyClassEditScreen({
    super.key,
    required this.academyId,
    this.classId,
  });

  final String academyId;

  /// Null for a new class.
  final String? classId;

  @override
  ConsumerState<AcademyClassEditScreen> createState() =>
      _AcademyClassEditScreenState();
}

class _AcademyClassEditScreenState
    extends ConsumerState<AcademyClassEditScreen> {
  final _name = TextEditingController();
  final _levelName = TextEditingController();
  final _ages = TextEditingController();
  final _fee = TextEditingController();
  final _trial = TextEditingController();
  final _dropIn = TextEditingController();
  final _capacity = TextEditingController(text: '12');
  final _court = TextEditingController();
  int _level = 1;
  final _weekdays = <int>{DateTime.saturday};
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  int _minutes = 90;
  String _coachId = '';
  bool _loaded = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _levelName,
      _ages,
      _fee,
      _trial,
      _dropIn,
      _capacity,
      _court,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Academy a) {
    if (_loaded) return;
    _loaded = true;
    final x = a.classes.where((c) => c.id == widget.classId).firstOrNull;
    if (x == null) {
      // A coach needs a verified licence before they get a class.
      _coachId = a.coaches.where((k) => k.head && k.nroc).firstOrNull?.id ?? '';
      return;
    }
    _name.text = x.name;
    _levelName.text = x.levelName;
    _ages.text = x.ages;
    _fee.text = x.feeCents == 0 ? '' : (x.feeCents / 100).toStringAsFixed(0);
    _trial.text = x.trialPriceCents == null ? '' : money(x.trialPriceCents!);
    _dropIn.text = x.dropinPriceCents == null ? '' : money(x.dropinPriceCents!);
    _capacity.text = '${x.capacity}';
    _court.text = x.court;
    _level = x.level;
    _weekdays
      ..clear()
      ..addAll(x.weekdays);
    _time = TimeOfDay(hour: x.hour, minute: x.minute);
    _minutes = x.minutes;
    _coachId = x.coachId;
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );
    final picked = await showOgPickerSheet<DateTime>(
      context: context,
      title: 'Start time',
      initial: start,
      picker: (onChanged) => CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: start,
        minuteInterval: 15,
        onDateTimeChanged: onChanged,
      ),
    );
    if (picked != null) {
      setState(
        () => _time = TimeOfDay(hour: picked.hour, minute: picked.minute),
      );
    }
  }

  Future<void> _save() async {
    final capacity = int.tryParse(_capacity.text.trim()) ?? 0;
    if (_name.text.trim().length < 2) {
      showOgToast(context, 'Give the class a name.', error: true);
      return;
    }
    if (_weekdays.isEmpty) {
      showOgToast(context, 'Pick at least one day.', error: true);
      return;
    }
    if (capacity < 1) {
      showOgToast(context, 'Say how many students fit.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(academyRepositoryProvider)
          .saveClass(
            widget.academyId,
            AcademyClass(
              id: widget.classId ?? '',
              academyId: widget.academyId,
              name: _name.text.trim(),
              level: _level,
              levelName: _levelName.text.trim(),
              weekdays: _weekdays.toList()..sort(),
              hour: _time.hour,
              minute: _time.minute,
              minutes: _minutes,
              ages: _ages.text.trim(),
              feeCents: ((double.tryParse(_fee.text.trim()) ?? 0) * 100)
                  .round(),
              capacity: capacity,
              coach: '',
              coachId: _coachId,
              court: _court.text.trim(),
              trialPriceCents: parseMinor(_trial.text.trim()),
              dropinPriceCents: parseMinor(_dropIn.text.trim()),
            ),
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(academyProvider(widget.academyId));
      ref.invalidate(academyListProvider);
      if (!mounted) return;
      showOgToast(
        context,
        widget.classId == null ? 'Class added' : 'Class saved',
      );
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.classId == null ? 'Add a class' : 'Edit class';
    final a = ref.watch(academyProvider(widget.academyId)).value;
    if (a == null) {
      return KitScaffold(
        header: KitHeader(title: title),
        children: const [CupertinoActivityIndicator()],
      );
    }
    _load(a);
    return KitScaffold(
      header: KitHeader(title: title, subtitle: a.name),
      bottom: [
        KitButton(
          label: widget.classId == null ? 'Add class' : 'Save class',
          loading: _busy,
          onPressed: _save,
        ),
      ],
      children: [
        KitInput(
          label: 'Class name',
          hint: 'Juniors Level 1',
          controller: _name,
          maxLength: 60,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Level', style: context.type.body),
            const SizedBox(height: 8),
            KitSegments(
              labels: const ['1', '2', '3', '4', '5'],
              selected: _level - 1,
              onSelect: (i) => setState(() => _level = i + 1),
            ),
          ],
        ),
        KitInput(
          label: 'Level name',
          hint: 'First Rallies',
          controller: _levelName,
          maxLength: 40,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Days', style: context.type.body),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var d = 1; d <= 7; d++)
                  KitChip(
                    label: _days[d - 1],
                    selected: _weekdays.contains(d),
                    onTap: () => setState(() {
                      if (!_weekdays.remove(d)) _weekdays.add(d);
                    }),
                  ),
              ],
            ),
          ],
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.clock,
              title: 'Starts at',
              subtitle: Fmt.clock(_time.hour, _time.minute),
              onTap: _pickTime,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Length', style: context.type.body),
            const SizedBox(height: 8),
            KitSegments(
              labels: const ['45 min', '60 min', '90 min', '2 hr'],
              selected: const [45, 60, 90, 120].indexOf(_minutes).clamp(0, 3),
              onSelect: (i) =>
                  setState(() => _minutes = const [45, 60, 90, 120][i]),
            ),
          ],
        ),
        KitInput(
          label: 'Ages',
          hint: 'ages 6 to 9, or adults',
          controller: _ages,
          maxLength: 40,
        ),
        Row(
          children: [
            Expanded(
              child: KitInput(
                label: 'Fee (S\$ per ${a.billing.unit})',
                controller: _fee,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KitInput(
                label: 'Students',
                controller: _capacity,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: KitInput(
                label: 'Trial (S\$, optional)',
                controller: _trial,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KitInput(
                label: 'Single class (S\$, optional)',
                controller: _dropIn,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
        KitInput(
          label: 'Court',
          hint: 'Court 3',
          controller: _court,
          maxLength: 40,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Coach', style: context.type.body),
            KitChoiceRow(
              title: 'No coach yet',
              subtitle: 'Parents can’t book until there’s a coach',
              selected: _coachId.isEmpty,
              onTap: () => setState(() => _coachId = ''),
            ),
            for (final k in a.coaches)
              KitChoiceRow(
                title: k.name,
                subtitle:
                    '${k.head ? 'Head coach' : k.role}'
                    '${k.nroc ? '' : ' · licence not verified yet'}',
                selected: _coachId == k.id,
                onTap: () => setState(() => _coachId = k.id),
              ),
          ],
        ),
        Text(
          'Monthly and term fees are paid to the academy directly, and show on '
          'the academy page so parents know what to expect. Trials and single '
          'classes are paid in the app. Leave them blank if you don’t offer '
          'them. The platform fee is added on top for the parent.',
          style: context.type.caption.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

/// The academy's coaches: add one by username, or remove them.
class AcademyCoachesScreen extends ConsumerStatefulWidget {
  const AcademyCoachesScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AcademyCoachesScreen> createState() =>
      _AcademyCoachesScreenState();
}

class _AcademyCoachesScreenState extends ConsumerState<AcademyCoachesScreen> {
  final _username = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _set(String username, bool add) async {
    if (username.trim().isEmpty) {
      showOgToast(context, 'Type their username.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(academyRepositoryProvider)
          .setCoach(widget.id, username.trim(), add: add);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ref.invalidate(academyProvider(widget.id));
      if (add) _username.clear();
      showOgToast(context, add ? 'Invitation sent' : 'Coach removed');
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(academyProvider(widget.id)).value;
    if (a == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Coaches'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final head = a.myRole == AcademyRole.headCoach;
    return KitScaffold(
      header: KitHeader(title: 'Coaches', subtitle: a.name),
      children: [
        KitCard(
          children: [
            for (final k in a.coaches)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    SolidAvatar.forId(
                      k.id.isEmpty ? k.name : k.id,
                      initials: k.initials,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.name, style: context.type.body),
                          Text(
                            k.head ? 'Head coach' : k.role,
                            style: context.type.caption,
                          ),
                        ],
                      ),
                    ),
                    if (head && !k.head)
                      KitLink(
                        'Remove',
                        onPressed: _busy ? null : () => _confirmRemove(k),
                      ),
                  ],
                ),
              ),
          ],
        ),
        if (a.invitedCoaches.isNotEmpty || a.pendingCoaches.isNotEmpty) ...[
          Text('Invited', style: context.type.section),
          for (final e in a.invitedCoaches)
            Text(
              '$e · can join once they have an account',
              style: context.type.secondary,
            ),
          for (final k in a.pendingCoaches)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${k.name} · hasn’t answered yet',
                    style: context.type.secondary,
                  ),
                ),
                if (head)
                  KitLink(
                    'Withdraw',
                    onPressed: _busy ? null : () => _set(k.id, false),
                  ),
              ],
            ),
        ],
        if (head) ...[
          Text('Add a coach', style: context.type.section),
          KitInput(
            label: 'Their OlympusGO username',
            hint: '@coachravi',
            controller: _username,
          ),
          KitButton(
            label: 'Add coach',
            loading: _busy,
            onPressed: () => _set(_username.text, true),
          ),
          Text(
            'Coaches can take attendance, write notes to parents and edit '
            'lesson plans. Only you can add classes and change settings.',
            style: context.type.caption.copyWith(height: 1.45),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRemove(AcademyCoach k) async {
    final ok = await showKitSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Remove ${k.name}?', style: context.type.section),
          const SizedBox(height: 8),
          Text(
            'Their classes are left without a coach until you pick a new one.',
            style: context.type.body.copyWith(
              color: sheet.og.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          KitButton(
            label: 'Remove coach',
            style: KitButtonStyle.danger,
            onPressed: () => Navigator.pop(sheet, true),
          ),
          const SizedBox(height: 8),
          KitButton(
            label: 'Keep',
            style: KitButtonStyle.outline,
            onPressed: () => Navigator.pop(sheet, false),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _set(k.id, false);
    }
  }
}

/// Billing and make-ups, for the head coach.
Future<void> showAcademyBilling(
  BuildContext context,
  WidgetRef ref,
  Academy a,
) async {
  var billing = a.billing;
  var makeups = a.makeupsPerMonth;
  final saved = await showKitSheet<bool>(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, set) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Billing and make-ups', style: context.type.section),
          const SizedBox(height: 12),
          for (final b in Billing.values)
            KitChoiceRow(
              title: b.label,
              selected: billing == b,
              onTap: () => set(() => billing = b),
            ),
          const SizedBox(height: 12),
          Text('Make-up classes each month', style: context.type.body),
          const SizedBox(height: 8),
          KitSegments(
            labels: const ['0', '1', '2', '3', '4'],
            selected: makeups.clamp(0, 4),
            onSelect: (i) => set(() => makeups = i),
          ),
          const SizedBox(height: 10),
          Text(
            'Parents pay the academy directly for now. This is what the '
            'academy page tells them.',
            style: context.type.caption.copyWith(
              color: sheet.og.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          KitButton(label: 'Save', onPressed: () => Navigator.pop(sheet, true)),
        ],
      ),
    ),
  );
  if (saved != true || !context.mounted) return;
  try {
    await ref
        .read(academyRepositoryProvider)
        .updateAcademy(a.id, billing: billing, makeups: makeups);
    ref.invalidate(academyProvider(a.id));
    if (context.mounted) showOgToast(context, 'Saved');
  } on AuthFailure catch (e) {
    if (context.mounted) showOgToast(context, e.message, error: true);
  }
}
