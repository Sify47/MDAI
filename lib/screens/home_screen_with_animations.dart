// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vita/models/user_model.dart';
import 'package:vita/screens/activities/activities_dashboard.dart';
import 'package:vita/screens/analysis/ai_dashboard.dart';
import 'package:vita/screens/analysis/water_dashboard.dart';
import 'package:vita/screens/notification_history_screen.dart';
import 'package:vita/services/ai_service.dart';
import 'package:vita/services/nutrition_api.dart';
import 'package:vita/services/symptom_api.dart';
import 'package:vita/services/water_service.dart';
import 'package:vita/services/weight_service.dart';
import 'package:vita/services/cache_manager.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:vita/utils/prefs_helper.dart';

import '../../models/dashboard_model.dart';
import '../../models/walking_model.dart';
import '../../models/activity_model.dart';
import '../../widgets/animated_goal_card.dart';
import '../../widgets/animated_medications_card.dart';
import '../../widgets/animated_walking_card.dart';
import '../../widgets/animated_achievements_card.dart';
import '../../widgets/animated_symptoms_card.dart';
import '../../widgets/animated_activities_card.dart';
import '../../constants/colors.dart';
import '../../providers/theme_provider.dart';
import '../../services/medication_api.dart';
import '../../services/walking_api.dart';
import '../../services/activity_api.dart';
import '../../models/medication_model.dart';
import '../../models/nutrition_model.dart';
import '../../services/dynamic_targets_service.dart';
import '../../models/dynamic_target_model.dart';
import '../../screens/dynamic_targets/dynamic_targets_dashboard.dart';

class HomeScreenWithAnimations extends StatefulWidget {
  const HomeScreenWithAnimations({super.key});

  @override
  State<HomeScreenWithAnimations> createState() =>
      _HomeScreenWithAnimationsState();
}

