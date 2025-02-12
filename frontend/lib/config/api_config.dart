import 'dart:io' show Platform;

class ApiConfig {
  // For Android Emulator, use 10.0.2.2 instead of localhost
  // For iOS Simulator, use localhost
  // For physical device, use your computer's IP address
  static const String LOCAL_IP = "192.168.1.202";

  static String get baseUrl {
    // You might want to make this configurable based on build environment
    if (Platform.isAndroid) {
      return 'http://$LOCAL_IP:5000/api';
    } else if (Platform.isIOS) {
      return 'http://localhost:5000/api';
    }
    // Default fallback
    return 'http://192.168.1.X:5000/api'; // Replace X with your local IP
  }

  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String tickets = '/tickets';
  static const String agents = '/agents';
  static const String workload = '/workload';
  static const String shifts = '/shifts';

  // Default headers
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Headers with authentication
  static Map<String, String> authHeaders(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };
}
