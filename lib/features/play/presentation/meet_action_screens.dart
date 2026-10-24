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
import '../application/play_providers.dart';
import '../data/payment_gateway.dart';
import '../domain/activity.dart';
import 'create_screens.dart';
import 'meet_detail_screen.dart';

/// Loads the activity, then builds [body] with it.
class WithActivity extends ConsumerWidget {
  const WithActivity({
    super.key,
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final Widget Function(Activity a) body;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(activityDetailProvider(id))) {
        AsyncData(:final value) => body(value),
        AsyncError() => KitScaffold(
          header: KitHeader(title: title),
          children: const [KitNote("This isn't available any more.")],
        ),
        _ => KitScaffold(
          header: KitHeader(title: title),
          children: const [
            Padding(
              padding: EdgeInsets.only(top: 80),
              child: CupertinoActivityIndicator(),
            ),
          ],
        ),
      };
}

/// The guest's level, as the Meet's bands name it.
const _guestLevels = [
  ('Beginner', 2.0),
  ('Low Intermediate', 4.0),
  ('Mid Intermediate', 5.0),
  ('High Intermediate', 6.0),
];

/// Bring a guest: their name and level, then pay for their spot.
class GuestScreen extends ConsumerStatefulWidget {
  const GuestScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends ConsumerState<GuestScreen> {
  final _name = TextEditingController();
  double? _level;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue(Activity a) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showOgToast(context, "Enter your guest's name.", error: true);
      return;
    }
    if (!a.isFree) {
      await startPayment(context, ref, a, guestName: name, guestLevel: _level);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(playRepositoryProvider)
          .join(a.id, guestName: name, guestLevel: _level);
      HapticFeedback.mediumImpact();
      refreshPlay(ref.invalidate);
      if (!mounted) return;
      await showDoneSheet(
        context,
        title: 'Guest added',
        body:
            '$name is coming. ${a.host.displayName.split(' ').first} sees them '
            'as your guest on the attendance list.',
        next: 'Back to Meet',
        onNext: () => context.pop(),
      );
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WithActivity(
    id: widget.activityId,
    title: 'Bring a guest',
    body: (a) {
      final c = context.og;
      final spots = a.myStatus == MyStatus.joined ? 1 : 2;
      final each = a.totalCents;
      return KitScaffold(
        header: const KitHeader(title: 'Bring a guest'),
        bottom: [
          KitButton(
            label: _level == null
                ? 'Pick their level'
                : a.isFree
                ? 'Add my guest'
                : 'Continue to pay · S\$${money(each * spots)}',
            loading: _busy,
            onPressed: _level == null ? null : () => _continue(a),
          ),
        ],
        children: [
          const KitTitle(
            'Who is coming with you?',
            lead:
                'A guest takes 1 spot. You pay for them and they do not need '
                'the app.',
          ),
          KitInput(
            label: 'Guest name',
            controller: _name,
            hint: 'Their full name',
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Their level', style: OgText.heading(20)),
              const SizedBox(height: 6),
              for (final (label, level) in _guestLevels)
                KitChoiceRow(
                  title: label,
                  selected: _level == level,
                  onTap: () => setState(() => _level = level),
                ),
            ],
          ),
          if (spots == 2)
            Text(
              'You are not on this Meet yet, so you pay for your spot and '
              'theirs.',
              style: OgText.body(14, height: 1.45, color: c.textMuted),
            ),
          const KitNote(
            'Guests do not earn Passport credit or points. You are responsible '
            'for your guest at the Meet.',
          ),
        ],
      );
    },
  );
}

/// Join the waitlist for a full Meet: nothing is charged until a spot
/// opens.
class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  String? _method;
  bool _busy = false;
  int? _place;

