import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_layout.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/cupertino_sheets.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_fields.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/settings_list.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/validators.dart';
import '../application/avatar_upload.dart';
import '../application/settings_providers.dart';
import '../domain/my_profile.dart';
import '../domain/settings_models.dart';
import 'settings_screens.dart' show ImageSourceChoice;

enum _PhotoChoice { camera, library, remove }

/// Edit profile: the photo, name and username, then the rows about you
/// (owner, 9 Nov 2026). Each row opens its own screen, which saves and comes
/// back here with "Saved". Right after onboarding, Continue goes on to
/// Account information.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.onboarding = false});

  final bool onboarding;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _uploading = false;

  MyProfileNotifier get _notifier => ref.read(myProfileProvider.notifier);

  Future<void> _open(String route) async {
    final saved = await context.push<bool>(route);
    if (saved == true && mounted) showOgToast(context, 'Saved');
  }

  Future<void> _pickGender(MyProfile p) async {
    final picked = await showOgListPicker<Gender>(
      context: context,
      title: 'Gender',
      items: Gender.values,
      selected: p.gender,
      label: (g) => g.label,
    );
    if (picked == null || picked == p.gender) return;
    try {
      await _notifier.save(gender: picked);
      if (mounted) showOgToast(context, 'Saved');
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) showOgToast(context, 'Link copied');
  }

  Future<void> _photo(MyProfile p) async {
    final choice = await showCupertinoModalPopup<_PhotoChoice>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Profile photo'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(_PhotoChoice.camera),
            child: const Text('Take photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(_PhotoChoice.library),
            child: const Text('Choose from library'),
          ),
          if (p.avatarUrl != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(_PhotoChoice.remove),
              child: const Text('Remove photo'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    try {
      if (choice == _PhotoChoice.remove) {
        setState(() => _uploading = true);
        await _notifier.removePhoto();
        return;
      }
      final picked = await pickAvatar(
        choice == _PhotoChoice.camera
            ? ImageSourceChoice.camera
            : ImageSourceChoice.library,
      );
      if (picked == null || !mounted) return;
      setState(() => _uploading = true);
      await _notifier.uploadPhoto(picked.$1, picked.$2);
    } on AuthFailure catch (e) {
      // The old photo stays.
      if (mounted) showOgToast(context, e.message, error: true);
    } on PlatformException {
      if (mounted) {
        showOgToast(
          context,
          "Your photo didn't change. Check OlympusGO can use the camera and "
          'photos, then try again.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider);
    final Widget body;
    if (profile.hasValue) {
      body = _content(profile.value);
    } else if (profile.hasError && !profile.isLoading) {
      body = SettingsLoadError(
        message:
            "We couldn't load your profile. Check your connection, then try "
            'again.',
        onRetry: _notifier.retry,
      );
    } else {
      body = _content(null);
    }
    return KitScaffold(
      header: KitHeader(
        title: 'Edit profile',
        onBack: widget.onboarding ? () => context.go(Routes.home) : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: OgSpace.s6),
      gap: 0,
      bottom: widget.onboarding
          ? [
              OgButton(
                label: 'Continue',
                onPressed: profile.hasValue
                    ? () => context.push(Routes.setupPersonal)
                    : null,
              ),
            ]
          : null,
      children: [ReadableWidth(child: body)],
    );
  }

  /// The page, with skeletons while [p] is null.
  Widget _content(MyProfile? p) {
    final loading = p == null;
    void wait() {}
    final link = p?.link;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          profile: p,
          uploading: _uploading,
          onPhoto: p == null || _uploading ? null : () => _photo(p),
        ),
        const SizedBox(height: OgSpace.s6),
        SettingsSection(
          style: SettingsStyle.outlined,
          rows: [
            SettingsRow(
              label: 'Name',
              value: p?.fullName,
              emptyText: 'Add',
              isLoading: loading,
              onTap: () => _open(Routes.editName),
            ),
            SettingsRow(
              label: 'Username',
              value: p?.username,
              emptyText: 'Add',
              isLoading: loading,
              onTap: () => _open(Routes.editUsername),
            ),
            SettingsRow(
              label: 'Profile link',
              value: p?.linkText,
              isLoading: loading,
              trailingIcon: OgIcons.copy,
              semanticHint: 'Copies the link',
              onTap: loading
                  ? wait
                  : (link == null ? null : () => _copyLink(link)),
            ),
          ],
        ),
        const SizedBox(height: OgSpace.s6),
        SettingsSection(
          style: SettingsStyle.outlined,
          label: 'About you',
          rows: [
            SettingsRow(
              label: 'Bio',
              value: p?.bioFirstLine,
              emptyText: 'Add',
              isLoading: loading,
              onTap: () => _open(Routes.editBio),
            ),
            SettingsRow(
              label: 'Sports',
              value: p?.sportsText,
              emptyText: 'Add',
              isLoading: loading,
              // Sports and levels saves itself; show what it saved.
              onTap: () async {
                await context.push(Routes.profileSports);
                _notifier.retry();
              },
            ),
            // Set from coaching and results, not here.
            SettingsRow(
              label: 'Level',
              value: p?.levelsText,
              isLoading: loading,
            ),
            SettingsRow(
              label: 'Gender',
              value: p?.gender.label,
              isLoading: loading,
              onTap: loading ? wait : () => _pickGender(p),
            ),
          ],
        ),
      ],
    );
  }
}

/// The photo with "Change photo" under it, then the name and username.
class _Header extends StatelessWidget {
  const _Header({
    required this.profile,
    required this.uploading,
    required this.onPhoto,
  });

  final MyProfile? profile;
  final bool uploading;
  final VoidCallback? onPhoto;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    const size = OgSize.avatarLarge;
    final photo = p == null
        ? const SkeletonBlock(height: size, width: size, circle: true)
        : Avatar(
            initials: p.initials,
            tone: AvatarTone.brand,
            imageUrl: p.avatarUrl,
            size: size,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          // The link below is the control a screen reader uses.
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: onPhoto,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  photo,
                  if (uploading)
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: context.tones.scrim,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const CupertinoActivityIndicator(
                        color: OgColors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: OgSpace.s2),
        Semantics(
          liveRegion: true,
          child: OgTextLink(
            uploading ? 'Updating photo…' : 'Change photo',
            onPressed: onPhoto,
          ),
        ),
        const SizedBox(height: OgSpace.s3),
        if (p == null) ...[
          const Center(
            child: FractionallySizedBox(
              widthFactor: 0.4,
              child: SkeletonBlock(height: OgSize.skeletonLine),
            ),
          ),
          const SizedBox(height: OgSpace.s2),
          const Center(
            child: FractionallySizedBox(
              widthFactor: 0.3,
              child: SkeletonBlock(height: OgSize.skeletonLine),
            ),
          ),
        ] else ...[
          Semantics(
            header: true,
            child: Text(
              p.fullName,
              textAlign: TextAlign.center,
              style: context.type.section,
            ),
          ),
          if (p.username.isNotEmpty)
            Text(
              '@${p.username}',
              textAlign: TextAlign.center,
              style: context.type.secondary,
            ),
        ],
      ],
    );
  }
}

