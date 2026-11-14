import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/resend_timer.dart';
import '../application/pending_code.dart';
import '../data/auth_repository.dart';
import 'code_copy.dart';

/// Enter the 6-digit code from email or SMS. Signing in succeeds here, and
/// the router then opens onboarding for a new number or Home for an account
/// that exists (Q247).
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

  Future<bool> _resend() async {
    try {
      await ref.read(pendingCodeControllerProvider.notifier).resend();
      return true;
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingCodeControllerProvider);
    final target = pending?.target ?? CodeTarget.mobile;
    return OgFlowScreen(
      children: [
        const OgBackButton(),
        OgHeading(
          title: codeTitle(target),
          lead: codeLead(target, pending?.destination ?? ''),
        ),
        const SizedBox(height: 32),
        OgCodeField(
          controller: _code,
          hasError: _error != null,
          onCompleted: (_) => _verify(),
        ),
        if (_error != null) OgErrorText(_error!),
        ResendTimer(onResend: _resend),
      ],
      bottom: [OgButton(label: 'Verify', loading: _busy, onPressed: _verify)],
    );
  }
}
