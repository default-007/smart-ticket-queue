import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/workload.dart';

class TeamCapacityChart extends StatelessWidget {
  final List<TeamCapacity> teamCapacities;

  const TeamCapacityChart({
    Key? key,
    required this.teamCapacities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the maximum utilization across all teams
    double maxUtilization = 0;
    for (final team in teamCapacities) {
      if (team.utilizationPercentage > maxUtilization) {
        maxUtilization = team.utilizationPercentage;
      }
    }

    // Add 20% padding to the max value and round to nearest 10
    double dynamicMaxY = (maxUtilization * 1.2).ceil() / 10 * 10;
    // Ensure minimum of 100
    dynamicMaxY = dynamicMaxY < 100 ? 100 : dynamicMaxY;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: dynamicMaxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            //tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final team = teamCapacities[groupIndex];
              return BarTooltipItem(
                '${team.teamName}\n'
                'Utilization: ${team.utilizationPercentage.toStringAsFixed(1)}%\n'
                'Active: ${team.activeAgents}/${team.totalAgents} agents',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= teamCapacities.length)
                  return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    teamCapacities[value.toInt()].teamName,
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}%');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: teamCapacities.asMap().entries.map((entry) {
          final index = entry.key;
          final team = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: team.utilizationPercentage,
                color: _getUtilizationColor(team.utilizationPercentage),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getUtilizationColor(double utilization) {
    if (utilization > 90) return Colors.red;
    if (utilization > 75) return Colors.orange;
    return Colors.green;
  }
}
