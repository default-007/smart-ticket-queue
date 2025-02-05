// lib/providers/shift_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/providers/providers.dart';
import '../models/shift.dart';
import '../services/api_service.dart';

final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ShiftNotifier(apiService);
});

class ShiftState {
  final bool isLoading;
  final List<Shift> shifts;
  final Shift? currentShift;
  final ShiftSchedule? schedule;
  final String? error;

  ShiftState({
    this.isLoading = false,
    this.shifts = const [],
    this.currentShift,
    this.schedule,
    this.error,
  });

  ShiftState copyWith({
    bool? isLoading,
    List<Shift>? shifts,
    Shift? currentShift,
    ShiftSchedule? schedule,
    String? error,
  }) {
    return ShiftState(
      isLoading: isLoading ?? this.isLoading,
      shifts: shifts ?? this.shifts,
      currentShift: currentShift ?? this.currentShift,
      schedule: schedule ?? this.schedule,
      error: error,
    );
  }
}

class ShiftNotifier extends StateNotifier<ShiftState> {
  final ApiService _apiService;
  Timer? _shiftTimer;

  ShiftNotifier(this._apiService) : super(ShiftState()) {
    _startShiftMonitoring();
  }

  void _startShiftMonitoring() {
    _shiftTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkShiftStatus();
    });
  }

  void _checkShiftStatus() {
    final currentShift = state.currentShift;
    if (currentShift != null) {
      if (currentShift.needsHandover) {
        _initiateHandover();
      }

      final currentBreak = currentShift.currentBreak;
      if (currentBreak != null) {
        _handleBreakStatus(currentBreak);
      }
    }
  }

  Future<void> loadAgentShifts(String agentId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.get('/shifts/agent/$agentId');
      final shifts = (response.data['data'] as List)
          .map((json) => Shift.fromJson(json))
          .toList();

      Shift? currentShift;
      try {
        currentShift = shifts.firstWhere((shift) => shift.isInProgress);
      } catch (_) {
        currentShift = null;
      }

      state = state.copyWith(
        isLoading: false,
        shifts: shifts,
        currentShift: currentShift,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> startShift(String agentId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.post(
        '/shifts/start',
        {'agentId': agentId},
      );

      final shift = Shift.fromJson(response.data['data']);

      final updatedShifts = [...state.shifts, shift];
      state = state.copyWith(
        isLoading: false,
        shifts: updatedShifts,
        currentShift: shift,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> endShift(String shiftId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _apiService.post('/shifts/$shiftId/end', {});

      final updatedShifts = state.shifts
          .map((s) => s.id == shiftId
              ? Shift.fromJson({...s.toJson(), 'isActive': false})
              : s)
          .toList();

      state = state.copyWith(
        isLoading: false,
        shifts: updatedShifts,
        currentShift: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> scheduleBreak(String shiftId, Break breakData) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.post(
        '/shifts/$shiftId/breaks',
        breakData.toJson(),
      );

      final updatedShift = Shift.fromJson(response.data['data']);
      _updateShift(updatedShift);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> startBreak(String shiftId, String breakId) async {
    try {
      final response = await _apiService.post(
        '/shifts/$shiftId/breaks/$breakId/start',
        {},
      );

      final updatedShift = Shift.fromJson(response.data['data']);
      _updateShift(updatedShift);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> endBreak(String shiftId, String breakId) async {
    try {
      final response = await _apiService.post(
        '/shifts/$shiftId/breaks/$breakId/end',
        {},
      );

      final updatedShift = Shift.fromJson(response.data['data']);
      _updateShift(updatedShift);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _updateShift(Shift updatedShift) {
    final updatedShifts = state.shifts
        .map((s) => s.id == updatedShift.id ? updatedShift : s)
        .toList();

    state = state.copyWith(
      shifts: updatedShifts,
      currentShift:
          updatedShift.isInProgress ? updatedShift : state.currentShift,
    );
  }

  void _initiateHandover() {
    // Implement handover logic
  }

  void _handleBreakStatus(Break currentBreak) {
    // Implement break status handling
  }

  @override
  void dispose() {
    _shiftTimer?.cancel();
    super.dispose();
  }
}