/// The two profile details edited as free text.
enum ProfileField {
  name('Name'),
  bio('Bio');

  const ProfileField(this.label);
  final String label;

  /// Null when [value] can be saved, otherwise the sentence to show.
  String? check(String value) => switch (this) {
    ProfileField.name => value.trim().isEmpty ? 'Enter your name.' : null,
    ProfileField.bio => null,
  };
}

/// Name or bio on its own screen. Save writes it and goes back to Edit
/// profile.
class ProfileFieldScreen extends ConsumerStatefulWidget {
  const ProfileFieldScreen({super.key, required this.field});

  final ProfileField field;

  @override
  ConsumerState<ProfileFieldScreen> createState() => _ProfileFieldScreenState();
}

class _ProfileFieldScreenState extends ConsumerState<ProfileFieldScreen> {
  final _text = TextEditingController();
  String? _initial;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _fill(MyProfile p) {
    if (_initial != null) return;
    _initial = widget.field == ProfileField.name ? p.fullName : p.bio;
    if (_text.text.isEmpty) _text.text = _initial!;
  }

  Future<void> _save() async {
    if (_busy) return;
    final value = _text.text.trim();
    final invalid = widget.field.check(value);
    if (invalid != null) return setState(() => _error = invalid);
    if (value == _initial?.trim()) return context.pop(false);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notifier = ref.read(myProfileProvider.notifier);
      if (widget.field == ProfileField.name) {
        await notifier.save(fullName: value);
      } else {
        await notifier.save(bio: value);
      }
      if (mounted) context.pop(true);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(myProfileProvider).whenData(_fill);
    final field = switch (widget.field) {
      ProfileField.name => OgTextField(
        label: 'Name',
        controller: _text,
        autofocus: true,
        autofillHints: const [AutofillHints.name],
        capitalization: TextCapitalization.words,
        // The database allows a name of 1 to 80 characters.
        inputFormatters: [LengthLimitingTextInputFormatter(80)],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
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
        OgHeading(title: widget.field.label, topGap: OgSpace.s2),
        const SizedBox(height: OgSpace.s4),
        field,
        if (_error != null && widget.field == ProfileField.bio)
          OgErrorText(_error!),
      ],
      bottom: [OgButton(label: 'Save', loading: _busy, onPressed: _save)],
    );
  }
}

