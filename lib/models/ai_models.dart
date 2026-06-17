// lib/models/ai_models.dart
// Data models for AI-powered nutrition features:
// - Smart Meal Recommendations Engine (Item 1)
// - Dynamic Recipe Adaptation (Item 2)
// - Predictive Nutrition Analytics (Item 3)
// - Visual Data Exploration (Item 4)
// - Nutrition Challenges System (Item 5)
// - Reward System (Item 6)

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
// ITEM 1: SMART MEAL RECOMMENDATIONS ENGINE
// ═══════════════════════════════════════════════════════════

/// Represents the context-aware reason for a recommendation
enum RecommendationReason {
  fillsNutritionGap,
  matchesTastePreference,
  suitableForHealthCondition,
  varietySuggestion,
  timeAppropriate,
  favorite,
  calorieTarget,
  diseaseSpecific,
  dailyBalance,
  hydrationReminder,
}

/// A scored meal suggestion with AI explanation
class AiMealRecommendation {
  final int mealId;
  final String mealName;
  final String mealType; // فطور - غداء - عشاء - سناك
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> ingredients;
  final String? imageUrl;
  final String description;
  final double relevanceScore; // 0.0 - 1.0
  final RecommendationReason primaryReason;
  final List<RecommendationReason> secondaryReasons;
  final String aiExplanation; // Arabic text explaining why recommended
  final bool isFromFavorite;
  final bool isDietBreakSuggestion;

  AiMealRecommendation({
    required this.mealId,
    required this.mealName,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    this.imageUrl,
    required this.description,
    required this.relevanceScore,
    required this.primaryReason,
    this.secondaryReasons = const [],
    required this.aiExplanation,
    this.isFromFavorite = false,
    this.isDietBreakSuggestion = false,
  });

  /// Get a human-readable (Arabic) reason label
  String get reasonLabel {
    switch (primaryReason) {
      case RecommendationReason.fillsNutritionGap:
        return 'يسد فجوة غذائية';
      case RecommendationReason.matchesTastePreference:
        return 'يناسب تفضيلاتك';
      case RecommendationReason.suitableForHealthCondition:
        return 'مناسب لحالتك الصحية';
      case RecommendationReason.varietySuggestion:
        return 'اقتراح للتنويع';
      case RecommendationReason.timeAppropriate:
        return 'مناسب لهذا الوقت';
      case RecommendationReason.favorite:
        return 'من وجباتك المفضلة';
      case RecommendationReason.calorieTarget:
        return 'ضمن هدف السعرات';
      case RecommendationReason.diseaseSpecific:
        return 'مخصص لحالتك';
      case RecommendationReason.dailyBalance:
        return 'لتحقيق التوازن اليومي';
      case RecommendationReason.hydrationReminder:
        return 'تذكير بشرب الماء';
    }
  }

  String get scoreLabel {
    if (relevanceScore >= 0.9) return 'ممتاز';
    if (relevanceScore >= 0.7) return 'جيد جداً';
    if (relevanceScore >= 0.5) return 'جيد';
    return 'مقبول';
  }

  Color get scoreColor {
    if (relevanceScore >= 0.9) return const Color(0xFF43A047);
    if (relevanceScore >= 0.7) return const Color(0xFF2E7D32);
    if (relevanceScore >= 0.5) return const Color(0xFFFFC107);
    return const Color(0xFFFF9800);
  }
}

/// Time-of-day context for recommendations
enum MealTimeContext {
  morning,    // 5-11 AM
  midday,     // 11-2 PM
  afternoon,  // 2-6 PM
  evening,    // 6-9 PM
  lateNight,  // 9 PM+
}

/// Context bundle for the AI recommendation engine
class RecommendationContext {
  final MealTimeContext timeContext;
  final double currentCalories;
  final double currentProtein;
  final double currentCarbs;
  final double currentFat;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final List<String> diseases;
  final String goal;
  final Set<String> recentlyEatenMeals;
  final Set<String> avoidedFoods;
  final Set<String> preferredCuisines;
  final int waterIntake;
  final List<String> todayMealTypes; // Which meal types already eaten

  RecommendationContext({
    required this.timeContext,
    required this.currentCalories,
    required this.currentProtein,
    required this.currentCarbs,
    required this.currentFat,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    this.diseases = const [],
    required this.goal,
    this.recentlyEatenMeals = const {},
    this.avoidedFoods = const {},
    this.preferredCuisines = const {},
    this.waterIntake = 0,
    this.todayMealTypes = const [],
  });

