// lib/providers/ticket_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/utils/logger.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';
import '../services/api_service.dart';

// Enum for loading states to handle different UI states
enum TicketLoadingState { initial, loading, loaded, error }

// Provider state class with proper error handling and loading states
class TicketState {
  final TicketLoadingState loadingState;
  final List<Ticket> tickets;
  final String? errorMessage;
  final DateTime? lastLoaded;
  final Map<String, dynamic>? filterParams;

  const TicketState({
    this.loadingState = TicketLoadingState.initial,
    this.tickets = const [],
    this.errorMessage,
    this.lastLoaded,
    this.filterParams,
  });

  String? get error => errorMessage;

  bool get isLoading => loadingState == TicketLoadingState.loading;
  bool get hasError => errorMessage != null;
  bool get isInitial => loadingState == TicketLoadingState.initial;
  bool get isLoaded => loadingState == TicketLoadingState.loaded;

  TicketState copyWith({
    TicketLoadingState? loadingState,
    List<Ticket>? tickets,
    String? errorMessage,
    DateTime? lastLoaded,
    Map<String, dynamic>? filterParams,
    bool clearError = false,
  }) {
    return TicketState(
      loadingState: loadingState ?? this.loadingState,
      tickets: tickets ?? this.tickets,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastLoaded: lastLoaded ?? this.lastLoaded,
      filterParams: filterParams ?? this.filterParams,
    );
  }

  // Helper methods for filtering tickets
  List<Ticket> getByStatus(String status) {
    return tickets.where((ticket) => ticket.status == status).toList();
  }

  List<Ticket> getByPriority(int priority) {
    return tickets.where((ticket) => ticket.priority == priority).toList();
  }

  List<Ticket> getOverdue() {
    return tickets.where((ticket) => ticket.isOverdue).toList();
  }

  List<Ticket> getSLABreach() {
    return tickets.where((ticket) => ticket.isSLABreached).toList();
  }
}

class TicketNotifier extends StateNotifier<TicketState> {
  final TicketService _ticketService;
  final logger = Logger();

  TicketNotifier(this._ticketService) : super(const TicketState());

  // Add debounce to prevent excessive API calls
  Timer? _debounceTimer;

  // Add cache timeout to invalidate cache after certain time
  DateTime? _lastCacheTime;
  final Duration _cacheDuration = const Duration(minutes: 1);

  bool get _isCacheValid =>
      _lastCacheTime != null &&
      DateTime.now().difference(_lastCacheTime!) < _cacheDuration;

