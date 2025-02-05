import 'package:flutter/material.dart';
import '../../../models/workload.dart';

class WorkloadOverviewCard extends StatelessWidget {
  final WorkloadMetrics metrics;

  const WorkloadOverviewCard({
    Key? key,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Workload',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetricTile(
                  'Active Agents',
                  '${metrics.activeAgents}/${metrics.totalAgents}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildMetricTile(
                  'Avg Load',
                  '${metrics.averageLoad.toStringAsFixed(1)}h',
                  Icons.work,
                  Colors.orange,
                ),
                _buildMetricTile(
                  'Utilization',
                  '${metrics.capacityUtilization.toStringAsFixed(1)}%',
                  Icons.analytics,
                  _getUtilizationColor(metrics.capacityUtilization),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Color _getUtilizationColor(double utilization) {
    if (utilization > 90) return Colors.red;
    if (utilization > 75) return Colors.orange;
    return Colors.green;
  }
}
