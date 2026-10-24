import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_screen.dart';
import '../data/auth_repository.dart';
import 'validators.dart';

/// "Get back your account" when both email and mobile are lost.
class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  final _email = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _email.text.trim();
    final invalid = Validators.email(email);
    if (invalid != null) return setState(() => _error = invalid);
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await ref.read(authRepositoryProvider).requestRecovery(email);
      if (mounted) context.pushReplacement(Routes.recoverySent);
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
          title: 'Get back your account',
          lead:
              'Lost access to both your email and your mobile number? Enter an email '
              "address you can use now and we'll help you recover your account.",
        ),
        const SizedBox(height: 32),
        OgTextField(
          label: 'Email address',
          controller: _email,
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _continue(),
          error: _error,
        ),
      ],
      bottom: [
        OgButton(label: 'Continue', loading: _busy, onPressed: _continue),
        const SizedBox(height: 16),
        OgTextLink('Back to log in', onPressed: () => context.go(Routes.logIn)),
      ],
    );
  }
}

class RecoverySentScreen extends StatelessWidget {
  const RecoverySentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OgFlowScreen(
      children: [
        OgBackButton(onPressed: () => context.pushReplacement(Routes.recovery)),
        const SizedBox(height: 24),
        const OgIconBadge(
          child: OgIcon(
            OgIcons.mailRound,
            size: 36,
            color: OgColors.orange300,
            strokeWidth: 2.2,
          ),
        ),
        const OgHeading(
          title: 'Check your email',
          lead:
              'We sent a message to that address with the next steps to get back into '
              "your account. If you don't see it in a few minutes, check your spam folder.",
        ),
      ],
      bottom: [
        OgButton(
          label: 'Back to log in',
          onPressed: () => context.go(Routes.logIn),
        ),
        const SizedBox(height: 16),
        OgTextLink(
          'Use a different email address',
          onPressed: () => context.pushReplacement(Routes.recovery),
        ),
      ],
    );
  }
}
