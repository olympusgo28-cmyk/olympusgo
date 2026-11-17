import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../providers.dart';
import 'og_kit.dart';

/// Whether private screens ask for Face ID. Demo mode doesn't, so a
/// simulator with no stack never asks for its passcode.
final faceIdAsksProvider = Provider<bool>((_) => Env.hasSupabase);

/// Asks for Face ID before a private screen builds (R-ACC-8, per screen since
/// the Account Centre went: owner, 9 Nov 2026, Q265). Until it passes, only
/// the screen's title and a spinner show, or a note and Try again.
class FaceIdLock extends ConsumerStatefulWidget {
  const FaceIdLock({
    super.key,
    required this.title,
    required this.reason,
    required this.child,
  });

  /// The locked screen's title.
  final String title;

  /// What the system prompt says the check is for ("Open your payment
  /// methods").
  final String reason;

  /// Built only once Face ID passes.
  final Widget child;

  @override
  ConsumerState<FaceIdLock> createState() => _FaceIdLockState();
}

class _FaceIdLockState extends ConsumerState<FaceIdLock> {
  bool? _unlocked;

  @override
  void initState() {
    super.initState();
    _unlock();
  }

  Future<void> _unlock() async {
    if (_unlocked == false) setState(() => _unlocked = null);
    final ok =
        !ref.read(faceIdAsksProvider) ||
        await ref.read(biometricVaultProvider).authenticate(widget.reason);
    if (mounted) setState(() => _unlocked = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked == true) return widget.child;
    return KitScaffold(
      header: KitHeader(title: widget.title),
      children: [
        if (_unlocked == false) ...[
          Semantics(
            liveRegion: true,
            child: const KitNote(
              'Face ID didn’t match, so this page stays locked.',
              tone: KitTone.warn,
            ),
          ),
          KitButton(label: 'Try again', onPressed: _unlock),
        ] else
          Semantics(
            label: 'Checking Face ID',
            child: const CupertinoActivityIndicator(),
          ),
      ],
    );
  }
}
