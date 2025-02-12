// lib/screens/agents/agent_list_screen.dart
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
  @override
  void initState() {
    super.initState();
    // Load agents after the frame is built
    Future.microtask(() {
      ref.read(agentProvider.notifier).loadAgents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final agentState = ref.watch(agentProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Agents'),
      drawer: const CustomDrawer(),
      body: agentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : agentState.error != null
              ? ErrorDisplay(
                  message: agentState.error!,
                  onRetry: () {
                    Future.microtask(() {
                      ref.read(agentProvider.notifier).loadAgents();
                    });
                  },
                )
              : _buildAgentList(agentState.agents),
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
              Navigator.pushNamed(
                context,
                '/agents/detail',
                arguments: agent,
              );
            },
          );
        },
      ),
    );
  }
}
