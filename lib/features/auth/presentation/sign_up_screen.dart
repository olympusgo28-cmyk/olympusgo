import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/country.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/phone_field.dart';
import '../application/pending_code.dart';
import '../data/auth_repository.dart';
import 'validators.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _mobile = TextEditingController();
  Country _country = Country.singapore;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final digits = _mobile.text.replaceAll(RegExp(r'\D'), '');
    final invalid = Validators.mobile(digits);
    if (invalid != null) return setState(() => _error = invalid);
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await ref
          .read(pendingCodeControllerProvider.notifier)
          .send(CodeChannel.signupMobile, '${_country.dialCode}$digits');
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
          lead: "Enter your mobile number. We'll send a 6-digit code. No password to remember.",
        ),
        const SizedBox(height: 32),
        PhoneField(
          country: _country,
          onCountryChanged: (v) => setState(() => _country = v),
          controller: _mobile,
          onSubmitted: (_) => _send(),
          error: _error,
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
