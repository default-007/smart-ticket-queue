import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ticketing/models/shift.dart';

class ShiftDetailsSheet extends StatelessWidget {
  final Shift shift;

  const ShiftDetailsSheet({
    Key? key,
    required this.shift,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            'Time',
            '${timeFormatter.format(shift.start)} - ${timeFormatter.format(shift.end)}',
            Icons.access_time,
          ),
          _buildDetailRow(
            context,
            'Duration',
            '${shift.end.difference(shift.start).inHours}h',
            Icons.timer,
          ),
          _buildDetailRow(
            context,
            'Status',
            _getShiftStatus(),
            Icons.info_outline,
          ),
          if (shift.breaks.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Breaks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shift.breaks.length,
              itemBuilder: (context, index) {
                final breakItem = shift.breaks[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getBreakIcon(breakItem.type),
                    size: 20,
                  ),
                  title: Text(breakItem.type.toString().split('.').last),
                  subtitle: Text(
                    '${timeFormatter.format(breakItem.start)} - ${timeFormatter.format(breakItem.end)}',
                  ),
                  trailing: _getBreakStatusChip(breakItem.status),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  String _getShiftStatus() {
    if (shift.isInProgress) return 'In Progress';
    if (shift.start.isAfter(DateTime.now())) return 'Upcoming';
    return 'Completed';
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

  Widget _getBreakStatusChip(BreakStatus status) {
    Color color;
    switch (status) {
      case BreakStatus.scheduled:
        color = Colors.blue;
        break;
      case BreakStatus.inProgress:
        color = Colors.orange;
        break;
      case BreakStatus.completed:
        color = Colors.green;
        break;
      case BreakStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toString().split('.').last,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
