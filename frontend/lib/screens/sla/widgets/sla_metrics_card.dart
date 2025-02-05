import 'package:flutter/material.dart';
import '../../../models/sla.dart';

class SLAMetricsCard extends StatelessWidget {
  final SLAMetrics metrics;

  const SLAMetricsCard({
    Key? key,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SLA Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildMetricWidget(
                  context,
                  'Compliance Rate',
                  metrics.complianceRateFormatted,
                  _getComplianceColor(metrics.slaComplianceRate),
                ),
                _buildMetricWidget(
                  context,
                  'Total Tickets',
                  metrics.totalTickets.toString(),
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMetricWidget(
                  context,
                  'Avg Response Time',
                  metrics.averageResponseTimeFormatted,
                  Colors.orange,
                ),
                _buildMetricWidget(
                  context,
                  'Avg Resolution Time',
                  metrics.averageResolutionTimeFormatted,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBreachesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricWidget(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreachesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Response SLA Breaches'),
              Text(
                metrics.responseSLABreaches.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Resolution SLA Breaches'),
              Text(
                metrics.resolutionSLABreaches.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getComplianceColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 75) return Colors.orange;
    return Colors.red;
  }
}
