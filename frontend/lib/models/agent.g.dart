// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      currentTicket: json['currentTicket'] as String?,
      activeTickets: (json['activeTickets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      shift: AgentShift.fromJson(json['shift'] as Map<String, dynamic>),
      maxTickets: (json['maxTickets'] as num?)?.toInt() ?? 5,
      currentLoad: (json['currentLoad'] as num?)?.toDouble() ?? 0,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      department: json['department'] as String,
      teams:
          (json['teams'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      specializations: (json['specializations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      performance: json['performance'] == null
          ? null
          : AgentPerformance.fromJson(
              json['performance'] as Map<String, dynamic>),
      availability: json['availability'] == null
          ? null
          : AgentAvailability.fromJson(
              json['availability'] as Map<String, dynamic>),
      user: json['user'] as String?,
    );

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'status': instance.status,
      'currentTicket': instance.currentTicket,
      'activeTickets': instance.activeTickets,
      'shift': instance.shift.toJson(),
      'maxTickets': instance.maxTickets,
      'currentLoad': instance.currentLoad,
      'skills': instance.skills,
      'department': instance.department,
      'teams': instance.teams,
      'specializations': instance.specializations,
      'performance': instance.performance?.toJson(),
      'availability': instance.availability?.toJson(),
      if (instance.user case final value?) 'user': value,
    };

AgentShift _$AgentShiftFromJson(Map<String, dynamic> json) => AgentShift(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      timezone: json['timezone'] as String,
      breaks: (json['breaks'] as List<dynamic>?)
              ?.map((e) => AgentBreak.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$AgentShiftToJson(AgentShift instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'timezone': instance.timezone,
      'breaks': instance.breaks,
    };

AgentBreak _$AgentBreakFromJson(Map<String, dynamic> json) => AgentBreak(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      type: json['type'] as String,
    );

Map<String, dynamic> _$AgentBreakToJson(AgentBreak instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'type': instance.type,
    };

AgentPerformance _$AgentPerformanceFromJson(Map<String, dynamic> json) =>
    AgentPerformance(
      averageResolutionTime:
          (json['averageResolutionTime'] as num?)?.toDouble(),
      ticketsResolved: (json['ticketsResolved'] as num?)?.toInt(),
      customerSatisfaction: (json['customerSatisfaction'] as num?)?.toDouble(),
      slaComplianceRate: (json['slaComplianceRate'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AgentPerformanceToJson(AgentPerformance instance) =>
    <String, dynamic>{
      'averageResolutionTime': instance.averageResolutionTime,
      'ticketsResolved': instance.ticketsResolved,
      'customerSatisfaction': instance.customerSatisfaction,
      'slaComplianceRate': instance.slaComplianceRate,
    };

AgentAvailability _$AgentAvailabilityFromJson(Map<String, dynamic> json) =>
    AgentAvailability(
      nextAvailableSlot: json['nextAvailableSlot'] == null
          ? null
          : DateTime.parse(json['nextAvailableSlot'] as String),
      workingHours: (json['workingHours'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, WorkingHours.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$AgentAvailabilityToJson(AgentAvailability instance) =>
    <String, dynamic>{
      'nextAvailableSlot': instance.nextAvailableSlot?.toIso8601String(),
      'workingHours': instance.workingHours,
    };

WorkingHours _$WorkingHoursFromJson(Map<String, dynamic> json) => WorkingHours(
      start: json['start'] as String,
      end: json['end'] as String,
      isWorkingDay: json['isWorkingDay'] as bool,
    );

Map<String, dynamic> _$WorkingHoursToJson(WorkingHours instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'isWorkingDay': instance.isWorkingDay,
    };
