import 'package:json_annotation/json_annotation.dart';
import 'ticket.dart';

part 'agent.g.dart';

@JsonSerializable(explicitToJson: true)
class Agent {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String email;
  final String status;
  final String? currentTicket;

  @JsonKey(defaultValue: [])
  final List<String> activeTickets;

  final AgentShift shift;

  @JsonKey(defaultValue: 5)
  final int maxTickets;

  @JsonKey(defaultValue: 0)
  final double currentLoad;

  @JsonKey(defaultValue: [])
  final List<String> skills;

  final String department;

  @JsonKey(defaultValue: [])
  final List<String> teams;

  @JsonKey(defaultValue: [])
  final List<String> specializations;

  final AgentPerformance? performance;
  final AgentAvailability? availability;

  @JsonKey(includeIfNull: false)
  final String? user;

  Agent({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.currentTicket,
    required this.activeTickets,
    required this.shift,
    required this.maxTickets,
    required this.currentLoad,
    required this.skills,
    required this.department,
    this.teams = const [],
    this.specializations = const [],
    this.performance,
    this.availability,
    this.user,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    // Make sure to handle the user field if it's missing
    if (!json.containsKey('user')) {
      json['user'] = null;
    }
    // Default shift if not present
    final shiftJson = json['shift'] ??
        {
          'start': DateTime.now().toIso8601String(),
          'end': DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
          'timezone': 'UTC',
          'breaks': []
        };

    return _$AgentFromJson({...json, 'shift': shiftJson});
  }

  Map<String, dynamic> toJson() => _$AgentToJson(this);

  bool get isOnShift {
    final now = DateTime.now();
    return now.isAfter(shift.start) && now.isBefore(shift.end);
  }

  // Create a copy of the agent with updated fields
  Agent copyWith({
    String? id,
    String? name,
    String? email,
    String? status,
    String? currentTicket,
    List<String>? activeTickets,
    AgentShift? shift,
    int? maxTickets,
    double? currentLoad,
    List<String>? skills,
    String? department,
    List<String>? teams,
    List<String>? specializations,
    AgentPerformance? performance,
    AgentAvailability? availability,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
      currentTicket: currentTicket ?? this.currentTicket,
      activeTickets: activeTickets ?? this.activeTickets,
      shift: shift ?? this.shift,
      maxTickets: maxTickets ?? this.maxTickets,
      currentLoad: currentLoad ?? this.currentLoad,
      skills: skills ?? this.skills,
      department: department ?? this.department,
      teams: teams ?? this.teams,
      specializations: specializations ?? this.specializations,
      performance: performance ?? this.performance,
      availability: availability ?? this.availability,
    );
  }
}

@JsonSerializable()
class AgentShift {
  final DateTime start;
  final DateTime end;
  final String timezone;

  @JsonKey(defaultValue: [])
  final List<AgentBreak> breaks;

  AgentShift({
    required this.start,
    required this.end,
    required this.timezone,
    required this.breaks,
  });

  factory AgentShift.fromJson(Map<String, dynamic> json) =>
      _$AgentShiftFromJson(json);

  Map<String, dynamic> toJson() => _$AgentShiftToJson(this);
}

@JsonSerializable()
class AgentBreak {
  final DateTime start;
  final DateTime end;
  final String type;

  AgentBreak({
    required this.start,
    required this.end,
    required this.type,
  });

  factory AgentBreak.fromJson(Map<String, dynamic> json) =>
      _$AgentBreakFromJson(json);

  Map<String, dynamic> toJson() => _$AgentBreakToJson(this);
}

@JsonSerializable()
class AgentPerformance {
  final double? averageResolutionTime;
  final int? ticketsResolved;
  final double? customerSatisfaction;
  final double? slaComplianceRate;

  AgentPerformance({
    this.averageResolutionTime,
    this.ticketsResolved,
    this.customerSatisfaction,
    this.slaComplianceRate,
  });

  factory AgentPerformance.fromJson(Map<String, dynamic> json) =>
      _$AgentPerformanceFromJson(json);

  Map<String, dynamic> toJson() => _$AgentPerformanceToJson(this);
}

@JsonSerializable()
class AgentAvailability {
  final DateTime? nextAvailableSlot;
  final Map<String, WorkingHours>? workingHours;

  AgentAvailability({
    this.nextAvailableSlot,
    this.workingHours,
  });

  factory AgentAvailability.fromJson(Map<String, dynamic> json) =>
      _$AgentAvailabilityFromJson(json);

  Map<String, dynamic> toJson() => _$AgentAvailabilityToJson(this);
}

@JsonSerializable()
class WorkingHours {
  final String start;
  final String end;
  final bool isWorkingDay;

  WorkingHours({
    required this.start,
    required this.end,
    required this.isWorkingDay,
  });

  factory WorkingHours.fromJson(Map<String, dynamic> json) =>
      _$WorkingHoursFromJson(json);

  Map<String, dynamic> toJson() => _$WorkingHoursToJson(this);
}
