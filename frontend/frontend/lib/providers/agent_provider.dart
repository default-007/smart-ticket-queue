import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/providers/providers.dart';
import '../models/agent.dart';
import '../services/agent_service.dart';

final agentProvider = StateNotifierProvider<AgentNotifier, AgentState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AgentNotifier(AgentService(apiService));
});

class AgentState {
  final bool isLoading;
  final List<Agent> agents;
  final String? error;

  AgentState({
    this.isLoading = false,
    this.agents = const [],
    this.error,
  });

  AgentState copyWith({
    bool? isLoading,
    List<Agent>? agents,
    String? error,
  }) {
    return AgentState(
      isLoading: isLoading ?? this.isLoading,
      agents: agents ?? this.agents,
      error: error,
    );
  }
}

class AgentNotifier extends StateNotifier<AgentState> {
  final AgentService _agentService;

  AgentNotifier(this._agentService) : super(AgentState());

  Future<void> loadAgentByUserId(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final agent = await _agentService.getAgentByUserId(userId);
      state = state.copyWith(
        isLoading: false,
        agents: [agent], // Store the current agent in the agents list
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadAvailableAgents() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final agents = await _agentService.getAvailableAgents();
      state = state.copyWith(isLoading: false, agents: agents);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateAgentStatus(String agentId, String status) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final updatedAgent = await _agentService.updateStatus(agentId, status);
      final updatedAgents = state.agents.map((agent) {
        return agent.id == agentId ? updatedAgent : agent;
      }).toList();
      state = state.copyWith(isLoading: false, agents: updatedAgents);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> claimTicket(String agentId, String ticketId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _agentService.claimTicket(agentId, ticketId);
      await loadAvailableAgents(); // Reload agents after claiming ticket
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
