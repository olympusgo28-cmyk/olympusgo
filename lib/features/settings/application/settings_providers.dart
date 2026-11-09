import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/account_info.dart';
import '../../profile/domain/profile.dart';
import '../domain/my_profile.dart';
import '../domain/settings_models.dart';

part 'settings_providers.g.dart';

@riverpod
Future<PrivateInfo> privateInfo(Ref ref) =>
    ref.watch(settingsRepositoryProvider).privateInfo();

/// The Account information screen. A failed load is not retried behind the
/// player's back (Riverpod would retry forever and the screen would never
/// leave its skeleton); the screen shows the error and Try again.
@Riverpod(retry: _noRetry)
class AccountInfoNotifier extends _$AccountInfoNotifier {
  @override
  Future<AccountInfo> build() async => AccountInfo.from(
    await ref.watch(settingsRepositoryProvider).privateInfo(),
  );

  /// Loads it again after an error.
  void retry() => ref.invalidateSelf();
}

Duration? _noRetry(int retryCount, Object error) => null;

/// Edit profile. Each edit saves on its own screen and shows here straight
/// away; Profile and the rest of the app reload with it. Sports load here
/// too, so a failed load shows Try again at once instead of retrying.
@Riverpod(retry: _noRetry)
class MyProfileNotifier extends _$MyProfileNotifier {
  @override
  Future<MyProfile> build() async {
    final userId = await ref.watch(currentUserIdProvider.future);
    final details = await ref.watch(settingsRepositoryProvider).account();
    final sports = userId == null
        ? const <PlayerSport>[]
        : await ref.watch(profileRepositoryProvider).sports(userId);
    return MyProfile.from(details, sports);
  }

  /// Loads it again after an error, or after Sports and levels.
  void retry() => ref.invalidateSelf();

  Future<MyProfile> get _latest async => state.value ?? await future;

  /// Saves one detail. Only that column is written, and only it changes
  /// here, so an edit never undoes another one.
  Future<void> save({
    String? fullName,
    String? username,
    String? bio,
    Gender? gender,
  }) async {
    await ref
        .read(settingsRepositoryProvider)
        .updateProfile(
          fullName: fullName,
          username: username,
          bio: bio,
          gender: gender,
        );
    final now = await _latest;
    state = AsyncData(
      now.copyWith(
        fullName: fullName?.trim() ?? now.fullName,
        username: username?.trim() ?? now.username,
        bio: bio?.trim() ?? now.bio,
        gender: gender ?? now.gender,
      ),
    );
    await ref.read(sessionProfileProvider.notifier).reload();
  }

  /// Uploads a new photo. On failure the old one stays.
  Future<void> uploadPhoto(Uint8List bytes, String extension) async {
    final url = await ref
        .read(settingsRepositoryProvider)
        .uploadAvatar(bytes, extension);
    state = AsyncData((await _latest).copyWith(avatarUrl: url));
    await ref.read(sessionProfileProvider.notifier).reload();
  }

  Future<void> removePhoto() async {
    try {
      await ref.read(settingsRepositoryProvider).removeAvatar();
    } catch (_) {
      // Show what the server now holds.
      ref.invalidateSelf();
      rethrow;
    }
    state = AsyncData((await _latest).copyWith(avatarUrl: null));
    await ref.read(sessionProfileProvider.notifier).reload();
  }
}

/// Notification switches. Each change saves straight away.
@riverpod
class NotificationSettings extends _$NotificationSettings {
  @override
  Future<NotificationPrefs> build() =>
      ref.watch(settingsRepositoryProvider).notifications();

  Future<void> change(
    NotificationPrefs Function(NotificationPrefs) edit,
  ) async {
    final before = state.value ?? const NotificationPrefs();
    final next = edit(before);
    state = AsyncData(next);
    try {
      await ref.read(settingsRepositoryProvider).saveNotifications(next);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}

/// Privacy switches. Each change saves straight away.
@riverpod
class PrivacySettings extends _$PrivacySettings {
  @override
  Future<PrivacyPrefs> build() =>
      ref.watch(settingsRepositoryProvider).privacy();

  Future<void> change(PrivacyPrefs Function(PrivacyPrefs) edit) async {
    final before = state.value ?? const PrivacyPrefs();
    final next = edit(before);
    state = AsyncData(next);
    try {
      await ref.read(settingsRepositoryProvider).savePrivacy(next);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}

/// Face ID unlock for the signed-in account on this phone. Off until this
/// player switches it on; another account on the same phone is not affected
/// (Q249).
@riverpod
class FaceIdEnabled extends _$FaceIdEnabled {
  @override
  Future<bool> build() async {
    final userId = await ref.watch(currentUserIdProvider.future);
    if (userId == null) return false;
    return ref.watch(biometricVaultProvider).isEnabledFor(userId);
  }

  /// Turning it on needs a face or fingerprint on this phone and one
  /// successful check, then keeps this session for a saved tile straight
  /// away. If any of that fails it stays off. Returns whether it ended up on.
  Future<bool> set(bool enabled) async {
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (userId == null) return false;
    final vault = ref.read(biometricVaultProvider);
    if (enabled &&
        !(await vault.hasBiometrics &&
            await vault.authenticate('Turn on Face ID for OlympusGO'))) {
      state = const AsyncData(false);
      return false;
    }
    await vault.setEnabledFor(userId, enabled);
    if (enabled &&
        !await ref.read(authRepositoryProvider).keepSessionForFaceId()) {
      await vault.setEnabledFor(userId, false);
      state = const AsyncData(false);
      return false;
    }
    state = AsyncData(enabled);
    // Saves or drops this account's tile (SessionProfile does it on load).
    if (enabled) await ref.read(sessionProfileProvider.notifier).reload();
    return enabled;
  }
}
