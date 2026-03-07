import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/storage/secure_storage.dart';
import '../services/notification_service.dart';

class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(AuthState());

  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await SecureStorageService.getAccessToken();
      if (token != null) {
        final user = await _authService.getProfile();
        if (user != null) {
          state = AuthState(
            user: user,
            isAuthenticated: true,
            isLoading: false,
          );
          await _registerPushToken();
          return;
        }
      }
      state = AuthState(isLoading: false);
    } catch (_) {
      state = AuthState(isLoading: false);
    }
  }

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.sendOtp(phone);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.verifyOtp(phone, otp);
      state = AuthState(
        user: result.user,
        isAuthenticated: true,
        isLoading: false,
      );
      await _registerPushToken();
      return result.isNewUser;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final auth = await account.authentication;
      if (auth.idToken == null) {
        state =
            state.copyWith(isLoading: false, error: 'Failed to get ID token');
        return false;
      }

      final result = await _authService.googleSignIn(auth.idToken!);
      state = AuthState(
        user: result.user,
        isAuthenticated: true,
        isLoading: false,
      );
      await _registerPushToken();
      return result.isNewUser;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  Future<void> updateProfile({String? name, String? avatarUrl}) async {
    try {
      final updatedUser =
          await _authService.updateProfile(name: name, avatarUrl: avatarUrl);
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      state = state.copyWith(error: _extractError(e));
    }
  }

  void updateUser(AppUser user) {
    state = state.copyWith(user: user);
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.logout();
    } finally {
      state = AuthState();
    }
  }

  Future<void> _registerPushToken() async {
    try {
      final playerId = await NotificationService.getPlayerId();
      if (playerId != null) {
        await _authService.updatePushToken(playerId);
      }
    } catch (_) {}
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('message')) {
        final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(msg);
        if (match != null) return match.group(1)!;
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
