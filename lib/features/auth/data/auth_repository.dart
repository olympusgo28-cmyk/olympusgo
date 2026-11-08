import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/config/session_storage.dart';
import '../domain/saved_account.dart';
import 'biometric_vault.dart';

/// A problem the person can act on, worded for the screen.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Passwordless sign-in: 6-digit codes through the resolve-login function,
/// plus saved-account tiles unlocked with Face ID.
abstract interface class AuthRepository {
  String? get currentUserId;
  Stream<String?> get userIdChanges;

  /// [identifier] is a mobile in +65 form, an email or a username. The answer
  /// is the same whether or not an account exists. Only a mobile can create
  /// one, with [signUp].
  Future<void> sendCode(String identifier, {bool signUp = false});
  Future<void> verifyCode(String identifier, String code);

  /// Adds a mobile number to the signed-in account.
  Future<void> startPhoneChange(String phone);
  Future<void> verifyPhoneChange(String phone, String code);

  /// Adds the optional email to the signed-in account.
  Future<void> startEmailChange(String email);
  Future<void> verifyEmailChange(String email, String code);

  Future<void> requestRecovery(String contactEmail);

  /// Accounts that can be opened from a tile on this phone.
  Future<List<SavedAccount>> savedAccounts();

  /// Keeps a tile for the signed-in account, shown from the next log-out on.
  Future<void> rememberAccount({
    required String displayName,
    String? avatarUrl,
    String? username,
  });

  /// Opens a tile with Face ID. A failed check leaves the tile in place;
  /// a token that no longer works removes it, and a fresh code is needed.
  Future<void> unlockAccount(String userId);
  Future<void> forgetAccount(String userId);

  /// Face ID was just switched on: keep this session for a tile now, rather
  /// than at the next token refresh. Returns whether it was kept.
  Future<bool> keepSessionForFaceId();
  Future<void> signOut();
}

const _badCode = AuthFailure("That code didn't work. Check it and try again.");

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, this._vault) {
    // Keep each account's newest refresh token for its Face ID tile.
    _sub = _client.auth.onAuthStateChange.listen((s) {
      final session = s.session;
      final token = session?.refreshToken;
      if (session != null && token != null) {
        _vault.saveToken(session.user.id, token);
      }
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
  Future<void> sendCode(String identifier, {bool signUp = false}) =>
      _guard(() async {
        await _client.functions.invoke(
          'resolve-login',
          body: {'action': 'send', 'identifier': identifier, 'sign_up': signUp},
        );
      });

  @override
  Future<void> verifyCode(String identifier, String code) => _guard(() async {
    final res = await _client.functions.invoke(
      'resolve-login',
      body: {'action': 'verify', 'identifier': identifier, 'code': code},
    );
    final token = (res.data as Map)['refresh_token'] as String?;
    if (token == null) throw _badCode;
    await _auth.setSession(token);
  });

  Future<void> _contactSend(String contact) => _guard(() async {
    await _client.functions.invoke(
      'resolve-login',
      body: {'action': 'contact_send', 'identifier': contact},
    );
  });

  Future<void> _contactVerify(String contact, String code) => _guard(() async {
    await _client.functions.invoke(
      'resolve-login',
      body: {'action': 'contact_verify', 'identifier': contact, 'code': code},
    );
  });

  @override
  Future<void> startPhoneChange(String phone) => _contactSend(phone);

  @override
  Future<void> verifyPhoneChange(String phone, String code) =>
      _contactVerify(phone, code);

  @override
  Future<void> startEmailChange(String email) => _contactSend(email);

  @override
  Future<void> verifyEmailChange(String email, String code) =>
      _contactVerify(email, code);

  @override
  Future<void> requestRecovery(String contactEmail) => _guard(
    () => _client.rpc(
      'account_recovery_request',
      params: {'p_email': contactEmail},
    ),
  );

  @override
  Future<List<SavedAccount>> savedAccounts() => _vault.accounts();

  /// The tile shows the mobile with most digits hidden, or the username. The
  /// email is never shown back (R-ACC-10).
  @override
  Future<void> rememberAccount({
    required String displayName,
    String? avatarUrl,
    String? username,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final private = await _client
        .from('account_private')
        .select('mobile')
        .eq('id', user.id)
        .maybeSingle();
    final phone = private?['mobile'] as String?;
    await _vault.saveAccount(
      SavedAccount(
        userId: user.id,
        displayName: displayName,
        avatarUrl: avatarUrl,
        maskedIdentifier: phone != null && phone.length >= 4
            ? '•••• ${phone.substring(phone.length - 4)}'
            : '@${username ?? ''}',
      ),
    );
  }

  @override
  Future<void> unlockAccount(String userId) async {
    final token = await _vault.unlockToken(userId, 'Unlock OlympusGO');
    if (token == null) {
      throw const AuthFailure(
        "Face ID didn't work. Log in with a code to continue.",
      );
    }
    try {
      await _guard(
        () => _auth.setSession(token),
        onAuthError: const AuthFailure(
          'That sign-in has expired. Log in with a code to continue.',
        ),
      );
    } on AuthFailure {
      await _vault.forget(userId);
      rethrow;
    }
  }

  @override
  Future<void> forgetAccount(String userId) => _vault.forget(userId);

  @override
  Future<bool> keepSessionForFaceId() async {
    final session = _auth.currentSession;
    final token = session?.refreshToken;
    if (session == null || token == null) return false;
    return _vault.saveToken(session.user.id, token);
  }

  /// With a saved tile the session stays alive on the server, held behind
  /// Face ID, so the tile can open it again. Without one it is ended.
  @override
  Future<void> signOut() async {
    final me = currentUserId;
    final tile =
        me != null &&
        await _vault.isEnabledFor(me) &&
        (await _vault.accounts()).any((a) => a.userId == me);
    sessionHttpClient.keepSession = tile;
    try {
      await _auth.signOut(scope: SignOutScope.local);
    } finally {
      sessionHttpClient.keepSession = false;
    }
  }
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
  Future<void> sendCode(String identifier, {bool signUp = false}) => _delay();

  @override
  Future<void> verifyCode(String identifier, String code) async {
    await _check(code);
    _signIn();
  }

  @override
  Future<void> startPhoneChange(String phone) => _delay();
  @override
  Future<void> verifyPhoneChange(String phone, String code) => _check(code);

  @override
  Future<void> startEmailChange(String email) => _delay();
  @override
  Future<void> verifyEmailChange(String email, String code) => _check(code);

  @override
  Future<void> requestRecovery(String contactEmail) => _delay();

  @override
  Future<List<SavedAccount>> savedAccounts() async => const [];
  @override
  Future<void> rememberAccount({
    required String displayName,
    String? avatarUrl,
    String? username,
  }) async {}
  @override
  Future<void> unlockAccount(String userId) async {
    await _delay();
    _signIn();
  }

  @override
  Future<void> forgetAccount(String userId) async {}

  /// Demo mode keeps nothing on the phone.
  @override
  Future<bool> keepSessionForFaceId() async => true;

  @override
  Future<void> signOut() async {
    _userId = null;
    _controller.add(null);
  }
}
