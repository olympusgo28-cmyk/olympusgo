// Q267 (audit S1): a player's photo is fetched with the viewer's session
// token, so the address must only ever be our own storage. A stored value
// that is anything but the owner's file path fetches nothing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:olympus_go/core/avatar_address.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/avatar.dart';

const _base = 'http://127.0.0.1:54321';
const _id = 'e6000000-0000-0000-0000-000000000001';
const _own = '/storage/v1/object/public/avatars/$_id/avatar.jpeg';

({Uri url, Map<String, String> headers})? _request(
  String? stored, {
  String base = _base,
  String? token = 'session-token',
  String anonKey = 'anon-key',
}) => avatarRequest(stored, baseUrl: base, token: token, anonKey: anonKey);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('our own stored path is fetched from our storage, with the token', () {
    final r = _request('$_own?v=1794400000000')!;
    expect(
      r.url.toString(),
      '$_base/storage/v1/object/authenticated/avatars/$_id/avatar.jpeg'
      '?v=1794400000000',
    );
    expect(r.headers, {
      'Authorization': 'Bearer session-token',
      'apikey': 'anon-key',
    });
    expect(
      _request(_own.replaceFirst('.jpeg', '.png'))!.url.path,
      endsWith('/avatar.png'),
    );
  });

  test('the address is built from our project URL, whatever it is', () {
    final r = _request(_own, base: 'https://abc.supabase.co')!;
    expect(r.url.scheme, 'https');
    expect(r.url.host, 'abc.supabase.co');
    expect(r.url.hasPort, isFalse);
  });

  test('what a new upload stores is what the loader accepts', () {
    final stored = storedAvatarPath(_id, 'png', 1794400000000);
    expect(
      stored,
      '/storage/v1/object/public/avatars/$_id/avatar.png?v=1794400000000',
    );
    expect(_request(stored), isNotNull);
  });

  group('nothing is fetched, so no token leaves, for', () {
    const hostile = {
      'an outside address': 'https://attacker.example/x.png',
      'the right path on an outside host': 'https://attacker.example$_own',
      'a full address on our own host': '$_base$_own',
      'a look-alike host': 'http://127.0.0.1:54321.attacker.example$_own',
      'a user-info trick': 'http://127.0.0.1:54321@attacker.example$_own',
      'a protocol-relative address': '//attacker.example$_own',
      'a backslash host':
          r'\\attacker.example'
          '$_own',
      'another bucket':
          '/storage/v1/object/public/chat-photos/$_id/avatar.jpeg',
      'the signed-in path, which is never stored':
          '/storage/v1/object/authenticated/avatars/$_id/avatar.jpeg',
      'another file name': '/storage/v1/object/public/avatars/$_id/x.jpeg',
      'another file type': '/storage/v1/object/public/avatars/$_id/avatar.svg',
      'a path that climbs out':
          '/storage/v1/object/public/avatars/$_id/../other/avatar.jpeg',
      'an encoded slash':
          '/storage/v1/object/public/avatars/$_id%2F..%2Fx/avatar.jpeg',
      'extra query text': '$_own?v=1&next=https://attacker.example',
      'a fragment': '$_own#@attacker.example',
      'a second line': '$_own\nhttps://attacker.example',
      'a trailing new line': '$_own\n',
      'an upper-case id': '/storage/v1/object/public/avatars/E6000000-0000-0000-0000-000000000001/avatar.jpeg',
      'a leading space': ' $_own',
      'a folder that is not an id':
          '/storage/v1/object/public/avatars/@attacker.example/avatar.jpeg',
      'a script address': 'javascript:alert(1)',
      'an empty value': '',
    };
    for (final MapEntry(key: what, value: stored) in hostile.entries) {
      test(what, () => expect(_request(stored), isNull));
    }

    test('no photo', () => expect(_request(null), isNull));
    test('a signed-out viewer', () {
      expect(_request(_own, token: null), isNull);
      expect(_request(_own, token: ''), isNull);
    });
    test('demo mode, with no key', () {
      expect(_request(_own, anonKey: ''), isNull);
    });
    test('a project URL that is not a plain https address (a mistyped '
        'build)', () {
      for (final base in [
        'not a url',
        '',
        'https://',
        '//attacker.example',
        'file:///storage',
        'https://ours.example@attacker.example',
        'http://attacker.example',
        'ftp://127.0.0.1',
      ]) {
        expect(_request(_own, base: base), isNull, reason: base);
      }
    });
  });

  group('the Avatar widget, signed in', () {
    setUp(
      () =>
          Avatar.debugSession = () =>
              (baseUrl: _base, token: 'session-token', anonKey: 'anon-key'),
    );
    tearDown(() => Avatar.debugSession = null);

    Future<void> show(WidgetTester tester, String address) => tester.pumpWidget(
      MaterialApp(
        theme: OgTheme.light(),
        home: Scaffold(
          body: Avatar(initials: 'AT', imageUrl: address),
        ),
      ),
    );

    testWidgets('fetches our own stored path from our storage, with the '
        'token', (tester) async {
      await show(tester, _own);
      final image = tester.widget<Image>(find.byType(Image)).image;
      final network =
          (image is ResizeImage ? image.imageProvider : image) as NetworkImage;
      expect(
        network.url,
        '$_base/storage/v1/object/authenticated/avatars/$_id/avatar.jpeg',
      );
      expect(
        network.headers,
        containsPair('Authorization', 'Bearer session-token'),
      );
    });

    testWidgets('fetches nothing for an outside address, even signed in', (
      tester,
    ) async {
      for (final hostile in [
        'https://attacker.example/x.png',
        'https://attacker.example$_own',
        '$_base$_own',
      ]) {
        await show(tester, hostile);
        expect(find.byType(Image), findsNothing, reason: hostile);
        expect(find.text('AT'), findsOneWidget);
      }
    });
  });

  testWidgets('signed out, an avatar draws initials and builds no network '
      'image', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OgTheme.light(),
        home: const Scaffold(
          body: Avatar(
            initials: 'AT',
            imageUrl: 'https://attacker.example/x.png',
          ),
        ),
      ),
    );
    expect(find.text('AT'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
