import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/settings_models.dart';

part 'settings_providers.g.dart';

@riverpod
Future<AccountDetails> accountDetails(Ref ref) {
  ref.watch(sessionProfileProvider);
  return ref.watch(settingsRepositoryProvider).account();
}

@riverpod
Future<PrivateInfo> privateInfo(Ref ref) =>
    ref.watch(settingsRepositoryProvider).privateInfo();

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
