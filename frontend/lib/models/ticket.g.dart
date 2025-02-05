// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ticket _$TicketFromJson(Map<String, dynamic> json) => Ticket(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: (json['priority'] as num).toInt(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      estimatedHours: (json['estimatedHours'] as num).toDouble(),
      assignedTo: json['assignedTo'] == null
          ? null
          : Agent.fromJson(json['assignedTo'] as Map<String, dynamic>),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sla: json['sla'] == null
          ? null
          : TicketSLA.fromJson(json['sla'] as Map<String, dynamic>),
      department: json['department'] as String,
      requiredSkills: (json['requiredSkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TicketToJson(Ticket instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'priority': instance.priority,
      'dueDate': instance.dueDate.toIso8601String(),
      'estimatedHours': instance.estimatedHours,
      'assignedTo': instance.assignedTo,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'sla': instance.sla,
      'department': instance.department,
      'requiredSkills': instance.requiredSkills,
    };
