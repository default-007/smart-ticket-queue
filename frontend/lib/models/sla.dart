import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sla.g.dart';

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

  factory SLAMetrics.fromJson(dynamic json) {
    // If it's a list, take the first item
    final data = json is List ? json.first : json;

    return SLAMetrics(
      totalTickets: data['totalTickets'] ?? 0,
      responseSLABreaches: data['responseSLABreaches'] ?? 0,
      resolutionSLABreaches: data['resolutionSLABreaches'] ?? 0,
      averageResponseTime: data['averageResponseTime'],
      averageResolutionTime: data['averageResolutionTime'],
      slaComplianceRate: (data['slaComplianceRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => _$SLAMetricsToJson(this);

  String get complianceRateFormatted =>
      '${slaComplianceRate.toStringAsFixed(1)}%';

  String get averageResponseTimeFormatted => averageResponseTime != null
      ? '${averageResponseTime!.toStringAsFixed(1)} min'
      : 'N/A';

  String get averageResolutionTimeFormatted => averageResolutionTime != null
      ? '${(averageResolutionTime! / 60).toStringAsFixed(1)} hrs'
      : 'N/A';
}

@JsonSerializable()
class TicketSLA {
  final DateTime? responseDeadline;
  final DateTime? resolutionDeadline;
  final bool? responseTimeMet;
  final bool? resolutionTimeMet;

  TicketSLA({
    this.responseDeadline,
    this.resolutionDeadline,
    this.responseTimeMet,
    this.resolutionTimeMet,
  });

  factory TicketSLA.fromJson(Map<String, dynamic> json) {
    return TicketSLA(
      responseDeadline: json['responseTime'] != null &&
              json['responseTime']['deadline'] != null
          ? DateTime.parse(json['responseTime']['deadline'] as String)
          : null,
      resolutionDeadline: json['resolutionTime'] != null &&
              json['resolutionTime']['deadline'] != null
          ? DateTime.parse(json['resolutionTime']['deadline'] as String)
          : null,
      responseTimeMet: json['responseTime'] != null
          ? json['responseTime']['met'] as bool?
          : null,
      resolutionTimeMet: json['resolutionTime'] != null
          ? json['resolutionTime']['met'] as bool?
          : null,
    );
  }

  Map<String, dynamic> toJson() => _$TicketSLAToJson(this);

  bool get isBreached =>
      (responseTimeMet != null && !responseTimeMet!) ||
      (resolutionTimeMet != null && !resolutionTimeMet!);

  Duration? get timeUntilResponseBreach {
    if (responseDeadline == null || responseTimeMet == true) return null;
    return responseDeadline!.difference(DateTime.now());
  }

  Duration? get timeUntilResolutionBreach {
    if (resolutionDeadline == null || resolutionTimeMet == true) return null;
    return resolutionDeadline!.difference(DateTime.now());
  }

  String getFormattedTimeUntilBreach() {
    final responseTime = timeUntilResponseBreach;
    final resolutionTime = timeUntilResolutionBreach;

    if (responseTime != null && responseTimeMet == false) {
      return _formatDuration(responseTime);
    } else if (resolutionTime != null && resolutionTimeMet == false) {
      return _formatDuration(resolutionTime);
    }
    return 'N/A';
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) {
      return 'Breached';
    }

    if (duration.inHours > 24) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }
}
