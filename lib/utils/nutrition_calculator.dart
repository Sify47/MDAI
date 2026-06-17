// lib/utils/nutrition_calculator.dart

import '../constants/colors.dart';
import '../models/medication_model.dart';
import '../models/symptom_model.dart';
import '../services/medication_api.dart';
import '../services/symptom_api.dart';

class NutritionCalculator {
  // ============================================
  // ✅ حساب BMR (معدل الأيض الأساسي)
  // ============================================
  static double calculateBMR({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    if (gender == 'ذكر') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // ============================================
  // ✅ حساب TDEE (إجمالي الطاقة المستهلكة)
  // ============================================
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    switch (activityLevel) {
      case 'قليل':
        return bmr * 1.2;
      case 'متوسط':
        return bmr * 1.375;
      case 'عالي':
        return bmr * 1.55;
      case 'مكثف':
        return bmr * 1.725;
      default:
        return bmr * 1.2;
    }
  }

  // ============================================
  // ✅ حساب السعرات المستهدفة حسب الهدف
  // ============================================
  static double calculateTargetCalories({
    required double tdee,
    required String goal,
    required String weightLossRate,
  }) {
    switch (goal) {
      case 'تخسيس':
        double reduction = double.parse(weightLossRate) * 1000;
        return (tdee - reduction).clamp(1200, tdee);
      case 'تثبيت':
        return tdee;
      case 'زيادة':
        return tdee + 300;
      default:
        return tdee;
    }
  }

  // ============================================
  // ✅ حساب السعرات المحروقة في المشي (مصحح)
  // ============================================
  static int calculateWalkingCalories({
    required double weight,
    required int steps,
    double speed = 5.0, // كم/ساعة (المشي العادي 5 كم/ساعة)
  }) {
    if (steps <= 0) return 0;
    
    // المعادلة الأساسية: 0.04 سعرة لكل كجم لكل 1000 خطوة
    double caloriesPer1000Steps = weight * 0.04;
    
    // تعديل حسب السرعة
    double speedFactor = speed / 5.0;
    speedFactor = speedFactor.clamp(0.5, 2.0);
    
    // حساب السعرات
    double calories = (steps / 1000) * caloriesPer1000Steps * speedFactor;
    
    return calories.round();
  }

  // ============================================
  // ✅ حساب السعرات المحروقة في المشي (حسب الوقت والمسافة)
  // ============================================
  static int calculateWalkingCaloriesByDistance({
    required double weight,
    required double distanceKm,
    required int durationMinutes,
  }) {
    // MET (معدل الأيض أثناء المشي) ≈ 3.5
    const double met = 3.5;
    
    // السعرات = MET × الوزن (كجم) × الوقت (ساعات)
    double hours = durationMinutes / 60.0;
    double calories = met * weight * hours;
    
    return calories.round();
  }

  // ============================================
  // ✅ حساب السعرات المحروقة حسب نوع النشاط
  // ============================================
  static int calculateActivityCalories({
    required double weight,
    required int durationMinutes,
    required String activityType, // walking, running, cycling, swimming
  }) {
    Map<String, double> metValues = {
      'walking': 3.5,
      'running': 8.0,
      'cycling': 6.0,
      'swimming': 7.0,
      'strength': 4.0,
      'yoga': 2.5,
    };
    
    double met = metValues[activityType] ?? 3.5;
    double hours = durationMinutes / 60.0;
    double calories = met * weight * hours;
    
    return calories.round();
  }

  // ============================================
  // 🆕 حساب السعرات المحروقة في تمارين الجيم (محسّن)
  // ============================================
  /// يستخدم MET خاص بالتمرين + وزن المستخدم الفعلي + المجموعات والعدات
  /// حساب السعرات المحروقة في تمارين الجيم (محسّن)
  static int calculateExerciseCalories({
    required double metValue,
    required double userWeight,
    required int sets,
    required int reps,
    int restSeconds = 60,
  }) {
    if (sets <= 0 || reps <= 0 || userWeight <= 0) return 0;

    // تقدير زمن التمرين الفعلي:
    // - كل عدة ≈ 1.5 ثانية (Time Under Tension)
    // - راحة بين المجموعات
    final workSeconds = sets * (reps * 1.5);
    final totalRestSeconds = (sets - 1) * restSeconds;
    final totalSeconds = workSeconds + totalRestSeconds;
    final hours = totalSeconds / 3600.0; // ✅ تصحيح: ثواني → ساعات مباشرة

    final calories = metValue * userWeight * hours;
    return calories.round().clamp(1, 9999);
  }

  /// حساب السعرات باستخدام MET + المدة الفعلية (بديل)
  static int calculateExerciseCaloriesByDuration({
    required double metValue,
    required double userWeight,
    required int durationMinutes,
  }) {
    final hours = durationMinutes / 60.0;
    final calories = metValue * userWeight * hours;
    return calories.round().clamp(1, 9999);
  }

  /// حساب السعرات بناءً على الحجم الكلي (weight × sets × reps)
  /// معامل: 0.05 سعرة لكل كجم من الحجم الكلي
  static int calculateCaloriesByVolume({
    required double metValue,
    required double userWeight,
    required int totalVolume, // weight × sets × reps
  }) {
    // متوسط 0.05 سعرة لكل كجم من الحجم الكلي مع تعديل حسب MET
    final metFactor = metValue / 4.0; // نسبة إلى MET الأساسي (4.0 للتمارين العادية)
    final calories = totalVolume * 0.05 * metFactor;
    return calories.round().clamp(1, 9999);
  }

  // ============================================
  // ✅ حساب توزيع المغذيات (ماكروز) حسب الأمراض
  // ============================================
  static Map<String, double> calculateMacros({
    required double calories,
    required String goal,
    required List<String> diseases,
  }) {
    double proteinRatio, carbsRatio, fatRatio;

    // النسب الأساسية حسب الهدف
    Map<String, Map<String, double>> goalMacros = {
      'تخسيس': {'protein': 0.30, 'carbs': 0.40, 'fat': 0.30},
      'تثبيت': {'protein': 0.25, 'carbs': 0.45, 'fat': 0.30},
      'زيادة': {'protein': 0.25, 'carbs': 0.50, 'fat': 0.25},
    };

    proteinRatio = goalMacros[goal]?['protein'] ?? 0.25;
    carbsRatio = goalMacros[goal]?['carbs'] ?? 0.45;
    fatRatio = goalMacros[goal]?['fat'] ?? 0.30;

    // تعديل حسب الأمراض
    Map<String, Map<String, double>> diseaseAdjustments = {
      'السكري': {'protein': 0.05, 'carbs': -0.10, 'fat': 0.05},
      'ضغط الدم': {'protein': 0.05, 'carbs': 0, 'fat': -0.05},
      'الكوليسترول': {'protein': 0.05, 'carbs': 0.03, 'fat': -0.08},
      'القلب': {'protein': 0.05, 'carbs': 0.05, 'fat': -0.10},
      'الربو': {'protein': 0.03, 'carbs': -0.03, 'fat': 0},
      'الروماتيزم': {'protein': 0.05, 'carbs': -0.02, 'fat': -0.03},
      'الأنيميا': {'protein': 0.08, 'carbs': 0, 'fat': -0.08},
      'الغدة الدرقية': {'protein': 0.02, 'carbs': -0.02, 'fat': 0},
    };

    for (var disease in diseases) {
      if (diseaseAdjustments.containsKey(disease)) {
        final adj = diseaseAdjustments[disease]!;
        proteinRatio += adj['protein'] ?? 0;
        carbsRatio += adj['carbs'] ?? 0;
        fatRatio += adj['fat'] ?? 0;
      }
    }

    // ضبط النسب لتكون بين 0.15 و 0.60
    proteinRatio = proteinRatio.clamp(0.15, 0.60);
    carbsRatio = carbsRatio.clamp(0.25, 0.65);
    fatRatio = fatRatio.clamp(0.15, 0.45);

    // ضبط النسب لتكون 100%
    double total = proteinRatio + carbsRatio + fatRatio;
    proteinRatio = proteinRatio / total;
    carbsRatio = carbsRatio / total;
    fatRatio = fatRatio / total;

    return {
      'protein': (calories * proteinRatio) / 4,
      'carbs': (calories * carbsRatio) / 4,
      'fat': (calories * fatRatio) / 9,
    };
  }

  // ============================================
  // ✅ حساب احتياج الماء
  // ============================================
  static double calculateWaterIntake(double weight, List<String> diseases) {
    double baseWater = weight * 0.033;

    Map<String, double> diseaseWaterFactors = {
      'السكري': 1.2,
      'ضغط الدم': 1.15,
      'القلب': 1.1,
      'الكوليسترول': 1.05,
      'الأنيميا': 1.0,
      'الروماتيزm': 1.05,
    };

    for (var disease in diseases) {
      if (diseaseWaterFactors.containsKey(disease)) {
        baseWater *= diseaseWaterFactors[disease]!;
      }
    }

    return baseWater.clamp(1.5, 4.0);
  }

  // ============================================
  // ✅ حساب هدف المشي اليومي
  // ============================================
  static int calculateDailyStepsGoal({
    required double weight,
    required String goal,
    required String activityLevel,
    List<String>? diseases,
  }) {
    int baseSteps = 5000;

    Map<String, int> goalSteps = {'تخسيس': 8000, 'تثبيت': 6000, 'زيادة': 4000};
    baseSteps = goalSteps[goal] ?? 5000;

    if (weight > 100) baseSteps += 2000;
    else if (weight > 80) baseSteps += 1000;
    else if (weight < 50) baseSteps -= 500;

    Map<String, int> activitySteps = {
      'قليل': -1000,
      'متوسط': 0,
      'عالي': 2000,
      'مكثف': 3000,
    };
    baseSteps += activitySteps[activityLevel] ?? 0;

    if (diseases != null) {
      Map<String, int> diseaseSteps = {
        'السكري': 1000,
        'ضغط الدم': 500,
        'الكوليسترول': 800,
        'القلب': -500,
        'الربو': -300,
        'الروماتيزم': -800,
        'الأنيميا': -1000,
      };
      for (var disease in diseases) {
        if (diseaseSteps.containsKey(disease)) {
          baseSteps += diseaseSteps[disease]!;
        }
      }
    }

    return baseSteps.clamp(3000, 15000);
  }

  // ============================================
  // ✅ حساب مؤشر كتلة الجسم (BMI)
  // ============================================
  static double calculateBMI({required double weight, required double height}) {
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // ============================================
  // ✅ تفسير BMI
  // ============================================
  static Map<String, dynamic> interpretBMI(double bmi) {
    if (bmi < 18.5) {
      return {
        'status': 'نقص وزن',
        'color': AppColors.warning,
        'icon': '⚠️',
        'advice': 'يُنصح بزيادة السعرات الحرارية وتناول أطعمة غنية بالعناصر الغذائية',
      };
    } else if (bmi >= 18.5 && bmi < 25) {
      return {
        'status': 'وزن طبيعي',
        'color': AppColors.success,
        'icon': '✅',
        'advice': 'حافظ على وزنك الصحي باتباع نظام غذائي متوازن',
      };
    } else if (bmi >= 25 && bmi < 30) {
      return {
        'status': 'زيادة وزن',
        'color': AppColors.warning,
        'icon': '⚠️',
        'advice': 'يُنصح بتقليل السعرات وزيادة النشاط البدني',
      };
    } else {
      return {
        'status': 'سمنة',
        'color': AppColors.danger,
        'icon': '🚨',
        'advice': 'استشر طبيبك لوضع خطة صحية مناسبة لإنقاص الوزن',
      };
    }
  }

  // ============================================
  // ✅ حساب نسبة الدهون التقريبية (Body Fat %)
  // ============================================
  static double estimateBodyFat({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    double bmi = calculateBMI(weight: weight, height: height);

    if (gender == 'ذكر') {
      return (1.20 * bmi) + (0.23 * age) - 16.2;
    } else {
      return (1.20 * bmi) + (0.23 * age) - 5.4;
    }
  }

  // ============================================
  // ✅ حساب الوقت المتوقع للوصول للهدف
  // ============================================
  static Map<String, dynamic> calculateTimeToGoal({
    required double currentWeight,
    required double targetWeight,
    required double weeklyRate,
    required String goal,
  }) {
    double weightDifference = (currentWeight - targetWeight).abs();
    double weeksNeeded = weightDifference / weeklyRate;
    double monthsNeeded = weeksNeeded / 4;
    double caloriesDeficit = weeklyRate * 7700 / 7;

    return {
      'weeks': weeksNeeded.round(),
      'months': monthsNeeded.round(),
      'daily_calories_change': caloriesDeficit.round(),
      'is_realistic': weeksNeeded <= 52,
    };
  }

  // ============================================
  // ✅ حساب احتياج البروتين حسب النشاط
  // ============================================
  static double calculateProteinNeed({
    required double weight,
    required int activityMinutes,
    required String goal,
  }) {
    double baseProtein = weight * 0.8;

    if (activityMinutes > 60) {
      baseProtein *= 1.5;
    } else if (activityMinutes > 30) {
      baseProtein *= 1.2;
    }

    if (goal == 'زيادة') {
      baseProtein *= 1.3;
    } else if (goal == 'تخسيس') {
      baseProtein *= 1.2;
    }

    return baseProtein.clamp(weight * 0.8, weight * 2.2);
  }

  // ============================================
  // ✅ توزيع السعرات على الوجبات حسب الوقت
  // ============================================
  static Map<String, double> distributeCaloriesByTime({
    required double totalCalories,
    required String goal,
    required int wakeUpHour,
    required int sleepHour,
  }) {
    int awakeHours = sleepHour - wakeUpHour;
    if (awakeHours <= 0) awakeHours += 24;

    double breakfastRatio = 0.25;
    double lunchRatio = 0.35;
    double dinnerRatio = 0.25;
    double snacksRatio = 0.15;

    if (goal == 'تخسيس') {
      breakfastRatio = 0.30;
      lunchRatio = 0.35;
      dinnerRatio = 0.20;
      snacksRatio = 0.15;
    } else if (goal == 'زيادة') {
      breakfastRatio = 0.25;
      lunchRatio = 0.30;
      dinnerRatio = 0.25;
      snacksRatio = 0.20;
    }

    return {
      'فطور': totalCalories * breakfastRatio,
      'غداء': totalCalories * lunchRatio,
      'عشاء': totalCalories * dinnerRatio,
      'سناك': totalCalories * snacksRatio,
    };
  }

  // ============================================
  // ✅ تقييم جودة الوجبة
  // ============================================
  static Map<String, dynamic> evaluateMealQuality({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required double fiber,
  }) {
    int score = 0;
    List<String> feedback = [];

    if (protein >= 20) {
      score += 25;
      feedback.add('✅ مصدر بروتين ممتاز');
    } else if (protein >= 10) {
      score += 15;
      feedback.add('⚠️ مصدر بروتين متوسط');
    } else {
      feedback.add('❌ يحتاج لمصدر بروتين');
    }

    if (fiber >= 5) {
      score += 25;
      feedback.add('✅ غني بالألياف');
    } else if (fiber >= 2) {
      score += 10;
      feedback.add('⚠️ يحتوي على ألياف قليلة');
    } else {
      feedback.add('❌ يفضل إضافة خضروات');
    }

    if (fat <= 15) {
      score += 25;
      feedback.add('✅ دهون صحية');
    } else if (fat <= 25) {
      score += 10;
      feedback.add('⚠️ دهون متوسطة');
    } else {
      feedback.add('❌ يحتوي على دهون عالية');
    }

    if (calories >= 300 && calories <= 600) {
      score += 25;
      feedback.add('✅ سعرات مناسبة للوجبة');
    } else if (calories < 300) {
      feedback.add('⚠️ سعرات قليلة للوجبة الرئيسية');
    } else {
      feedback.add('⚠️ سعرات عالية للوجبة');
    }

    String rating;
    if (score >= 80) {
      rating = 'ممتاز';
    } else if (score >= 60) {
      rating = 'جيد';
    } else if (score >= 40) {
      rating = 'متوسط';
    } else {
      rating = 'يحتاج تحسين';
    }

    return {'score': score, 'rating': rating, 'feedback': feedback};
  }

  // ============================================
  // ✅ نصائح غذائية عامة
  // ============================================
  static List<String> getGeneralTips() {
    return [
      '✅ **نصائح عامة**:',
      '• تناول 5 حصص من الخضار والفواكه يومياً',
      '• اشرب الماء بانتظام طوال اليوم (2-3 لتر)',
      '• مارس النشاط البدني بانتظام (30 دقيقة يومياً)',
      '• نم 7-8 ساعات يومياً لصحة أفضل',
    ];
  }

  // ============================================
  // ✅ نصائح غذائية حسب الأمراض
  // ============================================
  static Future<List<String>> getDiseaseSpecificTips(List<String> diseases) async {
    List<String> tips = [];

    Map<String, List<String>> diseaseTips = {
      'السكري': [
        '🍬 **مرض السكري**:',
        '• قسم وجباتك إلى 3 رئيسية و2-3 سناكات',
        '• تجنب السكريات البسيطة والمشروبات المحلاة',
        '• تناول الألياف في كل وجبة (خضار - فواكه)',
        '• اختر الكربوهيدرات المعقدة (شوفان - بطاطا - أرز بني)',
        '• راقب كمية الكارب في كل وجبة (30-45 جرام/وجبة)',
      ],
      'ضغط الدم': [
        '💓 **ضغط الدم**:',
        '• قلل الملح في الطعام (أقل من 5 جرام يومياً)',
        '• تجنب الأطعمة المصنعة والمعلبة',
        '• تناول أطعمة غنية بالبوتاسيوم (موز - أفوكادو - بطاطا - سبانخ)',
        '• استخدم الأعشاب والبهارات بدل الملح',
      ],
      'الكوليسترول': [
        '🧪 **الكوليسترول**:',
        '• قلل الدهون المشبعة (اللحوم الحمراء - الزبدة)',
        '• تناول أوميغا 3 (أسماك - مكسرات - بذور الكتان)',
        '• زد من الألياف القابلة للذوبان (شوفان - تفاح - بقوليات)',
        '• اختر مصادر بروتين قليلة الدهون (دجاج منزوع الجلد - أسماك)',
      ],
      'القلب': [
        '❤️ **أمراض القلب**:',
        '• اتبع نظاماً قليل الدهون والملح',
        '• تناول الأسماك مرتين أسبوعياً على الأقل',
        '• تجنب الأطعمة المقلية والدهون المشبعة',
        '• تناول الخضروات والفواكه بكثرة (5 حصص يومياً)',
      ],
    };

    for (var disease in diseases) {
      if (diseaseTips.containsKey(disease)) {
        tips.addAll(diseaseTips[disease]!);
      }
    }

    if (tips.isEmpty) {
      tips.addAll(getGeneralTips());
    }

    return tips;
  }

  // ============================================
  // ✅ تحليل الأعراض وعلاقتها بالأمراض
  // ============================================
  static Future<String?> analyzeSymptomWithDisease(
    String symptom,
    List<String> diseases,
  ) async {
    if (diseases.contains('السكري')) {
      if (symptom == 'دوخة') {
        return '⚠️ الدوخة قد تكون بسبب انخفاض السكر - قس سكرك فوراً';
      }
      if (symptom == 'عطش شديد') {
        return '⚠️ العطش الشديد قد يشير لارتفاع السكر';
      }
      if (symptom == 'تعب') {
        return '⚠️ التعب قد يكون بسبب ارتفاع أو انخفاض السكر';
      }
    }

    if (diseases.contains('ضغط الدم')) {
      if (symptom == 'صداع') {
        return '⚠️ الصداع قد يكون بسبب ارتفاع الضغط - قس ضغطك';
      }
      if (symptom == 'دوخة') {
        return '⚠️ الدوخة قد تكون بسبب انخفاض الضغط';
      }
    }

    if (diseases.contains('القلب')) {
      if (symptom == 'ألم صدر') {
        return '🚨 هذا عرض خطير - توجه للطوارئ فوراً';
      }
      if (symptom == 'ضيق تنفس') {
        return '🚨 ضيق التنفس قد يشير لمشكلة في القلب - استشر طبيبك';
      }
    }

    return null;
  }

  // ============================================
  // ✅ تأثير الأدوية على الأعراض
  // ============================================
  static Future<String?> checkMedicationSideEffect(
    UserMedication medication,
    String symptom,
  ) async {
    Map<String, List<String>> sideEffectsDB = {
      'أسبرين': ['غثيان', 'حرقة', 'طنين'],
      'جلوكوفاج': ['غثيان', 'إسهال', 'فقدان شهية'],
      'أملوديبين': ['دوخة', 'صداع', 'تورم كاحل'],
      'ليسينوبريل': ['دوخة', 'سعال جاف', 'صداع'],
      'أتورفاستاتين': ['ألم عضلي', 'غثيان', 'إسهال'],
    };

    if (sideEffectsDB.containsKey(medication.name)) {
      if (sideEffectsDB[medication.name]!.contains(symptom)) {
        return '⚠️ هذا العرض قد يكون أثراً جانبياً لـ ${medication.name}';
      }
    }

    return null;
  }

  // ============================================
  // ✅ حساب احتياج الماء مع النشاط
  // ============================================
  static double calculateWaterIntakeWithActivity({
    required double weight,
    required int activityMinutes,
    required List<String> diseases,
  }) {
    double baseWater = calculateWaterIntake(weight, diseases);
    double extraWater = (activityMinutes / 60) * 0.5;
    return (baseWater + extraWater).clamp(1.5, 4.5);
  }

  // ============================================
  // ✅ مقارنة وجبتين غذائيتين
  // ============================================
  static Map<String, dynamic> compareMeals({
    required Map<String, dynamic> meal1,
    required Map<String, dynamic> meal2,
  }) {
    double caloriesDiff = meal1['calories'] - meal2['calories'];
    double proteinDiff = meal1['protein'] - meal2['protein'];
    double carbsDiff = meal1['carbs'] - meal2['carbs'];
    double fatDiff = meal1['fat'] - meal2['fat'];

    return {
      'calories_diff': caloriesDiff,
      'protein_diff': proteinDiff,
      'carbs_diff': carbsDiff,
      'fat_diff': fatDiff,
      'better_for_weight_loss': caloriesDiff > 0 ? 'meal2' : 'meal1',
      'better_for_muscle_gain': proteinDiff > 0 ? 'meal1' : 'meal2',
    };
  }

  // ============================================
  // ✅ حساب السعرات المناسبة للتمرين
  // ============================================
  static int calculatePreWorkoutCalories({
    required int workoutDuration,
    required String workoutType,
  }) {
    switch (workoutType) {
      case 'cardio':
        return (workoutDuration * 5).clamp(100, 300);
      case 'strength':
        return (workoutDuration * 7).clamp(150, 400);
      case 'mixed':
        return (workoutDuration * 6).clamp(120, 350);
      default:
        return 200;
    }
  }
}