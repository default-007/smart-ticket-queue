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
    final timeFormatter = DateFormat('h:mm a');

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
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                if (currentBreak != null)
                  _buildBreakStatus(currentBreak)
                else
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.coffee),
                        tooltip: 'Schedule Break',
                        onPressed: onScheduleBreak,
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        tooltip: 'End Shift',
                        onPressed: onEndShift,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimeProgressBar(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatDuration(shift.remainingTime)} remaining',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Shift duration: ${_formatDuration(shift.duration)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakStatus(Break currentBreak) {
    final timeFormatter = DateFormat('h:mm a');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getBreakIcon(currentBreak.type),
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                'On Break',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            'Until ${timeFormatter.format(currentBreak.end)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.orange,
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
    final clampedProgress = progress.clamp(0.0, 1.0);

    return LinearProgressIndicator(
      value: clampedProgress,
      backgroundColor: Colors.grey[200],
      valueColor: AlwaysStoppedAnimation<Color>(
        _getProgressColor(clampedProgress),
      ),
      minHeight: 8,
      borderRadius: BorderRadius.circular(4),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress > 0.9) return Colors.orange;
    if (progress > 0.75) return Colors.amber;
    return Colors.blue;
  }

  IconData _getBreakIcon(BreakType type) {
    switch (type) {
      case BreakType.lunch:
        return Icons.restaurant;
      case BreakType.shortBreak:
        return Icons.coffee;
      case BreakType.training:
        return Icons.school;
      case BreakType.meeting:
        return Icons.groups;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}
