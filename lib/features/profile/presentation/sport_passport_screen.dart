import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_layout.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/settings_list.dart';
import '../../clubs/domain/club_sport.dart';
import '../../guardian/application/route_access.dart';
import '../../onboarding/domain/sport.dart';

/// The Sport Passport, opened from the namecard button on Profile: the
/// player's sports, each opening its Passport, and their sport profile
/// (owner, 9 Nov 2026). Lessons live in the schedule, clubs on Home.
class SportPassportScreen extends ConsumerWidget {
  const SportPassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sports = ref.watch(mySportsProvider);
    final sessions = ref.watch(mySummaryProvider).value?.sessions ?? 0;
    final can = routeAccess(ref);
    void open(String route) => context.push(route);

    final failed = sports.hasError && !sports.isLoading && !sports.hasValue;
    final list = sports.value ?? const [];
    final yourSports = SettingsSection(
      label: 'Your sports',
      rows: [
        if (sports.hasValue)
          for (final s in list)
            if (can(Routes.passportFor(s.sport)))
              SettingsRow(
                icon: Sport.fromId(s.sport).icon,
                label: Sport.fromId(s.sport).label,
                value: SkillBand.forLevel(s.level).code,
                semanticValue: SkillBand.forLevel(s.level).label,
                onTap: () => open(Routes.passportFor(s.sport)),
              ),
        if (can(Routes.profileSports))
          SettingsRow(
            icon: OgIcons.racquet,
            label: 'Sports and levels',
            isLoading: !sports.hasValue,
            emptyText: list.isEmpty ? 'Add' : null,
            semanticHint: list.isEmpty ? 'Adds your sports' : null,
            onTap: () => open(Routes.profileSports),
          ),
      ],
    );
    final sportProfile = SettingsSection(
      label: 'Sport profile',
      rows: [
        if (can(Routes.passport))
          SettingsRow(
            icon: OgIcons.trophy,
            label: 'Sessions and rating',
            value: sessions == 0 ? null : '$sessions',
            onTap: () => open(Routes.passport),
          ),
        if (can(Routes.creatorChallenges))
          SettingsRow(
            icon: OgIcons.trophyCup,
            label: 'Challenges',
            onTap: () => open(Routes.creatorChallenges),
          ),
        if (can(Routes.gear))
          SettingsRow(
            icon: OgIcons.racquetStrings,
            label: 'My gear',
            onTap: () => open(Routes.gear),
          ),
        if (can(Routes.shareProfile))
          SettingsRow(
            icon: OgIcons.shareUp,
            label: 'Share profile',
            onTap: () => open(Routes.shareProfile),
          ),
      ],
    );

    return KitScaffold(
      header: KitHeader(
        title: 'Sport Passport',
        background: context.og.groupedBg,
      ),
      background: context.og.groupedBg,
      padding: const EdgeInsets.only(top: OgSpace.s2, bottom: OgSpace.s8),
      gap: 0,
      children: [
        ReadableWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (failed) ...[
                const SizedBox(height: OgSpace.s4),
                SettingsLoadError(
                  message:
                      "We couldn't load your sports. Check your connection, "
                      'then try again.',
                  onRetry: () => ref.invalidate(mySportsProvider),
                ),
                const SizedBox(height: OgSpace.s6),
              ],
              SettingsList(sections: [if (!failed) yourSports, sportProfile]),
            ],
          ),
        ),
      ],
    );
  }
}
