import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_money/og_money.dart' show pointsText;

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/face_id_lock.dart';
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
import '../../earnings/application/earnings_providers.dart';
import '../../guardian/application/guardian_providers.dart';
import '../application/settings_providers.dart';

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
              style: context.type.section,
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
          Text('No sports yet. Add one below.', style: context.type.secondary),
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
        Text('Add a sport', style: context.type.section),
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
          style: context.type.caption.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

/// The app language.
/// The app is in English only. The other languages are listed as not ready;
/// there is no Save, because nothing can be chosen yet (Q266).
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const options = [
      ('English', 'English', true),
      ('中文', 'Chinese, simplified', false),
      ('Bahasa Melayu', 'Malay', false),
      ('தமிழ்', 'Tamil', false),
    ];
    return KitScaffold(
      header: const KitHeader(title: 'Language'),
      children: [
        const KitTitle(
          'App language',
          lead: 'OlympusGO is in English for now.',
        ),
        Column(
          children: [
            for (final (name, sub, ready) in options)
              KitChoiceRow(
                title: name,
                subtitle: sub,
                tag: ready ? null : 'Coming soon',
                selected: ready,
                onTap: ready
                    ? () {}
                    : () => showOgToast(context, '$sub is coming soon.'),
              ),
          ],
        ),
        Text(
          'You can switch here once another language is ready.',
          style: context.type.caption,
        ),
      ],
    );
  }
}

/// Delete the account: what we sort out first, then a 30-day grace period in
/// which logging in again keeps the account (R-ACC-11, R-REF-18).
/// Opens after Face ID, since it lists children, sessions and points
/// (R-ACC-8, Q265); deleting asks again.
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context) => const FaceIdLock(
    title: 'Delete account',
    reason: 'Open delete account',
    child: _DeleteAccount(),
  );
}

class _DeleteAccount extends ConsumerStatefulWidget {
  const _DeleteAccount();

