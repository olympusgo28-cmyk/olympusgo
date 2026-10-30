import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../application/club_providers.dart';

/// The most active public groups, by counted games. No player is named here.
class GroupRankScreen extends ConsumerWidget {
  const GroupRankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    return KitScaffold(
      header: const KitHeader(title: 'Most active groups'),
      children: [
        Text(
          'Ranked on games with 6 or more players checked in by QR, over the '
          'last 90 days.',
          style: OgText.lead(c.textMuted),
        ),
        ...ref
            .watch(groupRankingProvider)
            .when(
              loading: () => const [CupertinoActivityIndicator()],
              error: (_, _) => const [
                KitNote(
                  "Can't load this right now. Try again.",
                  tone: KitTone.warn,
                ),
              ],
              data: (list) => list.isEmpty
                  ? [
                      DashedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No groups are ranked yet.',
                            style: OgText.lead(c.textMuted),
                          ),
                        ),
                      ),
                    ]
                  : [
                      KitCard(
                        children: [
                          for (final (i, g) in list.indexed)
                            KitNavTile(
                              icon: OgIcons.group,
                              title: '${g.rank}. ${g.name}',
                              subtitle:
                                  '${g.games} ${g.games == 1 ? 'game' : 'games'}'
                                  '${g.area.isEmpty ? '' : ' · ${g.area}'}',
                              ruleAbove: i > 0,
                              onTap: () => context.push(Routes.club(g.clubId)),
                            ),
                        ],
                      ),
                    ],
            ),
      ],
    );
  }
}
