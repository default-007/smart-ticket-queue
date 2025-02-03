import 'package:dio/dio.dart';
import 'package:smart_ticketing/services/api_service.dart';

import '../models/agent.dart';
import '../models/ticket.dart';

class AgentService {
  final ApiService _apiService;

  AgentService(this._apiService);

  Future<Agent> getAgentByUserId(String userId) async {
    try {
      final response = await _apiService.get('/agents/user/$userId');
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
      return Agent.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Agent> updateShift(String agentId, AgentShift shift) async {
    try {
      final response =
          await _apiService.put('/agents/$agentId/shift', shift.toJson());
      return Agent.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> claimTicket(
      String agentId, String ticketId) async {
    try {
      final response =
          await _apiService.post('/agents/$agentId/claim/$ticketId', {});
      return {
        'agent': Agent.fromJson(response.data['data']['agent']),
        'ticket': Ticket.fromJson(response.data['data']['ticket'])
      };
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data != null && data['message'] != null) {
        return Exception(data['message']);
      }
    }
    return Exception('Failed to process agent operation');
  }
}
