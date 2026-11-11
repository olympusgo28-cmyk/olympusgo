// Photos are private to who may see them, but Flutter's image cache is keyed
// by address alone. When the signed-in player changes, the cache is emptied
// so the next viewer on this phone starts clean (Q267).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';

class _Auth implements AuthRepository {
  final changes = StreamController<String?>();

  @override
  String? get currentUserId => 'u1';

  @override
  Stream<String?> get userIdChanges => changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _png = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
    '60e6kgAAAABJRU5ErkJggg==',
  ),
);

void main() {
  testWidgets('a change of player empties the image cache; the same player '
      'keeps it', (tester) async {
    final auth = _Auth();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    addTearDown(auth.changes.close);
    container.listen(currentUserIdProvider, (_, _) {});

    await tester.pumpWidget(const SizedBox());
    Future<void> cache() => tester.runAsync(
      () => precacheImage(_png, tester.element(find.byType(SizedBox))),
    );
    Future<void> emit(String? id) async {
      await tester.runAsync(() async {
        auth.changes.add(id);
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
    }

    await cache();
    expect(imageCache.containsKey(_png), isTrue);

    await emit('u1');
    expect(imageCache.containsKey(_png), isTrue, reason: 'same player');

    await emit(null);
    expect(imageCache.containsKey(_png), isFalse, reason: 'logged out');

    await cache();
    await emit('u2');
    expect(imageCache.containsKey(_png), isFalse, reason: 'another player');
  });
}
