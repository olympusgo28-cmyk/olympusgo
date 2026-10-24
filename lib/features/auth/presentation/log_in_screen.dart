import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/country.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/phone_field.dart';
import '../application/pending_code.dart';
import '../data/auth_repository.dart';
import 'validators.dart';

enum LoginMethod { email, phone, username }

/// "Welcome back": log in by email, mobile number or username. The other
/// two methods and Face ID sit below as alternatives.
class LogInScreen extends ConsumerStatefulWidget {
  const LogInScreen({super.key, required this.method});

  final LoginMethod method;

  @override
  ConsumerState<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends ConsumerState<LogInScreen> {
  final _field = TextEditingController();
  Country _country = Country.singapore;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  String get _lead => switch (widget.method) {
    LoginMethod.email =>
      "Enter your email. We'll send you a 6-digit code by email.",
    LoginMethod.phone =>
      "Enter your mobile number. We'll send you a 6-digit code by SMS.",
    LoginMethod.username =>
      "Enter your username. We'll send you a 6-digit code by email.",
  };

  Future<void> _send() async {
    final value = _field.text.trim();
    final (
      String? invalid,
      CodeChannel channel,
      String destination,
    ) = switch (widget.method) {
      LoginMethod.email => (
        Validators.email(value),
        CodeChannel.loginEmail,
        value,
      ),
      LoginMethod.username => (
        Validators.username(value),
        CodeChannel.loginUsername,
        value,
      ),
      LoginMethod.phone => () {
        final digits = value.replaceAll(RegExp(r'\D'), '');
        return (
          Validators.mobile(digits),
          CodeChannel.loginPhone,
          '${_country.dialCode}$digits',
        );
      }(),
    };
    if (invalid != null) return setState(() => _error = invalid);
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await ref
          .read(pendingCodeControllerProvider.notifier)
          .send(channel, destination);
      if (mounted) context.push(Routes.logInCode);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _faceId() async {
    try {
      await ref.read(authRepositoryProvider).unlockWithBiometrics();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Face ID is not set up yet'),
          content: Text(e.message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _switchTo(String route) => context.pushReplacement(route);

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final field = switch (widget.method) {
      LoginMethod.email => OgTextField(
        label: 'Email',
        controller: _field,
        hint: 'you@example.com',
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _send(),
        error: _error,
      ),
      LoginMethod.username => OgTextField(
        label: 'Username',
        controller: _field,
        hint: 'your_username',
        autofillHints: const [AutofillHints.username],
        autocorrect: false,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _send(),
        error: _error,
      ),
      LoginMethod.phone => PhoneField(
        country: _country,
        onCountryChanged: (v) => setState(() => _country = v),
        controller: _field,
        onSubmitted: (_) => _send(),
        error: _error,
      ),
    };

    return OgFlowScreen(
      children: [
        OgBackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.welcome),
        ),
        OgHeading(title: 'Welcome back', lead: _lead),
        const SizedBox(height: 32),
        AutofillGroup(child: field),
        const SizedBox(height: 24),
        OgButton(label: 'Send code', loading: _busy, onPressed: _send),
        const SizedBox(height: 24),
        ExcludeSemantics(
          child: Row(
            children: [
              Expanded(child: Container(height: 2, color: c.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: OgText.body(14, color: c.textMuted)),
              ),
              Expanded(child: Container(height: 2, color: c.border)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OgMethodButton(
          icon: OgIcons.faceId,
          label: 'Unlock with Face ID',
          onPressed: _faceId,
        ),
        if (widget.method != LoginMethod.email) ...[
          const SizedBox(height: 10),
          OgMethodButton(
            icon: OgIcons.mail,
            label: 'Log in with email',
            onPressed: () => _switchTo(Routes.logIn),
          ),
        ],
        if (widget.method != LoginMethod.phone) ...[
          const SizedBox(height: 10),
          OgMethodButton(
            icon: OgIcons.phone,
            label: 'Log in with phone',
            onPressed: () => _switchTo(Routes.logInPhone),
          ),
        ],
        if (widget.method != LoginMethod.username) ...[
          const SizedBox(height: 10),
          OgMethodButton(
            icon: OgIcons.person,
            label: 'Log in with username',
            onPressed: () => _switchTo(Routes.logInUsername),
          ),
        ],
      ],
      bottom: [
        OgTextLink(
          'New here? Create an account',
          onPressed: () => context.pushReplacement(Routes.signUp),
        ),
        const SizedBox(height: 4),
        OgTextLink(
          'Forgotten both email and mobile? Get back in',
          onPressed: () => context.push(Routes.recovery),
        ),
      ],
    );
  }
}
