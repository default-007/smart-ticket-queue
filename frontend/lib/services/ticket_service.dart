import 'package:dio/dio.dart';
import 'package:smart_ticketing/services/api_service.dart';

import '../models/ticket.dart';

class TicketService {
  final ApiService _apiService;

  TicketService(this._apiService);

  Future<List<Ticket>> getTickets({String? status, String? assignedTo}) async {
    try {
      print('getTickets called with status: $status, assignedTo: $assignedTo');

      final queryParams = <String, dynamic>{};

      // Add parameters only if they are not null
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (assignedTo != null && assignedTo.isNotEmpty)
        queryParams['assignedTo'] = assignedTo;

      print('Sending request to /tickets with params: $queryParams');

      final response = await _apiService.get('/tickets', params: queryParams);

      print('Response received: ${response.statusCode}');

      // Check if response has expected format
      if (response.data == null) {
        print('Response data is null');
        return [];
      }

      if (response.data['data'] == null) {
        print('Response data["data"] is null');
        return [];
      }

      if (!(response.data['data'] is List)) {
        print(
            'Response data["data"] is not a List: ${response.data['data'].runtimeType}');
        return [];
      }

      print('Parsing ${(response.data['data'] as List).length} tickets');

      // Try to parse each ticket, skipping invalid ones
      final tickets = <Ticket>[];
      for (var ticketJson in response.data['data']) {
        try {
          final ticket = Ticket.fromJson(ticketJson);
          tickets.add(ticket);
        } catch (e) {
          print('Error parsing ticket: $e\nJSON: $ticketJson');
          // Skip invalid ticket rather than failing the whole operation
        }
      }

      print('Successfully parsed ${tickets.length} tickets');
      return tickets;
    } catch (e) {
      print('Error in getTickets: $e');
      throw _handleError(e);
    }
  }

  Future<Ticket> getTicketById(String id) async {
    try {
      final response = await _apiService.get('/tickets/$id');

      if (response.data == null || response.data['data'] == null) {
        throw Exception('Invalid response format or ticket not found');
      }

      return Ticket.fromJson(response.data['data']);
    } catch (e) {
      print('Error in getTicketById: $e');
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

  Future<Ticket> updateTicketWithAgent(
      String ticketId, String status, String agentId) async {
    try {
      final response = await _apiService.put(
          '/tickets/$ticketId/status', {'status': status, 'agentId': agentId});

      return Ticket.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Add batch operations for better performance
  Future<List<Ticket>> updateMultipleTickets(
      List<String> ticketIds, String status) async {
    try {
      final response = await _apiService.post(
        '/tickets/batch-update',
        {
          'ids': ticketIds,
          'status': status,
        },
      );

      return (response.data['data'] as List)
          .map((json) => Ticket.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Ticket> resolveEscalation(String ticketId) async {
    try {
      final response = await _apiService.put(
        '/tickets/$ticketId/resolve-escalation',
        {},
      );

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
    print('TicketService Error: ${e.toString()}');

    if (e is DioException) {
      final data = e.response?.data;
      if (data != null && data['message'] != null) {
        return Exception(data['message']);
      }

      // Handle specific error types
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception(
              'Connection timeout. Please check your internet connection.');
        case DioExceptionType.connectionError:
          return Exception('No internet connection.');
        default:
          return Exception('Failed to process ticket operation: ${e.message}');
      }
    }

    return Exception('Failed to process ticket operation');
  }
}
