import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_screen.dart';
import 'saved_accounts.dart';

/// The first screen when signed out. One way in: Log in shows this phone's
/// saved accounts, or log in by mobile when there are none (Q247).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final accounts = await ref
        .read(savedAccountsProvider.future)
        .catchError((_) => const <Never>[]);
    if (!context.mounted) return;
    context.push(accounts.isEmpty ? Routes.logInMobile : Routes.logIn);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    // Start reading the Keychain now, so Get started does not wait for it.
    ref.watch(savedAccountsProvider);
    return OgFlowScreen(
      fillGap: false,
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Mascot(
                  size: 220,
                  onDark: Theme.of(context).brightness == Brightness.dark,
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    'Find a game.\nJoin a Meet.',
                    textAlign: TextAlign.center,
                    style: OgText.display(36, color: c.text),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    'Play with people near you, keep your Passport, and grow your rating.',
                    textAlign: TextAlign.center,
                    style: OgText.lead(c.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      bottom: [
        OgButton(label: 'Get started', onPressed: () => _start(context, ref)),
      ],
    );
  }
}
