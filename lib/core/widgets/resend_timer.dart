import 'dart:async';

import 'package:flutter/widgets.dart';

import '../theme/og_colors.dart';
import '../theme/og_text.dart';
import 'og_buttons.dart';

/// "Send a new code in 0:30", which turns into a link when it reaches zero.
class ResendTimer extends StatefulWidget {
  const ResendTimer({super.key, required this.onResend, this.seconds = 30});

  final Future<void> Function() onResend;
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
      final s = _left.toString().padLeft(2, '0');
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          'Send a new code in 0:$s',
          style: OgText.body(15, color: context.og.textMuted),
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
                  await widget.onResend();
                  _start();
                } finally {
                  if (mounted) setState(() => _sending = false);
                }
              },
      ),
    );
  }
}
