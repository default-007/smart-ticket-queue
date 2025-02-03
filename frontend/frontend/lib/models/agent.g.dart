// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      currentTicket: json['currentTicket'] as String?,
      shift: AgentShift.fromJson(json['shift'] as Map<String, dynamic>),
      maxTickets: (json['maxTickets'] as num).toInt(),
      currentLoad: (json['currentLoad'] as num).toDouble(),
      skills:
          (json['skills'] as List<dynamic>).map((e) => e as String).toList(),
      department: json['department'] as String,
    );

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'status': instance.status,
      'currentTicket': instance.currentTicket,
      'shift': instance.shift,
      'maxTickets': instance.maxTickets,
      'currentLoad': instance.currentLoad,
      'skills': instance.skills,
      'department': instance.department,
    };

AgentShift _$AgentShiftFromJson(Map<String, dynamic> json) => AgentShift(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      timezone: json['timezone'] as String,
    );

Map<String, dynamic> _$AgentShiftToJson(AgentShift instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'timezone': instance.timezone,
    };
