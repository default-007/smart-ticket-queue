// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ticket _$TicketFromJson(Map<String, dynamic> json) => Ticket(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: (json['priority'] as num).toInt(),
      category: json['category'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      estimatedHours: (json['estimatedHours'] as num).toDouble(),
      assignedTo:
          Ticket._agentFromJson(json['assignedTo'] as Map<String, dynamic>?),
      createdBy: Ticket._createdByFromJson(json['createdBy']),
      department: json['department'] as String,
      requiredSkills: (json['requiredSkills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sla: Ticket._slaFromJson(json['sla'] as Map<String, dynamic>?),
      escalationLevel: (json['escalationLevel'] as num?)?.toInt() ?? 0,
      history: Ticket._historyFromJson(json['history']),
      firstResponseTime: json['firstResponseTime'] == null
          ? null
          : DateTime.parse(json['firstResponseTime'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      resolutionTime: (json['resolutionTime'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TicketToJson(Ticket instance) => <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'priority': instance.priority,
      'category': instance.category,
      'dueDate': instance.dueDate.toIso8601String(),
      'estimatedHours': instance.estimatedHours,
      'assignedTo': Ticket._agentToJson(instance.assignedTo),
      'createdBy': instance.createdBy,
      'department': instance.department,
      'requiredSkills': instance.requiredSkills,
      'sla': Ticket._slaToJson(instance.sla),
      'escalationLevel': instance.escalationLevel,
      'history': instance.history.map((e) => e.toJson()).toList(),
      'firstResponseTime': instance.firstResponseTime?.toIso8601String(),
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'resolutionTime': instance.resolutionTime,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

TicketHistory _$TicketHistoryFromJson(Map<String, dynamic> json) =>
    TicketHistory(
      action: json['action'] as String,
      performedBy: json['performedBy'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      details: json['details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TicketHistoryToJson(TicketHistory instance) =>
    <String, dynamic>{
      'action': instance.action,
      'performedBy': instance.performedBy,
      'timestamp': instance.timestamp.toIso8601String(),
      'details': instance.details,
    };
