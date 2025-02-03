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

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);
  Map<String, dynamic> toJson() => _$AgentToJson(this);

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

  factory AgentShift.fromJson(Map<String, dynamic> json) =>
      _$AgentShiftFromJson(json);
  Map<String, dynamic> toJson() => _$AgentShiftToJson(this);
}
