import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_ticketing/providers/auth_provider.dart';
import '../../models/ticket.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/agents/agent_selector.dart';

class TicketDetailScreen extends ConsumerWidget {
  final Ticket ticket;

  const TicketDetailScreen({
    Key? key,
    required this.ticket,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket #${ticket.id}'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit screen
                Navigator.pushNamed(
                  context,
                  '/tickets/edit',
                  arguments: ticket,
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBar(context, ref),
            const SizedBox(height: 24),
            _buildTicketInfo(),
            const SizedBox(height: 24),
            _buildAssignmentSection(context, ref, isAdmin),
            const SizedBox(height: 24),
            _buildDescription(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.statusDisplay,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            _buildStatusDropdown(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context, WidgetRef ref) {
    final availableStatuses = [
      'queued',
      'assigned',
      'in-progress',
      'resolved',
      'closed'
    ];

    return DropdownButton<String>(
      value: ticket.status,
      items: availableStatuses.map((status) {
        return DropdownMenuItem(
          value: status,
          child: Text(status
              .split('-')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ')),
        );
      }).toList(),
      onChanged: (String? newStatus) {
        if (newStatus != null) {
          ref.read(ticketProvider.notifier).updateTicketStatus(
                ticket.id,
                newStatus,
              );
        }
      },
    );
  }

  Widget _buildTicketInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Priority',
              ticket.priorityText,
              Icons.flag,
              _getPriorityColor(ticket.priority),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Due Date',
              DateFormat('MMM dd, yyyy').format(ticket.dueDate),
              Icons.calendar_today,
              ticket.isOverdue ? Colors.red : Colors.black,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Estimated Hours',
              '${ticket.estimatedHours} hours',
              Icons.timer,
              Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color),
        ),
      ],
    );
  }

  Widget _buildAssignmentSection(
    BuildContext context,
    WidgetRef ref,
    bool isAdmin,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assignment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (ticket.assignedTo != null)
              _buildAssignedAgent()
            else if (isAdmin)
              AgentSelector(
                onAgentSelected: (String agentId) {
                  ref.read(ticketProvider.notifier).updateTicketStatus(
                        ticket.id,
                        'assigned',
                      );
                },
              )
            else
              const Text('Not assigned'),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedAgent() {
    return Row(
      children: [
        CircleAvatar(
          child: Text(ticket.assignedTo!.name[0]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.assignedTo!.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(ticket.assignedTo!.email),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(ticket.description),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}
