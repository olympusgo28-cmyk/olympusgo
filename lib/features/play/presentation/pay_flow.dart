import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_money/og_money.dart';

import '../../../core/providers.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pay_sheet.dart';
import '../../auth/data/auth_repository.dart';
import '../data/payment_gateway.dart';
import '../domain/activity.dart';
import '../domain/meet_ops.dart' show newClientKey;

/// What's being paid for, which words the wait.
enum PayingFor {
  spot('spot'),
  order('order'),
  lesson('lesson');

  const PayingFor(this.noun);
  final String noun;
}

/// How a payment came out.
class PaidSpot {
  const PaidSpot({
    required this.totalCents,
    required this.paidWith,
    required this.receiptNo,
  });

  final int totalCents;
  final String paidWith;
  final String receiptNo;
}

/// Pays for a spot from start to finish: the sheet with the server's quote and
/// refund rule, the hold, then waiting for the webhook. Null means no spot was
/// paid for, and the player has been told why.
Future<PaidSpot?> payForSpot(
  BuildContext context,
  WidgetRef ref,
  Activity a, {
  required String kicker,
  required String subtitle,
  required String priceLine,
  required String payee,
  int qty = 1,
  String? guestName,
  double? guestLevel,
}) async {
  final gateway = ref.read(paymentGatewayProvider);
  try {
    final quote = await gateway.quote(a.id, qty: qty);
    if (!quote.paymentsEnabled || !gateway.canCollect) {
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
      kicker: kicker,
      title: a.title,
      subtitle: subtitle,
      lines: [
        if (quote.priceCents > 0) (priceLine, '${Money(quote.priceCents)}'),
        ('Platform fee', '${Money(quote.feeCents)}'),
      ],
      totalCents: quote.totalCents,
      payee: 'OlympusGO',
      notes: [
        quote.refundRule,
        'OlympusGO holds your payment until $payee marks attendance, or 24 '
            'hours after the end.',
      ],
    );
    if (method == null || !context.mounted) return null;
    final hold = await gateway.reserve(
      activityId: a.id,
      key: newClientKey(),
      qty: qty,
      guestName: guestName,
      guestLevel: guestLevel,
    );
    if (!context.mounted) return null;
    if (hold.id == null) {
      showOgToast(
        context,
        hold.result == 'waitlist'
            ? 'It just filled up, so you’re on the waitlist. You pay nothing '
                  'unless a spot opens.'
            : 'You’re already on this one.',
      );
      return null;
    }
    return await finishPayment(context, gateway, hold, method);
  } on AuthFailure catch (e) {
    if (context.mounted) showOgToast(context, e.message, error: true);
    return null;
  }
}

/// Pays the organizer fees that couldn't be charged to a card.
Future<PaidSpot?> payFeesOwed(
  BuildContext context,
  WidgetRef ref,
  int cents,
) async {
  final gateway = ref.read(paymentGatewayProvider);
  try {
    final method = await showPaySheet(
      context,
      kicker: 'Fees owed',
      title: 'Organizer fees',
      subtitle: 'For free Meets where you cover the fee',
      lines: [('Fees', '${Money(cents)}')],
      totalCents: cents,
      payee: 'OlympusGO',
    );
    if (method == null || !context.mounted) return null;
    final hold = await gateway.reserveFeesOwed(newClientKey());
    if (!context.mounted) return null;
    return await finishPayment(context, gateway, hold, method);
  } on AuthFailure catch (e) {
    if (context.mounted) showOgToast(context, e.message, error: true);
    return null;
  }
}

/// Starts the held payment and waits for the webhook.
Future<PaidSpot?> finishPayment(
  BuildContext context,
  PaymentGateway gateway,
  PaymentHold hold,
  PayMethod chosen, {
  PayingFor paying = PayingFor.spot,
}) async {
  // A live payment keeps the method it started with.
  final started = hold.method;
  final methods = await gateway.methods();
  final method = started == null
      ? chosen
      : methods.firstWhere((m) => m.id == started, orElse: () => chosen);
  await gateway.begin(hold.id!, method);
  if (!context.mounted) return null;
  final done = await Navigator.of(context, rootNavigator: true)
      .push<PaymentProgress>(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (_) => PaymentWaitingScreen(hold: hold, paying: paying),
        ),
      );
  if (done?.state != PaymentState.paid) return null;
  return PaidSpot(
    totalCents: hold.totalCents,
    paidWith: method.title,
    receiptNo: done!.receiptNo,
  );
}

