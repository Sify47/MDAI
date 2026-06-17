// lib/models/activity_model.dart

import 'package:flutter/material.dart';

enum ActivityCategoryType {
  work,
  study,
  exercise,
  reading,
  meditation,
  social,
  entertainment,
  family,
  health,
  other,
}

extension ActivityCategoryTypeExtension on ActivityCategoryType {
  String get name {
    switch (this) {
      case ActivityCategoryType.work:
        return 'عمل';
      case ActivityCategoryType.study:
        return 'دراسة';
      case ActivityCategoryType.exercise:
        return 'رياضة';
      case ActivityCategoryType.reading:
        return 'قراءة';
      case ActivityCategoryType.meditation:
        return 'تأمل';
      case ActivityCategoryType.social:
        return 'تواصل اجتماعي';
      case ActivityCategoryType.entertainment:
        return 'ترفيه';
      case ActivityCategoryType.family:
        return 'أسرة';
      case ActivityCategoryType.health:
        return 'صحة';
      case ActivityCategoryType.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityCategoryType.work:
        return Icons.work;
      case ActivityCategoryType.study:
        return Icons.school;
      case ActivityCategoryType.exercise:
        return Icons.fitness_center;
      case ActivityCategoryType.reading:
        return Icons.menu_book;
      case ActivityCategoryType.meditation:
        return Icons.self_improvement;
      case ActivityCategoryType.social:
        return Icons.people;
      case ActivityCategoryType.entertainment:
        return Icons.movie;
      case ActivityCategoryType.family:
        return Icons.family_restroom;
      case ActivityCategoryType.health:
        return Icons.health_and_safety;
      case ActivityCategoryType.other:
        return Icons.category;
    }
  }

  Color get color {
    switch (this) {
      case ActivityCategoryType.work:
        return Colors.blue;
      case ActivityCategoryType.study:
        return Colors.green;
      case ActivityCategoryType.exercise:
        return Colors.orange;
      case ActivityCategoryType.reading:
        return Colors.purple;
      case ActivityCategoryType.meditation:
        return Colors.teal;
      case ActivityCategoryType.social:
        return Colors.pink;
      case ActivityCategoryType.entertainment:
        return Colors.amber;
      case ActivityCategoryType.family:
        return Colors.red;
      case ActivityCategoryType.health:
        return Colors.cyan;
      case ActivityCategoryType.other:
        return Colors.grey;
    }
  }
}

class ActivityCategory {
  final int id;
  final String nameAr;
  final String nameEn;
  final String iconCode;
  final String colorCode;
  final ActivityCategoryType type;

  ActivityCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.iconCode,
    required this.colorCode,
    required this.type,
  });

  String get name => nameAr; // للاستخدام في الواجهة

  IconData get icon {
    // تحويل iconCode إلى IconData
    switch (iconCode) {
      case '💼':
        return Icons.work;
      case '📚':
        return Icons.school;
      case '🏃':
        return Icons.fitness_center;
      case '📖':
        return Icons.menu_book;
      case '🧘':
        return Icons.self_improvement;
      case '👥':
        return Icons.people;
      case '🎮':
        return Icons.movie;
      case '👨‍👩‍👧':
        return Icons.family_restroom;
      case '💊':
        return Icons.health_and_safety;
      default:
        return Icons.category;
    }
  }

  Color get color {
    return Color(int.parse(colorCode.replaceFirst('#', '0xff')));
  }

  factory ActivityCategory.fromJson(Map<String, dynamic> json) {
    return ActivityCategory(
      id: json['id'],
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      iconCode: json['icon_code'] ?? '📋',
      colorCode: json['color_code'] ?? '#2196F3',
      type: _mapStringToType(json['name_en']),
    );
  }

  static ActivityCategoryType _mapStringToType(String nameEn) {
    switch (nameEn.toLowerCase()) {
      case 'work':
        return ActivityCategoryType.work;
      case 'study':
        return ActivityCategoryType.study;
      case 'exercise':
        return ActivityCategoryType.exercise;
      case 'reading':
        return ActivityCategoryType.reading;
      case 'meditation':
        return ActivityCategoryType.meditation;
      case 'social':
        return ActivityCategoryType.social;
      case 'entertainment':
        return ActivityCategoryType.entertainment;
      case 'family':
        return ActivityCategoryType.family;
      case 'health':
        return ActivityCategoryType.health;
      default:
        return ActivityCategoryType.other;
    }
  }
}

class Activity {
  final int id;
  final String title;
  final String description;
  final int categoryId;
  final ActivityCategory? category;
  final DateTime startTime;
  final DateTime endTime;
  final bool isCompleted;
  final bool hasReminder;
  final int reminderMinutes;
  final String? notes;

  // 🆕 Exercise tracking fields (backward compatible)
  final bool isExercise;
  final String? exerciseName;
  final int? sets;
  final int? reps;
  final double? weightKg;
  final int? restSeconds;
  final int? caloriesBurned;

  // 🆕 Multi-exercise support (Phase A)
  final List<ActivityExercise> exercises;

