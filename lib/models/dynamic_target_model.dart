// lib/models/dynamic_target_model.dart
// نماذج الأهداف الديناميكية - متوافقة مع backend schemas

class DynamicDailyTarget {
  final int id;
  final int userId;
  final String date;

  // القيم الأساسية (من NutritionCalculator)
  final double? baseCalories;
  final double? baseSteps;
  final double? baseWater;
  final double? baseProtein;
  final double? baseCarbs;
  final double? baseFat;

  // تعديلات التأثير الصحي (نسبة مئوية)
  final double caloriesImpactPct;
  final double stepsImpactPct;
  final double waterImpactPct;
  final double proteinImpactPct;
  final double carbsImpactPct;
  final double fatImpactPct;

  // عوامل التكيف
  final double performanceFactor;
  final double weightTrendFactor;

  // الأهداف النهائية
  final double? targetCalories;
  final double? targetSteps;
  final double? targetWater;
  final double? targetProtein;
  final double? targetCarbs;
  final double? targetFat;

  // تفاصيل
  final List<Map<String, dynamic>>? impactDetails;
  final Map<String, dynamic>? performanceDetails;

  final String? createdAt;
  final String? updatedAt;

  DynamicDailyTarget({
    required this.id,
    required this.userId,
    required this.date,
    this.baseCalories,
    this.baseSteps,
    this.baseWater,
    this.baseProtein,
    this.baseCarbs,
    this.baseFat,
    this.caloriesImpactPct = 0.0,
    this.stepsImpactPct = 0.0,
    this.waterImpactPct = 0.0,
    this.proteinImpactPct = 0.0,
    this.carbsImpactPct = 0.0,
    this.fatImpactPct = 0.0,
    this.performanceFactor = 1.0,
    this.weightTrendFactor = 1.0,
    this.targetCalories,
    this.targetSteps,
    this.targetWater,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
    this.impactDetails,
    this.performanceDetails,
    this.createdAt,
    this.updatedAt,
  });

  factory DynamicDailyTarget.fromJson(Map<String, dynamic> json) {
    return DynamicDailyTarget(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      date: json['date'] ?? '',
      baseCalories: _toDouble(json['base_calories']),
      baseSteps: _toDouble(json['base_steps']),
      baseWater: _toDouble(json['base_water']),
      baseProtein: _toDouble(json['base_protein']),
      baseCarbs: _toDouble(json['base_carbs']),
      baseFat: _toDouble(json['base_fat']),
      caloriesImpactPct: _toDouble(json['calories_impact_pct']) ?? 0.0,
      stepsImpactPct: _toDouble(json['steps_impact_pct']) ?? 0.0,
      waterImpactPct: _toDouble(json['water_impact_pct']) ?? 0.0,
      proteinImpactPct: _toDouble(json['protein_impact_pct']) ?? 0.0,
      carbsImpactPct: _toDouble(json['carbs_impact_pct']) ?? 0.0,
      fatImpactPct: _toDouble(json['fat_impact_pct']) ?? 0.0,
      performanceFactor: _toDouble(json['performance_factor']) ?? 1.0,
      weightTrendFactor: _toDouble(json['weight_trend_factor']) ?? 1.0,
      targetCalories: _toDouble(json['target_calories']),
      targetSteps: _toDouble(json['target_steps']),
      targetWater: _toDouble(json['target_water']),
      targetProtein: _toDouble(json['target_protein']),
      targetCarbs: _toDouble(json['target_carbs']),
      targetFat: _toDouble(json['target_fat']),
      impactDetails: json['impact_details'] != null
          ? List<Map<String, dynamic>>.from(json['impact_details'])
          : null,
      performanceDetails: json['performance_details'] != null
          ? Map<String, dynamic>.from(json['performance_details'])
          : null,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'base_calories': baseCalories,
      'base_steps': baseSteps,
      'base_water': baseWater,
      'base_protein': baseProtein,
      'base_carbs': baseCarbs,
      'base_fat': baseFat,
      'calories_impact_pct': caloriesImpactPct,
      'steps_impact_pct': stepsImpactPct,
      'water_impact_pct': waterImpactPct,
      'protein_impact_pct': proteinImpactPct,
      'carbs_impact_pct': carbsImpactPct,
      'fat_impact_pct': fatImpactPct,
      'performance_factor': performanceFactor,
      'weight_trend_factor': weightTrendFactor,
      'target_calories': targetCalories,
      'target_steps': targetSteps,
      'target_water': targetWater,
      'target_protein': targetProtein,
      'target_carbs': targetCarbs,
      'target_fat': targetFat,
      'impact_details': impactDetails,
      'performance_details': performanceDetails,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// مساعد لتحويل القيم إلى double بأمان
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }
}

class DynamicTargetBreakdown {
  final String targetType;
  final double baseValue;
  final double healthImpactAdjustment;
  final double healthImpactPct;
  final double performanceAdjustment;
  final double performanceFactor;
  final double weightTrendAdjustment;
  final double weightTrendFactor;
  final double finalValue;
  final List<Map<String, dynamic>> impactReasons;

