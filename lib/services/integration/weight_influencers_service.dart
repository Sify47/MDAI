// lib/services/integration/weight_influencers_service.dart
// ⚖️ Weight Influencers Analysis Service
// Analyzes factors affecting weight changes across 5 dimensions:
// Calorie Balance, Activity, Water Retention, Medications, and Nutrition Quality

import 'package:vita/services/nutrition_api.dart';
import 'package:vita/services/medication_api.dart';
import 'package:vita/services/water_service.dart';
import 'package:vita/services/walking_api.dart';
import 'package:vita/services/weight_service.dart';

// ===================================================================
// 📊 Data Models
// ===================================================================

class WeightInfluencer {
  final String factorId;
  final String factorName;
  final String icon;
  final double impactScore; // 0.0 to 1.0 how much this affects weight
  final String direction; // up, down, neutral
  final List<String> evidence;
  final List<String> recommendations;

  const WeightInfluencer({
    required this.factorId,
    required this.factorName,
    required this.icon,
    required this.impactScore,
    required this.direction,
    required this.evidence,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'factor_id': factorId,
    'factor_name': factorName,
    'icon': icon,
    'impact_score': impactScore,
    'direction': direction,
    'evidence': evidence,
    'recommendations': recommendations,
  };
}

class WeightAnalysisResult {
  final List<WeightInfluencer> influencers;
  final String trend;
  final double? bmi;
  final double? weightChange30d;
  final double? weightChange7d;
  final String summary;
  final bool hasSufficientData;

  const WeightAnalysisResult({
    required this.influencers,
    required this.trend,
    this.bmi,
    this.weightChange30d,
    this.weightChange7d,
    required this.summary,
    required this.hasSufficientData,
  });

  List<WeightInfluencer> get rankedInfluencers {
    final sorted = List<WeightInfluencer>.from(influencers);
    sorted.sort((a, b) => b.impactScore.compareTo(a.impactScore));
    return sorted;
  }

  List<WeightInfluencer> get significantInfluencers =>
      rankedInfluencers.where((f) => f.impactScore > 0.3).toList();

  Map<String, dynamic> toJson() => {
    'influencers': influencers.map((f) => f.toJson()).toList(),
    'trend': trend,
    'bmi': bmi,
    'weight_change_30d': weightChange30d,
    'weight_change_7d': weightChange7d,
    'summary': summary,
    'has_sufficient_data': hasSufficientData,
  };
}

// ===================================================================
// ⚖️ WeightInfluencersService
// ===================================================================

class WeightInfluencersService {
  /// 🎯 Main analysis entry point
  static Future<WeightAnalysisResult> analyze() async {
    final service = WeightInfluencersService();
    return service._runAnalysis();
  }

  Future<WeightAnalysisResult> _runAnalysis() async {
    final influencers = <WeightInfluencer>[];
    double? bmi;
    double? change30d;
    double? change7d;

    try {
      final weightStats = await WeightService.getWeightStats(days: 30);
      if (weightStats['success'] == true) {
        final latest = (weightStats['latest_weight'] ?? 0).toDouble();
        final start = (weightStats['start_weight'] ?? latest).toDouble();
        change30d = start > 0 ? ((latest - start) / start * 100) : 0.0;

        // Get 7-day change
        final weekStats = await WeightService.getWeightStats(days: 7);
        if (weekStats['success'] == true) {
          final weekStart = (weekStats['start_weight'] ?? latest).toDouble();
          change7d = weekStart > 0
              ? ((latest - weekStart) / weekStart * 100)
              : 0.0;
        }

        // Only set BMI if the API returned a valid value
        final bmiRaw = weightStats['bmi'];
        if (bmiRaw != null && bmiRaw is num && bmiRaw > 0) {
          bmi = bmiRaw.toDouble();
        }
      }
    } catch (_) {}

    // Run all factor analyses in parallel
    final results = await Future.wait([
      _analyzeCalorieBalance(),
      _analyzeActivityImpact(),
      _analyzeWaterRetention(),
      _analyzeMedicationImpact(),
      _analyzeNutritionQuality(),
    ]);

    influencers.addAll(results);

    // Determine trend
    final trend = _determineTrend(change30d, influencers);

    // Generate summary
    final summary = _generateSummary(trend, change30d, influencers);

    return WeightAnalysisResult(
      influencers: influencers,
      trend: trend,
      bmi: bmi,
      weightChange30d: change30d,
      weightChange7d: change7d,
      summary: summary,
      hasSufficientData: influencers.any((f) => f.impactScore > 0),
    );
  }

