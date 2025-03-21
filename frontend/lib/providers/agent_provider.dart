import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/providers/providers.dart';
import '../models/agent.dart';
import '../services/agent_service.dart';

final agentProvider = StateNotifierProvider<AgentNotifier, AgentState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final agentService = AgentService(apiService);
  return AgentNotifier(agentService);
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

  Future<void> loadAgents() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final agents = await _agentService.getAgents();
      state = state.copyWith(isLoading: false, agents: agents);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createAgent(Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final agent = await _agentService.createAgent(data);
      final updatedAgents = [...state.agents, agent];
      state = state.copyWith(isLoading: false, agents: updatedAgents);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw e;
    }
  }

  Future<void> updateAgent(String agentId, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final updatedAgent = await _agentService.updateAgent(agentId, data);
      final updatedAgents = state.agents
          .map((agent) => agent.id == agentId ? updatedAgent : agent)
          .toList();
      state = state.copyWith(isLoading: false, agents: updatedAgents);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      throw e;
    }
  }

  Future<void> loadAgentByUserId(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final agent = await _agentService.getAgentByUserId(userId);
      state = state.copyWith(
        isLoading: false,
        agents: [agent], // Store the current agent in the agents list
      );
    } catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains("duplicate key error") ||
          errorMessage.contains("Agent not found")) {
        // Show a more friendly error message
        state = state.copyWith(
          isLoading: false,
          agents: [],
          error:
              "Your agent profile needs configuration. Please contact an administrator.",
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }
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
      final updatedAgent = await _agentService.updateStatus(agentId, status);
      final updatedAgents = state.agents.map((agent) {
        return agent.id == agentId ? updatedAgent : agent;
      }).toList();
      state = state.copyWith(agents: updatedAgents);
    } catch (e) {
      state = state.copyWith(error: e.toString());
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
