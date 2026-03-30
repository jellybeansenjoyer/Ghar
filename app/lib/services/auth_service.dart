import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<void> sendOtp(String phone) async {
    await _dio.post('/auth/send-otp', data: {'phone': phone});
  }

  Future<({AppUser user, bool isNewUser})> verifyOtp(
      String phone, String otp) async {
    final response = await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });

    final data = response.data['data'];
    await SecureStorageService.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    final user = AppUser.fromJson(data['user']);
    await SecureStorageService.saveUserId(user.id);
    final bool isNewUser = data['isNewUser'] == true;

    return (user: user, isNewUser: isNewUser);
  }

  Future<({AppUser user, bool isNewUser})> googleSignIn(
      String idToken) async {
    final response = await _dio.post('/auth/google', data: {
      'idToken': idToken,
    });

    final data = response.data['data'];
    await SecureStorageService.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    final user = AppUser.fromJson(data['user']);
    await SecureStorageService.saveUserId(user.id);
    final bool isNewUser = data['isNewUser'] == true;

    return (user: user, isNewUser: isNewUser);
  }

  Future<({AppUser user, bool isNewUser})> emailSignIn(
    String email, {
    String? name,
  }) async {
    final response = await _dio.post('/auth/email', data: {
      'email': email,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    });

    final data = response.data['data'];
    await SecureStorageService.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    final user = AppUser.fromJson(data['user']);
    await SecureStorageService.saveUserId(user.id);
    final bool isNewUser = data['isNewUser'] == true;

    return (user: user, isNewUser: isNewUser);
  }

  Future<AppUser?> getProfile() async {
    try {
      final response = await _dio.get('/users/me');
      if (response.data['success'] == true) {
        return AppUser.fromJson(response.data['data']);
      }
    } catch (_) {}
    return null;
  }

  Future<AppUser> updateProfile({String? name, String? avatarUrl}) async {
    final response = await _dio.put('/users/me', data: {
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    return AppUser.fromJson(response.data['data']);
  }

  Future<void> updatePushToken(String playerId) async {
    await _dio.put('/users/me/push-token', data: {'playerId': playerId});
  }

  Future<void> logout() async {
    try {
      final refreshToken = await SecureStorageService.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } finally {
      await SecureStorageService.clearAll();
    }
  }
}