  // ===================================================================
  // 🍽️ 1. Calorie Balance Analysis
  // ===================================================================
  Future<WeightInfluencer> _analyzeCalorieBalance() async {
    final evidence = <String>[];
    double impact = 0.0;
    String direction = 'neutral';

    try {
      final nutritionData = await NutritionService.getUserNutritionData();
      if (nutritionData == null) {
        return WeightInfluencer(
          factorId: 'calorie_balance',
          factorName: 'توازن السعرات',
          icon: '🍽️',
          impactScore: 0.0,
          direction: 'neutral',
          evidence: ['لا توجد بيانات غذائية'],
          recommendations: ['سجل وجباتك لتحليل السعرات الحرارية'],
        );
      }

      final tdee = nutritionData.tdee;
      final targetCalories = nutritionData.targetCalories;

      if (tdee > 0 && targetCalories > 0) {
        final calorieDiff = targetCalories - tdee;
        final diffPercent = (calorieDiff / tdee * 100).abs();

        if (calorieDiff > 300) {
          direction = 'up';
          evidence.add(
            '🍕 فائض سعرات: $targetCalories هدف - $tdee احتياج (+${calorieDiff.toStringAsFixed(0)})',
          );
          evidence.add(
            '⚠️ زيادة ${diffPercent.toStringAsFixed(0)}% عن الاحتياج',
          );
          impact = (diffPercent / 30).clamp(0.3, 1.0);
        } else if (calorieDiff < -300) {
          direction = 'down';
          evidence.add(
            '🥗 عجز سعرات: $targetCalories هدف - $tdee احتياج (${calorieDiff.toStringAsFixed(0)})',
          );
          evidence.add('📉 نقص ${diffPercent.toStringAsFixed(0)}% عن الاحتياج');
          impact = (diffPercent / 30).clamp(0.3, 1.0);
        } else {
          evidence.add('✅ توازن سعرات جيد');
          impact = 0.1;
        }
      } else {
        evidence.add('⚠️ بيانات السعرات غير مكتملة');
        impact = 0.0;
      }
    } catch (e) {
      evidence.add('خطأ في تحليل السعرات');
    }

    return WeightInfluencer(
      factorId: 'calorie_balance',
      factorName: 'توازن السعرات',
      icon: '🍽️',
      impactScore: impact,
      direction: direction,
      evidence: evidence,
      recommendations: _getCalorieRecs(direction),
    );
  }

  // ===================================================================
  // 🏃 2. Activity Impact Analysis
  // ===================================================================
  Future<WeightInfluencer> _analyzeActivityImpact() async {
    final evidence = <String>[];
    double impact = 0.0;
    String direction = 'neutral';

    try {
      final impactData = await WalkingService.calculateWalkingImpact();
      if (impactData['success'] == true) {
        final baseGoal = (impactData['base_goal'] ?? 8000).toDouble();
        final burnedCalories = (impactData['total_burned_calories'] ?? 0)
            .toDouble();

        // Get weekly steps
        final weekActivities = await WalkingService.getActivitiesForPeriod(7);
        final avgSteps = weekActivities.isNotEmpty
            ? weekActivities.fold<int>(0, (sum, a) => sum + a.steps) ~/
                  weekActivities.length
            : 0;

        final stepPercent = baseGoal > 0 ? avgSteps / baseGoal : 0.0;

        if (stepPercent > 1.2) {
          direction = 'down';
          evidence.add(
            '🏃 نشاط مرتفع: معدل $avgSteps خطوة/يوم (${(stepPercent * 100).toStringAsFixed(0)}% من الهدف)',
          );
          evidence.add('🔥 حرق $burnedCalories سعرة حرارية إضافية');
          impact = 0.6;
        } else if (stepPercent > 0.8) {
          evidence.add('🚶 نشاط جيد: معدل $avgSteps خطوة/يوم');
          impact = 0.2;
        } else if (stepPercent > 0.4) {
          direction = 'up';
          evidence.add(
            '🚶 نشاط متوسط: معدل $avgSteps خطوة/يوم (${(stepPercent * 100).toStringAsFixed(0)}% من الهدف)',
          );
          impact = 0.3;
        } else {
          direction = 'up';
          evidence.add('🛋️ نشاط منخفض جداً: معدل $avgSteps خطوة/يوم');
          impact = 0.6;
        }
      } else {
        evidence.add('⚠️ لا توجد بيانات نشاط كافية');
      }
    } catch (e) {
      evidence.add('خطأ في تحليل النشاط');
    }

    return WeightInfluencer(
      factorId: 'activity_impact',
      factorName: 'النشاط البدني',
      icon: '🏃',
      impactScore: impact,
      direction: direction,
      evidence: evidence,
      recommendations: _getActivityRecs(direction),
    );
  }

