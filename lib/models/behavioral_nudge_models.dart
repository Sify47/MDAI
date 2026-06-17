// lib/models/behavioral_nudge_models.dart

import 'package:flutter/material.dart';

/// أنواع التحفيز السلوكي
enum NudgeType {
  motivational,      // تحفيزي
  educational,       // تعليمي
  reminder,          // تذكير
  warning,           // تحذير
  encouragement,     // تشجيع
  celebration,       // احتفال
  habitBuilding,     // بناء عادة
  healthInsight,     // رؤية صحية
}

/// أولوية التحفيز
enum NudgePriority {
  low,      // منخفضة
  medium,   // متوسطة
  high,     // عالية
  critical, // حرجة
}

/// سياق التحفيز
enum NudgeContext {
  morningRoutine,    // روتين الصباح
  eveningRoutine,    // روتين المساء
  mealTime,          // وقت الوجبة
  medicationTime,    // وقت الدواء
  activityTime,      // وقت النشاط
  waterReminder,     // تذكير الماء
  sleepTime,         // وقت النوم
  stressTime,        // وقت التوتر
  idleTime,          // وقت الفراغ
  achievement,       // إنجاز
  setback,           // تراجع
}

/// نموذج التحفيز السلوكي
class BehavioralNudge {
  final int id;
  final String title;
  final String message;
  final NudgeType type;
  final NudgePriority priority;
  final NudgeContext context;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isDelivered;
  final bool isActionTaken;
  final DateTime? actionTakenAt;
  final Map<String, dynamic>? metadata;
  final List<NudgeAction>? actions;

  BehavioralNudge({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.context,
    required this.createdAt,
    this.scheduledFor,
    this.isDelivered = false,
    this.isActionTaken = false,
    this.actionTakenAt,
    this.metadata,
    this.actions,
  });

  factory BehavioralNudge.fromJson(Map<String, dynamic> json) {
    return BehavioralNudge(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NudgeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NudgeType.motivational,
      ),
      priority: NudgePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NudgePriority.medium,
      ),
      context: NudgeContext.values.firstWhere(
        (e) => e.name == json['context'],
        orElse: () => NudgeContext.morningRoutine,
      ),
      createdAt: DateTime.parse(json['created_at']),
      scheduledFor: json['scheduled_for'] != null
          ? DateTime.parse(json['scheduled_for'])
          : null,
      isDelivered: json['is_delivered'] ?? false,
      isActionTaken: json['is_action_taken'] ?? false,
      actionTakenAt: json['action_taken_at'] != null
          ? DateTime.parse(json['action_taken_at'])
          : null,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      actions: json['actions'] != null
          ? (json['actions'] as List)
              .map((a) => NudgeAction.fromJson(a))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'context': context.name,
      'created_at': createdAt.toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
      'is_delivered': isDelivered,
      'is_action_taken': isActionTaken,
      'action_taken_at': actionTakenAt?.toIso8601String(),
      'metadata': metadata,
      'actions': actions?.map((a) => a.toJson()).toList(),
    };
  }

  Color get typeColor {
    switch (type) {
      case NudgeType.motivational:
        return Colors.blue;
      case NudgeType.educational:
        return Colors.green;
      case NudgeType.reminder:
        return Colors.orange;
      case NudgeType.warning:
        return Colors.red;
      case NudgeType.encouragement:
        return Colors.purple;
      case NudgeType.celebration:
        return Colors.yellow;
      case NudgeType.habitBuilding:
        return Colors.teal;
      case NudgeType.healthInsight:
        return Colors.indigo;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NudgeType.motivational:
        return Icons.emoji_events;
      case NudgeType.educational:
        return Icons.school;
      case NudgeType.reminder:
        return Icons.notifications;
      case NudgeType.warning:
        return Icons.warning;
      case NudgeType.encouragement:
        return Icons.thumb_up;
      case NudgeType.celebration:
        return Icons.celebration;
      case NudgeType.habitBuilding:
        return Icons.psychology;
      case NudgeType.healthInsight:
        return Icons.insights;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case NudgePriority.low:
        return 'منخفضة';
      case NudgePriority.medium:
        return 'متوسطة';
      case NudgePriority.high:
        return 'عالية';
      case NudgePriority.critical:
        return 'حرجة';
    }
  }

  String get contextLabel {
    switch (context) {
      case NudgeContext.morningRoutine:
        return 'روتين الصباح';
      case NudgeContext.eveningRoutine:
        return 'روتين المساء';
      case NudgeContext.mealTime:
        return 'وقت الوجبة';
      case NudgeContext.medicationTime:
        return 'وقت الدواء';
      case NudgeContext.activityTime:
        return 'وقت النشاط';
      case NudgeContext.waterReminder:
        return 'تذكير الماء';
      case NudgeContext.sleepTime:
        return 'وقت النوم';
      case NudgeContext.stressTime:
        return 'وقت التوتر';
      case NudgeContext.idleTime:
        return 'وقت الفراغ';
      case NudgeContext.achievement:
        return 'إنجاز';
      case NudgeContext.setback:
        return 'تراجع';
    }
  }
}

