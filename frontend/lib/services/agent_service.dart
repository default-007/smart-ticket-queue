import 'package:dio/dio.dart';
import 'package:smart_ticketing/services/api_service.dart';

import '../models/agent.dart';
import '../models/ticket.dart';

class AgentService {
  final ApiService _apiService;

  AgentService(this._apiService);

  Future<List<Agent>> getAgents() async {
    try {
      final response = await _apiService.get('/agents');
      print('Agent response data: ${response.data}'); // Debug print

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      if (response.data['data'] == null) {
        throw Exception('Invalid response format');
      }

      final List<dynamic> agentsJson = response.data['data'];
      final agents = [];
      for (var json in agentsJson) {
        try {
          // Add the missing user field if needed
          json['user'] = json['user'] ?? null;
          // Convert _id to id if needed
          json['id'] = json['_id'];
          print('Parsing agent: ${json['name']}');
          final agent = Agent.fromJson(json);
          agents.add(agent);
        } catch (e) {
          print('Error parsing specific agent: $e');
          print('Problem JSON: $json');
        }
      }

      return agentsJson.map((json) => Agent.fromJson(json)).toList();
    } catch (e) {
      print('Error in getAgents: $e'); // Debug print
      throw _handleError(e);
    }
  }

  Future<Agent> createAgent(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/agents', data);

      if (response.data == null || response.data['data'] == null) {
        throw Exception('Invalid response format');
      }

      return Agent.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Agent> updateAgent(String agentId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/agents/$agentId', data);

      if (response.data == null || response.data['data'] == null) {
        throw Exception('Invalid response format');
      }

      return Agent.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Agent> updateAgentStatus(String agentId, String status) async {
    try {
      final response =
          await _apiService.put('/agents/$agentId/status', {'status': status});

      if (response.data == null || response.data['data'] == null) {
        throw Exception('Invalid response format');
      }

      return Agent.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Agent> getAgentByUserId(String userId) async {
    try {
      final response = await _apiService.get('/agents/user/$userId');
      if (response.data == null || response.data['data'] == null) {
        throw Exception('Invalid response format');
      }
      return Agent.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Agent>> getAvailableAgents() async {
    try {
      final response = await _apiService.get('/agents/available');
      return (response.data['data'] as List)
          .map((json) => Agent.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Agent> updateStatus(String agentId, String status) async {
    try {
      final response =
          await _apiService.put('/agents/$agentId/status', {'status': status});
      if (response.data == null || response.data['data'] == null) {
        throw Exception('Invalid response format');
      }
      return Agent.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /* Future<Agent> updateShift(String agentId, AgentShift shift) async {
    try {
      final response =
          await _apiService.put('/agents/$agentId/shift', shift.toJson());
      return Agent.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  } */

  Future<Map<String, dynamic>> claimTicket(
      String agentId, String ticketId) async {
    try {
      final response =
          await _apiService.post('/agents/$agentId/claim/$ticketId', {});

      if (response.data == null || response.data['data'] == null) {
        throw Exception('Invalid response format');
      }

      return {
        'agent': Agent.fromJson(response.data['data']['agent']),
        'ticket': response.data['data']['ticket']
      };
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    print('AgentService Error: $error'); // Debug print

    if (error is DioException) {
      print('DioError type: ${error.type}');
      print('DioError message: ${error.message}');
      print('DioError response: ${error.response?.data}');

      final data = error.response?.data;
      if (data != null && data['message'] != null) {
        return Exception(data['message']);
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception(
              'Connection timeout. Please check your internet connection.');
        case DioExceptionType.connectionError:
          return Exception('No internet connection.');
        default:
          return Exception(
              'Failed to process agent operation: ${error.message}');
      }
    }

    if (error is TypeError) {
      return Exception('Data format error: $error');
    }

    return Exception('An unexpected error occurred: $error');
  }
}
