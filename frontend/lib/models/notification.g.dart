// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
      id: json['id'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      recipient: json['recipient'] as String,
      read: json['read'] as bool,
      ticketId: json['ticketId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
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
