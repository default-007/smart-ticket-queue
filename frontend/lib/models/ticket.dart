import 'package:json_annotation/json_annotation.dart';
import 'agent.dart';
import 'sla.dart';

part 'ticket.g.dart';

@JsonSerializable()
class Ticket {
  final String id;
  final String title;
  final String description;
  final String status;
  final int priority;
  final DateTime dueDate;
  final double estimatedHours;
  final Agent? assignedTo; // Note the nullable type
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TicketSLA? sla;
  final String department;
  final List<String>? requiredSkills;
  final int escalationLevel;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.estimatedHours,
    this.assignedTo, // Properly marked as optional
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.sla,
    required this.department,
    this.requiredSkills,
    this.escalationLevel = 0,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as int,
      dueDate: DateTime.parse(json['dueDate'] as String),
      estimatedHours: (json['estimatedHours'] as num).toDouble(),
      // Handle assignedTo as it might be null or an object
      assignedTo: json['assignedTo'] != null
          ? (json['assignedTo'] is String
              ? null // Handle string ID case, likely no agent details available
              : Agent.fromJson(json['assignedTo'] as Map<String, dynamic>))
          : null,
      // Handle createdBy which comes as an object
      createdBy: json['createdBy'] is String
          ? json['createdBy'] as String
          : (json['createdBy'] as Map<String, dynamic>)['_id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      // Handle nullable SLA field
      sla: json['sla'] != null
          ? TicketSLA.fromJson(json['sla'] as Map<String, dynamic>)
          : null,
      department: json['department'] as String,
      // Handle nullable requiredSkills
      requiredSkills: json['requiredSkills'] != null
          ? List<String>.from(json['requiredSkills'] as List)
          : null,
      escalationLevel: json['escalationLevel'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => _$TicketToJson(this);

  bool get isOverdue => DateTime.now().isAfter(dueDate);
  bool get isEscalated => escalationLevel > 0 || status == 'escalated';

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

  String get statusDisplay {
    return status
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Add method to get escalation status text
  String get escalationStatusText {
    if (!isEscalated) return 'Not Escalated';
    return 'Level $escalationLevel Escalation';
  }

  // Add a method to check SLA status
  bool get isSLABreached {
    return sla?.isBreached ?? false;
  }

  // Add a method to get time until next SLA breach
  Duration? get timeUntilSLABreach {
    if (sla == null) return null;

    final responseTime = sla!.timeUntilResponseBreach;
    final resolutionTime = sla!.timeUntilResolutionBreach;

    if (responseTime != null && resolutionTime != null) {
      return responseTime < resolutionTime ? responseTime : resolutionTime;
    }
    return responseTime ?? resolutionTime;
  }
}
