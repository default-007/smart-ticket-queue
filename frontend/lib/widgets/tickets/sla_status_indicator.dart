// lib/widgets/tickets/sla_status_indicator.dart
import 'package:flutter/material.dart';
import '../../models/sla.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SLAStatusIndicator extends ConsumerWidget {
  final TicketSLA sla;
  final bool isCompact;

  const SLAStatusIndicator({
    Key? key,
    required this.sla,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isCompact) {
      return _buildCompactIndicator(context);
    }

    return _buildFullIndicator(context);
  }

  Widget _buildCompactIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusDot(),
          const SizedBox(width: 4),
          Text(
            sla.getFormattedTimeUntilBreach(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullIndicator(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SLA Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 16),
            _buildSLATimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusDot(),
          const SizedBox(width: 8),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getStatusColor(),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSLATimeline() {
    return Column(
      children: [
        _buildTimelineItem(
          'Response Time',
          sla.responseTimeMet,
          sla.responseDeadline,
        ),
        const SizedBox(height: 12),
        _buildTimelineItem(
          'Resolution Time',
          sla.resolutionTimeMet,
          sla.resolutionDeadline,
        ),
      ],
    );
  }

  Widget _buildTimelineItem(String label, bool isMet, DateTime? deadline) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isMet ? Colors.green : _getStatusColor(),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isMet ? Icons.check : Icons.access_time,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              if (!isMet && deadline != null)
                Text(
                  _formatDeadline(deadline),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDeadline(DateTime deadline) {
    final difference = deadline.difference(DateTime.now());
    if (difference.isNegative) {
      return 'Breached ${-difference.inMinutes} minutes ago';
    }
    return 'Due in ${difference.inMinutes} minutes';
  }

  Color _getStatusColor() {
    if (sla.isBreached) return Colors.red;

    final responseTime = sla.timeUntilResponseBreach;
    final resolutionTime = sla.timeUntilResolutionBreach;

    if (responseTime != null && responseTime.inMinutes < 30 ||
        resolutionTime != null && resolutionTime.inMinutes < 60) {
      return Colors.orange;
    }

    return Colors.green;
  }

  String _getStatusText() {
    if (sla.isBreached) return 'Breached';

    final responseTime = sla.timeUntilResponseBreach;
    final resolutionTime = sla.timeUntilResolutionBreach;

    if (responseTime != null && responseTime.inMinutes < 30 ||
        resolutionTime != null && resolutionTime.inMinutes < 60) {
      return 'At Risk';
    }

    return 'On Track';
  }
}
