import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../data/auth_repository.dart';
import '../domain/saved_account.dart';

part 'welcome_screen.g.dart';

@riverpod
Future<List<SavedAccount>> savedAccounts(Ref ref) =>
    ref.watch(authRepositoryProvider).savedAccounts();

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final accounts = ref.watch(savedAccountsProvider).value ?? const [];
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
        for (final account in accounts) ...[
          _AccountTile(account: account),
          const SizedBox(height: 12),
        ],
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
        Semantics(
          button: true,
          label: 'Read the Terms of use and the Privacy policy',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(Routes.legal),
            child: Text.rich(
              TextSpan(
                text: 'By continuing you agree to the ',
                children: [
                  TextSpan(
                    text: 'Terms of use',
                    style: OgText.body(
                      13,
                      weight: FontWeight.w600,
                      color: c.link,
                    ),
                  ),
                  const TextSpan(text: ' and the '),
                  TextSpan(
                    text: 'Privacy policy',
                    style: OgText.body(
                      13,
                      weight: FontWeight.w600,
                      color: c.link,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: OgText.body(13, height: 1.4, color: c.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}

/// A saved account. Tap to open it with Face ID; the cross removes it from
/// this phone, along with its token.
class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account});

  final SavedAccount account;

  Future<void> _unlock(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).unlockAccount(account.userId);
    } on AuthFailure catch (e) {
      if (!context.mounted) return;
      showOgToast(context, e.message, error: true);
      ref.invalidate(savedAccountsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border.all(color: c.borderControl),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Log in as ${account.displayName}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _unlock(context, ref),
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Avatar(
                        initials: account.displayName
                            .trim()
                            .split(RegExp(r'\s+'))
                            .take(2)
                            .map((w) => w[0].toUpperCase())
                            .join(),
                        imageUrl: account.avatarUrl,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              account.displayName,
                              style: OgText.body(
                                16,
                                weight: FontWeight.w600,
                                color: c.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              account.maskedIdentifier,
                              style: OgText.body(13, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Remove ${account.displayName} from this phone',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await ref
                    .read(authRepositoryProvider)
                    .forgetAccount(account.userId);
                ref.invalidate(savedAccountsProvider);
              },
              child: ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: OgIcon(OgIcons.close, size: 20, color: c.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
