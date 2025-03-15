// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sla.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SLAConfig _$SLAConfigFromJson(Map<String, dynamic> json) => SLAConfig(
      priority: (json['priority'] as num).toInt(),
      category: json['category'] as String,
      responseTime: (json['responseTime'] as num).toInt(),
      resolutionTime: (json['resolutionTime'] as num).toInt(),
      escalationRules: (json['escalationRules'] as List<dynamic>)
          .map((e) => SLAEscalationRule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SLAConfigToJson(SLAConfig instance) => <String, dynamic>{
      'priority': instance.priority,
      'category': instance.category,
      'responseTime': instance.responseTime,
      'resolutionTime': instance.resolutionTime,
      'escalationRules': instance.escalationRules,
    };

SLAEscalationRule _$SLAEscalationRuleFromJson(Map<String, dynamic> json) =>
    SLAEscalationRule(
      level: (json['level'] as num).toInt(),
      threshold: (json['threshold'] as num).toInt(),
      notifyRoles: (json['notifyRoles'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SLAEscalationRuleToJson(SLAEscalationRule instance) =>
    <String, dynamic>{
      'level': instance.level,
      'threshold': instance.threshold,
      'notifyRoles': instance.notifyRoles,
    };

SLAMetrics _$SLAMetricsFromJson(Map<String, dynamic> json) => SLAMetrics(
      totalTickets: (json['totalTickets'] as num).toInt(),
      responseSLABreaches: (json['responseSLABreaches'] as num).toInt(),
      resolutionSLABreaches: (json['resolutionSLABreaches'] as num).toInt(),
      averageResponseTime: (json['averageResponseTime'] as num?)?.toDouble(),
      averageResolutionTime:
          (json['averageResolutionTime'] as num?)?.toDouble(),
      slaComplianceRate: (json['slaComplianceRate'] as num).toDouble(),
    );

Map<String, dynamic> _$SLAMetricsToJson(SLAMetrics instance) =>
    <String, dynamic>{
      'totalTickets': instance.totalTickets,
      'responseSLABreaches': instance.responseSLABreaches,
      'resolutionSLABreaches': instance.resolutionSLABreaches,
      'averageResponseTime': instance.averageResponseTime,
      'averageResolutionTime': instance.averageResolutionTime,
      'slaComplianceRate': instance.slaComplianceRate,
    };

TicketSLA _$TicketSLAFromJson(Map<String, dynamic> json) => TicketSLA(
      responseDeadline: json['responseDeadline'] == null
          ? null
          : DateTime.parse(json['responseDeadline'] as String),
      resolutionDeadline: json['resolutionDeadline'] == null
          ? null
          : DateTime.parse(json['resolutionDeadline'] as String),
      responseTimeMet: json['responseTimeMet'] as bool?,
      resolutionTimeMet: json['resolutionTimeMet'] as bool?,
    );

Map<String, dynamic> _$TicketSLAToJson(TicketSLA instance) => <String, dynamic>{
      'responseDeadline': instance.responseDeadline?.toIso8601String(),
      'resolutionDeadline': instance.resolutionDeadline?.toIso8601String(),
      'responseTimeMet': instance.responseTimeMet,
      'resolutionTimeMet': instance.resolutionTimeMet,
    };
