// lib/services/progress_calculator_service.dart

import 'dart:math';
import 'package:vita/models/nutrition_model.dart';
import 'package:vita/models/walking_model.dart';
import 'package:vita/services/weight_service.dart';
import 'package:vita/services/nutrition_api.dart';
import 'package:vita/services/walking_api.dart';
import 'package:vita/services/water_service.dart';
import 'package:vita/utils/prefs_helper.dart';

class ProgressCalculatorService {
  static const double CALORIES_PER_KG = 7700.0;
  static const double STEPS_CALORIES_PER_1000 = 30.0;

  static Future<ProgressComparison> calculateProgress({
    required int userId,
    required int days,
  }) async {
    // 1. جلب البيانات
    final nutrition = await NutritionService.getUserNutritionData();

    final walkingActivities = await WalkingService.getTodayActivities();
    final waterData = await WaterService.getTodayWater();
    final weightHistory = await WeightService.getWeightHistory(limit: 10);

    // 2. حساب التقدم المتوقع
    final expected = await _calculateExpectedProgress(
      nutrition: nutrition,
      walkingActivities: walkingActivities,
      waterData: waterData,
      days: days,
    );

    // 3. حساب التقدم الفعلي
    final actual = await _calculateActualProgress(
      weightHistory: weightHistory,
      goal: nutrition?.goal,
    );

    // 4. المقارنة
    final difference = actual - expected;

    return ProgressComparison(
      expectedWeightChange: expected,
      actualWeightChange: actual,
      difference: difference,
      isAchieving: actual >= expected,
      message: _generateMessage(expected, actual),
      details: _generateDetails(
        expected,
        actual,
        nutrition,
        walkingActivities,
        waterData,
      ),
    );
  }

  static Future<double> _calculateExpectedProgress({
    required UserNutritionData? nutrition,
    required List<WalkingActivity> walkingActivities,
    required Map<String, dynamic>? waterData,
    required int days,
  }) async {
    if (nutrition == null) return 0.0;

    double totalCalorieDeficit = 0;
    double totalCaloriesBurned = 0;
    double totalCaloriesConsumed = 0;

    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final mealsData = await NutritionService.getMealsByDate(date);

      double dayConsumed = 0;
      if (mealsData != null && mealsData['meals'] != null) {
        final meals = mealsData['meals'] as List;
        for (var meal in meals) {
          // ✅ تحويل آمن إلى double
          final calories = meal['total_calories'];
          if (calories is int) {
            dayConsumed += calories.toDouble();
          } else if (calories is double) {
            dayConsumed += calories;
          } else if (calories is num) {
            dayConsumed += calories.toDouble();
          }
        }
      }
      totalCaloriesConsumed += dayConsumed;
    }

    for (var activity in walkingActivities) {
      final burned = activity.caloriesBurned;
      if (burned is int) {
        totalCaloriesBurned += burned.toDouble();
      } else if (burned is double) {
        totalCaloriesBurned += burned;
      } else if (burned is num) {
        totalCaloriesBurned += burned.toDouble();
      }
    }

    double targetTotal = nutrition.targetCalories * days;
    totalCalorieDeficit =
        (targetTotal - totalCaloriesConsumed) + totalCaloriesBurned;

    double waterEffect = 0;
    double currentWater = 0.0;
    if (waterData != null && waterData['total'] != null) {
      final total = waterData['total'];
      if (total is int) {
        currentWater = total.toDouble();
      } else if (total is double) {
        currentWater = total;
      } else if (total is num) {
        currentWater = total.toDouble();
      }
    }

    double dailyWaterGoal = nutrition.waterIntake ?? 2.5;
    double avgWaterPerDay = days > 0 ? currentWater / days : 0;

    if (avgWaterPerDay >= dailyWaterGoal) {
      waterEffect = 0.1;
    } else if (avgWaterPerDay >= dailyWaterGoal * 0.7) {
      waterEffect = 0.05;
    }

    double expectedChange =
        (totalCalorieDeficit / CALORIES_PER_KG) * (1 + waterEffect);

