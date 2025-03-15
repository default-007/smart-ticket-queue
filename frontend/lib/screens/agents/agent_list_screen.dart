import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/agent_provider.dart';
import '../../widgets/agents/agent_card.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_drawer.dart';
import '../../widgets/common/error_display.dart';

class AgentListScreen extends ConsumerStatefulWidget {
  const AgentListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends ConsumerState<AgentListScreen> {
  bool _showOnlyAvailable = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadAgents();
    });
  }

  void _loadAgents() {
    if (_showOnlyAvailable) {
      ref.read(agentProvider.notifier).loadAvailableAgents();
    } else {
      ref.read(agentProvider.notifier).loadAgents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentProvider);

    final displayedAgents = _showOnlyAvailable
        ? agentState.agents.where((a) => a.status == 'online').toList()
        : agentState.agents;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Agents'),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Show only available agents:'),
                Switch(
                  value: _showOnlyAvailable,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyAvailable = value;
                    });
                    _loadAgents();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: agentState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : agentState.error != null
                    ? ErrorDisplay(
                        message: agentState.error!,
                        onRetry: _loadAgents,
                      )
                    : _buildAgentList(agentState.agents),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          GoRouter.of(context).go('/agents/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAgentList(List agents) {
    if (agents.isEmpty) {
      return const Center(
        child: Text('No agents found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(agentProvider.notifier).loadAgents();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: agents.length,
        itemBuilder: (context, index) {
          final agent = agents[index];
          return AgentCard(
            agent: agent,
            onTap: () {
              context.push('/agents/detail', extra: agent);
            },
            onEdit: () {
              context.push('/agents/edit/${agent.id}', extra: agent);
            },
          );
        },
      ),
    );
  }
}
