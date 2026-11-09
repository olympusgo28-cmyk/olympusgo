import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/country.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_layout.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/phone_field.dart';
import '../../../core/widgets/settings_list.dart';
import '../../auth/data/auth_repository.dart';
import '../application/settings_providers.dart';
import '../domain/account_info.dart';

/// Account information: phone number, email, date of birth and account
/// region, then the Face ID switch (Q249, Q258). Only the owner sees these.
/// Phone and email open their own edit screens; date of birth and region
/// cannot be changed here (Q254).
class AccountInfoScreen extends ConsumerWidget {
  const AccountInfoScreen({super.key, this.onboarding = false});

  /// Shown once after onboarding, with Continue to the profile.
  final bool onboarding;

  static const regionNote =
      'Your account region is initially set based on the time and place of '
      'registration.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(accountInfoProvider);
    final faceId = ref.watch(faceIdEnabledProvider).value ?? false;

    final Widget details;
    if (info.hasValue) {
      details = _details(context, info.value);
    } else if (info.hasError && !info.isLoading) {
      details = SettingsLoadError(
        message:
            "We couldn't load your account information. Check your "
            'connection, then try again.',
        onRetry: () => ref.read(accountInfoProvider.notifier).retry(),
      );
    } else {
      details = _details(context, null);
    }

    Future<void> setFaceId(bool on) async {
      final now = await ref.read(faceIdEnabledProvider.notifier).set(on);
      if (on && !now && context.mounted) {
        showOgToast(
          context,
          'Face ID is still off. Check Face ID is set up on this phone, then try again.',
          error: true,
        );
      }
    }

    return KitScaffold(
      header: const KitHeader(title: 'Account information'),
      // Outlined sections bring their own side margins.
      padding: const EdgeInsets.symmetric(vertical: OgSpace.s6),
      gap: OgSpace.s6,
      bottom: onboarding
          ? [
              OgButton(
                label: 'Continue',
                onPressed: () => context.go(Routes.profile),
              ),
            ]
          : null,
      children: [
        ReadableWidth(child: details),
        // Hidden while local testing turns Face ID off.
        if (!ref.watch(biometricVaultProvider).skipped)
          ReadableWidth(
            child: SettingsSection(
              style: SettingsStyle.outlined,
              label: 'Sign-in',
              rows: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: OgSpace.s4),
                  child: SwitchRow(
                    title: 'Enable Face ID',
                    subtitle: 'Unlock OlympusGO with your face.',
                    value: faceId,
                    onChanged: setFaceId,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// The card, with skeleton rows while [info] is null.
  Widget _details(BuildContext context, AccountInfo? info) {
    final loading = info == null;
    return SettingsSection(
      style: SettingsStyle.outlined,
      label: 'Account information',
      helper: regionNote,
      rows: [
        SettingsRow(
          label: 'Phone number',
          value: info?.maskedPhone,
          semanticValue: info?.spokenPhone,
          emptyText: 'Add',
          isLoading: loading,
          onTap: () => context.push(Routes.changePhone),
        ),
        SettingsRow(
          label: 'Email',
          value: info?.maskedEmail,
          emptyText: 'Add',
          isLoading: loading,
          onTap: () => context.push(Routes.changeEmail),
        ),
        SettingsRow(
          label: 'Date of birth',
          value: info?.birthdayText,
          isLoading: loading,
        ),
        SettingsRow(
          label: 'Account region',
          value: info?.region.name,
          isLoading: loading,
        ),
      ],
    );
  }
}

/// Change or add the mobile. The number keeps its own dialling code, which
/// cannot be changed here (Q254). A code goes to the new number first.
class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _mobile = TextEditingController();
  AccountInfo? _info;

  /// The digits first put in the field, to tell an unchanged number.
  String _initial = '';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Country get _country => _info?.phoneCountry ?? Country.singapore;

  void _fill(AccountInfo info) {
    if (_info != null) return;
    _info = info;
    final dial = info.phoneCountry.dialCode.substring(1);
    var digits = info.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith(dial)) digits = digits.substring(dial.length);
    _initial = digits;
    // Never replace what the player has already typed.
    if (_mobile.text.isNotEmpty) return;
    _mobile.text = digits.length == 8
        ? '${digits.substring(0, 4)} ${digits.substring(4)}'
        : digits;
  }

  Future<void> _send() async {
    if (_busy) return;
    final digits = _mobile.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return setState(() => _error = 'Enter your mobile number.');
    }
    // Compared as typed, so a number whose dialling code the app doesn't
    // list is never re-sent under the region's code.
    if (digits == _initial) {
      context.pop();
      return;
    }
    final phone = '${_country.dialCode}$digits';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).startPhoneChange(phone);
    } on AuthFailure catch (e) {
      return setState(() {
        _error = e.message;
        _busy = false;
      });
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final done = await context.push<bool>(
      Routes.verifyPhoneChange,
      extra: phone,
    );
    if (done == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(accountInfoProvider).whenData(_fill);
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Phone number',
          topGap: OgSpace.s2,
          lead: "We'll text a 6-digit code to the new number.",
        ),
        const SizedBox(height: OgSpace.s4),
        PhoneField(
          country: _country,
          controller: _mobile,
          label: 'Mobile',
          onSubmitted: (_) => _send(),
        ),
        if (_error != null) OgErrorText(_error!),
      ],
      bottom: [OgButton(label: 'Send code', loading: _busy, onPressed: _send)],
    );
  }
}

/// Change or add the email. A code goes to the new address first.
class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _email = TextEditingController();
  AccountInfo? _info;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _fill(AccountInfo info) {
    if (_info != null) return;
    _info = info;
    // Never replace what the player has already typed.
    if (_email.text.isEmpty) _email.text = info.email;
  }

  Future<void> _send() async {
    if (_busy) return;
    final email = _email.text.trim();
    if (email.isEmpty) {
      return setState(() => _error = 'Enter your email address.');
    }
    if (email == _info?.email) {
      context.pop();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).startEmailChange(email);
    } on AuthFailure catch (e) {
      return setState(() {
        _error = e.message;
        _busy = false;
      });
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final done = await context.push<bool>(
      Routes.verifyPhoneChange,
      extra: email,
    );
    if (done == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(accountInfoProvider).whenData(_fill);
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Email',
          topGap: OgSpace.s2,
          lead: "We'll send a 6-digit code to the new address.",
        ),
        const SizedBox(height: OgSpace.s4),
        OgTextField(
          label: 'Email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _send(),
        ),
        if (_error != null) OgErrorText(_error!),
      ],
      bottom: [OgButton(label: 'Send code', loading: _busy, onPressed: _send)],
    );
  }
}