  /// Progress towards targets (0.0 - 1.0)
  double get calorieProgress =>
      targetCalories > 0 ? (currentCalories / targetCalories).clamp(0.0, 1.0) : 0.0;
  double get proteinProgress =>
      targetProtein > 0 ? (currentProtein / targetProtein).clamp(0.0, 1.0) : 0.0;
  double get carbsProgress =>
      targetCarbs > 0 ? (currentCarbs / targetCarbs).clamp(0.0, 1.0) : 0.0;
  double get fatProgress =>
      targetFat > 0 ? (currentFat / targetFat).clamp(0.0, 1.0) : 0.0;

  /// Check if a specific meal type has been eaten today
  bool hasEatenMealType(String type) => todayMealTypes.contains(type);

  /// Determine which meal type is most needed now
  String? get suggestedMealType {
    if (!todayMealTypes.contains('فطور')) return 'فطور';
    if (!todayMealTypes.contains('غداء')) return 'غداء';
    if (!todayMealTypes.contains('عشاء')) return 'عشاء';
    if (!todayMealTypes.contains('سناك')) return 'سناك';
    return null;
  }

  /// Get the most deficient nutrient
  String? get mostDeficientNutrient {
    final deficits = <String, double>{};
    deficits['بروتين'] = targetProtein - currentProtein;
    deficits['كارب'] = targetCarbs - currentCarbs;
    deficits['دهون'] = targetFat - currentFat;
    final maxDeficit = deficits.values.reduce((a, b) => a > b ? a : b);
    if (maxDeficit <= 0) return null;
    return deficits.entries.firstWhere((e) => e.value == maxDeficit).key;
  }
}

// ═══════════════════════════════════════════════════════════
// ITEM 2: DYNAMIC RECIPE ADAPTATION
// ═══════════════════════════════════════════════════════════

/// Represents an ingredient substitution suggestion
class IngredientSubstitution {
  final String originalIngredient;
  final String suggestedIngredient;
  final String reason;
  final double caloriesImpact; // difference in calories
  final bool isHealthier;

  IngredientSubstitution({
    required this.originalIngredient,
    required this.suggestedIngredient,
    required this.reason,
    required this.caloriesImpact,
    required this.isHealthier,
  });
}

/// An adapted recipe variant based on user needs
class AdaptedRecipe {
  final int originalMealId;
  final String originalName;
  final String adaptedName;
  final double originalCalories;
  final double adaptedCalories;
  final double originalProtein;
  final double adaptedProtein;
  final double originalCarbs;
  final double adaptedCarbs;
  final double originalFat;
  final double adaptedFat;
  final List<String> originalIngredients;
  final List<String> adaptedIngredients;
  final List<IngredientSubstitution> substitutions;
  final String adaptationReason;
  final String cookingTips;
  final List<String> servingSuggestions;

  AdaptedRecipe({
    required this.originalMealId,
    required this.originalName,
    required this.adaptedName,
    required this.originalCalories,
    required this.adaptedCalories,
    required this.originalProtein,
    required this.adaptedProtein,
    required this.originalCarbs,
    required this.adaptedCarbs,
    required this.originalFat,
    required this.adaptedFat,
    required this.originalIngredients,
    required this.adaptedIngredients,
    required this.substitutions,
    required this.adaptationReason,
    required this.cookingTips,
    required this.servingSuggestions,
  });

  /// Calculate the nutrition change percentages
  Map<String, double> get nutritionDelta => {
        'calories': originalCalories > 0
            ? ((adaptedCalories - originalCalories) / originalCalories * 100)
            : 0,
        'protein': originalProtein > 0
            ? ((adaptedProtein - originalProtein) / originalProtein * 100)
            : 0,
        'carbs': originalCarbs > 0
            ? ((adaptedCarbs - originalCarbs) / originalCarbs * 100)
            : 0,
        'fat': originalFat > 0
            ? ((adaptedFat - originalFat) / originalFat * 100)
            : 0,
      };
}

// ═══════════════════════════════════════════════════════════
// ITEM 3: PREDICTIVE NUTRITION ANALYTICS
// ═══════════════════════════════════════════════════════════

