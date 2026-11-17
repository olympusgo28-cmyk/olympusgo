// Q268 (audit S2), R-ACC-9, through the real API: a session alone can no
// longer change the login mobile or email, nor set a password on its own
// Supabase Auth user. It first confirms it is them with a code to the contact
// already on the account.
// Skipped unless LOCAL_SUPABASE_URL and LOCAL_SUPABASE_KEY point at
// `supabase start` with the functions served.
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
  final mobile = '+6582${(stamp % 1000000).toString().padLeft(6, '0')}';
  final firstEmail = 'first.$stamp@test.local';
  final attackerEmail = 'attacker.$stamp@test.local';
  final newEmail = 'new.$stamp@test.local';

  late SupabaseClient client;
  late SupabaseAuthRepository auth;

  Future<String?> emailOnFile() async =>
      (await client
              .from('account_private')
              .select('email')
              .eq('id', client.auth.currentUser!.id)
              .single())['email']
          as String?;

  /// A call to resolve-login made by hand, as an attacker with the token would.
  Future<http.Response> byHand(Map<String, Object?> body) => http.post(
    Uri.parse('$url/functions/v1/resolve-login'),
    headers: {
      'apikey': key!,
      'Authorization': 'Bearer ${client.auth.currentSession!.accessToken}',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  /// Supabase Auth itself, with the player's own token.
  Future<int> authUpdate(Map<String, Object?> body) async => (await http.put(
    Uri.parse('$url/auth/v1/user'),
    headers: {
      'apikey': key!,
      'Authorization': 'Bearer ${client.auth.currentSession!.accessToken}',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  )).statusCode;

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
    // An account made the way the app makes one.
    await auth.sendCode(mobile, signUp: true);
    await auth.verifyCode(mobile, code);
  });

  test('straight after logging in by code, a first email needs no second '
      'proof, and that proof is then used up', () async {
    await auth.startEmailChange(firstEmail);
    await auth.verifyEmailChange(firstEmail, code);
    expect(await emailOnFile(), firstEmail);
    // Even a first email is never added silently.
    expect(
      await client
          .from('notifications')
          .select('title')
          .eq('title', 'An email was added to your login'),
      hasLength(1),
    );
    await expectLater(
      auth.startEmailChange(attackerEmail),
      throwsA(isA<StepUpNeeded>()),
    );
  }, skip: skip);

  test('the takeover: a session with no proof cannot change the email, by '
      'the app or by hand', () async {
    await expectLater(
      auth.startEmailChange(attackerEmail),
      throwsA(isA<StepUpNeeded>()),
    );
    await expectLater(
      auth.verifyEmailChange(attackerEmail, code),
      throwsA(isA<StepUpNeeded>()),
    );
    await expectLater(
      auth.startPhoneChange('+6583000001'),
      throwsA(isA<StepUpNeeded>()),
    );
    for (final action in ['contact_send', 'contact_verify']) {
      final res = await byHand({
        'action': action,
        'identifier': attackerEmail,
        'code': code,
      });
      expect(res.statusCode, 403, reason: action);
      expect(jsonDecode(res.body), {'error': 'step_up'}, reason: action);
    }
    expect(await emailOnFile(), firstEmail, reason: 'nothing changed');
  }, skip: skip);

  test('Supabase Auth itself refuses a password, an email or a phone on a '
      'player’s account', () async {
    expect(await authUpdate({'password': 'probe-Password-123!'}), isNot(200));
    expect(await authUpdate({'email': attackerEmail}), isNot(200));
    expect(await authUpdate({'phone': '+6583000002'}), isNot(200));
    final internal = client.auth.currentUser!.email!;
    final login = await http.post(
      Uri.parse('$url/auth/v1/token?grant_type=password'),
      headers: {'apikey': key!, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': internal, 'password': 'probe-Password-123!'}),
    );
    expect(login.statusCode, isNot(200), reason: 'no password log-in exists');
    expect(login.body, isNot(contains('access_token')));
  }, skip: skip);

  test('confirming it’s you sends the code to the other contact, and a '
      'wrong code proves nothing', () async {
    // Changing the email is proved by the mobile; the answer says which
    // kind, never the contact.
    final res = await byHand({'action': 'step_up_send', 'changing': 'email'});
    expect(res.statusCode, 200);
    expect(jsonDecode(res.body), {'sent': true, 'via': 'mobile'});
    expect(res.body, isNot(contains(mobile.substring(3))));

    await expectLater(
      auth.verifyStepUp(LoginContact.email, '000000'),
      throwsA(isA<AuthFailure>()),
    );
    await expectLater(
      auth.startEmailChange(newEmail),
      throwsA(isA<StepUpNeeded>()),
      reason: 'still no proof',
    );
  }, skip: skip);

  test('the honest path: confirm, then the new contact’s code; the old '
      'one is told; the proof works once', () async {
    // The code from the test above is still good: a wrong guess did not use
    // it up. (Not sent again: every send counts against the per-address
    // limit that all these tests share.)
    await auth.verifyStepUp(LoginContact.email, code);
    // That code went to the mobile, so it does not let the mobile itself
    // move: with an email on file, that needs the email's code.
    await expectLater(
      auth.startPhoneChange('+6583000004'),
      throwsA(isA<StepUpNeeded>()),
    );
    await auth.startEmailChange(newEmail);
    await auth.verifyEmailChange(newEmail, code);
    expect(await emailOnFile(), newEmail);

    final notices = await client
        .from('notifications')
        .select('title')
        .eq('title', 'Your login email was changed');
    expect(notices, hasLength(1), reason: 'the change is not silent');

    await expectLater(
      auth.startPhoneChange('+6583000003'),
      throwsA(isA<StepUpNeeded>()),
      reason: 'a second change needs a new proof',
    );
    // Changing the mobile is proved by the email.
    expect(await auth.startStepUp(LoginContact.mobile), LoginContact.email);
  }, skip: skip);

  test('Supabase Auth issues no email code or link of its own, so there is '
      'nothing to guess', () async {
    // What a thief with the session would do: read the internal address,
    // ask Auth to mail a code to it, then guess the code against Auth.
    final internal = client.auth.currentUser!.email!;
    for (final path in ['otp', 'recover']) {
      final asked = await http.post(
        Uri.parse('$url/auth/v1/$path'),
        headers: {'apikey': key!, 'Content-Type': 'application/json'},
        body: jsonEncode({'email': internal}),
      );
      expect(asked.statusCode, isNot(200), reason: path);
    }
    final again = await http.get(
      Uri.parse('$url/auth/v1/reauthenticate'),
      headers: {
        'apikey': key!,
        'Authorization': 'Bearer ${client.auth.currentSession!.accessToken}',
      },
    );
    expect(again.statusCode, isNot(200), reason: 'reauthenticate');
    for (final type in ['email', 'magiclink', 'recovery']) {
      final guess = await http.post(
        Uri.parse('$url/auth/v1/verify'),
        headers: {'apikey': key, 'Content-Type': 'application/json'},
        body: jsonEncode({'type': type, 'email': internal, 'token': code}),
      );
      expect(guess.statusCode, isNot(200), reason: 'verify $type');
      expect(guess.body, isNot(contains('access_token')));
    }
    // The app's own log-in is untouched.
    final other = SupabaseClient(
      url!,
      key,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final again2 = SupabaseAuthRepository(other, _NoVault());
    await again2.sendCode(mobile);
    await again2.verifyCode(mobile, code);
    expect(other.auth.currentUser!.id, client.auth.currentUser!.id);
    await other.auth.signOut();
  }, skip: skip);

  test('signed out, none of it answers', () async {
    final res = await http.post(
      Uri.parse('$url/functions/v1/resolve-login'),
      headers: {'apikey': key!, 'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'step_up_send', 'changing': 'email'}),
    );
    expect(res.statusCode, 401);
  }, skip: skip);
}
