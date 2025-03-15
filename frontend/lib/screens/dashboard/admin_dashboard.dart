import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_ticketing/models/agent.dart';
import 'package:smart_ticketing/models/sla.dart';
import 'package:smart_ticketing/models/ticket.dart';
import 'package:smart_ticketing/models/workload.dart';
import 'package:smart_ticketing/providers/agent_provider.dart';
import 'package:smart_ticketing/providers/notification_provider.dart';
import 'package:smart_ticketing/providers/sla_provider.dart';
import 'package:smart_ticketing/providers/ticket_provider.dart';
import 'package:smart_ticketing/providers/workload_provider.dart';
import 'package:smart_ticketing/widgets/agents/agent_card.dart';
import 'package:smart_ticketing/widgets/common/custom_drawer.dart';
import 'package:smart_ticketing/widgets/common/error_display.dart';
import 'package:smart_ticketing/widgets/common/loading_indicator.dart';
import 'package:smart_ticketing/widgets/tickets/ticket_card.dart';

// Create a dashboard metrics provider to consolidate data
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  // Get data from all relevant providers
  final ticketState = await ref.watch(ticketProvider);
  final workloadState = await ref.watch(workloadProvider);
  final agentState = await ref.watch(agentProvider);
  final slaState = await ref.watch(slaProvider);

  // Parse metrics for the dashboard
  return DashboardMetrics(
    totalTickets: ticketState.tickets.length,
    openTickets: ticketState.tickets
        .where((t) => t.status != 'closed' && t.status != 'resolved')
        .length,
    slaBreaches:
        ticketState.tickets.where((t) => t.sla?.isBreached ?? false).length,
    totalAgents: agentState.agents.length,
    onlineAgents: agentState.agents.where((a) => a.status == 'online').length,
    averageWorkload: workloadState.metrics?.averageLoad ?? 0,
    slaCompliance: slaState.metrics?.slaComplianceRate ?? 0,
  );
});

class DashboardMetrics {
  final int totalTickets;
  final int openTickets;
  final int slaBreaches;
  final int totalAgents;
  final int onlineAgents;
  final double averageWorkload;
  final double slaCompliance;

