// lib/widgets/tickets/ticket_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/ticket.dart';
import '../../models/agent.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/agent_provider.dart';
import 'sla_status_indicator.dart';

class TicketCard extends ConsumerStatefulWidget {
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
  ConsumerState<TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends ConsumerState<TicketCard> {
  bool _expanded = false;

  Future<void> assignTicket(String ticketId) async {
    // First, show agent selection dialog
    final selectedAgent = await showAgentSelectionDialog(context);

    if (selectedAgent != null) {
      try {
        // Then update the ticket with both status and agentId
        await ref
            .read(ticketProvider.notifier)
            .updateTicketWithAgent(ticketId, 'assigned', selectedAgent.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ticket assigned to ${selectedAgent.name}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error assigning ticket: $e')),
          );
        }
      }
    }
  }

  Future<Agent?> showAgentSelectionDialog(BuildContext context) async {
    // Load available agents
    await ref.read(agentProvider.notifier).loadAvailableAgents();
    final agents = ref.read(agentProvider).agents;

    if (!mounted) return null;

    return await showDialog<Agent?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Agent'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: agents.isEmpty
              ? const Center(child: Text('No available agents'))
              : ListView.builder(
                  itemCount: agents.length,
                  itemBuilder: (context, index) {
                    final agent = agents[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(agent.name.isNotEmpty
                            ? agent.name[0].toUpperCase()
                            : 'A'),
                      ),
                      title: Text(agent.name),
                      subtitle: Text(
                          'Load: ${agent.currentLoad}/${agent.maxTickets}'),
                      onTap: () => Navigator.of(context).pop(agent),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // Add escalation indicator
      color: widget.ticket.isEscalated ? Colors.red.withOpacity(0.05) : null,
      child: InkWell(
        onTap: () {
          if (widget.onTap != null) {
            widget.onTap!();
          } else {
            setState(() {
              _expanded = !_expanded;
            });
          }
        },
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.ticket.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.ticket.isEscalated ? Colors.red : null,
                            ),
                          ),
                        ),
                        // Add escalation badge
                        if (widget.ticket.isEscalated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ESC ${widget.ticket.escalationLevel}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (widget.ticket.sla != null)
                          SLAStatusIndicator(
                            sla: widget.ticket.sla!,
                            isCompact: true,
                          ),
                        const SizedBox(width: 8),
                        _buildStatusChip(),
                      ],
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 16),
                Text(
                  widget.ticket.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due: ${_formatDueDate()}',
                    style: TextStyle(
                      color: widget.ticket.isOverdue
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${widget.ticket.estimatedHours}h',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (widget.ticket.assignedTo != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16),
                    const SizedBox(width: 4),
                    Text(widget.ticket.assignedTo!.name),
                  ],
                ),
              ],
              if (_expanded && widget.ticket.sla != null) ...[
                const SizedBox(height: 16),
                SLAStatusIndicator(sla: widget.ticket.sla!),
              ],
              if (widget.onStatusUpdate != null ||
                  widget.ticket.status == 'queued') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActionButtons(),
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
    switch (widget.ticket.priority) {
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
        widget.ticket.statusDisplay,
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.ticket.status) {
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
      case 'escalated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDueDate() {
    final now = DateTime.now();
    final difference = widget.ticket.dueDate.difference(now);

    if (difference.inDays.abs() <= 7) {
      return timeago.format(widget.ticket.dueDate);
    } else {
      return '${widget.ticket.dueDate.day}/${widget.ticket.dueDate.month}';
    }
  }

  List<Widget> _buildActionButtons() {
    final List<Widget> buttons = [];

    // Add assign button for unassigned, queued tickets
    if (widget.ticket.status == 'queued' && widget.ticket.assignedTo == null) {
      buttons.add(
        TextButton.icon(
          onPressed: () => assignTicket(widget.ticket.id),
          icon: const Icon(Icons.person_add),
          label: const Text('Assign'),
        ),
      );
    }

    // Add status update buttons
    if (widget.onStatusUpdate != null) {
      switch (widget.ticket.status) {
        case 'assigned':
          buttons.add(
            TextButton.icon(
              onPressed: () => widget.onStatusUpdate?.call('in-progress'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start'),
            ),
          );
          break;
        case 'in-progress':
          buttons.add(
            TextButton.icon(
              onPressed: () => widget.onStatusUpdate?.call('resolved'),
              icon: const Icon(Icons.check),
              label: const Text('Resolve'),
            ),
          );
          break;
        case 'resolved':
          buttons.add(
            TextButton.icon(
              onPressed: () => widget.onStatusUpdate?.call('closed'),
              icon: const Icon(Icons.done_all),
              label: const Text('Close'),
            ),
          );
          break;
      }
    }

    return buttons;
  }
}
