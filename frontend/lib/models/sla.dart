import 'package:json_annotation/json_annotation.dart';

part 'sla.g.dart';

@JsonSerializable()
class TicketSLA {
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? responseDeadline;

  final bool? responseTimeMet;

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? resolutionDeadline;

  final bool? resolutionTimeMet;

  final bool isBreached;

  TicketSLA({
    this.responseDeadline,
    this.responseTimeMet,
    this.resolutionDeadline,
    this.resolutionTimeMet,
    this.isBreached = false,
  });

  factory TicketSLA.fromJson(Map<String, dynamic> json) =>
      _$TicketSLAFromJson(json);
  Map<String, dynamic> toJson() => _$TicketSLAToJson(this);

  // Custom JSON conversion for DateTime
  static DateTime? _dateTimeFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.parse(value);
    return null;
  }

  static String? _dateTimeToJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }

  // Calculate time until SLA response breach
  Duration? get timeUntilResponseBreach {
    if (responseTimeMet == true || responseDeadline == null) return null;

    final now = DateTime.now();
    if (now.isAfter(responseDeadline!)) return Duration.zero;

    return responseDeadline!.difference(now);
  }

  // Calculate time until SLA resolution breach
  Duration? get timeUntilResolutionBreach {
    if (resolutionTimeMet == true || resolutionDeadline == null) return null;

    final now = DateTime.now();
    if (now.isAfter(resolutionDeadline!)) return Duration.zero;

    return resolutionDeadline!.difference(now);
  }

  // Format time until breach for display
  String getFormattedTimeUntilBreach() {
    final responseTime = timeUntilResponseBreach;
    final resolutionTime = timeUntilResolutionBreach;

    if (isBreached) return 'Breached';

    if (responseTime != null && !responseTimeMet!) {
      if (responseTime.inMinutes <= 0) return 'Response Overdue';
      if (responseTime.inMinutes < 60)
        return '${responseTime.inMinutes}m to resp';
      return '${responseTime.inHours}h to resp';
    }

    if (resolutionTime != null && !resolutionTimeMet!) {
      if (resolutionTime.inMinutes <= 0) return 'Resolution Overdue';
      if (resolutionTime.inMinutes < 60)
        return '${resolutionTime.inMinutes}m to resolve';
      return '${resolutionTime.inHours}h to resolve';
    }

    return 'On Track';
  }
}

@JsonSerializable()
class SLAConfig {
  final int priority;
  final String category;
  final int responseTime;
  final int resolutionTime;
  final List<SLAEscalationRule> escalationRules;

  SLAConfig({
    required this.priority,
    required this.category,
    required this.responseTime,
    required this.resolutionTime,
    required this.escalationRules,
  });

  factory SLAConfig.fromJson(Map<String, dynamic> json) =>
      _$SLAConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SLAConfigToJson(this);
}

@JsonSerializable()
class SLAEscalationRule {
  final int level;
  final int threshold;
  final List<String> notifyRoles;

  SLAEscalationRule({
    required this.level,
    required this.threshold,
    required this.notifyRoles,
  });

  factory SLAEscalationRule.fromJson(Map<String, dynamic> json) =>
      _$SLAEscalationRuleFromJson(json);

  Map<String, dynamic> toJson() => _$SLAEscalationRuleToJson(this);
}

@JsonSerializable()
class SLAMetrics {
  final int totalTickets;
  final int responseSLABreaches;
  final int resolutionSLABreaches;
  final double? averageResponseTime;
  final double? averageResolutionTime;
  final double slaComplianceRate;

  SLAMetrics({
    required this.totalTickets,
    required this.responseSLABreaches,
    required this.resolutionSLABreaches,
    this.averageResponseTime,
    this.averageResolutionTime,
    required this.slaComplianceRate,
  });

  factory SLAMetrics.fromJson(Map<String, dynamic> json) =>
      _$SLAMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$SLAMetricsToJson(this);

  String get complianceRateFormatted =>
      '${slaComplianceRate.toStringAsFixed(1)}%';

  String get averageResponseTimeFormatted {
    if (averageResponseTime == null) return 'N/A';
    return '${averageResponseTime!.toStringAsFixed(0)} min';
  }

  String get averageResolutionTimeFormatted {
    if (averageResolutionTime == null) return 'N/A';

    if (averageResolutionTime! < 60) {
      return '${averageResolutionTime!.toStringAsFixed(0)} min';
    } else {
      final hours = (averageResolutionTime! / 60).toStringAsFixed(1);
      return '$hours hr';
    }
  }
}
