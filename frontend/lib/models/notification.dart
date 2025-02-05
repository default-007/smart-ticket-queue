import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class Notification {
  final String id;
  final String type;
  final String message;
  final String recipient;
  final bool read;
  final String? ticketId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  Notification({
    required this.id,
    required this.type,
    required this.message,
    required this.recipient,
    required this.read,
    this.ticketId,
    required this.createdAt,
    this.metadata,
  });

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationToJson(this);

  NotificationType get notificationType =>
      NotificationTypeExtension.fromString(type);

  String get typeIcon {
    switch (notificationType) {
      case NotificationType.ticketAssigned:
        return 'assignment';
      case NotificationType.slaBreached:
        return 'warning';
      case NotificationType.escalation:
        return 'arrow_upward';
      case NotificationType.shiftEnding:
        return 'access_time';
      case NotificationType.handover:
        return 'swap_horiz';
      case NotificationType.breakReminder:
        return 'coffee';
      default:
        return 'notifications';
    }
  }

  Color get typeColor {
    switch (notificationType) {
      case NotificationType.ticketAssigned:
        return Colors.blue;
      case NotificationType.slaBreached:
        return Colors.red;
      case NotificationType.escalation:
        return Colors.orange;
      case NotificationType.shiftEnding:
        return Colors.purple;
      case NotificationType.handover:
        return Colors.green;
      case NotificationType.breakReminder:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

enum NotificationType {
  ticketAssigned,
  slaBreached,
  escalation,
  shiftEnding,
  handover,
  breakReminder,
  other
}

extension NotificationTypeExtension on NotificationType {
  static NotificationType fromString(String type) {
    switch (type) {
      case 'ticket_assigned':
        return NotificationType.ticketAssigned;
      case 'sla_breach':
        return NotificationType.slaBreached;
      case 'escalation':
        return NotificationType.escalation;
      case 'shift_ending':
        return NotificationType.shiftEnding;
      case 'handover':
        return NotificationType.handover;
      case 'break_reminder':
        return NotificationType.breakReminder;
      default:
        return NotificationType.other;
    }
  }
}
