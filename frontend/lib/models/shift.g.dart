// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Shift _$ShiftFromJson(Map<String, dynamic> json) => Shift(
      id: json['id'] as String,
      agentId: json['agentId'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      timezone: json['timezone'] as String,
      breaks: (json['breaks'] as List<dynamic>?)
              ?.map((e) => Break.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isActive: json['isActive'] as bool? ?? false,
      handoverStatus:
          $enumDecodeNullable(_$HandoverStatusEnumMap, json['handoverStatus']),
    );

Map<String, dynamic> _$ShiftToJson(Shift instance) => <String, dynamic>{
      'id': instance.id,
      'agentId': instance.agentId,
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'timezone': instance.timezone,
      'breaks': instance.breaks,
      'isActive': instance.isActive,
      'handoverStatus': _$HandoverStatusEnumMap[instance.handoverStatus],
    };

const _$HandoverStatusEnumMap = {
  HandoverStatus.pending: 'pending',
  HandoverStatus.inProgress: 'inProgress',
  HandoverStatus.completed: 'completed',
  HandoverStatus.skipped: 'skipped',
};

Break _$BreakFromJson(Map<String, dynamic> json) => Break(
      id: json['id'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      type: $enumDecode(_$BreakTypeEnumMap, json['type']),
      status: $enumDecodeNullable(_$BreakStatusEnumMap, json['status']) ??
          BreakStatus.scheduled,
    );

Map<String, dynamic> _$BreakToJson(Break instance) => <String, dynamic>{
      'id': instance.id,
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'type': _$BreakTypeEnumMap[instance.type]!,
      'status': _$BreakStatusEnumMap[instance.status]!,
    };

const _$BreakTypeEnumMap = {
  BreakType.lunch: 'lunch',
  BreakType.shortBreak: 'shortBreak',
  BreakType.training: 'training',
  BreakType.meeting: 'meeting',
};

const _$BreakStatusEnumMap = {
  BreakStatus.scheduled: 'scheduled',
  BreakStatus.inProgress: 'inProgress',
  BreakStatus.completed: 'completed',
  BreakStatus.cancelled: 'cancelled',
};

ShiftSchedule _$ShiftScheduleFromJson(Map<String, dynamic> json) =>
    ShiftSchedule(
      agentId: json['agentId'] as String,
      shifts: (json['shifts'] as List<dynamic>)
          .map((e) => Shift.fromJson(e as Map<String, dynamic>))
          .toList(),
      preferredHours: (json['preferredHours'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      availability: Map<String, bool>.from(json['availability'] as Map),
    );

Map<String, dynamic> _$ShiftScheduleToJson(ShiftSchedule instance) =>
    <String, dynamic>{
      'agentId': instance.agentId,
      'shifts': instance.shifts,
      'preferredHours': instance.preferredHours,
      'availability': instance.availability,
    };
