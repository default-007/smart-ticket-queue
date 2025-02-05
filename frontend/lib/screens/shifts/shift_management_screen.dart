// lib/screens/shifts/shift_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/screens/shifts/widgets/shift_details_sheet.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift.dart';
import 'widgets/current_shift_card.dart';
import 'widgets/break_schedule_card.dart';
import 'widgets/shift_schedule_calendar.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';

class ShiftManagementScreen extends ConsumerWidget {
  final String agentId;

  const ShiftManagementScreen({
    Key? key,
    required this.agentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Shift Management',
      ),
      body: shiftState.isLoading
          ? const Center(child: LoadingIndicator())
          : shiftState.error != null
              ? ErrorDisplay(
                  message: shiftState.error!,
                  onRetry: () {
                    ref.read(shiftProvider.notifier).loadAgentShifts(agentId);
                  },
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(shiftProvider.notifier)
                        .loadAgentShifts(agentId);
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (shiftState.currentShift != null)
                          CurrentShiftCard(
                            shift: shiftState.currentShift!,
                            onEndShift: () => _handleEndShift(context, ref),
                            onScheduleBreak: () => _showScheduleBreakDialog(
                              context,
                              ref,
                              shiftState.currentShift!,
                            ),
                          )
                        else
                          _buildStartShiftButton(context, ref),
                        const SizedBox(height: 24),
                        if (shiftState.currentShift?.breaks.isNotEmpty ?? false)
                          BreakScheduleCard(
                            breaks: shiftState.currentShift!.breaks,
                            onStartBreak: (breakId) => _handleStartBreak(
                              ref,
                              shiftState.currentShift!.id,
                              breakId,
                            ),
                            onEndBreak: (breakId) => _handleEndBreak(
                              ref,
                              shiftState.currentShift!.id,
                              breakId,
                            ),
                          ),
                        const SizedBox(height: 24),
                        const Text(
                          'Shift Schedule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ShiftScheduleCalendar(
                          shifts: shiftState.shifts,
                          onShiftTap: (shift) =>
                              _showShiftDetails(context, shift),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleShiftDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStartShiftButton(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'No Active Shift',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(shiftProvider.notifier).startShift(agentId);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Shift'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEndShift(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Shift'),
        content: const Text('Are you sure you want to end your current shift?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Shift'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final currentShift = ref.read(shiftProvider).currentShift;
      if (currentShift != null) {
        await ref.read(shiftProvider.notifier).endShift(currentShift.id);
      }
    }
  }

  Future<void> _showScheduleBreakDialog(
    BuildContext context,
    WidgetRef ref,
    Shift shift,
  ) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(minutes: 30)),
      ),
    );
    if (endTime == null) return;

    final now = DateTime.now();
    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    );
    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      endTime.hour,
      endTime.minute,
    );

    // Check if the BuildContext is still valid before showing the dialog
    if (!context.mounted) return;

    final breakType = await showDialog<BreakType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Break Type'),
        children: BreakType.values.map((type) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, type),
            child: Text(type.toString().split('.').last),
          );
        }).toList(),
      ),
    );
    if (breakType == null) return;

    final breakData = Break(
      id: '', // Will be assigned by backend
      start: startDateTime,
      end: endDateTime,
      type: breakType,
    );

    await ref.read(shiftProvider.notifier).scheduleBreak(shift.id, breakData);
  }

  Future<void> _handleStartBreak(
    WidgetRef ref,
    String shiftId,
    String breakId,
  ) async {
    await ref.read(shiftProvider.notifier).startBreak(shiftId, breakId);
  }

  Future<void> _handleEndBreak(
    WidgetRef ref,
    String shiftId,
    String breakId,
  ) async {
    await ref.read(shiftProvider.notifier).endBreak(shiftId, breakId);
  }

  void _showShiftDetails(BuildContext context, Shift shift) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ShiftDetailsSheet(shift: shift),
    );
  }

  Future<void> _showScheduleShiftDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Implement shift scheduling dialog
  }
}
