import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/shift.dart';

class ShiftScheduleCalendar extends StatefulWidget {
  final List<Shift> shifts;
  final Function(Shift) onShiftTap;

  const ShiftScheduleCalendar({
    Key? key,
    required this.shifts,
    required this.onShiftTap,
  }) : super(key: key);

  @override
  State<ShiftScheduleCalendar> createState() => _ShiftScheduleCalendarState();
}

class _ShiftScheduleCalendarState extends State<ShiftScheduleCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showShiftsForDay(selectedDay);
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: (day) {
              return widget.shifts
                  .where((shift) => isSameDay(shift.start, day))
                  .toList();
            },
          ),
          if (_selectedDay != null)
            _buildShiftList(_getShiftsForDay(_selectedDay!)),
        ],
      ),
    );
  }

  List<Shift> _getShiftsForDay(DateTime day) {
    return widget.shifts.where((shift) => isSameDay(shift.start, day)).toList();
  }

  void _showShiftsForDay(DateTime day) {
    final shifts = _getShiftsForDay(day);
    if (shifts.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: shifts.length,
        itemBuilder: (context, index) {
          final shift = shifts[index];
          return ListTile(
            title: Text(
              '${DateFormat('HH:mm').format(shift.start)} - ${DateFormat('HH:mm').format(shift.end)}',
            ),
            subtitle: Text('${shift.breaks.length} breaks scheduled'),
            onTap: () {
              Navigator.pop(context);
              widget.onShiftTap(shift);
            },
          );
        },
      ),
    );
  }

  Widget _buildShiftList(List<Shift> shifts) {
    if (shifts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No shifts scheduled for this day'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shifts.length,
      itemBuilder: (context, index) {
        final shift = shifts[index];
        return ListTile(
          title: Text(
            '${DateFormat('HH:mm').format(shift.start)} - ${DateFormat('HH:mm').format(shift.end)}',
          ),
          subtitle: Text('${shift.breaks.length} breaks scheduled'),
          onTap: () => widget.onShiftTap(shift),
        );
      },
    );
  }
}
