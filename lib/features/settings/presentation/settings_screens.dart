import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/cupertino_sheets.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/og_kit.dart';
import '../../auth/data/auth_repository.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../../social/application/social_providers.dart';
import '../application/avatar_upload.dart';
import '../application/settings_providers.dart';
import '../domain/settings_models.dart';

/// Settings: account, preferences and more, with Log out at the bottom.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(title: 'Settings', topGap: 8),
        const SectionLabel('Account'),
        RowGroup(
          children: [
            NavRow(
              icon: OgIcons.person,
              title: 'Account centre',
              subtitle: 'Name, username, bio and gender',
              onTap: () => context.push(Routes.accountCentre),
            ),
            NavRow(
              icon: OgIcons.idCard,
              title: 'Personal information',
              subtitle: 'Email, mobile, birthday and Face ID',
              onTap: () => context.push(Routes.personalInfo),
            ),
          ],
        ),
        const SectionLabel('Preferences'),
        RowGroup(
          children: [
            NavRow(
              icon: OgIcons.bell,
              title: 'Notifications',
              subtitle: 'Meets, messages and followers',
              onTap: () => context.push(Routes.notifications),
            ),
            NavRow(
              icon: OgIcons.shield,
              title: 'Privacy and safety',
              subtitle: 'Who can see and find you',
              onTap: () => context.push(Routes.privacy),
            ),
          ],
        ),
        const SectionLabel('More'),
        RowGroup(
          children: [
            NavRow(
              icon: OgIcons.wallet,
              title: 'Wallet and points',
              subtitle: 'Refunds, withdrawals and points',
              onTap: () => context.push(Routes.wallet),
            ),
            NavRow(
              icon: OgIcons.bag,
              title: 'My orders',
              subtitle: 'Track, return and review',
              onTap: () => context.push(Routes.orders()),
            ),
            NavRow(
              icon: OgIcons.bookmark,
              title: 'Saved',
              subtitle: 'Meets, players and clubs',
              onTap: () => context.push(Routes.saved),
            ),
            NavRow(
              icon: OgIcons.block,
              title: 'Blocked players',
              subtitle: 'People you blocked',
              onTap: () => context.push(Routes.blocked),
            ),
            NavRow(
              icon: OgIcons.help,
              title: 'Help',
              subtitle: 'Questions and support',
              onTap: () => context.push(Routes.help),
            ),
          ],
        ),
      ],
      bottom: [
        Pressable(
          onPressed: () => context.push(Routes.logOut),
          isButton: true,
          semanticLabel: 'Log out',
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OgIcon(OgIcons.logOut, size: 22, color: c.link),
                const SizedBox(width: 10),
                Text(
                  'Log out',
                  style: OgText.body(
                    16,
                    weight: FontWeight.w600,
                    color: c.link,
                    decoration: TextDecoration.underline,
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

/// Account centre: photo, name, username, bio and gender. Used both from
/// Settings and once right after onboarding ([onboarding] true).
class AccountCentreScreen extends ConsumerStatefulWidget {
  const AccountCentreScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<AccountCentreScreen> createState() =>
      _AccountCentreScreenState();
}

class _AccountCentreScreenState extends ConsumerState<AccountCentreScreen> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  Gender _gender = Gender.preferNotToSay;
  String? _avatarUrl;
  bool _loaded = false;
  bool _busy = false;
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _fill(AccountDetails d) {
    if (_loaded) return;
    _loaded = true;
    _name.text = d.fullName;
    _username.text = d.username;
    _bio.text = d.bio;
    _gender = d.gender;
    _avatarUrl = d.avatarUrl;
  }

  Future<void> _pickGender() async {
    final picked = await showOgListPicker<Gender>(
      context: context,
      title: 'Gender',
      items: Gender.values,
      selected: _gender,
      label: (g) => g.label,
    );
    if (picked != null) setState(() => _gender = picked);
  }

  Future<void> _changePhoto() async {
    final source = await showCupertinoModalPopup<ImageSourceChoice>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Profile photo'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.of(context).pop(ImageSourceChoice.camera),
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.of(context).pop(ImageSourceChoice.library),
            child: const Text('Choose from Library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (source == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadAvatar(ref, source);
      if (url != null && mounted) setState(() => _avatarUrl = url);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final username = _username.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Enter your name.');
    if (!RegExp(r'^[A-Za-z0-9_]{3,30}$').hasMatch(username)) {
      return setState(
        () => _error = 'Usernames use 3 to 30 letters, numbers or underscores.',
      );
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(settingsRepositoryProvider)
          .saveAccount(
            AccountDetails(
              fullName: name,
              username: username,
              bio: _bio.text,
              gender: _gender,
            ),
          );
      await ref.read(sessionProfileProvider.notifier).reload();
      if (!mounted) return;
      if (widget.onboarding) {
        context.push(Routes.setupPersonal);
      } else {
        showOgToast(context, 'Saved');
        context.pop();
      }
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(accountDetailsProvider);
    details.whenData(_fill);
    final initials = _initials(_name.text);
    return OgFlowScreen(
      asPage: true,
      children: [
        OgBackButton(
          onPressed: widget.onboarding ? () => context.go(Routes.home) : null,
        ),
        const OgHeading(title: 'Account centre', topGap: 8),
        const SizedBox(height: 16),
        Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Avatar(
                  initials: initials,
                  tone: AvatarTone.brand,
                  imageUrl: _avatarUrl,
                  size: 72,
                  fontSize: 28,
                ),
                if (_uploading)
                  const CupertinoActivityIndicator(color: OgColors.white),
              ],
            ),
            const SizedBox(width: 16),
            OgTextLink(
              'Change photo',
              align: Alignment.centerLeft,
              onPressed: _changePhoto,
            ),
          ],
        ),
        const SizedBox(height: 14),
        OgTextField(
          label: 'Name',
          controller: _name,
          autofillHints: const [AutofillHints.name],
          capitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        OgTextField(
          label: 'Username',
          controller: _username,
          autocorrect: false,
          autofillHints: const [AutofillHints.username],
        ),
        const SizedBox(height: 12),
        OgTextArea(label: 'Bio', controller: _bio, minLines: 2),
        const SizedBox(height: 12),
        Text('Gender', style: OgText.label),
        const SizedBox(height: 8),
        OgSelectField(
          value: _gender.label,
          semanticLabel: 'Gender',
          onTap: _pickGender,
        ),
        const SizedBox(height: 14),
        Pressable(
          onPressed: () => context.push(
            widget.onboarding ? Routes.setupPersonal : Routes.personalInfo,
          ),
          semanticLabel: 'Personal information settings',
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.og.borderControl, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Personal information settings',
                    style: OgText.body(
                      16,
                      weight: FontWeight.w600,
                      color: context.og.text,
                    ),
                  ),
                ),
                OgIcon(
                  OgIcons.chevronRight,
                  size: 22,
                  color: context.og.text,
                  strokeWidth: 2.5,
                ),
              ],
            ),
          ),
        ),
        if (_error != null) OgErrorText(_error!),
      ],
      bottom: [
        OgButton(
          label: widget.onboarding ? 'Continue' : 'Save',
          loading: _busy,
          onPressed: details.hasValue ? _save : null,
        ),
      ],
    );
  }
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Email, mobile, birthday (read only) and the Face ID switch.
class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  PrivateInfo? _original;
  bool _busy = false;
  String? _error;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void dispose() {
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  void _fill(PrivateInfo info) {
    if (_original != null) return;
    _original = info;
    _email.text = info.email;
    final dial = info.country.dialCode.substring(1);
    var digits = info.phone.replaceAll('+', '');
    if (digits.startsWith(dial)) digits = digits.substring(dial.length);
    _mobile.text = digits.length == 8
        ? '${digits.substring(0, 4)} ${digits.substring(4)}'
        : digits;
  }

  Future<void> _finish() async {
    if (widget.onboarding) {
      context.go(Routes.profile);
      return;
    }
    final email = _email.text.trim();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_original != null && email != _original!.email) {
        await ref.read(settingsRepositoryProvider).changeEmail(email);
        if (mounted) showOgToast(context, 'Check $email to confirm the change');
      }
      final digits = _mobile.text.replaceAll(RegExp(r'\D'), '');
      final phone = '${_original?.country.dialCode ?? '+65'}$digits';
      if (_original != null &&
          digits.isNotEmpty &&
          phone.replaceAll('+', '') != _original!.phone.replaceAll('+', '')) {
        await ref.read(authRepositoryProvider).startPhoneChange(phone);
        if (mounted) context.push(Routes.verifyPhoneChange, extra: phone);
        return;
      }
      if (mounted) context.pop();
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final info = ref.watch(privateInfoProvider);
    info.whenData(_fill);
    final faceId = ref.watch(faceIdEnabledProvider).value ?? true;
    final birthday = info.value?.birthday;
    final country = info.value?.country;

    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Personal information',
          topGap: 8,
          lead: 'Only you can see these details.',
        ),
        const SizedBox(height: 20),
        OgTextField(
          label: 'Email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        Text('Mobile', style: OgText.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 124,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.borderControl, width: 2),
              ),
              child: Row(
                children: [
                  if (country != null) country.flag(),
                  const SizedBox(width: 8),
                  Text(
                    country?.dialCode ?? '',
                    style: OgText.body(
                      18,
                      weight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OgInput(
                controller: _mobile,
                semanticLabel: 'Mobile',
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Date of birth', style: OgText.label),
        const SizedBox(height: 8),
        Semantics(
          readOnly: true,
          label: 'Date of birth',
          value: birthday == null
              ? ''
              : '${birthday.day} ${_months[birthday.month - 1]} ${birthday.year}',
          child: Container(
            height: 56,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderControl, width: 2),
            ),
            child: ExcludeSemantics(
              child: Text(
                birthday == null
                    ? ''
                    : '${birthday.day} ${_months[birthday.month - 1]} ${birthday.year}',
                style: OgText.body(18, color: c.textMuted),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Your date of birth can't be changed.",
          style: OgText.body(14, color: c.textMuted),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border, width: 2),
          ),
          child: SwitchRow(
            leading: OgIcon(OgIcons.faceId, size: 26, color: c.text),
            title: 'Enable Face ID',
            subtitle: 'Unlock OlympusGO with your face.',
            value: faceId,
            onChanged: (v) => ref.read(faceIdEnabledProvider.notifier).set(v),
          ),
        ),
        if (_error != null) OgErrorText(_error!),
      ],
      bottom: [
        OgButton(
          label: widget.onboarding ? 'Continue' : 'Save',
          loading: _busy,
          onPressed: _finish,
        ),
      ],
    );
  }
}

