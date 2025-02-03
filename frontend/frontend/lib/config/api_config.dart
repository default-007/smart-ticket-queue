class ApiConfig {
  static const String baseUrl = 'http://localhost:5000/api';
  static const String auth = '/auth';
  static const String tickets = '/tickets';
  static const String agents = '/agents';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };
}
