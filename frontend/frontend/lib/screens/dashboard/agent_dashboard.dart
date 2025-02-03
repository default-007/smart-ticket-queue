import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/models/agent.dart';
import 'package:smart_ticketing/models/ticket.dart';
import 'package:smart_ticketing/providers/auth_provider.dart';
import 'package:smart_ticketing/widgets/agents/agent_status_card.dart';
import 'package:smart_ticketing/widgets/common/custom_drawer.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/agent_provider.dart';
import '../../widgets/tickets/ticket_card.dart';

class AgentDashboard extends ConsumerStatefulWidget {
  const AgentDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends ConsumerState<AgentDashboard> {
  Agent? _currentAgent;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ticketProvider.notifier).loadTickets();
      _loadAgentData();
    });
  }

  Future<void> _loadAgentData() async {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      // Fetch agent data using the user's ID
      await ref
          .read(agentProvider.notifier)
          .loadAgentByUserId(authState.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);
    final authState = ref.watch(authProvider);
    final agentState = ref.watch(agentProvider);

    // Get the current agent from the agent state
    _currentAgent = agentState.agents.isNotEmpty ? agentState.agents[0] : null;

    if (_currentAgent == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(ticketProvider.notifier).loadTickets();
              _loadAgentData();
            },
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          AgentStatusCard(
            agent: _currentAgent!,
            onStatusChange: (String newStatus) {
              ref.read(agentProvider.notifier).updateAgentStatus(
                    _currentAgent!.id,
                    newStatus,
                  );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ticketState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ticketState.error != null
                    ? Center(child: Text(ticketState.error!))
                    : _buildTicketList(ticketState.tickets),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(List<Ticket> tickets) {
    if (_currentAgent == null) return const SizedBox();

    final assignedTickets =
        tickets.where((t) => t.assignedTo?.id == _currentAgent!.id).toList();

    if (assignedTickets.isEmpty) {
      return const Center(
        child: Text('No tickets assigned'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignedTickets.length,
      itemBuilder: (context, index) {
        final ticket = assignedTickets[index];
        return TicketCard(
          ticket: ticket,
          onStatusUpdate: (String newStatus) {
            ref.read(ticketProvider.notifier).updateTicketStatus(
                  ticket.id,
                  newStatus,
                );
          },
        );
      },
    );
  }
}
