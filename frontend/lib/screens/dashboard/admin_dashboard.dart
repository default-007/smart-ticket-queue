import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/providers/agent_provider.dart';
import 'package:smart_ticketing/providers/ticket_provider.dart';
import 'package:smart_ticketing/widgets/agents/agent_card.dart';
import 'package:smart_ticketing/widgets/common/custom_drawer.dart';
import 'package:smart_ticketing/widgets/tickets/ticket_card.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ticketProvider.notifier).loadTickets();
      ref.read(agentProvider.notifier).loadAvailableAgents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);
    final agentState = ref.watch(agentProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Queue'),
              Tab(text: 'Active'),
              Tab(text: 'Agents'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(ticketProvider.notifier).loadTickets();
                ref.read(agentProvider.notifier).loadAvailableAgents();
              },
            ),
          ],
        ),
        drawer: const CustomDrawer(),
        body: TabBarView(
          children: [
            _QueueTab(ticketState: ticketState),
            _ActiveTicketsTab(ticketState: ticketState),
            _AgentsTab(agentState: agentState),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await ref.read(ticketProvider.notifier).processQueue();
          },
          child: const Icon(Icons.sync),
        ),
      ),
    );
  }
}

class _QueueTab extends StatelessWidget {
  final TicketState ticketState;

  const _QueueTab({Key? key, required this.ticketState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ticketState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final queuedTickets =
        ticketState.tickets.where((t) => t.status == 'queued').toList();

    if (queuedTickets.isEmpty) {
      return const Center(child: Text('No tickets in queue'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: queuedTickets.length,
      itemBuilder: (context, index) {
        return TicketCard(ticket: queuedTickets[index]);
      },
    );
  }
}

class _ActiveTicketsTab extends StatelessWidget {
  final TicketState ticketState;

  const _ActiveTicketsTab({Key? key, required this.ticketState})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ticketState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeTickets =
        ticketState.tickets.where((t) => t.status == 'in-progress').toList();

    if (activeTickets.isEmpty) {
      return const Center(child: Text('No active tickets'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeTickets.length,
      itemBuilder: (context, index) {
        return TicketCard(ticket: activeTickets[index]);
      },
    );
  }
}

class _AgentsTab extends StatelessWidget {
  final AgentState agentState;

  const _AgentsTab({Key? key, required this.agentState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (agentState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agentState.agents.length,
      itemBuilder: (context, index) {
        final agent = agentState.agents[index];
        return AgentCard(agent: agent);
      },
    );
  }
}
