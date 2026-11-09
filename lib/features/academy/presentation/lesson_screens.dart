import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_money/og_money.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/cupertino_sheets.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pay_sheet.dart';
import '../../auth/data/auth_repository.dart';
import '../../earnings/application/earnings_providers.dart';
import '../../play/data/payment_gateway.dart' show PaymentHold;
import '../../play/domain/meet_ops.dart' show newClientKey;
import '../../play/presentation/pay_flow.dart';
import '../application/academy_providers.dart';
import '../domain/lesson_models.dart';
import 'academy_screens.dart' show PlayerChoices;

/// Pays for a lesson from start to finish: the server's quote and refund rule,
/// the hold, then the webhook. Returns the booking when one came of it.
Future<String?> payForLesson(
  BuildContext context,
  WidgetRef ref, {
  required LessonKind kind,
  required String lessonRef,
  required DateTime? at,
  required String studentId,
  required String studentName,
  required String academyName,
}) async {
  final lessons = ref.read(lessonRepositoryProvider);
  final gateway = ref.read(paymentGatewayProvider);
  String? bookingId;
  try {
    final q = await lessons.quote(kind, lessonRef, at);
    if (!q.enabled || !gateway.canCollect) {
      if (context.mounted) {
        showOgToast(
          context,
          'Paying in the app isn’t open yet. It opens once payments are '
          'switched on.',
        );
      }
      return null;
    }
    if (!context.mounted) return null;
    final method = await showPaySheet(
      context,
      kicker: kind.label,
      title: q.title,
      subtitle: '${Fmt.dayTimeComma(q.startsAt)} · for $studentName',
      lines: [
        (kind.label, '${Money(q.priceCents)}'),
        ('Platform fee', '${Money(q.feeCents)}'),
      ],
      totalCents: q.totalCents,
      payee: 'OlympusGO',
      notes: [
        q.refundRule,
        'OlympusGO holds your payment until $academyName marks attendance, or '
            '24 hours after the end.',
      ],
    );
    if (method == null || !context.mounted) return null;
    final (hold, id) = await lessons.reserve(
      kind,
      lessonRef,
      at: at,
      studentId: studentId,
      key: newClientKey(),
      expectedCents: q.totalCents,
    );
    bookingId = id;
    if (!context.mounted) return id;
    await finishPayment(
      context,
      gateway,
      hold,
      method,
      paying: PayingFor.lesson,
    );
    // The booking says what happened. Given up means there's nothing to show.
    final b = await lessons.get(id);
    return b.step == LessonStep.cancelled || b.step == LessonStep.expired
        ? null
        : id;
  } on AuthFailure catch (e) {
    if (context.mounted) {
      showOgToast(
        context,
        e.message == 'price_changed'
            ? 'The price changed. Check it and pay again.'
            : e.message,
        error: e.message != 'price_changed',
      );
    }
    return bookingId;
  }
}

Widget? _waiting(AsyncValue<Object?> v, String title, VoidCallback retry) {
  if (v.hasValue) return null;
  return KitScaffold(
    header: KitHeader(title: title),
    children: v.hasError
        ? [
            KitNote(_problem(v.error), tone: KitTone.warn),
            KitButton(label: 'Try again', onPressed: retry),
          ]
        : const [CupertinoActivityIndicator()],
  );
}

String _problem(Object? e) => e is AuthFailure
    ? e.message
    : 'Can’t load this right now. Check your connection.';

Widget _nothing(BuildContext context, String text) =>
    Text(text, style: context.type.secondary.copyWith(height: 1.4));

// ─── Booking a one-to-one ──────────────────────────────────────────────────

class OneToOneScreen extends ConsumerStatefulWidget {
  const OneToOneScreen({super.key, required this.academyId});

  final String academyId;

  @override
  ConsumerState<OneToOneScreen> createState() => _OneToOneScreenState();
}

