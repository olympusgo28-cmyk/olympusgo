import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_money/og_money.dart';

import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_kit.dart';
import '../../auth/data/auth_repository.dart';
import '../application/game_providers.dart';
import '../domain/game_models.dart';

Widget? _waiting(AsyncValue<Object?> v, String title, VoidCallback retry) {
  if (v.hasValue) return null;
  return KitScaffold(
    header: KitHeader(title: title),
    children: v.hasError
        ? [
            KitNote(
              v.error is AuthFailure
                  ? (v.error! as AuthFailure).message
                  : 'Can’t load this right now. Check your connection.',
              tone: KitTone.warn,
            ),
            KitButton(label: 'Try again', onPressed: retry),
          ]
        : const [CupertinoActivityIndicator()],
  );
}

/// Vouchers earned from organizing and campaigns. The code is only ever shown
/// here, to its owner.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final v = ref.watch(myVouchersProvider);
    final badges = ref.watch(myBadgesProvider).value ?? const <GameBadge>[];
    final blocked = _waiting(
      v,
      'My vouchers',
      () => ref.invalidate(myVouchersProvider),
    );
    if (blocked != null) return blocked;
    final list = v.requireValue;
    return KitScaffold(
      header: const KitHeader(title: 'My vouchers'),
      children: [
        if (list.isEmpty)
          Text(
            'No vouchers yet. You earn them from counted games and campaigns.',
            style: OgText.body(14, height: 1.4, color: c.textMuted),
          ),
        for (final x in list) _VoucherCard(x),
        if (list.isNotEmpty)
          const KitNote(
            'Vouchers stay on your account and can’t be passed on. Use them at '
            'checkout, one per item, in place of points.',
          ),
        if (badges.isNotEmpty)
          KitBlock(
            title: 'My badges',
            child: KitCheckList([for (final b in badges) b.name]),
          ),
      ],
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard(this.v);

  final GameVoucher v;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final (label, fill, ink) = switch (v.status) {
      'issued' => ('Ready to use', t.successFill, t.onSuccessFill),
      'held' => ('Opens with court booking', t.warnFill, t.onWarnFill),
      'used' => ('Used', t.tag, t.onTag),
      _ => ('Expired', t.tag, t.onTag),
    };
    return KitCard(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    v.name,
                    style: OgText.body(16, weight: FontWeight.w600),
                  ),
                ),
                Text('${Money(v.amountCents)} off', style: OgText.body(14)),
              ],
            ),
            Text(
              [
                if (v.product case final p?) '$p at ${v.where}' else v.where,
                if (v.usable && v.expiresAt != null)
                  'Use by ${Fmt.day(v.expiresAt!)}',
              ].join(' · '),
              style: OgText.body(13, color: c.textMuted),
            ),
            const SizedBox(height: 8),
            KitTag(label, background: fill, foreground: ink),
            if (v.usable) ...[
              const SizedBox(height: 8),
              Semantics(
                label: 'Voucher code ${v.code.split('').join(' ')}',
                excludeSemantics: true,
                child: Text(v.code, style: OgText.body(14, letterSpacing: 1)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Counted games and the next reward. Games that didn't count say why.
class OrganizerRewardsScreen extends ConsumerWidget {
  const OrganizerRewardsScreen({super.key});

  String _prize(int a, int b) => [
    if (a > 0) plural(a, 'shop voucher'),
    if (b > 0) plural(b, 'court voucher'),
  ].join(' and ');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final v = ref.watch(organizerRewardsProvider);
    final blocked = _waiting(
      v,
      'Organizer rewards',
      () => ref.invalidate(organizerRewardsProvider),
    );
    if (blocked != null) return blocked;
    final r = v.requireValue;
    return KitScaffold(
      header: const KitHeader(title: 'Organizer rewards'),
      children: [
        KitTitle(
          plural(r.counted, 'counted game'),
          size: 28,
          lead: r.nextGame == null
              ? null
              : 'Game ${r.nextGame} earns ${_prize(r.nextA, r.nextB)}.',
        ),
        if (r.waiting > 0)
          KitNote(
            r.open
                ? '${plural(r.waiting, 'voucher')} waiting. Our team is '
                      'setting them up.'
                : '${plural(r.waiting, 'voucher')} waiting. They’re issued as '
                      'soon as rewards open.',
          ),
        KitNote(
          'A game counts when ${r.minPresent} or more players are Present, '
          'every player paid the platform fee, and every player was scanned '
          'in by QR. You don’t have to pay or play yourself. To count towards '
          'the ${r.minPresent}, take a spot for the ${Money(r.feeCents)} fee.',
        ),
        if (r.games.isEmpty)
          Text(
            'Your Meets show up here once their money has settled.',
            style: OgText.body(14, color: c.textMuted),
          )
        else
          KitCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            children: [
              for (final g in r.games)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.title,
                        style: OgText.body(15, weight: FontWeight.w600),
                      ),
                      Text(
                        [
                          Fmt.day(g.at),
                          if (g.gameNo != null) 'Game ${g.gameNo}' else g.why,
                        ].join(' · '),
                        style: OgText.body(13, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        KitButton.outline(
          label: 'My vouchers',
          onPressed: () => context.push(Routes.wallet),
        ),
      ],
    );
  }
}