  DynamicTargetBreakdown({
    required this.targetType,
    required this.baseValue,
    required this.healthImpactAdjustment,
    required this.healthImpactPct,
    required this.performanceAdjustment,
    required this.performanceFactor,
    required this.weightTrendAdjustment,
    required this.weightTrendFactor,
    required this.finalValue,
    this.impactReasons = const [],
  });

  factory DynamicTargetBreakdown.fromJson(Map<String, dynamic> json) {
    return DynamicTargetBreakdown(
      targetType: json['target_type'] ?? '',
      baseValue: (json['base_value'] as num?)?.toDouble() ?? 0.0,
      healthImpactAdjustment:
          (json['health_impact_adjustment'] as num?)?.toDouble() ?? 0.0,
      healthImpactPct: (json['health_impact_pct'] as num?)?.toDouble() ?? 0.0,
      performanceAdjustment:
          (json['performance_adjustment'] as num?)?.toDouble() ?? 0.0,
      performanceFactor:
          (json['performance_factor'] as num?)?.toDouble() ?? 1.0,
      weightTrendAdjustment:
          (json['weight_trend_adjustment'] as num?)?.toDouble() ?? 0.0,
      weightTrendFactor:
          (json['weight_trend_factor'] as num?)?.toDouble() ?? 1.0,
      finalValue: (json['final_value'] as num?)?.toDouble() ?? 0.0,
      impactReasons: json['impact_reasons'] != null
          ? List<Map<String, dynamic>>.from(json['impact_reasons'])
          : [],
    );
  }
}

class PerformanceHistory {
  final int id;
  final int userId;
  final String date;

  // نسب الالتزام (0.0-1.0)
  final double? caloriesAdherence;
  final double? stepsAdherence;
  final double? waterAdherence;
  final double? medicationAdherence;
  final double? overallScore;

  // القيم الفعلية والهدف
  final double? actualCalories;
  final double? actualSteps;
  final double? actualWater;
  final double? targetCalories;
  final double? targetSteps;
  final double? targetWater;

  final String? createdAt;

  PerformanceHistory({
    required this.id,
    required this.userId,
    required this.date,
    this.caloriesAdherence,
    this.stepsAdherence,
    this.waterAdherence,
    this.medicationAdherence,
    this.overallScore,
    this.actualCalories,
    this.actualSteps,
    this.actualWater,
    this.targetCalories,
    this.targetSteps,
    this.targetWater,
    this.createdAt,
  });