/// إجراء يمكن اتخاذه من خلال التحفيز
class NudgeAction {
  final String id;
  final String label;
  final String actionType;
  final Map<String, dynamic>? parameters;
  final bool requiresConfirmation;

  NudgeAction({
    required this.id,
    required this.label,
    required this.actionType,
    this.parameters,
    this.requiresConfirmation = false,
  });

  factory NudgeAction.fromJson(Map<String, dynamic> json) {
    return NudgeAction(
      id: json['id'] as String,
      label: json['label'] as String,
      actionType: json['action_type'] as String,
      parameters: json['parameters'] != null
          ? Map<String, dynamic>.from(json['parameters'])
          : null,
      requiresConfirmation: json['requires_confirmation'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'action_type': actionType,
      'parameters': parameters,
      'requires_confirmation': requiresConfirmation,
    };
  }
}

/// تحليل الأنماط السلوكية
class BehavioralPattern {
  final String patternId;
  final String patternName;
  final String description;
  final double confidenceScore;
  final DateTime detectedAt;
  final List<String> triggers;
  final Map<String, dynamic> insights;

  BehavioralPattern({
    required this.patternId,
    required this.patternName,
    required this.description,
    required this.confidenceScore,
    required this.detectedAt,
    required this.triggers,
    required this.insights,
  });

  factory BehavioralPattern.fromJson(Map<String, dynamic> json) {
    return BehavioralPattern(
      patternId: json['pattern_id'] as String,
      patternName: json['pattern_name'] as String,
      description: json['description'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      detectedAt: DateTime.parse(json['detected_at']),
      triggers: List<String>.from(json['triggers']),
      insights: Map<String, dynamic>.from(json['insights']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pattern_id': patternId,
      'pattern_name': patternName,
      'description': description,
      'confidence_score': confidenceScore,
      'detected_at': detectedAt.toIso8601String(),
      'triggers': triggers,
      'insights': insights,
    };
  }
}

/// إحصائيات التحفيز السلوكي
class NudgeStatistics {
  final int totalNudges;
  final int deliveredNudges;
  final int actionTakenNudges;
  final Map<NudgeType, int> nudgeTypeCounts;
  final Map<NudgeContext, int> nudgeContextCounts;
  final double averageResponseTime; // بالدقائق
  final double effectivenessRate;   // نسبة الفعالية
  final DateTime periodStart;
  final DateTime periodEnd;

  NudgeStatistics({
    required this.totalNudges,
    required this.deliveredNudges,
    required this.actionTakenNudges,
    required this.nudgeTypeCounts,
    required this.nudgeContextCounts,
    required this.averageResponseTime,
    required this.effectivenessRate,
    required this.periodStart,
    required this.periodEnd,
  });

  factory NudgeStatistics.fromJson(Map<String, dynamic> json) {
    return NudgeStatistics(
      totalNudges: json['total_nudges'] as int,
      deliveredNudges: json['delivered_nudges'] as int,
      actionTakenNudges: json['action_taken_nudges'] as int,
      nudgeTypeCounts: Map<NudgeType, int>.fromEntries(
        (json['nudge_type_counts'] as Map<String, dynamic>).entries.map(
          (e) => MapEntry(
            NudgeType.values.firstWhere((t) => t.name == e.key),
            e.value as int,
          ),
        ),
      ),
      nudgeContextCounts: Map<NudgeContext, int>.fromEntries(
        (json['nudge_context_counts'] as Map<String, dynamic>).entries.map(
          (e) => MapEntry(
            NudgeContext.values.firstWhere((c) => c.name == e.key),
            e.value as int,
          ),
        ),
      ),
      averageResponseTime: (json['average_response_time'] as num).toDouble(),
      effectivenessRate: (json['effectiveness_rate'] as num).toDouble(),
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_nudges': totalNudges,
      'delivered_nudges': deliveredNudges,
      'action_taken_nudges': actionTakenNudges,
      'nudge_type_counts': Map.fromEntries(
        nudgeTypeCounts.entries.map(
          (e) => MapEntry(e.key.name, e.value),
        ),
      ),
      'nudge_context_counts': Map.fromEntries(
        nudgeContextCounts.entries.map(
          (e) => MapEntry(e.key.name, e.value),
        ),
      ),
      'average_response_time': averageResponseTime,
      'effectiveness_rate': effectivenessRate,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
    };
  }

  double get deliveryRate => totalNudges > 0 
      ? deliveredNudges / totalNudges * 100 
      : 0.0;

  double get actionRate => deliveredNudges > 0
      ? actionTakenNudges / deliveredNudges * 100
      : 0.0;
}