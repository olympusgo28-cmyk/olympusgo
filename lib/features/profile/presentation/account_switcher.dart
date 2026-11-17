import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/saved_account.dart';
import '../../auth/presentation/saved_accounts.dart';

/// The switch-account control at the left of Profile's header (owner, 16 Nov
/// 2026): a lock icon, the username and a dropdown icon. Tapping it opens a
/// bottom sheet with the accounts this phone can switch to.
class AccountSwitchButton extends ConsumerWidget {
  const AccountSwitchButton({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    return Pressable(
      semanticLabel: 'Switch account, $username',
      onPressed: () => showAccountSwitcher(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OgIcon(OgIcons.lock, size: 18, color: c.text, strokeWidth: 1.9),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.section,
              ),
            ),
            const SizedBox(width: 4),
            OgIcon(
              OgIcons.chevronDown,
              size: 18,
              color: c.text,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the sheet of accounts to switch to.
Future<void> showAccountSwitcher(BuildContext context) =>
    showKitSheet<void>(context, builder: (_) => const AccountSwitchSheet());

/// The accounts saved on this phone, the open one marked. Tapping another
/// opens it with Face ID, like its tile on the Welcome screen.
class AccountSwitchSheet extends ConsumerWidget {
  const AccountSwitchSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedAccountsProvider);
    final me = ref.watch(sessionProfileProvider).value;
    final accounts = saved.value ?? const <SavedAccount>[];
    // The open account leads, even when Face ID is off and it is not saved.
    final current = me == null
        ? null
        : accounts.where((a) => a.userId == me.id).firstOrNull ??
              SavedAccount(
                userId: me.id,
                displayName: me.fullName ?? me.username ?? 'You',
                avatarUrl: me.avatarUrl,
                maskedIdentifier: me.username == null ? '' : '@${me.username}',
              );
    final others = accounts.where((a) => a.userId != me?.id).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Switch account', style: context.type.section),
        ),
        const SizedBox(height: 8),
        if (current != null) _AccountRow(account: current, isCurrent: true),
        for (final a in others) _AccountRow(account: a, isCurrent: false),
        if (others.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No other accounts on this phone. Accounts you log in to with '
              'Face ID on show here.',
              style: context.type.secondary,
            ),
          ),
      ],
    );
  }
}

class _AccountRow extends ConsumerWidget {
  const _AccountRow({required this.account, required this.isCurrent});

  final SavedAccount account;
  final bool isCurrent;

  Future<void> _switch(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context);
    try {
      await ref.read(authRepositoryProvider).unlockAccount(account.userId);
      if (nav.mounted) nav.pop();
    } on AuthFailure catch (e) {
      if (!context.mounted) return;
      showOgToast(context, e.message, error: true);
      ref.invalidate(savedAccountsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final initials = account.displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final row = Container(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          Avatar(
            initials: initials.isEmpty ? '?' : initials,
            imageUrl: account.avatarUrl,
            tone: AvatarTone.brand,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(account.displayName, style: context.type.body),
                if (account.maskedIdentifier.isNotEmpty)
                  Text(account.maskedIdentifier, style: context.type.caption),
              ],
            ),
          ),
          if (isCurrent)
            OgIcon(OgIcons.check, size: 22, color: c.primary, strokeWidth: 2.4),
        ],
      ),
    );
    final label = isCurrent
        ? '${account.displayName}, current account'
        : 'Switch to ${account.displayName}';
    // The open account is not a button, so it is not dimmed like one.
    if (isCurrent) return Semantics(label: label, selected: true, child: row);
    return Pressable(
      semanticLabel: label,
      onPressed: () => _switch(context, ref),
      child: row,
    );
  }
}
