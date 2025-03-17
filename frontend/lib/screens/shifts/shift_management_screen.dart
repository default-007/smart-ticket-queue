// lib/screens/shifts/shift_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_ticketing/screens/shifts/widgets/shift_details_sheet.dart';
import 'package:smart_ticketing/widgets/common/custom_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shift_provider.dart';
import '../../models/shift.dart';
import 'widgets/current_shift_card.dart';
import 'widgets/break_schedule_card.dart';
import 'widgets/shift_schedule_calendar.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_display.dart';

class ShiftManagementScreen extends ConsumerStatefulWidget {
  const ShiftManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ShiftManagementScreen> createState() =>
      _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends ConsumerState<ShiftManagementScreen> {
  String? _agentId;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // We'll use Future.microtask to load the agent ID and shifts after build
    Future.microtask(() {
      _initializeAgentId();
    });
  }

  // Initialize agent ID separately from loading shifts
  Future<void> _initializeAgentId() async {
    if (_isInitialized) return;

    final authState = ref.read(authProvider);
    if (authState.user != null) {
      setState(() {
        _agentId = authState.user!.id;
        _isInitialized = true;
      });

      // Now that we have the agent ID, load the shifts
      _loadShifts();
    }
  }

  Future<void> _loadShifts() async {
    if (_agentId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use Future.microtask to avoid state updates during build
      await Future.microtask(() async {
        await ref.read(shiftProvider.notifier).loadAgentShifts(_agentId!);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading shifts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftState = ref.watch(shiftProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Shift Management',
      ),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : shiftState.error != null
              ? ErrorDisplay(
                  message: shiftState.error!,
                  onRetry: _loadShifts,
                )
              : RefreshIndicator(
                  onRefresh: _loadShifts,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (shiftState.currentShift != null)
                          CurrentShiftCard(
                            shift: shiftState.currentShift!,
                            onEndShift: () => _handleEndShift(context),
                            onScheduleBreak: () => _showScheduleBreakDialog(
                              context,
                              shiftState.currentShift!,
                            ),
                          )
                        else
                          _buildStartShiftButton(context),
                        const SizedBox(height: 24),
                        if (shiftState.currentShift?.breaks.isNotEmpty ?? false)
                          BreakScheduleCard(
                            breaks: shiftState.currentShift!.breaks,
                            onStartBreak: (breakId) => _handleStartBreak(
                              shiftState.currentShift!.id,
                              breakId,
                            ),
                            onEndBreak: (breakId) => _handleEndBreak(
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
        onPressed: () => _showScheduleShiftDialog(context),
        tooltip: 'Schedule Shift',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStartShiftButton(BuildContext context) {
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
              onPressed: _handleStartShift,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Shift'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStartShift() async {
    if (_agentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent ID not available')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use a separate function to avoid state modification during build
      await Future.microtask(() async {
        await ref.read(shiftProvider.notifier).startShift(_agentId!);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift started successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting shift: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEndShift(BuildContext context) async {
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
        setState(() {
          _isLoading = true;
        });

        try {
          // Use Future.microtask to avoid state updates during build
          await Future.microtask(() async {
            await ref.read(shiftProvider.notifier).endShift(currentShift.id);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shift ended successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error ending shift: ${e.toString()}')),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  Future<void> _showScheduleBreakDialog(
    BuildContext context,
    Shift shift,
  ) async {
    final now = DateTime.now();

    // Initialize to 15 minutes from now
    TimeOfDay startTime = TimeOfDay.fromDateTime(now);
    TimeOfDay endTime =
        TimeOfDay.fromDateTime(now.add(const Duration(minutes: 15)));
    BreakType breakType = BreakType.shortBreak;

    // First, select the start time
    final selectedStartTime = await showTimePicker(
      context: context,
      initialTime: startTime,
      helpText: 'Select break start time',
    );

    if (selectedStartTime == null) return;
    startTime = selectedStartTime;

    // Then select the end time
    if (!mounted) return;
    final selectedEndTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime(
              now.year, now.month, now.day, startTime.hour, startTime.minute)
          .add(const Duration(minutes: 15))),
      helpText: 'Select break end time',
    );

    if (selectedEndTime == null) return;
    endTime = selectedEndTime;

    // Convert to DateTime objects
    final startDateTime = DateTime(
        now.year, now.month, now.day, startTime.hour, startTime.minute);

    final endDateTime =
        DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);

    // Validate times
    if (startDateTime.isAfter(endDateTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
      }
      return;
    }

    // Select break type
    if (!mounted) return;
    final selectedBreakType = await showDialog<BreakType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Break Type'),
        children: BreakType.values.map((type) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, type),
            child: Text(_formatBreakType(type)),
          );
        }).toList(),
      ),
    );

    if (selectedBreakType == null) return;
    breakType = selectedBreakType;

    // Create the break object
    final breakData = Break(
      id: '', // Server will assign
      start: startDateTime,
      end: endDateTime,
      type: breakType,
    );

    // Schedule the break
    setState(() {
      _isLoading = true;
    });

    try {
      // Use Future.microtask to avoid state updates during build
      await Future.microtask(() async {
        await ref
            .read(shiftProvider.notifier)
            .scheduleBreak(shift.id, breakData);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Break scheduled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling break: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleStartBreak(String shiftId, String breakId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use Future.microtask to avoid state updates during build
      await Future.microtask(() async {
        await ref.read(shiftProvider.notifier).startBreak(shiftId, breakId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Break started successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting break: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEndBreak(String shiftId, String breakId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use Future.microtask to avoid state updates during build
      await Future.microtask(() async {
        await ref.read(shiftProvider.notifier).endBreak(shiftId, breakId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Break ended successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ending break: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showShiftDetails(BuildContext context, Shift shift) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ShiftDetailsSheet(shift: shift),
    );
  }

  String _formatBreakType(BreakType type) {
    final typeString = type.toString().split('.').last;
    // Convert camelCase to Title Case with spaces
    return typeString
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .replaceFirst(typeString[0], typeString[0].toUpperCase());
  }

  Future<void> _showScheduleShiftDialog(BuildContext context) async {
    if (_agentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent ID not available')),
      );
      return;
    }

    final now = DateTime.now();

    // Initial values
    DateTime startDate = now.add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);

    DateTime endDate = startDate;
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    String timezone = 'UTC';

    // Select start date
    final selectedStartDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedStartDate == null) return;
    startDate = selectedStartDate;
    endDate = selectedStartDate; // Default end date to same as start date

    // Select start time
    if (!mounted) return;
    final selectedStartTime = await showTimePicker(
      context: context,
      initialTime: startTime,
    );

    if (selectedStartTime == null) return;
    startTime = selectedStartTime;

    // Select end date (in case of multi-day shifts)
    if (!mounted) return;
    final selectedEndDate = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (selectedEndDate == null) return;
    endDate = selectedEndDate;

    // Select end time
    if (!mounted) return;
    final selectedEndTime = await showTimePicker(
      context: context,
      initialTime: endTime,
    );

    if (selectedEndTime == null) return;
    endTime = selectedEndTime;

    // Convert to DateTime objects
    final startDateTime = DateTime(startDate.year, startDate.month,
        startDate.day, startTime.hour, startTime.minute);

    final endDateTime = DateTime(
        endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute);

    // Validate times
    if (startDateTime.isAfter(endDateTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
      }
      return;
    }

    // Let user confirm the shift details
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Shift Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Start: ${DateFormat('MMM dd, yyyy hh:mm a').format(startDateTime)}'),
            const SizedBox(height: 8),
            Text(
                'End: ${DateFormat('MMM dd, yyyy hh:mm a').format(endDateTime)}'),
            const SizedBox(height: 8),
            Text(
                'Duration: ${endDateTime.difference(startDateTime).inHours} hours'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Schedule the shift
    setState(() {
      _isLoading = true;
    });

    try {
      // Use Future.microtask to avoid state updates during build
      await Future.microtask(() async {
        await ref.read(shiftProvider.notifier).scheduleShift(
              _agentId!,
              startDateTime,
              endDateTime,
              timezone,
            );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift scheduled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling shift: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
