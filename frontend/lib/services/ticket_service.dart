import 'package:dio/dio.dart';
import 'package:smart_ticketing/services/api_service.dart';

import '../models/ticket.dart';

class TicketService {
  final ApiService _apiService;

  TicketService(this._apiService);

  Future<List<Ticket>> getTickets({String? status}) async {
    try {
      final response = await _apiService.get('/tickets',
          params: status != null ? {'status': status} : null);

      return (response.data['data'] as List)
          .map((json) => Ticket.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Ticket> createTicket(Map<String, dynamic> ticketData) async {
    try {
      final response = await _apiService.post('/tickets', ticketData);
      return Ticket.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Ticket> updateTicketStatus(String ticketId, String status) async {
    try {
      final response = await _apiService
          .put('/tickets/$ticketId/status', {'status': status});
      return Ticket.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> processQueue() async {
    try {
      await _apiService.post('/tickets/process-queue', {});
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
    return Exception('Failed to process ticket operation');
  }
}
