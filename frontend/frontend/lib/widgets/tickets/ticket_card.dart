import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ticket.dart';
import 'package:timeago/timeago.dart' as timeago;

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final Function(String)? onStatusUpdate;

  const TicketCard({
    Key? key,
    required this.ticket,
    this.onTap,
    this.onStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildPriorityIndicator(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due: ${_formatDueDate()}',
                    style: TextStyle(
                      color: ticket.isOverdue ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${ticket.estimatedHours}h',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (ticket.assignedTo != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 4),
                    Text(ticket.assignedTo!.name),
                  ],
                ),
              ],
              if (onStatusUpdate != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => onStatusUpdate!('in-progress'),
                      child: const Text('Start'),
                    ),
                    TextButton(
                      onPressed: () => onStatusUpdate!('resolved'),
                      child: const Text('Resolve'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    Color color;
    switch (ticket.priority) {
      case 1:
        color = Colors.red;
        break;
      case 2:
        color = Colors.orange;
        break;
      case 3:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ticket.statusDisplay,
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (ticket.status) {
      case 'queued':
        return Colors.grey;
      case 'assigned':
        return Colors.blue;
      case 'in-progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDueDate() {
    final now = DateTime.now();
    final difference = ticket.dueDate.difference(now);

    if (difference.inDays.abs() <= 7) {
      return timeago.format(ticket.dueDate);
    } else {
      return DateFormat('MMM dd').format(ticket.dueDate);
    }
  }
}
