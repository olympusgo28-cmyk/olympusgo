import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/resend_timer.dart';
import '../application/pending_code.dart';
import '../data/auth_repository.dart';

/// Enter the 6-digit code from email or SMS. Signing in succeeds here, and
/// the router then moves on to onboarding or Home.
class CodeScreen extends ConsumerStatefulWidget {
  const CodeScreen({super.key});

  @override
  ConsumerState<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends ConsumerState<CodeScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (_code.text.length != 6) {
      return setState(() => _error = 'Enter all 6 digits of the code.');
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await ref.read(pendingCodeControllerProvider.notifier).verify(_code.text);
      HapticFeedback.mediumImpact();
    } on AuthFailure catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _error = e.message);
      _code.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(pendingCodeControllerProvider.notifier).resend();
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingCodeControllerProvider);
    final channel = pending?.channel ?? CodeChannel.loginEmail;
    final signUp = channel == CodeChannel.signupEmail;

    final title = signUp ? 'Check your email' : 'Enter the code';
    final lead = switch (channel) {
      CodeChannel.signupEmail => 'We sent a 6-digit code to the email you entered. It works for 10 minutes.',
      CodeChannel.loginPhone => 'We sent a 6-digit code by SMS to your mobile number. It works for 10 minutes.',
      _ => 'We sent a 6-digit code to the email on this account. It works for 10 minutes.',
    };

    return OgFlowScreen(
      children: [
        const OgBackButton(),
        OgHeading(title: title, lead: lead),
        const SizedBox(height: 32),
        OgCodeInput(
          controller: _code,
          hasError: _error != null,
          onCompleted: (_) => _verify(),
        ),
        if (_error != null) OgErrorText(_error!),
        ResendTimer(onResend: _resend),
      ],
      bottom: [
        OgButton(
          label: signUp ? 'Verify email' : 'Log in',
          loading: _busy,
          onPressed: _verify,
        ),
        const SizedBox(height: 16),
        OgTextLink(
          signUp
              ? 'Wrong email? Change it'
              : 'Use a different email, mobile or username',
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(signUp ? Routes.signUp : Routes.logIn),
        ),
      ],
    );
  }
}
