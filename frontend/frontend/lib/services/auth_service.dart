import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smart_ticketing/services/api_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'auth_token';

  AuthService()
      : _apiService = ApiService(),
        _storage = const FlutterSecureStorage();

  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      await _storage.write(key: _tokenKey, value: token);
      _apiService.setToken(token);

      return User.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<User> register(String name, String email, String password) async {
    try {
      final response = await _apiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      await _storage.write(key: _tokenKey, value: token);
      _apiService.setToken(token);

      return User.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    _apiService.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data != null && data['message'] != null) {
        return Exception(data['message']);
      }
    }
    return Exception('An unexpected error occurred');
  }
}
