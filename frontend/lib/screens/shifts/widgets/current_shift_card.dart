import 'package:flutter/material.dart';
import '../../../models/shift.dart';
import 'package:intl/intl.dart';

class CurrentShiftCard extends StatelessWidget {
  final Shift shift;
  final VoidCallback onEndShift;
  final VoidCallback onScheduleBreak;

  const CurrentShiftCard({
    Key? key,
    required this.shift,
    required this.onEndShift,
    required this.onScheduleBreak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentBreak = shift.currentBreak;
    final timeFormatter = DateFormat('HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Shift',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeFormatter.format(shift.start)} - ${timeFormatter.format(shift.end)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                if (currentBreak != null)
                  _buildBreakStatus(currentBreak)
                else
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'break',
                        child: Text('Schedule Break'),
                      ),
                      const PopupMenuItem(
                        value: 'end',
                        child: Text('End Shift'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'break') {
                        onScheduleBreak();
                      } else if (value == 'end') {
                        onEndShift();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimeProgressBar(),
            const SizedBox(height: 8),
            Text(
              '${shift.remainingTime.inHours}h ${shift.remainingTime.inMinutes.remainder(60)}m remaining',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakStatus(Break currentBreak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.coffee,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            'On ${currentBreak.type.toString().split('.').last}',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeProgressBar() {
    final totalDuration = shift.end.difference(shift.start);
    final elapsed = DateTime.now().difference(shift.start);
    final progress = elapsed.inMinutes / totalDuration.inMinutes;

    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      backgroundColor: Colors.grey[200],
      valueColor: AlwaysStoppedAnimation<Color>(
        progress > 0.9 ? Colors.orange : Colors.blue,
      ),
    );
  }
}
