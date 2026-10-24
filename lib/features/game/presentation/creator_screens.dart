import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../shop/presentation/shop_screens.dart' show compact;
import '../../wallet/presentation/wallet_screens.dart' show cash, MoneyRow;
import '../application/game_providers.dart';
import 'game_screens.dart' show CampaignCard;

/// A creator's page: follow, the running challenge, videos and gear.
class CreatorProfileScreen extends ConsumerWidget {
  const CreatorProfileScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final cr = ref.watch(creatorProvider(id)).value;
    if (cr == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Creator'),
        children: [CupertinoActivityIndicator()],
      );
    }
    Widget stat(String big, String small) => Expanded(
      child: Column(
        children: [
          Text(big, style: OgText.heading(20)),
          Text(small, style: OgText.body(12, color: c.textMuted)),
        ],
      ),
    );
    final initials = cr.name.split(' ').map((w) => w[0]).take(2).join();
    return KitScaffold(
      header: KitHeader(title: 'Creator', crumb: cr.name),
      children: [
        Row(
          children: [
            SolidAvatar.forId(
              cr.id,
              initials: initials,
              size: 72,
              fontSize: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cr.name, style: OgText.heading(24)),
                  Text(
                    '${cr.handle} · ${cr.line}',
                    style: OgText.body(13, color: c.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      KitTag(
                        'Creator',
                        background: t.gold,
                        foreground: t.onGold,
                      ),
                      if (cr.verified)
                        KitTag(
                          'Verified coach',
                          background: t.successFill,
                          foreground: t.onSuccessFill,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: KitButton(
                label: cr.following ? 'Following' : 'Follow',
                style: cr.following
                    ? KitButtonStyle.outline
                    : KitButtonStyle.primary,
                height: 46,
                onPressed: () async {
                  await ref
                      .read(gameRepositoryProvider)
                      .followCreator(cr.id, !cr.following);
                  HapticFeedback.selectionClick();
                  ref.invalidate(creatorProvider(id));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KitButton(
                label: 'Message',
                style: KitButtonStyle.outline,
                height: 46,
                onPressed: () => showOgToast(
                  context,
                  'Creators reply to messages from followers.',
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            stat(compact(cr.followers), 'followers'),
            stat('${cr.videos}', 'videos'),
            stat('${cr.challenges}', 'challenges'),
          ],
        ),
        if (cr.running != null) ...[
          Text('Running now', style: OgText.heading(20)),
          CampaignCard(c: cr.running!),
        ],
        Text('Videos', style: OgText.heading(20)),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.75,
          children: [
            for (final v in cr.videoViews)
              Pressable(
                semanticLabel: 'Video, ${compact(v)} views',
                onPressed: () => context.push(Routes.shopVideo('v1')),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.bottomLeft,
                  decoration: BoxDecoration(
                    color: OgColors.ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.play_fill,
                        size: 12,
                        color: Color(0xFFFFFFFF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        compact(v),
                        style: OgText.body(
                          12,
                          weight: FontWeight.w700,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (cr.gear.isNotEmpty) ...[
          Text('Gear he uses', style: OgText.heading(20)),
          KitCard(
            children: [
              for (final (name, sub, price) in cr.gear)
                MoneyRow(
                  title: name,
                  sub: sub,
                  amount: price,
                  onTap: () => context.push(Routes.product('p-racket')),
                ),
            ],
          ),
        ],
        if (cr.academy != null) ...[
          Text('Train with him', style: OgText.heading(20)),
          KitCard(
            children: [
              KitNavTile(
                icon: OgIcons.academy,
                title: cr.academy!,
                subtitle: cr.academyLine,
                onTap: () => context.push(Routes.academies),
              ),
            ],
          ),
        ],
        Row(
          children: [
            KitLink(
              'Report or block',
              color: c.textMuted,
              onPressed: () =>
                  context.push(Routes.reportListing('Creator: ${cr.name}')),
            ),
            const Spacer(),
            KitLink(
              'Community rules',
              color: c.textMuted,
              onPressed: () => context.push(Routes.help),
            ),
          ],
        ),
      ],
    );
  }
}

/// What the creator earned from tagged gear, sponsors and referrals.
class CreatorEarningsScreen extends ConsumerWidget {
  const CreatorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final e = ref.watch(creatorEarningsProvider).value;
    if (e == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Creator earnings'),
        children: [CupertinoActivityIndicator()],
      );
    }
    Widget tile(String big, String small) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: t.tag,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(big, style: OgText.heading(20)),
            Text(
              small,
              textAlign: TextAlign.center,
              style: OgText.body(12, color: t.onTag),
            ),
          ],
        ),
      ),
    );
    return KitScaffold(
      header: const KitHeader(title: 'Creator earnings'),
      bottom: [
        KitButton(
          label: 'Pay out now',
          onPressed: () => context.push(Routes.payout),
        ),
        KitButton(
          label: 'Start a challenge',
          style: KitButtonStyle.outline,
          onPressed: () => context.push(Routes.newChallenge),
        ),
      ],
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OgColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'READY TO PAY OUT',
                style: OgText.body(
                  12,
                  weight: FontWeight.w800,
                  color: t.gold,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                cash(e.readyCents),
                style: OgText.heading(44, color: const Color(0xFFFFFFFF)),
              ),
              Text(
                'From gear you tagged, challenges and your academy link.',
                style: OgText.body(14, color: const Color(0xFFC9C6BC)),
              ),
            ],
          ),
        ),
        Row(
          children: [
            tile(compact(e.views), 'views, 30 days'),
            const SizedBox(width: 8),
            tile('${e.sold}', 'items sold'),
            const SizedBox(width: 8),
            tile('${e.students}', 'new students'),
          ],
        ),
        Text('Where it came from', style: OgText.heading(20)),
        KitCard(
          children: [
            for (final (title, sub, cents) in e.sources)
              MoneyRow(title: title, sub: sub, amount: cash(cents), good: true),
          ],
        ),
        Text('Best videos', style: OgText.heading(20)),
        KitCard(
          children: [
            for (final (title, sub, cents) in e.videos)
              MoneyRow(title: title, sub: sub, amount: cash(cents)),
          ],
        ),
        Text(
          'You earn 5% when someone buys an item within 7 days of watching your video. Rates are set by each shop.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

/// The creator's challenges, and the follower threshold.
class CreatorChallengesScreen extends ConsumerWidget {
  const CreatorChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final s = ref.watch(creatorStatusProvider).value;
    if (s == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Challenges'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final below = s.followers < s.threshold;
    return KitScaffold(
      header: const KitHeader(title: 'Challenges'),
      bottom: [
        KitButton(
          label: 'New challenge',
          icon: OgIcons.plus,
          onPressed: s.unlocked
              ? () => context.push(Routes.newChallenge)
              : null,
        ),
        KitButton(
          label: 'Creator earnings',
          style: KitButtonStyle.outline,
          onPressed: () => context.push(Routes.creatorEarnings),
        ),
      ],
      children: [
        if (below)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.warnFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.graceEnds == null
                      ? 'Challenges unlock at ${s.threshold} followers'
                      : 'Creator access ends ${Fmt.day(s.graceEnds!)}',
                  style: OgText.body(
                    15,
                    weight: FontWeight.w800,
                    color: t.onWarnFill,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.graceEnds == null
                      ? 'Keep posting clips and playing. Followers who join your Meets count.'
                      : 'You are below ${s.threshold} followers. Challenges stay on for 30 days. Get back to ${s.threshold} to keep them.',
                  style: OgText.body(13, height: 1.4, color: t.onWarnFill),
                ),
                const SizedBox(height: 10),
                Text(
                  '${s.followers} of ${s.threshold} followers · ${s.threshold - s.followers} to go',
                  style: OgText.body(
                    13,
                    weight: FontWeight.w700,
                    color: t.onWarnFill,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: s.followers / s.threshold,
                    minHeight: 10,
                    backgroundColor: const Color(0x33000000),
                    color: OgColors.ink,
                  ),
                ),
                if (s.graceEnds != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${s.graceEnds!.difference(DateTime.now()).inDays} days left',
                    style: OgText.body(12, color: t.onWarnFill),
                  ),
                ],
              ],
            ),
          ),
        Text('Your challenges', style: OgText.heading(20)),
        if (s.mine.isEmpty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No challenges yet. Set a goal for your followers: they join, play and post their results.',
                style: OgText.body(14, height: 1.4, color: c.textMuted),
              ),
            ),
          )
        else
          for (final x in s.mine) CampaignCard(c: x),
      ],
    );
  }
}

