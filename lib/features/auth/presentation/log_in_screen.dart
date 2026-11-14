import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_screen.dart';
import 'saved_accounts.dart';

/// "Welcome": this phone's saved accounts, each opened with Face ID, and
/// "Use another profile" for log in by mobile, email or username. With no
/// saved accounts, log in by mobile opens instead (Q247).
class LogInScreen extends ConsumerStatefulWidget {
  const LogInScreen({super.key});

  /// Tiles shown before the list scrolls.
  static const visibleTiles = 3;

  @override
  ConsumerState<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends ConsumerState<LogInScreen> {
  bool _left = false;

  void _useAnother({bool replace = false}) {
    if (replace) {
      if (_left) return;
      _left = true;
      context.pushReplacement(Routes.logInMobile);
    } else {
      context.push(Routes.logInMobile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(savedAccountsProvider);
    final list = accounts.value ?? const [];
    // Nothing saved, or the last tile was removed: go straight to log in.
    if (accounts.hasValue && list.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _useAnother(replace: true);
      });
    }
    const gap = 12.0;
    final tiles = [
      for (final (i, account) in list.indexed) ...[
        if (i > 0) const SizedBox(height: gap),
        AccountTile(account: account),
      ],
    ];
    return OgFlowScreen(
      children: [
        OgBackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.welcome),
        ),
        const OgHeading(title: 'Welcome'),
        const SizedBox(height: 24),
        if (list.length > LogInScreen.visibleTiles)
          // Half of the next tile shows, so it is clear the list scrolls.
          SizedBox(
            height:
                LogInScreen.visibleTiles * (AccountTile.height + gap) +
                AccountTile.height / 2,
            child: ListView(padding: EdgeInsets.zero, children: tiles),
          )
        else
          ...tiles,
      ],
      bottom: [
        OgButton.outline(
          label: 'Use another profile',
          onPressed: () => _useAnother(),
        ),
        const SizedBox(height: 20),
        const LegalLine(),
      ],
    );
  }
}

/// "By continuing you agree to the Terms of use and the Privacy policy."
class LegalLine extends StatelessWidget {
  const LegalLine({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final link = context.type.button.copyWith(color: c.link);
    return Semantics(
      button: true,
      label: 'Read the Terms of use and the Privacy policy',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(Routes.legal),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: ExcludeSemantics(
              child: Text.rich(
                TextSpan(
                  text: 'By continuing you agree to the ',
                  children: [
                    TextSpan(text: 'Terms of use', style: link),
                    const TextSpan(text: ' and the '),
                    TextSpan(text: 'Privacy policy', style: link),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: context.type.caption.copyWith(height: 1.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
