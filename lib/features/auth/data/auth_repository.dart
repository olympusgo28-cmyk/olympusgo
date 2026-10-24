import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import 'biometric_vault.dart';

/// A problem the person can act on, worded for the screen.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Passwordless sign-in: 6-digit codes by email or SMS, plus Face ID unlock.
abstract interface class AuthRepository {
  String? get currentUserId;
  Stream<String?> get userIdChanges;

  Future<void> sendEmailCode(String email, {required bool createUser});
  Future<void> verifyEmailCode(String email, String code);
  Future<void> sendSmsCode(String phone);
  Future<void> verifySmsCode(String phone, String code);
  Future<void> sendUsernameCode(String username);
  Future<void> verifyUsernameCode(String username, String code);

  /// Adds a mobile number to the signed-in account (onboarding step 6–7).
  Future<void> startPhoneChange(String phone);
  Future<void> verifyPhoneChange(String phone, String code);

  Future<void> requestRecovery(String contactEmail);
  Future<bool> get canUnlockWithBiometrics;
  Future<void> unlockWithBiometrics();
  Future<void> signOut();
}

const _badCode = AuthFailure("That code didn't work. Check it and try again.");

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, this._vault) {
    // Keep the newest refresh token in the Keychain for Face ID unlock.
    _sub = _client.auth.onAuthStateChange.listen((s) {
      final token = s.session?.refreshToken;
      if (token != null) _vault.saveRefreshToken(token);
    });
  }

  final SupabaseClient _client;
  final BiometricVault _vault;
  late final StreamSubscription<AuthState> _sub;

  GoTrueClient get _auth => _client.auth;

  void dispose() => _sub.cancel();

  @override
  String? get currentUserId => _auth.currentUser?.id;

  @override
  Stream<String?> get userIdChanges =>
      _auth.onAuthStateChange.map((s) => s.session?.user.id).distinct();

  Future<T> _guard<T>(
    Future<T> Function() run, {
    AuthFailure? onAuthError,
  }) async {
    try {
      return await run();
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.statusCode} ${e.message}');
      if (onAuthError != null) throw onAuthError;
      if (e.statusCode == '429') {
        throw const AuthFailure(
          'Too many tries. Wait a minute, then send a new code.',
        );
      }
      if (e.message.contains('SMS provider')) {
        throw const AuthFailure(
          "Text messages aren't working right now. Try again later.",
        );
      }
      // Server faults arrive as raw JSON; never show that to players.
      if ((int.tryParse(e.statusCode ?? '') ?? 0) >= 500) {
        throw const AuthFailure('Something went wrong. Try again.');
      }
      throw AuthFailure(e.message);
    } on FunctionException catch (e) {
      final details = e.details;
      final message = details is Map ? details['error'] as String? : null;
      throw AuthFailure(message ?? 'Something went wrong. Try again.');
    } on PostgrestException catch (e) {
      debugPrint('Database error: ${e.code} ${e.message}');
      throw const AuthFailure('Something went wrong. Try again.');
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Network error: $e');
      throw const AuthFailure(
        "Can't reach OlympusGO. Check your connection and try again.",
      );
    }
  }

  @override
  Future<void> sendEmailCode(String email, {required bool createUser}) =>
      _guard(
        () => _auth.signInWithOtp(email: email, shouldCreateUser: createUser),
        onAuthError: createUser
            ? null
            : const AuthFailure(
                'No account uses that email. Check it, or create an account.',
              ),
      );

  @override
  Future<void> verifyEmailCode(String email, String code) => _guard(
    () => _auth.verifyOTP(email: email, token: code, type: OtpType.email),
    onAuthError: _badCode,
  );

  @override
  Future<void> sendSmsCode(String phone) =>
      _guard(() => _auth.signInWithOtp(phone: phone, shouldCreateUser: false));

  @override
  Future<void> verifySmsCode(String phone, String code) => _guard(
    () => _auth.verifyOTP(phone: phone, token: code, type: OtpType.sms),
    onAuthError: _badCode,
  );

  @override
  Future<void> sendUsernameCode(String username) => _guard(() async {
    await _client.functions.invoke(
      'username-login',
      body: {'action': 'send', 'username': username},
    );
  });

  @override
  Future<void> verifyUsernameCode(String username, String code) =>
      _guard(() async {
        final res = await _client.functions.invoke(
          'username-login',
          body: {'action': 'verify', 'username': username, 'code': code},
        );
        final token = (res.data as Map)['refresh_token'] as String?;
        if (token == null) throw _badCode;
        await _auth.setSession(token);
      });

  @override
  Future<void> startPhoneChange(String phone) =>
      _guard(() => _auth.updateUser(UserAttributes(phone: phone)));

  @override
  Future<void> verifyPhoneChange(String phone, String code) => _guard(
    () => _auth.verifyOTP(phone: phone, token: code, type: OtpType.phoneChange),
    onAuthError: _badCode,
  );

  @override
  Future<void> requestRecovery(String contactEmail) => _guard(
    () => _client.from('account_recovery_requests').insert({
      'contact_email': contactEmail,
    }),
  );

  @override
  Future<bool> get canUnlockWithBiometrics async =>
      await _vault.isAvailable && await _vault.readRefreshToken() != null;

  @override
  Future<void> unlockWithBiometrics() async {
    final token = await _vault.readRefreshToken();
    if (token == null) {
      throw const AuthFailure(
        'Log in once with your email or mobile number to turn on Face ID.',
      );
    }
    if (!await _vault.authenticate('Unlock OlympusGO')) return;
    await _guard(
      () => _auth.setSession(token),
      onAuthError: const AuthFailure(
        'Face ID sign-in has expired. Log in with your email or mobile number.',
      ),
    );
  }

  /// Signs out on this phone only, so Face ID can unlock the account again.
  @override
  Future<void> signOut() => _auth.signOut(scope: SignOutScope.local);
}

/// Used when no Supabase key is configured: every flow works, any 6-digit
/// code is accepted and nothing leaves the device.
class DemoAuthRepository implements AuthRepository {
  final _controller = StreamController<String?>.broadcast();
  String? _userId = Env.demoSignedIn ? demoUserId : null;

  static const demoUserId = '00000000-0000-0000-0000-000000000001';

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 600));

  void _signIn() {
    _userId = demoUserId;
    _controller.add(_userId);
  }

  Future<void> _check(String code) async {
    await _delay();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) throw _badCode;
  }

  @override
  String? get currentUserId => _userId;
  @override
  Stream<String?> get userIdChanges => _controller.stream;

  @override
  Future<void> sendEmailCode(String email, {required bool createUser}) =>
      _delay();
  @override
  Future<void> verifyEmailCode(String email, String code) async {
    await _check(code);
    _signIn();
  }

  @override
  Future<void> sendSmsCode(String phone) => _delay();
  @override
  Future<void> verifySmsCode(String phone, String code) async {
    await _check(code);
    _signIn();
  }

  @override
  Future<void> sendUsernameCode(String username) => _delay();
  @override
  Future<void> verifyUsernameCode(String username, String code) async {
    await _check(code);
    _signIn();
  }

  @override
  Future<void> startPhoneChange(String phone) => _delay();
  @override
  Future<void> verifyPhoneChange(String phone, String code) => _check(code);

  @override
  Future<void> requestRecovery(String contactEmail) => _delay();
  @override
  Future<bool> get canUnlockWithBiometrics async => true;
  @override
  Future<void> unlockWithBiometrics() async {
    await _delay();
    _signIn();
  }

  @override
  Future<void> signOut() async {
    _userId = null;
    _controller.add(null);
  }
}
