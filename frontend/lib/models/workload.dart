import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

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

  WorkloadMetrics({
    required this.totalAgents,
    required this.activeAgents,
    required this.averageLoad,
    required this.maxLoad,
    required this.overloadedAgents,
    required this.availableAgents,
    required this.workloadDistribution,
  });

  factory WorkloadMetrics.fromJson(Map<String, dynamic> json) {
    // Handle potential null values or invalid data format
    try {
      return WorkloadMetrics(
        totalAgents: json['totalAgents'] as int? ?? 0,
        activeAgents: json['activeAgents'] as int? ?? 0,
        averageLoad: (json['averageLoad'] as num?)?.toDouble() ?? 0.0,
        maxLoad: (json['maxLoad'] as num?)?.toDouble() ?? 8.0,
        overloadedAgents: json['overloadedAgents'] as int? ?? 0,
        availableAgents: json['availableAgents'] as int? ?? 0,
        workloadDistribution:
            _parseWorkloadDistribution(json['workloadDistribution']),
      );
    } catch (e) {
      print('Error parsing WorkloadMetrics: $e');
      // Return default values on parse error
      return WorkloadMetrics(
        totalAgents: 0,
        activeAgents: 0,
        averageLoad: 0.0,
        maxLoad: 8.0,
        overloadedAgents: 0,
        availableAgents: 0,
        workloadDistribution: {
          'low': 0,
          'moderate': 0,
          'high': 0,
          'overloaded': 0
        },
      );
    }
  }

  static Map<String, int> _parseWorkloadDistribution(dynamic distribution) {
    if (distribution == null) {
      return {'low': 0, 'moderate': 0, 'high': 0, 'overloaded': 0};
    }

    if (distribution is Map) {
      try {
        return Map<String, int>.from(distribution);
      } catch (e) {
        print('Error parsing workload distribution: $e');
      }
    }

    return {'low': 0, 'moderate': 0, 'high': 0, 'overloaded': 0};
  }

  Map<String, dynamic> toJson() => _$WorkloadMetricsToJson(this);

  double get capacityUtilization =>
      maxLoad > 0 ? (averageLoad / maxLoad) * 100 : 0;

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

  factory AgentWorkload.fromJson(Map<String, dynamic> json) {
    try {
      return AgentWorkload(
        agentId: json['agentId'] as String? ?? '',
        agentName: json['agentName'] as String? ?? 'Unknown',
        currentLoad: (json['currentLoad'] as num?)?.toDouble() ?? 0.0,
        maxLoad: (json['maxLoad'] as num?)?.toDouble() ?? 8.0,
        activeTickets: json['activeTickets'] as int? ?? 0,
        queuedTickets: json['queuedTickets'] as int? ?? 0,
        nextAvailableSlot: json['nextAvailableSlot'] != null
            ? DateTime.parse(json['nextAvailableSlot'] as String)
            : null,
        upcomingTasks: _parseUpcomingTasks(json['upcomingTasks']),
      );
    } catch (e) {
      print('Error parsing AgentWorkload: $e');
      // Return default values on parse error
      return AgentWorkload(
        agentId: '',
        agentName: 'Error parsing agent',
        currentLoad: 0.0,
        maxLoad: 8.0,
        activeTickets: 0,
        queuedTickets: 0,
        upcomingTasks: [],
      );
    }
  }

  static List<ScheduledTask> _parseUpcomingTasks(dynamic tasks) {
    if (tasks == null || tasks is! List) {
      return [];
    }

    try {
      return tasks
          .map((task) => ScheduledTask.fromJson(task as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error parsing upcoming tasks: $e');
      return [];
    }
  }

  Map<String, dynamic> toJson() => _$AgentWorkloadToJson(this);

  double get utilizationPercentage =>
      maxLoad > 0 ? (currentLoad / maxLoad) * 100 : 0;

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

  factory ScheduledTask.fromJson(Map<String, dynamic> json) {
    try {
      return ScheduledTask(
        taskId: json['taskId'] as String? ?? json['_id'] as String? ?? '',
        title: json['title'] as String? ?? 'Unknown Task',
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'] as String)
            : DateTime.now(),
        estimatedHours: (json['estimatedHours'] as num?)?.toDouble() ?? 1.0,
        priority: json['priority'] as String? ?? 'medium',
      );
    } catch (e) {
      print('Error parsing ScheduledTask: $e');
      // Return default values on parse error
      return ScheduledTask(
        taskId: '',
        title: 'Error parsing task',
        startTime: DateTime.now(),
        estimatedHours: 1.0,
        priority: 'medium',
      );
    }
  }

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

  factory TeamCapacity.fromJson(Map<String, dynamic> json) {
    try {
      return TeamCapacity(
        teamId: json['teamId'] as String? ?? '',
        teamName: json['teamName'] as String? ?? 'Unknown Team',
        totalAgents: json['totalAgents'] as int? ?? 0,
        activeAgents: json['activeAgents'] as int? ?? 0,
        currentCapacity: (json['currentCapacity'] as num?)?.toDouble() ?? 0.0,
        maxCapacity: (json['maxCapacity'] as num?)?.toDouble() ?? 0.0,
        skills: _parseSkills(json['skills']),
        skillDistribution: _parseSkillDistribution(json['skillDistribution']),
      );
    } catch (e) {
      print('Error parsing TeamCapacity: $e');
      // Return default values on parse error
      return TeamCapacity(
        teamId: '',
        teamName: 'Error parsing team',
        totalAgents: 0,
        activeAgents: 0,
        currentCapacity: 0.0,
        maxCapacity: 0.0,
        skills: [],
        skillDistribution: {},
      );
    }
  }

  static List<String> _parseSkills(dynamic skills) {
    if (skills == null || skills is! List) {
      return [];
    }

    try {
      return List<String>.from(skills);
    } catch (e) {
      print('Error parsing skills: $e');
      return [];
    }
  }

  static Map<String, int> _parseSkillDistribution(dynamic distribution) {
    if (distribution == null || distribution is! Map) {
      return {};
    }

    try {
      return Map<String, int>.from(distribution);
    } catch (e) {
      print('Error parsing skill distribution: $e');
      return {};
    }
  }

  Map<String, dynamic> toJson() => _$TeamCapacityToJson(this);

  double get utilizationPercentage =>
      maxCapacity > 0 ? (currentCapacity / maxCapacity) * 100 : 0;
}
