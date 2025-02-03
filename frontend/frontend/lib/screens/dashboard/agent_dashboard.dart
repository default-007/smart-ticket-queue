import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ticketProvider.notifier).loadTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);
    final authState = ref.watch(authProvider);
    final agent = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ticketProvider.notifier).loadTickets(),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          AgentStatusCard(
            agent: agent,
            onStatusChange: (String newStatus) {
              ref.read(agentProvider.notifier).updateAgentStatus(
                    agent.id,
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
    final assignedTickets =
        tickets.where((t) => t.assignedTo?.id == authState.user?.id).toList();

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
