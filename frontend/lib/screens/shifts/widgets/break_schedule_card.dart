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
                  'Break Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${breaks.length} breaks',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: breaks.length,
            itemBuilder: (context, index) {
              return _buildBreakItem(context, breaks[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreakItem(BuildContext context, Break breakItem) {
    final timeFormatter = DateFormat('HH:mm');
    final isOngoing = breakItem.status == BreakStatus.inProgress;
    final isScheduled = breakItem.status == BreakStatus.scheduled;

    return ListTile(
      leading: Icon(
        _getBreakIcon(breakItem.type),
        color: isOngoing ? Colors.orange : Colors.grey,
      ),
      title: Text(
        breakItem.type.toString().split('.').last,
        style: TextStyle(
          fontWeight: isOngoing ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${timeFormatter.format(breakItem.start)} - ${timeFormatter.format(breakItem.end)} (${breakItem.duration.inMinutes}min)',
      ),
      trailing: isScheduled || isOngoing
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
          : null,
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
}
