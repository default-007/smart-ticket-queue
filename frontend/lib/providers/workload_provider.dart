import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/providers/ticket_provider.dart';
import '../models/workload.dart';
import '../services/workload_service.dart';

final workloadServiceProvider = Provider<WorkloadService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return WorkloadService(apiService);
});

final workloadProvider =
    StateNotifierProvider<WorkloadNotifier, WorkloadState>((ref) {
  final workloadService = ref.watch(workloadServiceProvider);
  return WorkloadNotifier(workloadService);
});

class WorkloadState {
  final bool isLoading;
  final WorkloadMetrics? metrics;
  final List<AgentWorkload> agentWorkloads;
  final List<TeamCapacity> teamCapacities;
  final Map<String, dynamic>? predictions;
  final String? error;

  WorkloadState({
    this.isLoading = false,
    this.metrics,
    this.agentWorkloads = const [],
    this.teamCapacities = const [],
    this.predictions,
    this.error,
  });

  WorkloadState copyWith({
    bool? isLoading,
    WorkloadMetrics? metrics,
    List<AgentWorkload>? agentWorkloads,
    List<TeamCapacity>? teamCapacities,
    Map<String, dynamic>? predictions,
    String? error,
    bool clearError = false,
  }) {
    return WorkloadState(
      isLoading: isLoading ?? this.isLoading,
      metrics: metrics ?? this.metrics,
      agentWorkloads: agentWorkloads ?? this.agentWorkloads,
      teamCapacities: teamCapacities ?? this.teamCapacities,
      predictions: predictions ?? this.predictions,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class WorkloadNotifier extends StateNotifier<WorkloadState> {
  final WorkloadService _workloadService;
  Timer? _refreshTimer;

  WorkloadNotifier(this._workloadService) : super(WorkloadState()) {
    // Initialize real-time updates
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => refreshWorkloadData(),
    );
  }

  Future<void> refreshWorkloadData() async {
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
      );

      // Fetch metrics, agent workloads, and predictions independently
      // If any of these requests fail, we'll still have data from the others
      WorkloadMetrics? newMetrics;
      List<AgentWorkload> newAgentWorkloads = [];
      List<TeamCapacity> newTeamCapacities = [];
      Map<String, dynamic>? newPredictions;

      try {
        newMetrics = await _workloadService.getWorkloadMetrics();
      } catch (e) {
        print('Error fetching workload metrics: $e');
      }

      try {
        newAgentWorkloads = await _workloadService.getAgentWorkloads();
      } catch (e) {
        print('Error fetching agent workloads: $e');
      }

      try {
        newTeamCapacities = await _workloadService.getTeamCapacities();
      } catch (e) {
        print('Error fetching team capacities: $e');
      }

      try {
        newPredictions = await _workloadService.getWorkloadPredictions();
      } catch (e) {
        print('Error fetching workload predictions: $e');
      }

      state = state.copyWith(
        isLoading: false,
        metrics: newMetrics,
        agentWorkloads: newAgentWorkloads,
        teamCapacities: newTeamCapacities,
        predictions: newPredictions,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> rebalanceWorkload() async {
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
      );

      await _workloadService.rebalanceWorkload();
      await refreshWorkloadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> optimizeAssignments() async {
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
      );

      await _workloadService.optimizeAssignments();
      await refreshWorkloadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
