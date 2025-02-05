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
  final Agent? assignedTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TicketSLA? sla; // Add SLA field
  final String department;
  final List<String>? requiredSkills;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.estimatedHours,
    this.assignedTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.sla,
    required this.department,
    this.requiredSkills,
  });

  /* factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
  Map<String, dynamic> toJson() => _$TicketToJson(this); */
  factory Ticket.fromJson(Map<String, dynamic> json) => _$TicketFromJson(json);
  Map<String, dynamic> toJson() => _$TicketToJson(this);

  bool get isOverdue => DateTime.now().isAfter(dueDate);

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
