import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_ticketing/services/api_service.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _apiService;
  final _storage = const FlutterSecureStorage();

  AuthService(this._apiService);

  // Test connection method
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

  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiConfig.login,
        {
          'email': email,
          'password': password,
        },
      );

      print('Login response: ${response.data}'); // Debug print

      if (response.data['token'] != null) {
        await _apiService.setToken(response.data['token']);
        print('Token saved successfully'); // Debug print
      } else {
        print('No token in response'); // Debug print
      }

      if (response.data['data'] == null) {
        print('No user data in response'); // Debug print
        throw Exception('Invalid response format');
      }

      return User.fromJson(response.data['data']);
    } catch (e) {
      print('Login error: $e'); // Debug print
      throw _handleError(e);
    }
  }

  Future<User> register(String name, String email, String password) async {
    try {
      print('Attempting registration for email: $email'); // Debug print
      final response = await _apiService.post(
        ApiConfig.register,
        {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      print('Registration response: ${response.data}'); // Debug print

      if (response.data['token'] != null) {
        await _apiService.setToken(response.data['token']);
        print('Token saved successfully'); // Debug print
      } else {
        print('No token in response'); // Debug print
      }

      if (response.data['data'] == null) {
        print('No user data in response'); // Debug print
        throw Exception('Invalid response format');
      }

      return User.fromJson(response.data['data']);
    } catch (e) {
      print('Registration error: $e'); // Debug print
      throw _handleError(e);
    }
  }

  Future<User> updateProfile(String name, String email) async {
    try {
      final response = await _apiService.put(
        '/auth/profile',
        {
          'name': name,
          'email': email,
        },
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
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
  }

  Exception _handleError(dynamic e) {
    print('Handling error: $e'); // Debug print
    if (e is DioException) {
      print('DioError response data: ${e.response?.data}'); // Debug print
      final data = e.response?.data;
      if (data != null && data['message'] != null) {
        return Exception(data['message']);
      }
    }
    return Exception('Authentication failed');
  }

  // Get current user profile
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      return User.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }
}
