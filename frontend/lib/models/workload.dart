import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'agent.dart';

part 'workload.g.dart';

@JsonSerializable()
class WorkloadMetrics {
  final int totalAgents;
  final int activeAgents;
  final double averageLoad;
  final double maxLoad;
  final int overloadedAgents;
  final int availableAgents;
  final Map<String, int> workloadDistribution;
  final List<AgentWorkload> agentWorkloads;

  WorkloadMetrics({
    required this.totalAgents,
    required this.activeAgents,
    required this.averageLoad,
    required this.maxLoad,
    required this.overloadedAgents,
    required this.availableAgents,
    required this.workloadDistribution,
    required this.agentWorkloads,
  });

  factory WorkloadMetrics.fromJson(Map<String, dynamic> json) =>
      _$WorkloadMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$WorkloadMetricsToJson(this);

  double get capacityUtilization => (averageLoad / maxLoad) * 100;

  bool get needsRebalancing => overloadedAgents > 0 && availableAgents > 0;
}

@JsonSerializable()
class AgentWorkload {
  final String agentId;
  final String agentName;
  final double currentLoad;
  final double maxLoad;
  final int activeTickets;
  final int queuedTickets;
  final DateTime? nextAvailableSlot;
  final List<ScheduledTask> upcomingTasks;

  AgentWorkload({
    required this.agentId,
    required this.agentName,
    required this.currentLoad,
    required this.maxLoad,
    required this.activeTickets,
    required this.queuedTickets,
    this.nextAvailableSlot,
    required this.upcomingTasks,
  });

  factory AgentWorkload.fromJson(Map<String, dynamic> json) =>
      _$AgentWorkloadFromJson(json);

  Map<String, dynamic> toJson() => _$AgentWorkloadToJson(this);

  double get utilizationPercentage => (currentLoad / maxLoad) * 100;

  bool get isOverloaded => currentLoad > maxLoad * 0.9; // 90% threshold

  String get status {
    if (isOverloaded) return 'Overloaded';
    if (utilizationPercentage > 75) return 'Heavy Load';
    if (utilizationPercentage > 50) return 'Moderate';
    return 'Available';
  }

  Color get statusColor {
    if (isOverloaded) return Colors.red;
    if (utilizationPercentage > 75) return Colors.orange;
    if (utilizationPercentage > 50) return Colors.yellow;
    return Colors.green;
  }
}

@JsonSerializable()
class ScheduledTask {
  final String taskId;
  final String title;
  final DateTime startTime;
  final double estimatedHours;
  final String priority;

  ScheduledTask({
    required this.taskId,
    required this.title,
    required this.startTime,
    required this.estimatedHours,
    required this.priority,
  });

  factory ScheduledTask.fromJson(Map<String, dynamic> json) =>
      _$ScheduledTaskFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduledTaskToJson(this);
}

@JsonSerializable()
class TeamCapacity {
  final String teamId;
  final String teamName;
  final int totalAgents;
  final int activeAgents;
  final double currentCapacity;
  final double maxCapacity;
  final List<String> skills;
  final Map<String, int> skillDistribution;

  TeamCapacity({
    required this.teamId,
    required this.teamName,
    required this.totalAgents,
    required this.activeAgents,
    required this.currentCapacity,
    required this.maxCapacity,
    required this.skills,
    required this.skillDistribution,
  });

  factory TeamCapacity.fromJson(Map<String, dynamic> json) =>
      _$TeamCapacityFromJson(json);

  Map<String, dynamic> toJson() => _$TeamCapacityToJson(this);

  double get utilizationPercentage => (currentCapacity / maxCapacity) * 100;
}
