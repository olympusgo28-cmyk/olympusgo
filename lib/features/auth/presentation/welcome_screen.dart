import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.og;
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
        OgButton(
          label: 'Create account',
          onPressed: () => context.push(Routes.signUp),
        ),
        const SizedBox(height: 12),
        OgButton.outline(
          label: 'Log in',
          onPressed: () => context.push(Routes.logIn),
        ),
        const SizedBox(height: 20),
        Text(
          'By continuing you agree to the Terms of use and the Privacy policy.',
          textAlign: TextAlign.center,
          style: OgText.body(13, height: 1.4, color: c.textMuted),
        ),
      ],
    );
  }
}
