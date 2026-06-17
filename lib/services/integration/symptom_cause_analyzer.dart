// lib/services/integration/symptom_cause_analyzer.dart
// 🧠 Core AI Inference Engine: Analyzes symptom root causes across 7 data dimensions
// Orchestrates data from Nutrition, Medications, Hydration, Activity, Weight,
// Symptom Patterns, and Health Risks to produce ranked causes with evidence.

import 'package:vita/services/nutrition_api.dart';
import 'package:vita/services/medication_api.dart';
import 'package:vita/services/symptom_api.dart';
import 'package:vita/services/water_service.dart';
import 'package:vita/services/walking_api.dart';
import 'package:vita/services/weight_service.dart';
import 'package:vita/services/predictive_prevention_api.dart';
import 'package:vita/models/nutrition_model.dart';

// ===================================================================
// 📊 Data Models for Analysis Results
// ===================================================================

class FactorScore {
  final String
  factorId; // nutrition, medication, hydration, activity, weight, symptom_pattern, health_risk
  final String factorName; // Arabic display name
  final double score; // 0.0 to 1.0
  final double weight; // evidence weight multiplier
  final List<String> evidence; // supporting evidence strings
  final String? icon; // emoji icon

  const FactorScore({
    required this.factorId,
    required this.factorName,
    required this.score,
    required this.weight,
    required this.evidence,
    this.icon,
  });

  double get weightedScore => score * weight;

  Map<String, dynamic> toJson() => {
    'factor_id': factorId,
    'factor_name': factorName,
    'score': score,
    'weight': weight,
    'weighted_score': weightedScore,
    'evidence': evidence,
    'icon': icon,
  };
}

class CauseAnalysisResult {
  final String symptomName;
  final String severity;
  final DateTime analyzedAt;
  final List<FactorScore> factors;
  final List<String> topCauses;
  final List<String> recommendations;
  final String summary;
  final bool hasSufficientData;

  const CauseAnalysisResult({
    required this.symptomName,
    required this.severity,
    required this.analyzedAt,
    required this.factors,
    required this.topCauses,
    required this.recommendations,
    required this.summary,
    required this.hasSufficientData,
  });

  /// Returns factors sorted by weighted score descending
  List<FactorScore> get rankedFactors {
    final sorted = List<FactorScore>.from(factors);
    sorted.sort((a, b) => b.weightedScore.compareTo(a.weightedScore));
    return sorted;
  }

  /// Returns the top contributing factors (score > 0.3)
  List<FactorScore> get significantFactors =>
      rankedFactors.where((f) => f.weightedScore > 0.3).toList();

  Map<String, dynamic> toJson() => {
    'symptom_name': symptomName,
    'severity': severity,
    'analyzed_at': analyzedAt.toIso8601String(),
    'factors': factors.map((f) => f.toJson()).toList(),
    'top_causes': topCauses,
    'recommendations': recommendations,
    'summary': summary,
    'has_sufficient_data': hasSufficientData,
  };
}

// ===================================================================
// 🧠 SymptomCauseAnalyzer - Multi-Factor AI Inference Engine
// ===================================================================

class SymptomCauseAnalyzer {
  final String symptomName;
  final String severity;
  final DateTime occurredAt;
  final UserNutritionData? userData;

  // Cached values from analysis methods for use in helper methods
  double _waterGoal = 2.0;

  SymptomCauseAnalyzer({
    required this.symptomName,
    required this.severity,
    required this.occurredAt,
    this.userData,
  });

  /// 🎯 Main analysis entry point - orchestrates all 7 data dimensions
  static Future<CauseAnalysisResult> analyze({
    required String symptomName,
    required String severity,
    required DateTime occurredAt,
  }) async {
    final analyzer = SymptomCauseAnalyzer(
      symptomName: symptomName,
      severity: severity,
      occurredAt: occurredAt,
    );
    return analyzer._runAnalysis();
  }

