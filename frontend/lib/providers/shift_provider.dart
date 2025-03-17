// lib/providers/shift_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shift.dart';
import '../services/shift_service.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

// Initialize the shift service provider
final shiftServiceProvider = Provider<ShiftService>((ref) {
  final apiService = ApiService();
  return ShiftService(apiService);
});

// State class for the shift provider
class ShiftState {
  final bool isLoading;
  final String? error;
  final List<Shift> shifts;
  final Shift? currentShift;

  ShiftState({
    this.isLoading = false,
    this.error,
    this.shifts = const [],
    this.currentShift,
  });

  ShiftState copyWith({
    bool? isLoading,
    String? error,
    List<Shift>? shifts,
    Shift? currentShift,
    bool clearError = false,
  }) {
    return ShiftState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      shifts: shifts ?? this.shifts,
      currentShift: currentShift ?? this.currentShift,
    );
  }
}

// Shift provider notifier
class ShiftNotifier extends StateNotifier<ShiftState> {
  final ShiftService _shiftService;
  final logger = Logger();

  ShiftNotifier(this._shiftService) : super(ShiftState());

  // Load shifts for an agent
  Future<void> loadAgentShifts(String agentId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final shifts = await _shiftService.getAgentShifts(agentId);

      // Also try to get current shift
      Shift? currentShift;
      try {
        currentShift = await _shiftService.getCurrentShift(agentId);
      } catch (e) {
        // It's okay if there's no current shift
        logger.info('No current shift found: ${e.toString()}');
        currentShift = null;
      }

      state = state.copyWith(
        isLoading: false,
        shifts: shifts,
        currentShift: currentShift,
      );
    } catch (e) {
      logger.error('Error loading agent shifts: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Start a new shift
  Future<void> startShift(String agentId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final shift = await _shiftService.startShift(agentId);

      // Update the current shift and the list of shifts
      final updatedShifts = [...state.shifts, shift];

      state = state.copyWith(
        isLoading: false,
        currentShift: shift,
        shifts: updatedShifts,
      );
    } catch (e) {
      logger.error('Error starting shift: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // End a shift
  Future<void> endShift(String shiftId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final endedShift = await _shiftService.endShift(shiftId);

      // Update shifts list
      final updatedShifts = state.shifts.map((shift) {
        if (shift.id == shiftId) {
          return endedShift;
        }
        return shift;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        shifts: updatedShifts,
        currentShift: null, // Clear current shift
      );
    } catch (e) {
      logger.error('Error ending shift: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Schedule a break
  Future<void> scheduleBreak(String shiftId, Break breakData) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updatedShift =
          await _shiftService.scheduleBreak(shiftId, breakData);

      // Update current shift if it matches
      Shift? newCurrentShift;
      if (state.currentShift?.id == shiftId) {
        newCurrentShift = updatedShift;
      }

      // Update shifts list
      final updatedShifts = state.shifts.map((shift) {
        if (shift.id == shiftId) {
          return updatedShift;
        }
        return shift;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        shifts: updatedShifts,
        currentShift: newCurrentShift ?? state.currentShift,
      );
    } catch (e) {
      logger.error('Error scheduling break: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Start a break
  Future<void> startBreak(String shiftId, String breakId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updatedShift = await _shiftService.startBreak(shiftId, breakId);

      // Update current shift if it matches
      Shift? newCurrentShift;
      if (state.currentShift?.id == shiftId) {
        newCurrentShift = updatedShift;
      }

      // Update shifts list
      final updatedShifts = state.shifts.map((shift) {
        if (shift.id == shiftId) {
          return updatedShift;
        }
        return shift;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        shifts: updatedShifts,
        currentShift: newCurrentShift ?? state.currentShift,
      );
    } catch (e) {
      logger.error('Error starting break: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // End a break
  Future<void> endBreak(String shiftId, String breakId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updatedShift = await _shiftService.endBreak(shiftId, breakId);

      // Update current shift if it matches
      Shift? newCurrentShift;
      if (state.currentShift?.id == shiftId) {
        newCurrentShift = updatedShift;
      }

      // Update shifts list
      final updatedShifts = state.shifts.map((shift) {
        if (shift.id == shiftId) {
          return updatedShift;
        }
        return shift;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        shifts: updatedShifts,
        currentShift: newCurrentShift ?? state.currentShift,
      );
    } catch (e) {
      logger.error('Error ending break: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Schedule a new shift
  Future<void> scheduleShift(
      String agentId, DateTime start, DateTime end, String timezone) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final shift =
          await _shiftService.scheduleShift(agentId, start, end, timezone);

      // Add to list of shifts
      final updatedShifts = [...state.shifts, shift];

      state = state.copyWith(
        isLoading: false,
        shifts: updatedShifts,
      );
    } catch (e) {
      logger.error('Error scheduling shift: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Get shift by id
  Shift? getShiftById(String shiftId) {
    try {
      return state.shifts.firstWhere((shift) => shift.id == shiftId);
    } catch (_) {
      return null;
    }
  }
}

// Provider for the shift state
final shiftProvider = StateNotifierProvider<ShiftNotifier, ShiftState>((ref) {
  final shiftService = ref.watch(shiftServiceProvider);
  return ShiftNotifier(shiftService);
});
