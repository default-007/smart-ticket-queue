import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ticketing/providers/sla_provider.dart';
import 'package:smart_ticketing/models/sla.dart';
import 'package:smart_ticketing/widgets/common/custom_app_bar.dart';
import 'package:smart_ticketing/widgets/common/custom_drawer.dart';
import 'package:smart_ticketing/widgets/common/error_display.dart';

class SLAConfigScreen extends ConsumerStatefulWidget {
  const SLAConfigScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SLAConfigScreen> createState() => _SLAConfigScreenState();
}

class _SLAConfigScreenState extends ConsumerState<SLAConfigScreen> {
  bool showHelp = false;

  @override
  void initState() {
    super.initState();
    // Use the existing method to load SLA configurations
    Future.microtask(() => ref.read(slaProvider.notifier).loadSLAConfigs());
  }

  @override
  Widget build(BuildContext context) {
    final slaState = ref.watch(slaProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'SLA Configuration',
        actions: [
          IconButton(
            icon: Icon(showHelp ? Icons.help_outlined : Icons.help_outline),
            onPressed: () => setState(() => showHelp = !showHelp),
            tooltip: 'Toggle help text',
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: slaState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : slaState.error != null
              ? ErrorDisplay(
                  message: slaState.error!,
                  onRetry: () =>
                      ref.read(slaProvider.notifier).loadSLAConfigs(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHelp) _buildHelpCard(),
                      const SizedBox(height: 16),
                      _buildPrioritySection('High Priority (P1)', 1,
                          Colors.red.shade100, Colors.red, slaState.configs),
                      const SizedBox(height: 24),
                      _buildPrioritySection(
                          'Medium Priority (P2)',
                          2,
                          Colors.orange.shade100,
                          Colors.orange,
                          slaState.configs),
                      const SizedBox(height: 24),
                      _buildPrioritySection(
                          'Low Priority (P3)',
                          3,
                          Colors.green.shade100,
                          Colors.green,
                          slaState.configs),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHelpCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About SLA Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Service Level Agreements (SLAs) define the expected timeframes for responding to and resolving tickets. Each combination of priority and category has specific time thresholds:',
            ),
            const SizedBox(height: 8),
            _buildHelpItem(
              'Response Time',
              'Maximum time allowed before an agent must provide the first response to a ticket (in minutes)',
            ),
            _buildHelpItem(
              'Resolution Time',
              'Maximum time allowed for a ticket to be completely resolved (in minutes)',
            ),
            _buildHelpItem(
              'Escalation Rules',
              'Define when and to whom tickets should be escalated if SLA thresholds are approached or breached',
            ),
            const SizedBox(height: 8),
            const Text(
              'Changes to these values will affect all new tickets created with the corresponding priority and category.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.arrow_right, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection(String title, int priority, Color bgColor,
      Color accentColor, List<SLAConfig> configs) {
    final priorityConfigs =
        configs.where((config) => config.priority == priority).toList();

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.flag, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...priorityConfigs
              .map((config) => _buildConfigCard(config, accentColor))
              .toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConfigCard(SLAConfig config, Color accentColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(config.category),
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _getCategoryName(config.category),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showSLAEditDialog(config),
                  tooltip: 'Edit configuration',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimelineVisualization(config),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTimeCard(
                    'Response',
                    config.responseTime,
                    Icons.chat_bubble_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeCard(
                    'Resolution',
                    config.resolutionTime,
                    Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            if (config.escalationRules.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Escalation Rules',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...config.escalationRules
                  .map((rule) => _buildEscalationRule(rule, accentColor))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineVisualization(SLAConfig config) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Base timeline
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              color: Colors.grey.shade200,
              height: 2,
            ),
          ),

          // Timeline points
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: _buildTimelinePoint('Start', Colors.blue),
          ),

          // Response time marker
          Positioned(
            left: 100 *
                (config.responseTime / config.resolutionTime).clamp(0.05, 0.95),
            top: 0,
            bottom: 0,
            child: _buildTimelinePoint(
              '${_formatTime(config.responseTime)}\nResponse',
              Colors.orange,
            ),
          ),

          // Resolution time marker
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _buildTimelinePoint(
              '${_formatTime(config.resolutionTime)}\nResolution',
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePoint(String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimeCard(String title, int minutes, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatTime(minutes),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationRule(SLAEscalationRule rule, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rule.level.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('At ${_formatTime(rule.threshold)} →'),
          const SizedBox(width: 8),
          Text(
            rule.notifyRoles.join(', '),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showSLAEditDialog(SLAConfig config) {
    final responseTimeController =
        TextEditingController(text: config.responseTime.toString());
    final resolutionTimeController =
        TextEditingController(text: config.resolutionTime.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${_getCategoryName(config.category)} SLA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set timeframes in minutes. All new tickets will use these SLA settings.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Response Time (min)',
                        style: TextStyle(fontSize: 12),
                      ),
                      TextField(
                        controller: responseTimeController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., 30',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resolution Time (min)',
                        style: TextStyle(fontSize: 12),
                      ),
                      TextField(
                        controller: resolutionTimeController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., 240',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Would implement escalation rule editing here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final responseTime = int.tryParse(responseTimeController.text);
              final resolutionTime =
                  int.tryParse(resolutionTimeController.text);

              if (responseTime != null && resolutionTime != null) {
                if (responseTime > resolutionTime) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Response time cannot be greater than resolution time'),
                    ),
                  );
                  return;
                }

                ref.read(slaProvider.notifier).updateSLAConfig(
                  config.priority,
                  config.category,
                  {
                    'responseTime': responseTime,
                    'resolutionTime': resolutionTime,
                  },
                );
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid numbers'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'technical':
        return Icons.computer;
      case 'billing':
        return Icons.payment;
      case 'urgent':
        return Icons.priority_high;
      case 'general':
      default:
        return Icons.help_outline;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'technical':
        return 'Technical Support';
      case 'billing':
        return 'Billing Inquiry';
      case 'urgent':
        return 'Urgent Issue';
      case 'general':
      default:
        return 'General Inquiry';
    }
  }

  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else if (minutes == 60) {
      return '1 hour';
    } else if (minutes % 60 == 0) {
      return '${minutes ~/ 60} hours';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '$hours h $mins min';
    }
  }
}
