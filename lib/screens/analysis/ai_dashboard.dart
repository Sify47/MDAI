// lib/screens/analysis/ai_dashboard.dart
// 🧠 لوحة التحكم الذكية - نسخة معاد هيكلتها باستخدام مكونات منفصلة

import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/water_service.dart';
import '../../services/nutrition_api.dart';
import '../../services/symptom_api.dart';
import '../../services/medication_api.dart';
import '../../services/quiz_service.dart';
import '../../services/diabetes_api.dart';
import '../../services/community_api.dart';
import '../../constants/colors.dart';
import '../../utils/prefs_helper.dart';
import '../../models/symptom_model.dart';
import '../../models/quiz_models.dart';
import '../../models/diabetes_models.dart';
import '../../models/community_models.dart';
import '../../widgets/ai_dashboard/health_score_card.dart';
import '../../widgets/ai_dashboard/water_analysis_card.dart';
import '../../widgets/ai_dashboard/nutrition_card.dart';
import '../../widgets/ai_dashboard/symptom_card.dart';
import '../../widgets/ai_dashboard/personalized_tips_card.dart';
import '../../widgets/ai_dashboard/diabetes_card.dart';
import '../../widgets/ai_dashboard/quiz_card.dart';
import '../../widgets/ai_dashboard/community_card.dart';
import '../../widgets/ai_dashboard/loading_shimmer.dart';
import '../../widgets/ai_dashboard/error_view.dart';
import '../../widgets/ai_dashboard/ml_prediction_card.dart';
import '../../models/dashboard_model.dart' hide Symptom;

// ========== إضافات UI/UX الجديدة ==========
import '../../widgets/ai_dashboard/time_range_selector.dart';
import '../../widgets/ai_dashboard/nutrition_charts_card.dart';

// ========== بطاقات الخدمات الجديدة ==========
import '../../widgets/ai_dashboard/dynamic_targets_card.dart';
import '../../widgets/ai_dashboard/activity_card.dart';
import '../../widgets/ai_dashboard/challenges_card.dart';
import '../../widgets/ai_dashboard/behavioral_nudge_card.dart';

class AIDashboard extends StatefulWidget {
  const AIDashboard({Key? key}) : super(key: key);

  @override
  State<AIDashboard> createState() => _AIDashboardState();
}

