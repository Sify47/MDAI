import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vita/models/home_dashboard_model.dart';
import 'package:vita/services/medication_api.dart';
import 'package:vita/services/walking_api.dart';
import 'package:vita/services/nutrition_api.dart';
import 'package:vita/services/symptom_api.dart';
import 'package:vita/services/weight_service.dart';
import 'package:vita/services/water_service.dart';
import 'package:vita/models/medication_model.dart' as med_model;
import 'package:vita/models/symptom_model.dart' as symptom_model;

// Helper functions to convert between models
List<Medication> _convertToHomeMedications(
  List<med_model.UserMedication> medications,
) {
  return medications.map((med) {
    final medicineName = med.medicineInfo?.nameAr;
    final dosage = med.dosage;

    return Medication(
      name: medicineName != null && medicineName.isNotEmpty
          ? medicineName
          : 'دواء',
      dosage: dosage != null && dosage.isNotEmpty ? dosage : 'جرعة',
      time: DateTime.now().add(const Duration(hours: 2)), // Default time
    );
  }).toList();
}

List<Symptom> _convertToHomeSymptoms(List<symptom_model.Symptom> symptoms) {
  return symptoms.map((symptom) {
    // Convert severity string to int (خفيف=1, متوسط=2, شديد=3)
    int severityValue = 1;
    final severity = symptom.severity;
    if (severity == 'متوسط') {
      severityValue = 2;
    } else if (severity == 'شديد') {
      severityValue = 3;
    }

    final symptomName = symptom.name;
    final dateTime = symptom.dateTime;

    return Symptom(
      name: symptomName != null && symptomName.isNotEmpty ? symptomName : 'عرض',
      severity: severityValue,
      time: dateTime ?? DateTime.now(),
    );
  }).toList();
}

