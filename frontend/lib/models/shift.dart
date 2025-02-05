// lib/models/shift.dart
import 'package:json_annotation/json_annotation.dart';

part 'shift.g.dart';

@JsonSerializable()
class Shift {
  final String id;
  final String agentId;
  final DateTime start;
  final DateTime end;
  final String timezone;
  final List<Break> breaks;
  final bool isActive;
  final HandoverStatus? handoverStatus;

  Shift({
    required this.id,
    required this.agentId,
    required this.start,
    required this.end,
    required this.timezone,
    this.breaks = const [],
    this.isActive = false,
    this.handoverStatus,
  });

  factory Shift.fromJson(Map<String, dynamic> json) => _$ShiftFromJson(json);
  Map<String, dynamic> toJson() => _$ShiftToJson(this);

  bool get isInProgress {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  Duration get remainingTime {
    final now = DateTime.now();
    return end.difference(now);
  }

  Break? get currentBreak {
    final now = DateTime.now();
    try {
      return breaks.firstWhere(
        (b) => now.isAfter(b.start) && now.isBefore(b.end),
      );
    } catch (e) {
      return null;
    }
  }

  bool get needsHandover {
    final remaining = remainingTime.inMinutes;
    return remaining > 0 && remaining <= 30 && handoverStatus == null;
  }
}

@JsonSerializable()
class Break {
  final String id;
  final DateTime start;
  final DateTime end;
  final BreakType type;
  final BreakStatus status;

  Break({
    required this.id,
    required this.start,
    required this.end,
    required this.type,
    this.status = BreakStatus.scheduled,
  });

  factory Break.fromJson(Map<String, dynamic> json) => _$BreakFromJson(json);
  Map<String, dynamic> toJson() => _$BreakToJson(this);

  Duration get duration => end.difference(start);
}

enum BreakType { lunch, shortBreak, training, meeting }

enum BreakStatus { scheduled, inProgress, completed, cancelled }

enum HandoverStatus { pending, inProgress, completed, skipped }

@JsonSerializable()
class ShiftSchedule {
  final String agentId;
  final List<Shift> shifts;
  final Map<String, List<String>> preferredHours;
  final Map<String, bool> availability;

  ShiftSchedule({
    required this.agentId,
    required this.shifts,
    required this.preferredHours,
    required this.availability,
  });

  factory ShiftSchedule.fromJson(Map<String, dynamic> json) =>
      _$ShiftScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$ShiftScheduleToJson(this);
}