enum ImageSourceChoice { camera, library }

/// Notification switches; changes save as you go.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final prefs =
        ref.watch(notificationSettingsProvider).value ??
        const NotificationPrefs();
    final notifier = ref.read(notificationSettingsProvider.notifier);
    Future<void> change(
      NotificationPrefs Function(NotificationPrefs) edit,
    ) async {
      try {
        await notifier.change(edit);
      } on AuthFailure catch (e) {
        if (context.mounted) showOgToast(context, e.message, error: true);
      }
    }

    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Notifications',
          topGap: 8,
          lead: 'Sign-in codes and receipts always come through.',
        ),
        RowGroup(
          top: 16,
          dividers: true,
          children: [
            SwitchRow(
              title: 'Meet reminders',
              subtitle: 'Before a Meet you joined starts',
              value: prefs.meetReminders,
              onChanged: (v) => change((p) => p.copyWith(meetReminders: v)),
            ),
            SwitchRow(
              title: 'Court calls',
              subtitle: 'When it is your turn to play',
              value: prefs.courtCalls,
              onChanged: (v) => change((p) => p.copyWith(courtCalls: v)),
            ),
            SwitchRow(
              title: 'Messages',
              subtitle: 'From players and Meet hosts',
              value: prefs.messages,
              onChanged: (v) => change((p) => p.copyWith(messages: v)),
            ),
            SwitchRow(
              title: 'New followers',
              subtitle: 'When someone follows you',
              value: prefs.newFollowers,
              onChanged: (v) => change((p) => p.copyWith(newFollowers: v)),
            ),
            SwitchRow(
              title: 'Offers and news',
              subtitle: 'Tips and new features',
              value: prefs.offersAndNews,
              onChanged: (v) => change((p) => p.copyWith(offersAndNews: v)),
            ),
          ],
        ),
      ],
      bottom: [
        Text(
          'Changes save as you go.',
          textAlign: TextAlign.center,
          style: OgText.body(14, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Profile visibility and privacy switches; changes save as you go.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final prefs =
        ref.watch(privacySettingsProvider).value ?? const PrivacyPrefs();
    final notifier = ref.read(privacySettingsProvider.notifier);
    Future<void> change(PrivacyPrefs Function(PrivacyPrefs) edit) async {
      try {
        await notifier.change(edit);
      } on AuthFailure catch (e) {
        if (context.mounted) showOgToast(context, e.message, error: true);
      }
    }

    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(title: 'Privacy and safety', topGap: 8),
        const SizedBox(height: 20),
        Text('Who can see my profile', style: OgText.label),
        const SizedBox(height: 8),
        OgSelectField(
          value: prefs.visibility.label,
          semanticLabel: 'Who can see my profile',
          onTap: () async {
            final picked = await showOgListPicker<ProfileVisibility>(
              context: context,
              title: 'Who can see my profile',
              items: ProfileVisibility.values,
              selected: prefs.visibility,
              label: (v) => v.label,
            );
            if (picked != null) change((p) => p.copyWith(visibility: picked));
          },
        ),
        RowGroup(
          top: 20,
          dividers: true,
          children: [
            SwitchRow(
              title: 'Show my level',
              subtitle: 'Players see your Passport level',
              value: prefs.showLevel,
              onChanged: (v) => change((p) => p.copyWith(showLevel: v)),
            ),
            SwitchRow(
              title: 'Find me by mobile number',
              subtitle: 'Friends can look you up',
              value: prefs.findableByPhone,
              onChanged: (v) => change((p) => p.copyWith(findableByPhone: v)),
            ),
            SwitchRow(
              title: 'Share my location at Meets',
              subtitle: 'Only while you are checked in',
              value: prefs.shareLocationAtMeets,
              onChanged: (v) =>
                  change((p) => p.copyWith(shareLocationAtMeets: v)),
            ),
          ],
        ),
      ],
      bottom: [
        Text(
          'Changes save as you go.',
          textAlign: TextAlign.center,
          style: OgText.body(14, color: c.textMuted),
        ),
      ],
    );
  }
}

