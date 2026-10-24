import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Keeps the session refresh token in the iOS Keychain and releases it only
/// after Face ID (or the device passcode) succeeds.
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
  static const _key = 'og_refresh_token';

  Future<bool> get isAvailable async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  static const _enabledKey = 'og_faceid_enabled';

  /// Face ID unlock is on unless the player switched it off.
  Future<bool> get isEnabled async =>
      await _storage.read(key: _enabledKey) != 'false';

  Future<void> setEnabled(bool enabled) async {
    await _storage.write(key: _enabledKey, value: '$enabled');
    if (!enabled) await clear();
  }

  Future<void> saveRefreshToken(String token) async {
    if (await isEnabled) await _storage.write(key: _key, value: token);
  }

  Future<String?> readRefreshToken() => _storage.read(key: _key);

  Future<void> clear() => _storage.delete(key: _key);

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
