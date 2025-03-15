import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SLATrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> trendData;
  final String period;

  const SLATrendChart({
    Key? key,
    required this.trendData,
    this.period = 'weekly',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SLA Compliance Trends',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
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
                        getTitlesWidget: _getBottomTitles,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getDataPoints(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getDataPoints() {
    return trendData.asMap().entries.map((entry) {
      final dataPoint = entry.value;
      // Calculate compliance rate and convert to double explicitly
      final complianceRate = dataPoint['totalTickets'] > 0
          ? (100.0 -
              ((dataPoint['slaBreaches'] / dataPoint['totalTickets']) * 100.0))
          : 100.0;

      return FlSpot(entry.key.toDouble(), complianceRate.toDouble());
    }).toList();
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    if (value.toInt() >= trendData.length) return const Text('');

    final dataPoint = trendData[value.toInt()];
    String label = '';

    if (period == 'weekly') {
      label = 'W${dataPoint['_id']['week']}';
    } else if (period == 'monthly') {
      label =
          '${dataPoint['_id']['month']}/${dataPoint['_id']['year'].toString().substring(2)}';
    } else {
      label = '${dataPoint['_id']['day']}/${dataPoint['_id']['month']}';
    }

    return Text(
      label,
      style: const TextStyle(fontSize: 10),
    );
  }
}