class BlockedPlayersScreen extends ConsumerWidget {
  const BlockedPlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final blocked = ref.watch(blockedPlayersProvider);
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Blocked players',
          topGap: 8,
          lead: 'Blocked players cannot see your profile, message you or join your Meets.',
        ),
        const SizedBox(height: 12),
        ...switch (blocked) {
          AsyncData(:final value) when value.isEmpty => [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "You haven't blocked anyone.",
                style: OgText.body(16, color: c.textMuted),
              ),
            ),
          ],
          AsyncData(:final value) => [
            for (final p in value)
              ListRow(
                leading: Avatar(
                  initials: p.initials,
                  tone: AvatarTone.forId(p.id),
                  imageUrl: p.avatarUrl,
                ),
                title: p.displayName,
                subtitle: p.handle,
                trailing: OgButton.outline(
                  label: 'Unblock',
                  height: 40,
                  fontSize: 15,
                  expand: false,
                  onPressed: () async {
                    try {
                      await ref
                          .read(blockedPlayersProvider.notifier)
                          .unblock(p.id);
                      if (context.mounted) {
                        showOgToast(context, '${p.displayName} is unblocked');
                      }
                    } on AuthFailure catch (e) {
                      if (context.mounted) {
                        showOgToast(context, e.message, error: true);
                      }
                    }
                  },
                ),
              ),
          ],
          AsyncError() => [
            const OgErrorText("Can't load blocked players. Try again."),
          ],
          _ => [
            const Padding(
              padding: EdgeInsets.all(24),
              child: CupertinoActivityIndicator(),
            ),
          ],
        },
      ],
    );
  }
}

