import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/resend_timer.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/code_copy.dart';
import '../../auth/presentation/validators.dart';
import '../application/onboarding_controller.dart';

enum _Availability { idle, checking, available, taken }

/// Step 5: username, checked live as you type.
class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  late final _name = TextEditingController(
    text: ref.read(onboardingControllerProvider).username,
  );
  Timer? _debounce;
  _Availability _status = _Availability.idle;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_name.text.isNotEmpty) _onChanged(_name.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    final invalid = v.isEmpty ? null : Validators.username(v);
    setState(() {
      _error = invalid;
      _status = v.isEmpty || invalid != null
          ? _Availability.idle
          : _Availability.checking;
    });
    if (_status != _Availability.checking) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final ok = await ref
            .read(profileRepositoryProvider)
            .usernameAvailable(v);
        if (!mounted || _name.text != v) return;
        setState(
          () => _status = ok ? _Availability.available : _Availability.taken,
        );
      } on AuthFailure catch (e) {
        if (mounted) setState(() => _error = e.message);
      }
    });
  }

  Future<void> _continue() async {
    setState(() => _busy = true);
    try {
      final notifier = ref.read(onboardingControllerProvider.notifier)
        ..setUsername(_name.text);
      await notifier.save(complete: false);
      if (mounted) context.push(Routes.addEmail);
    } on AuthFailure catch (e) {
      setState(() {
        _error = e.message;
        _status = _Availability.idle;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final name = _name.text;
    return OgFlowScreen(
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Pick a username',
          step: 5,
          topGap: 16,
          lead: 'Players find you by it. Use letters, numbers and underscores.',
        ),
        const SizedBox(height: 28),
        OgTextField(
          label: 'Username',
          controller: _name,
          autofocus: name.isEmpty,
          autocorrect: false,
          autofillHints: const [AutofillHints.newUsername],
          valid: _status == _Availability.available,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')),
            LengthLimitingTextInputFormatter(30),
          ],
          onChanged: _onChanged,
        ),
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          child: switch (_status) {
            _Availability.checking => Text(
              'Checking…',
              style: context.type.secondary,
            ),
            _Availability.available => Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: c.success,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: OgIcon(
                    OgIcons.check,
                    size: 12,
                    color: c.bg,
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(width: 8),
                Text('$name is available', style: context.type.body),
              ],
            ),
            _Availability.taken => const OgErrorText(
              'That username is taken. Try another one.',
            ),
            _Availability.idle =>
              _error == null ? const SizedBox.shrink() : OgErrorText(_error!),
          },
        ),
      ],
      bottom: [
        OgButton(
          label: 'Continue',
          loading: _busy,
          onPressed: _status == _Availability.available ? _continue : null,
        ),
      ],
    );
  }
}

/// Step 6: an optional email, for getting back in if the mobile is lost.
class AddEmailScreen extends ConsumerStatefulWidget {
  const AddEmailScreen({super.key});

  @override
  ConsumerState<AddEmailScreen> createState() => _AddEmailScreenState();
}

class _AddEmailScreenState extends ConsumerState<AddEmailScreen> {
  late final _email = TextEditingController(
    text: ref.read(onboardingControllerProvider).email,
  );
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
    ref.read(onboardingControllerProvider.notifier).setEmail(email);
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await ref.read(authRepositoryProvider).startEmailChange(email);
      if (mounted) context.push(Routes.addEmailVerify);
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
          title: 'Add an email',
          step: 6,
          topGap: 16,
          lead:
              'Optional. It helps you get back in if you lose your mobile. '
              'Other players never see it.',
        ),
        const SizedBox(height: 28),
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
        OgTextLink('Skip for now', onPressed: () => context.go(Routes.ready)),
      ],
    );
  }
}

/// Confirms the optional email with its code. No progress bar: it is a
/// check, not a step (owner, 8 Nov 2026).
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
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
      final email = ref.read(onboardingControllerProvider).email;
      await ref
          .read(authRepositoryProvider)
          .verifyEmailChange(email, _code.text);
      HapticFeedback.mediumImpact();
      if (mounted) context.go(Routes.ready);
    } on AuthFailure catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _error = e.message);
      _code.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);
    return OgFlowScreen(
      children: [
        const OgBackButton(),
        OgHeading(
          title: codeTitle(CodeTarget.email),
          topGap: 16,
          lead: codeLead(CodeTarget.email, draft.email),
        ),
        const SizedBox(height: 32),
        OgCodeField(
          controller: _code,
          hasError: _error != null,
          onCompleted: (_) => _verify(),
        ),
        if (_error != null) OgErrorText(_error!),
        ResendTimer(
          onResend: () async {
            try {
              await ref
                  .read(authRepositoryProvider)
                  .startEmailChange(draft.email);
              return true;
            } on AuthFailure catch (e) {
              setState(() => _error = e.message);
              return false;
            }
          },
        ),
      ],
      bottom: [
        OgButton(label: 'Verify', loading: _busy, onPressed: _verify),
        const SizedBox(height: 16),
        OgTextLink('Skip for now', onPressed: () => context.go(Routes.ready)),
      ],
    );
  }
}

/// "You're in." The Passport is ready.
class ReadyScreen extends ConsumerStatefulWidget {
  const ReadyScreen({super.key});

  @override
  ConsumerState<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends ConsumerState<ReadyScreen> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  Future<void> _finish() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .save(complete: true);
      if (mounted) context.go(Routes.setupAccount);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingControllerProvider);
    final first = draft.sports.isEmpty
        ? null
        : draft.skillFor(draft.sports.first);
    final parts = draft.fullName.trim().split(RegExp(r'\s+'));
    final initials = parts.length > 1
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : draft.fullName.isEmpty
        ? '?'
        : draft.fullName[0].toUpperCase();

    return Theme(
      data: Theme.of(context).copyWith(extensions: const [OgColors.dark]),
      child: OgFlowScreen(
        dark: true,
        fillGap: false,
        background: OgColors.night,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Mascot(size: 180),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      "You're in.",
                      style: context.type.display.copyWith(
                        color: OgColors.offWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      'Your Passport is ready. Next, check your account details.',
                      textAlign: TextAlign.center,
                      style: context.type.body.copyWith(
                        color: OgColors.grey400,
                        height: 1.45,
                      ),
                    ),
                  ),
                  if (first != null) ...[
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: OgColors.charcoal900,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: OgColors.orange300,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: context.type.section.copyWith(
                                color: OgColors.charcoal900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${first.sport.label} · ${first.level.toStringAsFixed(1)}',
                                  style: context.type.section.copyWith(
                                    color: OgColors.offWhite,
                                    height: 1.2,
                                  ),
                                ),
                                Text(
                                  'Starting level. Adjusts after a few matches.',
                                  style: context.type.body.copyWith(
                                    color: OgColors.grey400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null) OgErrorText(_error!),
                ],
              ),
            ),
          ),
        ],
        bottom: [
          OgButton(
            label: 'Set up my account',
            loading: _busy,
            onPressed: _finish,
          ),
        ],
      ),
    );
  }
}