/// "Waiting for payment", with a countdown on the server's clock, so a wrong
/// phone clock can't show the wrong time left.
class PaymentWaitingScreen extends ConsumerStatefulWidget {
  const PaymentWaitingScreen({
    super.key,
    required this.hold,
    this.paying = PayingFor.spot,
  });

  final PaymentHold hold;
  final PayingFor paying;

  @override
  ConsumerState<PaymentWaitingScreen> createState() =>
      _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends ConsumerState<PaymentWaitingScreen> {
  Timer? _poll;
  Timer? _tick;
  late DateTime? _until = widget.hold.holdUntil;
  late Duration _skew = widget.hold.serverNow == null
      ? Duration.zero
      : DateTime.now().difference(widget.hold.serverNow!);
  bool _failed = false;
  bool _refunded = false;
  bool _ended = false;
  bool _busy = false;
  bool _done = false;

  /// Polls overlap, so only the first answer closes this screen.
  void _close([PaymentProgress? p]) {
    if (_done || !mounted) return;
    _done = true;
    _poll?.cancel();
    Navigator.of(context).pop(p);
  }

  Duration get _left {
    final until = _until;
    if (until == null) return Duration.zero;
    final left = until.difference(DateTime.now().subtract(_skew));
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _check());
    _check();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final p = await ref
          .read(paymentGatewayProvider)
          .progress(widget.hold.id!);
      if (!mounted || _done) return;
      if (p.state == PaymentState.paid) return _close(p);
      setState(() {
        _failed = p.failed;
        _refunded = p.state == PaymentState.refunded;
        _ended = p.state == PaymentState.ended;
        if (p.holdUntil != null) _until = p.holdUntil;
        if (p.serverNow != null) {
          _skew = DateTime.now().difference(p.serverNow!);
        }
      });
      if (_refunded || _ended) _poll?.cancel();
    } on AuthFailure {
      // The next poll tries again.
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      final gateway = ref.read(paymentGatewayProvider);
      await gateway.abandon(widget.hold.id!);
      // It may have gone through just before they tapped.
      final p = await gateway.progress(widget.hold.id!);
      _close(p.state == PaymentState.paid ? p : null);
    } on AuthFailure catch (e) {
      if (mounted) {
        showOgToast(context, e.message, error: true);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _simulate() async {
    try {
      await ref.read(paymentGatewayProvider).simulate(widget.hold.id!);
      await _check();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final gateway = ref.watch(paymentGatewayProvider);
    final noun = widget.paying.noun;
    final spot = widget.paying == PayingFor.spot;
    final left = _left;
    final time =
        '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    if (_refunded || _ended) {
      return KitScaffold(
        header: const KitHeader(title: 'Payment'),
        bottom: [KitButton(label: 'Close', onPressed: _close)],
        children: [
          KitTitle(
            _refunded ? 'Your payment is coming back' : 'This payment ended',
            lead: _refunded
                ? 'We couldn’t keep your $noun, so everything you paid goes '
                      'back to where it came from.'
                : spot
                ? 'You weren’t charged. Try again if you still want the spot.'
                : 'You weren’t charged. Try again if you still want it.',
          ),
        ],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Payment'),
      bottom: [
        if (gateway.canSimulate)
          KitButton(label: 'Finish test payment', onPressed: _simulate),
        KitButton.outline(label: 'Cancel', loading: _busy, onPressed: _cancel),
      ],
      children: [
        KitTitle(
          'Waiting for payment',
          lead: left == Duration.zero
              ? spot
                    ? 'Your hold ran out. If your payment still lands, we’ll give you '
                          'a spot if there is one, or send it all back.'
                    : 'Your hold ran out. If your payment still lands, we’ll '
                          'send it all back.'
              : 'We’re holding your $noun for $time.',
        ),
        if (_failed)
          KitNote(
            'That didn’t go through. You can try again while your '
            '$noun is held.',
            tone: KitTone.warn,
          ),
        Text(
          '${Money(widget.hold.totalCents)} to OlympusGO',
          style: OgText.heading(24),
        ),
        Text(switch (widget.paying) {
          PayingFor.order =>
            'OlympusGO holds your payment until you collect. Your order is '
                'placed as soon as your bank or card confirms it.',
          PayingFor.lesson =>
            'OlympusGO holds your payment until the coach marks attendance. '
                'You’re booked as soon as your bank or card confirms it.',
          PayingFor.spot =>
            'OlympusGO holds your payment until the organizer marks attendance. '
                'You’re in as soon as your bank or card confirms it.',
        }, style: OgText.body(14, height: 1.45, color: c.textMuted)),
      ],
    );
  }
}
