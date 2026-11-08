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

  /// The accounts that switched Face ID on, on this phone. Per account, so one
  /// player turning it on never opens Face ID for another (Q249).
  static const _enabledKey = 'og_faceid_accounts';
  static String _tokenKey(String userId) => 'og_refresh_token_$userId';

  Future<bool> get isAvailable async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// True when this phone can check a face or fingerprint. A passcode alone
  /// does not count: it would let anyone who knows it open a saved account.
  Future<bool> get hasBiometrics async {
    try {
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<Set<String>> _enabled() async {
    final raw = await _storage.read(key: _enabledKey);
    if (raw == null) return {};
    return {for (final id in jsonDecode(raw) as List) id as String};
  }

  /// Face ID unlock is off for every account until that player switches it
  /// on (Q249).
  Future<bool> isEnabledFor(String userId) async =>
      (await _enabled()).contains(userId);

  /// Switching off removes this account's tile and token, and nobody else's.
  Future<void> setEnabledFor(String userId, bool enabled) async {
    final ids = await _enabled();
    enabled ? ids.add(userId) : ids.remove(userId);
    await _storage.write(key: _enabledKey, value: jsonEncode(ids.toList()));
    if (!enabled) await forget(userId);
  }

  Future<List<SavedAccount>> _stored() async {
    final raw = await _storage.read(key: _accountsKey);
    if (raw == null) return const [];
    return [
      for (final item in jsonDecode(raw) as List)
        SavedAccount.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// Tiles for accounts with Face ID on. A tile left from a build where Face
  /// ID was on by default is removed, with its token, the first time it is
  /// read.
  Future<List<SavedAccount>> accounts() async {
    final ids = await _enabled();
    final all = await _stored();
    final keep = [
      for (final a in all)
        if (ids.contains(a.userId)) a,
    ];
    for (final a in all) {
      if (!ids.contains(a.userId)) {
        await _storage.delete(
          key: _tokenKey(a.userId),
          iOptions: _tokenOptions,
        );
      }
    }
    if (keep.length != all.length) await _writeAccounts(keep);
    return keep;
  }

  Future<void> _writeAccounts(List<SavedAccount> accounts) => _storage.write(
    key: _accountsKey,
    value: jsonEncode([for (final a in accounts) a.toJson()]),
  );

  /// Adds or refreshes a tile, newest first, for an account with Face ID on.
  Future<void> saveAccount(SavedAccount account) async {
    if (!await isEnabledFor(account.userId)) return;
    final rest = (await accounts()).where((a) => a.userId != account.userId);
    await _writeAccounts([account, ...rest]);
  }

  /// Deletes before writing: updating a protected entry would prompt for Face
  /// ID on every token refresh, and deleting one does not.
  /// Returns whether the token was kept.
  Future<bool> saveToken(String userId, String token) async {
    if (!await isEnabledFor(userId)) return false;
    try {
      await _storage.delete(key: _tokenKey(userId), iOptions: _tokenOptions);
      await _storage.write(
        key: _tokenKey(userId),
        value: token,
        iOptions: _tokenOptions,
      );
      return true;
    } on PlatformException catch (e) {
      // No biometrics set up on this phone: no tile, codes still work.
      debugPrint('Token not saved: ${e.code}');
      return false;
    }
  }

  /// The account's token after Face ID, or null if the check failed or iOS
  /// dropped the entry because the biometric set changed.
  Future<String?> unlockToken(String userId, String reason) async {
    if (!await isEnabledFor(userId)) return null;
    if (!await authenticate(reason)) return null;
    String? token;
    try {
      token = await _storage.read(
        key: _tokenKey(userId),
        iOptions: _tokenOptions,
      );
    } on PlatformException catch (e) {
      debugPrint('Token not read: ${e.code}');
    }
    // Face ID passed but nothing is stored: the tile can never open, so it
    // goes, and the next log-in by code makes a working one.
    if (token == null) await forget(userId);
    return token;
  }

  /// Removing a tile deletes its token.
  Future<void> forget(String userId) async {
    await _storage.delete(key: _tokenKey(userId), iOptions: _tokenOptions);
    final rest = (await _stored()).where((a) => a.userId != userId).toList();
    await _writeAccounts(rest);
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
