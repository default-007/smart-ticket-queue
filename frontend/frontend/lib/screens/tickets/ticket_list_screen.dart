import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/models/ticket.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/tickets/ticket_card.dart';
import '../../widgets/tickets/ticket_filter.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    ref.read(ticketProvider.notifier).loadTickets(status: _selectedStatus);
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          TicketFilter(
            selectedStatus: _selectedStatus,
            onStatusChanged: (String? status) {
              setState(() {
                _selectedStatus = status;
              });
              _loadTickets();
            },
          ),
          Expanded(
            child: ticketState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ticketState.error != null
                    ? Center(child: Text(ticketState.error!))
                    : _buildTicketList(ticketState.tickets),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/tickets/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTicketList(List<Ticket> tickets) {
    if (tickets.isEmpty) {
      return const Center(
        child: Text('No tickets found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        return TicketCard(
          ticket: tickets[index],
          onTap: () {
            Navigator.pushNamed(
              context,
              '/tickets/detail',
              arguments: tickets[index],
            );
          },
        );
      },
    );
  }
}