    if (nutrition.goal == 'تخسيس') {
      return expectedChange > 0 ? expectedChange : 0;
    } else if (nutrition.goal == 'زيادة') {
      return expectedChange < 0 ? -expectedChange : 0;
    }

    return 0;
  }

  static Future<double> _calculateActualProgress({
    required List<Map<String, dynamic>> weightHistory,
    required String? goal,
  }) async {
    if (weightHistory.length < 2) return 0.0;

    // ✅ تحويل آمن إلى double
    double firstWeight = 0.0;
    double lastWeight = 0.0;

    final first = weightHistory.first['weight'];
    final last = weightHistory.last['weight'];

    if (first is int) {
      firstWeight = first.toDouble();
    } else if (first is double) {
      firstWeight = first;
    } else if (first is num) {
      firstWeight = first.toDouble();
    }

    if (last is int) {
      lastWeight = last.toDouble();
    } else if (last is double) {
      lastWeight = last;
    } else if (last is num) {
      lastWeight = last.toDouble();
    }

    final change = lastWeight - firstWeight;

    if (goal == 'تخسيس') {
      return change < 0 ? -change : 0;
    } else if (goal == 'زيادة') {
      return change > 0 ? change : 0;
    }

    return change.abs();
  }

  static String _generateMessage(double expected, double actual) {
    final difference = actual - expected;
    final absDifference = difference.abs().toStringAsFixed(1);

    if (difference > 0.5) {
      return '🎉 ممتاز! أنت تتقدم أفضل من المتوقع بـ $absDifference كجم';
    } else if (difference > 0) {
      return '✅ جيد جداً! أنت تتقدم حسب الخطة أو أفضل قليلاً';
    } else if (difference > -0.5) {
      return '⚠️ قريب من الهدف! حاول تحسين التزامك قليلاً';
    } else {
      return '⚠️ يحتاج تحسين! أنت متأخر عن الهدف بـ ${absDifference} كجم';
    }
  }

  static Map<String, dynamic> _generateDetails(
    double expected,
    double actual,
    UserNutritionData? nutrition,
    List<WalkingActivity> walkingActivities,
    Map<String, dynamic>? waterData,
  ) {
    double totalSteps = 0;
    for (var activity in walkingActivities) {
      totalSteps += activity.steps.toDouble();
    }

    double totalWater = 0.0;
    if (waterData != null && waterData['total'] != null) {
      final total = waterData['total'];
      if (total is int) {
        totalWater = total.toDouble();
      } else if (total is double) {
        totalWater = total;
      } else if (total is num) {
        totalWater = total.toDouble();
      }
    }

    return {
      'expected_weight_change': expected.toStringAsFixed(2),
      'actual_weight_change': actual.toStringAsFixed(2),
      'difference': (actual - expected).toStringAsFixed(2),
      'total_steps': totalSteps.round(),
      'total_water': totalWater.toStringAsFixed(1),
      'goal_type': nutrition?.goal ?? 'تخسيس',
      'recommendation': _getRecommendation(expected, actual),
    };
  }

  static String _getRecommendation(double expected, double actual) {
    final difference = actual - expected;

    if (difference > 0.3) {
      return 'استمر على هذا المنوال! أنت تحقق نتائج رائعة 💪';
    } else if (difference > -0.3) {
      return 'أنت على المسار الصحيح. حافظ على التزامك بالوجبات والرياضة 🎯';
    } else {
      return 'حاول زيادة نشاطك اليومي وتقليل السعرات قليلاً. لا تنس شرب الماء 🏃‍♂️';
    }
  }
}

class ProgressComparison {
  final double expectedWeightChange;
  final double actualWeightChange;
  final double difference;
  final bool isAchieving;
  final String message;
  final Map<String, dynamic> details;

  ProgressComparison({
    required this.expectedWeightChange,
    required this.actualWeightChange,
    required this.difference,
    required this.isAchieving,
    required this.message,
    required this.details,
  });
}
