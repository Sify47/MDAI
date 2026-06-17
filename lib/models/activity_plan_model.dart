// lib/models/activity_plan_model.dart

import 'package:flutter/material.dart';

enum PlanType {
  weekly,
  monthly,
  custom,
}

extension PlanTypeExtension on PlanType {
  String get name {
    switch (this) {
      case PlanType.weekly:
        return 'أسبوعية';
      case PlanType.monthly:
        return 'شهرية';
      case PlanType.custom:
        return 'مخصصة';
    }
  }

  IconData get icon {
    switch (this) {
      case PlanType.weekly:
        return Icons.calendar_view_week;
      case PlanType.monthly:
        return Icons.calendar_month;
      case PlanType.custom:
        return Icons.edit_calendar;
    }
  }
}

class ActivityPlan {
  final int id;
  final String name;
  final String description;
  final PlanType planType;
  final DateTime startDate;
  final DateTime endDate;
  final double progressPercentage;
  final bool isActive;
  final int activityCount;
  final int completedCount;

  ActivityPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.planType,
    required this.startDate,
    required this.endDate,
    this.progressPercentage = 0.0,
    this.isActive = true,
    this.activityCount = 0,
    this.completedCount = 0,
  });

  factory ActivityPlan.fromJson(Map<String, dynamic> json) {
    return ActivityPlan(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      planType: _mapStringToPlanType(json['plan_type']),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? true,
      activityCount: json['activity_count'] ?? 0,
      completedCount: json['completed_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'plan_type': planType.name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_active': isActive,
    };
  }

  static PlanType _mapStringToPlanType(String type) {
    switch (type.toLowerCase()) {
      case 'أسبوعية':
      case 'weekly':
        return PlanType.weekly;
      case 'شهرية':
      case 'monthly':
        return PlanType.monthly;
      case 'مخصصة':
      case 'custom':
        return PlanType.custom;
      default:
        return PlanType.weekly;
    }
  }
}