List<WeightRecord> _convertToHomeWeightRecords(
  List<Map<String, dynamic>> records,
) {
  return records.map((record) {
    return WeightRecord(
      weight: (record['weight'] as num?)?.toDouble() ?? 70.0,
      date: DateTime.parse(
        record['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }).toList();
}

class HomeViewModel extends ChangeNotifier {
  HomeDashboardData? _dashboardData;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  DateTime? _lastUpdated;
  bool _isRefreshing = false;

  HomeDashboardData? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isRefreshing => _isRefreshing;

  // Cache management
  final Map<String, dynamic> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check cache first
      if (!forceRefresh && _isCacheValid()) {
        _dashboardData = _getCachedData();
        _lastUpdated = DateTime.now();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load all data in parallel with explicit type
      final results = await Future.wait<dynamic>([
        _loadMedications(),
        _loadWalkingData(),
        _loadNutritionData(),
        _loadSymptomsData(),
        _loadWeightData(),
        _loadWaterData(),
        _loadHealthScore(),
      ], eagerError: true);

      _dashboardData = HomeDashboardData(
        user: UserData(
          name: 'المستخدم',
          age: 30,
          weight: 70.0,
          height: 170.0,
          gender: 'ذكر',
          healthConditions: [],
        ),
        medications: results[0] as MedicationsData,
        walking: results[1] as WalkingData,
        nutrition: results[2] as NutritionData,
        symptoms: results[3] as SymptomsData,
        weight: results[4] as WeightData,
        water: results[5] as WaterData,
        healthScore: results[6] as int,
        lastUpdated: DateTime.now(),
      );

      // Update cache
      _updateCache(_dashboardData!);
      _lastUpdated = DateTime.now();
      _hasError = false;
    } catch (error) {
      _hasError = true;
      _errorMessage = _handleError(error);

      // Try to load cached data as fallback
      if (_dashboardData == null && _isCacheValid()) {
        _dashboardData = _getCachedData();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    _isRefreshing = true;
    notifyListeners();

    await loadDashboardData(forceRefresh: true);

    _isRefreshing = false;
    notifyListeners();
  }

  // Individual data loading methods using real services
  Future<MedicationsData> _loadMedications() async {
    try {
      // Use getTodaysMedications() which returns today's medications directly
      final todayMedications = await MedicationService.getTodaysMedications();

      // Calculate adherence rate (simplified - could be improved with actual dose tracking)
      double adherenceRate = todayMedications.isNotEmpty ? 0.8 : 0.0;

      return MedicationsData(
        todayCount: todayMedications.length,
        adherenceRate: adherenceRate,
        nextMedication: todayMedications.isNotEmpty
            ? _convertToHomeMedications([todayMedications.first]).first
            : null,
        latest: _convertToHomeMedications(todayMedications.take(3).toList()),
      );
    } catch (e) {
      // Return default data on error
      return MedicationsData(
        todayCount: 0,
        adherenceRate: 0.0,
        nextMedication: null,
        latest: [],
      );
    }
  }

  Future<WalkingData> _loadWalkingData() async {
    try {
      // Get walking activities and calculate today's steps
      final activities = await WalkingService.getAllActivities();
      final now = DateTime.now();
      final todayActivities = activities.where((activity) {
        final activityDate = activity.activityDate;
        return activityDate.year == now.year &&
            activityDate.month == now.month &&
            activityDate.day == now.day;
      }).toList();

      final todaySteps = todayActivities.fold(
        0,
        (sum, activity) => sum + (activity.steps ?? 0),
      );

      // Get walking goal from impact calculation
      final impactData = await WalkingService.calculateWalkingImpact();
      final dailyGoal = (impactData['adjusted_goal'] as num?)?.toInt() ?? 10000;
      final progress = dailyGoal > 0
          ? (todaySteps / dailyGoal).clamp(0.0, 1.0)
          : 0.0;

      return WalkingData(
        steps: todaySteps,
        goal: dailyGoal,
        progress: progress,
        percentage: (progress * 100).toInt(),
        latest: [],
      );
    } catch (e) {
      return WalkingData(
        steps: 0,
        goal: 10000,
        progress: 0.0,
        percentage: 0,
        latest: [],
      );
    }
  }

  Future<NutritionData> _loadNutritionData() async {
    try {
      // Get user nutrition data
      final nutritionData = await NutritionService.getUserNutritionData();
      final calories = nutritionData?.targetCalories ?? 0.0;
      final goal =
          nutritionData?.goal ??
          2000; // Default goal since nutritionData.goal is a String
      final progress = goal as num > 0
          ? (calories / goal).clamp(0.0, 1.0)
          : 0.0;

      return NutritionData(
        calories: calories.toInt(),
        goal: goal.toInt(),
        progress: progress,
        percentage: (progress * 100).toInt(),
        latest: [],
      );
    } catch (e) {
      return NutritionData(
        calories: 0,
        goal: 2000,
        progress: 0.0,
        percentage: 0,
        latest: [],
      );
    }
  }

  Future<SymptomsData> _loadSymptomsData() async {
    try {
      final symptoms = await SymptomService.getSymptoms();
      final todaySymptoms = symptoms.where((symptom) {
        final now = DateTime.now();
        final symptomDate = symptom.dateTime;
        return symptomDate.year == now.year &&
            symptomDate.month == now.month &&
            symptomDate.day == now.day;
      }).toList();

      return SymptomsData(
        todayCount: todaySymptoms.length,
        severity: todaySymptoms.isNotEmpty
            ? todaySymptoms
                  .map((s) {
                    if (s.severity == 'شديد') return 3;
                    if (s.severity == 'متوسط') return 2;
                    return 1;
                  })
                  .reduce((a, b) => a > b ? a : b)
            : 0,
        latest: _convertToHomeSymptoms(todaySymptoms.take(3).toList()),
      );
    } catch (e) {
      return SymptomsData(todayCount: 0, severity: 0, latest: []);
    }
  }

  Future<WeightData> _loadWeightData() async {
    try {
      final weightHistory = await WeightService.getWeightHistory();
      final currentWeight = weightHistory.isNotEmpty
          ? (weightHistory.last['weight'] as num?)?.toDouble() ?? 70.0
          : 70.0;
      final targetWeight = 65.0;

      return WeightData(
        current: currentWeight,
        target: targetWeight,
        progress: targetWeight > 0
            ? ((currentWeight - targetWeight) / targetWeight).abs()
            : 0.0,
        percentage: 0,
        latest: _convertToHomeWeightRecords(weightHistory.take(3).toList()),
      );
    } catch (e) {
      return WeightData(
        current: 70.0,
        target: 65.0,
        progress: 0.0,
        percentage: 0,
        latest: [],
      );
    }
  }

  Future<WaterData> _loadWaterData() async {
    try {
      final waterData = await WaterService.getTodayWater();
      final intake = (waterData != null && waterData['intake'] != null)
          ? (waterData['intake'] is int
                ? waterData['intake'].toDouble()
                : waterData['intake'])
          : 0.0;
      final goal = 2.5; // Default goal
      final progress = goal > 0 ? (intake / goal).clamp(0.0, 1.0) : 0.0;

      return WaterData(
        intake: intake,
        goal: goal,
        progress: progress,
        percentage: (progress * 100).toInt(),
      );
    } catch (e) {
      return WaterData(intake: 0.0, goal: 2.5, progress: 0.0, percentage: 0);
    }
  }

  Future<int> _loadHealthScore() async {
    try {
      // Calculate health score based on various factors
      // Since getHealthScore() doesn't exist, we'll calculate a composite score
      final medications = await MedicationService.getTodaysMedications();
      final walkingData = await WalkingService.getAllActivities();
      final nutritionData = await NutritionService.getUserNutritionData();

      // Calculate medication adherence score (0-25 points)
      final medScore = medications.isEmpty ? 25 : 20;

      // Calculate walking score (0-25 points)
      final walkingScore = walkingData.isEmpty ? 10 : 20;

      // Calculate nutrition score (0-25 points)
      final nutritionScore = nutritionData != null ? 20 : 15;

      // Calculate water score (0-25 points)
      final waterData = await WaterService.getTodayWater();
      final waterIntake = (waterData != null && waterData['intake'] != null)
          ? (waterData['intake'] is int
                ? waterData['intake'].toDouble()
                : waterData['intake'])
          : 0.0;
      final waterScore = waterIntake >= 2.0
          ? 25
          : (waterIntake >= 1.0 ? 15 : 5);

      // Composite score (0-100)
      final compositeScore =
          medScore + walkingScore + nutritionScore + waterScore;

      return compositeScore.clamp(0, 100);
    } catch (e) {
      return 70; // Default score
    }
  }

  // Cache management methods
  bool _isCacheValid() {
    final cachedData = _cache['dashboard_data'];
    if (cachedData == null) return false;

    final timestamp = cachedData['timestamp'] as DateTime;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  HomeDashboardData? _getCachedData() {
    final cachedData = _cache['dashboard_data'];
    if (cachedData != null) {
      return HomeDashboardData.fromJson(cachedData['data']);
    }
    return null;
  }

  void _updateCache(HomeDashboardData data) {
    _cache['dashboard_data'] = {
      'data': data.toJson(),
      'timestamp': DateTime.now(),
    };
  }

  // Error handling
  String _handleError(dynamic error) {
    if (error is TimeoutException) {
      return 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.';
    } else if (error is SocketException) {
      return 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك.';
    } else {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  // Clear error state
  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Dispose resources
  @override
  void dispose() {
    _cache.clear();
    super.dispose();
  }
}
