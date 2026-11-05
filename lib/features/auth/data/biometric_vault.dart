import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../domain/saved_account.dart';

/// The accounts saved on this phone. Each one's refresh token sits in its own
/// Keychain or Keystore entry and comes out only after Face ID.
///
/// On iOS the token is tied to the current biometric set: enrolling a new face
/// or finger makes iOS drop it, so the next log-in needs a fresh code. Android
/// checks in the app instead, because its equivalent would ask for a fingerprint
/// on every hourly token refresh.
class BiometricVault {
  BiometricVault({LocalAuthentication? auth, FlutterSecureStorage? storage})
    : _auth = auth ?? LocalAuthentication(),
      _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;

  static const _tokenOptions = IOSOptions(
    accessibility: KeychainAccessibility.passcode,
    accessControlFlags: [AccessControlFlag.biometryCurrentSet],
  );
  static const _accountsKey = 'og_saved_accounts';
  static const _enabledKey = 'og_faceid_enabled';
  static String _tokenKey(String userId) => 'og_refresh_token_$userId';

  Future<bool> get isAvailable async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Face ID unlock is on unless the player switched it off.
  Future<bool> get isEnabled async =>
      await _storage.read(key: _enabledKey) != 'false';

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _enabledKey, value: '$enabled');
    if (!enabled) await forgetAll();
  }

  Future<List<SavedAccount>> accounts() async {
    final raw = await _storage.read(key: _accountsKey);
    if (raw == null) return const [];
    return [
      for (final item in jsonDecode(raw) as List)
        SavedAccount.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> _writeAccounts(List<SavedAccount> accounts) => _storage.write(
    key: _accountsKey,
    value: jsonEncode([for (final a in accounts) a.toJson()]),
  );

  /// Adds or refreshes a tile, newest first.
  Future<void> saveAccount(SavedAccount account) async {
    if (!await isEnabled) return;
    final rest = (await accounts()).where((a) => a.userId != account.userId);
    await _writeAccounts([account, ...rest]);
  }

  /// Deletes before writing: updating a protected entry would prompt for Face
  /// ID on every token refresh, and deleting one does not.
  Future<void> saveToken(String userId, String token) async {
    if (!await isEnabled) return;
    try {
      await _storage.delete(key: _tokenKey(userId), iOptions: _tokenOptions);
      await _storage.write(
        key: _tokenKey(userId),
        value: token,
        iOptions: _tokenOptions,
      );
    } on PlatformException catch (e) {
      // No biometrics set up on this phone: no tile, codes still work.
      debugPrint('Token not saved: ${e.code}');
    }
  }

  /// The account's token after Face ID, or null if the check failed or iOS
  /// dropped the entry because the biometric set changed.
  Future<String?> unlockToken(String userId, String reason) async {
    if (!await authenticate(reason)) return null;
    try {
      return await _storage.read(
        key: _tokenKey(userId),
        iOptions: _tokenOptions,
      );
    } on PlatformException catch (e) {
      debugPrint('Token not read: ${e.code}');
      return null;
    }
  }

  /// Removing a tile deletes its token.
  Future<void> forget(String userId) async {
    await _storage.delete(key: _tokenKey(userId), iOptions: _tokenOptions);
    final rest = (await accounts()).where((a) => a.userId != userId).toList();
    await _writeAccounts(rest);
  }

  Future<void> forgetAll() async {
    for (final a in await accounts()) {
      await forget(a.userId);
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on LocalAuthException catch (e) {
      debugPrint('Face ID failed: ${e.code}');
      return false;
    } on PlatformException catch (e) {
      debugPrint('Face ID failed: ${e.code}');
      return false;
    }
  }
}