  // ===================================================================
  // 💧 3. Water Retention Analysis
  // ===================================================================
  Future<WeightInfluencer> _analyzeWaterRetention() async {
    final evidence = <String>[];
    double impact = 0.0;
    String direction = 'up';

    try {
      final waterData = await WaterService.getTodayWater();
      final waterIntake = (waterData?['total'] ?? 0.0).toDouble();
      final waterGoal = (waterData?['daily_goal'] ?? 2.5).toDouble();

      final percentage = waterGoal > 0 ? waterIntake / waterGoal : 0.0;

      if (percentage < 0.5) {
        evidence.add(
          '💧 شرب ماء قليل: $waterIntake/$waterGoal لتر - قد يسبب احتباس سوائل',
        );
        impact = 0.5;
      } else if (percentage < 0.8) {
        evidence.add(
          '💧 شرب ماء أقل من الموصى به: $waterIntake/$waterGoal لتر',
        );
        impact = 0.2;
      } else {
        evidence.add('✅ شرب ماء كافٍ: $waterIntake/$waterGoal لتر');
        impact = 0.0;
        direction = 'neutral';
      }

      // Check for sodium triggers
      final recentFoods = await _getRecentFoods();
      if (recentFoods.contains('ملح') || recentFoods.contains('أجبان')) {
        evidence.add('🧂 استهلاك مرتفع للصوديوم - قد يسبب احتباس سوائل');
        impact = (impact + 0.3).clamp(0.0, 1.0);
        direction = 'up';
      }
    } catch (e) {
      evidence.add('خطأ في تحليل الماء');
    }

    return WeightInfluencer(
      factorId: 'water_retention',
      factorName: 'احتباس السوائل',
      icon: '💧',
      impactScore: impact,
      direction: direction,
      evidence: evidence,
      recommendations: _getWaterRecs(impact),
    );
  }

  // ===================================================================
  // 💊 4. Medication Impact Analysis
  // ===================================================================
  Future<WeightInfluencer> _analyzeMedicationImpact() async {
    final evidence = <String>[];
    double impact = 0.0;
    String direction = 'neutral';

    try {
      final medications = await MedicationService.getMedications();
      if (medications.isEmpty) {
        return WeightInfluencer(
          factorId: 'medication_impact',
          factorName: 'تأثير الأدوية',
          icon: '💊',
          impactScore: 0.0,
          direction: 'neutral',
          evidence: ['لا توجد أدوية مسجلة'],
          recommendations: ['لا توجد توصيات دوائية'],
        );
      }

      for (final med in medications) {
        final medName = med.name.toLowerCase();

        // Medications known to affect weight
        if (medName.contains('كورتيزون') ||
            medName.contains('كورتيكوستيرويد') ||
            medName.contains('prednisone') ||
            medName.contains('depression') ||
            medName.contains('مضاد اكتئاب') ||
            medName.contains('سيروكسات') ||
            medName.contains('seroxat')) {
          evidence.add('⚠️ $medName قد يسبب زيادة وزن');
          impact = (impact + 0.5).clamp(0.0, 1.0);
          direction = 'up';
        }

        if (medName.contains('ميتفورمين') ||
            medName.contains('metformin') ||
            medName.contains('GLP-1') ||
            medName.contains('أوزمبك') ||
            medName.contains('ozempic') ||
            medName.contains('فيكتوزا') ||
            medName.contains('victoza')) {
          evidence.add('📉 $medName قد يساعد في خسارة الوزن');
          impact = (impact + 0.4).clamp(0.0, 1.0);
          direction = direction == 'up' ? 'neutral' : 'down';
        }
      }

      if (impact == 0.0) {
        evidence.add('✅ لا توجد أدوية تؤثر على الوزن');
      }
    } catch (e) {
      evidence.add('خطأ في تحليل الأدوية');
    }

    return WeightInfluencer(
      factorId: 'medication_impact',
      factorName: 'تأثير الأدوية',
      icon: '💊',
      impactScore: impact,
      direction: direction,
      evidence: evidence,
      recommendations: _getMedicationRecs(direction),
    );
  }

