import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                          const SizedBox(height: 16),
                          _buildSection(
                            'Agent Workloads',
                            AgentWorkloadList(
                              workloads: workloadState.agentWorkloads,
                            ),
                          ),
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
