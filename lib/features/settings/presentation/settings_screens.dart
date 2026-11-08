import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/country.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/cupertino_sheets.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/phone_field.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/resend_timer.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/code_copy.dart';
import '../../fitness/application/fitness_providers.dart';
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
              title: 'Edit profile',
              subtitle: 'Photo, name, username, bio and gender',
              onTap: () => context.push(Routes.editProfile),
            ),
            NavRow(
              icon: OgIcons.idCard,
              title: 'Account information',
              subtitle: 'Email, mobile, birthday, region and Face ID',
              onTap: () => context.push(Routes.accountInfo),
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
              title: 'Earnings and receipts',
              subtitle: 'What you’ve paid and what you’ve earned',
              onTap: () => context.push(Routes.earnings),
            ),
            NavRow(
              icon: OgIcons.bag,
              title: 'My orders',
              subtitle: 'Track, collect and review',
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

/// Edit profile: photo, then one card of rows for name, username, bio and
/// gender. Each row opens its own editor; Save (Settings) or Continue (right
/// after onboarding) writes them all (owner, 8 Nov 2026).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  String _name = '';
  String _username = '';
  String _bio = '';
  Gender _gender = Gender.preferNotToSay;
  String? _avatarUrl;
  bool _loaded = false;
  bool _busy = false;
  bool _uploading = false;
  String? _error;

  void _fill(AccountDetails d) {
    if (_loaded) return;
    _loaded = true;
    _name = d.fullName;
    _username = d.username;
    _bio = d.bio;
    _gender = d.gender;
    _avatarUrl = d.avatarUrl;
  }

  Future<void> _edit(ProfileField field, String value) async {
    final edited = await Navigator.of(context).push<String>(
      CupertinoPageRoute(
        builder: (_) => ProfileFieldScreen(field: field, initial: value),
      ),
    );
    if (edited == null || !mounted) return;
    setState(() {
      _error = null;
      switch (field) {
        case ProfileField.name:
          _name = edited;
        case ProfileField.username:
          _username = edited;
        case ProfileField.bio:
          _bio = edited;
      }
    });
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
    final name = _name.trim();
    final username = _username.trim();
    final invalid =
        ProfileField.name.check(name) ?? ProfileField.username.check(username);
    if (invalid != null) return setState(() => _error = invalid);
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
              bio: _bio,
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
    return OgFlowScreen(
      asPage: true,
      children: [
        OgBackButton(
          onPressed: widget.onboarding ? () => context.go(Routes.home) : null,
        ),
        const OgHeading(title: 'Edit profile', topGap: 8),
        const SizedBox(height: 16),
        // Two rows: the photo, then the link to change it.
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Avatar(
                initials: _initials(_name),
                tone: AvatarTone.brand,
                imageUrl: _avatarUrl,
                size: 72,
                fontSize: 28,
              ),
              if (_uploading)
                const CupertinoActivityIndicator(color: OgColors.white),
            ],
          ),
        ),
        const SizedBox(height: 4),
        OgTextLink(
          'Change photo',
          align: Alignment.center,
          onPressed: _changePhoto,
        ),
        const SizedBox(height: 16),
        KitCard(
          children: [
            DetailRow(
              label: 'Name',
              value: _name,
              onTap: () => _edit(ProfileField.name, _name),
            ),
            DetailRow(
              label: 'Username',
              value: _username.isEmpty ? '' : '@$_username',
              onTap: () => _edit(ProfileField.username, _username),
            ),
            DetailRow(
              label: 'Bio',
              value: _bio,
              placeholder: 'Add a few words about you',
              onTap: () => _edit(ProfileField.bio, _bio),
            ),
            DetailRow(
              label: 'Gender',
              value: _gender.label,
              onTap: _pickGender,
            ),
          ],
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

/// The three profile details with their own editor.
enum ProfileField {
  name('Name'),
  username('Username'),
  bio('Bio');

  const ProfileField(this.label);
  final String label;

  /// Null when [value] can be saved, otherwise the sentence to show.
  String? check(String value) => switch (this) {
    ProfileField.name => value.trim().isEmpty ? 'Enter your name.' : null,
    ProfileField.username =>
      RegExp(r'^[A-Za-z0-9_]{3,30}$').hasMatch(value.trim())
          ? null
          : 'Usernames use 3 to 30 letters, numbers or underscores.',
    ProfileField.bio => null,
  };
}

/// One profile detail on its own screen. Done hands the value back to Edit
/// profile, which saves it with the rest.
class ProfileFieldScreen extends StatefulWidget {
  const ProfileFieldScreen({
    super.key,
    required this.field,
    required this.initial,
  });

  final ProfileField field;
  final String initial;

  @override
  State<ProfileFieldScreen> createState() => _ProfileFieldScreenState();
}

class _ProfileFieldScreenState extends State<ProfileFieldScreen> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _done() {
    final value = _text.text.trim();
    final invalid = widget.field.check(value);
    if (invalid != null) return setState(() => _error = invalid);
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final field = switch (widget.field) {
      ProfileField.name => OgTextField(
        label: 'Name',
        controller: _text,
        autofocus: true,
        autofillHints: const [AutofillHints.name],
        capitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _done(),
        error: _error,
      ),
      ProfileField.username => OgTextField(
        label: 'Username',
        controller: _text,
        autofocus: true,
        autocorrect: false,
        autofillHints: const [AutofillHints.username],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _done(),
        error: _error,
      ),
      ProfileField.bio => OgTextArea(
        label: 'Bio',
        controller: _text,
        autofocus: true,
        minLines: 4,
        hint: 'What you play, when, and who you like to play with',
      ),
    };
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        OgHeading(title: widget.field.label, topGap: 8),
        const SizedBox(height: 16),
        field,
      ],
      bottom: [OgButton(label: 'Done', onPressed: _done)],
    );
  }
}