  factory PerformanceHistory.fromJson(Map<String, dynamic> json) {
    // ✅ دعم تنسيقين: nested (من performance/today) و flat (من performance/{date})
    // التنسيق nested: {"actual": {"calories": X}, "adherence": {"calories": Y}, "overall_score": Z}
    // التنسيق flat: {"actual_calories": X, "calories_adherence": Y, "overall_score": Z}
    final actual = json['actual'] as Map<String, dynamic>?;
    final targets = json['targets'] as Map<String, dynamic>?;
    final adherence = json['adherence'] as Map<String, dynamic>?;

    return PerformanceHistory(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      date: json['date'] ?? '',
      // نسب الالتزام - من adherence object أو من flat keys
      caloriesAdherence: _toDouble(
        adherence?['calories'] ?? json['calories_adherence'],
      ),
      stepsAdherence: _toDouble(adherence?['steps'] ?? json['steps_adherence']),
      waterAdherence: _toDouble(adherence?['water'] ?? json['water_adherence']),
      medicationAdherence: _toDouble(
        adherence?['medication'] ?? json['medication_adherence'],
      ),
      overallScore: _toDouble(json['overall_score']),
      // القيم الفعلية - من actual object أو من flat keys
      actualCalories: _toDouble(actual?['calories'] ?? json['actual_calories']),
      actualSteps: _toDouble(actual?['steps'] ?? json['actual_steps']),
      actualWater: _toDouble(actual?['water'] ?? json['actual_water']),
      // القيم المستهدفة - من targets object أو من flat keys
      targetCalories: _toDouble(
        targets?['calories'] ?? json['target_calories'],
      ),
      targetSteps: _toDouble(targets?['steps'] ?? json['target_steps']),
      targetWater: _toDouble(targets?['water'] ?? json['target_water']),
      createdAt: json['created_at'],
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }
}

class PerformanceSummary {
  final int periodDays;
  final double avgCaloriesAdherence;
  final double avgStepsAdherence;
  final double avgWaterAdherence;
  final double avgMedicationAdherence;
  final double avgOverallScore;
  final double performanceFactor;
  final String trend; // "improving", "stable", "declining"
  final List<PerformanceHistory> dailyRecords;

  PerformanceSummary({
    required this.periodDays,
    required this.avgCaloriesAdherence,
    required this.avgStepsAdherence,
    required this.avgWaterAdherence,
    required this.avgMedicationAdherence,
    required this.avgOverallScore,
    required this.performanceFactor,
    required this.trend,
    this.dailyRecords = const [],
  });

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      periodDays: json['period_days'] ?? 0,
      avgCaloriesAdherence:
          (json['avg_calories_adherence'] as num?)?.toDouble() ?? 0.0,
      avgStepsAdherence:
          (json['avg_steps_adherence'] as num?)?.toDouble() ?? 0.0,
      avgWaterAdherence:
          (json['avg_water_adherence'] as num?)?.toDouble() ?? 0.0,
      avgMedicationAdherence:
          (json['avg_medication_adherence'] as num?)?.toDouble() ?? 0.0,
      avgOverallScore: (json['avg_overall_score'] as num?)?.toDouble() ?? 0.0,
      performanceFactor:
          (json['performance_factor'] as num?)?.toDouble() ?? 1.0,
      trend: json['trend'] ?? 'stable',
      dailyRecords: json['daily_records'] != null
          ? (json['daily_records'] as List<dynamic>)
                .map(
                  (e) => PerformanceHistory.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : [],
    );
  }
}

class AchievementMilestone {
  final int id;
  final int userId;
  final String milestoneType;
  final double? milestoneValue;
  final String milestoneKey;
  final String? description;
  final String? icon;
  final int points;
  final String? achievedAt;

  AchievementMilestone({
    required this.id,
    required this.userId,
    required this.milestoneType,
    this.milestoneValue,
    required this.milestoneKey,
    this.description,
    this.icon,
    this.points = 0,
    this.achievedAt,
  });

  factory AchievementMilestone.fromJson(Map<String, dynamic> json) {
    return AchievementMilestone(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      milestoneType: json['milestone_type'] ?? '',
      milestoneValue: _toDouble(json['milestone_value']),
      milestoneKey: json['milestone_key'] ?? '',
      description: json['description'],
      icon: json['icon'],
      points: json['points'] ?? 0,
      achievedAt: json['achieved_at'],
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }
}

class AchievementStats {
  final int totalPoints;
  final int totalMilestones;
  final Map<String, int> milestonesByType;
  final List<AchievementMilestone> recentMilestones;
  final int streakDays;

  AchievementStats({
    required this.totalPoints,
    required this.totalMilestones,
    required this.milestonesByType,
    required this.recentMilestones,
    this.streakDays = 0,
  });

