import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/providers/providers.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';

final ticketProvider =
    StateNotifierProvider<TicketNotifier, TicketState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TicketNotifier(TicketService(apiService));
});

class TicketState {
  final bool isLoading;
  final List<Ticket> tickets;
  final String? error;

  TicketState({
    this.isLoading = false,
    this.tickets = const [],
    this.error,
  });

  TicketState copyWith({
    bool? isLoading,
    List<Ticket>? tickets,
    String? error,
  }) {
    return TicketState(
      isLoading: isLoading ?? this.isLoading,
      tickets: tickets ?? this.tickets,
      error: error,
    );
  }
}

class TicketNotifier extends StateNotifier<TicketState> {
  final TicketService _ticketService;

  TicketNotifier(this._ticketService) : super(TicketState());

  Future<void> loadTickets({String? status}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final tickets = await _ticketService.getTickets(status: status);
      state = state.copyWith(isLoading: false, tickets: tickets);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createTicket(Map<String, dynamic> ticketData) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final ticket = await _ticketService.createTicket(ticketData);
      state = state.copyWith(
        isLoading: false,
        tickets: [...state.tickets, ticket],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final updatedTicket = await _ticketService.updateTicketStatus(
        ticketId,
        status,
      );
      final updatedTickets = state.tickets.map((ticket) {
        return ticket.id == ticketId ? updatedTicket : ticket;
      }).toList();
      state = state.copyWith(isLoading: false, tickets: updatedTickets);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> processQueue() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _ticketService.processQueue();
      await loadTickets(); // Reload tickets after processing queue
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
