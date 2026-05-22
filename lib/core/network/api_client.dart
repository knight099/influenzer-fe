import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:influenzer_app/core/network/mock_interceptor.dart';

part 'api_client.g.dart';

/// Global auth token holder. Set after login, cleared on logout.
class AuthTokenHolder {
  static String? _token;
  
  static void setToken(String? token) {
    _token = token;
  }
  
  static String? get token => _token;
  
  static void clear() {
    _token = null;
  }
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.0.8:8080', // Host machine local IP
      // baseUrl: 'https://api.getcolabb.com', // Production base URL
      // baseUrl: 'http://localhost:8080', // Development base URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add Auth Interceptor - attaches JWT token to all requests
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = AuthTokenHolder.token;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  // Add Mock Interceptor
  dio.interceptors.add(MockInterceptor(ref));

  // Add Logging Interceptor
  dio.interceptors.add(
    TalkerDioLogger(
      settings: const TalkerDioLoggerSettings(
        printRequestData: true,
        printResponseData: true,
        printRequestHeaders: true,
        printResponseHeaders: false,
        printResponseMessage: true,
      ),
    ),
  );
  
  return dio;
}

