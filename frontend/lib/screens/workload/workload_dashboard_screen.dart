import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/widgets/common/custom_drawer.dart';
import '../../providers/workload_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import 'widgets/workload_overview_card.dart';
import 'widgets/agent_workload_list.dart';
import 'widgets/team_capacity_chart.dart';
import 'widgets/workload_distribution_chart.dart';

class WorkloadDashboardScreen extends ConsumerStatefulWidget {
  const WorkloadDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WorkloadDashboardScreen> createState() =>
      _WorkloadDashboardScreenState();
}

class _WorkloadDashboardScreenState
    extends ConsumerState<WorkloadDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(workloadProvider.notifier).refreshWorkloadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workloadState = ref.watch(workloadProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Workload Dashboard',
        actions: [
          if (workloadState.metrics?.needsRebalancing ?? false)
            IconButton(
              icon: const Icon(Icons.balance),
              onPressed: () {
                _showRebalanceConfirmation(context);
              },
              tooltip: 'Rebalance Workload',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(workloadProvider.notifier).refreshWorkloadData();
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: workloadState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : workloadState.error != null
              ? Center(child: Text(workloadState.error!))
              : RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(workloadProvider.notifier)
                        .refreshWorkloadData();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (workloadState.metrics != null)
                            WorkloadOverviewCard(
                              metrics: workloadState.metrics!,
                            ),

                          // Add the prediction card
                          if (workloadState.predictions != null)
                            _buildPredictionCard(workloadState.predictions),

                          const SizedBox(height: 16),
                          _buildSection(
                            'Agent Workloads',
                            AgentWorkloadList(
                              workloads: workloadState.agentWorkloads,
                            ),
                          ),
                          if (workloadState.teamCapacities.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSection(
                              'Team Capacity',
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: TeamCapacityChart(
                                  teamCapacities: workloadState.teamCapacities,
                                ),
                              ),
                            ),
                          ],
                          if (workloadState.metrics != null) ...[
                            const SizedBox(height: 24),
                            _buildSection(
                              'Workload Distribution',
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: WorkloadDistributionChart(
                                  metrics: workloadState.metrics!,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(workloadProvider.notifier).optimizeAssignments();
        },
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Optimize'),
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic>? predictions) {
    if (predictions == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workload Prediction',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Daily Average
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Ticket Average:'),
                Text(
                  '${predictions['nextWeekLoad']['dailyAverage'].toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Weekly Prediction
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Next Week Prediction:'),
                Text(
                  '${predictions['nextWeekLoad']['predictedTotal']} tickets',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Additional Agent Needs
            if (predictions['agentCapacityNeeds'] != null) ...[
              const Text('Additional Resources Needed:'),
              const SizedBox(height: 8),
              ...predictions['agentCapacityNeeds']
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${entry.key} Department:'),
                          Text(
                            '${entry.value['additionalAgentsNeeded']} agents',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: entry.value['additionalAgentsNeeded'] > 0
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Future<void> _showRebalanceConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rebalance Workload'),
        content: const Text(
          'This will redistribute tickets among available agents. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(workloadProvider.notifier).rebalanceWorkload();
            },
            child: const Text('Rebalance'),
          ),
        ],
      ),
    );
  }
}