/// Common questions and a way to reach support.
class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  static const _faqs = [
    (
      'How do I join a Meet?',
      'Open a Meet from Home or Discover, then tap Join. If it is full you can join the waitlist.',
    ),
    (
      'How do I change my skill level?',
      'Go to Profile, open Player profile, and edit your sport. Levels run from 1.0 to 8.0.',
    ),
    (
      'Where is my refund?',
      'Refunds go to your Wallet first, then to your card or bank if you ask.',
    ),
    (
      'How do I block or report someone?',
      'Open their profile, tap the three dots, then choose Report or block.',
    ),
  ];

  String _query = '';
  final _open = <int>{};

  Future<void> _contact() async {
    final controller = TextEditingController();
    final sent = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => _SupportSheet(controller: controller),
    );
    final message = controller.text.trim();
    controller.dispose();
    if (sent != true || message.isEmpty || !mounted) return;
    try {
      await ref.read(socialRepositoryProvider).contactSupport(message);
      if (mounted) showOgToast(context, "Sent. We'll reply by email.");
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final q = _query.toLowerCase();
    final shown = [
      for (var i = 0; i < _faqs.length; i++)
        if (q.isEmpty ||
            _faqs[i].$1.toLowerCase().contains(q) ||
            _faqs[i].$2.toLowerCase().contains(q))
          i,
    ];
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(title: 'Help', topGap: 8),
        const SizedBox(height: 16),
        OgSearchField(
          hint: 'Search help',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SectionLabel('Common questions', top: 22, size: 13),
        for (final i in shown)
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  button: true,
                  expanded: _open.contains(i),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(
                      () => _open.contains(i) ? _open.remove(i) : _open.add(i),
                    ),
                    child: SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _faqs[i].$1,
                              style: OgText.body(
                                16,
                                weight: FontWeight.w600,
                                color: c.text,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _open.contains(i) ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: OgIcon(
                              OgIcons.chevronDown,
                              size: 20,
                              color: c.text,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: _open.contains(i)
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _faqs[i].$2,
                            style: OgText.body(
                              15,
                              height: 1.45,
                              color: c.textMuted,
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              'No answers match. Contact support below.',
              style: OgText.body(15, color: c.textMuted),
            ),
          ),
        const SizedBox(height: 12),
        KitLink(
          'Read the community rules',
          onPressed: () => context.push(Routes.communityRules),
        ),
      ],
      bottom: [
        OgButton.outline(
          label: 'Contact support',
          height: 52,
          fontSize: 18,
          onPressed: _contact,
        ),
      ],
    );
  }
}

