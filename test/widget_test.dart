import 'package:flutter_test/flutter_test.dart';
import 'package:borderguard_ai/mock/mock_state.dart';
import 'package:borderguard_ai/models/user_model.dart';

void main() {
  test('MockState authentication & options test', () {
    final state = MockState();

    // 1. Initial State verification
    expect(state.isAuthenticated, true);
    expect(state.currentUser?.callsign, 'commander_alpha');
    expect(state.detectionSensitivity, 0.85);

    // 2. Test Invalid Login
    final error = state.loginWithUsernameAndPassword('commander_alpha', 'wrong_pass');
    expect(error, isNotNull);

    // 3. Test Valid Login with Commander Alpha
    final validLogin = state.loginWithUsernameAndPassword('commander_alpha', 'password123');
    expect(validLogin, isNull);
    expect(state.currentUser?.name, 'Arun Kumar');
    expect(state.currentUser?.provider, AuthProvider.password);

    // 4. Test Google Sign In
    state.loginWithGoogle(UserModel.googleDemoUser1);
    expect(state.currentUser?.name, 'Dr. Arjun Mehta');
    expect(state.currentUser?.provider, AuthProvider.google);

    // 5. Test Settings Update
    state.setDetectionSensitivity(0.92);
    expect(state.detectionSensitivity, 0.92);

    state.toggleAudibleSiren(false);
    expect(state.audibleSiren, false);

    // 6. Test Logout
    state.logout();
    expect(state.currentUser, isNull);
    expect(state.isAuthenticated, false);

    // Dispose timer cleanly
    state.dispose();
  });
}