/// A predicted trend for a specific metric
class NutritionTrend {
  final String metricName;
  final String metricUnit;
  final List<double> historicalValues;
  final List<DateTime> historicalDates;
  final double predictedValue;
  final double currentValue;
  final double changePercent;
  final TrendDirection direction;
  final String insight; // Arabic text insight
  final bool isAlert;

  NutritionTrend({
    required this.metricName,
    required this.metricUnit,
    required this.historicalValues,
    required this.historicalDates,
    required this.predictedValue,
    required this.currentValue,
    required this.changePercent,
    required this.direction,
    required this.insight,
    this.isAlert = false,
  });
}

enum TrendDirection { increasing, decreasing, stable, fluctuating }

/// A predicted nutrition deficiency
class PredictedDeficiency {
  final String nutrient;
  final String icon;
  final double riskScore; // 0.0 - 1.0
  final String expectedDate;
  final String description;
  final List<String> preventiveActions;

  PredictedDeficiency({
    required this.nutrient,
    required this.icon,
    required this.riskScore,
    required this.expectedDate,
    required this.description,
    required this.preventiveActions,
  });

  String get riskLabel {
    if (riskScore >= 0.7) return 'مرتفع';
    if (riskScore >= 0.4) return 'متوسط';
    return 'منخفض';
  }

  Color get riskColor {
    if (riskScore >= 0.7) return const Color(0xFFF44336);
    if (riskScore >= 0.4) return const Color(0xFFFFC107);
    return const Color(0xFF43A047);
  }
}

/// Complete predictive analytics report
class NutritionPredictionReport {
  final DateTime generatedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<NutritionTrend> trends;
  final List<PredictedDeficiency> predictedDeficiencies;
  final double overallScore; // 0-100
  final String overallAssessment;
  final List<String> actionableRecommendations;
  final Map<String, double> weeklyCalorieForecast;
  final Map<String, double> weeklyProteinForecast;
  final Map<String, double> weeklyCarbsForecast;
  final Map<String, double> weeklyFatForecast;

  NutritionPredictionReport({
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.trends,
    required this.predictedDeficiencies,
    required this.overallScore,
    required this.overallAssessment,
    required this.actionableRecommendations,
    required this.weeklyCalorieForecast,
    required this.weeklyProteinForecast,
    required this.weeklyCarbsForecast,
    required this.weeklyFatForecast,
  });
}

// ═══════════════════════════════════════════════════════════
// ITEM 4: VISUAL DATA EXPLORATION
// ═══════════════════════════════════════════════════════════

/// Types of visualizations supported
enum VisualizationType {
  dailyTrend,
  macroBreakdown,
  weeklyComparison,
  goalProgress,
  heatmap,
  radarChart,
  nutrientTimeline,
  streakCalendar,
}

/// A data point for visualization
class DataPoint {
  final DateTime date;
  final String label;
  final double value;
  final String? secondaryValue;
  final Color? color;

  DataPoint({
    required this.date,
    required this.label,
    required this.value,
    this.secondaryValue,
    this.color,
  });
}

/// A series of related data points for charting
class DataSeries {
  final String name;
  final String unit;
  final List<DataPoint> points;
  final Color seriesColor;
  final bool showOnChart;

  DataSeries({
    required this.name,
    required this.unit,
    required this.points,
    required this.seriesColor,
    this.showOnChart = true,
  });

  double get average =>
      points.isEmpty ? 0 : points.map((p) => p.value).reduce((a, b) => a + b) / points.length;
  double get max => points.isEmpty ? 0 : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
  double get min => points.isEmpty ? 0 : points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
}

/// Structured chart data
class NutritionChartData {
  final String title;
  final String subtitle;
  final VisualizationType type;
  final List<DataSeries> series;
  final List<String> insights;

  NutritionChartData({
    required this.title,
    this.subtitle = '',
    required this.type,
    required this.series,
    this.insights = const [],
  });
}

// ═══════════════════════════════════════════════════════════
// ITEM 5: NUTRITION CHALLENGES SYSTEM
// ═══════════════════════════════════════════════════════════

enum ChallengeCategory {
  daily,
  weekly,
  monthly,
  special,
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  expert,
}

enum ChallengeStatus {
  notStarted,
  inProgress,
  completed,
  failed,
  claimed,
}

