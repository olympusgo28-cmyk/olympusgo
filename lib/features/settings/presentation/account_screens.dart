import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../academy/application/academy_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../../play/application/play_providers.dart';
import '../../play/domain/activity.dart';
import '../../profile/domain/profile.dart';
import '../../wallet/application/wallet_providers.dart';
import '../../wallet/presentation/wallet_screens.dart' show cash;
import '../application/settings_providers.dart';

/// Account Centre: sign-in, payments, family and account, behind Face ID.
class AccountHubScreen extends ConsumerStatefulWidget {
  const AccountHubScreen({super.key});

  @override
  ConsumerState<AccountHubScreen> createState() => _AccountHubScreenState();
}

class _AccountHubScreenState extends ConsumerState<AccountHubScreen> {
  bool? _open;

  @override
  void initState() {
    super.initState();
    _unlock();
  }

  Future<void> _unlock() async {
    // Demo mode skips the device check, so a simulator never asks for its
    // passcode.
    final ok =
        !Env.hasSupabase ||
        await ref
            .read(biometricVaultProvider)
            .authenticate('Open your Account Centre');
    if (mounted) setState(() => _open = ok);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    if (_open != true) {
      return KitScaffold(
        header: const KitHeader(title: 'Account Centre'),
        children: [
          if (_open == false) ...[
            const KitNote(
              'Face ID didn’t match, so the Account Centre stays locked.',
              tone: KitTone.warn,
            ),
            KitButton(label: 'Try again', onPressed: _unlock),
          ] else
            const CupertinoActivityIndicator(),
        ],
      );
    }
    final info = ref.watch(privateInfoProvider).value;
    final children = ref.watch(myStudentsProvider).value ?? const [];
    Widget verified(String value) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: OgText.body(13, color: c.textMuted),
          ),
        ),
        const SizedBox(width: 6),
        KitTag(
          'Verified',
          height: 22,
          fontSize: 11,
          background: t.successFill,
          foreground: t.onSuccessFill,
        ),
      ],
    );
    Widget section(String title, List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: OgText.heading(20)),
        const SizedBox(height: 8),
        KitCard(children: rows),
      ],
    );
    return KitScaffold(
      header: const KitHeader(title: 'Account Centre'),
      children: [
        Text(
          'Opened with Face ID. You are asked again before any change to '
          'sign-in or payment details.',
          style: OgText.body(14, height: 1.4, color: c.textMuted),
        ),
        section('Sign-in', [
          KitNavTile(
            icon: OgIcons.mail,
            title: 'Email',
            trailing: info == null ? null : verified(info.email),
            onTap: () => context.push(Routes.personalInfo),
          ),
          KitNavTile(
            icon: OgIcons.phone,
            title: 'Mobile',
            trailing: info == null ? null : verified(info.phone),
            onTap: () => context.push(Routes.personalInfo),
          ),
          KitNavTile(
            icon: OgIcons.faceId,
            title: 'Face ID',
            subtitle: 'On. It replaces the text code on this phone',
            onTap: () => context.push(Routes.personalInfo),
          ),
        ]),
        section('Payments', [
          KitNavTile(
            icon: OgIcons.walletCard,
            title: 'Payment methods',
            subtitle: 'Card ending 4242, PayNow',
            onTap: () =>
                showOgToast(context, 'Cards are added when you first pay.'),
          ),
          KitNavTile(
            icon: OgIcons.clipboardList,
            title: 'Receipts',
            subtitle: 'Every Meet, entry, ticket, class and order',
            onTap: () => context.push(Routes.receipts),
          ),
          KitNavTile(
            icon: OgIcons.wallet,
            title: 'Payout account',
            subtitle: 'Where your earnings are paid',
            onTap: () => context.push(Routes.payoutAccount),
          ),
        ]),
        if (children.isNotEmpty)
          section('Family', [
            KitNavTile(
              icon: OgIcons.people,
              title: 'Linked children',
              subtitle: children.map((s) => s.name).join(', '),
              onTap: () => context.push(Routes.studentHome(children.first.id)),
            ),
            KitNavTile(
              icon: OgIcons.shieldTick,
              title: 'Under-18 protection',
              subtitle: 'Settings that stay on for children',
              onTap: () => context.push(Routes.privacy),
            ),
          ]),
        section('Account', [
          KitNavTile(
            icon: OgIcons.idCard,
            title: 'Identity check',
            subtitle: 'Needed to run tournaments and receive payouts',
            trailing: KitTag(
              'Done',
              background: t.successFill,
              foreground: t.onSuccessFill,
            ),
            onTap: () {},
            chevron: false,
          ),
          KitNavTile(
            icon: OgIcons.trash,
            title: 'Delete account',
            subtitle: 'Removes your profile. Ratings history is anonymised.',
            danger: true,
            onTap: () => context.push(Routes.deleteAccount),
          ),
        ]),
        section('More', [
          KitNavTile(
            icon: OgIcons.help,
            title: 'Help and terms',
            subtitle: 'Common questions, chat with support, terms',
            onTap: () => context.push(Routes.help),
          ),
          KitNavTile(
            icon: OgIcons.shield,
            title: 'My reports',
            subtitle: 'Status and result of what you reported',
            onTap: () => context.push(Routes.myReports),
          ),
          KitNavTile(
            icon: OgIcons.block,
            title: 'Blocked players',
            subtitle: 'People you have blocked',
            onTap: () => context.push(Routes.blocked),
          ),
          KitNavTile(
            icon: OgIcons.location,
            title: 'Country',
            subtitle:
                '${info?.country.name ?? 'Singapore'} · S\$ · emergency 999',
            chevron: false,
            onTap: () {},
          ),
          KitNavTile(
            icon: OgIcons.chatLines,
            title: 'Language',
            subtitle: 'English',
            onTap: () => context.push(Routes.language),
          ),
          KitNavTile(
            icon: OgIcons.logOut,
            title: 'Log out',
            onTap: () => context.push(Routes.logOut),
          ),
        ]),
      ],
    );
  }
}

