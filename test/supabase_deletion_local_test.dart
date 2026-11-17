// P1-14 through the real API: a request hides the player and shuts the door
// on everything but keeping the account; keeping it opens the door again.
// Skipped unless LOCAL_SUPABASE_URL and LOCAL_SUPABASE_KEY point at
// `supabase start`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/local_accounts.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final skip = url == null || key == null || !url.contains('127.0.0.1')
      ? 'Needs a local Supabase stack'
      : null;

  SupabaseClient client() => SupabaseClient(
    url!,
    key!,
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
  );

  Future<SupabaseClient> player(String name) async {
    final c = client();
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await signUpLocal(
      c,
      email: '$name.$stamp@test.local',
      password: 'test-password-123',
    );
    await c.rpc(
      'set_birthday',
      params: {'p_birthday': '1990-01-01', 'p_country': 'SG'},
    );
    await c
        .from('profiles')
        .update({
          'username': '${name}_${stamp % 10000000}',
          'full_name': '$name Test',
          'onboarding_completed': true,
          'visibility': 'everyone',
        })
        .eq('id', c.auth.currentUser!.id);
    return c;
  }

  test('request, shut door, keep', () async {
    final leaver = await player('leaver');
    final other = await player('other');
    final me = leaver.auth.currentUser!.id;

    Future<int> seen() async =>
        (await other.from('profiles').select('id').eq('id', me) as List).length;
    expect(await seen(), 1, reason: 'before: another player sees them');

    final r = await leaver.rpc(
      'account_delete_request',
      params: {'p_reason': 'Testing'},
    ) as Map;
    final until = DateTime.parse(r['erase_after'] as String);
    expect(until.difference(DateTime.now()).inDays, inInclusiveRange(29, 30));

    expect(await seen(), 0, reason: 'the profile is hidden at once');
    final status = await leaver.rpc('my_restrictions') as Map;
    expect(DateTime.parse(status['closing_until'] as String), until);

    // Everything else is refused, whatever the call.
    await expectLater(
      leaver.from('notifications').select('id'),
      throwsA(
        isA<PostgrestException>().having(
          (e) => e.message,
          'message',
          contains('closing'),
        ),
      ),
    );
    await expectLater(
      leaver.rpc('shop_products', params: {'p_mall': null}),
      throwsA(isA<PostgrestException>()),
    );
    // Asking again is harmless and returns the same date.
    final again = await leaver.rpc('account_delete_request') as Map;
    expect(DateTime.parse(again['erase_after'] as String), until);

    await leaver.rpc('account_delete_cancel');
    expect(await seen(), 1, reason: 'kept: visible again');
    final back = await leaver.rpc('my_restrictions') as Map;
    expect(back['closing_until'], isNull);
    await leaver.from('notifications').select('id'); // the door is open again
  }, skip: skip);
}
