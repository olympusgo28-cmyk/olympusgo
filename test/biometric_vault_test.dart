import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/core/config/env.dart';
import 'package:olympus_go/features/auth/data/biometric_vault.dart';
import 'package:olympus_go/features/auth/domain/saved_account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mei = SavedAccount(
    userId: 'u1',
    displayName: 'Mei Tan',
    maskedIdentifier: '•••• 0004',
  );
  const aaron = SavedAccount(
    userId: 'u2',
    displayName: 'Aaron Ng',
    avatarUrl: 'https://example.com/a.png',
    maskedIdentifier: '•••• 0001',
  );

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  /// Face ID is off for every account until that player switches it on.
  Future<BiometricVault> switchedOn(List<String> ids) async {
    final vault = BiometricVault();
    for (final id in ids) {
      await vault.setEnabledFor(id, true);
    }
    return vault;
  }

  Future<Map<String, String>> stored() =>
      const FlutterSecureStorage().readAll();

  test('SKIP_FACE_ID: checks pass without asking, no tile shows, nothing is '
      'saved or removed, and the tiles come back when it is off', () async {
    final real = await switchedOn(['u1']);
    await real.saveAccount(mei);
    await real.saveToken('u1', 'token-1');
    final before = await stored();

    final skipping = BiometricVault(skip: true);
    expect(skipping.skipped, isTrue);
    expect(await skipping.authenticate('Open your Account Centre'), isTrue);
    expect(await skipping.isEnabledFor('u1'), isFalse);
    expect(await skipping.accounts(), isEmpty);
    expect(await skipping.unlockToken('u1', 'Unlock OlympusGO'), isNull);
    expect(await skipping.saveToken('u1', 'token-2'), isFalse);
    await skipping.saveAccount(aaron);
    // Turning it on, off, or forgetting the tile changes nothing either.
    await skipping.setEnabledFor('u1', true);
    await skipping.setEnabledFor('u1', false);
    await skipping.forget('u1');
    expect(await stored(), before);

    expect(await BiometricVault().accounts(), [mei]);
  });

  test('without SKIP_FACE_ID every check really asks', () {
    // Tests run on a hosted URL with no flag, like a release build.
    expect(Env.skipFaceId, isFalse);
    expect(BiometricVault().skipped, isFalse);
  });

  test('SKIP_FACE_ID needs a debug build, a local stack and the flag', () {
    for (final debug in [false, true]) {
      for (final local in [false, true]) {
        for (final asked in [false, true]) {
          expect(
            Env.skipFaceIdWhen(debug: debug, local: local, asked: asked),
            debug && local && asked,
            reason: 'debug $debug, local $local, asked $asked',
          );
        }
      }
    }
  });

  test('Q249 Face ID is off on a new phone, so nothing is saved', () async {
    final vault = BiometricVault();
    expect(await vault.isEnabledFor('u1'), isFalse);
    await vault.saveAccount(mei);
    expect(await vault.saveToken('u1', 'token-1'), isFalse);
    expect(await vault.accounts(), isEmpty);
    expect(await stored(), isNot(contains('og_refresh_token_u1')));
  });

  test('Q249 one player switching it on does not switch it on for another '
      'account on the same phone', () async {
    final vault = await switchedOn(['u1']);
    await vault.saveAccount(mei);
    await vault.saveAccount(aaron);
    await vault.saveToken('u1', 'token-1');
    expect(await vault.saveToken('u2', 'token-2'), isFalse);
    expect(await vault.accounts(), [mei]);
    expect(await vault.isEnabledFor('u2'), isFalse);
    expect(await stored(), isNot(contains('og_refresh_token_u2')));
  });

  test('Q249 tiles from a build where Face ID was on by default go, with '
      'their tokens', () async {
    FlutterSecureStorage.setMockInitialValues({
      'og_faceid_enabled': 'true',
      'og_saved_accounts':
          '[{"userId":"u1","displayName":"Mei Tan","maskedIdentifier":"x"}]',
      'og_refresh_token_u1': 'old-token',
    });
    final vault = BiometricVault();
    expect(await vault.accounts(), isEmpty);
    expect(await stored(), isNot(contains('og_refresh_token_u1')));
    expect(await vault.unlockToken('u1', 'Unlock'), isNull);
  });

  test('P1-05 a saved account comes back with its tile details', () async {
    final vault = await switchedOn(['u1']);
    await vault.saveAccount(mei);
    expect(await vault.accounts(), [mei]);
  });

  test('P1-05 several accounts sit on one phone, newest first', () async {
    final vault = await switchedOn(['u1', 'u2']);
    await vault.saveAccount(mei);
    await vault.saveAccount(aaron);
    await vault.saveAccount(mei);
    expect(await vault.accounts(), [mei, aaron]);
  });

  test(
    'P1-05 removing a tile deletes its token and leaves the others',
    () async {
      final vault = await switchedOn(['u1', 'u2']);
      await vault.saveAccount(mei);
      await vault.saveAccount(aaron);
      await vault.saveToken('u1', 'token-1');
      await vault.saveToken('u2', 'token-2');
      await vault.forget('u1');
      expect(await vault.accounts(), [aaron]);
      final left = await stored();
      expect(left.containsKey('og_refresh_token_u1'), isFalse);
      expect(left['og_refresh_token_u2'], 'token-2');
    },
  );

  test('switching Face ID off clears that account only, token included, '
      'even with no tile', () async {
    final vault = await switchedOn(['u1', 'u2']);
    await vault.saveAccount(aaron);
    // A token kept before its tile was saved (the profile load failed).
    await vault.saveToken('u1', 'token-1');
    await vault.saveToken('u2', 'token-2');
    await vault.setEnabledFor('u1', false);
    expect(await stored(), isNot(contains('og_refresh_token_u1')));
    expect(await vault.accounts(), [aaron]);
    await vault.saveAccount(mei);
    expect(await vault.accounts(), [aaron], reason: 'off stays off');
  });
}