/// Passport sports and the level the player sets for each.
class ProfileSportsScreen extends ConsumerStatefulWidget {
  const ProfileSportsScreen({super.key});

  @override
  ConsumerState<ProfileSportsScreen> createState() =>
      _ProfileSportsScreenState();
}

class _ProfileSportsScreenState extends ConsumerState<ProfileSportsScreen> {
  List<PlayerSport>? _sports;
  bool _busy = false;

  static const _offered = [
    Sport.badminton,
    Sport.pickleball,
    Sport.tennis,
    Sport.tableTennis,
    Sport.padel,
  ];

  Future<void> _save() async {
    final me = ref.read(currentUserIdProvider).value;
    if (me == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).saveSports(me, _sports!);
      HapticFeedback.mediumImpact();
      ref.invalidate(mySportsProvider);
      ref.invalidate(playSportsProvider);
      if (!mounted) return;
      showOgToast(context, 'Saved');
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickLevel(int i) async {
    final s = _sports![i];
    final picked = await showKitSheet<double>(
      context,
      builder: (sheet) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Level for ${Sport.fromId(s.sport).label}',
              style: OgText.heading(22),
            ),
            const SizedBox(height: 8),
            for (final b in SkillBand.values)
              KitChoiceRow(
                title: b.label,
                subtitle:
                    '${b.code} · ${b.index + 1}.0 to ${b.index == 7 ? '8.0' : '${b.index + 1}.9'}',
                selected: SkillBand.forLevel(s.level) == b,
                onTap: () => Navigator.of(sheet).pop(b.index + 1.0),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _sports![i] = PlayerSport(
        sport: s.sport,
        level: picked,
        playMin: (picked - 1).clamp(1, 8),
        playMax: (picked + 1.9).clamp(1, 8),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final loaded = ref.watch(mySportsProvider).value;
    if (loaded != null && _sports == null) _sports = [...loaded];
    final sports = _sports;
    if (sports == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Sports and levels'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final have = {for (final s in sports) s.sport};
    return KitScaffold(
      header: const KitHeader(title: 'Sports and levels'),
      bottom: [KitButton(label: 'Save', loading: _busy, onPressed: _save)],
      children: [
        const KitTitle(
          'Your Passport sports',
          lead:
              'Your level sets which Meets and tournaments are suggested, and '
              'the default range in filters.',
        ),
        if (sports.isEmpty)
          Text(
            'No sports yet. Add one below.',
            style: OgText.body(14, color: c.textMuted),
          ),
        KitCard(
          children: [
            for (final (i, s) in sports.indexed)
              KitNavTile(
                icon: Sport.fromId(s.sport).icon,
                title: Sport.fromId(s.sport).label,
                subtitle:
                    '${SkillBand.forLevel(s.level).label} · ${SkillBand.forLevel(s.level).code}',
                trailing: KitLink(
                  'Remove',
                  color: context.tones.onDangerFill,
                  onPressed: () => setState(() => sports.removeAt(i)),
                ),
                onTap: () => _pickLevel(i),
              ),
          ],
        ),
        Text('Add a sport', style: OgText.heading(20)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in _offered.where((s) => !have.contains(s.id)))
              KitChip(
                label: s.label,
                icon: s.icon,
                onTap: () => setState(
                  () => sports.add(
                    PlayerSport(
                      sport: s.id,
                      level: 3,
                      playMin: 2,
                      playMax: 4.9,
                    ),
                  ),
                ),
              ),
          ],
        ),
        Text(
          'You choose your own level. Your rating is separate: it only moves '
          'when ranked game scores are confirmed by both sides or an umpire.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

/// The app language.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _picked = 'English';

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    const options = [
      ('English', 'English', true),
      ('中文', 'Chinese, simplified', false),
      ('Bahasa Melayu', 'Malay', false),
      ('தமிழ்', 'Tamil', false),
    ];
    return KitScaffold(
      header: const KitHeader(title: 'Language'),
      bottom: [
        KitButton(
          label: 'Save',
          onPressed: () {
            showOgToast(context, 'Language saved');
            context.pop();
          },
        ),
      ],
      children: [
        const KitTitle(
          'App language',
          lead: 'Menus and messages use this language. Names of Meets and clubs stay as written.',
        ),
        Column(
          children: [
            for (final (name, sub, ready) in options)
              KitChoiceRow(
                title: name,
                subtitle: sub,
                tag: ready ? null : 'Coming soon',
                selected: _picked == name,
                onTap: ready
                    ? () => setState(() => _picked = name)
                    : () => showOgToast(context, '$sub is coming soon.'),
              ),
          ],
        ),
        Text(
          'More languages are being translated.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Delete the account: what we sort out first, then a 30-day grace period.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  String? _why;
  bool _done = false;

  Future<void> _confirm() async {
    final sure = await showKitSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Delete your account?', style: OgText.heading(24)),
          const SizedBox(height: 8),
          Text(
            'Your Wallet money goes to your bank, your Meets are refunded, and '
            'linked children’s accounts close with yours. You have 30 days to '
            'undo it.',
            style: OgText.body(15, height: 1.45, color: sheet.og.textMuted),
          ),
          const SizedBox(height: 18),
          KitButton(
            label: 'Delete with Face ID',
            style: KitButtonStyle.danger,
            icon: OgIcons.faceId,
            onPressed: () async {
              final ok =
                  !Env.hasSupabase ||
                  await ref
                      .read(biometricVaultProvider)
                      .authenticate('Delete your account');
              if (sheet.mounted) Navigator.of(sheet).pop(ok);
            },
          ),
          const SizedBox(height: 10),
          KitButton(
            label: 'Cancel',
            style: KitButtonStyle.outline,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    if (Env.hasSupabase) {
      showOgToast(
        context,
        'Account deletion is handled by support for now. Write to us from Help and it is done within 30 days.',
        error: true,
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final wallet = ref.watch(walletSummaryProvider).value;
    final upcoming = (ref.watch(myScheduleProvider).value ?? const <Activity>[])
        .where((a) => a.myStatus == MyStatus.joined && !a.isFree)
        .toList();
    final kids = ref.watch(myStudentsProvider).value ?? const [];
    final info = ref.watch(privateInfoProvider).value;
    final closeBy = DateTime.now().add(const Duration(days: 30));
    if (_done) {
      return KitScaffold(
        header: const KitHeader(title: 'Delete account'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(label: 'Done', onPressed: () => context.go(Routes.home)),
        ],
        children: [
          const KitDoneBanner(title: 'Closing'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You can still change your mind',
                  style: OgText.heading(22),
                ),
                const SizedBox(height: 6),
                Text(
                  'Log in before ${Fmt.day(closeBy)} to keep your account. After '
                  'that it is erased. We sent the details to ${info?.email ?? 'your email'}.',
                  style: OgText.body(15, height: 1.45, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }
    Widget item(
      String title,
      String body, {
      String? action,
      VoidCallback? onAction,
    }) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.tag,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: OgText.body(15, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(body, style: OgText.body(13, height: 1.4, color: t.onTag)),
          if (action != null)
            KitLink(action, underline: true, onPressed: onAction),
        ],
      ),
    );
    return KitScaffold(
      header: const KitHeader(title: 'Delete account'),
      bottom: [
        KitButton(
          label: 'Delete my account',
          style: KitButtonStyle.danger,
          onPressed: _confirm,
        ),
        KitButton(
          label: 'Keep my account',
          style: KitButtonStyle.outline,
          onPressed: () => context.pop(),
        ),
      ],
      children: [
        const KitTitle(
          'Before you go',
          lead: 'We sort these out for you when you delete. Check that each one is what you want.',
        ),
        if ((wallet?.balanceCents ?? 0) > 0)
          item(
            '${cash(wallet!.balanceCents)} in your Wallet',
            'We send it to your bank account first, free of charge.',
            action: 'Withdraw it now instead',
            onAction: () => context.push(Routes.walletWithdraw),
          ),
        if (upcoming.isNotEmpty)
          item(
            '${upcoming.length} upcoming paid ${upcoming.length == 1 ? 'session' : 'sessions'}',
            '${upcoming.first.title} on ${Fmt.day(upcoming.first.startsAt)}${upcoming.length > 1 ? ' and more' : ''}. You get a full refund, platform fee included.',
          ),
        if (kids.isNotEmpty)
          item(
            '${kids.map((k) => k.name.split(' ').first).join(' and ')} ${kids.length == 1 ? 'is' : 'are'} linked to you',
            'Their accounts close too, unless another parent takes them over.',
          ),
        if ((wallet?.points ?? 0) > 0)
          item(
            '${wallet!.points.toStringAsFixed(1)} points',
            'Points cannot be moved or paid out, so they are lost.',
            action: 'Use your points first',
            onAction: () => context.push(Routes.shop),
          ),
        Text('What happens', style: OgText.heading(20)),
        const KitCheckList([
          'Your profile, photos, chats and Passport leave the app at once.',
          'You have 30 days to change your mind. Log in to cancel the deletion.',
          'After 30 days your data is erased. Your match results stay on other players’ records as “Former player”.',
          'Receipts are kept for 5 years, because payment records must be kept by law.',
        ]),
        Text('Why are you leaving? (optional)', style: OgText.heading(20)),
        Column(
          children: [
            for (final r in const [
              'I don’t play any more',
              'I use another app',
              'Too many notifications',
              'Privacy worries',
              'Something else',
            ])
              KitChoiceRow(
                title: r,
                selected: _why == r,
                onTap: () => setState(() => _why = r),
              ),
          ],
        ),
      ],
    );
  }
}