  @override
  ConsumerState<_DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends ConsumerState<_DeleteAccount> {
  String? _why;
  DateTime? _closingUntil;
  bool _sending = false;

  Future<void> _confirm() async {
    final sure = await showKitSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Delete your account?', style: context.type.title),
          const SizedBox(height: 8),
          Text(
            'Your upcoming Meets and lessons are refunded in full. Linked '
            'children keep their accounts but need another adult to link. '
            'You have 30 days to undo it.',
            style: context.type.body.copyWith(
              color: sheet.og.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          KitButton(
            label: 'Delete with Face ID',
            style: KitButtonStyle.danger,
            icon: OgIcons.faceId,
            onPressed: () async {
              final ok = await ref
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
    setState(() => _sending = true);
    try {
      final until = await ref
          .read(settingsRepositoryProvider)
          .requestDeletion(_why);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _sending = false;
        _closingUntil = until;
      });
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showOgToast(context, e.message, error: true);
    }
  }

  /// The tile stays, so logging in again from it is how they keep the account.
  Future<void> _leave() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go(Routes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final wallet = ref.watch(pointsSummaryProvider).value;
    final upcoming = (ref.watch(myScheduleProvider).value ?? const <Activity>[])
        .where((a) => a.myStatus == MyStatus.joined && !a.isFree)
        .toList();
    final kids = ref.watch(myStudentsProvider).value ?? const [];
    final closingUntil = _closingUntil;
    if (closingUntil != null) {
      return KitScaffold(
        header: const KitHeader(title: 'Delete account'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [KitButton(label: 'Done', onPressed: _leave)],
        children: [
          const KitDoneBanner(title: 'Closing'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You can still change your mind',
                  style: context.type.section,
                ),
                const SizedBox(height: 6),
                Text(
                  'Log in before ${Fmt.day(closingUntil)} to keep your account. '
                  'After that it is erased.',
                  style: context.type.secondary.copyWith(height: 1.45),
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
          Text(title, style: context.type.body),
          const SizedBox(height: 2),
          Text(
            body,
            style: context.type.caption.copyWith(color: t.onTag, height: 1.4),
          ),
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
          loading: _sending,
          onPressed: _sending ? null : _confirm,
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
        if (upcoming.isNotEmpty)
          item(
            '${upcoming.length} upcoming paid ${upcoming.length == 1 ? 'session' : 'sessions'}',
            '${upcoming.first.title} on ${Fmt.day(upcoming.first.startsAt)}${upcoming.length > 1 ? ' and more' : ''}. You get a full refund, platform fee included.',
          ),
        if (kids.isNotEmpty)
          item(
            '${kids.map((k) => k.name.split(' ').first).join(' and ')} ${kids.length == 1 ? 'is' : 'are'} linked to you',
            'They keep their accounts, but need another adult to link before '
                'they can do more than browse.',
          ),
        if ((wallet?.minor ?? 0) > 0)
          item(
            '${pointsText(wallet!.minor)} points',
            'Points and vouchers cannot be moved or paid out, so they are lost.',
            action: 'Use your points first',
            onAction: () => context.push(Routes.shop),
          ),
        Text('What happens', style: context.type.section),
        const KitCheckList([
          'Your profile, photos, chats and Passport leave the app at once.',
          'Upcoming Meets and lessons are refunded in full, platform fee included. Shop orders finish first.',
          'You have 30 days to change your mind. Log in to keep your account.',
          'After 30 days your data is erased. Your match results stay on other players’ records as “Former player”.',
          'Receipts are kept for as long as the law requires.',
        ]),
        Text('Why are you leaving? (optional)', style: context.type.section),
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

/// A closing account lands here on every sign-in until the player keeps it
/// or logs out. The database refuses it everything else (R-ACC-11).
class AccountClosingScreen extends ConsumerStatefulWidget {
  const AccountClosingScreen({super.key});

  @override
  ConsumerState<AccountClosingScreen> createState() =>
      _AccountClosingScreenState();
}

class _AccountClosingScreenState extends ConsumerState<AccountClosingScreen> {
  bool _busy = false;

  Future<void> _keep() async {
    setState(() => _busy = true);
    try {
      await ref.read(settingsRepositoryProvider).keepAccount();
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showOgToast(context, 'Welcome back. Your account stays open.');
      // The router sends them home once this reloads.
      ref.invalidate(restrictionsProvider);
      unawaited(ref.read(sessionProfileProvider.notifier).reload());
    } on AuthFailure catch (e) {
      if (!mounted) return;
      showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final until = ref.watch(restrictionsProvider).value?.closingUntil;
    return KitScaffold(
      children: [
        Semantics(
          header: true,
          child: Text('OlympusGO', style: context.type.title),
        ),
        const KitNote('Your account is closing', tone: KitTone.warn),
        Text(
          until == null
              ? 'It is erased soon unless you keep it. Until then you can’t '
                    'use the rest of OlympusGO.'
              : 'It is erased on ${Fmt.day(until)} unless you keep it. Until '
                    'then you can’t use the rest of OlympusGO.',
          style: context.type.secondary,
        ),
        KitButton(
          label: 'Keep my account',
          loading: _busy,
          onPressed: _busy ? null : _keep,
        ),
        KitButton.outline(
          label: 'Log out',
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}

/// Where the player's identity check stands, and why it is needed.
/// Opens after Face ID (R-ACC-8, Q265).
class IdentityCheckScreen extends StatelessWidget {
  const IdentityCheckScreen({super.key});

  @override
  Widget build(BuildContext context) => const FaceIdLock(
    title: 'Identity check',
    reason: 'Open your identity check',
    child: _IdentityCheck(),
  );
}

class _IdentityCheck extends ConsumerWidget {
  const _IdentityCheck();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tones;
    final done = ref.watch(privateInfoProvider).value?.identityVerified;
    return KitScaffold(
      header: const KitHeader(title: 'Identity check'),
      bottom: [
        if (done == false)
          KitButton(
            label: 'Set up payouts',
            onPressed: () => context.push(Routes.payoutAccount),
          ),
      ],
      children: [
        if (done == null)
          const CupertinoActivityIndicator()
        else if (done)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: t.successFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Your identity is checked. You can run paid tournaments and receive payouts.',
              style: context.type.body.copyWith(
                color: t.onSuccessFill,
                height: 1.45,
              ),
            ),
          )
        else
          const KitNote(
            'Not checked yet. You only need it to run paid tournaments or to receive money from Meets, classes and sales.',
          ),
        const KitBlock(
          title: 'Why we check',
          child: KitCheckList([
            'Players know who is taking their money',
            'Payouts go only to the person who earned them',
            'It keeps fake organizers out',
          ]),
        ),
        const KitBlock(
          title: 'How it works',
          child: KitCheckList([
            'Start it when you set up payouts or create a paid tournament',
            'Our review team checks your details, usually within 2 working days',
            'Your documents are never shown to other players',
          ]),
        ),
      ],
    );
  }
}
