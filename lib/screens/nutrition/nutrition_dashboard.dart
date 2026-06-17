// lib/screens/nutrition/nutrition_dashboard.dart

import 'package:flutter/material.dart';
import 'package:vita/screens/analysis/water_dashboard.dart';
import '../../../constants/colors.dart';
import '../../../constants/design_constants.dart';
import '../../../models/nutrition_model.dart';
import '../../../models/medication_model.dart';
import '../../../services/nutrition_api.dart';
import '../../../services/medication_api.dart';
import '../../../services/symptom_api.dart';
import '../../../widgets/nutrition/loading_shimmers.dart';
import '../../../widgets/nutrition/empty_nutrition_state.dart';
import '../../../widgets/nutrition/nutrition_card.dart';
import '../../../widgets/nutrition/meal_helpers.dart';
import '../../../utils/nutrition_calculator.dart';
import '../../../models/preferences_model.dart';
import '../../../services/personalization_service.dart';
import 'add_meal_screen.dart';
import 'meal_suggestions_screen.dart';
import 'meal_history_screen.dart';
import 'meal_planner_screen.dart';
import 'ai_insights_screen.dart';

// ✅ استيراد نظام الماء الجديد

class NutritionDashboard extends StatefulWidget {
  final UserNutritionData userData;

  const NutritionDashboard({Key? key, required this.userData})
    : super(key: key);

  @override
  State<NutritionDashboard> createState() => _NutritionDashboardState();
}