  // 🆕 Plan linking
  final int? planId;
  final String? planName;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    this.category,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
    this.hasReminder = false,
    this.reminderMinutes = 15,
    this.notes,
    // 🆕 Exercise tracking
    this.isExercise = false,
    this.exerciseName,
    this.sets,
    this.reps,
    this.weightKg,
    this.restSeconds,
    this.caloriesBurned,
    // 🆕 Multi-exercise support
    this.exercises = const [],
    // 🆕 Plan linking
    this.planId,
    this.planName,
  });

  Duration get duration => endTime.difference(startTime);
  int get durationMinutes => duration.inMinutes;

  /// حساب إجمالي عدد التكرارات (sets × reps)
  int? get totalReps => (sets != null && reps != null) ? sets! * reps! : null;

  /// حساب الحجم الكلي للتمرين (weight × sets × reps)
  double? get totalVolume => (weightKg != null && sets != null && reps != null)
      ? weightKg! * sets! * reps!
      : null;

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      categoryId: json['category_id'],
      category: json['category'] != null
          ? ActivityCategory.fromJson(json['category'])
          : null,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      isCompleted: json['is_completed'] ?? false,
      hasReminder: json['has_reminder'] ?? false,
      reminderMinutes: json['reminder_minutes'] ?? 15,
      notes: json['notes'],
      // 🆕 Exercise tracking
      isExercise: json['is_exercise'] ?? false,
      exerciseName: json['exercise_name'],
      sets: json['sets'],
      reps: json['reps'],
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      restSeconds: json['rest_seconds'],
      caloriesBurned: json['calories_burned'],
      // 🆕 Multi-exercise support
      exercises: json['exercises'] != null
          ? (json['exercises'] as List<dynamic>)
                .map((e) => ActivityExercise.fromJson(e))
                .toList()
          : [],
      // 🆕 Plan linking
      planId: json['plan_id'],
      planName: json['plan_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_completed': isCompleted,
      'has_reminder': hasReminder,
      'reminder_minutes': reminderMinutes,
      'notes': notes,
      // 🆕 Exercise tracking
      'is_exercise': isExercise,
      'exercise_name': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight_kg': weightKg,
      'rest_seconds': restSeconds,
      'calories_burned': caloriesBurned,
      // 🆕 Plan linking
      'plan_id': planId,
      'plan_name': planName,
      // 🆕 Multi-exercise support (not included in flat payload - sent via bulk endpoint)
    };
  }
}

/// 🆕 نموذج التمرين المرتبط بنشاط (Phase A - Multi-exercise)
class ActivityExercise {
  final int? id;
  final int? activityId;
  final String? exerciseId;
  final String? exerciseNameAr;
  final String? exerciseNameEn;
  final String? muscleGroup;
  final String? muscleGroupEn;
  final double? metValue;
  final int? sets;
  final int? reps;
  final double? weightKg;
  final int? restSeconds;
  final int? caloriesBurned;
  final int? orderIndex;
  final DateTime? createdAt;

  ActivityExercise({
    this.id,
    this.activityId,
    this.exerciseId,
    this.exerciseNameAr,
    this.exerciseNameEn,
    this.muscleGroup,
    this.muscleGroupEn,
    this.metValue,
    this.sets,
    this.reps,
    this.weightKg,
    this.restSeconds,
    this.caloriesBurned,
    this.orderIndex,
    this.createdAt,
  });

  /// حساب إجمالي عدد التكرارات (sets × reps)
  int? get totalReps => (sets != null && reps != null) ? sets! * reps! : null;

  /// حساب الحجم الكلي للتمرين (weight × sets × reps)
  double? get totalVolume => (weightKg != null && sets != null && reps != null)
      ? weightKg! * sets! * reps!
      : null;

  factory ActivityExercise.fromJson(Map<String, dynamic> json) {
    return ActivityExercise(
      id: json['id'],
      activityId: json['activity_id'],
      exerciseId: json['exercise_id'],
      exerciseNameAr: json['exercise_name_ar'],
      exerciseNameEn: json['exercise_name_en'],
      muscleGroup: json['muscle_group'],
      muscleGroupEn: json['muscle_group_en'],
      metValue: (json['met_value'] as num?)?.toDouble(),
      sets: json['sets'],
      reps: json['reps'],
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      restSeconds: json['rest_seconds'],
      caloriesBurned: json['calories_burned'],
      orderIndex: json['order_index'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (activityId != null) 'activity_id': activityId,
      'exercise_id': exerciseId,
      'exercise_name_ar': exerciseNameAr,
      'exercise_name_en': exerciseNameEn,
      'muscle_group': muscleGroup,
      'muscle_group_en': muscleGroupEn,
      'met_value': metValue,
      'sets': sets,
      'reps': reps,
      'weight_kg': weightKg,
      'rest_seconds': restSeconds,
      'calories_burned': caloriesBurned,
      'order_index': orderIndex,
    };
  }

  /// تحويل إلى صيغة ExerciseFormResult للاستخدام في الواجهة
  Map<String, dynamic> toExerciseFormMap() {
    return {
      'exercise_name': exerciseNameAr,
      'exercise_name_en': exerciseNameEn,
      'exercise_id': exerciseId,
      'muscle_group': muscleGroup,
      'muscle_group_en': muscleGroupEn,
      'met_value': metValue,
      'sets': sets,
      'reps': reps,
      'weight_kg': weightKg,
      'rest_seconds': restSeconds,
      'calories_burned': caloriesBurned,
    };
  }
}

class ActivityStats {
  final DateTime date;
  final int totalActivities;
  final int completedActivities;
  final double completionRate;
  final double workHours;
  final double studyHours;
  final int exerciseMinutes;
  final Map<String, int> activitiesByCategory;

  ActivityStats({
    required this.date,
    required this.totalActivities,
    required this.completedActivities,
    required this.completionRate,
    required this.workHours,
    required this.studyHours,
    required this.exerciseMinutes,
    required this.activitiesByCategory,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    return ActivityStats(
      date: DateTime.parse(json['date']),
      totalActivities: json['total_activities'],
      completedActivities: json['completed_activities'],
      completionRate: json['completion_rate'].toDouble(),
      workHours: json['work_hours'].toDouble(),
      studyHours: json['study_hours'].toDouble(),
      exerciseMinutes: json['exercise_minutes'],
      activitiesByCategory: Map<String, int>.from(
        json['activities_by_category'],
      ),
    );
  }
}