  Future<CauseAnalysisResult> _runAnalysis() async {
    final factors = <FactorScore>[];
    final allEvidence = <String>[];
    final allRecommendations = <String>{};

    // 🔄 Run all factor analyses in parallel
    final results = await Future.wait([
      _scoreNutrition(),
      _scoreMedications(),
      _scoreHydration(),
      _scoreActivity(),
      _scoreWeight(),
      _scoreSymptomPattern(),
      _scoreHealthRisks(),
    ]);

    for (final result in results) {
      factors.add(result);
      allEvidence.addAll(result.evidence);
      if (result.weightedScore > 0.2) {
        allRecommendations.addAll(_getRecommendationsForFactor(result));
      }
    }

    // 📊 Rank factors and determine top causes
    final ranked = List<FactorScore>.from(factors)
      ..sort((a, b) => b.weightedScore.compareTo(a.weightedScore));

    final topCauses = <String>[];
    for (final factor in ranked) {
      if (factor.weightedScore > 0.3) {
        topCauses.add(factor.factorName);
      }
    }

    // 📝 Generate summary
    final hasData = factors.any((f) => f.score >= 0 && f.evidence.isNotEmpty);
    final summary = _generateSummary(ranked, topCauses);

    return CauseAnalysisResult(
      symptomName: symptomName,
      severity: severity,
      analyzedAt: DateTime.now(),
      factors: factors,
      topCauses: topCauses.isNotEmpty ? topCauses : ['سبب غير محدد'],
      recommendations: allRecommendations.toList(),
      summary: summary,
      hasSufficientData: hasData,
    );
  }

  // ===================================================================
  // 🥗 1. Nutrition Factor Analysis
  // ===================================================================
  Future<FactorScore> _scoreNutrition() async {
    final evidence = <String>[];
    double score = 0.0;
    int checks = 0;

    try {
      final nutritionData = await NutritionService.getUserNutritionData();
      if (nutritionData == null) {
        return FactorScore(
          factorId: 'nutrition',
          factorName: 'التغذية',
          score: 0.0,
          weight: 0.20,
          evidence: ['لا توجد بيانات غذائية كافية'],
          icon: '🥗',
        );
      }

      // Check 7-day macro averages
      final lastWeekMeals = await _getLastWeekMeals();
      if (lastWeekMeals.isNotEmpty) {
        double totalProtein = 0, totalCarbs = 0, totalFat = 0;
        int daysWithMeals = 0;

        for (final meal in lastWeekMeals) {
          if (meal['total_protein'] != null) {
            totalProtein += (meal['total_protein'] as num).toDouble();
            totalCarbs += (meal['total_carbs'] as num).toDouble();
            totalFat += (meal['total_fat'] as num).toDouble();
            daysWithMeals++;
          }
        }

        if (daysWithMeals > 0) {
          // Use NutritionCalculator or fallback to simple targets
          final targetProtein = 60.0; // g/day default
          final targetCarbs = 250.0;
          final targetFat = 70.0;

          final avgProtein = totalProtein / daysWithMeals;
          final avgCarbs = totalCarbs / daysWithMeals;
          final avgFat = totalFat / daysWithMeals;

          // Protein deficiency
          if (avgProtein < targetProtein * 0.7) {
            evidence.add(
              'نقص البروتين: ${avgProtein.toStringAsFixed(0)}جم/يوم (المعدل $targetProteinجم)',
            );
            score += 0.3;
            checks++;
            if (_isSymptomLinkedToNutrition('تعب', 'إرهاق', 'ضعف')) {
              score += 0.2;
            }
          }

          // Carbs imbalance
          if (avgCarbs < targetCarbs * 0.6) {
            evidence.add(
              'انخفاض الكربوهيدرات: ${avgCarbs.toStringAsFixed(0)}جم/يوم',
            );
            score += 0.25;
            checks++;
          } else if (avgCarbs > targetCarbs * 1.3) {
            evidence.add(
              'ارتفاع الكربوهيدرات: ${avgCarbs.toStringAsFixed(0)}جم/يوم',
            );
            score += 0.15;
            checks++;
          }

          // Fat excess
          if (avgFat > targetFat * 1.2) {
            evidence.add('ارتفاع الدهون: ${avgFat.toStringAsFixed(0)}جم/يوم');
            if (_isSymptomLinkedToNutrition('غثيان', 'ألم بطن', 'عسر هضم')) {
              score += 0.3;
            }
            checks++;
          }
        }
      }

      // Check recent food items for symptom-specific triggers
      final recentFoods = await _getRecentFoods();
      if (recentFoods.contains('كافيين') &&
          _isSymptomLinkedToNutrition('صداع', 'دوخة', 'تعب')) {
        evidence.add('استهلاك مرتفع للكافيين قد يسبب $symptomName');
        score += 0.35;
        checks++;
      }
      if (recentFoods.contains('سكريات') &&
          _isSymptomLinkedToNutrition('تعب', 'إرهاق', 'دوخة')) {
        evidence.add('استهلاك السكريات يسبب انهيار الطاقة');
        score += 0.2;
        checks++;
      }
      if (recentFoods.contains('دهون') &&
          _isSymptomLinkedToNutrition('غثيان', 'ألم بطن', 'عسر هضم')) {
        evidence.add('الوجبات الدهنية قد تسبب اضطراب هضمي');
        score += 0.25;
        checks++;
      }
    } catch (e) {
      print('⚠️ [Nutrition Factor] Error: $e');
    }

    final finalScore = checks > 0
        ? (score / (checks * 0.5)).clamp(0.0, 1.0)
        : 0.0;

    return FactorScore(
      factorId: 'nutrition',
      factorName: 'التغذية',
      score: finalScore,
      weight: 0.20,
      evidence: evidence.isNotEmpty
          ? evidence
          : ['لم يتم العثور على مؤشرات غذائية'],
      icon: '🥗',
    );
  }

