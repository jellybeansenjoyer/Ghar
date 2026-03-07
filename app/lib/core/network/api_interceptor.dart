import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  bool _isRefreshing = false;

  AuthInterceptor(this.dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for public endpoints
    final publicPaths = [
      '/auth/send-otp',
      '/auth/verify-otp',
      '/auth/google',
      '/auth/refresh',
      '/visitors', // POST visitor is public
    ];

    final isPublic = publicPaths.any((path) => options.path.contains(path));
    if (!isPublic) {
      final token = await SecureStorageService.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await SecureStorageService.getRefreshToken();
        if (refreshToken != null) {
          final response = await Dio(
            BaseOptions(baseUrl: dio.options.baseUrl),
          ).post('/auth/refresh', data: {'refreshToken': refreshToken});

          if (response.statusCode == 200 && response.data['success'] == true) {
            final newAccessToken = response.data['data']['accessToken'];
            await SecureStorageService.saveTokens(
              accessToken: newAccessToken,
              refreshToken: refreshToken,
            );

            // Retry the failed request
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(opts);
            handler.resolve(retryResponse);
            return;
          }
        }
      } catch (_) {
        // Refresh failed - clear tokens
        await SecureStorageService.clearAll();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }
}
