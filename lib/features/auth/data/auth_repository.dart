import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';
import 'package:influenzer_app/core/storage/auth_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(authStorageProvider),
  );
}

class AuthRepository {
  final Dio _dio;
  final AuthStorage _authStorage;

  AuthRepository(this._dio, this._authStorage);

  Future<void> login(String email, String password) async {
    final response = await _dio.post('/auth/login/email', data: {
      'email': email,
      'password': password,
    });
    await _handleAuthResponse(response);
  }

  Future<void> register(String email, String password, String role) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'role': role,
    });
    await _handleAuthResponse(response);
  }

  Future<void> googleLogin(String token) async {
    final response = await _dio.post('/auth/google', data: {
      'token': token,
    });
    await _handleAuthResponse(response);
  }

  Future<Map<String, dynamic>> socialLogin(String provider, String token, {String? name, String? avatarUrl}) async {
    // Clear any existing auth token first
    AuthTokenHolder.clear();
    
    final response = await _dio.post(
      '/auth/login/social',
      data: {
        'provider': provider,
        'token': token,
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      },
      options: Options(
        headers: {'Authorization': null}, // Explicitly remove auth header for login
      ),
    );
    await _handleAuthResponse(response);
    
    // Return user data from response
    final data = response.data;
    if (data != null && data is Map<String, dynamic>) {
      return data['user'] ?? {};
    }
    return {};
  }
  
  Future<void> connectSocial(String provider, String authCode, {String? redirectUri}) async {
    await _dio.post('/auth/connect-social', data: {
      'platform': provider,
      'auth_code': authCode,
      'redirect_uri': redirectUri ?? 'http://localhost:8081/callback',
    });
  }

  Future<void> logout() async {
    // Sign out from Google
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    
    // Clear tokens
    AuthTokenHolder.clear();
    await _authStorage.deleteToken();
  }

  Future<void> setRole(String role) async {
    await _dio.post('/auth/set-role', data: {
      'role': role,
    });
  }

  /// Initialize auth from stored token (call on app startup)
  Future<void> initializeAuth() async {
    final storedToken = await _authStorage.getToken();
    if (storedToken != null && storedToken.isNotEmpty) {
      AuthTokenHolder.setToken(storedToken);
    }
  }

  /// Extract and store token from auth response
  Future<void> _handleAuthResponse(Response response) async {
    final data = response.data;
    if (data != null && data is Map<String, dynamic>) {
      // Try common token field names
      final token = data['token'] ?? data['access_token'] ?? data['jwt'];
      if (token != null && token is String) {
        AuthTokenHolder.setToken(token);
        await _authStorage.saveToken(token);
      }
    }
  }
}

