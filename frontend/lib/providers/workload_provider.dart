import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/providers/providers.dart';

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
  }) {
    return WorkloadState(
      isLoading: isLoading ?? this.isLoading,
      metrics: metrics ?? this.metrics,
      agentWorkloads: agentWorkloads ?? this.agentWorkloads,
      teamCapacities: teamCapacities ?? this.teamCapacities,
      predictions: predictions ?? this.predictions,
      error: error,
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
      state = state.copyWith(isLoading: true, error: null);

      // Fetch all workload data in parallel
      final results = await Future.wait([
        _workloadService.getWorkloadMetrics(),
        _workloadService.getAgentWorkloads(),
        _workloadService.getTeamCapacities(),
        _workloadService.getWorkloadPredictions(),
      ]);

      state = state.copyWith(
        isLoading: false,
        metrics: results[0] as WorkloadMetrics,
        agentWorkloads: results[1] as List<AgentWorkload>,
        teamCapacities: results[2] as List<TeamCapacity>,
        predictions: results[3] as Map<String, dynamic>,
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
      state = state.copyWith(isLoading: true, error: null);
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
      state = state.copyWith(isLoading: true, error: null);
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