  Future<void> _join(Activity a) async {
    setState(() => _busy = true);
    try {
      final pos = await ref.read(playRepositoryProvider).joinWaitlist(a.id);
      HapticFeedback.mediumImpact();
      refreshPlay(ref.invalidate);
      if (mounted) setState(() => _place = pos);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WithActivity(
    id: widget.activityId,
    title: 'Join the waitlist',
    body: (a) {
      final c = context.og;
      final place =
          _place ??
          (a.myStatus == MyStatus.waitlist ? a.myWaitlistPosition : null);
      final back = KitButton(
        label: 'Back to Meet',
        style: place == null ? KitButtonStyle.outline : KitButtonStyle.primary,
        onPressed: () => context.pop(),
      );
      if (place != null) {
        return KitScaffold(
          header: const KitHeader(title: 'Join the waitlist'),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          bottom: [back],
          children: [
            KitDoneBanner(title: "You're #$place"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'On the waitlist for ${a.title}',
                    style: OgText.heading(22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We message you the moment a spot opens. Nothing is '
                    'charged until then.',
                    style: OgText.body(15, height: 1.45, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        );
      }
      final total = a.totalCents;
      final methods = ref.watch(_payMethodsProvider).value ?? const [];
      final picked = _method ?? methods.firstOrNull?.id;
      return KitScaffold(
        header: const KitHeader(title: 'Join the waitlist'),
        bottom: [
          KitButton(
            label: 'Join the waitlist',
            loading: _busy,
            onPressed: () => _join(a),
          ),
          back,
        ],
        children: [
          KitTitle(
            'This Meet is full',
            lead:
                '${a.capacity} of ${a.capacity} spots are taken. '
                '${a.waitlistCount == 0 ? 'Nobody is waiting yet.' : '${a.waitlistCount} ${a.waitlistCount == 1 ? 'player is' : 'players are'} waiting.'}',
          ),
          KitCheckList([
            'You are not charged now',
            if (!a.isFree)
              'If a spot opens, the first player in line gets it and is '
                  'charged S\$${money(total)}'
            else
              'If a spot opens, the first player in line gets it',
            'You get a message and have 30 minutes to say no',
            'Leave the waitlist any time',
          ]),
          if (!a.isFree && methods.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('If a spot opens, pay with', style: OgText.heading(20)),
                const SizedBox(height: 6),
                for (final m in methods)
                  KitChoiceRow(
                    title: m.title,
                    subtitle: m.detail,
                    selected: picked == m.id,
                    onTap: () => setState(() => _method = m.id),
                  ),
              ],
            ),
        ],
      );
    },
  );
}

final _payMethodsProvider = FutureProvider.autoDispose<List<PayMethod>>(
  (ref) => ref.watch(paymentGatewayProvider).methods(),
);

/// My schedule: the week at a glance, then what I joined and what I host.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, this.hosting = false});

  final bool hosting;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late int _tab = widget.hosting ? 1 : 0;

  /// A day picked on the week strip, to show that day only.
  DateTime? _day;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final joined = ref.watch(myScheduleProvider);
    final hosting = ref.watch(hostingProvider);
    final joinList = (joined.value ?? const <Activity>[])
        .where((a) => !a.iAmHost)
        .toList();
    final hostList = hosting.value ?? const <Activity>[];
    final list = _tab == 0 ? joinList : hostList;

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final week = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
    final weekEnd = monday.add(const Duration(days: 7));
    final busy = {
      for (final a in [...joinList, ...hostList])
        for (final d in week)
          if (_sameDay(a.startsAt, d)) d,
    };

    final shown = _day == null
        ? list
        : list.where((a) => _sameDay(a.startsAt, _day!)).toList();
    final thisWeek = shown.where((a) => a.startsAt.isBefore(weekEnd)).toList();
    final later = shown.where((a) => !a.startsAt.isBefore(weekEnd)).toList();
    final loading = (_tab == 0 ? joined : hosting).isLoading;

    Widget section(String title, List<Activity> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: OgText.heading(20))),
            Text(
              '${items.length} ${items.length == 1 ? 'session' : 'sessions'}',
              style: OgText.body(13, color: c.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        KitCard(
          children: [
            for (final a in items)
              _ScheduleRow(activity: a, hosting: _tab == 1),
          ],
        ),
      ],
    );

    return KitScaffold(
      header: const KitHeader(title: 'My schedule'),
      children: [
        Row(
          children: [
            for (final d in week)
              Expanded(
                child: _DayTile(
                  day: d,
                  today: _sameDay(d, now),
                  picked: _day != null && _sameDay(d, _day!),
                  busy: busy.contains(d),
                  onTap: () => setState(
                    () => _day = _day != null && _sameDay(d, _day!) ? null : d,
                  ),
                ),
              ),
          ],
        ),
        KitUnderlineTabs(
          labels: [
            'Joined · ${joinList.length}',
            'Hosting · ${hostList.length}',
          ],
          selected: _tab,
          spread: true,
          padding: EdgeInsets.zero,
          onSelect: (i) => setState(() => _tab = i),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CupertinoActivityIndicator(),
          )
        else if (list.isEmpty)
          _Empty(hosting: _tab == 1)
        else if (shown.isEmpty)
          Text(
            'Nothing on ${Fmt.day(_day!)}.',
            style: OgText.body(15, color: c.textMuted),
          )
        else ...[
          if (thisWeek.isNotEmpty) section('This week', thisWeek),
          if (later.isNotEmpty) section('Later', later),
        ],
        if (_tab == 1)
          KitCard(
            children: [
              KitNavTile(
                icon: OgIcons.wallet,
                title: 'Earnings and payouts',
                subtitle: 'What your Meets made, and when it is paid out',
                onTap: () => context.push(Routes.earnings),
              ),
            ],
          ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.today,
    required this.picked,
    required this.busy,
    required this.onTap,
  });

  final DateTime day;
  final bool today;
  final bool picked;
  final bool busy;
  final VoidCallback onTap;

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final on = picked || (today && !picked);
    final bg = picked ? OgColors.ink : (today ? c.primary : Colors.transparent);
    final fg = picked ? Colors.white : (today ? c.onPrimary : c.text);
    return Pressable(
      semanticLabel:
          '${Fmt.day(day)}${busy ? ', has sessions' : ''}${today ? ', today' : ''}',
      selected: picked,
      onPressed: onTap,
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _names[day.weekday - 1],
              style: OgText.body(
                12,
                weight: FontWeight.w600,
                color: on ? fg : c.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text('${day.day}', style: OgText.heading(18, color: fg)),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: busy ? (on ? fg : c.primary) : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.activity, required this.hosting});

  final Activity activity;
  final bool hosting;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final a = activity;
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final line = switch (a.myStatus) {
      _ when hosting =>
        '${Fmt.time(a.startsAt)} · ${a.spotsTaken} of ${a.capacity} ${a.kind == ActivityKind.tournament ? 'teams' : 'joined'}',
      MyStatus.waitlist =>
        'Waitlist #${a.myWaitlistPosition} · ${Fmt.time(a.startsAt)}',
      MyStatus.requested => 'Waiting for the host · ${Fmt.time(a.startsAt)}',
      _ =>
        '${meetWhen(a).split(', ').first == 'Tonight' ? 'Tonight ' : ''}'
            '${Fmt.time(a.startsAt)}, ${a.venue.name}',
    };
    return Pressable(
      semanticLabel: '${a.title}, $line, ${a.kind.label}',
      onPressed: () => context.push(Routes.activity(a.id)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 52,
              decoration: BoxDecoration(
                color: t.tag,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[a.startsAt.weekday - 1],
                    style: OgText.body(
                      11,
                      weight: FontWeight.w800,
                      color: t.onTag,
                    ),
                  ),
                  Text('${a.startsAt.day}', style: OgText.heading(18)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(13, color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            KitTag(a.kind.label),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hosting});

  final bool hosting;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return DashedBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hosting ? 'Nothing hosted yet' : 'Nothing joined yet',
              style: OgText.heading(20),
            ),
            const SizedBox(height: 6),
            Text(
              hosting
                  ? 'Meets, tournaments and events you run show up here, '
                        'with their organizer tools.'
                  : 'Meets, tournaments and events you join show up here.',
              style: OgText.body(14, height: 1.45, color: c.textMuted),
            ),
            const SizedBox(height: 14),
            KitButton(
              label: hosting
                  ? 'Create a Meet, tournament or event'
                  : 'Find a Meet',
              style: KitButtonStyle.outline,
              onPressed: () =>
                  hosting ? showCreateMenu(context) : context.push(Routes.play),
            ),
          ],
        ),
      ),
    );
  }
}