  // ===================================================================
  // 🥗 5. Nutrition Quality Analysis
  // ===================================================================
  Future<WeightInfluencer> _analyzeNutritionQuality() async {
    final evidence = <String>[];
    double impact = 0.0;
    String direction = 'neutral';

    try {
      final nutritionData = await NutritionService.getUserNutritionData();
      if (nutritionData == null) {
        return WeightInfluencer(
          factorId: 'nutrition_quality',
          factorName: 'جودة التغذية',
          icon: '🥗',
          impactScore: 0.0,
          direction: 'neutral',
          evidence: ['لا توجد بيانات غذائية'],
          recommendations: ['حسن جودة غذائك - ركز على البروتين والألياف'],
        );
      }

      // Check goal alignment
      if (nutritionData.goal.contains('تخسيس') ||
          nutritionData.goal.contains('خسارة') ||
          nutritionData.goal.contains('weight_loss')) {
        // Verify if on track
        if (nutritionData.targetCalories < nutritionData.tdee) {
          evidence.add('🎯 النظام الغذائي متوافق مع هدف إنقاص الوزن');
          impact = 0.1;
          direction = 'down';
        } else {
          evidence.add(
            '⚠️ السعرات المستهدفة (${nutritionData.targetCalories}) أعلى من الاحتياج (${nutritionData.tdee})',
          );
          impact = 0.4;
          direction = 'up';
        }
      } else if (nutritionData.goal.contains('زيادة') ||
          nutritionData.goal.contains('تضخيم') ||
          nutritionData.goal.contains('weight_gain')) {
        if (nutritionData.targetCalories > nutritionData.tdee) {
          evidence.add('🎯 النظام الغذائي متوافق مع هدف زيادة الوزن');
          impact = 0.1;
          direction = 'up';
        } else {
          evidence.add(
            '⚠️ السعرات المستهدفة (${nutritionData.targetCalories}) أقل من الاحتياج (${nutritionData.tdee})',
          );
          impact = 0.4;
          direction = 'down';
        }
      } else {
        evidence.add('✅ نظام غذائي متوازن');
        impact = 0.0;
      }
    } catch (e) {
      evidence.add('خطأ في تحليل التغذية');
    }

    return WeightInfluencer(
      factorId: 'nutrition_quality',
      factorName: 'جودة التغذية',
      icon: '🥗',
      impactScore: impact,
      direction: direction,
      evidence: evidence,
      recommendations: _getNutritionRecs(direction),
    );
  }

  // ===================================================================
  // 🧠 Helper Methods
  // ===================================================================

  String _determineTrend(
    double? change30d,
    List<WeightInfluencer> influencers,
  ) {
    if (change30d != null && change30d.abs() > 1.0) {
      return change30d > 0 ? 'up' : 'down';
    }

    // Check cumulative direction from influencers
    int upCount = 0, downCount = 0;
    for (final inf in influencers) {
      if (inf.direction == 'up') upCount++;
      if (inf.direction == 'down') downCount++;
    }

    if (upCount > downCount + 1) return 'up';
    if (downCount > upCount + 1) return 'down';
    return 'stable';
  }

  String _generateSummary(
    String trend,
    double? change30d,
    List<WeightInfluencer> influencers,
  ) {
    final significant = influencers.where((f) => f.impactScore > 0.3).toList();

    if (change30d == null) {
      return 'لا توجد بيانات وزن كافية للتحليل. سجل وزنك بانتظام لمتابعة التغيرات.';
    }

    switch (trend) {
      case 'up':
        final causes = significant.map((f) => f.factorName).join('، ');
        return '⚖️ زيادة وزن بنسبة ${change30d.toStringAsFixed(1)}% خلال 30 يوم. '
            'العوامل المؤثرة: $causes. يُنصح بمراجعة النظام الغذائي وزيادة النشاط البدني.';
      case 'down':
        final causes = significant.map((f) => f.factorName).join('، ');
        return '⚖️ نقص وزن بنسبة ${change30d.abs().toStringAsFixed(1)}% خلال 30 يوم. '
            'العوامل المؤثرة: $causes. تأكد من تناول سعرات كافية.';
      default:
        return '⚖️ الوزن مستقر. حافظ على نظامك الحالي وراقب أي تغيرات.';
    }
  }

