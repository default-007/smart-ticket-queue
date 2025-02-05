import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/providers/providers.dart';
import '../models/sla.dart';
import '../services/api_service.dart';

final slaProvider = StateNotifierProvider<SLANotifier, SLAState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return SLANotifier(apiService);
});

class SLAState {
  final bool isLoading;
  final SLAMetrics? metrics;
  final List<SLAConfig> configs;
  final String? error;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedDepartment;

  SLAState({
    this.isLoading = false,
    this.metrics,
    this.configs = const [],
    this.error,
    this.startDate,
    this.endDate,
    this.selectedDepartment,
  });

  SLAState copyWith({
    bool? isLoading,
    SLAMetrics? metrics,
    List<SLAConfig>? configs,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedDepartment,
  }) {
    return SLAState(
      isLoading: isLoading ?? this.isLoading,
      metrics: metrics ?? this.metrics,
      configs: configs ?? this.configs,
      error: error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
    );
  }
}

class SLANotifier extends StateNotifier<SLAState> {
  final ApiService _apiService;

  SLANotifier(this._apiService) : super(SLAState()) {
    // Initialize with last 30 days by default
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    updateDateRange(thirtyDaysAgo, now);
  }

  Future<void> updateDateRange(DateTime startDate, DateTime endDate) async {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
    );
    await loadSLAMetrics();
  }

  Future<void> updateDepartment(String? department) async {
    state = state.copyWith(selectedDepartment: department);
    await loadSLAMetrics();
  }

  Future<void> loadSLAMetrics() async {
    if (state.startDate == null || state.endDate == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.get(
        '/sla/metrics',
        params: {
          'startDate': state.startDate!.toIso8601String(),
          'endDate': state.endDate!.toIso8601String(),
          if (state.selectedDepartment != null)
            'department': state.selectedDepartment,
        },
      );

      final metrics = SLAMetrics.fromJson(response.data['data']);
      state = state.copyWith(
        isLoading: false,
        metrics: metrics,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadSLAConfigs() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _apiService.get('/sla/config');
      final configs = (response.data['data'] as List)
          .map((json) => SLAConfig.fromJson(json))
          .toList();
      state = state.copyWith(
        isLoading: false,
        configs: configs,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateSLAConfig(
    int priority,
    String category,
    Map<String, dynamic> configData,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _apiService.put(
        '/sla/config/$priority/$category',
        configData,
      );
      await loadSLAConfigs();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
