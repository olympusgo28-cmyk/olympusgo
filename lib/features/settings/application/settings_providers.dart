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

/// Face ID unlock on this phone.
@riverpod
class FaceIdEnabled extends _$FaceIdEnabled {
  @override
  Future<bool> build() => ref.watch(biometricVaultProvider).isEnabled;

  Future<void> set(bool enabled) async {
    state = AsyncData(enabled);
    await ref.read(biometricVaultProvider).setEnabled(enabled);
  }
}
