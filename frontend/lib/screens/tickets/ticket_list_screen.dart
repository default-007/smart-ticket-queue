// lib/screens/tickets/ticket_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_ticketing/widgets/common/custom_app_bar.dart';
import 'package:smart_ticketing/widgets/common/custom_drawer.dart';
import 'package:smart_ticketing/widgets/common/error_display.dart';
import 'package:smart_ticketing/widgets/common/loading_indicator.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure we load tickets when the screen initializes
    Future.microtask(() => _loadTickets(forceRefresh: true));
  }

  Future<void> _loadTickets({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(ticketProvider.notifier).loadTickets(
            status: _selectedStatus,
            forceRefresh: forceRefresh,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tickets: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tickets',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadTickets(forceRefresh: true),
            tooltip: 'Refresh tickets',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          TicketFilter(
            selectedStatus: _selectedStatus,
            onStatusChanged: (String? status) {
              setState(() {
                _selectedStatus = status;
              });
              // Force reload with the new filter
              _loadTickets(forceRefresh: true);
            },
          ),
          Expanded(
            child: _isLoading || ticketState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ticketState.hasError
                    ? ErrorDisplay(
                        message: ticketState.errorMessage ??
                            'An unknown error occurred',
                        onRetry: () {
                          _loadTickets(forceRefresh: true);
                        },
                      )
                    : _buildTicketList(ticketState.tickets),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/tickets/create');
        },
        tooltip: 'Create new ticket',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTicketList(List tickets) {
    if (tickets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No tickets found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create a new ticket or change your filter',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadTickets(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return TicketCard(
            ticket: ticket,
            onTap: () {
              context.push('/tickets/detail', extra: ticket);
            },
            onStatusUpdate: (newStatus) {
              // Allow updating ticket status directly from the list
              ref.read(ticketProvider.notifier).updateTicketStatus(
                    ticket.id,
                    newStatus,
                  );
            },
          );
        },
      ),
    );
  }
}
