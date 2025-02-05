import 'package:dio/dio.dart';
import '../models/workload.dart';
import 'api_service.dart';

class WorkloadService {
  final ApiService _apiService;

  WorkloadService(this._apiService);

  Future<WorkloadMetrics> getWorkloadMetrics() async {
    try {
      final response = await _apiService.get('/workload/metrics');
      return WorkloadMetrics.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<AgentWorkload>> getAgentWorkloads() async {
    try {
      final response = await _apiService.get('/workload/agents');
      return (response.data['data'] as List)
          .map((json) => AgentWorkload.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<TeamCapacity>> getTeamCapacities() async {
    try {
      final response = await _apiService.get('/workload/teams');
      return (response.data['data'] as List)
          .map((json) => TeamCapacity.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> rebalanceWorkload() async {
    try {
      await _apiService.post('/workload/rebalance', {});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> optimizeAssignments() async {
    try {
      await _apiService.post('/workload/optimize', {});
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getWorkloadPredictions() async {
    try {
      final response = await _apiService.get('/workload/predictions');
      return response.data['data'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data != null && data['message'] != null) {
        return Exception(data['message']);
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('Connection timeout. Please try again.');
        case DioExceptionType.badCertificate:
          return Exception('Network error. Please check your connection.');
        default:
          return Exception('Failed to process workload operation.');
      }
    }
    return Exception('An unexpected error occurred.');
  }
}