class _SupportSheet extends StatelessWidget {
  const _SupportSheet({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Contact support',
                style: OgText.section.copyWith(color: c.text),
              ),
              const SizedBox(height: 12),
              OgTextArea(
                label: 'How can we help?',
                controller: controller,
                maxLength: 2000,
                minLines: 4,
                hint: 'Tell us what happened',
              ),
              const SizedBox(height: 16),
              OgButton(
                label: 'Send',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Log out?" confirmation.
class LogOutScreen extends ConsumerStatefulWidget {
  const LogOutScreen({super.key});

  @override
  ConsumerState<LogOutScreen> createState() => _LogOutScreenState();
}

class _LogOutScreenState extends ConsumerState<LogOutScreen> {
  bool _busy = false;

  Future<void> _logOut() async {
    setState(() => _busy = true);
    ref.invalidate(onboardingControllerProvider);
    await ref.read(authRepositoryProvider).signOut();
    // The router sends signed-out players to Welcome.
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return OgFlowScreen(
      asPage: true,
      children: [
        const SizedBox(height: 160),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.primaryTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: OgIcon(OgIcons.logOut, size: 34, color: c.link),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            'Log out?',
            textAlign: TextAlign.center,
            style: OgText.h1.copyWith(color: c.text),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can log back in with your email, mobile or username.',
          textAlign: TextAlign.center,
          style: OgText.lead(c.textMuted),
        ),
      ],
      bottom: [
        OgButton(label: 'Log out', loading: _busy, onPressed: _logOut),
        const SizedBox(height: 10),
        OgButton.outline(
          label: 'Cancel',
          height: 52,
          fontSize: 18,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

/// Confirms a new mobile number with the 6-digit SMS code.
class VerifyPhoneChangeScreen extends ConsumerStatefulWidget {
  const VerifyPhoneChangeScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<VerifyPhoneChangeScreen> createState() =>
      _VerifyPhoneChangeScreenState();
}

class _VerifyPhoneChangeScreenState
    extends ConsumerState<VerifyPhoneChangeScreen> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy || _code.text.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyPhoneChange(widget.phone, _code.text);
      ref.invalidate(privateInfoProvider);
      if (!mounted) return;
      showOgToast(context, 'Mobile number updated');
      context.go(Routes.settings);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
      _code.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        OgHeading(
          title: 'Verify your number',
          lead:
              'We texted a 6-digit code to ${widget.phone}. It works for 10 minutes.',
        ),
        const SizedBox(height: 32),
        OgCodeInput(
          controller: _code,
          hasError: _error != null,
          onCompleted: (_) => _verify(),
        ),
        if (_error != null) OgErrorText(_error!),
      ],
      bottom: [OgButton(label: 'Verify', loading: _busy, onPressed: _verify)],
    );
  }
}
