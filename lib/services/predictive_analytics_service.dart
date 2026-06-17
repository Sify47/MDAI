// lib/services/predictive_analytics_service.dart
// ITEM 3: Predictive Nutrition Analytics
// ITEM 4: Visual Data Exploration (data aggregation)
//
// Analyzes historical nutrition data to predict trends,
// identify patterns, and generate visual data sets.

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ai_models.dart';
import '../models/nutrition_model.dart';
import 'nutrition_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PredictiveAnalyticsService {
  static const String _historyPrefKey = 'predictive_nutrition_history';
  static const String _reportCacheKey = 'predictive_last_report';

  // ═══════════════════════════════════════════════════════════
  // ITEM 3: PREDICTIVE NUTRITION ANALYTICS
  // ═══════════════════════════════════════════════════════════

  /// Generate a complete nutrition prediction report
  static Future<NutritionPredictionReport> generatePredictionReport({
    required UserNutritionData userData,
    int lookbackDays = 30,
    int forecastDays = 7,
  }) async {
    // Gather historical data
    final historicalData = await _loadHistoricalData(lookbackDays);

    // Calculate trends
    final trends = _calculateTrends(historicalData, forecastDays);

    // Predict deficiencies
    final deficiencies = _predictDeficiencies(historicalData, userData);

    // Calculate overall score
    final overallScore = _calculateOverallScore(historicalData, userData);

    // Generate assessments
    final assessment = _generateOverallAssessment(overallScore, trends, deficiencies);
    final recommendations = _generateRecommendations(trends, deficiencies, userData);

    // Generate weekly forecast
    final forecast = _generateWeeklyForecast(historicalData, forecastDays);

    final report = NutritionPredictionReport(
      generatedAt: DateTime.now(),
      periodStart: DateTime.now().subtract(Duration(days: lookbackDays)),
      periodEnd: DateTime.now().add(Duration(days: forecastDays)),
      trends: trends,
      predictedDeficiencies: deficiencies,
      overallScore: overallScore,
      overallAssessment: assessment,
      actionableRecommendations: recommendations,
      weeklyCalorieForecast: forecast['calories']!,
      weeklyProteinForecast: forecast['protein']!,
      weeklyCarbsForecast: forecast['carbs']!,
      weeklyFatForecast: forecast['fat']!,
    );

    // Cache the report
    await _cacheReport(report);

    return report;
  }

  /// Get a quick health score (0-100) for dashboard display
  static Future<double> getHealthScore(UserNutritionData userData) async {
    final historicalData = await _loadHistoricalData(14);
    if (historicalData.isEmpty) return 50.0; // Default mid-range

    return _calculateOverallScore(historicalData, userData);
  }

  /// Get quick trends for dashboard display
  static Future<List<NutritionTrend>> getQuickTrends({
    int lookbackDays = 14,
    int forecastDays = 3,
  }) async {
    final historicalData = await _loadHistoricalData(lookbackDays);
    return _calculateTrends(historicalData, forecastDays);
  }

  /// Get today's predicted completion status
  static Future<Map<String, double>> getTodayPrediction({
    required double currentCalories,
    required double currentProtein,
    required double currentCarbs,
    required double currentFat,
    required double targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
  }) async {
    final historicalData = await _loadHistoricalData(7);
    final avgCompletion = _calculateAverageCompletionRate(historicalData);

    return {
      'calories_prediction': avgCompletion['calories']!,
      'protein_prediction': avgCompletion['protein']!,
      'carbs_prediction': avgCompletion['carbs']!,
      'fat_prediction': avgCompletion['fat']!,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // ITEM 4: VISUAL DATA EXPLORATION (data aggregation)
  // ═══════════════════════════════════════════════════════════

  /// Get chart data for daily nutrition trends (last N days)
  static Future<List<NutritionChartData>> getDailyTrendCharts({
    int days = 14,
  }) async {
    final historicalData = await _loadHistoricalData(days);
    if (historicalData.isEmpty) return [];

    final charts = <NutritionChartData>[
      _buildCalorieTrendChart(historicalData, days),
      _buildMacroBreakdownChart(historicalData, days),
      _buildGoalProgressChart(historicalData),
    ];

    return charts;
  }

  /// Get weekly comparison chart data
  static Future<List<NutritionChartData>> getWeeklyComparisonCharts() async {
    final historicalData = await _loadHistoricalData(14);
    if (historicalData.isEmpty) return [];

    return [
      _buildWeeklyComparisonChart(historicalData),
      _buildNutrientTimelineChart(historicalData),
    ];
  }

  /// Get heat map data for meal logging consistency
  static Future<List<NutritionChartData>> getConsistencyCharts({
    int days = 30,
  }) async {
    final historicalData = await _loadHistoricalData(days);
    if (historicalData.isEmpty) return [];

    return [
      _buildConsistencyHeatmap(historicalData, days),
      _buildStreakCalendar(historicalData, days),
    ];
  }

  /// Get radar chart data for macro balance
  static Future<NutritionChartData> getRadarChartData({
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
  }) async {
    final today = await NutritionService.getTodayMeals();
    final currentProtein = (today?['total_protein'] as num?)?.toDouble() ?? 0;
    final currentCarbs = (today?['total_carbs'] as num?)?.toDouble() ?? 0;
    final currentFat = (today?['total_fat'] as num?)?.toDouble() ?? 0;

    final proteinPct = targetProtein > 0
        ? (currentProtein / targetProtein * 100).clamp(0, 100).toDouble()
        : 0.0;
    final carbsPct = targetCarbs > 0
        ? (currentCarbs / targetCarbs * 100).clamp(0, 100).toDouble()
        : 0.0;
    final fatPct = targetFat > 0
        ? (currentFat / targetFat * 100).clamp(0, 100).toDouble()
        : 0.0;

    final current = DataSeries(
      name: 'اليوم',
      unit: '%',
      points: [
        DataPoint(date: DateTime.now(), label: 'بروتين', value: proteinPct),
        DataPoint(date: DateTime.now(), label: 'كارب', value: carbsPct),
        DataPoint(date: DateTime.now(), label: 'دهون', value: fatPct),
      ],
      seriesColor: const Color(0xFF1565C0),
    );

    return NutritionChartData(
      title: 'توازن الماكروز',
      subtitle: 'نسبة تحقيق الهدف اليومي',
      type: VisualizationType.radarChart,
      series: [current],
      insights: [
        if (proteinPct >= 90) '✓ نسبة البروتين ممتازة',
        if (proteinPct < 70) '⚠ البروتين أقل من المطلوب',
        if (carbsPct >= 90) '✓ نسبة الكربوهيدرات ممتازة',
        if (carbsPct < 70) '⚠ الكربوهيدرات أقل من المطلوب',
        if (fatPct >= 90) '✓ نسبة الدهون ممتازة',
        if (fatPct < 70) '⚠ الدهون أقل من المطلوب',
        if (proteinPct >= 90 && carbsPct >= 90 && fatPct >= 90)
          '🎯 توازن غذائي مثالي اليوم!',
      ],
    );
  }

  /// Get a summary of nutrition data for insights
  static Future<Map<String, dynamic>> getNutritionInsights({
    required String goal,
    int days = 30,
  }) async {
    final historicalData = await _loadHistoricalData(days);
    if (historicalData.isEmpty) {
      return {
        'total_meals_logged': 0,
        'average_calories': 0,
        'most_consistent_meal': 'لا توجد بيانات كافية',
        'best_day': 'لا توجد بيانات كافية',
        'consistency_rate': 0,
        'top_tip': 'ابدأ بتسجيل وجباتك للحصول على تحليلات مخصصة',
      };
    }

    // Calculate metrics
    int totalDays = historicalData.length;
    int daysWithMeals = historicalData.where((d) => d['meals_count'] != null && (d['meals_count'] as num) > 0).length;
    double consistencyRate = totalDays > 0 ? (daysWithMeals / totalDays) * 100 : 0;

    double avgCalories = 0;
    if (historicalData.isNotEmpty) {
      avgCalories = historicalData
              .map((d) => (d['total_calories'] as num?)?.toDouble() ?? 0)
              .reduce((a, b) => a + b) /
          historicalData.length;
    }

    // Find best day by calorie target achievement
    String bestDay = 'لا توجد بيانات';
    double bestRate = 0;
    for (final day in historicalData) {
      final cal = (day['total_calories'] as num?)?.toDouble() ?? 0;
      final target = (day['target_calories'] as num?)?.toDouble() ?? 2000;
      final rate = target > 0 ? cal / target : 0.0;
      if (rate > bestRate && rate <= 1.2) {
        bestRate = rate;
        bestDay = day['date'] ?? '';
      }
    }

    // Most consistent meal type
    final mealTypeCounts = <String, int>{};
    for (final day in historicalData) {
      final meals = day['meals'] as List? ?? [];
      for (final meal in meals) {
        final type = (meal is Map ? meal['type'] : '') as String? ?? '';
        mealTypeCounts[type] = (mealTypeCounts[type] ?? 0) + 1;
      }
    }
    String mostConsistentMeal = 'غير محدد';
    int maxCount = 0;
    for (final entry in mealTypeCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostConsistentMeal = entry.key;
      }
    }

    // Generate tip
    String topTip = _generateInsightTip(consistencyRate, avgCalories, goal);

    return {
      'total_meals_logged': daysWithMeals,
      'average_calories': avgCalories,
      'most_consistent_meal': mostConsistentMeal,
      'best_day': bestDay,
      'consistency_rate': consistencyRate,
      'top_tip': topTip,
    };
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  /// Load historical nutrition data from local storage
  static Future<List<Map<String, dynamic>>> _loadHistoricalData(int days) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_historyPrefKey);
    if (data == null) return [];

    try {
      final rawList = data.split('|||').map((s) {
        if (s.isEmpty) return null;
        final parts = s.split('::');
        return <String, dynamic>{
          'date': parts[0],
          'total_calories': double.tryParse(parts[1]) ?? 0,
          'total_protein': double.tryParse(parts[2]) ?? 0,
          'total_carbs': double.tryParse(parts[3]) ?? 0,
          'total_fat': double.tryParse(parts[4]) ?? 0,
          'meals_count': int.tryParse(parts[5]) ?? 0,
          'target_calories': double.tryParse(parts.length > 6 ? parts[6] : '0') ?? 0,
          'meals': [],
        };
      }).whereType<Map<String, dynamic>>().toList();

      // Filter to recent days
      final cutoff = DateTime.now().subtract(Duration(days: days));
      return rawList.where((d) {
        final date = DateTime.tryParse(d['date'] ?? '');
        return date != null && date.isAfter(cutoff);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save daily nutrition snapshot to history
  static Future<void> saveDailySnapshot({
    required double totalCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    required int mealsCount,
    double targetCalories = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_historyPrefKey) ?? '';
    final today =
        '${DateTime.now().toIso8601String().split('T')[0]}::$totalCalories::$totalProtein::$totalCarbs::$totalFat::$mealsCount::$targetCalories';
    final updated = existing.isEmpty ? today : '$today|||$existing';

    // Keep only last 90 days
    final entries = updated.split('|||');
    if (entries.length > 90) {
      await prefs.setString(_historyPrefKey, entries.take(90).join('|||'));
    } else {
      await prefs.setString(_historyPrefKey, updated);
    }
  }

  /// Calculate trends from historical data
  static List<NutritionTrend> _calculateTrends(
    List<Map<String, dynamic>> data,
    int forecastDays,
  ) {
    if (data.length < 3) return [];

    final trends = <NutritionTrend>[];
    final metrics = ['total_calories', 'total_protein', 'total_carbs', 'total_fat'];
    final metricNames = ['السعرات', 'البروتين', 'الكربوهيدرات', 'الدهون'];
    final metricUnits = ['سعرة', 'جم', 'جم', 'جم'];

    for (int i = 0; i < metrics.length; i++) {
      final values = data
          .map((d) => (d[metrics[i]] as num?)?.toDouble() ?? 0)
          .toList();
      final dates = data
          .map((d) => DateTime.tryParse(d['date'] ?? '') ?? DateTime.now())
          .toList();

      if (values.isEmpty) continue;

      // Simple linear regression for trend direction
      final trend = _calculateLinearTrend(values);
      final currentValue = values.last;
      final predictedValue = currentValue + (trend * forecastDays);

      final changePercent = currentValue > 0
          ? ((predictedValue - currentValue) / currentValue * 100)
          : 0.0;

      final direction = trend > values.length * 0.1
          ? TrendDirection.increasing
          : trend < -values.length * 0.1
              ? TrendDirection.decreasing
              : _isFluctuating(values)
                  ? TrendDirection.fluctuating
                  : TrendDirection.stable;

      // Generate insight
      String insight = '';
      bool isAlert = false;
      switch (direction) {
        case TrendDirection.increasing:
          insight = '${metricNames[i]} في ارتفاع ملحوظ';
          if (metrics[i] == 'total_calories' && changePercent > 15) {
            insight = '⚠ ارتفاع كبير في السعرات الحرارية';
            isAlert = true;
          }
          break;
        case TrendDirection.decreasing:
          insight = '${metricNames[i]} في انخفاض';
          if (metrics[i] == 'total_calories' && changePercent.abs() > 15) {
            insight = '⚠ انخفاض كبير في السعرات - قد يؤثر على طاقتك';
            isAlert = true;
          }
          break;
        case TrendDirection.fluctuating:
          insight = '${metricNames[i]} متذبذب - حاول تحقيق الاستقرار';
          break;
        case TrendDirection.stable:
          insight = '👍 ${metricNames[i]} مستقر والأداء جيد';
          break;
      }

      trends.add(NutritionTrend(
        metricName: metricNames[i],
        metricUnit: metricUnits[i],
        historicalValues: values,
        historicalDates: dates,
        predictedValue: predictedValue,
        currentValue: currentValue,
        changePercent: changePercent,
        direction: direction,
        insight: insight,
        isAlert: isAlert,
      ));
    }

    return trends;
  }

  /// Predict potential deficiencies
  static List<PredictedDeficiency> _predictDeficiencies(
    List<Map<String, dynamic>> data,
    UserNutritionData userData,
  ) {
    final deficiencies = <PredictedDeficiency>[];

    if (data.length < 5) return deficiencies;

    // Check protein deficiency
    final proteinValues = data
        .map((d) => (d['total_protein'] as num?)?.toDouble() ?? 0)
        .toList();
    final avgProtein = proteinValues.isEmpty
        ? 0.0
        : proteinValues.reduce((a, b) => a + b) / proteinValues.length;

    // Estimate target protein from user data
    final targetCalories = userData.targetCalories;
    double targetProtein = targetCalories * 0.25 / 4; // ~25% of calories from protein
    if (targetProtein > 0 && avgProtein < targetProtein * 0.7) {
      deficiencies.add(PredictedDeficiency(
        nutrient: 'بروتين',
        icon: '🥩',
        riskScore: 1.0 - (avgProtein / targetProtein),
        expectedDate: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        description: 'متوسط استهلاك البروتين أقل من الموصى به',
        preventiveActions: [
          'أضف مصدر بروتين لكل وجبة',
          'تناول البيض أو الزبادي في الفطور',
          'وزع البروتين على مدار اليوم',
        ],
      ));
    }

    // Check fiber (from carbs composition)
    final carbValues = data
        .map((d) => (d['total_carbs'] as num?)?.toDouble() ?? 0)
        .toList();
    final avgCarbs = carbValues.isEmpty
        ? 0.0
        : carbValues.reduce((a, b) => a + b) / carbValues.length;

    // High carb might indicate low fiber
    if (avgCarbs > targetCalories * 0.5 / 4) {
      deficiencies.add(PredictedDeficiency(
        nutrient: 'ألياف',
        icon: '🥬',
        riskScore: 0.4,
        expectedDate: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        description: 'نسبة الكربوهيدرات مرتفعة - قد تكون الألياف منخفضة',
        preventiveActions: [
          'أضف الخضروات الورقية',
          'تناول الفواكه بقشرها',
          'اختر الحبوب الكاملة',
        ],
      ));
    }

    // Check fat
    final fatValues = data
        .map((d) => (d['total_fat'] as num?)?.toDouble() ?? 0)
        .toList();
    final avgFat = fatValues.isEmpty
        ? 0.0
        : fatValues.reduce((a, b) => a + b) / fatValues.length;
    double targetFat = targetCalories * 0.30 / 9; // ~30% of calories from fat

    if (avgFat < targetFat * 0.6) {
      deficiencies.add(PredictedDeficiency(
        nutrient: 'دهون صحية',
        icon: '🥑',
        riskScore: 0.5,
        expectedDate: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        description: 'الدهون الصحية أقل من المستوى الموصى به',
        preventiveActions: [
          'أضف زيت زيتون للسلطة',
          'تناول المكسرات كسناك',
          'أضف الأفوكادو لوجباتك',
        ],
      ));
    }

    // Check overall calorie deficit for weight gain goal
    final calValues = data
        .map((d) => (d['total_calories'] as num?)?.toDouble() ?? 0)
        .toList();
    final avgCal = calValues.isEmpty
        ? 0.0
        : calValues.reduce((a, b) => a + b) / calValues.length;

    if (userData.goal == 'زيادة' && avgCal < targetCalories * 0.9) {
      deficiencies.add(PredictedDeficiency(
        nutrient: 'طاقة',
        icon: '🔥',
        riskScore: 0.6,
        expectedDate: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        description: 'السعرات الحرارية أقل من المطلوب لزيادة الوزن',
        preventiveActions: [
          'تناول وجبات أكبر حجماً',
          'أضف سناك بين الوجبات',
          'ركّز على الأطعمة الغنية بالطاقة',
        ],
      ));
    }

    return deficiencies;
  }

  /// Calculate overall nutrition score (0-100)
  static double _calculateOverallScore(
    List<Map<String, dynamic>> data,
    UserNutritionData userData,
  ) {
    if (data.isEmpty) return 50.0;

    double score = 0;
    int factors = 0;

    // Factor 1: Consistency (30 points)
    final daysWithMeals = data.where((d) => ((d['meals_count'] as num?)?.toInt() ?? 0) > 0).length;
    final consistencyScore = data.isNotEmpty ? (daysWithMeals / data.length) * 30 : 0;
    score += consistencyScore;
    factors++;

    // Factor 2: Calorie target achievement (30 points)
    final targetCal = userData.targetCalories > 0 ? userData.targetCalories : 2000;
    double calScore = 0;
    int calDays = 0;
    for (final day in data) {
      final cal = (day['total_calories'] as num?)?.toDouble() ?? 0;
      if (cal > 0) {
        final rate = cal / targetCal;
        if (rate >= 0.7 && rate <= 1.2) {
          calScore += 30;
        } else if (rate >= 0.5 || rate <= 1.5) {
          calScore += 15;
        }
        calDays++;
      }
    }
    if (calDays > 0) {
      score += calScore / calDays;
      factors++;
    }

    // Factor 3: Macro balance (20 points)
    double macroScore = 0;
    int macroDays = 0;
    for (final day in data) {
      final p = (day['total_protein'] as num?)?.toDouble() ?? 0;
      final c = (day['total_carbs'] as num?)?.toDouble() ?? 0;
      final f = (day['total_fat'] as num?)?.toDouble() ?? 0;
      final totalCal = (day['total_calories'] as num?)?.toDouble() ?? 0;
      if (totalCal > 0 && p > 0 && c > 0 && f > 0) {
        final pPct = (p * 4) / totalCal;
        final cPct = (c * 4) / totalCal;
        final fPct = (f * 9) / totalCal;
        if (pPct >= 0.15 && pPct <= 0.35 &&
            cPct >= 0.30 && cPct <= 0.60 &&
            fPct >= 0.15 && fPct <= 0.40) {
          macroScore += 20;
        } else {
          macroScore += 10;
        }
        macroDays++;
      }
    }
    if (macroDays > 0) {
      score += macroScore / macroDays;
      factors++;
    }

    // Factor 4: Trend stability (20 points)
    if (data.length >= 7) {
      final recentCal = data
          .takeLast(7)
          .map((d) => (d['total_calories'] as num?)?.toDouble() ?? 0)
          .toList();
      final std = _calculateStdDev(recentCal);
      final mean = recentCal.isEmpty ? 0 : recentCal.reduce((a, b) => a + b) / recentCal.length;
      final cv = mean > 0 ? std / mean : 1;
      if (cv < 0.3) {
        score += 20;
      } else if (cv < 0.5) {
        score += 10;
      }
      factors++;
    }

    return factors > 0 ? (score / factors).clamp(0, 100).roundToDouble() : 50.0;
  }

  /// Generate overall assessment text
  static String _generateOverallAssessment(
    double score,
    List<NutritionTrend> trends,
    List<PredictedDeficiency> deficiencies,
  ) {
    if (score >= 80) {
      return 'أداء غذائي ممتاز! استمر في الحفاظ على توازنك الغذائي';
    } else if (score >= 60) {
      return 'أداء جيد. هناك مجال للتحسين في بعض الجوانب';
    } else if (score >= 40) {
      return 'أداء متوسط. حاول تحسين انتظام وتسجيل وجباتك';
    } else {
      return 'تحتاج لتحسين عاداتك الغذائية. ابدأ بتسجيل وجباتك بانتظام';
    }
  }

  /// Generate actionable recommendations
  static List<String> _generateRecommendations(
    List<NutritionTrend> trends,
    List<PredictedDeficiency> deficiencies,
    UserNutritionData userData,
  ) {
    final recs = <String>[];

    for (final trend in trends) {
      if (trend.isAlert) {
        recs.add(trend.insight);
      }
    }

    for (final def in deficiencies) {
      if (def.riskScore >= 0.5) {
        recs.addAll(def.preventiveActions.take(2));
      }
    }

    if (userData.goal == 'تخسيس' && recs.isEmpty) {
      recs.add('استمر في نقص السعرات - أداؤك جيد');
    } else if (userData.goal == 'زيادة' && recs.isEmpty) {
      recs.add('حاول زيادة السعرات اليومية بشكل تدريجي');
    }

    if (recs.isEmpty) {
      recs.add('حافظ على توازن وجباتك بين البروتين والكارب والخضار');
    }

    return recs.take(5).toList();
  }

  /// Generate weekly forecast map
  static Map<String, Map<String, double>> _generateWeeklyForecast(
    List<Map<String, dynamic>> data,
    int forecastDays,
  ) {
    final forecast = <String, Map<String, double>>{};
    final metrics = ['calories', 'protein', 'carbs', 'fat'];
    final keys = ['total_calories', 'total_protein', 'total_carbs', 'total_fat'];

    for (int i = 0; i < metrics.length; i++) {
      final values = data
          .map((d) => (d[keys[i]] as num?)?.toDouble() ?? 0)
          .toList();
      final trend = _calculateLinearTrend(values);
      final lastValue = values.isNotEmpty ? values.last : 0;

      final dayForecast = <String, double>{};
      for (int day = 1; day <= forecastDays; day++) {
        final predicted = lastValue + (trend * day);
        dayForecast['day_$day'] = predicted.clamp(0, 5000).toDouble();
      }
      forecast[metrics[i]] = dayForecast;
    }

    return forecast;
  }

  /// Build calorie trend chart
  static NutritionChartData _buildCalorieTrendChart(
    List<Map<String, dynamic>> data,
    int days,
  ) {
    final points = <DataPoint>[];
    final targetPoints = <DataPoint>[];

    for (int i = 0; i < min(data.length, days); i++) {
      final day = data[i];
      final date = DateTime.tryParse(day['date'] ?? '') ?? DateTime.now();
      final cal = (day['total_calories'] as num?)?.toDouble() ?? 0;
      final target = (day['target_calories'] as num?)?.toDouble() ?? 2000;
      points.add(DataPoint(
        date: date,
        label: '${date.day}/${date.month}',
        value: cal,
      ));
      targetPoints.add(DataPoint(
        date: date,
        label: '${date.day}/${date.month}',
        value: target,
      ));
    }

    return NutritionChartData(
      title: 'اتجاه السعرات الحرارية',
      subtitle: 'آخر $days يوم',
      type: VisualizationType.dailyTrend,
      series: [
        DataSeries(
          name: 'السعرات',
          unit: 'سعرة',
          points: points,
          seriesColor: const Color(0xFFFF9800),
        ),
        DataSeries(
          name: 'الهدف',
          unit: 'سعرة',
          points: targetPoints,
          seriesColor: const Color(0xFF43A047),
        ),
      ],
      insights: [
        if (points.isNotEmpty) 'متوسط السعرات: ${points.map((p) => p.value).reduce((a, b) => a + b) ~/ points.length}',
        'حقق توازن السعرات للحفاظ على هدفك',
      ],
    );
  }

  /// Build macro breakdown chart
  static NutritionChartData _buildMacroBreakdownChart(
    List<Map<String, dynamic>> data,
    int days,
  ) {
    final proteinPoints = <DataPoint>[];
    final carbsPoints = <DataPoint>[];
    final fatPoints = <DataPoint>[];

    for (int i = 0; i < min(data.length, days); i++) {
      final day = data[i];
      final date = DateTime.tryParse(day['date'] ?? '') ?? DateTime.now();
      proteinPoints.add(DataPoint(
        date: date,
        label: '${date.day}/${date.month}',
        value: (day['total_protein'] as num?)?.toDouble() ?? 0,
      ));
      carbsPoints.add(DataPoint(
        date: date,
        label: '${date.day}/${date.month}',
        value: (day['total_carbs'] as num?)?.toDouble() ?? 0,
      ));
      fatPoints.add(DataPoint(
        date: date,
        label: '${date.day}/${date.month}',
        value: (day['total_fat'] as num?)?.toDouble() ?? 0,
      ));
    }

    return NutritionChartData(
      title: 'توزيع الماكروز',
      subtitle: 'بروتين - كارب - دهون',
      type: VisualizationType.macroBreakdown,
      series: [
        DataSeries(
          name: 'بروتين',
          unit: 'جم',
          points: proteinPoints,
          seriesColor: const Color(0xFF1565C0),
        ),
        DataSeries(
          name: 'كارب',
          unit: 'جم',
          points: carbsPoints,
          seriesColor: const Color(0xFFFF9800),
        ),
        DataSeries(
          name: 'دهون',
          unit: 'جم',
          points: fatPoints,
          seriesColor: const Color(0xFF43A047),
        ),
      ],
    );
  }

  /// Build goal progress chart
  static NutritionChartData _buildGoalProgressChart(
    List<Map<String, dynamic>> data,
  ) {
    final points = <DataPoint>[];
    for (int i = 0; i < min(data.length, 7); i++) {
      final day = data[data.length - 1 - i];
      final date = DateTime.tryParse(day['date'] ?? '') ?? DateTime.now();
      final cal = (day['total_calories'] as num?)?.toDouble() ?? 0;
      final target = (day['target_calories'] as num?)?.toDouble() ?? 2000;
      final pct = target > 0 ? (cal / target * 100).clamp(0, 100).toDouble() : 0.0;
      points.add(DataPoint(
        date: date,
        label: '${date.day}/${date.month}',
        value: pct,
      ));
    }
    points.sort((a, b) => a.date.compareTo(b.date));

    return NutritionChartData(
      title: 'نسبة تحقيق الهدف',
      subtitle: 'آخر 7 أيام',
      type: VisualizationType.goalProgress,
      series: [
        DataSeries(
          name: 'نسبة الإنجاز',
          unit: '%',
          points: points,
          seriesColor: const Color(0xFF1565C0),
        ),
      ],
      insights: [
        if (points.isNotEmpty && points.last.value >= 90) '🎯 أحسنت! حققت هدفك اليوم',
        if (points.isNotEmpty && points.last.value < 70) '💪 حاول زيادة سعراتك لتحقيق الهدف',
      ],
    );
  }

  /// Build weekly comparison chart
  static NutritionChartData _buildWeeklyComparisonChart(
    List<Map<String, dynamic>> data,
  ) {
    // Group by week
    final weekData = <String, double>{};
    for (final day in data) {
      final date = DateTime.tryParse(day['date'] ?? '');
      if (date == null) continue;
      final weekKey = '${date.year}-W${date.weekday}';
      final cal = (day['total_calories'] as num?)?.toDouble() ?? 0;
      weekData[weekKey] = (weekData[weekKey] ?? 0) + cal;
    }

    final weekPoints = weekData.entries.map((e) {
      return DataPoint(
        date: DateTime.now(),
        label: 'أسبوع ${e.key.split('-W').last}',
        value: e.value / (data.length > 7 ? 7 : 1),
      );
    }).toList();

    return NutritionChartData(
      title: 'مقارنة أسبوعية',
      subtitle: 'متوسط السعرات لكل أسبوع',
      type: VisualizationType.weeklyComparison,
      series: [
        DataSeries(
          name: 'متوسط السعرات',
          unit: 'سعرة',
          points: weekPoints,
          seriesColor: const Color(0xFF1565C0),
        ),
      ],
    );
  }

  /// Build nutrient timeline chart
  static NutritionChartData _buildNutrientTimelineChart(
    List<Map<String, dynamic>> data,
  ) {
    final points = <DataPoint>[];
    for (int i = 0; i < min(data.length, 30); i++) {
      final day = data[i];
      final date = DateTime.tryParse(day['date'] ?? '') ?? DateTime.now();
      final cal = (day['total_calories'] as num?)?.toDouble() ?? 0;
      points.add(DataPoint(
        date: date,
        label: '${date.day}/${date.month}',
        value: cal,
        secondaryValue: '${(day['total_protein'] as num?)?.toDouble() ?? 0} جم بروتين',
      ));
    }

    return NutritionChartData(
      title: 'الخط الزمني للتغذية',
      subtitle: 'آخر 30 يوم',
      type: VisualizationType.nutrientTimeline,
      series: [
        DataSeries(
          name: 'السعرات',
          unit: 'سعرة',
          points: points,
          seriesColor: const Color(0xFF1565C0),
        ),
      ],
      insights: [
        if (points.isNotEmpty) 'أعلى يوم: ${points.map((p) => p.value).reduce((a, b) => a > b ? a : b)} سعرة',
      ],
    );
  }

  /// Build consistency heatmap
  static NutritionChartData _buildConsistencyHeatmap(
    List<Map<String, dynamic>> data,
    int days,
  ) {
    final heatmapPoints = <DataPoint>[];

    for (int i = 0; i < min(data.length, days); i++) {
      final day = data[i];
      final date = DateTime.tryParse(day['date'] ?? '') ?? DateTime.now();
      final mealsCount = (day['meals_count'] as num?)?.toInt() ?? 0;
      heatmapPoints.add(DataPoint(
        date: date,
        label: '${date.day}/${date.month}',
        value: (mealsCount / 4).clamp(0, 1).toDouble(), // Normalize to 0-1
      ));
    }

    return NutritionChartData(
      title: 'خريطة تسجيل الوجبات',
      subtitle: 'توزيع أيام التسجيل',
      type: VisualizationType.heatmap,
      series: [
        DataSeries(
          name: 'تسجيل',
          unit: '',
          points: heatmapPoints,
          seriesColor: const Color(0xFF1565C0),
        ),
      ],
      insights: [
        '🎯 انتظام التسجيل = %${data.isEmpty ? 0 : (data.where((d) => ((d['meals_count'] as num?)?.toInt() ?? 0) > 0).length * 100 ~/ data.length)}',
      ],
    );
  }

  /// Build streak calendar
  static NutritionChartData _buildStreakCalendar(
    List<Map<String, dynamic>> data,
    int days,
  ) {
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    for (int i = 0; i < min(data.length, days); i++) {
      final day = data[i];
      final mealsCount = (day['meals_count'] as num?)?.toInt() ?? 0;
      if (mealsCount > 0) {
        tempStreak++;
        if (tempStreak > longestStreak) longestStreak = tempStreak;
      } else {
        tempStreak = 0;
      }
    }
    currentStreak = tempStreak;

    final streakPoints = <DataPoint>[];
    for (int i = 0; i < min(data.length, days); i++) {
      final day = data[i];
      final date = DateTime.tryParse(day['date'] ?? '') ?? DateTime.now();
      final mealsCount = (day['meals_count'] as num?)?.toInt() ?? 0;
      streakPoints.add(DataPoint(
        date: date,
        label: '${date.day}/${date.month}',
        value: mealsCount > 0 ? 1.0 : 0.0,
        color: mealsCount > 0 ? const Color(0xFF43A047) : const Color(0xFFE0E0E0),
      ));
    }

    return NutritionChartData(
      title: 'سجل الاستمرارية',
      subtitle: 'الأيام التي سجلت فيها وجبات',
      type: VisualizationType.streakCalendar,
      series: [
        DataSeries(
          name: 'استمرار',
          unit: 'يوم',
          points: streakPoints,
          seriesColor: const Color(0xFF43A047),
        ),
      ],
      insights: [
        '🔥 الاستمرار الحالي: $currentStreak يوم',
        if (longestStreak > 0) '🏆 أطول استمرار: $longestStreak يوم',
      ],
    );
  }

  /// Calculate average completion rates from historical data
  static Map<String, double> _calculateAverageCompletionRate(
    List<Map<String, dynamic>> data,
  ) {
    if (data.isEmpty) {
      return {
        'calories': 0.5,
        'protein': 0.5,
        'carbs': 0.5,
        'fat': 0.5,
      };
    }

    double calRate = 0, proRate = 0, carbRate = 0, fatRate = 0;
    int count = 0;

    for (final day in data) {
      final cal = (day['total_calories'] as num?)?.toDouble() ?? 0;
      final target = (day['target_calories'] as num?)?.toDouble() ?? 2000;
      if (cal > 0 && target > 0) {
        calRate += (cal / target).clamp(0, 1);
        count++;
      }
    }

    if (count > 0) {
      calRate /= count;
    }

    return {
      'calories': calRate.clamp(0, 1).toDouble(),
      'protein': proRate > 0 ? (proRate / count).clamp(0, 1).toDouble() : 0.5,
      'carbs': carbRate > 0 ? (carbRate / count).clamp(0, 1).toDouble() : 0.5,
      'fat': fatRate > 0 ? (fatRate / count).clamp(0, 1).toDouble() : 0.5,
    };
  }

  /// Generate an insight tip based on aggregated data
  static String _generateInsightTip(
    double consistencyRate,
    double avgCalories,
    String goal,
  ) {
    if (consistencyRate < 30) {
      return 'ابدأ بتسجيل وجباتك يومياً - هذا هو المفتاح لتحسين تغذيتك';
    }
    if (consistencyRate < 70) {
      return 'أحسنت بالتسجيل المنتظم! حاول ألا تفوت أي وجبة';
    }
    if (goal == 'تخسيس' && avgCalories > 2000) {
      return 'حاول تقليل سعراتك تدريجياً لتحقيق هدف التخسيس';
    }
    if (goal == 'زيادة' && avgCalories < 2000) {
      return 'زد من سعراتك الحرارية لتحقيق هدف زيادة الوزن';
    }
    return 'استمر في الحفاظ على توازنك الغذائي';
  }

  // ============================================
  // MATH HELPERS
  // ============================================

  /// Simple linear regression slope
  static double _calculateLinearTrend(List<double> values) {
    if (values.length < 2) return 0;
    final n = values.length;
    final indices = List.generate(n, (i) => i.toDouble());
    final sumX = indices.reduce((a, b) => a + b);
    final sumY = values.reduce((a, b) => a + b);
    final sumXY = indices.fold<double>(0, (sum, x) => sum + x * values[x.toInt()]);
    final sumX2 = indices.fold<double>(0, (sum, x) => sum + x * x);
    final denominator = n * sumX2 - sumX * sumX;
    if (denominator == 0) return 0;
    return (n * sumXY - sumX * sumY) / denominator;
  }

  /// Standard deviation
  static double _calculateStdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.fold<double>(0, (sum, v) => sum + (v - mean) * (v - mean)) / values.length;
    return sqrt(variance);
  }

  /// Check if values are fluctuating
  static bool _isFluctuating(List<double> values) {
    if (values.length < 4) return false;
    int directionChanges = 0;
    for (int i = 2; i < values.length; i++) {
      if ((values[i] - values[i - 1]).sign != (values[i - 1] - values[i - 2]).sign) {
        directionChanges++;
      }
    }
    return directionChanges >= values.length ~/ 2;
  }

  /// Clamp for double
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Min of two integers
  static int min(int a, int b) => a < b ? a : b;

  /// Cache the prediction report to SharedPreferences
  static Future<void> _cacheReport(NutritionPredictionReport report) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reportCacheKey,
      '${report.generatedAt.toIso8601String()}|||'
      '${report.overallScore}|||'
      '${report.overallAssessment}',
    );
  }
}

/// Extension to support takeLast on List
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return toList();
    return sublist(length - count);
  }
}