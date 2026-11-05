import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('P1-05 a saved account comes back with its tile details', () async {
    final vault = BiometricVault();
    await vault.saveAccount(mei);
    expect(await vault.accounts(), [mei]);
  });

  test('P1-05 several accounts sit on one phone, newest first', () async {
    final vault = BiometricVault();
    await vault.saveAccount(mei);
    await vault.saveAccount(aaron);
    await vault.saveAccount(mei);
    expect(await vault.accounts(), [mei, aaron]);
  });

  test(
    'P1-05 removing a tile deletes its token and leaves the others',
    () async {
      final vault = BiometricVault();
      await vault.saveAccount(mei);
      await vault.saveAccount(aaron);
      await vault.saveToken('u1', 'token-1');
      await vault.saveToken('u2', 'token-2');
      await vault.forget('u1');
      expect(await vault.accounts(), [aaron]);
      final left = await const FlutterSecureStorage().readAll();
      expect(left.containsKey('og_refresh_token_u1'), isFalse);
      expect(left['og_refresh_token_u2'], 'token-2');
    },
  );

  test('P1-05 switching Face ID off clears every tile and token', () async {
    final vault = BiometricVault();
    await vault.saveAccount(mei);
    await vault.saveToken('u1', 'token-1');
    await vault.setEnabled(false);
    expect(await vault.accounts(), isEmpty);
    await vault.saveAccount(mei);
    expect(await vault.accounts(), isEmpty, reason: 'off stays off');
  });
}
