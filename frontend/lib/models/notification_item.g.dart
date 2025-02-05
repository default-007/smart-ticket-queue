// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationItem _$NotificationItemFromJson(Map<String, dynamic> json) =>
    NotificationItem(
      id: json['id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      recipient: json['recipient'] as String,
      read: json['read'] as bool,
      ticketId: json['ticketId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NotificationItemToJson(NotificationItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'message': instance.message,
      'recipient': instance.recipient,
      'read': instance.read,
      'ticketId': instance.ticketId,
      'createdAt': instance.createdAt.toIso8601String(),
      'metadata': instance.metadata,
    };
