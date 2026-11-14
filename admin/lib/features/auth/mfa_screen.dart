import 'package:flutter/material.dart';
import 'package:og_design/og_design.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Staff get no data until this is done. First time: enrol an authenticator
/// app. After that: enter its 6-digit code.
class MfaScreen extends StatefulWidget {
  const MfaScreen({super.key});

  @override
  State<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends State<MfaScreen> {
  final _code = TextEditingController();
  GoTrueMFAApi get _mfa => Supabase.instance.client.auth.mfa;
  String? _factorId;
  String? _secret;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final factors = await _mfa.listFactors();
    final verified = factors.totp.where(
      (f) => f.status == FactorStatus.verified,
    );
    if (verified.isNotEmpty) {
      setState(() => _factorId = verified.first.id);
      return;
    }
    for (final stale in factors.totp) {
      await _mfa.unenroll(stale.id);
    }
    final enrolled = await _mfa.enroll(issuer: 'OlympusGO staff');
    setState(() {
      _factorId = enrolled.id;
      _secret = enrolled.totp?.secret;
    });
  }

  Future<void> _verify() async {
    final id = _factorId;
    if (id == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _mfa.challengeAndVerify(factorId: id, code: _code.text.trim());
    } on AuthException {
      if (mounted) setState(() => _error = "That code didn't work.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Two-step sign-in', style: OgText.h1),
            const SizedBox(height: 12),
            if (_secret != null) ...[
              Text(
                'Add this key to your authenticator app, then enter the code '
                'it shows.',
                style: OgText.lead(context.og.textMuted),
              ),
              const SizedBox(height: 12),
              SelectableText(_secret!, style: OgText.body(16)),
            ] else
              Text(
                'Enter the code from your authenticator app.',
                style: OgText.lead(context.og.textMuted),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _verify(),
              decoration: const InputDecoration(labelText: '6-digit code'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: OgText.body(14, color: context.og.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: const Text('Continue'),
            ),
            TextButton(
              onPressed: () => Supabase.instance.client.auth.signOut(),
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    ),
  );
}
