import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/agent.dart';
import '../../providers/agent_provider.dart';
import 'agent_status_badge.dart';

class AgentSelector extends ConsumerWidget {
  final Function(String) onAgentSelected;

  const AgentSelector({
    Key? key,
    required this.onAgentSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentState = ref.watch(agentProvider);

    if (agentState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (agentState.agents.isEmpty) {
      return const Text('No available agents');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Agent',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...agentState.agents.map((agent) => _buildAgentTile(agent)).toList(),
      ],
    );
  }

  Widget _buildAgentTile(Agent agent) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(agent.name[0]),
      ),
      title: Text(agent.name),
      subtitle: Text('Current Load: ${agent.currentLoad}h'),
      trailing: AgentStatusBadge(
        status: agent.status,
        isOnShift: agent.isOnShift,
      ),
      onTap: () => onAgentSelected(agent.id),
    );
  }
}