/// A nutrition challenge
class NutritionChallenge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final int durationDays;
  final int xpReward;
  final String? badgeId; // Associated badge on completion
  final List<String> requirements;
  final List<String> tips;
  final ChallengeStatus status;
  final double progress; // 0.0 - 1.0
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime expiresAt;
  final String? specialLabel; // مثل "رمضان" أو "الشتاء"

  NutritionChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.difficulty,
    required this.durationDays,
    required this.xpReward,
    this.badgeId,
    this.requirements = const [],
    this.tips = const [],
    this.status = ChallengeStatus.notStarted,
    this.progress = 0.0,
    this.startedAt,
    this.completedAt,
    required this.expiresAt,
    this.specialLabel,
  });

  NutritionChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    ChallengeCategory? category,
    ChallengeDifficulty? difficulty,
    int? durationDays,
    int? xpReward,
    String? badgeId,
    List<String>? requirements,
    List<String>? tips,
    ChallengeStatus? status,
    double? progress,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    String? specialLabel,
  }) {
    return NutritionChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      durationDays: durationDays ?? this.durationDays,
      xpReward: xpReward ?? this.xpReward,
      badgeId: badgeId ?? this.badgeId,
      requirements: requirements ?? this.requirements,
      tips: tips ?? this.tips,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      specialLabel: specialLabel ?? this.specialLabel,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'category': category.name,
    'difficulty': difficulty.name,
    'durationDays': durationDays,
    'xpReward': xpReward,
    'badgeId': badgeId,
    'requirements': requirements,
    'tips': tips,
    'status': status.name,
    'progress': progress,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'specialLabel': specialLabel,
  };

  factory NutritionChallenge.fromJson(Map<String, dynamic> json) {
    return NutritionChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: ChallengeCategory.values.firstWhere((e) => e.name == json['category']),
      difficulty: ChallengeDifficulty.values.firstWhere((e) => e.name == json['difficulty']),
      durationDays: json['durationDays'] as int,
      xpReward: json['xpReward'] as int,
      badgeId: json['badgeId'] as String?,
      requirements: (json['requirements'] as List?)?.cast<String>() ?? [],
      tips: (json['tips'] as List?)?.cast<String>() ?? [],
      status: ChallengeStatus.values.firstWhere((e) => e.name == (json['status'] ?? 'notStarted')),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      specialLabel: json['specialLabel'] as String?,
    );
  }

  String get progressLabel => '${(progress * 100).round()}%';
  String get remainingLabel {
    if (status == ChallengeStatus.completed || status == ChallengeStatus.claimed) {
      return 'مكتمل ✓';
    }
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.inDays > 0) return '${remaining.inDays} يوم متبقي';
    if (remaining.inHours > 0) return '${remaining.inHours} ساعة متبقية';
    return 'ينتهي اليوم';
  }

  Color get difficultyColor {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return const Color(0xFF43A047);
      case ChallengeDifficulty.medium:
        return const Color(0xFFFFC107);
      case ChallengeDifficulty.hard:
        return const Color(0xFFFF9800);
      case ChallengeDifficulty.expert:
        return const Color(0xFFF44336);
    }
  }

  static const List<String> challengeIcons = [
    '🥗', '💧', '🏃', '🧘', '🥩', '🍎',
    '🥦', '📝', '🔥', '⭐', '🎯', '🏆',
  ];
}