class _NutritionDashboardState extends State<NutritionDashboard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Map<String, double> _macros;
  late double _targetCalories;
  late List<String> _diseaseTips;

  List<UserMedication> _userMedications = [];
  Map<String, Map<String, dynamic>> _medicineRecommendations = {};

  Map<String, dynamic> _todayMeals = {
    'totalCalories': 0,
    'totalProtein': 0,
    'totalCarbs': 0,
    'totalFat': 0,
    'meals': [],
  };

  List<NutritionGap> _nutritionGaps = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _initializeData();
    _loadTodayMeals();
    _loadUserMedications();
    _loadPersonalizationData();
    _controller.forward();
  }

  Future<void> _initializeData() async {
    _targetCalories = widget.userData.targetCalories > 0
        ? widget.userData.targetCalories
        : 2000.0;

    _macros = NutritionCalculator.calculateMacros(
      calories: _targetCalories,
      goal: widget.userData.goal,
      diseases: widget.userData.diseases,
    );

    _diseaseTips = await NutritionCalculator.getDiseaseSpecificTips(
      widget.userData.diseases,
    );
  }

  Future<void> _loadUserMedications() async {
    if (!mounted) return;

    try {
      final medications = await MedicationService.getMedications();

      if (!mounted) return;

      setState(() {
        _userMedications = medications;
      });

      for (var med in medications) {
        final recs = await SymptomService.getMedicineImpact(
          med.medicineId ?? 0,
        );
        if (!mounted) return;

        if (recs['success']) {
          setState(() {
            _medicineRecommendations[med.name] = {
              'foods_to_avoid': recs['foods_to_avoid'] ?? [],
              'foods_to_eat': recs['foods_to_eat'] ?? [],
              'drinks_to_avoid': recs['drinks_to_avoid'] ?? [],
              'drinks_recommended': recs['drinks_recommended'] ?? [],
              'timing_instructions': recs['timing_instructions'] ?? '',
            };
          });
        }
      }
    } catch (e) {
      print('❌ خطأ في تحميل الأدوية: $e');
    }
  }

  Future<void> _loadTodayMeals() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meals = await NutritionService.getTodayMeals();

      if (!mounted) return;

      if (meals != null) {
        setState(() {
          _todayMeals = {
            'totalCalories':
                meals['total_calories'] ?? meals['totalCalories'] ?? 0,
            'totalProtein':
                meals['total_protein'] ?? meals['totalProtein'] ?? 0,
            'totalCarbs': meals['total_carbs'] ?? meals['totalCarbs'] ?? 0,
            'totalFat': meals['total_fat'] ?? meals['totalFat'] ?? 0,
            'meals': meals['meals'] ?? [],
          };
          _isLoading = false;
        });
        // تحليل الفجوات الغذائية بعد تحميل الوجبات
        final gaps = PersonalizationService.analyzeNutritionGaps(
          currentCalories: (_todayMeals['totalCalories'] as num).toDouble(),
          currentProtein: (_todayMeals['totalProtein'] as num).toDouble(),
          currentCarbs: (_todayMeals['totalCarbs'] as num).toDouble(),
          currentFat: (_todayMeals['totalFat'] as num).toDouble(),
          targetCalories: _targetCalories,
          targetProtein: _macros['protein'] ?? 0,
          targetCarbs: _macros['carbs'] ?? 0,
          targetFat: _macros['fat'] ?? 0,
        );
        if (!mounted) return;
        setState(() => _nutritionGaps = gaps);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'فشل في تحميل الوجبات';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPersonalizationData() async {
    if (!mounted) return;
    try {
      final gaps = PersonalizationService.analyzeNutritionGaps(
        currentCalories: (_todayMeals['totalCalories'] ?? 0).toDouble(),
        currentProtein: (_todayMeals['totalProtein'] ?? 0).toDouble(),
        currentCarbs: (_todayMeals['totalCarbs'] ?? 0).toDouble(),
        currentFat: (_todayMeals['totalFat'] ?? 0).toDouble(),
        targetCalories: _targetCalories,
        targetProtein: _macros['protein'] ?? 0,
        targetCarbs: _macros['carbs'] ?? 0,
        targetFat: _macros['fat'] ?? 0,
      );
      if (!mounted) return;
      setState(() => _nutritionGaps = gaps);
    } catch (_) {}
  }

  // ✅ دالة للانتقال إلى شاشة الماء
  void _navigateToWater() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WaterDashboard()),
    );
  }

  // ✅ دالة للانتقال إلى مخطط الوجبات الأسبوعي
  void _navigateToMealPlanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealPlannerScreen(userData: widget.userData),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          title: Semantics(
            label: 'نظام الغذاء الرئيسي',
            header: true,
            child: Text('🍎 نظام الغذاء'),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'شرب الماء',
              child: IconButton(
                icon: Icon(Icons.water_drop, color: theme.colorScheme.primary),
                onPressed: _navigateToWater,
                tooltip: 'شرب الماء',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
            Semantics(
              button: true,
              label: 'مخطط الوجبات الأسبوعي',
              child: IconButton(
                icon: Icon(
                  Icons.calendar_month,
                  color: theme.colorScheme.primary,
                ),
                onPressed: _navigateToMealPlanner,
                tooltip: 'مخطط الوجبات',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
            Semantics(
              button: true,
              label: 'عرض سجل الوجبات',
              child: IconButton(
                icon: Icon(Icons.history, color: theme.colorScheme.primary),
                tooltip: 'سجل الوجبات',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MealHistoryScreen(userData: widget.userData),
                    ),
                  );
                },
              ),
            ),
            Semantics(
              button: true,
              label: 'تحديث البيانات',
              child: IconButton(
                icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                tooltip: 'تحديث',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () {
                  _loadTodayMeals();
                  _loadUserMedications();
                  _loadPersonalizationData();
                },
              ),
            ),
          ],
        ),
        // ✅ Sticky layout: Scrollable content + Fixed bottom action buttons
        body: SafeArea(
          child: _isLoading
              ? const DashboardShimmer()
              : _errorMessage != null
              ? _buildError(theme)
              : Column(
                  children: [
                    // 📜 Scrollable content area
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        child: FadeTransition(
                          opacity: _controller,
                          child: Column(
                            children: [
                              Semantics(
                                label: 'بطاقة السعرات الحرارية اليومية',
                                child: _buildCalorieCard(theme),
                              ),
                              const SizedBox(height: 16),
                              Semantics(
                                label: 'المغذيات اليومية واستهلاك الماء',
                                child: _buildMacrosCard(theme),
                              ),
                              const SizedBox(height: 16),
                              Semantics(
                                label: 'شريط تقدم السعرات الحرارية',
                                child: _buildProgressBar(theme),
                              ),
                              const SizedBox(height: 16),
                              Semantics(
                                label: 'قائمة وجبات اليوم',
                                child: _buildTodayMeals(theme),
                              ),
                              const SizedBox(height: 16),
                              if (_nutritionGaps.isNotEmpty)
                                Semantics(
                                  label: 'فجوات غذائية تحتاج تعويض',
                                  child: _buildNutritionGapsCard(theme),
                                ),
                              const SizedBox(height: 16),
                              if (_userMedications.isNotEmpty)
                                Semantics(
                                  label: 'توصيات الأدوية',
                                  child: _buildMedicinesCard(theme),
                                ),
                              const SizedBox(height: 16),
                              if (_diseaseTips.isNotEmpty)
                                Semantics(
                                  label: 'نصائح مخصصة للحالة الصحية',
                                  child: _buildTipsCard(theme),
                                ),
                              // Bottom breathing room for sticky buttons
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 📌 Sticky action buttons bar
                    _buildStickyActionBar(theme),
                  ],
                ),
        ),
      ),
    );
  }

  /// 📌 Sticky bottom action bar – always visible above the system navigation
  Widget _buildStickyActionBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _buildActionButtons(theme),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: 'إعادة المحاولة',
              child: ElevatedButton(
                onPressed: () {
                  _loadTodayMeals();
                  _loadUserMedications();
                  _loadPersonalizationData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  minimumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('إعادة المحاولة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieCard(ThemeData theme) {
    return NutritionCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        colors: [AppColors.calories, theme.colorScheme.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.calories.withOpacity(0.3),
          spreadRadius: 2,
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        children: [
          const Text(
            'احتياجك اليومي',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _targetCalories.round().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'سعرة',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'لـ ${widget.userData.goal} الوزن',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosCard(ThemeData theme) {
    return NutritionCard.defaultStyle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المغذيات اليومية',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'بروتين ${_macros['protein']?.round() ?? 0} جرام',
                  child: _buildMacroItem(
                    label: 'بروتين',
                    value: _macros['protein']?.round() ?? 0,
                    unit: 'جرام',
                    color: theme.colorScheme.primary,
                    icon: '🥩',
                    theme: theme,
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  label: 'كارب ${_macros['carbs']?.round() ?? 0} جرام',
                  child: _buildMacroItem(
                    label: 'كارب',
                    value: _macros['carbs']?.round() ?? 0,
                    unit: 'جرام',
                    color: AppColors.calories,
                    icon: '🍚',
                    theme: theme,
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  label: 'دهون ${_macros['fat']?.round() ?? 0} جرام',
                  child: _buildMacroItem(
                    label: 'دهون',
                    value: _macros['fat']?.round() ?? 0,
                    unit: 'جرام',
                    color: AppColors.warning,
                    icon: '🥑',
                    theme: theme,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // ✅ زر الانتقال لشاشة الماء بدلاً من عرض احتياج الماء
          Semantics(
            button: true,
            label: 'انتقال إلى تتبع شرب الماء',
            child: InkWell(
              onTap: _navigateToWater,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.water_drop,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💧 شرب الماء',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'تتبع كمية الماء اليومية',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem({
    required String label,
    required int value,
    required String unit,
    required Color color,
    required String icon,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          '$value $unit',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    double consumedCalories = _todayMeals['totalCalories']?.toDouble() ?? 0;
    double progress = _targetCalories > 0
        ? consumedCalories / _targetCalories
        : 0;
    bool isOver = progress > 1;

    return NutritionCard.defaultStyle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'السعرات المستهلكة اليوم',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Semantics(
                label: '$consumedCalories سعرة من أصل $_targetCalories سعرة',
                child: Text(
                  '${consumedCalories.round()} / ${_targetCalories.round()} سعرة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOver
                        ? AppColors.danger
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: isOver
                ? 'تجاوزت الحد المسموح'
                : 'تقدم السعرات ${(progress * 100).round()}%',
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0, 1),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOver
                            ? [
                                AppColors.danger,
                                AppColors.danger.withOpacity(0.7),
                              ]
                            : [theme.colorScheme.primary, AppColors.success],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label:
                    'السعرات المتبقية ${(_targetCalories - consumedCalories).round()} سعرة',
                child: Text(
                  'المتبقي: ${(_targetCalories - consumedCalories).round()} سعرة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
              if (isOver)
                Semantics(
                  label: 'تحذير: تجاوزت الحد المسموح من السعرات',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'تجاوزت الحد المسموح',
                      style: TextStyle(fontSize: 11, color: AppColors.danger),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMeals(ThemeData theme) {
    final meals = _todayMeals['meals'] as List? ?? [];

    if (meals.isEmpty) {
      return NutritionCard.flat(
        child: SizedBox(
          height: 220,
          child: EmptyNutritionState.noMeals(
            onAddMeal: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddMealScreen(userData: widget.userData),
                ),
              ).then((result) {
                if (result == true) {
                  _loadTodayMeals();
                }
              });
            },
          ),
        ),
      );
    }

    return NutritionCard.defaultStyle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'وجبات اليوم',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final meal = meals[index];
              final mealType = meal['type'] ?? '';
              final foods = meal['foods'] as List? ?? [];
              final foodsCount = meal['foods_count'] ?? foods.length;
              Color mealColor = getMealTypeColor(mealType);
              return Semantics(
                label: '${meal['name'] ?? 'وجبة'} من نوع $mealType',
                child: InkWell(
                  onTap: () => _showMealDetailDialog(meal, theme),
                  borderRadius: DesignConstants.borderRadiusItem,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: mealColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              getMealEmoji(mealType),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal['name'] ?? 'وجبة',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Show food names under meal name
                              if (foods.isNotEmpty)
                                Text(
                                  foods
                                      .map((f) => f['name'] ?? 'طعام')
                                      .join('، '),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else
                                Text(
                                  mealType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: '${meal['total_calories'] ?? 0} سعرة حرارية',
                          child: Text(
                            '${meal['total_calories'] ?? 0} سعرة',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.calories,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showMealDetailDialog(Map<String, dynamic> meal, ThemeData theme) {
    final foods = meal['foods'] as List? ?? [];
    final mealType = meal['type'] ?? '';
    final mealColor = getMealTypeColor(mealType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: mealColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        getMealEmoji(mealType),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal['name'] ?? 'وجبة',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          mealType,
                          style: TextStyle(color: mealColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${meal['total_calories'] ?? 0}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.calories,
                        ),
                      ),
                      Text(
                        'سعرة حرارية',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.calories.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (foods.isNotEmpty) ...[
                Text(
                  'الأطعمة',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...foods.map(
                  (f) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: mealColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f['name'] ?? 'طعام',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '${f['quantity']} ${f['unit'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${f['calories']?.toStringAsFixed(0) ?? '0'} سعرة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.calories,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Nutritional summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildNutrientRow(
                      'البروتين',
                      meal['total_protein'] ?? 0,
                      'g',
                      AppColors.protein,
                    ),
                    const SizedBox(height: 6),
                    _buildNutrientRow(
                      'الكربوهيدرات',
                      meal['total_carbs'] ?? 0,
                      'g',
                      AppColors.carbs,
                    ),
                    const SizedBox(height: 6),
                    _buildNutrientRow(
                      'الدهون',
                      meal['total_fat'] ?? 0,
                      'g',
                      AppColors.fat,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (meal['notes'] != null && (meal['notes'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '📝 ${meal['notes']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNutrientRow(
    String label,
    dynamic value,
    String unit,
    Color color,
  ) {
    final num v = (value ?? 0) is int
        ? ((value ?? 0) as int).toDouble()
        : (value ?? 0).toDouble();
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(
          '${v.toStringAsFixed(1)} $unit',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicinesCard(ThemeData theme) {
    return NutritionCard.defaultStyle(
      padding: EdgeInsets.zero,
      child: Semantics(
        label: 'توصيات الأدوية - ${_userMedications.length} أدوية',
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.medications.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication, color: AppColors.medications),
          ),
          title: Text(
            '💊 توصيات أدويتك',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${_userMedications.length} دواء - اضغط للمزيد',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _userMedications.map((med) {
                  final recs = _medicineRecommendations[med.name];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.medication,
                              size: 18,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              med.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              med.dosage,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (recs != null) ...[
                          if (recs['timing_instructions'] != null &&
                              recs['timing_instructions'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      recs['timing_instructions'],
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (recs['foods_to_eat'] != null &&
                              recs['foods_to_eat'].isNotEmpty)
                            _buildRecsChip(
                              '✅ أطعمة مفيدة',
                              recs['foods_to_eat'],
                              AppColors.success,
                              theme,
                            ),

                          if (recs['foods_to_avoid'] != null &&
                              recs['foods_to_avoid'].isNotEmpty)
                            _buildRecsChip(
                              '🚫 أطعمة ممنوعة',
                              recs['foods_to_avoid'],
                              AppColors.danger,
                              theme,
                            ),

                          if (recs['drinks_recommended'] != null &&
                              recs['drinks_recommended'].isNotEmpty)
                            _buildRecsChip(
                              '💧 مشروبات مفيدة',
                              recs['drinks_recommended'],
                              theme.colorScheme.primary,
                              theme,
                            ),

                          if (recs['drinks_to_avoid'] != null &&
                              recs['drinks_to_avoid'].isNotEmpty)
                            _buildRecsChip(
                              '❌ مشروبات ممنوعة',
                              recs['drinks_to_avoid'],
                              AppColors.danger,
                              theme,
                            ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecsChip(
    String title,
    List<dynamic> items,
    Color color,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionGapsCard(ThemeData theme) {
    final shownGaps = _nutritionGaps.take(3).toList();
    return NutritionCard.tips(
      accentColor: Colors.orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'فجوات غذائية تحتاج تعويض',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...shownGaps.map(
            (gap) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(gap.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gap.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          gap.suggestion,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(ThemeData theme) {
    return NutritionCard.tips(
      accentColor: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'نصائح مخصصة لحالتك',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._diseaseTips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                tip,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'تسجيل وجبة جديدة',
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddMealScreen(userData: widget.userData),
                      ),
                    ).then((result) {
                      if (result == true) {
                        _loadTodayMeals();
                      }
                    });
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('تسجيل وجبة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(44, 48),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                button: true,
                label: 'عرض اقتراحات الوجبات',
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MealSuggestionsScreen(userData: widget.userData),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lightbulb, size: 20),
                  label: const Text('اقتراحات'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(44, 48),
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Semantics(
            button: true,
            label: 'فتح رؤى الذكاء الاصطناعي',
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AIInsightsScreen(userData: widget.userData),
                  ),
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('🤖 رؤى الذكاء الاصطناعي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size(44, 48),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
