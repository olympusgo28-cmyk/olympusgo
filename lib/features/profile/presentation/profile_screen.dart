import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_money/og_money.dart' show pointsText;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/pressable.dart';
import '../../clubs/application/club_providers.dart';
import '../../earnings/application/earnings_providers.dart';
import '../../earnings/data/earnings_repository.dart';
import '../../home/home_rows.dart' show StatusScrim, nextLabel;
import '../../play/application/play_providers.dart';
import '../../play/domain/activity.dart';
import '../../shell/main_shell.dart';
import '../../social/application/social_providers.dart';
import '../application/past_sessions.dart';
import '../domain/profile.dart';
import 'account_switcher.dart';

/// Profile (redesigned 16 Nov 2026), top to bottom:
/// - the header row: the switch-account control at the left, the three icon
///   buttons at the right;
/// - the profile row: the avatar with an add button, and beside it the display
///   name over Following, Followers and Play counts;
/// - the bio row, then the links row;
/// - the body row: the player's past sessions, in Meet, Event and Tournament
///   pill tabs.
///
/// The Passport card is on the sport profile.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _kinds = [
    ('Meet', 'meet'),
    ('Event', 'event'),
    ('Tournament', 'tournament'),
  ];
  int _kind = 0;

  Future<void> _refresh() async {
    await ref.read(sessionProfileProvider.notifier).reload();
    ref.invalidate(mySportsProvider);
    ref.invalidate(mySummaryProvider);
    ref.invalidate(mySocialProvider);
    ref.invalidate(myPastSessionsProvider);
    ref.invalidate(myScheduleProvider);
    ref.invalidate(pointsSummaryProvider);
  }

  /// "Tonight 8:00 PM · Tampines Smashers", or the venue without a club.
  static String _sessionLine(Activity a, WidgetRef ref) {
    final club = a.clubId == null
        ? null
        : ref.watch(clubProvider(a.clubId!)).value?.name;
    final when = nextLabel(a.startsAt).replaceFirst(', ', ' ');
    return '$when · ${club ?? a.venue.name}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final profile = ref.watch(sessionProfileProvider).value;
    final summary = ref.watch(mySummaryProvider).value;
    final social = ref.watch(mySocialProvider).value;
    final past = ref.watch(myPastSessionsProvider);
    final wallet = ref.watch(pointsSummaryProvider).value;
    final upcoming = (ref.watch(myScheduleProvider).value ?? const <Activity>[])
        .take(3)
        .toList();
    final top = MediaQuery.of(context).padding.top;
    final (label, kind) = _kinds[_kind];
    final shown = [
      for (final i in past.value ?? const <HistoryItem>[])
        if (i.kind == kind) i,
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: StatusScrim(
        after: 0,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _refresh),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                top + 8,
                16,
                24 + MainTabBar.reservedHeight(context),
              ),
              sliver: SliverList.list(
                children: [
                  // Header row.
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AccountSwitchButton(
                            username: profile?.username ?? '',
                          ),
                        ),
                      ),
                      KitIconButton(
                        icon: OgIcons.scan,
                        label: 'My QR code',
                        size: 22,
                        strokeWidth: 1.9,
                        onPressed: () => context.push(Routes.shareProfile),
                      ),
                      KitIconButton(
                        icon: OgIcons.idCard,
                        label: 'Sport Passport',
                        size: 22,
                        strokeWidth: 1.9,
                        onPressed: () => context.push(Routes.sportPassport),
                      ),
                      // Everything that was the Account list lives in
                      // Settings and activity now.
                      KitIconButton(
                        icon: OgIcons.menu,
                        label: 'Settings and activity',
                        size: 22,
                        strokeWidth: 1.9,
                        onPressed: () => context.push(Routes.settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Profile row.
                  _ProfileRow(
                    profile: profile,
                    following: social?.following ?? 0,
                    followers: social?.followers ?? 0,
                    played: summary?.sessions ?? 0,
                  ),
                  const SizedBox(height: 12),
                  // Bio row.
                  _Bio(bio: profile?.bio),
                  // Links row.
                  if (profile != null && profile.links.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _Links(links: profile.links),
                  ],
                  // Points, badges and next sessions (owner, 16 Nov 2026).
                  if (wallet != null && wallet.worthShowing) ...[
                    const SizedBox(height: 20),
                    _PointsBanner(wallet: wallet),
                  ],
                  if (summary != null && summary.badges.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _Section(
                      title: 'Badges',
                      trailing: Text(
                        '${summary.badgeCount} earned',
                        style: context.type.caption,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final b in summary.badges) ...[
                                if (b != summary.badges.first)
                                  const SizedBox(width: 8),
                                _BadgeTile(b),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _Section(
                    title: 'Next sessions',
                    trailing: KitLink(
                      'Shown to: ${summary?.sessionsShownTo ?? 'Followers'} · Change',
                      size: 13,
                      onPressed: () => context.push(Routes.privacy),
                    ),
                    child: KitCard(
                      children: [
                        if (upcoming.isEmpty)
                          _ListRow(
                            title: 'Nothing booked',
                            subtitle: 'Find a Meet, tournament or event',
                            onTap: () => context.push(Routes.play),
                          ),
                        for (final a in upcoming)
                          _ListRow(
                            title: a.title,
                            subtitle: _sessionLine(a, ref),
                            onTap: () => context.push(Routes.activity(a.id)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Body row: past sessions.
                  PillTabs(
                    labels: [for (final k in _kinds) k.$1],
                    index: _kind,
                    onChanged: (i) => setState(() => _kind = i),
                  ),
                  const SizedBox(height: 12),
                  if (past.isLoading && !past.hasValue)
                    const SizedBox(height: 96)
                  else if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No past ${label}s yet',
                        textAlign: TextAlign.center,
                        style: context.type.secondary,
                      ),
                    )
                  else
                    KitCard(
                      children: [
                        for (final s in shown)
                          _SessionRow(
                            item: s,
                            onTap: () => context.push(Routes.activity(s.id)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The avatar with an orange add button at its bottom right, and beside it the
/// display name over the Following, Followers and Play counts.
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.profile,
    required this.following,
    required this.followers,
    required this.played,
  });

  final Profile? profile;
  final int following;
  final int followers;
  final int played;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1st column: the avatar and its add button.
        Pressable(
          semanticLabel: 'Change profile photo',
          onPressed: () => context.push(Routes.editProfile),
          child: SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Avatar(
                    initials: profile?.initials ?? '?',
                    tone: AvatarTone.brand,
                    imageUrl: profile?.avatarUrl,
                    size: 80,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: OgIcon(
                      OgIcons.plus,
                      size: 16,
                      color: c.onPrimary,
                      strokeWidth: 2.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 2nd column: the name, then the counts.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  profile?.fullName ?? profile?.username ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.title,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Count(
                    count: following,
                    label: 'Following',
                    onTap: () => context.push(Routes.connections()),
                  ),
                  const SizedBox(width: 20),
                  _Count(
                    count: followers,
                    label: 'Followers',
                    onTap: () =>
                        context.push(Routes.connections(followers: true)),
                  ),
                  const SizedBox(width: 20),
                  _Count(count: played, label: 'Play'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A number (section, Inter 17 Medium) over its label (caption, Inter 13
/// regular).
class _Count extends StatelessWidget {
  const _Count({required this.count, required this.label, this.onTap});

  final int count;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', style: context.type.section),
        Text(label, style: context.type.caption),
      ],
    );
    // A count with nothing to open is plain text, not a disabled button.
    if (onTap == null) {
      return Semantics(
        container: true,
        label: '$count $label',
        child: ExcludeSemantics(child: column),
      );
    }
    return Pressable(
      semanticLabel: '$count $label',
      onPressed: onTap,
      child: column,
    );
  }
}

/// The player's bio (Inter 15 regular), or an "Add a bio" prompt that opens
/// Edit profile.
class _Bio extends StatelessWidget {
  const _Bio({required this.bio});

  final String? bio;

  @override
  Widget build(BuildContext context) {
    final text = bio?.trim() ?? '';
    if (text.isEmpty) {
      return Pressable(
        semanticLabel: 'Add a bio',
        onPressed: () => context.push(Routes.editProfile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('Add a bio', style: context.type.secondary),
        ),
      );
    }
    return Text(
      text,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: context.type.body,
    );
  }
}

/// The player's links, each with a link icon (Inter 15 regular, link colour).
class _Links extends StatelessWidget {
  const _Links({required this.links});

  final List<String> links;

  static Uri _uri(String link) =>
      Uri.parse(link.contains('://') ? link : 'https://$link');

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        for (final l in links)
          Pressable(
            semanticLabel: 'Open link $l',
            onPressed: () => launchUrl(_uri(l)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OgIcon(OgIcons.link, size: 16, color: c.link),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l.replaceFirst(RegExp(r'^https?://'), ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.body.copyWith(color: c.link),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A past session: the title (Inter 15 regular), the day and how the games
/// went (Inter 13 regular), and a chevron.
class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.item, required this.onTap});

  final HistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final result = item.played == 0
        ? null
        : 'Won ${item.won} of ${item.played} '
              '${item.played == 1 ? 'game' : 'games'}';
    return _ListRow(
      title: item.title,
      subtitle: [Fmt.day(item.at), ?result].join(' · '),
      onTap: onTap,
    );
  }
}

/// A heading (section, Inter 17 Medium) with an optional note at the right,
/// over its content.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 32,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: context.type.section.copyWith(height: 1.2),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// A row in a card: a title (Inter 15 regular) over a line (Inter 13
/// regular), and a chevron.
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: '$title. $subtitle',
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: context.type.body),
                  const SizedBox(height: 1),
                  Text(subtitle, style: context.type.caption),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OgIcon(
              OgIcons.chevronRight,
              size: 20,
              strokeWidth: 2,
              color: const Color(0xFF9A9FA5),
            ),
          ],
        ),
      ),
    );
  }
}

/// The points the player has: the amount (Inter 15 regular), a line under it
/// (Inter 13 regular) and "Use points", on a peach card.
class _PointsBanner extends StatelessWidget {
  const _PointsBanner({required this.wallet});

  final PointsSummary wallet;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF7A3B00);
    return Pressable(
      semanticLabel: '${pointsText(wallet.minor)} points. Use points',
      onPressed: () => context.push(Routes.points),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE6D6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pointsText(wallet.minor)} points',
                    style: context.type.body.copyWith(color: ink),
                  ),
                  Text(
                    wallet.pendingMinor > 0
                        ? '${pointsText(wallet.pendingMinor)} more pending'
                        : wallet.earning
                        ? 'Earn points by playing'
                        : 'Use them in the Shop',
                    style: context.type.caption.copyWith(color: ink),
                  ),
                ],
              ),
            ),
            Text('Use points', style: context.type.body.copyWith(color: ink)),
          ],
        ),
      ),
    );
  }
}

/// A badge the player has earned: its mark in a 44-point avatar, and its name
/// (Inter 13 regular) under it.
class _BadgeTile extends StatelessWidget {
  const _BadgeTile(this.badge);

  final ProfileBadge badge;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          SolidAvatar(
            initials: badge.mark,
            color: Color(badge.color),
            ink: Color(badge.ink),
            size: 44,
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: context.type.caption.copyWith(height: 1.25),
          ),
        ],
      ),
    );
  }
}
