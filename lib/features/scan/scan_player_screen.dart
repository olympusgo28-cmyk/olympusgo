import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/og_buttons.dart';
import '../../core/widgets/og_screen.dart';
import '../../core/widgets/og_toast.dart';
import '../auth/data/auth_repository.dart';
import '../onboarding/domain/sport.dart';
import '../social/application/social_providers.dart';
import '../social/domain/social_models.dart';

final _scannedProvider = FutureProvider.autoDispose
    .family<PlayerDetail?, String>((ref, username) async {
      final summary = await ref
          .watch(socialRepositoryProvider)
          .byUsername(username);
      if (summary == null) return null;
      return ref.watch(playerDetailProvider(summary.id).future);
    });

/// "Player found" after scanning someone's OlympusGO code.
class ScanPlayerScreen extends ConsumerWidget {
  const ScanPlayerScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final result = ref.watch(_scannedProvider(username));
    final detail = result.value;
    final following =
        detail != null &&
        (ref.watch(myFollowingProvider).value?.contains(detail.player.id) ??
            false);

    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        OgHeading(
          title: detail == null && result.hasValue
              ? 'No player found'
              : 'Player found',
          topGap: 8,
          lead: detail == null && result.hasValue
              ? "That code doesn't match an OlympusGO player."
              : 'Scanned from their OlympusGO code.',
        ),
        if (result.isLoading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: CupertinoActivityIndicator(),
          ),
        if (detail != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.border, width: 2),
            ),
            child: Column(
              children: [
                Avatar(
                  initials: detail.player.initials,
                  tone: AvatarTone.forId(detail.player.id),
                  imageUrl: detail.player.avatarUrl,
                  size: 96,
                  fontSize: 34,
                ),
                const SizedBox(height: 14),
                Text(
                  detail.player.displayName,
                  style: OgText.display(26, color: c.text),
                ),
                Text(
                  detail.player.handle,
                  style: OgText.body(15, color: c.textMuted),
                ),
                if (detail.showLevel && detail.sports.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final s in detail.sports)
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: c.border, width: 2),
                          ),
                          child: Text(
                            '${Sport.fromId(s.sport).label} ${s.level.toStringAsFixed(1)}',
                            style: OgText.body(
                              14,
                              weight: FontWeight.w600,
                              color: c.text,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (following)
            OgButton.outline(
              label: 'Following',
              onPressed: () => _toggle(context, ref, detail.player.id),
            )
          else
            OgButton(
              label: 'Follow',
              onPressed: () => _toggle(context, ref, detail.player.id),
            ),
          const SizedBox(height: 10),
          OgButton.outline(
            label: 'View profile',
            height: 52,
            fontSize: 18,
            onPressed: () => context.push(Routes.player(detail.player.id)),
          ),
          const SizedBox(height: 10),
          OgButton.outline(
            label: 'Message',
            height: 52,
            fontSize: 18,
            onPressed: () =>
                context.push(Routes.messagePlayer(detail.player.id)),
          ),
        ],
      ],
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(myFollowingProvider.notifier).toggle(id);
    } on AuthFailure catch (e) {
      if (context.mounted) showOgToast(context, e.message, error: true);
    }
  }
}
