import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/code_rules.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/resend_timer.dart';
import '../../auth/data/auth_repository.dart';
import '../application/settings_providers.dart';

/// Runs [send], which changes a login contact. If the server first wants
/// proof it is really them (R-ACC-9, Q268), shows "Confirm it's you" and then
/// runs [send] once more. Returns false if they backed out.
Future<bool> withConfirmItsYou(
  BuildContext context,
  LoginContact changing,
  Future<void> Function() send,
) async {
  try {
    await send();
    return true;
  } on StepUpNeeded {
    if (!context.mounted) return false;
    // Pushed directly, not as an app route, so it also works in onboarding,
    // where the router keeps players inside the onboarding screens.
    final confirmed = await Navigator.of(context, rootNavigator: true)
        .push<bool>(
          CupertinoPageRoute(
            builder: (_) => ConfirmItsYouScreen(changing: changing),
          ),
        );
    if (confirmed != true) return false;
    await send();
    return true;
  }
}

/// "Confirm it's you": a 6-digit code sent to the contact already on the
/// account, before a login mobile or email can change.
class ConfirmItsYouScreen extends ConsumerStatefulWidget {
  const ConfirmItsYouScreen({super.key, required this.changing});

  final LoginContact changing;

  @override
  ConsumerState<ConfirmItsYouScreen> createState() =>
      _ConfirmItsYouScreenState();
}

class _ConfirmItsYouScreenState extends ConsumerState<ConfirmItsYouScreen> {
  final _code = TextEditingController();
  LoginContact? _via;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _send();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<bool> _send() async {
    try {
      final via = await ref
          .read(authRepositoryProvider)
          .startStepUp(widget.changing);
      if (mounted) {
        setState(() {
          _via = via;
          _error = null;
        });
      }
      return true;
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
      return false;
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (_code.text.length != 6) {
      return setState(() => _error = 'Enter all 6 digits of the code.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyStepUp(widget.changing, _code.text);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } on AuthFailure catch (e) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      _code.clear();
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  /// Names where the code went without showing an email (R-ACC-10): the
  /// mobile with most digits hidden, or just "your email".
  String get _lead {
    final where = switch (_via) {
      null => null,
      LoginContact.email => 'your email',
      LoginContact.mobile =>
        ref.watch(accountInfoProvider).value?.maskedPhone ?? 'your mobile',
    };
    final change = widget.changing == LoginContact.mobile
        ? 'mobile number'
        : 'email';
    return where == null
        ? 'Before your $change changes, we need to check it’s you.'
        : 'Before your $change changes, enter the 6-digit code we sent to '
              '$where. It works for ${CodeRules.minutes} minutes.';
  }

  @override
  Widget build(BuildContext context) {
    return OgFlowScreen(
      asPage: true,
      children: [
        OgBackButton(onPressed: () => Navigator.of(context).pop(false)),
        OgHeading(title: 'Confirm it’s you', lead: _lead),
        const SizedBox(height: 32),
        OgCodeField(
          controller: _code,
          hasError: _error != null,
          onCompleted: (_) => _verify(),
        ),
        if (_error != null) OgErrorText(_error!),
        ResendTimer(onResend: _send),
      ],
      bottom: [OgButton(label: 'Confirm', loading: _busy, onPressed: _verify)],
    );
  }
}
