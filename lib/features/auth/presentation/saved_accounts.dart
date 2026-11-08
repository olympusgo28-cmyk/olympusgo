import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_toast.dart';
import '../data/auth_repository.dart';
import '../domain/saved_account.dart';

part 'saved_accounts.g.dart';

/// Accounts this phone can open with Face ID. Empty unless Face ID is on
/// (Q249).
@riverpod
Future<List<SavedAccount>> savedAccounts(Ref ref) =>
    ref.watch(authRepositoryProvider).savedAccounts();

/// A saved account. Tap to open it with Face ID; the cross removes it from
/// this phone, along with its token.
class AccountTile extends ConsumerWidget {
  const AccountTile({super.key, required this.account});

  /// Every tile is this tall, so a list of them can be sized exactly.
  static const height = 72.0;

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
      height: height,
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border.all(color: c.borderControl, width: 2),
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
                          mainAxisAlignment: MainAxisAlignment.center,
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
