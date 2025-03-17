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
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
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
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getShiftsForDay,
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Shifts on ${DateFormat.yMMMd().format(_selectedDay!)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildShiftList(_getShiftsForDay(_selectedDay!)),
          ],
        ],
      ),
    );
  }

  List<Shift> _getShiftsForDay(DateTime day) {
    return widget.shifts
        .where((shift) =>
            isSameDay(shift.start, day) ||
            isSameDay(shift.end, day) ||
            (shift.start.isBefore(day) && shift.end.isAfter(day)))
        .toList();
  }

  Widget _buildShiftList(List<Shift> shifts) {
    if (shifts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('No shifts scheduled for this day')),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shifts.length,
      itemBuilder: (context, index) => _buildShiftListItem(shifts[index]),
    );
  }

  Widget _buildShiftListItem(Shift shift) {
    final bool isActive = shift.isInProgress;
    final startTime = DateFormat('h:mm a').format(shift.start);
    final endTime = DateFormat('h:mm a').format(shift.end);
    final duration =
        '${shift.duration.inHours}h ${shift.duration.inMinutes % 60}m';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive ? Colors.green : Colors.blue,
        child: Icon(
          isActive ? Icons.play_arrow : Icons.event,
          color: Colors.white,
        ),
      ),
      title: Text(
        '${startTime} - ${endTime}',
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Duration: $duration'),
          Text('Status: ${shift.status.toUpperCase()}'),
        ],
      ),
      trailing: Text('${shift.breaks.length} breaks'),
      onTap: () => widget.onShiftTap(shift),
    );
  }
}
