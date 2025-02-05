import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/sla.dart';

class SLAChart extends StatelessWidget {
  final SLAMetrics metrics;

  const SLAChart({
    Key? key,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  //axisSide: meta.axisSide,
                  meta: meta,
                  child: Text(
                    _getBottomTitle(value.toInt()),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: _generateSpots(),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    // This is a placeholder. In a real implementation,
    // you would use historical SLA data points
    return [
      const FlSpot(0, 85),
      const FlSpot(1, 80),
      const FlSpot(2, 90),
      const FlSpot(3, 87),
      const FlSpot(4, 93),
      const FlSpot(5, 88),
      FlSpot(6, metrics.slaComplianceRate),
    ];
  }

  String _getBottomTitle(int value) {
    // This is a placeholder. In a real implementation,
    // you would use actual date labels
    final now = DateTime.now();
    final date = now.subtract(Duration(days: (6 - value)));
    return '${date.day}/${date.month}';
  }
}
