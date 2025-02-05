import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sla_provider.dart';
import '../../models/sla.dart';
import '../../widgets/common/custom_app_bar.dart';

class SLAConfigScreen extends ConsumerStatefulWidget {
  const SLAConfigScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SLAConfigScreen> createState() => _SLAConfigScreenState();
}

class _SLAConfigScreenState extends ConsumerState<SLAConfigScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(slaProvider.notifier).loadSLAConfigs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final slaState = ref.watch(slaProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'SLA Configuration',
      ),
      body: slaState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : slaState.error != null
              ? Center(child: Text(slaState.error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPrioritySection('High Priority', 1, slaState.configs),
                    const Divider(height: 32),
                    _buildPrioritySection(
                        'Medium Priority', 2, slaState.configs),
                    const Divider(height: 32),
                    _buildPrioritySection('Low Priority', 3, slaState.configs),
                  ],
                ),
    );
  }

  Widget _buildPrioritySection(
    String title,
    int priority,
    List<SLAConfig> configs,
  ) {
    final priorityConfigs =
        configs.where((config) => config.priority == priority).toList();

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
        ...priorityConfigs.map((config) => _buildConfigCard(config)).toList(),
      ],
    );
  }

  Widget _buildConfigCard(SLAConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.category.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeRow(
              'Response Time',
              config.responseTime,
              onChanged: (value) {
                _updateConfig(
                  config,
                  responseTime: value,
                );
              },
            ),
            const SizedBox(height: 8),
            _buildTimeRow(
              'Resolution Time',
              config.resolutionTime,
              onChanged: (value) {
                _updateConfig(
                  config,
                  resolutionTime: value,
                );
              },
            ),
            const SizedBox(height: 16),
            _buildEscalationRules(config.escalationRules),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(
    String label,
    int minutes, {
    required Function(int) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: minutes.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  final newValue = int.tryParse(value);
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text('minutes'),
          ],
        ),
      ],
    );
  }

  Widget _buildEscalationRules(List<SLAEscalationRule> rules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escalation Rules',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...rules.map((rule) => _buildEscalationRule(rule)).toList(),
      ],
    );
  }

  Widget _buildEscalationRule(SLAEscalationRule rule) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Level ${rule.level}'),
          Text('${rule.threshold} min'),
          Text(rule.notifyRoles.join(', ')),
        ],
      ),
    );
  }

  Future<void> _updateConfig(
    SLAConfig config, {
    int? responseTime,
    int? resolutionTime,
  }) async {
    await ref.read(slaProvider.notifier).updateSLAConfig(
      config.priority,
      config.category,
      {
        if (responseTime != null) 'responseTime': responseTime,
        if (resolutionTime != null) 'resolutionTime': resolutionTime,
      },
    );
  }
}
