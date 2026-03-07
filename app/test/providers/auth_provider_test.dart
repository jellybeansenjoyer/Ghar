import 'package:flutter_test/flutter_test.dart';
import 'package:ghar/providers/auth_provider.dart';
import 'package:ghar/models/user.dart';

void main() {
  group('AuthState', () {
    test('should have default values', () {
      final state = AuthState();

      expect(state.user, isNull);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isAuthenticated, false);
    });

    test('should create state with custom values', () {
      final user = AppUser(id: '1', name: 'Test');
      final state = AuthState(
        user: user,
        isLoading: true,
        error: 'Error',
        isAuthenticated: true,
      );

      expect(state.user, user);
      expect(state.isLoading, true);
      expect(state.error, 'Error');
      expect(state.isAuthenticated, true);
    });

    test('copyWith should update specified fields', () {
      final user = AppUser(id: '1', name: 'Test');
      final state = AuthState(user: user, isAuthenticated: true);

      final updated = state.copyWith(isLoading: true);

      expect(updated.user, user);
      expect(updated.isAuthenticated, true);
      expect(updated.isLoading, true);
    });

    test('copyWith should clear error when not provided', () {
      final state = AuthState(error: 'Some error');
      final updated = state.copyWith(isLoading: false);

      // error is not preserved in copyWith (it's set to the parameter value, which defaults to null)
      expect(updated.error, isNull);
    });

    test('copyWith should preserve user when not specified', () {
      final user = AppUser(id: '1', name: 'Test');
      final state = AuthState(user: user);
      final updated = state.copyWith(isLoading: true);

      expect(updated.user?.id, '1');
    });
  });

  group('AuthNotifier', () {
    late AuthNotifier notifier;

    setUp(() {
      notifier = AuthNotifier();
    });

    test('initial state should not be authenticated', () {
      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.user, isNull);
      expect(notifier.state.isLoading, false);
    });

    test('updateUser should update user in state', () {
      final user = AppUser(id: '1', name: 'Test');
      notifier.updateUser(user);

      expect(notifier.state.user?.id, '1');
      expect(notifier.state.user?.name, 'Test');
    });

    // Note: logout() calls AuthService which requires SecureStorageService.
    // Full logout integration test requires mocking the service layer.
  });
}
