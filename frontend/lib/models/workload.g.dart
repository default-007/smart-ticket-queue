// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkloadMetrics _$WorkloadMetricsFromJson(Map<String, dynamic> json) =>
    WorkloadMetrics(
      totalAgents: (json['totalAgents'] as num).toInt(),
      activeAgents: (json['activeAgents'] as num).toInt(),
      averageLoad: (json['averageLoad'] as num).toDouble(),
      maxLoad: (json['maxLoad'] as num).toDouble(),
      overloadedAgents: (json['overloadedAgents'] as num).toInt(),
      availableAgents: (json['availableAgents'] as num).toInt(),
      workloadDistribution:
          Map<String, int>.from(json['workloadDistribution'] as Map),
      agentWorkloads: (json['agentWorkloads'] as List<dynamic>)
          .map((e) => AgentWorkload.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WorkloadMetricsToJson(WorkloadMetrics instance) =>
    <String, dynamic>{
      'totalAgents': instance.totalAgents,
      'activeAgents': instance.activeAgents,
      'averageLoad': instance.averageLoad,
      'maxLoad': instance.maxLoad,
      'overloadedAgents': instance.overloadedAgents,
      'availableAgents': instance.availableAgents,
      'workloadDistribution': instance.workloadDistribution,
      'agentWorkloads': instance.agentWorkloads,
    };

AgentWorkload _$AgentWorkloadFromJson(Map<String, dynamic> json) =>
    AgentWorkload(
      agentId: json['agentId'] as String,
      agentName: json['agentName'] as String,
      currentLoad: (json['currentLoad'] as num).toDouble(),
      maxLoad: (json['maxLoad'] as num).toDouble(),
      activeTickets: (json['activeTickets'] as num).toInt(),
      queuedTickets: (json['queuedTickets'] as num).toInt(),
      nextAvailableSlot: json['nextAvailableSlot'] == null
          ? null
          : DateTime.parse(json['nextAvailableSlot'] as String),
      upcomingTasks: (json['upcomingTasks'] as List<dynamic>)
          .map((e) => ScheduledTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AgentWorkloadToJson(AgentWorkload instance) =>
    <String, dynamic>{
      'agentId': instance.agentId,
      'agentName': instance.agentName,
      'currentLoad': instance.currentLoad,
      'maxLoad': instance.maxLoad,
      'activeTickets': instance.activeTickets,
      'queuedTickets': instance.queuedTickets,
      'nextAvailableSlot': instance.nextAvailableSlot?.toIso8601String(),
      'upcomingTasks': instance.upcomingTasks,
    };

ScheduledTask _$ScheduledTaskFromJson(Map<String, dynamic> json) =>
    ScheduledTask(
      taskId: json['taskId'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      estimatedHours: (json['estimatedHours'] as num).toDouble(),
      priority: json['priority'] as String,
    );

Map<String, dynamic> _$ScheduledTaskToJson(ScheduledTask instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'title': instance.title,
      'startTime': instance.startTime.toIso8601String(),
      'estimatedHours': instance.estimatedHours,
      'priority': instance.priority,
    };

TeamCapacity _$TeamCapacityFromJson(Map<String, dynamic> json) => TeamCapacity(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      totalAgents: (json['totalAgents'] as num).toInt(),
      activeAgents: (json['activeAgents'] as num).toInt(),
      currentCapacity: (json['currentCapacity'] as num).toDouble(),
      maxCapacity: (json['maxCapacity'] as num).toDouble(),
      skills:
          (json['skills'] as List<dynamic>).map((e) => e as String).toList(),
      skillDistribution:
          Map<String, int>.from(json['skillDistribution'] as Map),
    );

Map<String, dynamic> _$TeamCapacityToJson(TeamCapacity instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'teamName': instance.teamName,
      'totalAgents': instance.totalAgents,
      'activeAgents': instance.activeAgents,
      'currentCapacity': instance.currentCapacity,
      'maxCapacity': instance.maxCapacity,
      'skills': instance.skills,
      'skillDistribution': instance.skillDistribution,
    };
