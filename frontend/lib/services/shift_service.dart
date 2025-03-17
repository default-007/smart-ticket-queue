// lib/services/shift_service.dart
import 'package:dio/dio.dart';
import '../models/shift.dart';
import 'api_service.dart';
import '../utils/logger.dart';

class ShiftService {
  final ApiService _apiService;
  final logger = Logger();

  ShiftService(this._apiService);

  Future<List<Shift>> getAgentShifts(
    String agentId, {
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      logger.info('Fetching shifts for agent: $agentId');

      final params = <String, dynamic>{};
      if (startDate != null) params['startDate'] = startDate.toIso8601String();
      if (endDate != null) params['endDate'] = endDate.toIso8601String();
      if (status != null) params['status'] = status;

      final response =
          await _apiService.get('/shifts/agent/$agentId', params: params);
      logger.info('Shifts response received: ${response.statusCode}');

      if (response.data == null || response.data['data'] == null) {
        logger.warn('No shift data returned from server');
        return [];
      }

      final List<dynamic> shiftsJson = response.data['data'];
      final shifts = shiftsJson.map((json) {
        // Ensure id field is properly set from _id if needed
        if (json['_id'] != null && json['id'] == null) {
          json['id'] = json['_id'];
        }

        // Make sure breaks is defined as an array
        if (json['breaks'] == null) {
          json['breaks'] = [];
        }

        return Shift.fromJson(json);
      }).toList();

      logger.info('Parsed ${shifts.length} shifts');
      return shifts;
    } catch (e) {
      logger.error('Error fetching agent shifts: $e');

      // More detailed error logging for debugging
      if (e is DioException) {
        logger.error('DioError status: ${e.response?.statusCode}');
        logger.error('DioError message: ${e.message}');
        logger.error('DioError response data: ${e.response?.data}');
      }

      throw _handleError(e);
    }
  }

  Future<Shift?> getCurrentShift(String agentId) async {
    try {
      final response = await _apiService.get('/shifts/current/$agentId');

      if (response.data == null || response.data['data'] == null) {
        return null;
      }

      return Shift.fromJson(response.data['data']);
    } catch (e) {
      // Return null instead of throwing if no current shift
      if (e is DioException &&
          (e.response?.statusCode == 404 || e.response?.statusCode == 400)) {
        return null;
      }
      logger.error('Error fetching current shift: $e');
      throw _handleError(e);
    }
  }

  Future<Shift> startShift(String agentId) async {
    try {
      final response = await _apiService.post('/shifts/start', {
        'agentId': agentId,
      });

      return Shift.fromJson(response.data['data']);
    } catch (e) {
      logger.error('Error starting shift: $e');
      throw _handleError(e);
    }
  }

  Future<Shift> endShift(String shiftId) async {
    try {
      final response = await _apiService.put('/shifts/$shiftId/end', {});
      return Shift.fromJson(response.data['data']);
    } catch (e) {
      logger.error('Error ending shift: $e');
      throw _handleError(e);
    }
  }

  Future<Shift> scheduleBreak(String shiftId, Break breakData) async {
    try {
      final response =
          await _apiService.post('/shifts/$shiftId/breaks', breakData.toJson());
      return Shift.fromJson(response.data['data']);
    } catch (e) {
      logger.error('Error scheduling break: $e');
      throw _handleError(e);
    }
  }

  Future<Shift> startBreak(String shiftId, String breakId) async {
    try {
      final response =
          await _apiService.put('/shifts/$shiftId/breaks/$breakId/start', {});
      return Shift.fromJson(response.data['data']);
    } catch (e) {
      logger.error('Error starting break: $e');
      throw _handleError(e);
    }
  }

  Future<Shift> endBreak(String shiftId, String breakId) async {
    try {
      final response =
          await _apiService.put('/shifts/$shiftId/breaks/$breakId/end', {});
      return Shift.fromJson(response.data['data']);
    } catch (e) {
      logger.error('Error ending break: $e');
      throw _handleError(e);
    }
  }

  Future<Shift> scheduleShift(
      String agentId, DateTime start, DateTime end, String timezone) async {
    try {
      final response = await _apiService.post('/shifts/schedule', {
        'agentId': agentId,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'timezone': timezone,
      });

      return Shift.fromJson(response.data['data']);
    } catch (e) {
      logger.error('Error scheduling shift: $e');
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
        case DioExceptionType.connectionError:
          return Exception('No internet connection.');
        default:
          return Exception(
              'Failed to process shift operation: ${error.message}');
      }
    }
    return Exception('An unexpected error occurred');
  }
}
