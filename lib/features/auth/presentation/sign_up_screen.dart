import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_screen.dart';
import '../application/pending_code.dart';
import '../data/auth_repository.dart';
import 'validators.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _email = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    final invalid = Validators.email(email);
    if (invalid != null) return setState(() => _error = invalid);
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await ref
          .read(pendingCodeControllerProvider.notifier)
          .send(CodeChannel.signupEmail, email);
      if (mounted) context.push(Routes.signUpCode);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OgFlowScreen(
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Create your account',
          lead: "Enter your email. We'll send a 6-digit code. No password to remember.",
        ),
        const SizedBox(height: 32),
        AutofillGroup(
          child: OgTextField(
            label: 'Email',
            controller: _email,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            error: _error,
          ),
        ),
      ],
      bottom: [
        OgButton(label: 'Send code', loading: _busy, onPressed: _send),
        const SizedBox(height: 16),
        OgTextLink(
          'Already have an account? Log in',
          onPressed: () => context.pushReplacement(Routes.logIn),
        ),
      ],
    );
  }
}
