import 'package:flutter/material.dart';
import '../../../models/workload.dart';

class AgentWorkloadList extends StatelessWidget {
  final List<AgentWorkload> workloads;

  const AgentWorkloadList({
    Key? key,
    required this.workloads,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workloads.length,
      itemBuilder: (context, index) {
        final workload = workloads[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: workload.statusColor.withOpacity(0.1),
              child: Text(
                workload.agentName[0].toUpperCase(),
                style: TextStyle(color: workload.statusColor),
              ),
            ),
            title: Text(workload.agentName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: workload.utilizationPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(workload.statusColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${workload.currentLoad}h / ${workload.maxLoad}h - ${workload.status}',
                  style: TextStyle(color: workload.statusColor),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${workload.activeTickets} active'),
                Text('${workload.queuedTickets} queued'),
              ],
            ),
          ),
        );
      },
    );
  }
}