class _HomeScreenWithAnimationsState extends State<HomeScreenWithAnimations>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  UserNutritionData? userNutritionData;
  User? _currentUser;
  DashboardData? _dashboardData;
  List<Activity> _todayActivities = [];

  bool _isLoading = true;
  String? _errorMessage;
  int _userId = 1;
  String username = 'أحمد';
  int _currentTipIndex = 0;
  MLPredictionData? _mlPrediction;

  // ========== Cache fields to reduce API calls ==========
  bool _mlPredictionFetched = false;
  Timer? _debounceTimer;
  // =====================================================

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _refreshAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.elasticOut),
    );

    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Debounce: prevent repeated refreshes when widget rebuilds
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _refreshData();
      }
    });
  }

  Future<double> _getTodayWaterAmount() async {
    // Use CacheManager to deduplicate and cache water data
    try {
      final waterData = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: 'home_water_today',
            fetch: () async => await WaterService.getTodayWater(),
            ttl: const Duration(minutes: 2),
            staleWhileRevalidate: true,
          );
      return (waterData?['total'] ?? 0.0).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> _getHealthScore() async {
    // Use CacheManager to deduplicate and cache health score
    try {
      final aiData = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: 'home_health_score',
            fetch: () async => await AIService.getAIDashboard(),
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );
      if (aiData != null && aiData['overall_health_score'] != null) {
        return aiData['overall_health_score'] as int;
      }
      // Calculate locally as fallback
      if (_dashboardData != null) {
        return _calculateLocalHealthScore();
      }
      return 70;
    } catch (e) {
      // Calculate locally as fallback on error
      if (_dashboardData != null) {
        return _calculateLocalHealthScore();
      }
      return 70;
    }
  }

  int _calculateLocalHealthScore() {
    final data = _dashboardData!;
    int score = 70;
    if (data.calories.percentage > 80) {
      score += 10;
    } else if (data.calories.percentage < 50) {
      score -= 10;
    }
    if (data.walking.percentage > 80) {
      score += 10;
    } else if (data.walking.percentage < 30) {
      score -= 10;
    }
    final medsTotal = data.medications.totalToday;
    final medsTaken = data.medications.taken;
    if (medsTotal > 0) {
      final medsRate = (medsTaken / medsTotal) * 100;
      if (medsRate > 80) {
        score += 10;
      } else if (medsRate < 50) {
        score -= 10;
      }
    }
    return score.clamp(0, 100);
  }

  Future<void> _loadInitialData() async {
    // Load user ID FIRST so NutritionService uses the correct user_id
    await _loadUserId();
    // _loadUserData is not needed here because _loadDashboardData()
    // (called at the end of _loadUserId) already fetches nutrition data
    // UserNutritionService + CacheManager handle deduplication automatically
  }

  
  Future<void> _loadUserId() async {
    if (!mounted) return;
    try {
      final user = await PrefsHelper.getUser();
      if (!mounted) return;
      if (user != null) {
        setState(() {
          _currentUser = user;
          username = user.name;
          _userId = user.id;
        });
      } else {
        final userData = PrefsHelper.getUserData();
        if (!mounted) return;
        setState(() {
          username = userData['name'] ?? 'أحمد';
          _userId = userData['id'] ?? 1;
        });
      }
    } catch (e) {
      setState(() {
        _userId = 1;
        username = 'أحمد';
      });
    }
    await _loadDashboardData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ============================================
  // ✅ دالة إعادة حساب الوزن المتوقع ديناميكياً
  // ============================================
  // ============================================
  // ✅ دالة مشتركة لحساب توقع الوزن من السعرات
  // ============================================
  static WeightProjectionResult _calculateWeightProjection({
    required double currentWeight,
    required double targetWeight,
    required double initialWeight,
    required String goal,
    required int weeksRemaining,
    required int consumedCalories,
    required int targetCalories,
  }) {
    double weeklyExpectedChange = 0;
    double expectedWeightChange = 0;
    double predictedWeight = currentWeight;
    String progressMessage = "";

    if (goal == 'تخسيس') {
      weeklyExpectedChange = ((targetCalories - consumedCalories) * 7) / 7700;
      expectedWeightChange = weeklyExpectedChange > 0
          ? weeklyExpectedChange
          : 0;
      predictedWeight = currentWeight - (expectedWeightChange * weeksRemaining);

      if (predictedWeight < targetWeight) predictedWeight = targetWeight;
      if (predictedWeight > currentWeight) predictedWeight = currentWeight;

      if (expectedWeightChange > 0) {
        progressMessage =
            "✅ بناءً على سعراتك، من المتوقع خسارة ${expectedWeightChange.toStringAsFixed(2)} كجم هذا الأسبوع";
      } else if (expectedWeightChange == 0) {
        if (consumedCalories > targetCalories) {
          progressMessage = "⚠️ سعراتك أعلى من الهدف، قد يزيد وزنك هذا الأسبوع";
        } else {
          progressMessage = "⚠️ سعراتك متوازنة، زد نشاطك لتحقيق الهدف";
        }
      } else {
        progressMessage = "⚠️ بناءً على سعراتك، قد يزيد وزنك هذا الأسبوع";
      }
    } else if (goal == 'زيادة') {
      weeklyExpectedChange = ((consumedCalories - targetCalories) * 7) / 7700;
      expectedWeightChange = weeklyExpectedChange > 0
          ? weeklyExpectedChange
          : 0;
      predictedWeight = currentWeight + (expectedWeightChange * weeksRemaining);

      if (predictedWeight > targetWeight) predictedWeight = targetWeight;
      if (predictedWeight < currentWeight) predictedWeight = currentWeight;

      if (expectedWeightChange > 0) {
        progressMessage =
            "✅ بناءً على سعراتك، من المتوقع زيادة ${expectedWeightChange.toStringAsFixed(2)} كجم هذا الأسبوع";
      } else if (expectedWeightChange == 0) {
        if (consumedCalories < targetCalories) {
          progressMessage = "⚠️ سعراتك أقل من الهدف، قد تخسر وزناً هذا الأسبوع";
        } else {
          progressMessage = "⚠️ سعراتك متوازنة، زد سعراتك لتحقيق الهدف";
        }
      } else {
        progressMessage = "⚠️ بناءً على سعراتك، قد تخسر وزناً هذا الأسبوع";
      }
    } else {
      progressMessage = "✅ هدفك هو تثبيت الوزن";
    }

    double totalExpectedChange = 0;
    double expectedWeightFromCalories = initialWeight;

    if (goal == 'تخسيس') {
      totalExpectedChange = expectedWeightChange * weeksRemaining;
      expectedWeightFromCalories = initialWeight - totalExpectedChange;
      if (expectedWeightFromCalories < targetWeight) {
        expectedWeightFromCalories = targetWeight;
      }
      if (expectedWeightFromCalories > initialWeight) {
        expectedWeightFromCalories = initialWeight;
      }
    } else if (goal == 'زيادة') {
      totalExpectedChange = expectedWeightChange * weeksRemaining;
      expectedWeightFromCalories = initialWeight + totalExpectedChange;
      if (expectedWeightFromCalories > targetWeight) {
        expectedWeightFromCalories = targetWeight;
      }
      if (expectedWeightFromCalories < initialWeight) {
        expectedWeightFromCalories = initialWeight;
      }
    } else {
      expectedWeightFromCalories = initialWeight;
    }

    final weightDifference = currentWeight - expectedWeightFromCalories;

    String weightAdvice = "";
    if (goal == 'تخسيس') {
      if (weightDifference > 0.5) {
        weightAdvice =
            "⚠️ أنت متأخر ${weightDifference.toStringAsFixed(1)} كجم عن المتوقع. حاول تقليل 200 سعرة إضافية يومياً.";
      } else if (weightDifference < -0.5) {
        weightAdvice =
            "🎉 ممتاز! أنت متقدم ${weightDifference.abs().toStringAsFixed(1)} كجم عن المتوقع. استمر على هذا المنوال.";
      } else {
        weightAdvice =
            "✅ أنت على المسار الصحيح. استمر في متابعة سعراتك وخطواتك.";
      }
    } else if (goal == 'زيادة') {
      if (weightDifference < -0.5) {
        weightAdvice =
            "⚠️ أنت متأخر ${weightDifference.abs().toStringAsFixed(1)} كجم عن المتوقع. حاول زيادة 300 سعرة إضافية يومياً.";
      } else if (weightDifference > 0.5) {
        weightAdvice =
            "🎉 ممتاز! أنت متقدم ${weightDifference.toStringAsFixed(1)} كجم عن المتوقع. استمر على هذا المنوال.";
      } else {
        weightAdvice = "✅ أنت على المسار الصحيح. استمر في متابعة سعراتك.";
      }
    } else {
      weightAdvice = "✅ أنت على المسار الصحيح. استمر في متابعة وزنك.";
    }

    return WeightProjectionResult(
      expectedWeightChange: expectedWeightChange,
      predictedWeight: predictedWeight,
      progressMessage: progressMessage,
      expectedWeightFromCalories: expectedWeightFromCalories,
      weightDifference: weightDifference,
      weightAdvice: weightAdvice,
    );
  }

  // ============================================
  // ✅ تطبيق توقع الوزن على _dashboardData
  // ============================================
  void _applyWeightProjection(WeightProjectionResult projection) {
    if (_dashboardData == null) return;
    final data = _dashboardData!;
    setState(() {
      _dashboardData = DashboardData(
        user: data.user,
        progress: data.progress,
        calories: data.calories,
        walking: data.walking,
        medications: data.medications,
        symptoms: data.symptoms,
        achievements: data.achievements,
        workSchedule: data.workSchedule,
        expectedWeightChange: projection.expectedWeightChange,
        predictedWeight: projection.predictedWeight,
        progressMessage: projection.progressMessage,
        expectedWeightFromCalories: projection.expectedWeightFromCalories,
        weightDifference: projection.weightDifference,
        weightAdvice: projection.weightAdvice,
        mlPrediction: _mlPrediction,
      );
    });
  }

  // ============================================
  // ✅ إعادة حساب الوزن المتوقع ديناميكياً
  // ============================================
  void _recalculateWeightProjection() {
    if (_dashboardData == null) return;
    final data = _dashboardData!;
    final projection = _calculateWeightProjection(
      currentWeight: data.user.currentWeight.toDouble(),
      targetWeight: data.user.targetWeight.toDouble(),
      initialWeight:
          data.user.initialWeight ?? data.user.currentWeight.toDouble(),
      goal: data.user.goalType,
      weeksRemaining: data.progress.weeksRemaining,
      consumedCalories: data.calories.consumed,
      targetCalories: data.calories.target,
    );
    _applyWeightProjection(projection);
  }

  // ============================================
  // 🤖 جلب توقع ML من الباك إند
  // ============================================
  Future<void> _fetchMLPrediction() async {
    // Only fetch ML prediction once per session to reduce API calls
    if (_mlPredictionFetched) return;
    _mlPredictionFetched = true;
    try {
      final goal = _dashboardData?.user.goalType ?? 'تخسيس';
      final result = await WeightService.predictWeight(
        weeksAhead: 4,
        goal: goal,
      );
      if (!mounted) return;
      if (result['success'] != false && result['predicted_weight'] != null) {
        _mlPrediction = MLPredictionData.fromApi(result);
      } else {
        _mlPrediction = MLPredictionData.unavailable();
      }
      // تحديث _dashboardData إذا كان موجوداً
      if (_dashboardData != null) {
        setState(() {
          _dashboardData = _dashboardData!.copyWith(
            mlPrediction: _mlPrediction,
          );
        });
      }
    } catch (e) {
      print('⚠️ [ML Prediction] فشل جلب التوقع: $e');
      _mlPrediction = MLPredictionData.unavailable();
    }
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      NutritionService.setUserId(_userId);

      final results = await Future.wait([
        MedicationService.getMedications(),
        MedicationService.getTodayDoses(),
        NutritionService.getUserNutritionData(),
        WalkingService.getTodayActivities(),
        ActivityService.getTodayActivities(),
        NutritionService.getTodayMeals(),
        SymptomService.getSymptoms(limit: 5),
      ]);

      if (!mounted) return;

      final medications = results[0] as List<UserMedication>;
      final todayDoses = results[1] as List<MedicationDose>;
      final nutrition = results[2] as UserNutritionData?;
      final walkingActivities = results[3] as List<WalkingActivity>;
      final activities = results[4] as List<Activity>;
      final todayMeals = results[5] as Map<String, dynamic>?;
      final apiSymptoms = results[6] as List<dynamic>;

      if (nutrition != null && mounted) {
        setState(() {
          userNutritionData = nutrition;
        });
      }

      int totalToday = todayDoses.length;
      int takenToday = todayDoses.where((d) => d.status == 'taken').length;

      List<Medication> medicationsList = medications.map((med) {
        final medDoses = todayDoses
            .where((d) => d.medicationId == med.id.toString())
            .toList();
        String status = 'pending';
        if (medDoses.isNotEmpty) {
          status = medDoses.first.status;
        }
        return Medication(
          name: med.name,
          dose: med.dosage,
          time: med.times.isNotEmpty ? med.times[0] : '08:00',
          status: status,
        );
      }).toList();

      int totalSteps = 0;
      int totalDuration = 0;
      double totalDistance = 0.0;
      String lastActivityTime = '--:--';
      String lastActivityType = 'لا يوجد';
      int walkingCalories = 0;

      if (walkingActivities.isNotEmpty) {
        for (var activity in walkingActivities) {
          totalSteps += activity.steps;
          totalDuration += activity.durationMinutes;
          totalDistance += activity.distanceKm;

          if (userNutritionData != null) {
            double weight = userNutritionData!.weight;
            int activityCalories = ((weight * 0.04 * (activity.steps / 1000)))
                .round();
            walkingCalories += activityCalories;
          }
        }

        final latest = walkingActivities.reduce(
          (curr, next) =>
              curr.activityDate.isAfter(next.activityDate) ? curr : next,
        );
        lastActivityTime = latest.activityTime?.substring(0, 5) ?? '--:--';
        lastActivityType = 'مشي';
      }

      int consumedCaloriesFromMeals = 0;
      if (todayMeals != null && todayMeals['total_calories'] != null) {
        final caloriesValue = todayMeals['total_calories'];
        if (caloriesValue is int) {
          consumedCaloriesFromMeals = caloriesValue;
        } else if (caloriesValue is double) {
          consumedCaloriesFromMeals = caloriesValue.round();
        } else if (caloriesValue is num) {
          consumedCaloriesFromMeals = caloriesValue.toInt();
        }
      }

      int totalConsumedCalories = consumedCaloriesFromMeals + walkingCalories;

      List<Symptom> symptomsList = [];
      for (var s in apiSymptoms) {
        if (s is Symptom) {
          symptomsList.add(s);
        } else if (s is Map<String, dynamic>) {
          symptomsList.add(
            Symptom(
              symptom: s['name'] ?? s['symptom'] ?? '',
              severity: s['severity'] ?? 'متوسط',
              date: s['date'] ?? DateTime.now().toIso8601String(),
              analyzed:
                  s['analyzed'] ??
                  (s['analysis'] != null &&
                      s['analysis'].toString().isNotEmpty),
            ),
          );
        } else {
          try {
            symptomsList.add(
              Symptom(
                symptom: s.name,
                severity: s.severity,
                date: s.dateTime != null
                    ? '${s.dateTime.year}/${s.dateTime.month}/${s.dateTime.day}'
                    : DateTime.now().toIso8601String(),
                analyzed:
                    s.analysis != null && s.analysis.toString().isNotEmpty,
              ),
            );
          } catch (e) {
            print('⚠️ خطأ في تحويل العرض: $e');
          }
        }
      }

      List<Achievement> achievements = [];

      if (takenToday == totalToday && totalToday > 0) {
        achievements.add(
          Achievement(text: 'الالتزام بجميع أدوية اليوم ✅', type: 'success'),
        );
      }

      final userDataPrefs = PrefsHelper.getUserData();
      int dailyStepsGoal =
          userDataPrefs['dailyStepsGoal'] ??
          _calculateDailyStepsGoalFromUserData();
      int walkingPercentage = dailyStepsGoal > 0
          ? ((totalSteps / dailyStepsGoal) * 100).round()
          : 0;
      walkingPercentage = walkingPercentage.clamp(0, 100);

      if (totalSteps >= dailyStepsGoal && dailyStepsGoal > 0) {
        achievements.add(
          Achievement(text: '🎉 حققت هدف الخطوات اليوم!', type: 'success'),
        );
      }

      int completedActivities = activities.where((a) => a.isCompleted).length;
      if (activities.isNotEmpty && completedActivities == activities.length) {
        achievements.add(
          Achievement(text: '🎯 أكملت كل أنشطة اليوم!', type: 'success'),
        );
      }

      double _toSafeDouble(dynamic value, {double defaultValue = 0.0}) {
        if (value == null) return defaultValue;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
        return defaultValue;
      }

      int _toSafeInt(dynamic value, {int defaultValue = 0}) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        if (value is double) return value.round();
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed.round();
        }
        return defaultValue;
      }

      final currentWeight = _toSafeDouble(
        userNutritionData?.weight,
        defaultValue: 70.0,
      );
      final targetWeight = _toSafeDouble(
        userNutritionData?.targetWeight,
        defaultValue: 65.0,
      );
      final weightLossRate = _toSafeDouble(
        double.tryParse(userNutritionData?.weightLossRate ?? '0.5'),
        defaultValue: 0.5,
      );
      final goal = userNutritionData?.goal ?? 'تخسيس';
      final targetCalories = _toSafeInt(
        userNutritionData?.targetCalories,
        defaultValue: 2000,
      );
      final userSelectedWeeks = _toSafeInt(
        userNutritionData?.targetWeeks,
        defaultValue: 0,
      );

      double initialWeight = currentWeight;
      try {
        final weightHistory = await NutritionService.getWeightHistory();
        if (weightHistory != null && weightHistory.isNotEmpty) {
          initialWeight = _toSafeDouble(
            weightHistory.first.weight,
            defaultValue: currentWeight,
          );
        }
      } catch (e) {
        initialWeight = currentWeight;
      }

      int caloriesPercentageValue = targetCalories > 0
          ? ((totalConsumedCalories / targetCalories) * 100).round()
          : 0;
      caloriesPercentageValue = caloriesPercentageValue.clamp(0, 200);

      double lostWeight = 0;
      double gainedWeight = 0;
      double remainingWeight = 0;
      double remainingToGain = 0;
      double progressPercentage = 0;
      int weeksRemaining = 0;

      if (goal == 'تخسيس') {
        final totalToLose = (initialWeight - targetWeight).abs();
        if (initialWeight > targetWeight && totalToLose > 0) {
          if (currentWeight < initialWeight) {
            lostWeight = (initialWeight - currentWeight).abs();
            remainingWeight = (currentWeight - targetWeight).abs();
            progressPercentage = ((lostWeight / totalToLose) * 100).clamp(
              0,
              100,
            );
          } else if (currentWeight <= targetWeight) {
            lostWeight = totalToLose;
            remainingWeight = 0;
            progressPercentage = 100;
          } else {
            lostWeight = 0;
            remainingWeight = totalToLose;
            progressPercentage = 0;
          }
          weeksRemaining = userSelectedWeeks > 0
              ? userSelectedWeeks
              : (remainingWeight / weightLossRate).ceil();
        } else {
          progressPercentage = 100;
        }
      } else if (goal == 'زيادة') {
        final totalToGain = (targetWeight - initialWeight).abs();
        if (initialWeight < targetWeight && totalToGain > 0) {
          if (currentWeight > initialWeight) {
            gainedWeight = (currentWeight - initialWeight).abs();
            remainingToGain = (targetWeight - currentWeight).abs();
            progressPercentage = ((gainedWeight / totalToGain) * 100).clamp(
              0,
              100,
            );
          } else if (currentWeight >= targetWeight) {
            gainedWeight = totalToGain;
            remainingToGain = 0;
            progressPercentage = 100;
          } else {
            gainedWeight = 0;
            remainingToGain = totalToGain;
            progressPercentage = 0;
          }
          weeksRemaining = userSelectedWeeks > 0
              ? userSelectedWeeks
              : (remainingToGain / weightLossRate).ceil();
        } else {
          progressPercentage = 100;
        }
      } else {
        progressPercentage = 100;
      }

      progressPercentage = progressPercentage.clamp(0, 100);
      weeksRemaining = weeksRemaining.clamp(0, 52);

      // استخدام الدالة المشتركة لحساب توقع الوزن من السعرات
      final projection = _calculateWeightProjection(
        currentWeight: currentWeight,
        targetWeight: targetWeight,
        initialWeight: initialWeight,
        goal: goal,
        weeksRemaining: weeksRemaining,
        consumedCalories: totalConsumedCalories,
        targetCalories: targetCalories,
      );
      final expectedWeightChange = projection.expectedWeightChange;
      final predictedWeight = projection.predictedWeight;
      final progressMessage = projection.progressMessage;
      final expectedWeightFromCalories = projection.expectedWeightFromCalories;
      final weightDifference = projection.weightDifference;
      final weightAdvice = projection.weightAdvice;

      if (!mounted) return;

      setState(() {
        _dashboardData = DashboardData(
          user: UserData(
            name: username,
            currentWeight: currentWeight.round(),
            targetWeight: targetWeight.round(),
            initialWeight: initialWeight,
            goalType: goal,
            weeklyRate: weightLossRate,
          ),
          progress: ProgressData(
            lostWeight: lostWeight.round(),
            gainedWeight: gainedWeight.round(),
            remainingWeight: remainingWeight.round(),
            remainingToGain: remainingToGain.round(),
            percentage: progressPercentage.round(),
            weeksRemaining: weeksRemaining,
          ),
          calories: CaloriesData(
            consumed: totalConsumedCalories,
            target: targetCalories,
            percentage: caloriesPercentageValue,
          ),
          walking: WalkingData(
            steps: totalSteps,
            target: dailyStepsGoal,
            percentage: walkingPercentage,
            caloriesBurned: walkingCalories,
            distanceKm: totalDistance,
            durationMin: totalDuration,
            lastActivity: LastActivity(
              type: lastActivityType,
              time: lastActivityTime,
            ),
          ),
          medications: MedicationsData(
            totalToday: totalToday,
            taken: takenToday,
            remaining: totalToday - takenToday,
            list: medicationsList,
          ),
          symptoms: SymptomsData(
            latest: symptomsList,
            newToday: symptomsList.isNotEmpty,
          ),
          achievements: achievements,
          workSchedule: WorkSchedule(
            day: _getDayName(DateTime.now().weekday),
            workHours: '9ص - 5م',
            reminderTimes: ['8ص', '8م'],
          ),
          expectedWeightChange: expectedWeightChange,
          predictedWeight: predictedWeight,
          progressMessage: progressMessage,
          expectedWeightFromCalories: expectedWeightFromCalories,
          weightDifference: weightDifference,
          weightAdvice: weightAdvice,
          mlPrediction: _mlPrediction,
        );
        _todayActivities = activities;
        _isLoading = false;
      });

      // جلب توقع ML من الباك إند
      _fetchMLPrediction();
    } catch (e, stackTrace) {
      print('❌ خطأ في تحميل البيانات: $e');
      print('📚 Stack trace: $stackTrace');
      if (!mounted) return;

      setState(() {
        _errorMessage = 'فشل في تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  /// Calculate daily steps goal dynamically from user nutrition data
  /// when no stored value exists in SharedPreferences.
  int _calculateDailyStepsGoalFromUserData() {
    if (userNutritionData == null) {
      // Fallback: try reading from PrefsHelper user data
      final data = PrefsHelper.getUserData();
      final goal = data['goal'] ?? 'تخسيس';
      final weight = (data['weight'] ?? 70.0).toDouble();
      final activityLevel = data['activityLevel'] ?? 'متوسط';
      final diseases = List<String>.from(data['diseases'] ?? []);
      return _calculateGoal(goal, weight, activityLevel, diseases);
    }

    return _calculateGoal(
      userNutritionData!.goal,
      userNutritionData!.weight,
      userNutritionData!.activityLevel,
      userNutritionData!.diseases,
    );
  }

  int _calculateGoal(
    String goal,
    double weight,
    String activityLevel,
    List<String> diseases,
  ) {
    int baseSteps = 5000;

    switch (goal) {
      case 'تخسيس':
        baseSteps = 8000;
        break;
      case 'تثبيت':
        baseSteps = 6000;
        break;
      case 'زيادة':
        baseSteps = 4000;
        break;
    }

    if (weight > 100) {
      baseSteps += 2000;
    } else if (weight > 80) {
      baseSteps += 1000;
    } else if (weight < 50) {
      baseSteps -= 500;
    }

    switch (activityLevel) {
      case 'قليل':
        baseSteps -= 1000;
        break;
      case 'عالي':
        baseSteps += 2000;
        break;
      case 'مكثف':
        baseSteps += 3000;
        break;
    }

    if (diseases.contains('السكري')) {
      baseSteps += 1000;
    }

    if (diseases.contains('القلب')) {
      baseSteps = (baseSteps * 0.8).round();
    }

    return baseSteps.clamp(3000, 15000);
  }

  String _getDayName(int weekday) {
    const days = [
      '',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[weekday];
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    // Invalidate CacheManager entries for home screen on explicit refresh
    CacheManager.instance.invalidatePattern('home_');
    CacheManager.instance.invalidatePattern('nutrition_userdata');
    CacheManager.instance.invalidatePattern('nutrition_todaymeals');
    CacheManager.instance.invalidatePattern('nutrition_weighthistory');
    setState(() => _isLoading = true);
    _refreshController.forward();
    await _loadDashboardData();
    // _updateConsumedCalories() is redundant - _loadDashboardData already
    // fetches todayMeals and walking activities and calculates consumed calories
    if (!mounted) return;
    _refreshController.reverse();
  }

  void _navigateToActivities() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActivitiesDashboard()),
    ).then((_) {
      _refreshData();
    });
  }

  PreferredSizeWidget _buildAnimatedAppBar(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return AppBar(
      backgroundColor: themeProvider.getCardBackgroundColor(),
      elevation: 0,
      title: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'VITA',
                  style: TextStyle(
                    color: themeProvider.getTextColor(),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 2 * 3.14,
              child: IconButton(
                icon: Icon(
                  Icons.notifications_active_outlined,
                  color: themeProvider.getTextColor(),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationHistoryScreen(),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  final List<Map<String, dynamic>> _loadingTips = [
    {
      'icon': '💧',
      'title': 'شرب الماء',
      'message': 'اشرب 2-3 لتر ماء يومياً لتحسين التركيز والنشاط',
      'color': Colors.blue,
      'image': '💧',
    },
    {
      'icon': '🥗',
      'title': 'التغذية الصحية',
      'message': 'تناول الخضروات والفواكه يومياً لتقوية المناعة',
      'color': AppColors.nutrition,
      'image': '🥗',
    },
    {
      'icon': '🚶',
      'title': 'النشاط البدني',
      'message': 'المشي 30 دقيقة يومياً يحسن صحة القلب',
      'color': AppColors.walking,
      'image': '🚶',
    },
    {
      'icon': '💊',
      'title': 'الأدوية',
      'message': 'تناول أدويتك في موعدها المحدد للحصول على أفضل نتيجة',
      'color': AppColors.medications,
      'image': '💊',
    },
    {
      'icon': '😴',
      'title': 'النوم الكافي',
      'message': 'النوم 7-8 ساعات يحسن الذاكرة والمزاج',
      'color': Colors.purple,
      'image': '😴',
    },
    {
      'icon': '🧘',
      'title': 'الصحة النفسية',
      'message': 'خذ 10 دقائق تأمل يومياً لتقليل التوتر',
      'color': Colors.teal,
      'image': '🧘',
    },
    {
      'icon': '⚖️',
      'title': 'الوزن المثالي',
      'message': 'تتبع وزنك بانتظام يساعدك على التحكم به',
      'color': AppColors.primary,
      'image': '⚖️',
    },
    {
      'icon': '❤️',
      'title': 'صحة القلب',
      'message': 'قلل الملح والدهون المشبعة لصحة قلب أفضل',
      'color': AppColors.danger,
      'image': '❤️',
    },
    {
      'icon': '🩸',
      'title': 'فحص السكر',
      'message': 'راقب مستوى السكر بانتظام إذا كنت مصاباً بالسكري',
      'color': AppColors.calories,
      'image': '🩸',
    },
    {
      'icon': '💪',
      'title': 'العضلات',
      'message': 'البروتين مهم لبناء العضلات والحفاظ على كتلتها',
      'color': AppColors.success,
      'image': '💪',
    },
  ];
  @override
  Widget build(BuildContext context) {
    // ✅ هذا السطر مهم جداً لـ AutomaticKeepAliveClientMixin
    super.build(context);

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: themeProvider.getBackgroundColor(),
        appBar: _buildAnimatedAppBar(context),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          color: themeProvider.getCurrentPrimaryColor(),
          child: _isLoading
              ? _buildLoading(themeProvider)
              : _errorMessage != null
              ? _buildError(themeProvider)
              : _buildContent(context, themeProvider),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: themeProvider.isDarkMode
              ? [const Color(0xFF0A0E21), const Color(0xFF1A1A2E)]
              : [const Color(0xFFF8F9FF), const Color(0xFFE8F4FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),

              // Animated VITA Logo with multiple animations
              Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing background glow
                  _buildPulsingGlow(themeProvider),

                  // Main logo with rotation and scale
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.success],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 25,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '❤️',
                              style: TextStyle(
                                fontSize: 50,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Animated progress indicator with text
              Column(
                children: [
                  // Progress bar with shimmer effect
                  SizedBox(
                    width: 200,
                    child: Stack(
                      children: [
                        // Background track
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: themeProvider.isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),

                        // Animated progress fill
                        _buildProgressFill(),

                        // Shimmer effect
                        _buildShimmerEffect(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Loading text with typing animation
                  Column(
                    children: [
                      Text(
                        'جاري تحميل بياناتك الصحية...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.getTextColor(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Animated dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAnimatedDot(0, themeProvider),
                          _buildAnimatedDot(1, themeProvider),
                          _buildAnimatedDot(2, themeProvider),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Loading details
                      Text(
                        'جاري تحميل: البيانات الصحية • النشاط • التغذية',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.getSecondaryTextColor(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Enhanced tips carousel
              SizedBox(
                height: 240,
                child: PageView.builder(
                  itemCount: _loadingTips.length,
                  physics: const BouncingScrollPhysics(),
                  controller: PageController(viewportFraction: 0.88),
                  itemBuilder: (context, index) {
                    final tip = _loadingTips[index];
                    return _buildTipCard(tip, themeProvider, index);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Enhanced page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _loadingTips.length,
                  (index) => _buildPageIndicator(index, themeProvider),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for pulsing glow animation
  Widget _buildPulsingGlow(ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                themeProvider.isDarkMode
                    ? const Color(0xFF4A148C).withOpacity(value * 0.3)
                    : const Color(0xFFE040FB).withOpacity(value * 0.2),
                Colors.transparent,
              ],
              stops: const [0.0, 0.8],
            ),
          ),
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: themeProvider.isDarkMode
                ? [const Color(0xFF7B1FA2), const Color(0xFF4A148C)]
                : [const Color(0xFFE040FB), const Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: themeProvider.isDarkMode
                  ? const Color(0xFF7B1FA2).withOpacity(0.5)
                  : const Color(0xFFE040FB).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(child: Text('❤️', style: TextStyle(fontSize: 48))),
      ),
    );
  }

  // Helper method for progress fill animation
  Widget _buildProgressFill() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          height: 8,
          width: 200 * value,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  // Helper method for shimmer effect
  Widget _buildShimmerEffect() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: -1.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Positioned(
          left: 200 * (value + 1) / 2,
          child: Container(
            width: 60,
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.8),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method for animated loading dots
  Widget _buildAnimatedDot(int index, ThemeProvider themeProvider) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 800 + index * 200),
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? const Color(0xFF4CAF50).withOpacity(0.7)
            : const Color(0xFF4CAF50).withOpacity(0.5),
        shape: BoxShape.circle,
      ),
    );
  }

  // Helper method for enhanced tip cards
  Widget _buildTipCard(
    Map<String, dynamic> tip,
    ThemeProvider themeProvider,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tip['color'] ?? const Color(0xFF2196F3),
            tip['color']?.withOpacity(0.7) ??
                const Color(0xFF2196F3).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (tip['color'] ?? const Color(0xFF2196F3)).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(tip['emoji'] ?? '💡', style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            tip['title'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tip['message'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for enhanced page indicators
  Widget _buildPageIndicator(int index, ThemeProvider themeProvider) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Container(
          width: _currentTipIndex == index ? 24 * value : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _currentTipIndex == index
                ? themeProvider.isDarkMode
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF4CAF50)
                : themeProvider.isDarkMode
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildError(ThemeProvider themeProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.getTextColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'فشل في تحميل البيانات',
              textAlign: TextAlign.center,
              style: TextStyle(color: themeProvider.getSecondaryTextColor()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDashboardData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeProvider themeProvider) {
    if (_dashboardData == null) {
      return _buildError(themeProvider);
    }

    final data = _dashboardData!;
    final isDark = themeProvider.isDarkMode;

    final walkingUserData =
        userNutritionData ??
        UserNutritionData(
          id: _userId,
          weight: data.user.currentWeight.toDouble(),
          height: 170.0,
          age: 30,
          gender: 'ذكر',
          goal: data.user.goalType,
          activityLevel: 'متوسط',
          weightLossRate: data.user.weeklyRate.toString(),
          targetWeight: data.user.targetWeight.toDouble(),
          diseases: [],
          targetCalories: data.calories.target.toDouble(),
          bmr: 1500.0,
          tdee: 2000.0,
          createdAt: DateTime.now(),
          waterIntake: 2.5,
        );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [AppColors.background, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: AnimationLimiter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(themeProvider, data),
                  const SizedBox(height: 16),
                  _buildSmartDailyChallenge(themeProvider, data),
                  const SizedBox(height: 16),
                  AnimationConfiguration.staggeredGrid(
                    position: 0,
                    duration: const Duration(milliseconds: 500),
                    columnCount: 1,
                    child: FadeInAnimation(
                      child: SlideAnimation(
                        horizontalOffset: -50,
                        child: AnimatedGoalCard(
                          progress: data.progress,
                          user: data.user,
                          expectedWeightChange: data.expectedWeightChange,
                          predictedWeight: data.predictedWeight,
                          progressMessage: data.progressMessage,
                          expectedWeightFromCalories:
                              data.expectedWeightFromCalories,
                          weightDifference: data.weightDifference,
                          weightAdvice: data.weightAdvice,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'السعرات',
                          icon: '🔥',
                          value: data.calories.consumed.toString(),
                          subtitle: 'من ${data.calories.target}',
                          percentage: data.calories.percentage,
                          color: AppColors.calories,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'الخطوات',
                          icon: '👣',
                          value: data.walking.steps.toString(),
                          subtitle: 'من ${data.walking.target}',
                          percentage: data.walking.percentage,
                          color: AppColors.walking,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'الأدوية',
                          icon: '💊',
                          value: '${data.medications.remaining}',
                          subtitle: 'متبقية',
                          percentage: data.medications.totalToday > 0
                              ? ((data.medications.taken /
                                            data.medications.totalToday) *
                                        100)
                                    .round()
                              : 0,
                          color: AppColors.medications,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDynamicTargetsPreview(themeProvider),
                  const SizedBox(height: 16),
                  AnimationConfiguration.staggeredGrid(
                    position: 6,
                    duration: const Duration(milliseconds: 800),
                    columnCount: 1,
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WaterDashboard(),
                              ),
                            ).then((_) => _refreshData());
                          },
                          child: _buildWaterCard(themeProvider, data),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimationConfiguration.staggeredGrid(
                    position: 7,
                    duration: const Duration(milliseconds: 800),
                    columnCount: 1,
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AIDashboard(),
                              ),
                            );
                          },
                          child: _buildAICard(themeProvider),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimeBasedQuote(),
                  const SizedBox(height: 16),
                  AnimationConfiguration.staggeredGrid(
                    position: 4,
                    duration: const Duration(milliseconds: 800),
                    columnCount: 1,
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: _navigateToActivities,
                          child: AnimatedActivitiesCard(
                            activities: _todayActivities,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (data.medications.totalToday > 0)
                    _buildMedicationAwarenessBanner(data),
                  const SizedBox(height: 16),
                  AnimationConfiguration.staggeredGrid(
                    position: 5,
                    duration: const Duration(milliseconds: 800),
                    columnCount: 1,
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: AnimatedMedicationsCard(
                          medications: data.medications,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHealthQuote(data),
                  const SizedBox(height: 16),
                  _buildWalkingAwarenessBanner(data),
                  const SizedBox(height: 16),
                  AnimationConfiguration.staggeredGrid(
                    position: 8,
                    duration: const Duration(milliseconds: 800),
                    columnCount: 1,
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: AnimatedWalkingCard(
                          walking: data.walking,
                          userData: walkingUserData,
                          onRefresh: _refreshData,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimationConfiguration.staggeredGrid(
                    position: 9,
                    duration: const Duration(milliseconds: 800),
                    columnCount: 1,
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: AnimatedAchievementsCard(
                          achievements: data.achievements,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFitnessQuote(data),
                  const SizedBox(height: 16),
                  if (data.symptoms.latest.isNotEmpty)
                    _buildSymptomsAwarenessBanner(data),
                  const SizedBox(height: 16),
                  AnimationConfiguration.staggeredGrid(
                    position: 10,
                    duration: const Duration(milliseconds: 800),
                    columnCount: 1,
                    child: SlideAnimation(
                      verticalOffset: 50,
                      child: FadeInAnimation(
                        child: AnimatedSymptomsCard(symptoms: data.symptoms),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTargetsPreview(ThemeProvider themeProvider) {
    final isDark = themeProvider.isDarkMode;
    return AnimationConfiguration.staggeredGrid(
      position: 1,
      duration: const Duration(milliseconds: 600),
      columnCount: 1,
      child: SlideAnimation(
        verticalOffset: 50,
        child: FadeInAnimation(
          child: FutureBuilder<Map<String, dynamic>>(
            future: DynamicTargetsService.getTodayTargets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildDynamicTargetsShimmer(isDark);
              }
              if (!snapshot.hasData || snapshot.data?['success'] != true) {
                return const SizedBox.shrink();
              }
              final target = snapshot.data!['data'] as DynamicDailyTarget;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DynamicTargetsDashboard(),
                    ),
                  ).then((_) => _refreshData());
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF004D40), const Color(0xFF00695C)]
                          : [const Color(0xFF00897B), const Color(0xFF26A69A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00897B).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الأهداف الديناميكية',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'أهداف مخصصة بناءً على أدائك',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              target.performanceFactor > 1.0
                                  ? "ممتاز"
                                  : target.performanceFactor > 0.9
                                  ? "جيد"
                                  : "قيد التحسن",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildMiniStat(
                            icon: '🔥',
                            label: 'السعرات',
                            value:
                                target.targetCalories?.toStringAsFixed(0) ?? "—",
                            isDark: isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildMiniStat(
                            icon: '👣',
                            label: 'الخطوات',
                            value:
                                target.targetSteps?.toStringAsFixed(0) ?? "—",
                            isDark: isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildMiniStat(
                            icon: '💧',
                            label: 'الماء',
                            value:
                                '${target.targetWater?.toStringAsFixed(1) ?? "—"} لتر',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicTargetsShimmer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: i < 2 ? 12 : 0),
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String icon,
    required String value,
    required String subtitle,
    required int percentage,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 11)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartDailyChallenge(
    ThemeProvider themeProvider,
    DashboardData data,
  ) {
    final hasMedications = data.medications.totalToday > 0;

    return FutureBuilder<double>(
      future: _getTodayWaterAmount(),
      builder: (context, waterSnapshot) {
        final waterProgress = waterSnapshot.data ?? 0.0;
        final waterGoal = 2.5;
        final waterPercentage = waterGoal > 0
            ? (waterProgress / waterGoal).clamp(0.0, 1.0)
            : 0.0;

        Map<String, dynamic> challenge;

        if (hasMedications && data.medications.remaining > 0) {
          challenge = {
            'icon': '💊',
            'title': 'خذ أدويتك في موعدها',
            'description':
                'لديك ${data.medications.remaining} جرعة متبقية اليوم',
            'target': data.medications.totalToday.toDouble(),
            'current': data.medications.taken.toDouble(),
            'color': AppColors.medications,
            'action': 'تذكر موعد دوائك القادم',
          };
        } else if (data.calories.percentage < 50) {
          challenge = {
            'icon': '🍽️',
            'title': 'زد سعراتك اليومية',
            'description': 'سعراتك الحالية أقل من المطلوب',
            'target': data.calories.target.toDouble(),
            'current': data.calories.consumed.toDouble(),
            'color': AppColors.calories,
            'action': 'تناول وجبة خفيفة صحية',
          };
        } else if (data.walking.percentage < 50) {
          challenge = {
            'icon': '🚶',
            'title': 'زد خطواتك اليومية',
            'description':
                '${data.walking.target - data.walking.steps} خطوة متبقية',
            'target': data.walking.target.toDouble(),
            'current': data.walking.steps.toDouble(),
            'color': AppColors.walking,
            'action': 'تمشى 10 دقائق الآن',
          };
        } else if (waterPercentage < 0.5) {
          challenge = {
            'icon': '💧',
            'title': 'اشرب ماء كافياً',
            'description':
                '${(waterGoal - waterProgress).toStringAsFixed(1)} لتر متبقي',
            'target': waterGoal,
            'current': waterProgress,
            'color': Colors.blue,
            'action': 'اشرب كوب ماء الآن',
          };
        } else {
          final nextGoal = data.calories.target - data.calories.consumed;
          if (nextGoal > 0) {
            challenge = {
              'icon': '🎯',
              'title': 'أكمل سعراتك اليومية',
              'description': '$nextGoal سعرة متبقية لهدفك',
              'target': data.calories.target.toDouble(),
              'current': data.calories.consumed.toDouble(),
              'color': AppColors.primary,
              'action': 'تناول وجبة خفيفة',
            };
          } else {
            challenge = {
              'icon': '🏆',
              'title': 'أنت رائع!',
              'description': 'أداء ممتاز اليوم، استمر',
              'target': 100.0,
              'current': 100.0,
              'color': AppColors.success,
              'action': 'شارك تقدمك مع الأصدقاء',
            };
          }
        }

        final progressValue = (challenge['target'] as double) > 0
            ? ((challenge['current'] as double) /
                      (challenge['target'] as double))
                  .clamp(0.0, 1.0)
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (challenge['color'] as Color).withOpacity(0.15),
                (challenge['color'] as Color).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (challenge['color'] as Color).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (challenge['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  challenge['icon'] as String,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '🎯 تحدّي اليوم',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (challenge['color'] as Color).withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'مخصص لك',
                            style: TextStyle(
                              fontSize: 9,
                              color: challenge['color'] as Color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      challenge['description'] as String,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 6,
                        backgroundColor: (challenge['color'] as Color)
                            .withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          challenge['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (challenge['color'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  challenge['action'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: challenge['color'] as Color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicationAwarenessBanner(DashboardData data) {
    final hasRemaining = data.medications.remaining > 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.medications.withOpacity(0.12),
            AppColors.medications.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.medications.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.medications.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                hasRemaining ? '💊⚠️' : '💊✅',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasRemaining ? 'تذكير بالأدوية' : 'أحسنت!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.medications,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasRemaining
                      ? 'لديك ${data.medications.remaining} جرعة لم تتناولها بعد'
                      : 'تم تناول جميع أدويتك اليوم',
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  hasRemaining
                      ? 'تناول أدويتك في موعدها المحدد'
                      : 'الالتزام بالأدوية يحسن صحتك',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.medications.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hasRemaining ? 'تذكير' : 'ممتاز',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.medications,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkingAwarenessBanner(DashboardData data) {
    String icon;
    String title;
    String message;
    String detail;
    Color color;

    if (data.walking.percentage >= 80) {
      icon = '🏃✅';
      title = 'أداء ممتاز!';
      message = 'حققت ${data.walking.percentage}% من هدف خطواتك';
      detail = 'استمر على هذا المنوال الرائع';
      color = AppColors.success;
    } else if (data.walking.percentage >= 50) {
      icon = '🚶👍';
      title = 'أداء جيد';
      message = 'حققت ${data.walking.percentage}% من هدف خطواتك';
      detail = '${data.walking.target - data.walking.steps} خطوة متبقية لهدفك';
      color = AppColors.walking;
    } else if (data.walking.percentage > 0) {
      icon = '🚶⚠️';
      title = 'نشاطك منخفض';
      message = 'خطواتك اليومية أقل من الهدف';
      detail = 'المشي 30 دقيقة يومياً يحسن صحتك';
      color = AppColors.warning;
    } else {
      icon = '🚶';
      title = 'ابدأ خطوتك الأولى';
      message = 'لم تسجل أي خطوات اليوم';
      detail = 'المشي يحسن صحة القلب والتركيز';
      color = AppColors.walking;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(message, style: const TextStyle(fontSize: 11)),
                Text(
                  detail,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data.walking.percentage >= 80 ? 'ممتاز' : 'تحرك',
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsAwarenessBanner(DashboardData data) {
    final latestSymptom = data.symptoms.latest.first;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.symptoms.withOpacity(0.12),
            AppColors.symptoms.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.symptoms.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.symptoms.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🩺', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تنبيه صحي',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.symptoms,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'سجلت عرض: ${latestSymptom.symptom}',
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  'إذا استمرت الأعراض، استشر طبيبك',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.symptoms.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'تحليل',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.symptoms,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBasedQuote() {
    final hour = DateTime.now().hour;

    final morningQuotes = [
      '🌅 "بداية اليوم الجديد، بداية جديدة لصحتك"',
      '☀️ "صباح النشاط، اجعل اليوم أفضل من الأمس"',
      '🥗 "فطور صحي = يوم مليء بالطاقة"',
      '💪 "استيقظ وأنت تعلم أنك قادر على الإنجاز"',
      '🏃‍♂️ "الحركة الصباحية تنشط الدورة الدموية"',
      '💧 "كوب ماء على الريق يعزز الأيض"',
    ];

    final afternoonQuotes = [
      '🌤️ "ظهرك، لا تنس شرب الماء"',
      '🍽️ "الغداء المتوازن يمنع الخمول"',
      '🚶 "تمشى 10 دقائق بعد الغداء"',
      '💊 "تذكر أدويتك، صحتك أمانة"',
      '🥙 "اختر وجبة غنية بالبروتين والخضار"',
      '📊 "تتبع سعراتك يساعدك على الهدف"',
    ];

    final eveningQuotes = [
      '🌙 "مساء الخير، حان وقت الاسترخاء"',
      '🛌 "نوم مبكر = صحة أفضل"',
      '📝 "راجع إنجازاتك اليوم، أنت رائع"',
      '🥗 "عشاء خفيف قبل النوم بساعتين"',
      '🧘 "تأمل 5 دقائق يريح أعصابك"',
      '🎯 "كل يوم خطوة نحو هدفك"',
    ];

    List<String> quotes;
    String timeIcon;

    if (hour < 12) {
      quotes = morningQuotes;
      timeIcon = '🌅';
    } else if (hour < 18) {
      quotes = afternoonQuotes;
      timeIcon = '☀️';
    } else {
      quotes = eveningQuotes;
      timeIcon = '🌙';
    }

    final int index =
        (DateTime.now().millisecondsSinceEpoch ~/ 60000) % quotes.length;
    final String selectedQuote = quotes[index];

    return _buildQuoteCard(selectedQuote, timeIcon, AppColors.primary);
  }

  Widget _buildHealthQuote(DashboardData data) {
    final healthQuotes = [
      '💊 "الالتزام بأدويتك = حماية لقلبك وصحتك"',
      '🩺 "الصحة تاج على رؤوس الأصحاء"',
      '❤️ "قلب سليم = حياة سعيدة"',
      '🧠 "صحتك النفسية مهمة مثل صحتك الجسدية"',
      '🦷 "النظافة اليومية تمنع الأمراض"',
      '👁️ "راحة العين كل 20 دقيقة تحمي نظرك"',
      '🦴 "الكالسيوم وفيتامين د لعظام قوية"',
      '💉 "الفحوصات الدورية تكشف المشاكل مبكراً"',
      '😴 "النوم 7-8 ساعات يقوي المناعة"',
      '🧘 "التأمل يقلل التوتر والضغط"',
    ];

    final int index = DateTime.now().second % healthQuotes.length;
    final String selectedQuote = healthQuotes[index];

    Color quoteColor;
    if (selectedQuote.contains('💊')) {
      quoteColor = AppColors.medications;
    } else if (selectedQuote.contains('❤️') || selectedQuote.contains('🩺')) {
      quoteColor = AppColors.calories;
    } else if (selectedQuote.contains('😴') || selectedQuote.contains('🧘')) {
      quoteColor = Colors.purple;
    } else {
      quoteColor = AppColors.success;
    }

    return _buildQuoteCard(selectedQuote, '🩺', quoteColor);
  }

  Widget _buildFitnessQuote(DashboardData data) {
    final fitnessQuotes = [
      '🏃 "المشي 30 دقيقة يومياً يغير حياتك"',
      '💪 "العضلات تحرق الدهون حتى في الراحة"',
      '🥗 "أنت ما تأكل، اختر الأفضل"',
      '🔥 "الاستمرارية أهم من الشدة"',
      '🎯 "هدفك بين يديك، استمر"',
      '💧 "الماء يحرق الدهون وينقي الجسم"',
      '🏆 "كل خطوة تقربك من هدفك"',
      '⚡ "التمارين تفرز هرمون السعادة"',
      '📈 "التقدم ولو بطيء أفضل من التوقف"',
      '✨ "جسمك هو معبدك، اعتني به"',
    ];

    final int index =
        (DateTime.now().millisecondsSinceEpoch ~/ 30000) % fitnessQuotes.length;
    final String selectedQuote = fitnessQuotes[index];

    Color quoteColor;
    if (selectedQuote.contains('🏃') || selectedQuote.contains('🔥')) {
      quoteColor = AppColors.walking;
    } else if (selectedQuote.contains('🥗') || selectedQuote.contains('💧')) {
      quoteColor = AppColors.calories;
    } else if (selectedQuote.contains('🏆') || selectedQuote.contains('⚡')) {
      quoteColor = AppColors.success;
    } else {
      quoteColor = AppColors.primary;
    }

    return _buildQuoteCard(selectedQuote, '🎯', quoteColor);
  }

  Widget _buildQuoteCard(String quote, String icon, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: 0.95 + (scale * 0.05),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.03)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    quote,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: color,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // lib/screens/home/home_screen_with_animations.dart

  // استبدل دالة _buildGreeting بهذه النسخة المحسنة

  Widget _buildGreeting(ThemeProvider themeProvider, DashboardData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour = DateTime.now().hour;

    String getTimeBasedGreeting() {
      if (hour < 12) return '🌅 صباح الخير';
      if (hour < 18) return '🌤️ مساء الخير';
      return '🌙 مساء الخير';
    }

    // تحديد الكويز المتاح بناءً على الوقت
    Map<String, dynamic> getAvailableQuiz() {
      final now = DateTime.now();
      final isMorningTime = hour >= 6 && hour < 12;
      final isEveningTime = hour >= 18 && hour < 22;

      if (isMorningTime) {
        return {
          'available': true,
          'type': 'morning',
          'icon': '🌅',
          'text': 'كويز الصباح',
          'color': Colors.orange,
        };
      } else if (isEveningTime) {
        return {
          'available': true,
          'type': 'evening',
          'icon': '🌙',
          'text': 'كويز المساء',
          'color': Colors.purple,
        };
      } else {
        return {
          'available': false,
          'type': 'none',
          'icon': '📋',
          'text': 'انتظر الموعد',
          'color': Colors.grey,
        };
      }
    }

    Map<String, dynamic> mood;
    if (hour < 12) {
      mood = {'icon': '☀️', 'text': 'صباح النشاط!', 'color': Colors.orange};
    } else if (hour < 18) {
      mood = {'icon': '🌤️', 'text': 'ظهرك كويس؟', 'color': Colors.blue};
    } else {
      mood = {'icon': '🌙', 'text': 'مساء الاسترخاء', 'color': Colors.purple};
    }

    final quizInfo = getAvailableQuiz();

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.success.withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : AppColors.primary.withOpacity(0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصف الأول: الصورة + التحية + الاسم
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.success],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '👋',
                            style: TextStyle(fontSize: 22 * scale),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${getTimeBasedGreeting()}،',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        data.user.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // زر الكويز والمزاج معاً في صف واحد
                Row(
                  children: [
                    // زر الكويز
                    GestureDetector(
                      onTap: () {
                        if (quizInfo['available'] as bool) {
                          Navigator.of(context).pushNamed(
                            '/daily-quiz',
                            arguments: {'timeOfDay': quizInfo['type']},
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (quizInfo['color'] as Color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (quizInfo['color'] as Color).withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              quizInfo['icon'] as String,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              quizInfo['text'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: quizInfo['color'] as Color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // حالة المزاج
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (mood['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (mood['color'] as Color).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            mood['icon'] as String,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mood['text'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: mood['color'] as Color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // الخط الفاصل
            Container(
              height: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppColors.border.withOpacity(0.5),
            ),

            const SizedBox(height: 8),

            // الصف الثاني: الوقت والتاريخ
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'آخر تحديث: ${_formatLastUpdate()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.calendar_today,
                  size: 10,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<double> _getTodayWaterGoal() async {
    // Use CacheManager to deduplicate and cache water goal
    try {
      final waterData = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: 'home_water_today',
            fetch: () async => await WaterService.getTodayWater(),
            ttl: const Duration(minutes: 2),
            staleWhileRevalidate: true,
          );
      return (waterData?['daily_goal'] ?? 2.5).toDouble();
    } catch (e) {
      return 2.5;
    }
  }

  Widget _buildWaterCard(ThemeProvider themeProvider, DashboardData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<double>(
      future: _getTodayWaterAmount(),
      builder: (context, waterSnapshot) {
        return FutureBuilder<double>(
          future: _getTodayWaterGoal(),
          builder: (context, goalSnapshot) {
            final waterIntake = waterSnapshot.data ?? 0.0;
            final waterGoal = goalSnapshot.data ?? 2.5;
            final progress = waterGoal > 0
                ? (waterIntake / waterGoal).clamp(0.0, 1.0)
                : 0.0;
            final isGoalMet = waterIntake >= waterGoal;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WaterDashboard(),
                      ),
                    ).then((_) => _refreshData());
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? (isGoalMet
                                ? LinearGradient(
                                    colors: [
                                      Colors.teal.shade900,
                                      Colors.green.shade900,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.blue.shade900,
                                      Colors.cyan.shade900,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ))
                          : (isGoalMet
                                ? LinearGradient(
                                    colors: [
                                      Colors.teal.shade400,
                                      Colors.green.shade500,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.cyan.shade600,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isGoalMet
                                      ? Icons.celebration
                                      : Icons.water_drop,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '💧 شرب الماء',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isGoalMet)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'مكتمل!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isGoalMet
                                    ? '🎉 أحسنت! أكملت هدفك اليومي'
                                    : 'سجل كمية الماء التي تشربها يومياً',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 8,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.25),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${waterIntake.toStringAsFixed(1)} / ${waterGoal.toStringAsFixed(1)} لتر',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAICard(ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<int>(
      future: _getHealthScore(),
      builder: (context, snapshot) {
        final healthScore = snapshot.data ?? 70;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        Color scoreColor = healthScore >= 80
            ? AppColors.success
            : healthScore >= 60
            ? AppColors.warning
            : AppColors.danger;

        String scoreText = healthScore >= 80
            ? 'ممتاز'
            : healthScore >= 60
            ? 'جيد'
            : 'يحتاج تحسين';

        String scoreIcon = healthScore >= 80
            ? '🌟'
            : healthScore >= 60
            ? '👍'
            : '⚠️';

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AIDashboard()),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF1A237E),
                            const Color(0xFF0D47A1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.psychology,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🧠 التحليل الذكي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تحليل متقدم لبياناتك الصحية',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  scoreIcon,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$scoreText • $healthScore%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.star, size: 10, color: scoreColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatLastUpdate() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate() {
    final now = DateTime.now();
    final days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    final dayName = days[now.weekday % 7];
    final day = now.day;
    final month = months[now.month - 1];

    return '$dayName، $day $month';
  }
}

// ============================================
// ✅ كلاس نتيجة توقع الوزن
// ============================================
class WeightProjectionResult {
  final double expectedWeightChange;
  final double predictedWeight;
  final String progressMessage;
  final double expectedWeightFromCalories;
  final double weightDifference;
  final String weightAdvice;

  WeightProjectionResult({
    required this.expectedWeightChange,
    required this.predictedWeight,
    required this.progressMessage,
    required this.expectedWeightFromCalories,
    required this.weightDifference,
    required this.weightAdvice,
  });
}
