import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/workload.dart';

class WorkloadDistributionChart extends StatelessWidget {
  final WorkloadMetrics metrics;

  const WorkloadDistributionChart({
    Key? key,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> sections = [];
    metrics.workloadDistribution.forEach((key, value) {
      sections.add(
        PieChartSectionData(
          value: value.toDouble(),
          title: '$key\n$value',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          color: _getWorkloadColor(key),
        ),
      );
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Color _getWorkloadColor(String category) {
    switch (category.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'overloaded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
