// Q267 (audit S1) through the real API: a player's photo is stored as a path
// with no host, another player reads it from our storage with their own
// token, and the database refuses any other address.
// Skipped unless LOCAL_SUPABASE_URL, LOCAL_SUPABASE_KEY and
// LOCAL_SUPABASE_SERVICE_KEY point at `supabase start`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/avatar_address.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/local_accounts.dart';

/// A one-pixel PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final skip =
      url == null ||
          key == null ||
          Platform.environment['LOCAL_SUPABASE_SERVICE_KEY'] == null ||
          !url.contains('127.0.0.1')
      ? 'Needs a local Supabase stack'
      : null;

  Future<SupabaseClient> player(String name) async {
    final c = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
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

  Future<int> fetch(Uri address, Map<String, String> headers) async {
    final http = HttpClient();
    try {
      final request = await http.getUrl(address);
      headers.forEach(request.headers.set);
      final response = await request.close();
      await response.drain<void>();
      return response.statusCode;
    } finally {
      http.close();
    }
  }

  test('upload, read as another player, refuse an outside address', () async {
    final owner = await player('photo');
    final viewer = await player('viewer');
    final me = owner.auth.currentUser!.id;

    await owner.storage
        .from('avatars')
        .uploadBinary(
          '$me/avatar.png',
          _png,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/png',
          ),
        );
    final stored = storedAvatarPath(me, 'png', 1794400000000);
    await owner.from('profiles').update({'avatar_url': stored}).eq('id', me);

    // What another player's app is given, and what it fetches.
    final seen =
        (await viewer
                .from('profiles')
                .select('avatar_url')
                .eq('id', me)
                .single())['avatar_url']
            as String;
    expect(seen, stored);
    expect(seen, startsWith('/storage/'), reason: 'no host is stored');
    final request = avatarRequest(
      seen,
      baseUrl: url!,
      token: viewer.auth.currentSession!.accessToken,
      anonKey: key!,
    )!;
    expect(request.url.toString(), startsWith('$url/storage/v1/object/'));
    expect(await fetch(request.url, request.headers), 200);
    expect(
      await fetch(request.url, {'apikey': key}),
      isNot(200),
      reason: 'the photo is private: no token, no photo',
    );

    // The attack: every form of outside address is refused by the database.
    for (final hostile in [
      'https://attacker.example/x.png',
      'https://attacker.example/storage/v1/object/public/avatars/$me/avatar.png',
      '//attacker.example/storage/v1/object/public/avatars/$me/avatar.png',
      '/storage/v1/object/public/avatars/${viewer.auth.currentUser!.id}/avatar.png',
    ]) {
      await expectLater(
        owner.from('profiles').update({'avatar_url': hostile}).eq('id', me),
        throwsA(
          isA<PostgrestException>().having((e) => e.code, 'code', '23514'),
        ),
        reason: hostile,
      );
    }
    expect(
      (await owner
          .from('profiles')
          .select('avatar_url')
          .eq('id', me)
          .single())['avatar_url'],
      stored,
      reason: 'the photo is unchanged',
    );

    await owner.storage.from('avatars').remove(['$me/avatar.png']);
    await owner.from('profiles').update({'avatar_url': null}).eq('id', me);
  }, skip: skip);
}