/// Set a goal for followers.
class NewChallengeScreen extends ConsumerStatefulWidget {
  const NewChallengeScreen({super.key});

  @override
  ConsumerState<NewChallengeScreen> createState() => _NewChallengeScreenState();
}

class _NewChallengeScreenState extends ConsumerState<NewChallengeScreen> {
  final _title = TextEditingController();
  final _goal = TextEditingController();
  final _reward = TextEditingController();
  String _sport = 'Badminton';
  int _days = 7;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _goal.dispose();
    _reward.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_title.text.trim().length < 4 || _goal.text.trim().isEmpty) {
      showOgToast(context, 'Add a title and the goal.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final x = await ref
          .read(gameRepositoryProvider)
          .createChallenge(
            title: _title.text.trim(),
            sport: _sport,
            days: _days,
            goal: _goal.text.trim(),
            reward: _reward.text.trim(),
          );
      HapticFeedback.mediumImpact();
      refreshGame(ref.invalidate);
      if (!mounted) return;
      showOgToast(context, 'Challenge published');
      context.pushReplacement(Routes.campaign(x.id));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final s = ref.watch(creatorStatusProvider).value;
    return KitScaffold(
      header: const KitHeader(title: 'New challenge'),
      bottom: [
        KitButton(
          label: 'Publish challenge',
          loading: _busy,
          onPressed: _publish,
        ),
      ],
      children: [
        KitTag(
          'CREATOR FEATURE · 1,000+ FOLLOWERS',
          background: t.gold,
          foreground: t.onGold,
        ),
        const KitTitle(
          'New challenge',
          lead: 'Set a goal for your followers. They join, play and post their results.',
        ),
        if (s != null && s.followers < s.threshold && s.graceEnds != null)
          KitNote(
            'Creator access ends ${Fmt.day(s.graceEnds!)}. You are below ${s.threshold} followers. Challenges stay on for 30 days.',
            tone: KitTone.warn,
          ),
        KitInput(
          label: 'Challenge title',
          controller: _title,
          hint: 'Win 5 doubles matches in 14 days',
          maxLength: 60,
        ),
        Text('Sport', style: OgText.body(15, weight: FontWeight.w700)),
        KitSegments(
          labels: const ['Badminton', 'Pickleball'],
          selected: _sport == 'Badminton' ? 0 : 1,
          onSelect: (i) =>
              setState(() => _sport = i == 0 ? 'Badminton' : 'Pickleball'),
        ),
        Text('Duration', style: OgText.body(15, weight: FontWeight.w700)),
        KitSegments(
          labels: const ['7 days', '14 days', '30 days'],
          selected: [7, 14, 30].indexOf(_days),
          onSelect: (i) => setState(() => _days = const [7, 14, 30][i]),
        ),
        KitTextArea(
          label: 'Goal',
          controller: _goal,
          hint: 'Play with a partner you have not played before. Log each win in the app.',
        ),
        KitInput(
          label: 'Reward (optional)',
          controller: _reward,
          hint: '1 hour on court with me',
        ),
      ],
    );
  }
}
