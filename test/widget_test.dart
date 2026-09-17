import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventguard_ai/mock/mock_state.dart';
import 'package:eventguard_ai/models/user_model.dart';
import 'package:eventguard_ai/services/vault_encryption_service.dart';

void main() {
  test('Strict Operator Registration & Encrypted Vault Authentication Test', () async {
    final state = MockState();

    // 1. Initial State verification - App starts strictly unauthenticated, no dummy user
    expect(state.isAuthenticated, false);
    expect(state.currentUser, isNull);

    // 2. Test Unregistered Dummy User Login - MUST BE REJECTED
    final dummyLogin = await state.loginWithUsernameAndPassword('random_borrower', 'password123');
    expect(dummyLogin, isNotNull);
    expect(dummyLogin, contains('ACCESS DENIED'));
    expect(state.isAuthenticated, false);

    // 3. Test Register New Operator into operators.enc
    final regError = await state.registerOperator(
      username: 'test_commander',
      password: 'defense_secret_key_2026',
      name: 'General Vikram Rao',
      role: 'Surveillance Commander',
      clearanceLevel: 'LEVEL 5 • DEFCON-1 COMMAND',
    );
    expect(regError, isNull);
    expect(state.isAuthenticated, true);
    expect(state.currentUser?.name, 'General Vikram Rao');
    expect(state.currentUser?.callsign, 'test_commander');

    // 4. Verify operators.enc exists and is encrypted (cannot be read as plain text JSON)
    final vaultFile = File('operators.enc');
    expect(await vaultFile.exists(), true);
    final encryptedContent = await vaultFile.readAsString();
    expect(encryptedContent.startsWith('BG_DEFENSE_VAULT_V1::'), true);
    expect(encryptedContent.contains('defense_secret_key_2026'), false); // Password is never stored in plain text!

    // Decrypt and verify
    final decrypted = VaultEncryptionService.decryptString(encryptedContent);
    expect(decrypted.contains('General Vikram Rao'), true);

    // 5. Test Logging in again with newly registered operator
    state.logout();
    expect(state.isAuthenticated, false);

    // Wrong password test
    final wrongPassResult = await state.loginWithUsernameAndPassword('test_commander', 'wrong_pass');
    expect(wrongPassResult, isNotNull);
    expect(state.isAuthenticated, false);

    // Correct password test
    final validLogin = await state.loginWithUsernameAndPassword('test_commander', 'defense_secret_key_2026');
    expect(validLogin, isNull);
    expect(state.isAuthenticated, true);
    expect(state.currentUser?.name, 'General Vikram Rao');

    // 6. Test GitHub Developer Token Auth
    final ghUser = UserModel(
      id: 'GH-8829',
      name: 'Niranchan (Lead)',
      callsign: 'niranchan-gif',
      email: 'niranchan@eventguard.mil',
      role: 'Lead Defense Architect',
      clearanceLevel: 'LEVEL 5 • ROOT C2 ARCHITECT',
      provider: AuthProvider.github,
    );
    state.loginWithGitHub(ghUser);
    expect(state.currentUser?.name, 'Niranchan (Lead)');
    expect(state.currentUser?.provider, AuthProvider.github);

    // Clean up test vault file if created in cwd
    if (await vaultFile.exists()) {
      await vaultFile.delete();
    }

    state.dispose();
  });
}
