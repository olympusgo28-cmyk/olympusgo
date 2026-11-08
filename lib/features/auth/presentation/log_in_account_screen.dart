import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/country.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/phone_field.dart';
import '../application/pending_code.dart';
import 'code_copy.dart';
import 'log_in_screen.dart' show LegalLine;
import 'saved_accounts.dart';
import '../data/auth_repository.dart';
import 'validators.dart';

enum LoginMethod { email, phone, username }

/// Log in by mobile number, email or username; the other two methods sit
/// below as alternatives. A mobile with no account signs up here: after its
/// code the router opens onboarding, and Home for an account that exists
/// (Q247). Face ID tiles are on the Log in screen.
class LogInAccountScreen extends ConsumerStatefulWidget {
  const LogInAccountScreen({super.key, required this.method});

  final LoginMethod method;

  @override
  ConsumerState<LogInAccountScreen> createState() => _LogInAccountScreenState();
}

class _LogInAccountScreenState extends ConsumerState<LogInAccountScreen> {
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
    LoginMethod.username => "Enter your username. We'll send a 6-digit code to the email or mobile on your account.",
  };

  Future<void> _send() async {
    final value = _field.text.trim();
    final (
      String? invalid,
      CodeTarget target,
      String destination,
    ) = switch (widget.method) {
      LoginMethod.email => (Validators.email(value), CodeTarget.email, value),
      LoginMethod.username => (
        Validators.username(value),
        CodeTarget.username,
        value,
      ),
      LoginMethod.phone => () {
        final digits = value.replaceAll(RegExp(r'\D'), '');
        return (
          Validators.mobile(digits),
          CodeTarget.mobile,
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
          .send(target, destination);
      if (mounted) context.push(Routes.logInCode);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _switchTo(String route) => context.pushReplacement(route);

  /// Back to where this screen came from; otherwise to the saved accounts
  /// when this phone has some, or to Welcome.
  Future<void> _back() async {
    if (context.canPop()) return context.pop();
    final saved = await ref
        .read(savedAccountsProvider.future)
        .catchError((_) => const <Never>[]);
    if (mounted) context.go(saved.isEmpty ? Routes.welcome : Routes.logIn);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    // Read ahead, so Back knows at once whether this phone has saved tiles.
    ref.watch(savedAccountsProvider);
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
        OgBackButton(onPressed: _back),
        OgHeading(
          // A new number signs up here, so "Welcome back" would be wrong.
          title: widget.method == LoginMethod.phone
              ? 'Log in or sign up'
              : 'Log in',
          lead: _lead,
        ),
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
        if (widget.method != LoginMethod.phone) ...[
          const SizedBox(height: 10),
          OgMethodButton(
            icon: OgIcons.phone,
            label: 'Log in with mobile',
            onPressed: () => _switchTo(Routes.logInMobile),
          ),
        ],
        if (widget.method != LoginMethod.email) ...[
          const SizedBox(height: 10),
          OgMethodButton(
            icon: OgIcons.mail,
            label: 'Log in with email',
            onPressed: () => _switchTo(Routes.logInEmail),
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
          'Trouble logging in? Get back into your account',
          onPressed: () => context.push(Routes.recovery),
        ),
        // A new phone has no tiles and skips the Log in screen, so the terms
        // are shown here too, before anyone signs up (Q255).
        const SizedBox(height: 8),
        const LegalLine(),
      ],
    );
  }
}