  List<String> _getCalorieRecs(String direction) {
    switch (direction) {
      case 'up':
        return [
          '🍽️ قلل السعرات بمقدار 300-500 سعرة يومياً',
          '🥗 اختر أطعمة منخفضة السعرات وغنية بالألياف',
          '🍃 استبدل المشروبات السكرية بالماء',
          '📊 استخدم حاسبة السعرات في التطبيق',
        ];
      case 'down':
        return [
          '🍽️ زد سعراتك بمقدار 200-300 سعرة يومياً',
          '🥑 أضف دهون صحية (أفوكادو، مكسرات، زيت زيتون)',
          '🍗 زد كمية البروتين في وجباتك',
          '📊 راجع أهدافك مع أخصائي تغذية',
        ];
      default:
        return [
          '🍽️ حافظ على توازن السعرات الحالي',
          '🥗 استمر في تناول وجبات متوازنة',
          '📊 راقب وزنك أسبوعياً',
        ];
    }
  }

  List<String> _getActivityRecs(String direction) {
    switch (direction) {
      case 'up':
        return [
          '🚶 امشِ 30-45 دقيقة يومياً لزيادة حرق السعرات',
          '🏋️ أضف تمارين مقاومة 3 مرات أسبوعياً',
          '🧘 جرب تمارين HIIT لحرق أسرع',
          '📱 استخدم مؤشر النشاط لتحقيق 10000 خطوة يومياً',
        ];
      case 'down':
        return [
          '🥗 زد سعراتك لدعم النشاط البدني المتزايد',
          '🏃 حافظ على نشاطك ولكن لا تفرط في التمارين',
          '💪 ركز على تمارين القوة لبناء العضلات',
        ];
      default:
        return [
          '🚶 حافظ على نشاطك اليومي',
          '🏋️ استمر في روتينك الرياضي الحالي',
        ];
    }
  }

  List<String> _getWaterRecs(double impact) {
    if (impact > 0.3) {
      return [
        '💧 اشرب 8-10 أكواب ماء يومياً',
        '🧂 قلل الملح في طعامك لتقليل احتباس السوائل',
        '🥒 تناول خيار، بطيخ، وخضروات غنية بالماء',
        '☕ قلل الكافيين والمشروبات المدرة للبول',
      ];
    }
    return ['💧 حافظ على شرب الماء بكميات كافية', '🥤 8 أكواب يومياً معدل جيد'];
  }

  List<String> _getMedicationRecs(String direction) {
    if (direction == 'up') {
      return [
        '💊 استشر طبيبك حول بدائل أدويتك',
        '⚕️ لا توقف الدواء من تلقاء نفسك',
        '🍽️ ناقش طرق تخفيف زيادة الوزن مع طبيبك',
      ];
    }
    if (direction == 'down') {
      return [
        '💊 استمر في تناول أدويتك بانتظام',
        '📊 راقب وزنك مع بداية أي دواء جديد',
      ];
    }
    return [];
  }

  List<String> _getNutritionRecs(String direction) {
    switch (direction) {
      case 'up':
        return [
          '🥗 زد الخضروات والفواكه في وجباتك',
          '🍗 اختر مصادر بروتين قليلة الدهون',
          '🌾 استبدل الكربوهيدرات البسيطة بالمعقدة',
          '🥑 تناول دهون صحية باعتدال',
        ];
      case 'down':
        return [
          '🍗 زد البروتين لحماية العضلات أثناء خسارة الوزن',
          '🥜 أضف وجبات خفيفة غنية بالسعرات (مكسرات، فواكه مجففة)',
          '🥑 أضف دهون صحية لزيادة السعرات',
        ];
      default:
        return [
          '🥗 حافظ على نظام غذائي متوازن',
          '🍽️ تناول 3 وجبات رئيسية + وجبات خفيفة صحية',
        ];
    }
  }

  Future<Set<String>> _getRecentFoods() async {
    final foods = <String>{};
    try {
      for (int i = 0; i < 3; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dayMeals = await NutritionService.getMealsByDate(date);
        if (dayMeals == null) continue;

        final meals = dayMeals['meals'] as List? ?? [];
        for (final meal in meals) {
          final mealFoods = meal['foods'] as List? ?? [];
          for (final food in mealFoods) {
            final name = (food['name'] ?? '').toString().toLowerCase();
            if (name.contains('ملح') || name.contains('مخلل')) {
              foods.add('ملح');
            }
            if (name.contains('جبن') || name.contains('أجبان')) {
              foods.add('أجبان');
            }
            if (name.contains('مقلي') || name.contains('زيت')) {
              foods.add('دهون');
            }
          }
        }
      }
    } catch (_) {}
    return foods;
  }
}
