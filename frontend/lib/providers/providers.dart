import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/ticket_service.dart';
import '../services/agent_service.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthService(apiService);
});

// Ticket Service Provider
final ticketServiceProvider = Provider<TicketService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TicketService(apiService);
});

// Agent Service Provider
final agentServiceProvider = Provider<AgentService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AgentService(apiService);
});
