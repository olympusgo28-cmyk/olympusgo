import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/code_rules.dart';
import 'og_buttons.dart';
import '../../core/theme/og_type.dart';

/// "Send a new code in 2:59", which turns into a link when it reaches zero.
/// It waits as long as a code works (Q248).
class ResendTimer extends StatefulWidget {
  const ResendTimer({
    super.key,
    required this.onResend,
    this.seconds = CodeRules.resendSeconds,
  });

  /// Resolves true once a new code was sent. On false (the screen showed
  /// why) the link stays, rather than making the player wait again.
  final Future<bool> Function() onResend;
  final int seconds;

  @override
  State<ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<ResendTimer> {
  late int _left = widget.seconds;
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _left = widget.seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_left <= 1) t.cancel();
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_left > 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          'Send a new code in ${resendClock(_left)}',
          style: context.type.secondary,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OgTextLink(
        _sending ? 'Sending…' : 'Send a new code',
        align: Alignment.centerLeft,
        onPressed: _sending
            ? null
            : () async {
                setState(() => _sending = true);
                try {
                  if (await widget.onResend()) _start();
                } finally {
                  if (mounted) setState(() => _sending = false);
                }
              },
      ),
    );
  }
}

/// 180 → "3:00", 59 → "0:59".
String resendClock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
