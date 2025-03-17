// lib/models/ticket.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';
import 'agent.dart';
import 'sla.dart';

part 'ticket.g.dart';

@JsonSerializable(explicitToJson: true)
class Ticket {
  @JsonKey(name: '_id') // Map MongoDB _id to id
  final String id;
  final String title;
  final String description;
  final String status;
  final int priority;
  final String category;
  final DateTime dueDate;
  final double estimatedHours;

  @JsonKey(fromJson: _agentFromJson, toJson: _agentToJson)
  final Agent? assignedTo; // Agent who the ticket is assigned to

  @JsonKey(name: 'createdBy', fromJson: _createdByFromJson)
  final String createdBy;

  final String department;

  @JsonKey(defaultValue: [])
  final List<String> requiredSkills;

  @JsonKey(fromJson: _slaFromJson, toJson: _slaToJson)
  final TicketSLA? sla;

  @JsonKey(defaultValue: 0)
  final int escalationLevel;

  @JsonKey(fromJson: _historyFromJson)
  final List<TicketHistory> history;

  final DateTime? firstResponseTime;
  final DateTime? resolvedAt;
  final int? resolutionTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.dueDate,
    required this.estimatedHours,
    this.assignedTo,
    required this.createdBy,
    required this.department,
    required this.requiredSkills,
    this.sla,
    this.escalationLevel = 0,
    required this.history,
    this.firstResponseTime,
    this.resolvedAt,
    this.resolutionTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Copy json map to avoid modifying the original
    final jsonCopy = Map<String, dynamic>.from(json);

    // Handle _id if exists
    if (jsonCopy.containsKey('_id') && !jsonCopy.containsKey('id')) {
      jsonCopy['id'] = jsonCopy['_id'];
    }

    try {
      return _$TicketFromJson(jsonCopy);
    } catch (e) {
      print('Error in Ticket.fromJson: $e');
      throw e;
    }
  }

  Map<String, dynamic> toJson() => _$TicketToJson(this);

  // Custom JSON conversion methods for Agent
  static Agent? _agentFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return Agent.fromJson(json);
    } catch (e) {
      print('Error parsing Agent: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _agentToJson(Agent? agent) => agent?.toJson();

  // Parsing createdBy which could be a string ID or an object with _id
  static String _createdByFromJson(dynamic createdBy) {
    if (createdBy is String) {
      return createdBy;
    } else if (createdBy is Map<String, dynamic> &&
        createdBy.containsKey('_id')) {
      return createdBy['_id'].toString();
    }
    throw Exception('Invalid createdBy format: $createdBy');
  }

  // Custom JSON conversion methods for SLA
  static TicketSLA? _slaFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      return TicketSLA.fromJson(json);
    } catch (e) {
      print('Error parsing SLA: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _slaToJson(TicketSLA? sla) => sla?.toJson();

  // Handle history parsing
  static List<TicketHistory> _historyFromJson(dynamic history) {
    if (history is! List) return [];

    return history.map((item) {
      try {
        if (item is Map<String, dynamic>) {
          return TicketHistory.fromJson(item);
        }
        throw Exception('History item is not a Map: $item');
      } catch (e) {
        print('Error parsing history item: $e');
        // Return a placeholder history item
        return TicketHistory(
          action: 'error',
          timestamp: DateTime.now(),
        );
      }
    }).toList();
  }

  // Getters for derived properties
  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) &&
      status != 'resolved' &&
      status != 'closed';

  bool get isEscalated => escalationLevel > 0 || status == 'escalated';

  // New getter to fix the missing isSLABreached property
  bool get isSLABreached => sla?.isBreached ?? false;

  String get statusDisplay => status
      .split('-')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  String get priorityText {
    switch (priority) {
      case 1:
        return 'High';
      case 2:
        return 'Medium';
      case 3:
        return 'Low';
      default:
        return 'Unknown';
    }
  }

  // Create a copy of the ticket with updated fields
  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    int? priority,
    String? category,
    DateTime? dueDate,
    double? estimatedHours,
    Agent? assignedTo,
    String? createdBy,
    String? department,
    List<String>? requiredSkills,
    TicketSLA? sla,
    int? escalationLevel,
    List<TicketHistory>? history,
    DateTime? firstResponseTime,
    DateTime? resolvedAt,
    int? resolutionTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      department: department ?? this.department,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      sla: sla ?? this.sla,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      history: history ?? this.history,
      firstResponseTime: firstResponseTime ?? this.firstResponseTime,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionTime: resolutionTime ?? this.resolutionTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class TicketHistory {
  final String action;
  final String? performedBy;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  TicketHistory({
    required this.action,
    this.performedBy,
    required this.timestamp,
    this.details,
  });

  factory TicketHistory.fromJson(Map<String, dynamic> json) {
    try {
      // Create a copy of the map to avoid modifying the original
      final jsonCopy = Map<String, dynamic>.from(json);

      // Handle MongoDB _id
      if (jsonCopy.containsKey('_id') && !jsonCopy.containsKey('id')) {
        jsonCopy['id'] = jsonCopy['_id'];
      }

      // Map the timestamp if it's missing
      if (!jsonCopy.containsKey('timestamp') && jsonCopy.containsKey('date')) {
        jsonCopy['timestamp'] = jsonCopy['date'];
      }

      return _$TicketHistoryFromJson(jsonCopy);
    } catch (e) {
      print('Error in TicketHistory.fromJson: $e');
      return TicketHistory(
        action: 'error',
        timestamp: DateTime.now(),
        details: {'error': e.toString()},
      );
    }
  }

  Map<String, dynamic> toJson() => _$TicketHistoryToJson(this);
}