enum _Availability { same, idle, checking, available, taken }

/// Username on its own screen: the rules, then a live check that the new
/// name is free, a moment after typing stops.
class ChangeUsernameScreen extends ConsumerStatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  ConsumerState<ChangeUsernameScreen> createState() =>
      _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends ConsumerState<ChangeUsernameScreen> {
  final _text = TextEditingController();
  String? _current;
  var _status = _Availability.idle;
  String? _error;
  Timer? _debounce;
  bool _busy = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _fill(MyProfile p) {
    if (_current != null) return;
    _current = p.username;
    if (_text.text.isEmpty) {
      _text.text = p.username;
      _status = _Availability.same;
    }
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v == _current) {
      return setState(() {
        _error = null;
        _status = _Availability.same;
      });
    }
    final invalid = Validators.username(v);
    setState(() {
      _error = invalid;
      _status = invalid == null ? _Availability.checking : _Availability.idle;
    });
    if (invalid != null) return;
    _debounce = Timer(OgMotion.debounce, () async {
      try {
        final free = await ref
            .read(profileRepositoryProvider)
            .usernameAvailable(v);
        if (!mounted || _text.text != v) return;
        setState(
          () => _status = free ? _Availability.available : _Availability.taken,
        );
      } on AuthFailure catch (e) {
        if (mounted) {
          setState(() {
            _error = e.message;
            _status = _Availability.idle;
          });
        }
      }
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_status == _Availability.same) return context.pop(false);
    final name = _text.text;
    setState(() => _busy = true);
    try {
      await ref.read(myProfileProvider.notifier).save(username: name);
      if (mounted) context.pop(true);
    } on AuthFailure catch (e) {
      setState(() {
        _error = e.message;
        _status = _Availability.idle;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(myProfileProvider).whenData(_fill);
    final c = context.og;
    final name = _text.text;
    final status = switch (_status) {
      _Availability.same => Text(
        'This is your username.',
        style: context.type.secondary,
      ),
      _Availability.checking => Text(
        'Checking…',
        style: context.type.secondary,
      ),
      _Availability.available => Row(
        children: [
          OgIcon(OgIcons.check, size: OgSize.iconSmall, color: c.success),
          const SizedBox(width: OgSpace.s2),
          Expanded(child: Text('$name is available', style: context.type.body)),
        ],
      ),
      _Availability.taken => const OgErrorText(
        'That username is taken. Try another one.',
      ),
      _Availability.idle =>
        _error == null ? const SizedBox.shrink() : OgErrorText(_error!),
    };
    return OgFlowScreen(
      asPage: true,
      children: [
        const OgBackButton(),
        const OgHeading(
          title: 'Username',
          topGap: OgSpace.s2,
          lead:
              'Players find you by it. Use 3 to 30 letters, numbers or '
              'underscores.',
        ),
        const SizedBox(height: OgSpace.s4),
        OgTextField(
          label: 'Username',
          controller: _text,
          autofocus: true,
          autocorrect: false,
          autofillHints: const [AutofillHints.newUsername],
          valid: _status == _Availability.available,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_]')),
            LengthLimitingTextInputFormatter(30),
          ],
          onChanged: _onChanged,
        ),
        const SizedBox(height: OgSpace.s2),
        Semantics(liveRegion: true, child: status),
      ],
      bottom: [
        OgButton(
          label: 'Save',
          loading: _busy,
          onPressed:
              _status == _Availability.available ||
                  _status == _Availability.same
              ? _save
              : null,
        ),
      ],
    );
  }
}
