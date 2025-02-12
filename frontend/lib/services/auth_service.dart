// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_ticketing/services/api_service.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthResponse {
  final User user;
  final String token;
  final String refreshToken;

  AuthResponse._internal({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory AuthResponse({
    required User user,
    required String token,
    required String refreshToken,
  }) {
    final updatedUser = user.copyWith(token: token);
    return AuthResponse._internal(
      user: updatedUser,
      token: token,
      refreshToken: refreshToken,
    );
  }

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json['data']);
    final token = json['token'] as String;
    final refreshToken = json['refreshToken'] as String;
    return AuthResponse._internal(
      user: user.copyWith(token: token),
      token: token,
      refreshToken: refreshToken,
    );
  }
}

class AuthService {
  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();

  AuthService(this._apiService);

  // Helper method to store auth tokens
  Future<void> _storeTokens(String token, String refreshToken) async {
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  Future<bool> testConnection() async {
    try {
      final response = await _apiService.get('/auth/test');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        {'email': email, 'password': password},
      );

      _validateAuthResponse(response.data);
      final authResponse = AuthResponse.fromJson(response.data);
      await _storeTokens(authResponse.token, authResponse.refreshToken);

      return authResponse;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResponse> register(
      String name, String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.register,
        {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResponse.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Could not connect to server. Please check your connection and try again.');
      }
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> validateSession(String token) async {
    try {
      final response = await _apiService.get('/auth/me');
      final user = User.fromJson(response.data['data']);
      return {
        'isValid': true,
        'user': user.copyWith(token: token),
      };
    } catch (e) {
      return {'isValid': false};
    }
  }

  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiService.post(
        '/auth/refresh-token',
        {'refreshToken': refreshToken},
      );

      final newToken = response.data['token'] as String;
      await _storage.write(key: 'token', value: newToken);
      return {'token': newToken};
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> updateProfile(String name, String email) async {
    try {
      final response = await _apiService.put(
        '/auth/profile',
        {'name': name, 'email': email},
      );
      return User.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      await _apiService.put(
        '/auth/change-password',
        {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout', {});
    } finally {
      await _storage.deleteAll();
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      return User.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  void _validateAuthResponse(Map<String, dynamic> data) {
    if (data['token'] == null ||
        data['data'] == null ||
        data['refreshToken'] == null) {
      throw Exception('Invalid response format');
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data != null && data['message'] != null) {
        return Exception(data['message']);
      }

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception(
              'Connection timeout. Please check your internet connection.');
        case DioExceptionType.connectionError:
          return Exception('No internet connection.');
        default:
          return Exception('Authentication failed: ${e.message}');
      }
    }
    return Exception('Authentication failed');
  }
}