  // Update loadTickets with improved implementation, debugging, and forceRefresh option
  Future<void> loadTickets({
    String? status,
    String? assignedTo,
    bool forceRefresh = false,
  }) async {
    // Skip if already loading
    if (state.isLoading) return;

    // Check if we can use cached data
    if (!forceRefresh && _isCacheValid && state.isLoaded) {
      logger
          .debug('Using cached ticket data from ${_lastCacheTime.toString()}');
      return;
    }

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Use debounce to prevent excessive calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        logger
            .info('Loading tickets - status: $status, assignedTo: $assignedTo');

        state = state.copyWith(
          loadingState: TicketLoadingState.loading,
          clearError: true,
          filterParams: {
            'status': status,
            'assignedTo': assignedTo,
          },
        );

        final tickets = await _ticketService.getTickets(
          status: status,
          assignedTo: assignedTo,
        );

        logger.info('Loaded ${tickets.length} tickets successfully');

        state = state.copyWith(
          loadingState: TicketLoadingState.loaded,
          tickets: tickets,
          lastLoaded: DateTime.now(),
        );

        _lastCacheTime = DateTime.now();
      } catch (e) {
        logger.error('Error loading tickets: $e');
        state = state.copyWith(
          loadingState: TicketLoadingState.error,
          errorMessage: e.toString(),
        );
      }
    });
  }

  // Create a new ticket with proper error handling
  Future<Ticket> createTicket(Map<String, dynamic> ticketData) async {
    try {
      // Set loading state
      state = state.copyWith(
        loadingState: TicketLoadingState.loading,
        clearError: true,
      );

      // Call API
      final ticket = await _ticketService.createTicket(ticketData);

      // Update state with new ticket added
      state = state.copyWith(
        loadingState: TicketLoadingState.loaded,
        tickets: [...state.tickets, ticket],
      );

      return ticket;
    } catch (e) {
      // Handle errors
      state = state.copyWith(
        loadingState: TicketLoadingState.error,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  // Update ticket status with optimistic updates for better UX
  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      // Find the existing ticket in state
      final existingTicket = state.tickets.firstWhere(
        (ticket) => ticket.id == ticketId,
        orElse: () => throw Exception('Ticket not found'),
      );

      // Create optimistic update (immediate UI update)
      final optimisticTickets = [...state.tickets];
      final index = optimisticTickets.indexWhere((t) => t.id == ticketId);

      if (index != -1) {
        // Create temporary optimistic ticket with updated status
        optimisticTickets[index] = existingTicket.copyWith(status: status);

        // Update state immediately for responsive UI
        state = state.copyWith(tickets: optimisticTickets);
      }

      // Make the actual API call
      final updatedTicket =
          await _ticketService.updateTicketStatus(ticketId, status);

      // Update the state again with the accurate server data
      final updatedTickets = [...state.tickets];
      final finalIndex = updatedTickets.indexWhere((t) => t.id == ticketId);

      if (finalIndex != -1) {
        updatedTickets[finalIndex] = updatedTicket;
        state = state.copyWith(tickets: updatedTickets);
      }
    } catch (e) {
      logger.error('Error updating ticket status: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
        loadingState: TicketLoadingState.error,
      );
    }
  }

  Future<void> updateTicketWithAgent(
      String ticketId, String status, String agentId) async {
    try {
      final updatedTicket =
          await _ticketService.updateTicketWithAgent(ticketId, status, agentId);

      final updatedTickets = [...state.tickets];
      final index = updatedTickets.indexWhere((t) => t.id == ticketId);

      if (index != -1) {
        updatedTickets[index] = updatedTicket;
        state = state.copyWith(tickets: updatedTickets);
      }
    } catch (e) {
      logger.error('Error assigning ticket to agent: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
        loadingState: TicketLoadingState.error,
      );
    }
  }

  Future<void> resolveEscalation(String ticketId) async {
    try {
      final updatedTicket = await _ticketService.resolveEscalation(ticketId);

      final updatedTickets = [...state.tickets];
      final index = updatedTickets.indexWhere((t) => t.id == ticketId);

      if (index != -1) {
        updatedTickets[index] = updatedTicket;
        state = state.copyWith(tickets: updatedTickets);
      }
    } catch (e) {
      logger.error('Error resolving escalation: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
        loadingState: TicketLoadingState.error,
      );
    }
  }

  // Process ticket queue
  Future<void> processQueue() async {
    try {
      await _ticketService.processQueue();

      // Reload tickets to get updated state
      await loadTickets(forceRefresh: true);
    } catch (e) {
      logger.error('Error processing ticket queue: $e');
      state = state.copyWith(
        errorMessage: e.toString(),
        loadingState: TicketLoadingState.error,
      );
    }
  }

  Future<Ticket?> getTicketById(String id) async {
    // First try to find in current state
    try {
      final ticket = state.tickets.firstWhere(
        (t) => t.id == id,
      );
      return ticket;
    } catch (e) {
      // Not found in state, so try to fetch from API
    }

    // If not in state, fetch from API
    try {
      state = state.copyWith(
        loadingState: TicketLoadingState.loading,
        clearError: true,
      );

      final ticket = await _ticketService.getTicketById(id);

      // Update state to include this ticket for future reference
      if (!state.tickets.any((t) => t.id == ticket.id)) {
        state = state.copyWith(
          tickets: [...state.tickets, ticket],
          loadingState: TicketLoadingState.loaded,
        );
      }

      return ticket;
    } catch (e) {
      state = state.copyWith(
        loadingState: TicketLoadingState.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // Clear error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(clearError: true);
    }
  }
}

// Define providers
final ticketServiceProvider = Provider<TicketService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TicketService(apiService);
});

final ticketProvider =
    StateNotifierProvider<TicketNotifier, TicketState>((ref) {
  final ticketService = ref.watch(ticketServiceProvider);
  return TicketNotifier(ticketService);
});

// Derived providers for filtered ticket lists
final queuedTicketsProvider = Provider<List<Ticket>>((ref) {
  final ticketState = ref.watch(ticketProvider);
  return ticketState.getByStatus('queued');
});

final assignedTicketsProvider = Provider<List<Ticket>>((ref) {
  final ticketState = ref.watch(ticketProvider);
  return ticketState.getByStatus('assigned');
});

final inProgressTicketsProvider = Provider<List<Ticket>>((ref) {
  final ticketState = ref.watch(ticketProvider);
  return ticketState.getByStatus('in-progress');
});

final overdueTicketsProvider = Provider<List<Ticket>>((ref) {
  final ticketState = ref.watch(ticketProvider);
  return ticketState.getOverdue();
});

final slaBreachTicketsProvider = Provider<List<Ticket>>((ref) {
  final ticketState = ref.watch(ticketProvider);
  return ticketState.getSLABreach();
});

// Import required provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
