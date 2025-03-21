import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:smart_ticketing/services/notification_item.dart';

part 'notification_item.g.dart';

@JsonSerializable()
class NotificationItem {
  final String id;
  final String type;
  final String message;
  final String recipient;
  final bool read;
  final String? ticketId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    required this.recipient,
    required this.read,
    this.ticketId,
    required this.createdAt,
    this.metadata,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    try {
      // Handle MongoDB _id field
      final notificationId =
          json['_id']?.toString() ?? json['id']?.toString() ?? '';

      return NotificationItem(
        id: notificationId,
        type: json['type'] as String,
        message: json['message'] as String,
        recipient: json['recipient'] as String,
        read: json['read'] as bool,
        ticketId: json['ticketId'] as String?, // Handle properly as nullable
        createdAt: DateTime.parse(json['createdAt'] as String),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error parsing NotificationItem: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => _$NotificationItemToJson(this);

  NotificationItemType get notificationType =>
      NotificationItemTypeExtension.fromString(type);

  String get typeIcon {
    switch (notificationType) {
      case NotificationItemType.ticketAssigned:
        return 'assignment';
      case NotificationItemType.slaBreached:
        return 'warning';
      case NotificationItemType.escalation:
        return 'arrow_upward';
      case NotificationItemType.shiftEnding:
        return 'access_time';
      case NotificationItemType.handover:
        return 'swap_horiz';
      case NotificationItemType.breakReminder:
        return 'coffee';
      default:
        return 'notifications';
    }
  }

  Color get typeColor {
    switch (notificationType) {
      case NotificationItemType.ticketAssigned:
        return Colors.blue;
      case NotificationItemType.slaBreached:
        return Colors.red;
      case NotificationItemType.escalation:
        return Colors.orange;
      case NotificationItemType.shiftEnding:
        return Colors.purple;
      case NotificationItemType.handover:
        return Colors.green;
      case NotificationItemType.breakReminder:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color getPriorityColor() {
    if (metadata == null || !metadata!.containsKey('priority'))
      return Colors.grey;

    switch (metadata!['priority']) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  int? getMinutesRemaining() {
    if (metadata == null || !metadata!.containsKey('minutesRemaining'))
      return null;
    return metadata!['minutesRemaining'] as int?;
  }
}
