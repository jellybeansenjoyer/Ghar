import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import 'api_interceptor.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio dio;

  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.apiBaseUrl}/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    dio.interceptors.add(AuthInterceptor(dio));
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => developer.log('$obj', name: 'API'),
    ));
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }
}
