import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sla_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import 'widgets/sla_metrics_card.dart';
import 'widgets/sla_chart.dart';
import 'widgets/sla_date_filter.dart';

class SLADashboardScreen extends ConsumerWidget {
  const SLADashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slaState = ref.watch(slaProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'SLA Dashboard',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(slaProvider.notifier).loadSLAMetrics();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SLADateFilter(
                  startDate: slaState.startDate,
                  endDate: slaState.endDate,
                  onDateRangeSelected: (start, end) {
                    ref.read(slaProvider.notifier).updateDateRange(start, end);
                  },
                ),
                const SizedBox(height: 16),
                if (slaState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (slaState.error != null)
                  Center(
                    child: Text(
                      slaState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else if (slaState.metrics != null) ...[
                  SLAMetricsCard(metrics: slaState.metrics!),
                  const SizedBox(height: 24),
                  const Text(
                    'SLA Compliance Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: SLAChart(metrics: slaState.metrics!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/sla/config');
        },
        child: const Icon(Icons.settings),
      ),
    );
  }
}