  // ===================================================================
  // 💊 2. Medication Factor Analysis
  // ===================================================================
  Future<FactorScore> _scoreMedications() async {
    final evidence = <String>[];
    double score = 0.0;
    int checks = 0;

    try {
      final medications = await MedicationService.getMedications();
      if (medications.isEmpty) {
        return FactorScore(
          factorId: 'medication',
          factorName: 'الأدوية',
          score: 0.0,
          weight: 0.15,
          evidence: ['لا توجد أدوية مسجلة'],
          icon: '💊',
        );
      }

      for (final med in medications) {
        final impact = await SymptomService.getMedicineImpact(
          med.medicineId ?? 0,
        );

        if (impact['success'] == true) {
          // Check side effects matching symptom
          if (impact['side_effects'] != null) {
            final sideEffects = List<String>.from(impact['side_effects']);
            for (final effect in sideEffects) {
              if (effect.contains(symptomName) ||
                  symptomName.contains(effect)) {
                evidence.add('⚠️ ${med.name} قد يسبب $symptomName كأثر جانبي');
                score += 0.6;
                checks++;
              }
            }
          }

          // Check food interactions
          if (impact['foods_to_avoid'] != null &&
              impact['foods_to_avoid'].isNotEmpty) {
            final recentFoods = await _getRecentFoods();
            final foodList = List<String>.from(impact['foods_to_avoid']);
            for (final food in foodList) {
              if (recentFoods.contains(food)) {
                evidence.add(
                  '⚡ تفاعل دوائي: ${med.name} مع $food قد يسبب $symptomName',
                );
                score += 0.4;
                checks++;
              }
            }
          }
        }

        // Check timing - if symptom occurred near medication time
        if (med.times.isNotEmpty) {
          final symptomHour = occurredAt.hour;
          for (final time in med.times) {
            final parts = time.split(':');
            if (parts.length >= 2) {
              final medHour = int.tryParse(parts[0]) ?? -1;
              if (medHour >= 0 && (symptomHour - medHour).abs() <= 3) {
                evidence.add(
                  '⏰ $symptomName ظهر بعد $medHour:${parts[1]} (وقت دواء ${med.name})',
                );
                score += 0.25;
                checks++;
              }
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ [Medication Factor] Error: $e');
    }

    final finalScore = checks > 0
        ? (score / (checks * 0.8)).clamp(0.0, 1.0)
        : 0.0;

    return FactorScore(
      factorId: 'medication',
      factorName: 'الأدوية',
      score: finalScore,
      weight: 0.15,
      evidence: evidence.isNotEmpty
          ? evidence
          : ['لا توجد تأثيرات دوائية مرتبطة'],
      icon: '💊',
    );
  }

  // ===================================================================
  // 💧 3. Hydration Factor Analysis
  // ===================================================================
  Future<FactorScore> _scoreHydration() async {
    final evidence = <String>[];
    double score = 0.0;

    try {
      final waterData = await WaterService.getTodayWater();
      if (waterData == null) {
        return FactorScore(
          factorId: 'hydration',
          factorName: 'شرب الماء',
          score: 0.0,
          weight: 0.15,
          evidence: ['لا توجد بيانات ماء كافية'],
          icon: '💧',
        );
      }

      final waterIntake = (waterData['total'] ?? 0.0).toDouble();
      _waterGoal = (waterData['daily_goal'] ?? 2.5).toDouble();
      final waterGoal = _waterGoal;

      final percentage = waterGoal > 0 ? waterIntake / waterGoal : 0.0;

      if (percentage < 0.3) {
        evidence.add(
          '⚠️ جفاف شديد: شربت $waterIntake لتر من $waterGoal لتر (${(percentage * 100).toStringAsFixed(0)}%)',
        );
        score = 0.8;
        // Boost for dehydration-linked symptoms
        if (_isSymptomLinkedToHydration()) {
          score = 0.9;
        }
      } else if (percentage < 0.5) {
        evidence.add(
          '💧 جفاف خفيف: شربت $waterIntake لتر من $waterGoal لتر (${(percentage * 100).toStringAsFixed(0)}%)',
        );
        score = 0.5;
        if (_isSymptomLinkedToHydration()) {
          score = 0.6;
        }
      } else if (percentage < 0.7) {
        evidence.add(
          '💧 شرب الماء أقل من الموصى به: $waterIntake/$waterGoal لتر',
        );
        score = 0.2;
      } else {
        evidence.add('✅ كمية الماء كافية: $waterIntake/$waterGoal لتر');
        score = 0.0;
      }
    } catch (e) {
      print('⚠️ [Hydration Factor] Error: $e');
    }

    return FactorScore(
      factorId: 'hydration',
      factorName: 'شرب الماء',
      score: score,
      weight: 0.15,
      evidence: evidence.isNotEmpty ? evidence : ['لا توجد بيانات ماء'],
      icon: '💧',
    );
  }

  // ===================================================================
  // 🏃 4. Activity Factor Analysis
  // ===================================================================
  Future<FactorScore> _scoreActivity() async {
    final evidence = <String>[];
    double score = 0.0;
    int checks = 0;

    try {
      final walkingImpact = await WalkingService.calculateWalkingImpact();

      if (walkingImpact['success'] == false) {
        return FactorScore(
          factorId: 'activity',
          factorName: 'النشاط البدني',
          score: 0.0,
          weight: 0.10,
          evidence: ['لا توجد بيانات نشاط كافية'],
          icon: '🏃',
        );
      }

      final baseGoal = (walkingImpact['base_goal'] ?? 8000).toDouble();

      // Get weekly stats for step trend
      final weekActivities = await WalkingService.getActivitiesForPeriod(7);
      if (weekActivities.isNotEmpty) {
        int totalSteps = 0;
        int daysWithData = 0;
        for (final activity in weekActivities) {
          totalSteps += activity.steps;
          daysWithData++;
        }

        if (daysWithData > 0) {
          final avgSteps = totalSteps / daysWithData;
          final stepPercentage = avgSteps / baseGoal;

          if (stepPercentage < 0.3) {
            evidence.add(
              '🚶 نشاط منخفض جداً: معدل $avgSteps خطوة/يوم (الهدف $baseGoal)',
            );
            score += 0.4;
            checks++;
            if (_isSymptomLinkedToInactivity()) {
              score += 0.2;
            }
          } else if (stepPercentage < 0.6) {
            evidence.add('🚶 نشاط أقل من الموصى به: معدل $avgSteps خطوة/يوم');
            score += 0.2;
            checks++;
          } else {
            evidence.add('✅ مستوى النشاط جيد: معدل $avgSteps خطوة/يوم');
          }
        }
      }

      // Check impact details for symptom-specific effects
      if (walkingImpact['impact_details'] != null) {
        final details = List<Map<String, dynamic>>.from(
          walkingImpact['impact_details'],
        );
        for (final detail in details) {
          final reason = detail['reason'] ?? '';
          if (reason.contains(symptomName)) {
            evidence.add(
              '📊 تأثير $symptomName على النشاط: ${detail['impact_percentage']}%',
            );
            score += 0.2;
            checks++;
          }
        }
      }
    } catch (e) {
      print('⚠️ [Activity Factor] Error: $e');
    }

    final finalScore = checks > 0
        ? (score / (checks * 0.7)).clamp(0.0, 1.0)
        : 0.0;

    return FactorScore(
      factorId: 'activity',
      factorName: 'النشاط البدني',
      score: finalScore,
      weight: 0.10,
      evidence: evidence.isNotEmpty ? evidence : ['مستوى النشاط طبيعي'],
      icon: '🏃',
    );
  }

  // ===================================================================
  // ⚖️ 5. Weight Factor Analysis
  // ===================================================================
  Future<FactorScore> _scoreWeight() async {
    final evidence = <String>[];
    double score = 0.0;

    try {
      final weightStats = await WeightService.getWeightStats(days: 30);
      if (weightStats['success'] == false) {
        return FactorScore(
          factorId: 'weight',
          factorName: 'الوزن',
          score: 0.0,
          weight: 0.10,
          evidence: ['لا توجد بيانات وزن كافية'],
          icon: '⚖️',
        );
      }

      final latestWeight = (weightStats['latest_weight'] ?? 0).toDouble();
      final startWeight = (weightStats['start_weight'] ?? latestWeight)
          .toDouble();
      final change = latestWeight - startWeight;
      final changePercentage = startWeight > 0
          ? (change / startWeight * 100)
          : 0.0;

      // Rapid weight loss
      if (changePercentage < -3.0) {
        evidence.add(
          '📉 فقدان وزن سريع: ${changePercentage.abs().toStringAsFixed(1)}% خلال 30 يوم',
        );
        if (_isSymptomLinkedToWeightLoss()) {
          score += 0.5;
        } else {
          score += 0.3;
        }
      }
      // Rapid weight gain
      else if (changePercentage > 3.0) {
        evidence.add(
          '📈 زيادة وزن سريعة: ${changePercentage.toStringAsFixed(1)}% خلال 30 يوم',
        );
        if (_isSymptomLinkedToWeightGain()) {
          score += 0.5;
        } else {
          score += 0.2;
        }
      }

      // Check for overweight/obesity link
      final bmi = (weightStats['bmi'] ?? 0).toDouble();
      if (bmi > 30) {
        evidence.add('⚠️ مؤشر كتلة الجسم $bmi (سمنة) - يزيد خطر $symptomName');
        score = score > 0.4 ? score : 0.4;
      } else if (bmi > 25) {
        evidence.add(
          '⚠️ مؤشر كتلة الجسم $bmi (وزن زائد) - قد يؤثر على $symptomName',
        );
        score = score > 0.2 ? score : 0.2;
      }
    } catch (e) {
      print('⚠️ [Weight Factor] Error: $e');
    }

    return FactorScore(
      factorId: 'weight',
      factorName: 'الوزن',
      score: score.clamp(0.0, 1.0),
      weight: 0.10,
      evidence: evidence.isNotEmpty ? evidence : ['مستقر الوزن'],
      icon: '⚖️',
    );
  }

  // ===================================================================
  // 📈 6. Symptom Pattern Analysis
  // ===================================================================
  Future<FactorScore> _scoreSymptomPattern() async {
    final evidence = <String>[];
    double score = 0.0;
    int checks = 0;

    try {
      // Get symptom timeline data
      final timeline = await SymptomService.getSymptomsTimeline();
      if (timeline['success'] == true && timeline['timeline'] != null) {
        final timelineData = timeline['timeline'];
        final frequency = timelineData['frequency'] ?? 0;
        final recurrence = timelineData['recurring_pattern'] ?? false;

        if (frequency > 5) {
          evidence.add('📊 ظهور متكرر: $frequency مرة في الشهر');
          score += 0.3;
          checks++;
        }
        if (recurrence == true) {
          evidence.add('🔄 نمط متكرر - $symptomName يظهر بشكل دوري');
          score += 0.3;
          checks++;
        }
      }

      // Get symptoms from last 7 days to check for patterns
      final recentSymptoms = await SymptomService.getSymptoms(
        fromDate: occurredAt.subtract(const Duration(days: 7)),
        toDate: occurredAt,
      );

      if (recentSymptoms.length > 3) {
        evidence.add(
          '⚠️ تعدد الأعراض: ${recentSymptoms.length} أعراض في آخر 7 أيام',
        );
        score += 0.25;
        checks++;
      }

      // Check if this symptom has appeared before
      final allSimilarSymptoms = recentSymptoms
          .where((s) => s.name.contains(symptomName))
          .length;
      if (allSimilarSymptoms > 1) {
        evidence.add(
          '🔄 تكرار $symptomName $allSimilarSymptoms مرات في آخر 7 أيام',
        );
        score += 0.35;
        checks++;
      }

      // Check severity escalation
      final highestSeverity = recentSymptoms
          .where((s) => s.name.contains(symptomName))
          .map((s) => s.severity)
          .toSet();
      if (highestSeverity.length > 1) {
        evidence.add('📈 تغير في شدة $symptomName');
        score += 0.2;
        checks++;
      }
    } catch (e) {
      print('⚠️ [Symptom Pattern Factor] Error: $e');
    }

    final finalScore = checks > 0
        ? (score / (checks * 0.5)).clamp(0.0, 1.0)
        : 0.0;

    return FactorScore(
      factorId: 'symptom_pattern',
      factorName: 'نمط الأعراض',
      score: finalScore,
      weight: 0.15,
      evidence: evidence.isNotEmpty ? evidence : ['لا يوجد نمط واضح'],
      icon: '📈',
    );
  }

  // ===================================================================
  // 🏥 7. Health Risk Analysis
  // ===================================================================
  Future<FactorScore> _scoreHealthRisks() async {
    final evidence = <String>[];
    double score = 0.0;
    int checks = 0;

    try {
      final risks = await PredictivePreventionApi.analyzeHealthRisks();
      if (risks.isEmpty) {
        return FactorScore(
          factorId: 'health_risk',
          factorName: 'المخاطر الصحية',
          score: 0.0,
          weight: 0.15,
          evidence: ['لا توجد مخاطر صحية محددة'],
          icon: '🏥',
        );
      }

      for (final risk in risks) {
        final riskType = risk['risk_type'] ?? '';
        final riskLevel = risk['risk_level'] ?? 'low';

        if (riskLevel == 'high' || riskLevel == 'critical') {
          // Map risk types to symptom links
          if (_doesRiskCauseSymptom(riskType)) {
            evidence.add(
              '⚠️ خطر ${_getRiskArabicName(riskType)} بمستوى $riskLevel قد يسبب $symptomName',
            );
            score += 0.6;
            checks++;
          }

          // Check risk factors mentioning this symptom
          if (risk['factors'] != null) {
            final factors = List<String>.from(risk['factors']);
            for (final factor in factors) {
              if (factor.contains(symptomName)) {
                evidence.add('📋 عامل خطر: $factor');
                score += 0.4;
                checks++;
              }
            }
          }
        } else if (riskLevel == 'medium') {
          if (_doesRiskCauseSymptom(riskType)) {
            evidence.add(
              '⚠️ خطر ${_getRiskArabicName(riskType)} بمستوى $riskLevel',
            );
            score += 0.3;
            checks++;
          }
        }
      }
    } catch (e) {
      print('⚠️ [Health Risk Factor] Error: $e');
    }

    final finalScore = checks > 0
        ? (score / (checks * 0.8)).clamp(0.0, 1.0)
        : 0.0;

    return FactorScore(
      factorId: 'health_risk',
      factorName: 'المخاطر الصحية',
      score: finalScore,
      weight: 0.15,
      evidence: evidence.isNotEmpty ? evidence : ['لا توجد مخاطر صحية مرتبطة'],
      icon: '🏥',
    );
  }

  // ===================================================================
  // 🧠 Helper Methods
  // ===================================================================

  bool _isSymptomLinkedToNutrition(String s1, String s2, String s3) {
    return symptomName.contains(s1) ||
        symptomName.contains(s2) ||
        symptomName.contains(s3);
  }

  bool _isSymptomLinkedToHydration() {
    return symptomName.contains('صداع') ||
        symptomName.contains('دوخة') ||
        symptomName.contains('تعب') ||
        symptomName.contains('إرهاق');
  }

  bool _isSymptomLinkedToInactivity() {
    return symptomName.contains('تعب') ||
        symptomName.contains('إرهاق') ||
        symptomName.contains('آلام') ||
        symptomName.contains('خمول');
  }

  bool _isSymptomLinkedToWeightLoss() {
    return symptomName.contains('تعب') ||
        symptomName.contains('إرهاق') ||
        symptomName.contains('دوخة') ||
        symptomName.contains('ضعف');
  }

  bool _isSymptomLinkedToWeightGain() {
    return symptomName.contains('تعب') ||
        symptomName.contains('خمول') ||
        symptomName.contains('ضيق تنفس');
  }

  bool _doesRiskCauseSymptom(String riskType) {
    switch (riskType) {
      case 'diabetes':
        return symptomName.contains('دوخة') ||
            symptomName.contains('تعب') ||
            symptomName.contains('زغللة') ||
            symptomName.contains('تنميل');
      case 'hypertension':
        return symptomName.contains('صداع') ||
            symptomName.contains('دوخة') ||
            symptomName.contains('زغللة');
      case 'obesity':
        return symptomName.contains('ضيق تنفس') ||
            symptomName.contains('تعب') ||
            symptomName.contains('خمول');
      case 'heart_disease':
        return symptomName.contains('ألم صدر') ||
            symptomName.contains('ضيق تنفس') ||
            symptomName.contains('دوخة');
      case 'inactivity':
        return symptomName.contains('تعب') ||
            symptomName.contains('إرهاق') ||
            symptomName.contains('آلام');
      case 'malnutrition':
        return symptomName.contains('تعب') ||
            symptomName.contains('دوخة') ||
            symptomName.contains('ضعف') ||
            symptomName.contains('تنميل');
      case 'stress':
        return symptomName.contains('صداع') ||
            symptomName.contains('ألم بطن') ||
            symptomName.contains('تعب') ||
            symptomName.contains('إرهاق');
      default:
        return false;
    }
  }

  String _getRiskArabicName(String riskType) {
    switch (riskType) {
      case 'diabetes':
        return 'السكري';
      case 'hypertension':
        return 'ارتفاع الضغط';
      case 'obesity':
        return 'السمنة';
      case 'heart_disease':
        return 'أمراض القلب';
      case 'inactivity':
        return 'قلة النشاط';
      case 'malnutrition':
        return 'سوء التغذية';
      case 'stress':
        return 'الإجهاد';
      default:
        return riskType;
    }
  }

  List<String> _getRecommendationsForFactor(FactorScore factor) {
    switch (factor.factorId) {
      case 'nutrition':
        return [
          '🍗 زد من البروتين في وجباتك (دجاج، سمك، بيض، بقوليات)',
          '🥗 تناول خضروات وفواكه طازجة يومياً',
          '🌾 استبدل الكربوهيدرات البسيطة بالمعقدة (شوفان، أرز بني)',
          '🥑 قلل من الدهون المشبعة والمقلية',
          '☕ قلل من الكافيين خاصة في المساء',
        ];
      case 'medication':
        return [
          '💊 استشر طبيبك حول الآثار الجانبية لأدويتك',
          '⏰ حاول تنظيم مواعيد الأدوية لتقليل التداخلات',
          '🍽️ تناول الأدوية مع الطعام إذا وصفها الطبيب كذلك',
          '💧 اشرب ماء كافياً مع أدويتك',
        ];
      case 'hydration':
        return [
          '💧 اشرب $_waterGoal لتر ماء يومياً',
          '🚰 احمل زجاجة ماء معك طوال اليوم',
          '⏰ ضع تذكيرات لشرب الماء كل ساعة',
          '🍉 تناول فواكه غنية بالماء (بطيخ، برتقال)',
        ];
      case 'activity':
        return [
          '🚶 امشِ 30 دقيقة يومياً',
          '🧘 جرب تمارين الاسترخاء والتنفس',
          '🏋️ ابدأ بتمارين خفيفة وزدها تدريجياً',
          '📱 استخدم مؤشر النشاط في التطبيق',
        ];
      case 'weight':
        return [
          '⚖️ حافظ على وزن صحي من خلال التغذية المتوازنة',
          '🏃 زد النشاط البدني لتحسين الوزن',
          '📊 تابع وزنك أسبوعياً',
          '🥗 استشر أخصائي تغذية لوضع خطة مناسبة',
        ];
      case 'symptom_pattern':
        return [
          '📝 سجل أعراضك يومياً لتحديد الأنماط',
          '⏰ لاحظ الأوقات التي تظهر فيها الأعراض',
          '🍽️ تتبع علاقة الأعراض بالوجبات',
          '🩺 استشر طبيبك إذا تكررت الأعراض',
        ];
      case 'health_risk':
        return [
          '🩺 استشر طبيبك لتقييم المخاطر الصحية',
          '📊 تابع المؤشرات الصحية بانتظام',
          '🥗 اتبع نظاماً صحياً متوازناً',
          '🏃 مارس النشاط البدني بانتظام',
        ];
      default:
        return ['تابع الأعراض واستشر طبيبك إذا استمرت'];
    }
  }

  String _generateSummary(List<FactorScore> ranked, List<String> topCauses) {
    if (topCauses.isEmpty) {
      return 'بناءً على تحليل البيانات المتاحة، لا توجد عوامل واضحة تسبب $symptomName. قد يكون السبب عابراً أو يحتاج متابعة طبية.';
    }

    final mainCause = topCauses.first;
    final secondaryCauses = topCauses.length > 1
        ? '، ${topCauses.sublist(1).join('، ')}'
        : '';

    switch (mainCause) {
      case 'التغذية':
        return '🍽️ من المحتمل أن $symptomName ناتج عن عوامل غذائية$secondaryCauses. يُنصح بتحسين النظام الغذائي وتناول وجبات متوازنة.';
      case 'الأدوية':
        return '💊 يرجح أن $symptomName مرتبط بتأثير جانبي للأدوية$secondaryCauses. استشر طبيبك حول إمكانية تعديل الجرعة أو الدواء.';
      case 'شرب الماء':
        return '💧 $symptomName قد يكون بسبب الجفاف$secondaryCauses. اشرب كمية كافية من الماء يومياً.';
      case 'النشاط البدني':
        return '🏃 $symptomName قد يكون مرتبطاً بمستوى النشاط البدني$secondaryCauses. حاول زيادة النشاط تدريجياً.';
      case 'الوزن':
        return '⚖️ $symptomName قد يتأثر بتغيرات الوزن$secondaryCauses. حافظ على وزن صحي ومتوازن.';
      case 'نمط الأعراض':
        return '📈 $symptomName يظهر بنمط متكرر$secondaryCauses. سجل الأعراض لمساعدة طبيبك في التشخيص.';
      case 'المخاطر الصحية':
        return '🏥 $symptomName قد يكون مرتبطاً بمخاطر صحية موجودة$secondaryCauses. يُنصح بزيارة الطبيب للتقييم.';
      default:
        return 'تحليل متعدد العوامل يشير إلى أن $symptomName قد يكون ناتجاً عن $mainCause$secondaryCauses. يُنصح بالمتابعة والمراقبة.';
    }
  }

  Future<List<Map<String, dynamic>>> _getLastWeekMeals() async {
    final meals = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayMeals = await NutritionService.getMealsByDate(date);
      if (dayMeals != null) {
        meals.add(dayMeals);
      }
    }
    return meals;
  }

  Future<Set<String>> _getRecentFoods() async {
    final foods = <String>{};
    final lastWeekMeals = await _getLastWeekMeals();

    for (final day in lastWeekMeals) {
      final dayMeals = day['meals'] as List? ?? [];
      for (final meal in dayMeals) {
        final mealFoods = meal['foods'] as List? ?? [];
        for (final food in mealFoods) {
          final foodName = (food['name'] ?? '').toString().toLowerCase();
          if (foodName.contains('قهوة') || foodName.contains('شاي')) {
            foods.add('كافيين');
          }
          if (foodName.contains('حلو') || foodName.contains('سكر')) {
            foods.add('سكريات');
          }
          if (foodName.contains('مقلي') || foodName.contains('زيت')) {
            foods.add('دهون');
          }
          if (foodName.contains('مشروبات غازية') ||
              foodName.contains('بيبسي')) {
            foods.add('مشروبات غازية');
          }
          if (foodName.contains('أجبان') || foodName.contains('جبن')) {
            foods.add('أجبان قديمة');
          }
        }
      }
    }
    return foods;
  }
}