/// Available challenges data
class ChallengeLibrary {
  static List<NutritionChallenge> getDefaultChallenges() {
    final now = DateTime.now();
    return [
      // Daily Challenges
      NutritionChallenge(
        id: 'ch_daily_veggies_5',
        title: 'تحدي الخضار',
        description: 'تناول 5 حصص من الخضروات الطازجة المتنوعة اليوم',
        icon: '🥗',
        category: ChallengeCategory.daily,
        difficulty: ChallengeDifficulty.easy,
        durationDays: 1,
        xpReward: 50,
        badgeId: 'badge_veggie_lover',
        requirements: ['تناول وجبة تحتوي على خضروات', 'تنويع في أنواع الخضار'],
        tips: ['أضف الخيار للسلطة', 'جزر مع وجبة الغداء', 'سبانخ في العشاء'],
        status: ChallengeStatus.notStarted,
        expiresAt: now.add(const Duration(days: 1)),
      ),
      NutritionChallenge(
        id: 'ch_daily_water_8',
        title: 'تحدي الماء',
        description: 'اشرب 8 أكواب ماء على الأقل اليوم',
        icon: '💧',
        category: ChallengeCategory.daily,
        difficulty: ChallengeDifficulty.easy,
        durationDays: 1,
        xpReward: 40,
        requirements: ['تسجيل 8 أكواب ماء'],
        tips: ['احضر زجاجة ماء معك', 'اشرب كوب مع كل وجبة'],
        status: ChallengeStatus.notStarted,
        expiresAt: now.add(const Duration(days: 1)),
      ),
      NutritionChallenge(
        id: 'ch_daily_logger',
        title: 'مسجل مميز',
        description: 'سجل جميع وجباتك اليوم بالكامل', icon: '📝',
        category: ChallengeCategory.daily,
        difficulty: ChallengeDifficulty.medium,
        durationDays: 1,
        xpReward: 60,
        requirements: ['تسجيل الفطور', 'تسجيل الغداء', 'تسجيل العشاء'],
        status: ChallengeStatus.notStarted,
        expiresAt: now.add(const Duration(days: 1)),
      ),
      NutritionChallenge(
        id: 'ch_daily_no_sugar',
        title: 'بدون سكر',
        description: 'تجنب السكريات المضافة اليوم', icon: '🚫',
        category: ChallengeCategory.daily,
        difficulty: ChallengeDifficulty.hard,
        durationDays: 1,
        xpReward: 100,
        badgeId: 'badge_sugar_free',
        requirements: ['لا مشروبات محلاة', 'لا حلويات', 'لا سكريات مضافة'],
        tips: ['استخدم الفواكه للتحلية', 'اشرب الماء بدل المشروبات الغازية'],
        status: ChallengeStatus.notStarted,
        expiresAt: now.add(const Duration(days: 1)),
      ),

      // Weekly Challenges
      NutritionChallenge(
        id: 'ch_weekly_balanced',
        title: 'أسبوع متوازن',
        description: 'حقق التوازن الغذائي كل يوم لمدة أسبوع كامل', icon: '⚖️',
        category: ChallengeCategory.weekly,
        difficulty: ChallengeDifficulty.medium,
        durationDays: 7,
        xpReward: 300,
        badgeId: 'badge_balanced_week',
        requirements: ['نسبة بروتين 25-35% يومياً', 'نسبة كارب 40-55% يومياً'],
        tips: ['خطط لوجباتك مسبقاً', 'استخدم حاسبة الماكروز'],
        status: ChallengeStatus.notStarted,
        expiresAt: now.add(const Duration(days: 7)),
      ),
      NutritionChallenge(
        id: 'ch_weekly_protein',
        title: 'هدف البروتين',
        description: 'حقق هدف البروتين اليومي لمدة 7 أيام متتالية', icon: '🥩',
        category: ChallengeCategory.weekly,
        difficulty: ChallengeDifficulty.medium,
        durationDays: 7,
        xpReward: 350,
        badgeId: 'badge_protein_master',
        requirements: ['بروتين كافي كل يوم', 'مصادر بروتين متنوعة'],
        tips: ['وزع البروتين على الوجبات', 'ادمج البقوليات'],
        status: ChallengeStatus.notStarted,
        expiresAt: now.add(const Duration(days: 7)),
      ),
      NutritionChallenge(
        id: 'ch_weekly_hydration',
        title: 'بطل الترطيب',
        description: 'حقق هدف الماء اليومي لمدة 7 أيام', icon: '💧',
        category: ChallengeCategory.weekly,
        difficulty: ChallengeDifficulty.easy,
        durationDays: 7,
        xpReward: 250,
        badgeId: 'badge_hydration_hero',
        requirements: ['8+ أكواب ماء يومياً'],
        tips: ['استخدم تطبيق تتبع الماء', 'أضف شرائح ليمون للنكهة'],
        status: ChallengeStatus.notStarted,
        expiresAt: now.add(const Duration(days: 7)),
      ),

      // Monthly Challenges
      NutritionChallenge(
        id: 'ch_monthly_streak',
        title: 'شهر من الالتزام',
        description: 'سجل وجباتك يومياً لمدة 30 يوماً متتالية', icon: '🔥',
        category: ChallengeCategory.monthly,
        difficulty: ChallengeDifficulty.hard,
        durationDays: 30,
        xpReward: 1000,
        badgeId: 'badge_month_streak',
        requirements: ['تسجيل وجبة واحدة على الأقل يومياً'],
        status: ChallengeStatus.notStarted,
        expiresAt: now.add(const Duration(days: 30)),
      ),
      NutritionChallenge(
        id: 'ch_monthly_variety',
        title: 'خبير التنويع',
        description: 'تناول 30 نوع مختلف من الأطعمة هذا الشهر', icon: '🎯',
        category: ChallengeCategory.monthly,
        difficulty: ChallengeDifficulty.hard,
        durationDays: 30,
        xpReward: 800,
        badgeId: 'badge_variety_expert',
        requirements: ['30 نوع طعام مختلف', 'تنويع في المجموعات الغذائية'],
        tips: ['جرب وصفة جديدة كل أسبوع', 'اشتري خضروات موسمية'],
        status: ChallengeStatus.notStarted,
        expiresAt: now.add(const Duration(days: 30)),
      ),

      // Special Challenges
      NutritionChallenge(
        id: 'ch_special_meal_master',
        title: 'طاهي التغذية',
        description: 'قم بتحضير 5 وجبات متوازنة كاملة من وصفات التطبيق', icon: '👨‍🍳',
        category: ChallengeCategory.special,
        difficulty: ChallengeDifficulty.medium,
        durationDays: 14,
        xpReward: 500,
        badgeId: 'badge_chef',
        requirements: ['تحضير 5 وجبات', 'استخدام وصفات التطبيق'],
        tips: ['ابدأ بوجبات بسيطة', 'صور وجباتك للمشاركة'],
        status: ChallengeStatus.notStarted,
        expiresAt: now.add(const Duration(days: 14)),
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════
// ITEM 6: REWARD SYSTEM
// ═══════════════════════════════════════════════════════════

/// Types of badges/rewards
enum BadgeType {
  achievement,     // إنجاز
  milestone,       // معلم
  streak,          // استمرارية
  challenge,       // تحدي
  special,         // خاص
  hidden,          // مخفي
}

/// A badge/reward that can be earned
class NutritionBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeType type;
  final int xpRequired;
  final bool isEarned;
  final DateTime? earnedAt;
  final double progress; // 0.0 - 1.0
  final String progressText;
  final bool isSecret;

  NutritionBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    this.xpRequired = 0,
    this.isEarned = false,
    this.earnedAt,
    this.progress = 0.0,
    this.progressText = '',
    this.isSecret = false,
  });

  NutritionBadge copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    BadgeType? type,
    int? xpRequired,
    bool? isEarned,
    DateTime? earnedAt,
    double? progress,
    String? progressText,
    bool? isSecret,
  }) {
    return NutritionBadge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      xpRequired: xpRequired ?? this.xpRequired,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
      progress: progress ?? this.progress,
      progressText: progressText ?? this.progressText,
      isSecret: isSecret ?? this.isSecret,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'type': type.name,
    'xpRequired': xpRequired,
    'isEarned': isEarned,
    'earnedAt': earnedAt?.toIso8601String(),
    'progress': progress,
    'progressText': progressText,
    'isSecret': isSecret,
  };

  factory NutritionBadge.fromJson(Map<String, dynamic> json) {
    return NutritionBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      type: BadgeType.values.firstWhere((e) => e.name == json['type']),
      xpRequired: json['xpRequired'] as int? ?? 0,
      isEarned: json['isEarned'] as bool? ?? false,
      earnedAt: json['earnedAt'] != null ? DateTime.parse(json['earnedAt'] as String) : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      progressText: json['progressText'] as String? ?? '',
      isSecret: json['isSecret'] as bool? ?? false,
    );
  }

  Color get typeColor {
    switch (type) {
      case BadgeType.achievement:
        return const Color(0xFF1565C0);
      case BadgeType.milestone:
        return const Color(0xFF00897B);
      case BadgeType.streak:
        return const Color(0xFFFF9800);
      case BadgeType.challenge:
        return const Color(0xFF43A047);
      case BadgeType.special:
        return const Color(0xFF9C27B0);
      case BadgeType.hidden:
        return const Color(0xFF607D8B);
    }
  }
}

