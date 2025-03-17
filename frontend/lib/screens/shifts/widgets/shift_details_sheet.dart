import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/shift.dart';

class ShiftDetailsSheet extends StatelessWidget {
  final Shift shift;

  const ShiftDetailsSheet({
    Key? key,
    required this.shift,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('h:mm a');
    final dateFormatter = DateFormat('MMM dd, yyyy');

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
            'Date',
            dateFormatter.format(shift.start),
            Icons.calendar_today,
          ),
          _buildDetailRow(
            context,
            'Time',
            '${timeFormatter.format(shift.start)} - ${timeFormatter.format(shift.end)}',
            Icons.access_time,
          ),
          _buildDetailRow(
            context,
            'Duration',
            _formatDuration(shift.duration),
            Icons.timelapse,
          ),
          _buildDetailRow(
            context,
            'Status',
            _formatStatus(shift.status),
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
                    color: _getBreakColor(breakItem.status),
                  ),
                  title: Text(_formatBreakType(breakItem.type)),
                  subtitle: Text(
                    '${timeFormatter.format(breakItem.start)} - ${timeFormatter.format(breakItem.end)} (${breakItem.duration.inMinutes} min)',
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
          Icon(icon, size: 20, color: Colors.grey[700]),
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

  String _formatStatus(String status) {
    return status
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
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

  Color _getBreakColor(BreakStatus status) {
    switch (status) {
      case BreakStatus.scheduled:
        return Colors.blue;
      case BreakStatus.inProgress:
        return Colors.orange;
      case BreakStatus.completed:
        return Colors.green;
      case BreakStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _getBreakStatusChip(BreakStatus status) {
    final color = _getBreakColor(status);
    final statusText = status.toString().split('.').last;

    // Convert camelCase to Title Case with spaces
    final displayText = statusText
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .trim()
        .replaceFirst(statusText[0], statusText[0].toUpperCase());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