/// "You are checked in" after scanning a Meet's code at the venue.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  late final Future<int> _here = ref
      .read(playRepositoryProvider)
      .checkIn(widget.activityId);

  @override
  Widget build(BuildContext context) => WithActivity(
    id: widget.activityId,
    title: 'Check in',
    body: (a) => FutureBuilder<int>(
      future: _here,
      builder: (context, snap) {
        if (snap.hasError) {
          return KitScaffold(
            header: const KitHeader(title: 'Check in'),
            bottom: [
              KitButton(
                label: 'Back to Scan',
                onPressed: () => context.go(Routes.scan),
              ),
            ],
            children: [
              KitNote(
                snap.error is AuthFailure
                    ? (snap.error! as AuthFailure).message
                    : "Couldn't check you in.",
                tone: KitTone.warn,
              ),
            ],
          );
        }
        if (!snap.hasData) {
          return const KitScaffold(
            header: KitHeader(title: 'Check in'),
            children: [CupertinoActivityIndicator()],
          );
        }
        return KitScaffold(
          header: const KitHeader(title: 'Check in'),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          bottom: [
            KitButton(label: 'Done', onPressed: () => context.go(Routes.home)),
            KitButton(
              label: 'See the Meet',
              style: KitButtonStyle.outline,
              onPressed: () => context.push(Routes.activity(a.id)),
            ),
          ],
          children: [
            const KitDoneBanner(title: 'Checked in'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  KitKeyValue('Meet', a.title),
                  KitKeyValue('Where', [a.venue.name, ?a.court].join(', ')),
                  KitKeyValue('Time', Fmt.dayTimeComma(a.startsAt)),
                  KitKeyValue('Players here', '${snap.data} of ${a.capacity}'),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