/// User's overall gamification stats
class UserGamificationStats {
  final int totalXp;
  final int currentLevel;
  final int xpToNextLevel;
  final int challengesCompleted;
  final int currentStreak;
  final int longestStreak;
  final int badgesEarned;
  final int totalBadges;
  final List<NutritionBadge> recentBadges;
  final Map<String, int> challengeStats; // completed, inProgress, failed

  UserGamificationStats({
    this.totalXp = 0,
    this.currentLevel = 1,
    this.xpToNextLevel = 100,
    this.challengesCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badgesEarned = 0,
    this.totalBadges = 0,
    this.recentBadges = const [],
    this.challengeStats = const {},
  });

  UserGamificationStats copyWith({
    int? totalXp,
    int? currentLevel,
    int? xpToNextLevel,
    int? challengesCompleted,
    int? currentStreak,
    int? longestStreak,
    int? badgesEarned,
    int? totalBadges,
    List<NutritionBadge>? recentBadges,
    Map<String, int>? challengeStats,
  }) {
    return UserGamificationStats(
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      badgesEarned: badgesEarned ?? this.badgesEarned,
      totalBadges: totalBadges ?? this.totalBadges,
      recentBadges: recentBadges ?? this.recentBadges,
      challengeStats: challengeStats ?? this.challengeStats,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalXp': totalXp,
    'currentLevel': currentLevel,
    'xpToNextLevel': xpToNextLevel,
    'challengesCompleted': challengesCompleted,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'badgesEarned': badgesEarned,
    'totalBadges': totalBadges,
    'recentBadges': recentBadges.map((b) => b.toJson()).toList(),
    'challengeStats': challengeStats,
  };

  factory UserGamificationStats.fromJson(Map<String, dynamic> json) {
    return UserGamificationStats(
      totalXp: json['totalXp'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 100,
      challengesCompleted: json['challengesCompleted'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      badgesEarned: json['badgesEarned'] as int? ?? 0,
      totalBadges: json['totalBadges'] as int? ?? 0,
      recentBadges: (json['recentBadges'] as List?)
              ?.map((e) => NutritionBadge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      challengeStats: (json['challengeStats'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as int)) ??
          {},
    );
  }

  /// Calculate level from XP
  static int calculateLevel(int xp) {
    if (xp < 100) return 1;
    return (xp / 100).floor() + 1;
  }

  /// XP needed for next level
  static int xpForNextLevel(int currentLevel) {
    return currentLevel * 100;
  }

  /// Progress within current level (0.0 - 1.0)
  double get levelProgress {
    final xpForThisLevel = xpForNextLevel(currentLevel - 1);
    final xpForCurrentLevel = xpForNextLevel(currentLevel);
    final xpInLevel = totalXp - xpForThisLevel;
    final xpNeeded = xpForCurrentLevel - xpForThisLevel;
    if (xpNeeded <= 0) return 1.0;
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  }

  String get levelTitle {
    if (currentLevel <= 3) return 'مبتدئ';
    if (currentLevel <= 6) return 'متقدم';
    if (currentLevel <= 10) return 'خبير';
    if (currentLevel <= 15) return 'محترف';
    return 'أسطورة';
  }
}

/// Default badges library
class BadgeLibrary {
  static List<NutritionBadge> getDefaultBadges() {
    return [
      // Streak badges
      NutritionBadge(
        id: 'badge_streak_3',
        name: 'بداية قوية',
        description: 'تسجيل الوجبات لمدة 3 أيام متتالية',
        icon: '🔥',
        type: BadgeType.streak,
        xpRequired: 30,
      ),
      NutritionBadge(
        id: 'badge_streak_7',
        name: 'أسبوع من الالتزام',
        description: 'تسجيل الوجبات لمدة 7 أيام متتالية',
        icon: '⭐',
        type: BadgeType.streak,
        xpRequired: 100,
      ),
      NutritionBadge(
        id: 'badge_streak_30',
        name: 'شهر كامل',
        description: 'تسجيل الوجبات لمدة 30 يوماً متتالية',
        icon: '🏆',
        type: BadgeType.streak,
        xpRequired: 500,
      ),
      NutritionBadge(
        id: 'badge_streak_100',
        name: 'مئة يوم',
        description: 'تسجيل الوجبات لمدة 100 يوم متتالية',
        icon: '👑',
        type: BadgeType.streak,
        xpRequired: 2000,
      ),

      // Achievement badges
      NutritionBadge(
        id: 'badge_first_meal',
        name: 'أول وجبة',
        description: 'تسجيل أول وجبة في التطبيق',
        icon: '🍽️',
        type: BadgeType.achievement,
        xpRequired: 10,
      ),
      NutritionBadge(
        id: 'badge_veggie_lover',
        name: 'عاشق الخضار',
        description: 'تناول 5 حصص خضار في يوم واحد',
        icon: '🥗',
        type: BadgeType.achievement,
        xpRequired: 100,
      ),
      NutritionBadge(
        id: 'badge_protein_master',
        name: 'خبير البروتين',
        description: 'تحقيق هدف البروتين لمدة أسبوع',
        icon: '🥩',
        type: BadgeType.achievement,
        xpRequired: 200,
      ),
      NutritionBadge(
        id: 'badge_calorie_king',
        name: 'ملك السعرات',
        description: 'تحقيق هدف السعرات بدقة لمدة 7 أيام',
        icon: '🎯',
        type: BadgeType.achievement,
        xpRequired: 200,
      ),

      // Milestone badges
      NutritionBadge(
        id: 'badge_50_meals',
        name: '50 وجبة',
        description: 'تسجيل 50 وجبة في التطبيق',
        icon: '📊',
        type: BadgeType.milestone,
        xpRequired: 150,
      ),
      NutritionBadge(
        id: 'badge_100_meals',
        name: '100 وجبة',
        description: 'تسجيل 100 وجبة في التطبيق',
        icon: '💯',
        type: BadgeType.milestone,
        xpRequired: 300,
      ),
      NutritionBadge(
        id: 'badge_500_meals',
        name: '500 وجبة',
        description: 'تسجيل 500 وجبة في التطبيق',
        icon: '🏅',
        type: BadgeType.milestone,
        xpRequired: 1000,
      ),

      // Challenge badges
      NutritionBadge(
        id: 'badge_balanced_week',
        name: 'أسبوع متوازن',
        description: 'إكمال تحدي الأسبوع المتوازن',
        icon: '⚖️',
        type: BadgeType.challenge,
        xpRequired: 300,
      ),
      NutritionBadge(
        id: 'badge_hydration_hero',
        name: 'بطل الترطيب',
        description: 'إكمال تحدي الترطيب الأسبوعي',
        icon: '💧',
        type: BadgeType.challenge,
        xpRequired: 250,
      ),
      NutritionBadge(
        id: 'badge_sugar_free',
        name: 'متحدي السكر',
        description: 'إكمال تحدي يوم بدون سكر',
        icon: '🚫',
        type: BadgeType.challenge,
        xpRequired: 100,
      ),
      NutritionBadge(
        id: 'badge_month_streak',
        name: 'أسطورة الاستمرارية',
        description: 'إكمال تحدي التسجيل لمدة شهر',
        icon: '🔥',
        type: BadgeType.challenge,
        xpRequired: 1000,
      ),
      NutritionBadge(
        id: 'badge_variety_expert',
        name: 'خبير التنويع',
        description: 'إكمال تحدي تنويع الطعام',
        icon: '🎯',
        type: BadgeType.challenge,
        xpRequired: 800,
      ),
      NutritionBadge(
        id: 'badge_chef',
        name: 'طاهي التغذية',
        description: 'إكمال تحدي تحضير الوجبات',
        icon: '👨‍🍳',
        type: BadgeType.challenge,
        xpRequired: 500,
      ),

      // Special badges
      NutritionBadge(
        id: 'badge_early_adopter',
        name: 'أحد الأوائل',
        description: 'من أوائل مستخدمي التطبيق',
        icon: '🌟',
        type: BadgeType.special,
        xpRequired: 50,
      ),
      NutritionBadge(
        id: 'badge_consistency',
        name: 'التميز في الاستمرار',
        description: 'تسجيل جميع الوجبات لمدة أسبوع كامل',
        icon: '💪',
        type: BadgeType.special,
        xpRequired: 400,
      ),
      // Hidden badge (isSecret = true)
      NutritionBadge(
        id: 'badge_midnight_logger',
        name: 'مسجل منتصف الليل',
        description: 'تسجيل وجبة بعد منتصف الليل',
        icon: '🌙',
        type: BadgeType.hidden,
        xpRequired: 50,
        isSecret: true,
      ),
    ];
  }
}