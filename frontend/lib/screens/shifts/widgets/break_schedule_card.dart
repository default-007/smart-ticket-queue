import 'package:flutter/material.dart';
import '../../../models/shift.dart';
import 'package:intl/intl.dart';

class BreakScheduleCard extends StatelessWidget {
  final List<Break> breaks;
  final Function(String) onStartBreak;
  final Function(String) onEndBreak;

  const BreakScheduleCard({
    Key? key,
    required this.breaks,
    required this.onStartBreak,
    required this.onEndBreak,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeBreaks = breaks
        .where((b) =>
            b.status == BreakStatus.scheduled ||
            b.status == BreakStatus.inProgress)
        .toList();
    final pastBreaks = breaks
        .where((b) =>
            b.status == BreakStatus.completed ||
            b.status == BreakStatus.cancelled)
        .toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Breaks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${activeBreaks.length} active, ${pastBreaks.length} completed',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Active breaks
          if (activeBreaks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Active Breaks',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeBreaks.length,
              itemBuilder: (context, index) {
                return _buildBreakItem(context, activeBreaks[index]);
              },
            ),
          ],

          // Past breaks (if any)
          if (pastBreaks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Completed Breaks',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pastBreaks.length,
              itemBuilder: (context, index) {
                return _buildBreakItem(context, pastBreaks[index],
                    showActions: false);
              },
            ),
          ],

          // No breaks message
          if (breaks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No breaks scheduled')),
            ),
        ],
      ),
    );
  }

  Widget _buildBreakItem(BuildContext context, Break breakItem,
      {bool showActions = true}) {
    final timeFormatter = DateFormat('h:mm a');
    final isOngoing = breakItem.status == BreakStatus.inProgress;
    final isScheduled = breakItem.status == BreakStatus.scheduled;

    final now = DateTime.now();
    final bool isUpcoming = breakItem.start.isAfter(now);
    final bool isPast = breakItem.end.isBefore(now);

    Color statusColor;
    if (isOngoing) {
      statusColor = Colors.orange;
    } else if (isScheduled && isUpcoming) {
      statusColor = Colors.blue;
    } else if (breakItem.status == BreakStatus.completed) {
      statusColor = Colors.green;
    } else if (breakItem.status == BreakStatus.cancelled) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.grey;
    }

    return ListTile(
      leading: Icon(
        _getBreakIcon(breakItem.type),
        color: statusColor,
      ),
      title: Text(
        _formatBreakType(breakItem.type),
        style: TextStyle(
          fontWeight: isOngoing ? FontWeight.bold : FontWeight.normal,
          color: isOngoing ? statusColor : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${timeFormatter.format(breakItem.start)} - ${timeFormatter.format(breakItem.end)}',
          ),
          Text(
            '${breakItem.duration.inMinutes} minutes',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: showActions && (isScheduled || isOngoing)
          ? TextButton(
              onPressed: () {
                if (isScheduled) {
                  onStartBreak(breakItem.id);
                } else if (isOngoing) {
                  onEndBreak(breakItem.id);
                }
              },
              child: Text(
                isScheduled ? 'Start' : 'End',
                style: TextStyle(
                  color: isOngoing ? Colors.orange : Colors.blue,
                ),
              ),
            )
          : _getStatusChip(breakItem.status),
    );
  }

  Widget _getStatusChip(BreakStatus status) {
    Color color;
    String text;

    switch (status) {
      case BreakStatus.scheduled:
        color = Colors.blue;
        text = 'Scheduled';
        break;
      case BreakStatus.inProgress:
        color = Colors.orange;
        text = 'In Progress';
        break;
      case BreakStatus.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case BreakStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
}