class _OneToOneScreenState extends ConsumerState<OneToOneScreen> {
  String? _who;
  LessonSlot? _slot;
  bool _busy = false;

  Future<void> _book(EnrolPlayer who) async {
    final s = _slot!;
    final a = ref.read(academyProvider(widget.academyId)).value;
    setState(() => _busy = true);
    final id = await payForLesson(
      context,
      ref,
      kind: LessonKind.oneToOne,
      lessonRef: s.id,
      at: null,
      studentId: who.id,
      studentName: who.name,
      academyName: a?.name ?? 'the academy',
    );
    if (!mounted) return;
    ref.invalidate(openSlotsProvider(widget.academyId));
    ref.invalidate(myLessonsProvider);
    setState(() => _busy = false);
    if (id != null) context.pushReplacement(Routes.lesson(id));
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(openSlotsProvider(widget.academyId));
    final players = ref.watch(myPlayersProvider);
    final blocked = _waiting(slots, 'One-to-one', () {
      ref.invalidate(openSlotsProvider(widget.academyId));
    });
    if (blocked != null) return blocked;
    final list = slots.requireValue;
    final people = players.value ?? const <EnrolPlayer>[];
    final who = people.where((p) => p.id == _who).firstOrNull;
    return KitScaffold(
      header: const KitHeader(title: 'One-to-one'),
      bottom: [
        KitButton(
          label: 'Continue to pay',
          loading: _busy,
          onPressed: _slot == null || who == null ? null : () => _book(who),
        ),
      ],
      children: [
        const KitTitle(
          'Book a coach',
          size: 28,
          lead:
              'One lesson with one coach. Every coach here holds a verified '
              'licence.',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Who is it for?', style: context.type.body),
            PlayerChoices(
              players: players,
              selected: _who,
              onSelect: (id) => setState(() => _who = id),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pick a time', style: context.type.body),
            if (list.isEmpty)
              _nothing(context, 'No lessons are open right now.'),
            for (final s in list)
              KitChoiceRow(
                title: Fmt.dayTimeComma(s.startsAt),
                subtitle: [
                  s.coach,
                  '${s.endsAt.difference(s.startsAt).inMinutes} min',
                  if (s.venue.isNotEmpty) s.venue,
                ].join(' · '),
                tag: '${Money(s.totalCents)}',
                selected: _slot?.id == s.id,
                onTap: () => setState(() => _slot = s),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── My lessons ────────────────────────────────────────────────────────────

class _LessonRow extends StatelessWidget {
  const _LessonRow(this.b, {this.showStudent = false});

  final LessonBooking b;
  final bool showStudent;

  @override
  Widget build(BuildContext context) => KitNavTile(
    icon: OgIcons.calendar,
    title: b.title,
    subtitle: [
      Fmt.dayTimeComma(b.startsAt),
      if (showStudent) b.student else b.academy,
      b.step.label,
    ].join(' · '),
    onTap: () => context.push(Routes.lesson(b.id)),
  );
}

class MyLessonsScreen extends ConsumerWidget {
  const MyLessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(myLessonsProvider);
    final blocked = _waiting(
      lessons,
      'My lessons',
      () => ref.invalidate(myLessonsProvider),
    );
    if (blocked != null) return blocked;
    final list = lessons.requireValue;
    return KitScaffold(
      header: const KitHeader(title: 'My lessons'),
      children: [
        if (list.isEmpty)
          _nothing(
            context,
            'Nothing booked yet. Trials and one-to-ones you book show up here.',
          )
        else
          KitCard(children: [for (final b in list) _LessonRow(b)]),
      ],
    );
  }
}

class LessonDetailScreen extends ConsumerStatefulWidget {
  const LessonDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() act) async {
    setState(() => _busy = true);
    try {
      await act();
      HapticFeedback.mediumImpact();
      if (mounted) _refresh();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refresh() {
    final b = ref.read(lessonBookingProvider(widget.id)).value;
    ref.invalidate(lessonBookingProvider(widget.id));
    ref.invalidate(myLessonsProvider);
    refreshEarnings(ref.invalidate);
    if (b != null) {
      ref.invalidate(academyLessonsProvider(b.academyId));
      ref.invalidate(openSlotsProvider(b.academyId));
      ref.invalidate(mySlotsProvider(b.academyId));
    }
  }

  /// Picks up a payment that didn't finish.
  Future<void> _finish(LessonBooking b) async {
    final gateway = ref.read(paymentGatewayProvider);
    setState(() => _busy = true);
    final method = await showPaySheet(
      context,
      kicker: b.kind.label,
      title: b.title,
      subtitle: '${Fmt.dayTimeComma(b.startsAt)} · for ${b.student}',
      lines: [
        (b.kind.label, '${Money(b.priceCents)}'),
        ('Platform fee', '${Money(b.feeCents)}'),
      ],
      totalCents: b.totalCents,
      payee: 'OlympusGO',
    );
    if (!mounted) return;
    if (method != null) {
      try {
        await finishPayment(
          context,
          gateway,
          PaymentHold(
            result: 'reserved',
            id: b.paymentId,
            totalCents: b.totalCents,
            holdUntil: b.holdUntil,
            serverNow: b.serverNow,
            method: b.paymentMethod,
          ),
          method,
          paying: PayingFor.lesson,
        );
      } on AuthFailure catch (e) {
        if (mounted) showOgToast(context, e.message, error: true);
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _refresh();
  }

  Future<void> _cancel(LessonBooking b) async {
    final inTime =
        b.freeCancelUntil != null &&
        !DateTime.now().isAfter(b.freeCancelUntil!);
    final yes = await _confirm(
      'Cancel this lesson?',
      inTime
          ? 'You get ${Money(b.priceCents)} back to how you paid. The '
                '${Money(b.feeCents)} fee isn’t refunded.'
          : 'It’s less than 24 hours away, so you won’t get anything back.',
    );
    if (yes != true) return;
    await _run(() async {
      await ref
          .read(lessonRepositoryProvider)
          .cancel(b.id, expectedCents: inTime ? b.priceCents : 0);
    });
  }

  Future<bool?> _confirm(String title, String body) =>
      showCupertinoDialog<bool>(
        context: context,
        builder: (d) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Keep it'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

  Future<String?> _ask(String title, String hint) {
    var text = '';
    return showCupertinoDialog<String>(
      context: context,
      builder: (d) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            placeholder: hint,
            maxLength: 200,
            maxLines: 3,
            onChanged: (v) => text = v,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(d),
            child: const Text('Back'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(d, text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _report(LessonBooking b) async {
    final note = await _ask('Report a problem', 'What went wrong?');
    if (note == null || note.isEmpty) return;
    await _run(() => ref.read(lessonRepositoryProvider).report(b.id, note));
  }

  Future<void> _academyCancel(LessonBooking b) async {
    final why = await _ask('Cancel this lesson', 'Why? The parent sees this.');
    if (why == null || why.isEmpty) return;
    await _run(
      () => ref.read(lessonRepositoryProvider).academyCancel(b.id, why),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(lessonBookingProvider(widget.id));
    final blocked = _waiting(
      v,
      'Lesson',
      () => ref.invalidate(lessonBookingProvider(widget.id)),
    );
    if (blocked != null) return blocked;
    final b = v.requireValue;
    final canCancel = b.canPay && b.step == LessonStep.paid && !b.started;
    final canReport =
        b.canPay &&
        b.started &&
        (b.step == LessonStep.paid || b.step == LessonStep.lateCancelled);
    final canMark = b.canTeach && b.step == LessonStep.paid && b.started;
    final canAcademyCancel =
        b.canTeach &&
        (b.step == LessonStep.paid || b.step == LessonStep.lateCancelled);
    return KitScaffold(
      header: const KitHeader(title: 'Lesson'),
      bottom: [
        if (canMark) ...[
          KitButton(
            label: '${b.student} came',
            loading: _busy,
            onPressed: () => _run(
              () => ref
                  .read(lessonRepositoryProvider)
                  .markAttendance(b.id, present: true),
            ),
          ),
          KitButton.outline(
            label: '${b.student} didn’t come',
            onPressed: _busy
                ? null
                : () => _run(
                    () => ref
                        .read(lessonRepositoryProvider)
                        .markAttendance(b.id, present: false),
                  ),
          ),
        ],
        if (b.canPay && b.step == LessonStep.pending) ...[
          KitButton(
            label: 'Finish paying',
            loading: _busy,
            onPressed: () => _finish(b),
          ),
          KitButton.outline(
            label: 'Don’t book this',
            onPressed: _busy
                ? null
                : () => _run(() async {
                    await ref.read(lessonRepositoryProvider).cancel(b.id);
                  }),
          ),
        ],
        if (canCancel)
          KitButton.outline(
            label: 'Cancel lesson',
            loading: _busy,
            onPressed: () => _cancel(b),
          ),
        if (canReport)
          KitButton.outline(
            label: 'Report a problem',
            loading: _busy,
            onPressed: () => _report(b),
          ),
        if (canAcademyCancel)
          KitButton.outline(
            label: 'Cancel this lesson',
            onPressed: _busy ? null : () => _academyCancel(b),
          ),
      ],
      children: [
        KitTitle(
          b.title,
          size: 26,
          lead: '${b.academy} · ${Fmt.dayTimeComma(b.startsAt)}',
        ),
        KitKeyValue('Status', b.step.label),
        KitKeyValue('For', b.student),
        KitKeyValue('Coach', b.coach),
        if (b.attendance != null)
          KitKeyValue(
            'Attendance',
            b.attendance == 'present' ? 'Came' : 'Didn’t come',
          ),
        KitKeyValue(b.charged ? 'Paid' : 'Total', '${Money(b.totalCents)}'),
        if (b.refundedCents > 0)
          KitKeyValue('Refunded', '${Money(b.refundedCents)}'),
        if (b.step == LessonStep.paid &&
            b.canPay &&
            (b.freeCancelUntil?.isAfter(DateTime.now()) ?? false))
          Text(
            'Cancel by ${Fmt.dayTimeComma(b.freeCancelUntil!)} for the price '
            'back, without the fee. After that, no refund.',
            style: context.type.caption.copyWith(height: 1.4),
          ),
      ],
    );
  }
}

// ─── The coach's side ──────────────────────────────────────────────────────

class AcademyLessonsScreen extends ConsumerWidget {
  const AcademyLessonsScreen({super.key, required this.academyId});

  final String academyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(academyLessonsProvider(academyId));
    final blocked = _waiting(
      lessons,
      'Lessons',
      () => ref.invalidate(academyLessonsProvider(academyId)),
    );
    if (blocked != null) return blocked;
    final list = lessons.requireValue;
    return KitScaffold(
      header: const KitHeader(title: 'Lessons'),
      bottom: [
        KitButton(
          label: 'One-to-one times',
          onPressed: () => context.push(Routes.lessonSlots(academyId)),
        ),
      ],
      children: [
        if (list.isEmpty)
          _nothing(context, 'No paid lessons yet.')
        else
          KitCard(
            children: [for (final b in list) _LessonRow(b, showStudent: true)],
          ),
      ],
    );
  }
}

class LessonSlotsScreen extends ConsumerStatefulWidget {
  const LessonSlotsScreen({super.key, required this.academyId});

  final String academyId;

  @override
  ConsumerState<LessonSlotsScreen> createState() => _LessonSlotsScreenState();
}

class _LessonSlotsScreenState extends ConsumerState<LessonSlotsScreen> {
  bool _busy = false;

  Future<void> _withdraw(LessonSlot s) async {
    setState(() => _busy = true);
    try {
      await ref.read(lessonRepositoryProvider).withdrawSlot(s.id);
      if (mounted) ref.invalidate(mySlotsProvider(widget.academyId));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(mySlotsProvider(widget.academyId));
    final blocked = _waiting(
      slots,
      'One-to-one times',
      () => ref.invalidate(mySlotsProvider(widget.academyId)),
    );
    if (blocked != null) return blocked;
    final list = slots.requireValue;
    return KitScaffold(
      header: const KitHeader(title: 'One-to-one times'),
      bottom: [
        KitButton(
          label: 'Add a time',
          onPressed: () => context.push(Routes.lessonSlotNew(widget.academyId)),
        ),
      ],
      children: [
        if (list.isEmpty) _nothing(context, 'You haven’t opened any times.'),
        for (final s in list)
          KitCard(
            padding: const EdgeInsets.all(14),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Fmt.dayTimeComma(s.startsAt),
                          style: context.type.body,
                        ),
                        Text(
                          [
                            '${Money(s.priceCents)}',
                            if (s.venue.isNotEmpty) s.venue,
                            if (s.booked) 'Booked',
                          ].join(' · '),
                          style: context.type.caption,
                        ),
                      ],
                    ),
                  ),
                  if (!s.booked)
                    KitLink(
                      'Remove',
                      onPressed: _busy ? null : () => _withdraw(s),
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class LessonSlotEditScreen extends ConsumerStatefulWidget {
  const LessonSlotEditScreen({super.key, required this.academyId});

  final String academyId;

  @override
  ConsumerState<LessonSlotEditScreen> createState() =>
      _LessonSlotEditScreenState();
}

class _LessonSlotEditScreenState extends ConsumerState<LessonSlotEditScreen> {
  final _price = TextEditingController();
  final _venue = TextEditingController();
  late DateTime _at = DateTime.now().add(const Duration(days: 2));
  int _minutes = 60;
  bool _busy = false;

  @override
  void dispose() {
    _price.dispose();
    _venue.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showOgPickerSheet<DateTime>(
      context: context,
      title: 'Lesson starts',
      initial: _at,
      picker: (onChanged) => CupertinoDatePicker(
        initialDateTime: _at,
        minimumDate: DateTime.now(),
        onDateTimeChanged: onChanged,
      ),
    );
    if (picked != null) setState(() => _at = picked);
  }

  Future<void> _save() async {
    final cents = parseMinor(_price.text.trim());
    if (cents == null || cents <= 0) {
      showOgToast(context, 'Set a price.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(lessonRepositoryProvider)
          .addSlot(
            widget.academyId,
            at: _at,
            minutes: _minutes,
            priceCents: cents,
            venue: _venue.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(mySlotsProvider(widget.academyId));
      kitPop(context);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => KitScaffold(
    header: const KitHeader(title: 'Add a time'),
    bottom: [
      KitButton(label: 'Open this time', loading: _busy, onPressed: _save),
    ],
    children: [
      KitNavTile(
        icon: OgIcons.calendar,
        title: 'Starts',
        subtitle: Fmt.dayTimeComma(_at),
        onTap: _pickTime,
      ),
      KitSegments(
        labels: const ['30 min', '60 min', '90 min'],
        selected: const [30, 60, 90].indexOf(_minutes),
        onSelect: (i) => setState(() => _minutes = const [30, 60, 90][i]),
      ),
      KitInput(
        label: 'Price (S\$)',
        controller: _price,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      KitInput(label: 'Where', controller: _venue, maxLength: 80),
      const KitNote(
        'A platform fee of 10%, at least S\$2.00, is added on top for the '
        'parent. OlympusGO pays the academy owner, not you directly.',
      ),
    ],
  );
}