/// A label over its value, and a chevron when it opens something. The value
/// wraps, so a long bio shows in full.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.placeholder,
    this.leading,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  /// Shown muted when [value] is empty.
  final String? placeholder;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final empty = value.isEmpty;
    return Pressable(
      semanticLabel: '$label, ${empty ? (placeholder ?? 'empty') : value}',
      onPressed: onTap,
      dimWhenDisabled: false,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: OgText.body(13, color: c.textMuted)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            empty ? (placeholder ?? '') : value,
                            softWrap: true,
                            style: OgText.body(
                              16,
                              height: 1.35,
                              weight: empty ? FontWeight.w400 : FontWeight.w600,
                              color: empty ? c.textMuted : c.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                OgIcon(OgIcons.chevronRight, size: 20, color: c.borderControl),
              ],
            ],
          ),
        ),
      ),
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

/// Account information: email, mobile, date of birth (read only), account
/// region (read only, Q254) and the Face ID switch (off until switched on,
/// Q249). Only the owner sees these.
class AccountInfoScreen extends ConsumerStatefulWidget {
  const AccountInfoScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends ConsumerState<AccountInfoScreen> {
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

  /// The mobile's own dialling code, which can differ from the account's
  /// region (a Malaysian number on a Singapore account).
  Country get _mobileCountry =>
      Country.fromPhone(_original?.phone ?? '') ??
      _original?.country ??
      Country.singapore;

  void _fill(PrivateInfo info) {
    if (_original != null) return;
    _original = info;
    _email.text = info.email;
    final dial = _mobileCountry.dialCode.substring(1);
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
        await ref.read(authRepositoryProvider).startEmailChange(email);
        if (mounted) context.push(Routes.verifyPhoneChange, extra: email);
        return;
      }
      final digits = _mobile.text.replaceAll(RegExp(r'\D'), '');
      final phone = '${_mobileCountry.dialCode}$digits';
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

  Future<void> _setFaceId(bool on) async {
    final now = await ref.read(faceIdEnabledProvider.notifier).set(on);
    if (on && !now && mounted) {
      showOgToast(
        context,
        'Face ID is still off. Check Face ID is set up on this phone, then try again.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final info = ref.watch(privateInfoProvider);
    info.whenData(_fill);
    final faceId = ref.watch(faceIdEnabledProvider).value ?? false;
    final birthday = info.value?.birthday;
    final country = info.value?.country ?? Country.singapore;
    final born = birthday == null
        ? ''
        : '${birthday.day} ${_months[birthday.month - 1]} ${birthday.year}';
    final note = OgText.body(14, color: c.textMuted);

    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Account information',
          topGap: 8,
          lead: 'Only you can see these details.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OgTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              // The number keeps its own dialling code; it cannot be changed
              // here (Q254).
              PhoneField(
                country: _mobileCountry,
                controller: _mobile,
                label: 'Mobile',
              ),
              const SizedBox(height: 16),
              ReadOnlyField(label: 'Date of birth', value: born),
              const SizedBox(height: 6),
              Text("Your date of birth can't be changed.", style: note),
              const SizedBox(height: 16),
              ReadOnlyField(
                label: 'Account region',
                value: info.hasValue ? country.name : '',
                leading: info.hasValue ? country.flag() : null,
              ),
              const SizedBox(height: 6),
              Text(
                'Sets your currency, emergency number and local rules.',
                style: note,
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: context.tones.divider),
              SwitchRow(
                leading: OgIcon(OgIcons.faceId, size: 26, color: c.text),
                title: 'Enable Face ID',
                subtitle: 'Unlock OlympusGO with your face.',
                value: faceId,
                onChanged: _setFaceId,
              ),
            ],
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

/// A greyed, outlined field that cannot be edited (date of birth, region).
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.leading,
  });

  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Semantics(
      readOnly: true,
      label: label,
      value: value,
      child: ExcludeSemantics(
        child: InputDecorator(
          isEmpty: value.isEmpty,
          decoration: ogOutlinedDecoration(
            context,
            label: label,
            prefix: leading == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    // A Row keeps the flag at its own size, not the field's.
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [leading!],
                    ),
                  ),
          ).copyWith(enabled: false, filled: true, fillColor: c.surface),
          child: Text(value, style: OgText.input.copyWith(color: c.textMuted)),
        ),
      ),
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
    final aiStatus = ref.watch(aiStatusProvider);
    final ai = aiStatus.value;
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
            // Stays while they've agreed, so withdrawing is always possible.
            if ((ai?.open ?? false) || (ai?.agreed ?? false))
              SwitchRow(
                title: 'AI plans',
                subtitle: 'Sends a workout summary to our AI provider',
                value: ai!.agreed,
                onChanged: (v) async {
                  if (v) {
                    await context.push(Routes.fitnessAiPlan);
                    return;
                  }
                  final container = ProviderScope.containerOf(
                    context,
                    listen: false,
                  );
                  try {
                    await container
                        .read(fitnessRepositoryProvider)
                        .setAiConsent(false);
                    container.invalidate(aiStatusProvider);
                  } on AuthFailure catch (e) {
                    if (context.mounted) {
                      showOgToast(context, e.message, error: true);
                    }
                  }
                },
              ),
          ],
        ),
        // Never hide a way to withdraw in silence.
        if (aiStatus.hasError && !aiStatus.hasValue) ...[
          const SizedBox(height: 12),
          KitLink(
            'Can’t load AI plans. Try again',
            onPressed: () => ref.invalidate(aiStatusProvider),
          ),
        ],
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
      'Refunds go back to the card or PayNow you paid with. PayNow takes minutes, and a card takes 3 to 5 working days.',
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
        KitLink(
          'Terms and privacy',
          onPressed: () => context.push(Routes.legal),
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

/// Confirms a new mobile number or email with its 6-digit code.
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

  /// This screen confirms a new email as well as a new mobile.
  bool get _isEmail => widget.phone.contains('@');

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  CodeTarget get _target => _isEmail ? CodeTarget.email : CodeTarget.mobile;

  Future<bool> _resend() async {
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_isEmail) {
        await auth.startEmailChange(widget.phone);
      } else {
        await auth.startPhoneChange(widget.phone);
      }
      return true;
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
      return false;
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (_code.text.length != 6) {
      return setState(() => _error = 'Enter all 6 digits of the code.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_isEmail) {
        await auth.verifyEmailChange(widget.phone, _code.text);
      } else {
        await auth.verifyPhoneChange(widget.phone, _code.text);
      }
      ref.invalidate(privateInfoProvider);
      if (!mounted) return;
      showOgToast(
        context,
        _isEmail ? 'Email updated' : 'Mobile number updated',
      );
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
          title: codeTitle(_target),
          lead: codeLead(_target, widget.phone),
        ),
        const SizedBox(height: 32),
        OgCodeField(
          controller: _code,
          hasError: _error != null,
          onCompleted: (_) => _verify(),
        ),
        if (_error != null) OgErrorText(_error!),
        ResendTimer(onResend: _resend),
      ],
      bottom: [OgButton(label: 'Verify', loading: _busy, onPressed: _verify)],
    );
  }
}
