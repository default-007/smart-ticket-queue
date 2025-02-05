import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/widgets/common/custom_app_bar.dart';
import 'package:smart_ticketing/widgets/common/custom_drawer.dart';
import 'package:smart_ticketing/widgets/common/error_display.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/tickets/ticket_card.dart';
import '../../widgets/tickets/ticket_filter.dart';

final ticketsLoadedProvider = StateProvider<bool>((ref) => false);

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
    // Only load tickets if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLoaded = ref.read(ticketsLoadedProvider);
      if (!isLoaded) {
        ref.read(ticketProvider.notifier).loadTickets();
        ref.read(ticketsLoadedProvider.notifier).state = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);
    print(
        'Ticket state: ${ticketState.tickets.length} tickets, error: ${ticketState.error}');

    return Scaffold(
      appBar: const CustomAppBar(title: 'Tickets'),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          TicketFilter(
            selectedStatus: _selectedStatus,
            onStatusChanged: (String? status) {
              setState(() {
                _selectedStatus = status;
              });
              // Use Future.microtask to avoid build-time state modifications
              Future.microtask(() {
                ref.read(ticketProvider.notifier).loadTickets(status: status);
              });
            },
          ),
          Expanded(
            child: ticketState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ticketState.error != null
                    ? ErrorDisplay(
                        message: ticketState.error!,
                        onRetry: () {
                          Future.microtask(() {
                            ref
                                .read(ticketProvider.notifier)
                                .loadTickets(status: _selectedStatus);
                          });
                        },
                      )
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

  Widget _buildTicketList(List tickets) {
    print('Building ticket list with ${tickets.length} tickets: $tickets');
    if (tickets.isEmpty) {
      return const Center(
        child: Text('No tickets found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Reset loaded state and reload tickets
        ref.read(ticketsLoadedProvider.notifier).state = false;
        await ref
            .read(ticketProvider.notifier)
            .loadTickets(status: _selectedStatus);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return TicketCard(
            ticket: ticket,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/tickets/detail',
                arguments: ticket,
              );
            },
          );
        },
      ),
    );
  }
}
