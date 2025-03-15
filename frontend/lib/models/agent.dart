import 'package:json_annotation/json_annotation.dart';

part 'agent.g.dart';

@JsonSerializable()
class Agent {
  final String id;
  final String name;
  final String email;
  final String status;
  final String? currentTicket;
  final AgentShift shift;
  final int maxTickets;
  final double currentLoad;
  final List<String> skills;
  final String department;

  Agent({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.currentTicket,
    required this.shift,
    required this.maxTickets,
    required this.currentLoad,
    required this.skills,
    required this.department,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    try {
      final agentId = json['_id']?.toString() ?? json['id']?.toString() ?? '';

      return Agent(
        id: agentId,
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        currentTicket: json['currentTicket']?.toString(),
        shift: json['shift'] != null
            ? AgentShift.fromJson(Map<String, dynamic>.from(json['shift']))
            : AgentShift.defaultShift(),
        maxTickets: (json['maxTickets'] ?? 0) as int,
        currentLoad: (json['currentLoad'] ?? 0).toDouble(),
        skills: List<String>.from(json['skills'] ?? []),
        department: json['department']?.toString() ?? '',
      );
    } catch (e) {
      print('Agent parsing error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'status': status,
      'currentTicket': currentTicket,
      'shift': shift.toJson(),
      'maxTickets': maxTickets,
      'currentLoad': currentLoad,
      'skills': skills,
      'department': department,
    };
  }

  bool get isAvailable => status == 'online' && currentTicket == null;

  bool get isOnShift {
    final now = DateTime.now();
    return now.isAfter(shift.start) && now.isBefore(shift.end);
  }
}

@JsonSerializable()
class AgentShift {
  final DateTime start;
  final DateTime end;
  final String timezone;

  AgentShift({
    required this.start,
    required this.end,
    required this.timezone,
  });

  factory AgentShift.fromJson(Map<String, dynamic> json) {
    return AgentShift(
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      timezone: json['timezone'] ?? 'UTC',
    );
  }

  factory AgentShift.defaultShift() {
    final now = DateTime.now();
    return AgentShift(
        start: now, end: now.add(const Duration(hours: 8)), timezone: 'UTC');
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'timezone': timezone,
    };
  }
}
