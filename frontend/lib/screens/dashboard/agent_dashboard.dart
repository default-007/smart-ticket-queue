// lib/screens/dashboard/agent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/models/agent.dart';
import 'package:smart_ticketing/models/ticket.dart';
import 'package:smart_ticketing/providers/auth_provider.dart';
import 'package:smart_ticketing/widgets/agents/agent_status_card.dart';
import 'package:smart_ticketing/widgets/common/custom_drawer.dart';
import 'package:smart_ticketing/widgets/common/error_display.dart';
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
      _loadAgentData().then((_) => _loadTicketsForAgent());
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

  // This method loads tickets assigned to the current agent
  Future<void> _loadTicketsForAgent() async {
    final agentState = ref.read(agentProvider);
    if (agentState.agents.isNotEmpty) {
      _currentAgent = agentState.agents[0];

      // Use assignedTo parameter
      await ref.read(ticketProvider.notifier).loadTickets(
            assignedTo: _currentAgent!.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);
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
              _loadAgentData().then((_) => _loadTicketsForAgent());
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
                : ticketState.hasError
                    ? ErrorDisplay(
                        // Use ErrorDisplay widget for consistent error handling
                        message: ticketState.errorMessage ??
                            'An unknown error occurred',
                        onRetry: () {
                          _loadTicketsForAgent();
                        },
                      )
                    : _buildTicketList(ticketState.tickets),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(List<Ticket> tickets) {
    if (_currentAgent == null) return const SizedBox();

    // Filter tickets for the current agent (though this should now be redundant)
    final assignedTickets = tickets;

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
