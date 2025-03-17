// lib/models/shift.dart
import 'package:flutter/material.dart';

enum BreakType { lunch, shortBreak, training, meeting }

enum BreakStatus { scheduled, inProgress, completed, cancelled }

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

  Duration get duration => end.difference(start);

  factory Break.fromJson(Map<String, dynamic> json) {
    return Break(
      id: json['id'] ?? '',
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      type: _parseBreakType(json['type']),
      status: _parseBreakStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
    };
  }

  Break copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    BreakType? type,
    BreakStatus? status,
  }) {
    return Break(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }

  static BreakType _parseBreakType(String? typeStr) {
    if (typeStr == null) return BreakType.shortBreak;

    switch (typeStr.toLowerCase()) {
      case 'lunch':
        return BreakType.lunch;
      case 'training':
        return BreakType.training;
      case 'meeting':
        return BreakType.meeting;
      case 'shortbreak':
      case 'short_break':
      default:
        return BreakType.shortBreak;
    }
  }

  static BreakStatus _parseBreakStatus(String? statusStr) {
    if (statusStr == null) return BreakStatus.scheduled;

    switch (statusStr.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
      case 'in-progress':
        return BreakStatus.inProgress;
      case 'completed':
        return BreakStatus.completed;
      case 'cancelled':
      case 'canceled':
        return BreakStatus.cancelled;
      case 'scheduled':
      default:
        return BreakStatus.scheduled;
    }
  }
}

class Shift {
  final String id;
  final DateTime start;
  final DateTime end;
  final String timezone;
  final String status;
  final List<Break> breaks;

  Shift({
    required this.id,
    required this.start,
    required this.end,
    this.timezone = 'UTC',
    this.status = 'in-progress',
    this.breaks = const [],
  });

  Duration get duration => end.difference(start);

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(end)) return Duration.zero;
    if (now.isBefore(start)) return duration;
    return end.difference(now);
  }

  bool get isInProgress {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end) && status == 'in-progress';
  }

  // Find current break if any
  Break? get currentBreak {
    final now = DateTime.now();
    return breaks.firstWhere(
      (breakItem) =>
          breakItem.status == BreakStatus.inProgress &&
          now.isAfter(breakItem.start) &&
          now.isBefore(breakItem.end),
      orElse: () => null as Break,
    );
  }

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] ?? '',
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      timezone: json['timezone'] ?? 'UTC',
      status: json['status'] ?? 'in-progress',
      breaks: (json['breaks'] as List?)
              ?.map((breakJson) => Break.fromJson(breakJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'timezone': timezone,
      'status': status,
      'breaks': breaks.map((breakItem) => breakItem.toJson()).toList(),
    };
  }

  Shift copyWith({
    String? id,
    DateTime? start,
    DateTime? end,
    String? timezone,
    String? status,
    List<Break>? breaks,
  }) {
    return Shift(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      timezone: timezone ?? this.timezone,
      status: status ?? this.status,
      breaks: breaks ?? this.breaks,
    );
  }
}
