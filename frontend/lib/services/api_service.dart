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
        // Increase timeout durations
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
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

          // Special handling for timeouts to avoid login failures
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            // For login requests, check if token was already saved
            if (error.requestOptions.path.contains('/auth/login') ||
                error.requestOptions.path.contains('/auth/register')) {
              final token = await _storage.read(key: 'token');
              if (token != null) {
                print(
                    'Login timeout but token found - considering login successful');

                // The problem is here - the synthetic response needs user data too
                // Get the user data to fully restore the session
                try {
                  // Attempt to get user data with the existing token
                  final userResponse = await _dio.get('/auth/me',
                      options:
                          Options(headers: {'Authorization': 'Bearer $token'}));

                  // Return a more complete synthetic response
                  return handler.resolve(Response(
                    requestOptions: error.requestOptions,
                    data: {
                      'success': true,
                      'token': token,
                      'data': userResponse.data['data'], // Include user data
                    },
                    statusCode: 200,
                  ));
                } catch (userError) {
                  // If we can't get user data, the token might be invalid
                  await _storage.delete(key: 'token');
                  print('Token cleared due to validation failure');
                }
              }
            }
          }

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

  // Add method for safe API calls with better error handling
  Future<T> safeApiCall<T>(
    Future<T> Function() apiCall, {
    String errorPrefix = 'Operation failed',
    bool isRetryable = true,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        attempts++;
        return await apiCall();
      } catch (e) {
        if (e is DioException) {
          // Handle specific errors
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            print(
                'Timeout error (Attempt $attempts/$maxRetries): ${e.message}');
            if (attempts < maxRetries && isRetryable) {
              // Exponential backoff
              await Future.delayed(Duration(milliseconds: 1000 * attempts));
              continue;
            }
          }

          // Handle server validation errors (400 Bad Request)
          if (e.response?.statusCode == 400) {
            final message = e.response?.data['message'] ?? errorPrefix;
            throw Exception('Validation error: $message');
          }

          // Handle auth errors
          if (e.response?.statusCode == 401) {
            throw Exception('Authentication error: Please log in again');
          }

          // Handle server errors
          if (e.response?.statusCode != null &&
              e.response!.statusCode! >= 500) {
            throw Exception('Server error. Please try again later.');
          }

          // Handle data format errors
          final data = e.response?.data;
          if (data != null && data['message'] != null) {
            throw Exception('${data['message']}');
          }
        }

        // General error handling
        throw Exception('$errorPrefix: ${e.toString()}');
      }
    }

    throw Exception('$errorPrefix: Maximum retry attempts reached');
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return safeApiCall(
      () => _dio.get(path, queryParameters: params),
      errorPrefix: 'Failed to get data',
    );
  }

  Future<Response> post(String path, dynamic data) async {
    return safeApiCall(
      () => _dio.post(path, data: data),
      errorPrefix: 'Failed to submit data',
    );
  }

  Future<Response> put(String path, dynamic data) async {
    return safeApiCall(
      () => _dio.put(path, data: data),
      errorPrefix: 'Failed to update data',
    );
  }

  Future<Response> delete(String path) async {
    return safeApiCall(
      () => _dio.delete(path),
      errorPrefix: 'Failed to delete data',
    );
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
