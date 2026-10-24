import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/country.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/phone_field.dart';
import '../../../core/widgets/resend_timer.dart';
import '../../auth/data/auth_repository.dart';
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
      if (mounted) context.push(Routes.mobile);
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
              style: OgText.body(
                14,
                weight: FontWeight.w600,
                color: c.textMuted,
              ),
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
                Text(
                  '$name is available',
                  style: OgText.body(
                    14,
                    weight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
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

/// Step 6: mobile number for sign-in codes and match alerts.
class MobileNumberScreen extends ConsumerStatefulWidget {
  const MobileNumberScreen({super.key});

  @override
  ConsumerState<MobileNumberScreen> createState() => _MobileNumberScreenState();
}

class _MobileNumberScreenState extends ConsumerState<MobileNumberScreen> {
  late final _number = TextEditingController(
    text: ref.read(onboardingControllerProvider).phoneNumber,
  );
  late Country _country = ref.read(onboardingControllerProvider).phoneCountry;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    final invalid = Validators.mobile(digits);
    if (invalid != null) return setState(() => _error = invalid);
    ref
        .read(onboardingControllerProvider.notifier)
        .setPhone(_country, _number.text.trim());
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .startPhoneChange(ref.read(onboardingControllerProvider).fullPhone);
      if (mounted) context.push(Routes.mobileVerify);
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
          title: 'Your mobile number',
          step: 6,
          topGap: 16,
          lead: 'We use it for sign-in codes by SMS and match alerts. Other players never see it.',
        ),
        const SizedBox(height: 28),
        AutofillGroup(
          child: PhoneField(
            country: _country,
            onCountryChanged: (v) => setState(() => _country = v),
            controller: _number,
            onSubmitted: (_) => _send(),
          ),
        ),
        if (_error != null) OgErrorText(_error!),
        if (_error != null && kDebugMode)
          OgTextLink(
            'Skip for now (debug build only)',
            align: Alignment.centerLeft,
            onPressed: () => context.push(Routes.ready),
          ),
      ],
      bottom: [OgButton(label: 'Send code', loading: _busy, onPressed: _send)],
    );
  }
}

/// Step 7: confirm the SMS code.
class VerifyMobileScreen extends ConsumerStatefulWidget {
  const VerifyMobileScreen({super.key});

  @override
  ConsumerState<VerifyMobileScreen> createState() => _VerifyMobileScreenState();
}

class _VerifyMobileScreenState extends ConsumerState<VerifyMobileScreen> {
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
      final phone = ref.read(onboardingControllerProvider).fullPhone;
      await ref
          .read(authRepositoryProvider)
          .verifyPhoneChange(phone, _code.text);
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
          title: 'Verify your number',
          step: 7,
          topGap: 16,
          lead:
              'We texted a 6-digit code to ${draft.phoneCountry.dialCode} '
              '${draft.phoneNumber}. It works for 10 minutes.',
        ),
        const SizedBox(height: 32),
        OgCodeInput(
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
                  .startPhoneChange(draft.fullPhone);
            } on AuthFailure catch (e) {
              setState(() => _error = e.message);
            }
          },
        ),
      ],
      bottom: [
        OgButton(label: 'Verify', loading: _busy, onPressed: _verify),
        const SizedBox(height: 16),
        OgTextLink('Wrong number? Change it', onPressed: () => context.pop()),
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
                      style: OgText.display(38, color: OgColors.offWhite),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      'Your Passport is ready. Next, check your account details.',
                      textAlign: TextAlign.center,
                      style: OgText.body(
                        17,
                        height: 1.45,
                        color: OgColors.grey400,
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
                              style: OgText.display(
                                18,
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
                                  style: OgText.display(
                                    19,
                                    height: 1.2,
                                    color: OgColors.offWhite,
                                  ),
                                ),
                                Text(
                                  'Starting level. Adjusts after a few matches.',
                                  style: OgText.body(
                                    14,
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
