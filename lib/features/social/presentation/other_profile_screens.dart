import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../onboarding/domain/sport.dart';
import '../application/social_providers.dart';
import '../domain/social_models.dart';

/// Another player's profile: follow, message, report or block.
class OtherProfileScreen extends ConsumerWidget {
  const OtherProfileScreen({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final detail = ref.watch(playerDetailProvider(playerId));
    final iFollow =
        ref.watch(myFollowingProvider).value?.contains(playerId) ?? false;

    Widget stat(String value, String label) => Column(
      children: [
        Text(value, style: OgText.display(22, color: c.text)),
        Text(label, style: OgText.body(13, color: c.textMuted)),
      ],
    );

    return OgFlowScreen(
      asPage: true,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const OgBackButton(),
            Pressable(
              onPressed: () => context.push(Routes.reportPlayer(playerId)),
              semanticLabel: 'More',
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(child: OgIcon(OgIcons.more, color: c.text)),
              ),
            ),
          ],
        ),
        ...switch (detail) {
          AsyncData(:final value) => _body(context, ref, value, iFollow, stat),
          AsyncError() => [
            const SizedBox(height: 40),
            Text(
              "This profile isn't available.",
              textAlign: TextAlign.center,
              style: OgText.lead(c.textMuted),
            ),
          ],
          _ => [
            const SizedBox(height: 120),
            const CupertinoActivityIndicator(),
          ],
        },
      ],
    );
  }

  List<Widget> _body(
    BuildContext context,
    WidgetRef ref,
    PlayerDetail d,
    bool iFollow,
    Widget Function(String, String) stat,
  ) {
    final c = context.og;
    final p = d.player;
    final followers =
        d.social.followers +
        (iFollow && !d.social.iFollow ? 1 : 0) -
        (!iFollow && d.social.iFollow ? 1 : 0);
    return [
      const SizedBox(height: 4),
      Center(
        child: Avatar(
          initials: p.initials,
          tone: AvatarTone.forId(p.id),
          imageUrl: p.avatarUrl,
          size: 104,
          fontSize: 38,
        ),
      ),
      const SizedBox(height: 12),
      Semantics(
        header: true,
        child: Text(
          p.displayName,
          textAlign: TextAlign.center,
          style: OgText.display(28, color: c.text),
        ),
      ),
      Text(
        [if (p.username != null) p.handle, d.country.name].join(' · '),
        textAlign: TextAlign.center,
        style: OgText.body(15, color: c.textMuted),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          stat('${d.social.following}', 'Following'),
          const SizedBox(width: 36),
          stat('$followers', 'Followers'),
          const SizedBox(width: 36),
          stat('${d.played}', 'Played'),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: iFollow
                ? OgButton.outline(
                    label: 'Following',
                    height: 52,
                    fontSize: 18,
                    onPressed: () => _toggle(context, ref),
                  )
                : OgButton(
                    label: d.social.followsMe ? 'Follow back' : 'Follow',
                    height: 52,
                    fontSize: 18,
                    onPressed: () => _toggle(context, ref),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OgButton.outline(
              label: 'Message',
              height: 52,
              fontSize: 18,
              onPressed: () => context.push(Routes.messagePlayer(p.id)),
            ),
          ),
        ],
      ),
      if (d.bio != null && d.bio!.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(d.bio!, style: OgText.body(15, height: 1.45, color: c.text)),
      ],
      if (d.sports.isNotEmpty) ...[
        const SectionLabel('Sports and levels', top: 22, size: 13),
        for (final s in d.sports)
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border, width: 2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    Sport.fromId(s.sport).label,
                    style: OgText.body(
                      16,
                      weight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ),
                Text(
                  d.showLevel
                      ? 'Level ${s.level.toStringAsFixed(1)}'
                      : 'Level hidden',
                  style: OgText.body(16, color: c.textMuted),
                ),
              ],
            ),
          ),
      ],
    ];
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(myFollowingProvider.notifier).toggle(playerId);
    } on AuthFailure catch (e) {
      if (context.mounted) showOgToast(context, e.message, error: true);
    }
  }
}

/// Report a player, or block them.
class ReportBlockScreen extends ConsumerStatefulWidget {
  const ReportBlockScreen({super.key, required this.playerId});

  final String playerId;

  @override
  ConsumerState<ReportBlockScreen> createState() => _ReportBlockScreenState();
}

class _ReportBlockScreenState extends ConsumerState<ReportBlockScreen> {
  ReportReason _reason = ReportReason.harassment;
  bool _sending = false;

  String get _name =>
      ref
          .read(playerDetailProvider(widget.playerId))
          .value
          ?.player
          .displayName ??
      'this player';

  Future<void> _report() async {
    setState(() => _sending = true);
    try {
      await ref.read(socialRepositoryProvider).report(widget.playerId, _reason);
      if (!mounted) return;
      showOgToast(context, "Thanks. We'll review your report.");
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _block() async {
    final name = _name;
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Block $name?'),
        content: const Text(
          "They won't be able to see your profile, message you or join your Meets.",
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(blockedPlayersProvider.notifier).block(widget.playerId);
      if (!mounted) return;
      showOgToast(context, '$name is blocked');
      context.go(Routes.blocked);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        ref
            .watch(playerDetailProvider(widget.playerId))
            .value
            ?.player
            .displayName ??
        'This player';
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        OgHeading(
          title: 'Report or block',
          topGap: 8,
          lead: '$name will not be told who reported them.',
        ),
        const SectionLabel('Reason', top: 22, size: 13),
        for (final r in ReportReason.values)
          RadioRow(
            label: r.label,
            selected: r == _reason,
            onTap: () => setState(() => _reason = r),
          ),
      ],
      bottom: [
        OgButton(label: 'Send report', loading: _sending, onPressed: _report),
        const SizedBox(height: 10),
        OgButton.outline(
          label: 'Block $name',
          height: 52,
          fontSize: 18,
          onPressed: _block,
        ),
      ],
    );
  }
}