  factory AchievementStats.fromJson(Map<String, dynamic> json) {
    return AchievementStats(
      totalPoints: json['total_points'] ?? 0,
      totalMilestones: json['total_milestones'] ?? 0,
      milestonesByType: Map<String, int>.from(json['milestones_by_type'] ?? {}),
      recentMilestones:
          (json['recent_milestones'] as List<dynamic>?)
              ?.map(
                (e) => AchievementMilestone.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      streakDays: json['streak_days'] ?? 0,
    );
  }
}

class DynamicTargetComparison {
  final double? staticCalories;
  final double? dynamicCalories;
  final double? caloriesChangePct;
  final int? staticSteps;
  final double? dynamicSteps;
  final double? stepsChangePct;
  final double? staticWater;
  final double? dynamicWater;
  final double? waterChangePct;
  final double? staticProtein;
  final double? dynamicProtein;
  final double? staticCarbs;
  final double? dynamicCarbs;
  final double? staticFat;
  final double? dynamicFat;
  final List<Map<String, dynamic>> changeReasons;

  DynamicTargetComparison({
    this.staticCalories,
    this.dynamicCalories,
    this.caloriesChangePct,
    this.staticSteps,
    this.dynamicSteps,
    this.stepsChangePct,
    this.staticWater,
    this.dynamicWater,
    this.waterChangePct,
    this.staticProtein,
    this.dynamicProtein,
    this.staticCarbs,
    this.dynamicCarbs,
    this.staticFat,
    this.dynamicFat,
    this.changeReasons = const [],
  });

  factory DynamicTargetComparison.fromJson(Map<String, dynamic> json) {
    return DynamicTargetComparison(
      staticCalories: _toDouble(json['static_calories']),
      dynamicCalories: _toDouble(json['dynamic_calories']),
      caloriesChangePct: _toDouble(json['calories_change_pct']),
      staticSteps: json['static_steps'] as int?,
      dynamicSteps: _toDouble(json['dynamic_steps']),
      stepsChangePct: _toDouble(json['steps_change_pct']),
      staticWater: _toDouble(json['static_water']),
      dynamicWater: _toDouble(json['dynamic_water']),
      waterChangePct: _toDouble(json['water_change_pct']),
      staticProtein: _toDouble(json['static_protein']),
      dynamicProtein: _toDouble(json['dynamic_protein']),
      staticCarbs: _toDouble(json['static_carbs']),
      dynamicCarbs: _toDouble(json['dynamic_carbs']),
      staticFat: _toDouble(json['static_fat']),
      dynamicFat: _toDouble(json['dynamic_fat']),
      changeReasons: json['change_reasons'] != null
          ? List<Map<String, dynamic>>.from(json['change_reasons'])
          : [],
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }
}

class DynamicTargetHistory {
  final List<DynamicDailyTarget> targets;
  final int periodDays;
  final double avgTargetCalories;
  final double avgTargetSteps;
  final double avgTargetWater;
  final String caloriesTrend; // "increasing", "stable", "decreasing"
  final String stepsTrend;
  final String waterTrend;

  DynamicTargetHistory({
    required this.targets,
    required this.periodDays,
    required this.avgTargetCalories,
    required this.avgTargetSteps,
    required this.avgTargetWater,
    required this.caloriesTrend,
    required this.stepsTrend,
    required this.waterTrend,
  });

  factory DynamicTargetHistory.fromJson(Map<String, dynamic> json) {
    return DynamicTargetHistory(
      targets:
          (json['targets'] as List<dynamic>?)
              ?.map(
                (e) => DynamicDailyTarget.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      periodDays: json['period_days'] ?? 0,
      avgTargetCalories:
          (json['avg_target_calories'] as num?)?.toDouble() ?? 0.0,
      avgTargetSteps: (json['avg_target_steps'] as num?)?.toDouble() ?? 0.0,
      avgTargetWater: (json['avg_target_water'] as num?)?.toDouble() ?? 0.0,
      caloriesTrend: json['calories_trend'] ?? 'stable',
      stepsTrend: json['steps_trend'] ?? 'stable',
      waterTrend: json['water_trend'] ?? 'stable',
    );
  }
}
