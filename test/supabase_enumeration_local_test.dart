// Q41, Gate A: Supabase Auth, called directly, must not tell a registered
// mobile or email from an unknown one, and must not get round the lockout
// that resolve-login enforces. Runs against a local stack with the functions
// served; skipped unless LOCAL_SUPABASE_URL and LOCAL_SUPABASE_KEY are set.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/auth/data/biometric_vault.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoVault extends BiometricVault {
  @override
  Future<bool> saveToken(String userId, String token) async => false;
}

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final skip = url == null || key == null || !url.contains('127.0.0.1')
      ? 'Needs a local Supabase stack'
      : null;

  // Test contacts get the fixed local code. Nothing is sent.
  const code = '123456';
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final mobile = '+6580000${(stamp % 1000).toString().padLeft(3, '0')}';
  final email = 'enum.$stamp@test.local';
  const unknownMobile = '+6581000000';
  final unknownEmail = 'nobody.$stamp@test.local';

  late SupabaseClient client;
  late SupabaseAuthRepository auth;

  Future<http.Response> direct(String path, Map<String, Object?> body) =>
      http.post(
        Uri.parse('$url/auth/v1/$path'),
        headers: {'apikey': key!, 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

  /// The same status and the same body, whatever was asked about.
  void expectSame(http.Response a, http.Response b, String what) {
    expect(a.statusCode, b.statusCode, reason: '$what: status differs');
    expect(a.body, b.body, reason: '$what: body differs');
    expect(a.body, isNot(contains('access_token')), reason: what);
  }

  setUpAll(() async {
    if (skip != null) return;
    client = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    auth = SupabaseAuthRepository(client, _NoVault());
    // A real account, made the way the app makes one: its address in
    // Supabase Auth is random and private.
    await auth.sendCode(mobile, signUp: true);
    await auth.verifyCode(mobile, code);
    await auth.startEmailChange(email);
    await auth.verifyEmailChange(email, code);
    await client.auth.signOut();
  });

  test(
    'a registered mobile is as unknown to Supabase Auth as any other',
    () async {
      expectSame(
        await direct('otp', {'phone': mobile}),
        await direct('otp', {'phone': unknownMobile}),
        'otp by mobile',
      );
      expectSame(
        await direct('verify', {'type': 'sms', 'phone': mobile, 'token': code}),
        await direct('verify', {
          'type': 'sms',
          'phone': unknownMobile,
          'token': code,
        }),
        'verify by mobile',
      );
    },
    skip: skip,
  );

  test(
    'a registered email is as unknown to Supabase Auth as any other',
    () async {
      expectSame(
        await direct('otp', {'email': email}),
        await direct('otp', {'email': unknownEmail}),
        'otp by email',
      );
      expectSame(
        await direct('verify', {
          'type': 'email',
          'email': email,
          'token': code,
        }),
        await direct('verify', {
          'type': 'email',
          'email': unknownEmail,
          'token': code,
        }),
        'verify by email',
      );
    },
    skip: skip,
  );

  test(
    'five wrong codes lock the target, and Supabase Auth is no way round',
    () async {
      await auth.sendCode(mobile);
      for (var i = 0; i < 5; i++) {
        await expectLater(
          auth.verifyCode(mobile, '000000'),
          throwsA(isA<AuthFailure>()),
        );
      }
      // The right code is refused while the lock holds.
      await expectLater(
        auth.verifyCode(mobile, code),
        throwsA(isA<AuthFailure>()),
      );
      expect(client.auth.currentSession, isNull);

      final skipAttempt = await direct('verify', {
        'type': 'sms',
        'phone': mobile,
        'token': code,
      });
      expect(skipAttempt.statusCode, greaterThanOrEqualTo(400));
      expect(skipAttempt.body, isNot(contains('access_token')));
    },
    skip: skip,
  );
}
