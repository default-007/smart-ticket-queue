import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: ApiConfig.headers,
        validateStatus: (status) {
          return status! < 500;
        },
      ),
    );

    // Add interceptors for token handling and error processing
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('REQUEST[${options.method}] => PATH: ${options.path}');
          print('REQUEST DATA => ${options.data}');
          // Get token from secure storage
          final token = await _storage.read(key: 'token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('TOKEN => $token');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
          // Handle unsuccessful responses
          if (response.statusCode != 200 && response.statusCode != 201) {
            print('ERROR RESPONSE => ${response.data}');
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: response.data['message'] ?? 'An error occurred',
            );
          }
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('ERROR[${error.response?.statusCode}] => ${error.message}');
          print('ERROR DATA => ${error.response?.data}');
          if (error.response?.statusCode == 401) {
            // Handle token expiration
            await _storage.delete(key: 'token');
            print('Token cleared due to 401 error');
            // Add code navigate to login screen here later
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: params,
      );
      return response;
    } catch (e) {
      print('GET Request Error: $e');
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, dynamic data) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
      );
      return response;
    } catch (e) {
      print('POST Request Error: $e');
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, dynamic data) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
      );
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    print('API Error: $e'); // Debug print

    if (e is DioException) {
      print('DioError response data: ${e.response?.data}'); // Debug print
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
          return Exception('No internet connection');
        default:
          return Exception('An unexpected error occurred: ${e.message}');
      }
    }

    return Exception('Authentication failed');
  }

  // Token management
  Future<void> setToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }
}

// Create a global instance
final apiService = ApiService();