class _AIDashboardState extends State<AIDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ========== حالة التحميل التدريجي ==========
  bool _isLoading = true;
  bool _isCriticalLoaded = false;
  bool _isSecondaryLoaded = false;
  String? _errorMessage;

  // ========== منتقي النطاق الزمني ==========
  TimeRange _selectedTimeRange = TimeRange.day;

  // ========== بيانات اللوحة الأساسية ==========
  Map<String, dynamic> _aiData = {};
  Map<String, dynamic> _waterData = {};
  Map<String, dynamic> _nutritionAnalysis = {};
  List<Symptom> _recentSymptoms = [];

  // بيانات المستخدم (من PrefsHelper)
  Map<String, dynamic> _userProfile = {};

  // بيانات الكويز
  QuizAnalysisResult? _quizAnalysis;

  // بيانات التحليل المتكامل
  Map<String, dynamic>? _diabetesAnalysis;

  // بيانات الكويز اليومي
  DailyQuizStatus? _dailyQuizStatus;
  List<DailyQuizStatus> _dailyQuizStats = [];

  // بيانات المجتمع
  Map<String, dynamic>? _communityStats;
  List<CommunityPost> _trendingCommunityPosts = [];

  // بيانات توقع الوزن بالذكاء الاصطناعي
  MLPredictionData? _mlPrediction;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _loadUserProfile();
    _loadAllData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _userProfile = PrefsHelper.getUserData();
    });
  }

  // ========== تحميل تدريجي ==========

  /// 🛡️ غلاف آمن — يلتقط أي استثناء (timeout, socket, format, etc.)
  /// ويرجع null بدلاً من رمي الاستثناء، حتى لا يفشل Future.wait بالكامل
  Future<dynamic> _safeCall(Future<dynamic> future, String label) async {
    try {
      return await future.timeout(const Duration(seconds: 15));
    } on TimeoutException catch (_) {
      print('⚠️ [$label] timeout — استمرار بالبيانات المتاحة');
      return null;
    } catch (e) {
      print('⚠️ [$label] خطأ: $e — استمرار بالبيانات المتاحة');
      return null;
    }
  }

  /// تحميل البيانات الحرجة أولاً (تظهر اللوحة بسرعة)
  Future<void> _loadCriticalData() async {
    try {
      // ✅ كل future مغلف بـ _safeCall — لا يفشل Future.wait بالكامل
      final criticalResults = await Future.wait([
        _safeCall(AIService.getAIDashboard(), 'AIDashboard'),
        _safeCall(
          AIService.getPersonalizedNutritionAdvice(),
          'NutritionAdvice',
        ),
        _safeCall(WaterService.getTodayWater(), 'WaterToday'),
        _safeCall(NutritionService.getTodayMeals(), 'NutritionMeals'),
        _safeCall(SymptomService.getSymptoms(limit: 20), 'Symptoms'),
        _safeCall(MedicationService.getMedications(), 'Medications'),
      ]);

      if (!mounted) return;

      setState(() {
        final dashboardData = criticalResults[0];
        final nutritionAdvice = criticalResults[1];
        final waterData = criticalResults[2];
        final mealsData = criticalResults[3];
        final symptoms = criticalResults[4] is List
            ? criticalResults[4] as List<Symptom>
            : <Symptom>[];

        if (dashboardData != null && dashboardData is Map<String, dynamic>) {
          _aiData = dashboardData;
        }
        if (waterData != null && waterData is Map<String, dynamic>) {
          _waterData = waterData;
        }
        _recentSymptoms = symptoms;
        _nutritionAnalysis = _analyzeNutritionData(
          mealsData as Map<String, dynamic>?,
        );

        if (nutritionAdvice != null &&
            nutritionAdvice is Map<String, dynamic>) {
          if (nutritionAdvice['success'] == true) {
            _aiData['nutrition_advice'] = nutritionAdvice;
          }
        }

        _isCriticalLoaded = true;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ خطأ في تحميل البيانات الحرجة: $e');
      // ✅ بدلاً من عرض خطأ كامل — نعرض اللوحة بالبيانات المتاحة
      if (mounted) {
        setState(() {
          _isCriticalLoaded = true;
          _isLoading = false;
          // لا نعرض _errorMessage — نعرض اللوحة بالبيانات المتاحة فقط
        });
      }
    }
  }

  /// تحميل البيانات الثانوية بعد ظهور اللوحة
  Future<void> _loadSecondaryData() async {
    try {
      final userProfile = PrefsHelper.getUserData();
      final diseases = List<String>.from(userProfile['diseases'] ?? []);
      final hasDiabetes = diseases.contains('السكري');
      final userId = userProfile['id'] ?? 1;

      final diabetesApi = DiabetesApi();

      // ✅ كل future مغلف بـ _safeCall — لا يفشل Future.wait بالكامل
      final secondaryResults = await Future.wait([
        _safeCall(AIService.predictWeight(), 'PredictWeight'),
        _safeCall(QuizService.getSessions(limit: 6), 'QuizSessions'),
        _safeCall(QuizService.analyzeQuiz(), 'QuizAnalysis'),
        _safeCall(QuizService.compareSessions(), 'QuizComparison'),
        _safeCall(QuizService.getTodayQuizStatus(), 'DailyQuizStatus'),
        _safeCall(QuizService.getWeeklyQuizStatus(), 'WeeklyQuizStatus'),
        _safeCall(CommunityApi.getCommunityStats(), 'CommunityStats'),
        _safeCall(
          CommunityApi.getPosts(limit: 5, featured: true),
          'CommunityPosts',
        ),
        _safeCall(
          CommunityApi.getNotifications(limit: 5),
          'CommunityNotifications',
        ),
        if (hasDiabetes)
          _safeCall(
            diabetesApi.getDiabetesAnalysis(userId, 'week'),
            'DiabetesAnalysis',
          ),
        if (hasDiabetes)
          _safeCall(
            diabetesApi.getBloodSugarMeasurements(userId),
            'BloodSugar',
          ),
        if (hasDiabetes)
          _safeCall(
            diabetesApi.getDiabetesSymptoms(userId),
            'DiabetesSymptoms',
          ),
      ]);

      if (!mounted) return;

      setState(() {
        // ✅ تحويل آمن — كل نتيجة قد تكون null من _safeCall
        final weightPrediction = secondaryResults[0] is Map<String, dynamic>
            ? secondaryResults[0] as Map<String, dynamic>
            : null;
        final quizAnalysis = secondaryResults[2] is QuizAnalysisResult
            ? secondaryResults[2] as QuizAnalysisResult
            : null;
        final dailyQuizStatus = secondaryResults[4] is DailyQuizStatus
            ? secondaryResults[4] as DailyQuizStatus
            : null;
        final weeklyQuizStatus = secondaryResults[5] is List<DailyQuizStatus>
            ? secondaryResults[5] as List<DailyQuizStatus>
            : <DailyQuizStatus>[];
        final communityStats = secondaryResults[6] is Map<String, dynamic>
            ? secondaryResults[6] as Map<String, dynamic>
            : null;
        final trendingPosts = secondaryResults[7] is List<CommunityPost>
            ? secondaryResults[7] as List<CommunityPost>
            : <CommunityPost>[];

        DiabetesAnalysis? diabetesAnalysis;

        if (hasDiabetes && secondaryResults.length > 9) {
          diabetesAnalysis = secondaryResults[9] is DiabetesAnalysis
              ? secondaryResults[9] as DiabetesAnalysis
              : null;
        }

        _quizAnalysis = quizAnalysis;
        _dailyQuizStatus = dailyQuizStatus;
        _dailyQuizStats = weeklyQuizStatus;
        _communityStats = communityStats;
        _trendingCommunityPosts = trendingPosts;

        if (weightPrediction != null && weightPrediction['success'] == true) {
          _mlPrediction = MLPredictionData.fromApi(weightPrediction);
        } else {
          _mlPrediction = null;
        }

        if (hasDiabetes && diabetesAnalysis != null) {
          _diabetesAnalysis = {
            'date': diabetesAnalysis.date.toIso8601String(),
            'averageBloodSugar': diabetesAnalysis.averageBloodSugar,
            'measurementCount': diabetesAnalysis.measurementCount,
            'highReadings': diabetesAnalysis.highReadings,
            'lowReadings': diabetesAnalysis.lowReadings,
            'normalReadings': diabetesAnalysis.normalReadings,
            'commonSymptoms': diabetesAnalysis.commonSymptoms,
            'medicationAdherence': diabetesAnalysis.medicationAdherence,
            'controlPercentage': diabetesAnalysis.controlPercentage,
            'controlStatus': diabetesAnalysis.controlStatus,
          };
        }

        _isSecondaryLoaded = true;
      });
    } catch (e) {
      print('❌ خطأ في تحميل البيانات الثانوية: $e');
      if (mounted) {
        setState(() {
          _isSecondaryLoaded = true; // نتابع حتى لو فشلت البيانات الثانوية
        });
      }
    }
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _isCriticalLoaded = false;
      _isSecondaryLoaded = false;
      _errorMessage = null;
    });

    // التحميل المتوازي: البيانات الحرجة أولاً
    await _loadCriticalData();
    if (!mounted) return;

    // ثم التحميل الثانوي بعد ظهور اللوحة
    _loadSecondaryData();
  }

  Map<String, dynamic> _analyzeNutritionData(Map<String, dynamic>? mealsData) {
    if (mealsData == null) {
      return {
        'totalCalories': 0.0,
        'totalProtein': 0.0,
        'totalCarbs': 0.0,
        'totalFat': 0.0,
        'meals': [],
        'analysis': null,
      };
    }

    final totalCalories = (mealsData['total_calories'] ?? 0.0).toDouble();
    final totalProtein = (mealsData['total_protein'] ?? 0.0).toDouble();
    final totalCarbs = (mealsData['total_carbs'] ?? 0.0).toDouble();
    final totalFat = (mealsData['total_fat'] ?? 0.0).toDouble();

    final totalMacros = totalProtein + totalCarbs + totalFat;
    final proteinPercentage = totalMacros > 0
        ? (totalProtein / totalMacros * 100)
        : 0.0;
    final carbsPercentage = totalMacros > 0
        ? (totalCarbs / totalMacros * 100)
        : 0.0;
    final fatPercentage = totalMacros > 0
        ? (totalFat / totalMacros * 100)
        : 0.0;

    List<String> suggestions = [];

    if (totalCalories == 0) {
      suggestions = ['ابدأ بتسجيل وجباتك للحصول على تحليل دقيق'];
    } else {
      if (proteinPercentage < 20) {
        suggestions.add(
          '🥩 نسبة البروتين منخفضة - أضف مصادر بروتين مثل البيض، الدجاج، أو البقوليات',
        );
      } else if (proteinPercentage > 35) {
        suggestions.add(
          '⚖️ نسبة البروتين مرتفعة - وازن وجباتك بإضافة الكربوهيدرات الصحية',
        );
      }
      if (carbsPercentage > 55) {
        suggestions.add(
          '🍚 نسبة الكربوهيدرات مرتفعة - قلل من النشويات وزد الخضروات',
        );
      } else if (carbsPercentage < 30) {
        suggestions.add(
          '🌾 نسبة الكربوهيدرات منخفضة - أضف مصادر طاقة صحية مثل الشوفان أو الأرز البني',
        );
      }
      if (fatPercentage > 35) {
        suggestions.add('🥑 نسبة الدهون مرتفعة - اختر دهون صحية وتجنب المقلية');
      } else if (fatPercentage < 15) {
        suggestions.add(
          '🥜 نسبة الدهون منخفضة - أضف دهون صحية مثل زيت الزيتون أو المكسرات',
        );
      }
    }

    return {
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'proteinPercentage': proteinPercentage,
      'carbsPercentage': carbsPercentage,
      'fatPercentage': fatPercentage,
      'mealsCount': mealsData['meals_count'] ?? 0,
      'suggestions': suggestions,
      'meals': mealsData['meals'] ?? [],
    };
  }

  // ==================== نصائح ذكية مخصصة ====================
  List<Map<String, dynamic>> _getPersonalizedTips() {
    final goal = _userProfile['goal'] ?? 'تخسيس';
    final diseases = List<String>.from(_userProfile['diseases'] ?? []);
    final totalCalories = _nutritionAnalysis['totalCalories'] ?? 0.0;
    final waterIntake = (_waterData['total'] ?? 0.0).toDouble();
    final waterGoal = (_waterData['daily_goal'] ?? 2.5).toDouble();
    final walkingPercentage = (_aiData['walking_percentage'] ?? 0.0).toDouble();

    List<Map<String, dynamic>> tips = [];

    // نصائح حسب الهدف
    if (goal == 'تخسيس') {
      if (totalCalories > 0 && totalCalories > 2000) {
        tips.add({
          'icon': '🔥',
          'title': 'تقليل السعرات',
          'tip':
              'سعراتك اليوم ($totalCalories سعرة) مرتفعة عن الهدف، حاول تقليل 300-500 سعرة',
          'priority': 1,
        });
      } else if (totalCalories > 0 && totalCalories < 1200) {
        tips.add({
          'icon': '⚠️',
          'title': 'سعرات منخفضة',
          'tip':
              'سعراتك منخفضة جداً، هذا قد يبطئ عملية الأيض. تناول وجبات متوازنة',
          'priority': 1,
        });
      } else {
        tips.add({
          'icon': '🥗',
          'title': 'استمرارية',
          'tip': 'استمر في تناول سعرات مناسبة مع زيادة النشاط البدني',
          'priority': 2,
        });
      }
      if (walkingPercentage < 0.5) {
        tips.add({
          'icon': '🏃',
          'title': 'زيادة الحركة',
          'tip': 'المشي يساعد على حرق الدهون، حاول المشي 30-45 دقيقة يومياً',
          'priority': 1,
        });
      }
    } else if (goal == 'زيادة') {
      if (totalCalories > 0 && totalCalories < 2500) {
        tips.add({
          'icon': '💪',
          'title': 'زيادة السعرات',
          'tip':
              'سعراتك الحالية قد لا تكفي لزيادة الوزن، أضف 300-500 سعرة إضافية',
          'priority': 1,
        });
      } else {
        tips.add({
          'icon': '🥩',
          'title': 'بروتين وتمرين',
          'tip':
              'تناول 1.6-2.2 جرام بروتين لكل كجم من وزنك، مع تدريبات المقاومة',
          'priority': 2,
        });
      }
    } else {
      tips.add({
        'icon': '⚖️',
        'title': 'تثبيت الوزن',
        'tip': 'حافظ على توازن السعرات مع النشاط البدني المنتظم',
        'priority': 2,
      });
    }

    // نصائح حسب الأمراض
    for (var disease in diseases) {
      switch (disease) {
        case 'السكري':
          tips.add({
            'icon': '🍬',
            'title': 'مرض السكري',
            'tip':
                'تناول وجبات صغيرة متكررة، وراقب كمية الكربوهيدرات، وامش 30 دقيقة يومياً',
            'priority': 1,
          });
          break;
        case 'ضغط الدم':
          tips.add({
            'icon': '❤️',
            'title': 'ضغط الدم',
            'tip':
                'قلل الملح في الطعام، وتناول أطعمة غنية بالبوتاسيوم (موز، أفوكادو، بطاطس)',
            'priority': 1,
          });
          break;
        case 'القلب':
          tips.add({
            'icon': '🫀',
            'title': 'صحة القلب',
            'tip':
                'تجنب الدهون المشبعة، وزيد من أوميغا 3 (أسماك، مكسرات) والألياف',
            'priority': 1,
          });
          break;
      }
    }

    // نصائح الماء
    if (waterIntake < waterGoal * 0.5) {
      tips.add({
        'icon': '💧',
        'title': 'الجفاف',
        'tip':
            'تحتاج لشرب ${(waterGoal - waterIntake).toStringAsFixed(1)} لتر ماء إضافية اليوم',
        'priority': 1,
      });
    } else if (waterIntake < waterGoal) {
      tips.add({
        'icon': '💧',
        'title': 'شرب الماء',
        'tip':
            'اشرب ${(waterGoal - waterIntake).toStringAsFixed(1)} لتر ماء لتحقيق هدفك اليومي',
        'priority': 2,
      });
    } else if (waterIntake >= waterGoal) {
      tips.add({
        'icon': '💧',
        'title': 'ترطيب ممتاز',
        'tip': 'ممتاز! حافظ على شرب كمية كافية من الماء يومياً',
        'priority': 3,
      });
    }

    // نصائح غذائية إضافية
    final proteinPct = _nutritionAnalysis['proteinPercentage'] ?? 0.0;
    final carbsPct = _nutritionAnalysis['carbsPercentage'] ?? 0.0;
    final fatPct = _nutritionAnalysis['fatPercentage'] ?? 0.0;

    if (proteinPct < 20 && totalCalories > 0) {
      tips.add({
        'icon': '🥚',
        'title': 'البروتين',
        'tip':
            'أضف مصادر بروتين صحية: البيض، الدجاج، السمك، البقوليات، أو الزبادي اليوناني',
        'priority': 2,
      });
    }
    if (carbsPct > 55 && totalCalories > 0) {
      tips.add({
        'icon': '🍚',
        'title': 'الكربوهيدرات',
        'tip': 'قلل من النشويات المكررة (خبز أبيض، أرز أبيض) وزد من الخضروات',
        'priority': 2,
      });
    }
    if (fatPct > 35 && totalCalories > 0) {
      tips.add({
        'icon': '🥑',
        'title': 'الدهون',
        'tip': 'اختر دهون صحية (زيت زيتون، أفوكادو، مكسرات) وتجنب المقلية',
        'priority': 2,
      });
    }

    // نصائح الكويز
    if (_quizAnalysis != null && _quizAnalysis!.hasAnalysis) {
      final quizScore = _quizAnalysis!.totalScore ?? 0;
      if (quizScore < 50) {
        tips.add({
          'icon': '📊',
          'title': 'تحسين الصحة العامة',
          'tip':
              'نتيجة الكويز الشهري ($quizScore%) تشير إلى حاجة لتحسين عاداتك الصحية',
          'priority': 1,
        });
      } else if (quizScore >= 80) {
        tips.add({
          'icon': '🏆',
          'title': 'أداء ممتاز',
          'tip':
              'ممتاز! نتيجة الكويز ($quizScore%) ممتازة. استمر في عاداتك الصحية الرائعة',
          'priority': 3,
        });
      }
    }

    // إزالة التكرار والترتيب حسب الأولوية
    final uniqueTips = <String, Map<String, dynamic>>{};
    for (var tip in tips) {
      final key = tip['title'];
      if (!uniqueTips.containsKey(key) ||
          uniqueTips[key]!['priority'] > tip['priority']) {
        uniqueTips[key] = tip;
      }
    }

    return uniqueTips.values.toList()
      ..sort((a, b) => a['priority'].compareTo(b['priority']));
  }

  // ==================== دوال مساعدة ====================
  double _calculateWeeklyQuizConsistency(List<DailyQuizStatus> statuses) {
    if (statuses.isEmpty) return 0.0;
    final total = statuses.fold<double>(
      0.0,
      (sum, status) => sum + (status.completionPercentage / 100),
    );
    return total / statuses.length;
  }

  String _calculateWeeklyMoodTrend(List<DailyQuizStatus> statuses) {
    if (statuses.isEmpty) return 'مستقر';
    final averageScore =
        statuses.fold<double>(
          0.0,
          (sum, status) => sum + status.morningScore + status.eveningScore,
        ) /
        (statuses.length * 2);
    if (averageScore >= 80) return 'جيد جداً';
    if (averageScore >= 50) return 'مستقر';
    return 'متقلب';
  }

  String _getMostFrequentSymptom() {
    if (_recentSymptoms.isEmpty) return '-';
    final frequencies = <String, int>{};
    for (var symptom in _recentSymptoms) {
      frequencies[symptom.name] = (frequencies[symptom.name] ?? 0) + 1;
    }
    return frequencies.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // ==================== البناء الرئيسي ====================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final healthScore = (_aiData['overall_health_score'] ?? 70).toInt();
    final diseases = List<String>.from(_userProfile['diseases'] ?? []);
    final hasDiabetes = diseases.contains('السكري');
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('🧠 التحليلات الذكية'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllData,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _buildBody(
          theme,
          isDark,
          healthScore,
          diseases,
          hasDiabetes,
          isTablet,
        ),
      ),
    );
  }

  // ==================== بناء المحتوى الرئيسي ====================
  Widget _buildBody(
    ThemeData theme,
    bool isDark,
    int healthScore,
    List<String> diseases,
    bool hasDiabetes,
    bool isTablet,
  ) {
    // مرحلة التحميل الأولي (كل شيء)
    if (_isLoading && !_isCriticalLoaded) {
      return const DashboardLoadingShimmer();
    }

    // خطأ فادح
    if (_errorMessage != null && !_isCriticalLoaded) {
      return DashboardErrorView(
        errorMessage: _errorMessage,
        onRetry: _loadAllData,
      );
    }

    // البيانات الحرجة متاحة → نعرض اللوحة
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadAllData,
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== منتقي النطاق الزمني ==========
              _buildTimeRangeSelector(theme, isDark),

              const SizedBox(height: 16),

              // ========== صف البطاقات المتجاوبة (Tablet → صفين، موبايل → عمود) ==========
              if (isTablet)
                _buildTabletLayout(
                  theme,
                  isDark,
                  healthScore,
                  diseases,
                  hasDiabetes,
                )
              else
                _buildMobileLayout(
                  theme,
                  isDark,
                  healthScore,
                  diseases,
                  hasDiabetes,
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ========== منتقي النطاق الزمني ==========
  Widget _buildTimeRangeSelector(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TimeRangeSelector(
        selected: _selectedTimeRange,
        onChanged: (range) {
          setState(() {
            _selectedTimeRange = range;
          });
          // يمكن إعادة تحميل البيانات حسب النطاق مستقبلاً
        },
      ),
    );
  }

  // ========== تخطيط الموبايل (عمودي) ==========
  Widget _buildMobileLayout(
    ThemeData theme,
    bool isDark,
    int healthScore,
    List<String> diseases,
    bool hasDiabetes,
  ) {
    return Column(
      children: [
        // 🏥 درجة الصحة
        HealthScoreCard(
          score: healthScore,
          nutritionScore: _nutritionAnalysis['totalCalories'] > 0 ? 0.7 : 0.0,
          walkingPercentage: _aiData['walking_percentage'] ?? 0.5,
          waterProgress:
              (_waterData['total'] ?? 0.0) / (_waterData['daily_goal'] ?? 2.5),
          onTap: () => _showHealthScoreExplanation(context),
        ),

        const SizedBox(height: 16),

        // 🎯 الأهداف الديناميكية
        const DynamicTargetsCard(),

        const SizedBox(height: 16),

        // 🏃 الأنشطة البدنية
        const ActivityCard(),

        const SizedBox(height: 16),

        // 💧 تحليل الماء
        WaterAnalysisCard(
          totalWater: (_waterData['total'] ?? 0.0).toDouble(),
          dailyGoal: (_waterData['daily_goal'] ?? 2.5).toDouble(),
        ),

        const SizedBox(height: 16),

        // 🍽️ التغذية + الرسوم البيانية
        NutritionCard(
          totalCalories: (_nutritionAnalysis['totalCalories'] ?? 0.0)
              .toDouble(),
          totalProtein: (_nutritionAnalysis['totalProtein'] ?? 0.0).toDouble(),
          totalCarbs: (_nutritionAnalysis['totalCarbs'] ?? 0.0).toDouble(),
          totalFat: (_nutritionAnalysis['totalFat'] ?? 0.0).toDouble(),
          proteinPct: (_nutritionAnalysis['proteinPercentage'] ?? 0.0)
              .toDouble(),
          carbsPct: (_nutritionAnalysis['carbsPercentage'] ?? 0.0).toDouble(),
          fatPct: (_nutritionAnalysis['fatPercentage'] ?? 0.0).toDouble(),
          suggestions: List<String>.from(
            _nutritionAnalysis['suggestions'] ?? [],
          ),
          mealsCount: (_nutritionAnalysis['mealsCount'] ?? 0).toInt(),
        ),

        const SizedBox(height: 16),

        // 📊 رسم بياني للتغذية
        _isSecondaryLoaded
            ? NutritionChartsCard(
                protein: (_nutritionAnalysis['totalProtein'] ?? 0.0).toDouble(),
                carbs: (_nutritionAnalysis['totalCarbs'] ?? 0.0).toDouble(),
                fat: (_nutritionAnalysis['totalFat'] ?? 0.0).toDouble(),
              )
            : const DashboardLoadingShimmer(
                specificType: ShimmerCardType.chart,
              ),

        const SizedBox(height: 16),

        // 🤒 الأعراض
        SymptomCard(
          symptoms: _recentSymptoms,
          mostFrequentSymptom: _getMostFrequentSymptom(),
        ),

        const SizedBox(height: 16),

        // 🧪 توقع الوزن (بيانات ثانوية)
        if (_isSecondaryLoaded && _mlPrediction != null) ...[
          MLPredictionCard(prediction: _mlPrediction!),
          const SizedBox(height: 16),
        ],

        // 🧠 تحفيزات سلوكية (بيانات ثانوية)
        _isSecondaryLoaded
            ? const BehavioralNudgeCard()
            : const DashboardLoadingShimmer(specificType: ShimmerCardType.tips),

        const SizedBox(height: 16),

        // 📈 التحليل المتكامل (بيانات ثانوية)
        _isSecondaryLoaded
            ? _buildIntegratedAnalysisSection(theme, hasDiabetes)
            : const DashboardLoadingShimmer(
                specificType: ShimmerCardType.stats,
              ),

        const SizedBox(height: 16),

        // 🏆 التحديات (بيانات ثانوية)
        _isSecondaryLoaded
            ? const ChallengesCard()
            : const DashboardLoadingShimmer(
                specificType: ShimmerCardType.stats,
              ),

        const SizedBox(height: 16),

        // 💡 النصائح الذكية
        _isSecondaryLoaded
            ? PersonalizedTipsCard(
                tips: _getPersonalizedTips(),
                onTipTap: (tip) => _showTipExplanation(context, tip),
              )
            : const DashboardLoadingShimmer(specificType: ShimmerCardType.tips),

        const SizedBox(height: 16),

        // مؤشر تحميل البيانات الثانوية (إذا لم تكتمل بعد)
        if (!_isSecondaryLoaded) _buildSecondaryLoadingIndicator(),
      ],
    );
  }

  // ========== تخطيط التابلت (شبكة 2 عمود) ==========
  Widget _buildTabletLayout(
    ThemeData theme,
    bool isDark,
    int healthScore,
    List<String> diseases,
    bool hasDiabetes,
  ) {
    return Column(
      children: [
        // الصف الأول: درجة الصحة + الأهداف
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HealthScoreCard(
                score: healthScore,
                nutritionScore: _nutritionAnalysis['totalCalories'] > 0
                    ? 0.7
                    : 0.0,
                walkingPercentage: _aiData['walking_percentage'] ?? 0.5,
                waterProgress:
                    (_waterData['total'] ?? 0.0) /
                    (_waterData['daily_goal'] ?? 2.5),
                onTap: () => _showHealthScoreExplanation(context),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: DynamicTargetsCard()),
          ],
        ),

        const SizedBox(height: 16),

        // الصف الثاني: الأنشطة + الماء
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: ActivityCard()),
            const SizedBox(width: 16),
            Expanded(
              child: WaterAnalysisCard(
                totalWater: (_waterData['total'] ?? 0.0).toDouble(),
                dailyGoal: (_waterData['daily_goal'] ?? 2.5).toDouble(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // الصف الثالث: التغذية + الرسم البياني
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: NutritionCard(
                totalCalories: (_nutritionAnalysis['totalCalories'] ?? 0.0)
                    .toDouble(),
                totalProtein: (_nutritionAnalysis['totalProtein'] ?? 0.0)
                    .toDouble(),
                totalCarbs: (_nutritionAnalysis['totalCarbs'] ?? 0.0)
                    .toDouble(),
                totalFat: (_nutritionAnalysis['totalFat'] ?? 0.0).toDouble(),
                proteinPct: (_nutritionAnalysis['proteinPercentage'] ?? 0.0)
                    .toDouble(),
                carbsPct: (_nutritionAnalysis['carbsPercentage'] ?? 0.0)
                    .toDouble(),
                fatPct: (_nutritionAnalysis['fatPercentage'] ?? 0.0).toDouble(),
                suggestions: List<String>.from(
                  _nutritionAnalysis['suggestions'] ?? [],
                ),
                mealsCount: (_nutritionAnalysis['mealsCount'] ?? 0).toInt(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isSecondaryLoaded
                  ? NutritionChartsCard(
                      protein: (_nutritionAnalysis['totalProtein'] ?? 0.0)
                          .toDouble(),
                      carbs: (_nutritionAnalysis['totalCarbs'] ?? 0.0)
                          .toDouble(),
                      fat: (_nutritionAnalysis['totalFat'] ?? 0.0).toDouble(),
                    )
                  : const DashboardLoadingShimmer(
                      specificType: ShimmerCardType.chart,
                    ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // الصف الرابع: الأعراض + التحفيزات
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SymptomCard(
                symptoms: _recentSymptoms,
                mostFrequentSymptom: _getMostFrequentSymptom(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isSecondaryLoaded
                  ? const BehavioralNudgeCard()
                  : const DashboardLoadingShimmer(
                      specificType: ShimmerCardType.tips,
                    ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // توقع الوزن (إن وجد)
        if (_isSecondaryLoaded && _mlPrediction != null) ...[
          MLPredictionCard(prediction: _mlPrediction!),
          const SizedBox(height: 16),
        ],

        // الصف الخامس: التحليل المتكامل + التحديات
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _isSecondaryLoaded
                  ? _buildIntegratedAnalysisSection(theme, hasDiabetes)
                  : const DashboardLoadingShimmer(
                      specificType: ShimmerCardType.stats,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _isSecondaryLoaded
                  ? const ChallengesCard()
                  : const DashboardLoadingShimmer(
                      specificType: ShimmerCardType.stats,
                    ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 💡 النصائح الذكية (عرض كامل)
        _isSecondaryLoaded
            ? PersonalizedTipsCard(
                tips: _getPersonalizedTips(),
                onTipTap: (tip) => _showTipExplanation(context, tip),
              )
            : const DashboardLoadingShimmer(specificType: ShimmerCardType.tips),

        const SizedBox(height: 16),

        if (!_isSecondaryLoaded) _buildSecondaryLoadingIndicator(),
      ],
    );
  }

  // ========== مؤشر تحميل البيانات الثانوية ==========
  Widget _buildSecondaryLoadingIndicator() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'جاري تحميل التحليلات المتقدمة...',
            style: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ========== شرح درجة الصحة (BottomSheet مع AI) ==========
  void _showHealthScoreExplanation(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final healthScore = (_aiData['overall_health_score'] ?? 70).toInt();
    final surfaceColor = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final bottomSheetBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : surfaceColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: bottomSheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // مقبض السحب
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: onSurface.withOpacity(isDark ? 0.4 : 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // أيقونة + العنوان
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '🧠 تحليل الذكاء الاصطناعي',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // درجة الصحة
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: healthScore >= 80
                            ? [AppColors.success, AppColors.success.withOpacity(0.7)]
                            : healthScore >= 50
                            ? [AppColors.warning, AppColors.warning.withOpacity(0.7)]
                            : [AppColors.danger, AppColors.danger.withOpacity(0.7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (healthScore >= 80
                                      ? AppColors.success
                                      : healthScore >= 50
                                      ? AppColors.warning
                                      : AppColors.danger)
                                  .withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$healthScore',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: onSurface.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            healthScore >= 80
                                ? 'ممتاز'
                                : healthScore >= 50
                                ? 'جيد'
                                : 'تحتاج تحسين',
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // شرح AI
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getAIHealthExplanation(healthScore),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // تفاصيل العوامل
                Text(
                  '📊 تفاصيل العوامل',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildFactorRow(
                  icon: Icons.restaurant,
                  label: 'التغذية',
                  value: _nutritionAnalysis['totalCalories'] > 0
                      ? 'جيد'
                      : 'غير مسجل',
                  color: _nutritionAnalysis['totalCalories'] > 0
                      ? AppColors.success
                      : onSurface.withOpacity(0.4),
                ),
                const SizedBox(height: 8),
                _buildFactorRow(
                  icon: Icons.directions_walk,
                  label: 'المشي',
                  value: (_aiData['walking_percentage'] ?? 0.0) >= 0.5
                      ? 'جيد'
                      : 'قليل',
                  color: (_aiData['walking_percentage'] ?? 0.0) >= 0.5
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(height: 8),
                _buildFactorRow(
                  icon: Icons.water_drop,
                  label: 'الماء',
                  value:
                      (_waterData['total'] ?? 0.0) >=
                          (_waterData['daily_goal'] ?? 2.5) * 0.7
                      ? 'جيد'
                      : 'قليل',
                  color:
                      (_waterData['total'] ?? 0.0) >=
                          (_waterData['daily_goal'] ?? 2.5) * 0.7
                      ? AppColors.success
                      : AppColors.warning,
                ),

                const SizedBox(height: 20),

                // نصائح
                if (healthScore < 80) ...[
                  Text(
                    '💡 نصائح للتحسين',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._getImprovementTips().map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: TextStyle(color: AppColors.warning)),
                          Expanded(
                            child: Text(
                              tip,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onSurface.withOpacity(isDark ? 0.6 : 0.7),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAIHealthExplanation(int score) {
    if (score >= 85) {
      return 'تبرز درجة صحتك العامة الممتازة ($score%) التزامك بنمط حياة صحي متكامل. '
          'تظهر بياناتك توازناً جيداً في التغذية والنشاط البدني والعناية الذاتية. '
          'استمر في هذا النهج المتميز، واحرص على المراجعة الدورية للفحوصات للوقاية المستمرة.';
    } else if (score >= 70) {
      return 'درجة صحتك ($score%) جيدة وتعكس اهتمامك بصحتك العامة. '
          'هناك بعض المجالات التي يمكن تحسينها للوصول إلى المستوى الأمثل، '
          'خاصة في توازن العناصر الغذائية وانتظام النشاط البدني. '
          'حافظ على عاداتك الإيجابية وركز على تحسين النقاط الأقل.';
    } else if (score >= 50) {
      return 'تشير درجة صحتك ($score%) إلى وجود فرصة للتحسين في عدة جوانب. '
          'نوصي بالتركيز على تحسين النظام الغذائي وزيادة النشاط البدني تدريجياً. '
          'تذكر أن التحسينات الصغيرة والمستدامة تؤدي إلى نتائج كبيرة على المدى الطويل.';
    } else {
      return 'درجة صحتك ($score%) منخفضة وتحتاج إلى اهتمام فوري. '
          'نوصي باستشارة أخصائي صحي لوضع خطة شاملة. '
          'البدء بخطوات بسيطة مثل شرب الماء بانتظام والمشي يومياً يمكن أن يحدث فرقاً كبيراً.';
    }
  }

  List<String> _getImprovementTips() {
    final tips = <String>[];
    final totalCalories = _nutritionAnalysis['totalCalories'] ?? 0.0;
    final waterIntake = (_waterData['total'] ?? 0.0).toDouble();
    final waterGoal = (_waterData['daily_goal'] ?? 2.5).toDouble();

    if (totalCalories == 0) {
      tips.add('سجل وجباتك اليومية للحصول على تحليل غذائي دقيق');
    }
    if (waterIntake < waterGoal * 0.7) {
      tips.add(
        'اشرب ${(waterGoal - waterIntake).toStringAsFixed(1)} لتر ماء إضافية',
      );
    }
    if ((_aiData['walking_percentage'] ?? 0.0) < 0.5) {
      tips.add('حاول المشي 30 دقيقة على الأقل يومياً');
    }

    if (tips.isEmpty) {
      tips.add('استمر في عاداتك الصحية الممتازة! 🎉');
    }

    return tips;
  }

  Widget _buildFactorRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ========== شرح النصيحة (BottomSheet) ==========
  void _showTipExplanation(BuildContext context, Map<String, dynamic> tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TipExplanationSheet(tip: tip),
    );
  }

  // ==================== قسم التحليل المتكامل ====================
  Widget _buildIntegratedAnalysisSection(ThemeData theme, bool hasDiabetes) {
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(isDark ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights,
                  color: AppColors.info,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '📈 التحليل المتكامل',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              if (hasDiabetes)
                DiabetesCard(
                  controlPercentage:
                      (_diabetesAnalysis?['controlPercentage'] ?? 0.0)
                          .toDouble(),
                  averageBloodSugar:
                      (_diabetesAnalysis?['averageBloodSugar'] ?? 0.0)
                          .toDouble(),
                  measurementCount:
                      (_diabetesAnalysis?['measurementCount'] ?? 0).toInt(),
                ),
              QuizCard(
                morningDone: _dailyQuizStatus?.morningCompleted ?? false,
                eveningDone: _dailyQuizStatus?.eveningCompleted ?? false,
                weeklyConsistency: _calculateWeeklyQuizConsistency(
                  _dailyQuizStats,
                ),
                moodTrend: _calculateWeeklyMoodTrend(_dailyQuizStats),
              ),
              CommunityCard(
                totalPosts: _communityStats?['totalPosts'] ?? 0,
                totalLikes: _communityStats?['totalLikes'] ?? 0,
                totalComments: _communityStats?['totalComments'] ?? 0,
                trendingPostsCount: _trendingCommunityPosts.length,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== BottomSheet شرح النصيحة ====================
class _TipExplanationSheet extends StatelessWidget {
  final Map<String, dynamic> tip;

  const _TipExplanationSheet({required this.tip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final bottomSheetBg = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surface;

    final icon = tip['icon'] ?? '💡';
    final title = tip['title'] ?? 'نصيحة';
    final content = tip['tip'] ?? '';
    final priority = tip['priority'] ?? 2;

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: bottomSheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مقبض
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: onSurface.withOpacity(isDark ? 0.4 : 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // أيقونة + العنوان
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // شارة الأولوية
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: priority == 1
                      ? AppColors.danger.withOpacity(0.1)
                      : priority == 2
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  priority == 1
                      ? '🔴 أولوية عالية'
                      : priority == 2
                      ? '🟡 أولوية متوسطة'
                      : '🟢 أولوية منخفضة',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: priority == 1
                        ? AppColors.danger
                        : priority == 2
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // محتوى النصيحة
              Text(
                content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 20),

              // شرح AI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getAIExplanation(title, content),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAIExplanation(String title, String content) {
    // تحليل ذكي للنصيحة بناءً على محتواها
    if (content.contains('ماء') ||
        content.contains('شرب') ||
        title.contains('ماء')) {
      return 'الحفاظ على ترطيب الجسم ضروري لوظائف الأعضاء الحيوية. '
          'الماء يساعد في تنظيم درجة حرارة الجسم، نقل المغذيات، '
          'وتحسين وظائف الكلى. شرب كمية كافية يومياً يحسن التركيز والطاقة.';
    }
    if (content.contains('سعرات') ||
        content.contains('وجبة') ||
        content.contains('طعام')) {
      return 'توازن السعرات الحرارية هو أساس إدارة الوزن. '
          'يُنصح بتوزيع السعرات على 3-5 وجبات صغيرة خلال اليوم '
          'مع التركيز على الأطعمة الغنية بالألياف والبروتين لزيادة الشبع.';
    }
    if (content.contains('مشي') ||
        content.contains('حركة') ||
        content.contains('نشاط')) {
      return 'النشاط البدني المنتظم يحسن صحة القلب والعظام والمزاج. '
          'المشي 30 دقيقة يومياً يقلل خطر الأمراض المزمنة بنسبة كبيرة. '
          'حاول زيادة خطواتك تدريجياً لتحقيق أهدافك.';
    }
    if (content.contains('نوم') || content.contains('sleep')) {
      return 'النوم الجيد أساسي لصحة الجسم والعقل. '
          'يحتاج البالغون 7-9 ساعات نوم يومياً. '
          'تحسين جودة النوم يعزز المناعة والذاكرة والأداء العام.';
    }
    if (content.contains('ضغط') ||
        content.contains('قلب') ||
        content.contains('قلبية')) {
      return 'صحة القلب والأوعية الدموية تعتمد على نمط حياة متكامل. '
          'تقليل الملح والدهون المشبعة، مع ممارسة الرياضة، '
          'والتحكم بالتوتر، كلها عوامل أساسية للحفاظ على ضغط دم صحي.';
    }

    return 'هذه النصيحة مبنية على تحليل بياناتك الصحية الشخصية. '
        'اتباع التوصيات المناسبة لحالتك يساعد في تحسين نتائجك الصحية '
        'وتحقيق أهدافك بشكل أكثر فعالية وأماناً.';
  }
}