  DashboardMetrics({
    required this.totalTickets,
    required this.openTickets,
    required this.slaBreaches,
    required this.totalAgents,
    required this.onlineAgents,
    required this.averageWorkload,
    required this.slaCompliance,
  });
}

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load all data initially
    Future.microtask(() => _loadAllData());

    // Set up periodic refresh
    _setupPeriodicRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Load data from providers
      await ref.read(ticketProvider.notifier).loadTickets();
      await ref.read(agentProvider.notifier).loadAvailableAgents();
      await ref.read(workloadProvider.notifier).refreshWorkloadData();
      await ref.read(slaProvider.notifier).loadSLAMetrics();
      await ref.read(notificationProvider.notifier).loadNotifications();
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _setupPeriodicRefresh() {
    // Refresh data every 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        _loadAllData();
        _setupPeriodicRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);
    final agentState = ref.watch(agentProvider);
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Queue'),
            Tab(text: 'Active'),
            Tab(text: 'Agents'),
          ],
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator())),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllData,
              tooltip: 'Refresh Data',
            ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(metricsAsync),
          _buildQueueTab(ticketState),
          _buildActiveTicketsTab(ticketState),
          _buildAgentsTab(agentState),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref.read(ticketProvider.notifier).processQueue();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Queue processing initiated')),
          );
        },
        tooltip: 'Process Queue',
        child: const Icon(Icons.sync),
      ),
    );
  }

  Widget _buildOverviewTab(AsyncValue<DashboardMetrics> metricsAsync) {
    return metricsAsync.when(
      data: (metrics) => _buildOverviewContent(metrics),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => ErrorDisplay(
        message: err.toString(),
        onRetry: _loadAllData,
      ),
    );
  }

  Widget _buildOverviewContent(DashboardMetrics metrics) {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Summary Cards Row
            Row(
              children: [
                _buildMetricCard(
                  'Total Tickets',
                  '${metrics.totalTickets}',
                  Icons.confirmation_number,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Open Tickets',
                  '${metrics.openTickets}',
                  Icons.inbox,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'SLA Breaches',
                  '${metrics.slaBreaches}',
                  Icons.warning,
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Agent Stats Row
            Row(
              children: [
                _buildMetricCard(
                  'Total Agents',
                  '${metrics.totalAgents}',
                  Icons.people,
                  Colors.purple,
                ),
                _buildMetricCard(
                  'Online Agents',
                  '${metrics.onlineAgents}',
                  Icons.person,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Avg Workload',
                  '${metrics.averageWorkload.toStringAsFixed(1)}h',
                  Icons.work,
                  Colors.amber,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // SLA Compliance
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SLA Compliance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: metrics.slaCompliance / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getSLAColor(metrics.slaCompliance),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${metrics.slaCompliance.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getSLAColor(metrics.slaCompliance),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  Color _getSLAColor(double compliance) {
    if (compliance >= 90) return Colors.green;
    if (compliance >= 75) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(icon, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final ticketState = ref.watch(ticketProvider);
    final notificationState = ref.watch(notificationProvider);

    // Get recent tickets (last 5)
    final recentTickets = ticketState.tickets
        .where((t) => t.status != 'closed')
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final recentActivity = recentTickets.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (recentActivity.isEmpty)
              const Center(child: Text('No recent activity')),
            ...recentActivity.map((ticket) => ListTile(
                  title: Text(ticket.title),
                  subtitle: Text(
                    '${ticket.statusDisplay} - Updated ${_formatTimeAgo(ticket.updatedAt)}',
                  ),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(ticket.status),
                    child: Text(
                      ticket.priority.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  trailing: ticket.assignedTo != null
                      ? Chip(
                          label: Text(ticket.assignedTo!.name.split(' ')[0]),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                        )
                      : const Chip(
                          label: Text('Unassigned'),
                          backgroundColor: Colors.grey,
                        ),
                  onTap: () {
                    // Navigate to ticket details
                    Navigator.pushNamed(
                      context,
                      '/tickets/detail',
                      arguments: ticket,
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'queued':
        return Colors.grey;
      case 'assigned':
        return Colors.blue;
      case 'in-progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.purple;
      case 'escalated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildQueueTab(TicketState ticketState) {
    if (ticketState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final queuedTickets =
        ticketState.tickets.where((t) => t.status == 'queued').toList();

    if (queuedTickets.isEmpty) {
      return const Center(child: Text('No tickets in queue'));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: queuedTickets.length,
        itemBuilder: (context, index) {
          return TicketCard(ticket: queuedTickets[index]);
        },
      ),
    );
  }

  Widget _buildActiveTicketsTab(TicketState ticketState) {
    if (ticketState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final activeTickets = ticketState.tickets
        .where((t) => t.status == 'in-progress' || t.status == 'assigned')
        .toList();

    if (activeTickets.isEmpty) {
      return const Center(child: Text('No active tickets'));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeTickets.length,
        itemBuilder: (context, index) {
          return TicketCard(ticket: activeTickets[index]);
        },
      ),
    );
  }

  Widget _buildAgentsTab(AgentState agentState) {
    if (agentState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (agentState.error != null) {
      return ErrorDisplay(
        message: agentState.error!,
        onRetry: () => ref.read(agentProvider.notifier).loadAvailableAgents(),
      );
    }

    if (agentState.agents.isEmpty) {
      return const Center(child: Text('No agents available'));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: agentState.agents.length,
        itemBuilder: (context, index) {
          final agent = agentState.agents[index];
          return AgentCard(
            agent: agent,
            onTap: () {
              // Navigate to agent details
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
