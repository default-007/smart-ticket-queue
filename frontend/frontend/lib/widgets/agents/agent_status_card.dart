import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
import 'agent_status_badge.dart';
import 'package:intl/intl.dart';

class AgentStatusCard extends ConsumerWidget {
  final Agent agent;
  final Function(String) onStatusChange;

  const AgentStatusCard({
    Key? key,
    required this.agent,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
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
                    Text(
                      'Agent Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    AgentStatusBadge(
                      status: agent.status,
                      isOnShift: agent.isOnShift,
                    ),
                  ],
                ),
                _buildStatusDropdown(context),
              ],
            ),
            const Divider(height: 32),
            _buildShiftInfo(),
            if (agent.currentTicket != null) ...[
              const Divider(height: 32),
              _buildCurrentWorkload(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return DropdownButton<String>(
      value: agent.status,
      items: [
        DropdownMenuItem(
          value: 'online',
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Online'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'busy',
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Busy'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'offline',
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Offline'),
            ],
          ),
        ),
      ],
      onChanged: (String? newStatus) {
        if (newStatus != null) {
          onStatusChange(newStatus);
        }
      },
    );
  }

  Widget _buildShiftInfo() {
    final startTime = DateFormat('HH:mm').format(agent.shift.start);
    final endTime = DateFormat('HH:mm').format(agent.shift.end);
    final now = DateTime.now();
    final shiftProgress = _calculateShiftProgress(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Shift',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$startTime - $endTime'),
            Text(agent.shift.timezone),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: shiftProgress,
          backgroundColor: Colors.grey[200],
        ),
        const SizedBox(height: 4),
        Text(
          '${(shiftProgress * 100).toInt()}% of shift complete',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentWorkload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Workload',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${agent.currentLoad}h of ${agent.maxTickets}h'),
            Text(
              '${((agent.currentLoad / agent.maxTickets) * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: agent.currentLoad / agent.maxTickets,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getWorkloadColor(agent.currentLoad / agent.maxTickets),
          ),
        ),
      ],
    );
  }

  double _calculateShiftProgress(DateTime now) {
    final shiftStart = agent.shift.start;
    final shiftEnd = agent.shift.end;
    final totalShiftDuration = shiftEnd.difference(shiftStart).inMinutes;
    final elapsedDuration = now.difference(shiftStart).inMinutes;

    if (elapsedDuration < 0) return 0;
    if (elapsedDuration > totalShiftDuration) return 1;

    return elapsedDuration / totalShiftDuration;
  }

  Color _getWorkloadColor(double workloadPercentage) {
    if (workloadPercentage >= 0.9) {
      return Colors.red;
    } else if (workloadPercentage >= 0.7) {
      return Colors.orange;
    }
    return Colors.green;
  }
}
