import 'package:json_annotation/json_annotation.dart';
import 'agent.dart';

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
  });

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
}
