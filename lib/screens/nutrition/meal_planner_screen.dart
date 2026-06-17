// lib/screens/nutrition/meal_planner_screen.dart
// 🍽️ Meal Planner with Weekly Calendar, Templates, and Favorites

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/meal_plan_model.dart';
import '../../models/nutrition_model.dart';
import '../../services/meal_planner_service.dart';
import '../../services/nutrition_api.dart';
import '../../widgets/nutrition/nutrition_card.dart';
import '../../widgets/nutrition/meal_helpers.dart';
import '../../widgets/nutrition/meal_suggestion_card.dart';

class MealPlannerScreen extends StatefulWidget {
  final UserNutritionData? userData;

  const MealPlannerScreen({super.key, this.userData});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _weekStart = MealPlannerService.getCurrentWeekDays().first;
  List<PlannedMeal> _weekPlans = [];
  List<MealTemplate> _templates = [];
  List<FavoriteMeal> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        MealPlannerService.getPlannedMealsForWeek(_weekStart),
        MealPlannerService.getTemplates(),
        MealPlannerService.getFavorites(),
      ]);
      if (!mounted) return;
      setState(() {
        _weekPlans = results[0] as List<PlannedMeal>;
        _templates = results[1] as List<MealTemplate>;
        _favorites = results[2] as List<FavoriteMeal>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToPreviousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
    _loadAll();
  }

  void _goToNextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
    });
    _loadAll();
  }

  void _goToCurrentWeek() {
    setState(() {
      _weekStart = MealPlannerService.getCurrentWeekDays().first;
    });
    _loadAll();
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
            label: 'مخطط الوجبات الأسبوعي',
            header: true,
            child: Text('🍽️ مخطط الوجبات'),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                text: '📅 الأسبوع',
                icon: Icon(Icons.calendar_month, size: 20),
              ),
              Tab(text: '📋 القوالب', icon: Icon(Icons.bookmark, size: 20)),
              Tab(text: '⭐ المفضلة', icon: Icon(Icons.favorite, size: 20)),
            ],
            labelStyle: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: theme.textTheme.bodySmall,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildWeeklyCalendar(theme, isDark),
                  _buildTemplatesTab(theme, isDark),
                  _buildFavoritesTab(theme, isDark),
                ],
              ),
      ),
    );
  }

  // ============================================
  // 📅 WEEKLY CALENDAR TAB
  // ============================================

  Widget _buildWeeklyCalendar(ThemeData theme, bool isDark) {
    final weekDays = MealPlannerService.getWeekDays(_weekStart);
    final now = DateTime.now();
    final isCurrentWeek = MealPlannerService.isSameDay(
      _weekStart,
      MealPlannerService.getCurrentWeekDays().first,
    );

    return Column(
      children: [
        // Week navigation
        NutritionCard.flat(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'الأسبوع السابق',
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _goToPreviousWeek,
                  tooltip: 'الأسبوع السابق',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  label: isCurrentWeek
                      ? 'هذا الأسبوع'
                      : 'أسبوع ${_weekStart.year}',
                  child: GestureDetector(
                    onTap: isCurrentWeek ? null : _goToCurrentWeek,
                    child: Center(
                      child: Text(
                        isCurrentWeek
                            ? '📅 هذا الأسبوع'
                            : '${_weekStart.day}/${_weekStart.month}/${_weekStart.year}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'الأسبوع القادم',
                child: IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _goToNextWeek,
                  tooltip: 'الأسبوع القادم',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Day cards
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: weekDays.length,
            itemBuilder: (context, index) {
              final day = weekDays[index];
              final dayPlans = _weekPlans
                  .where((p) => p.dayKey == _dayKey(day))
                  .toList();
              final isToday = MealPlannerService.isSameDay(day, now);
              return _buildDayCard(theme, day, dayPlans, isToday, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(
    ThemeData theme,
    DateTime day,
    List<PlannedMeal> plans,
    bool isToday,
    bool isDark,
  ) {
    final dayName = MealPlannerService.dayNamesArabic[day.weekday - 1];
    final dayNum = day.day.toString();
    final totalCal = plans.fold<double>(0, (sum, p) => sum + p.totalCalories);

    return NutritionCard.defaultStyle(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: '$dayName $dayNum${isToday ? " - اليوم" : ""}',
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plans.isNotEmpty)
                        Text(
                          '${plans.length} وجبات • ${totalCal.toInt()} سعرة',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.grey[400]
                                : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'اليوم',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Planned meals list
          if (plans.isNotEmpty) ...[
            const Divider(height: 16),
            ...plans.map((plan) => _buildPlannedMealRow(theme, plan, isDark)),
          ],
          // Add meal button
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'إضافة وجبة لـ $dayName',
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _showAddMealToDay(day),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('إضافة وجبة'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannedMealRow(ThemeData theme, PlannedMeal plan, bool isDark) {
    final typeColor = getMealTypeColor(plan.type);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Semantics(
        label:
            '${plan.type}: ${plan.name} - ${plan.totalCalories.toInt()} سعرة',
        child: Row(
          children: [
            Container(
              width: 6,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${getMealEmoji(plan.type)} ${plan.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${plan.totalCalories.toInt()} سعرة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.grey[400]
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'حذف ${plan.name} من الخطة',
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
                onPressed: () => _removePlannedMeal(plan),
                tooltip: 'حذف',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // 📋 TEMPLATES TAB
  // ============================================

  Widget _buildTemplatesTab(ThemeData theme, bool isDark) {
    if (_templates.isEmpty) {
      return Center(
        child: NutritionCard.tips(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📋', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              Text(
                'لا توجد قوالب بعد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'احفظ وجباتك المفضلة كقوالب لاستخدامها لاحقاً',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: 'إنشاء قالب جديد',
                child: ElevatedButton.icon(
                  onPressed: _showCreateTemplateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('إنشاء قالب'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Create template button
        NutritionCard.flat(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Semantics(
            button: true,
            label: 'إنشاء قالب جديد',
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showCreateTemplateDialog,
                icon: const Icon(Icons.add),
                label: const Text('إنشاء قالب جديد'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _templates.length,
            itemBuilder: (context, index) =>
                _buildTemplateCard(theme, _templates[index], isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
    ThemeData theme,
    MealTemplate template,
    bool isDark,
  ) {
    final typeColor = getMealTypeColor(template.type);
    return NutritionCard.defaultStyle(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Semantics(
        label:
            'قالب: ${template.name} - ${template.type} - ${template.totalCalories.toInt()} سعرة',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${getMealEmoji(template.type)} ${template.type}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'حذف القالب ${template.name}',
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.danger,
                    ),
                    onPressed: () => _deleteTemplate(template),
                    tooltip: 'حذف',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${template.totalCalories.toInt()} سعرة | بروتين: ${template.totalProtein.toInt()}g | كارب: ${template.totalCarbs.toInt()}g | دهون: ${template.totalFat.toInt()}g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              ),
            ),
            if (template.foods.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                template.foods.map((f) => f['name'] ?? '').join(' - '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[500] : AppColors.textHint,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'إضافة ${template.name} إلى خطة اليوم',
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddTemplateToDay(template),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('إضافة إلى خطة اليوم'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ⭐ FAVORITES TAB
  // ============================================

  Widget _buildFavoritesTab(ThemeData theme, bool isDark) {
    if (_favorites.isEmpty) {
      return Center(
        child: NutritionCard.tips(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⭐', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              Text(
                'لا توجد وجبات مفضلة بعد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أضف وجباتك المفضلة من صفحة الوجبات للوصول السريع',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _favorites.length,
      itemBuilder: (context, index) =>
          _buildFavoriteCard(theme, _favorites[index], isDark),
    );
  }

  Widget _buildFavoriteCard(ThemeData theme, FavoriteMeal meal, bool isDark) {
    final typeColor = getMealTypeColor(meal.type);
    return NutritionCard.defaultStyle(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Semantics(
        label:
            'مفضلة: ${meal.name} - ${meal.type} - ${meal.calories.toInt()} سعرة',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${getMealEmoji(meal.type)} ${meal.type}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meal.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'إزالة ${meal.name} من المفضلة',
                  child: IconButton(
                    icon: Icon(
                      Icons.favorite,
                      size: 20,
                      color: AppColors.danger,
                    ),
                    onPressed: () => _removeFavorite(meal),
                    tooltip: 'إزالة من المفضلة',
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                ),
              ],
            ),
            if (meal.description != null && meal.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                meal.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${meal.calories.toInt()} سعرة | بروتين: ${meal.protein.toInt()}g | كارب: ${meal.carbs.toInt()}g | دهون: ${meal.fat.toInt()}g',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[500] : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'إضافة ${meal.name} إلى خطة اليوم',
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddFavoriteToDay(meal),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text('إضافة للخطة'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'حفظ ${meal.name} كقالب',
                    child: OutlinedButton.icon(
                      onPressed: () => _saveFavoriteAsTemplate(meal),
                      icon: const Icon(Icons.bookmark_add, size: 16),
                      label: const Text('حفظ كقالب'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // 🎯 DIALOGS & ACTIONS
  // ============================================

  void _removePlannedMeal(PlannedMeal plan) async {
    await MealPlannerService.removePlannedMeal(
      plan.id,
      DateTime.parse(plan.dayKey),
    );
    _loadAll();
    // ✅ إصلاح: استخدام WidgetsBinding.instance.addPostFrameCallback
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف "${plan.name}" من الخطة'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  // عرض اقتراحات الوجبات تلقائياً بناءً على نوع الوجبة
  void _showSuggestionPicker(DateTime day, String mealType) {
    final goal = widget.userData?.goal ?? 'تخسيس';
    final diseases = widget.userData?.diseases;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return _SuggestionPickerSheet(
          goal: goal,
          diseases: diseases,
          mealType: mealType,
          day: day,
          onSaveSuggestion: _saveSuggestionToDay,
        );
      },
    );
  }

  // حفظ الاقتراح كوجبة مخطط لها
  void _saveSuggestionToDay(
    MealSuggestion suggestion,
    DateTime day,
    String mealType,
    BuildContext bottomSheetContext,
  ) {
    // تحويل مكونات الاقتراح إلى قائمة أطعمة
    List<Map<String, dynamic>> foods = [];
    int totalIngredients = suggestion.ingredients.length;

    if (totalIngredients > 0) {
      double caloriesPerIngredient = suggestion.calories / totalIngredients;
      double proteinPerIngredient = suggestion.protein / totalIngredients;
      double carbsPerIngredient = suggestion.carbs / totalIngredients;
      double fatPerIngredient = suggestion.fat / totalIngredients;

      for (var ingredient in suggestion.ingredients) {
        String ingredientName = ingredient['name'] ?? ingredient.toString();
        String ingredientQuantity = ingredient['quantity']?.toString() ?? '';
        String ingredientUnit = ingredient['unit'] ?? 'جرام';

        foods.add({
          'name': ingredientName,
          'calories': caloriesPerIngredient,
          'protein': proteinPerIngredient,
          'carbs': carbsPerIngredient,
          'fat': fatPerIngredient,
          'unit': ingredientUnit,
          'quantity': ingredientQuantity.isNotEmpty
              ? double.tryParse(ingredientQuantity) ?? 1.0
              : 1.0,
          'food_id': 0,
        });
      }
    } else {
      foods.add({
        'name': suggestion.name,
        'calories': suggestion.calories,
        'protein': suggestion.protein,
        'carbs': suggestion.carbs,
        'fat': suggestion.fat,
        'unit': 'وجبة',
        'quantity': 1.0,
        'food_id': 0,
      });
    }

    final plan = PlannedMeal(
      id: MealPlannerService.generateId(),
      dayKey: _dayKey(day),
      type: mealType,
      name: suggestion.name,
      foods: foods,
      totalCalories: suggestion.calories,
      totalProtein: suggestion.protein,
      totalCarbs: suggestion.carbs,
      totalFat: suggestion.fat,
    );

    MealPlannerService.addPlannedMeal(plan);
    Navigator.pop(bottomSheetContext); // إغلاق البottom sheet
    _loadAll();

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم إضافة "${suggestion.name}" بنجاح'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  void _deleteTemplate(MealTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف القالب'),
        content: Text('هل أنت متأكد من حذف القالب "${template.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await MealPlannerService.deleteTemplate(template.id);
      _loadAll();
    }
  }

  void _removeFavorite(FavoriteMeal meal) async {
    await MealPlannerService.removeFavorite(meal.id);
    _loadAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إزالة "${meal.name}" من المفضلة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Add template to a specific day
  void _showAddTemplateToDay(MealTemplate template) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _buildDayPickerSheet(ctx, template, null, null),
    );
  }

  // Add favorite to a specific day
  void _showAddFavoriteToDay(FavoriteMeal meal) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _buildDayPickerSheet(ctx, null, meal, null),
    );
  }

  // Add meal (generic) to a specific day
  void _showAddMealToDay(DateTime day) {
    String selectedType = 'غداء';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🍽️ إضافة وجبة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إلى ${MealPlannerService.dayNamesArabic[day.weekday - 1]}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'نوع الوجبة',
                border: OutlineInputBorder(),
              ),
              items: mealTypes
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text('${getMealEmoji(t)} $t'),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) selectedType = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // ✅ عرض اقتراحات الوجبات بناءً على نوع الوجبة
              _showSuggestionPicker(day, selectedType);
            },
            child: const Text('التالي'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPickerSheet(
    BuildContext ctx,
    MealTemplate? template,
    FavoriteMeal? favorite,
    PlannedMeal? planned,
  ) {
    final weekDays = MealPlannerService.getWeekDays(_weekStart);
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  template != null
                      ? '📋 ${template.name}'
                      : (favorite != null ? '⭐ ${favorite.name}' : '🍽️'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'إغلاق',
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                  tooltip: 'إغلاق',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اختر اليوم الذي تريد إضافته:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ...weekDays.map((day) {
            final isToday = MealPlannerService.isSameDay(day, now);
            final dayName = MealPlannerService.dayNamesArabic[day.weekday - 1];
            return Semantics(
              button: true,
              label: '$dayName${isToday ? " - اليوم" : ""}',
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isToday ? AppColors.primary : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                title: Text(dayName),
                subtitle: isToday
                    ? Text('اليوم', style: TextStyle(color: AppColors.primary))
                    : null,
                trailing: const Icon(Icons.add_circle_outline),
                minLeadingWidth: 44,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (template != null) {
                    _addTemplateToDay(template, day);
                  } else if (favorite != null) {
                    _addFavoriteToDay(favorite, day);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  void _addTemplateToDay(MealTemplate template, DateTime day) {
    final plan = PlannedMeal(
      id: MealPlannerService.generateId(),
      dayKey: _dayKey(day),
      type: template.type,
      templateId: template.id,
      name: template.name,
      foods: template.foods,
      totalCalories: template.totalCalories,
      totalProtein: template.totalProtein,
      totalCarbs: template.totalCarbs,
      totalFat: template.totalFat,
    );
    MealPlannerService.addPlannedMeal(plan);
    _loadAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ تم إضافة "${template.name}" إلى ${MealPlannerService.dayNamesArabic[day.weekday - 1]}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addFavoriteToDay(FavoriteMeal meal, DateTime day) {
    final foodItem = {
      'foodId': 0,
      'name': meal.name,
      'quantity': 1.0,
      'unit': 'حصة',
      'calories': meal.calories,
      'protein': meal.protein,
      'carbs': meal.carbs,
      'fat': meal.fat,
    };
    final plan = PlannedMeal(
      id: MealPlannerService.generateId(),
      dayKey: _dayKey(day),
      type: meal.type,
      name: meal.name,
      foods: [foodItem],
      totalCalories: meal.calories,
      totalProtein: meal.protein,
      totalCarbs: meal.carbs,
      totalFat: meal.fat,
    );
    MealPlannerService.addPlannedMeal(plan);
    _loadAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ تم إضافة "${meal.name}" إلى ${MealPlannerService.dayNamesArabic[day.weekday - 1]}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCreateTemplateDialog() {
    final nameController = TextEditingController();
    String selectedType = 'غداء';
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📋 إنشاء قالب جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم القالب',
                  hintText: 'مثال: فطور صحي',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'نوع الوجبة',
                  border: OutlineInputBorder(),
                ),
                items: mealTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text('${getMealEmoji(t)} $t'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedType = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesController,
                decoration: const InputDecoration(
                  labelText: 'السعرات (سعرة)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      decoration: const InputDecoration(
                        labelText: 'بروتين (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      decoration: const InputDecoration(
                        labelText: 'كارب (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatController,
                      decoration: const InputDecoration(
                        labelText: 'دهون (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          Semantics(
            button: true,
            label: 'حفظ القالب',
            child: ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                final template = MealTemplate(
                  id: MealPlannerService.generateId(),
                  name: nameController.text.trim(),
                  type: selectedType,
                  foods: [],
                  totalCalories: double.tryParse(caloriesController.text) ?? 0,
                  totalProtein: double.tryParse(proteinController.text) ?? 0,
                  totalCarbs: double.tryParse(carbsController.text) ?? 0,
                  totalFat: double.tryParse(fatController.text) ?? 0,
                );
                MealPlannerService.saveTemplate(template);
                _loadAll();
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(44, 44)),
              child: const Text('حفظ'),
            ),
          ),
        ],
      ),
    );
  }

  void _saveFavoriteAsTemplate(FavoriteMeal meal) {
    final template = MealTemplate(
      id: MealPlannerService.generateId(),
      name: meal.name,
      type: meal.type,
      foods: [
        {
          'foodId': 0,
          'name': meal.name,
          'quantity': 1.0,
          'unit': 'حصة',
          'calories': meal.calories,
          'protein': meal.protein,
          'carbs': meal.carbs,
          'fat': meal.fat,
        },
      ],
      totalCalories: meal.calories,
      totalProtein: meal.protein,
      totalCarbs: meal.carbs,
      totalFat: meal.fat,
    );
    MealPlannerService.saveTemplate(template);
    _loadAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حفظ "${meal.name}" كقالب'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Bottom sheet content for showing meal suggestions as a picker.
/// Extracted as a proper [StatefulWidget] to ensure data loading
/// happens exactly once in [initState], preventing the infinite
/// re-render loop that occurred with [StatefulBuilder] +
/// [WidgetsBinding.instance.addPostFrameCallback] inside the builder.
class _SuggestionPickerSheet extends StatefulWidget {
  final String goal;
  final List<String>? diseases;
  final String mealType;
  final DateTime day;
  final void Function(MealSuggestion, DateTime, String, BuildContext)
  onSaveSuggestion;

  const _SuggestionPickerSheet({
    required this.goal,
    this.diseases,
    required this.mealType,
    required this.day,
    required this.onSaveSuggestion,
  });

  @override
  State<_SuggestionPickerSheet> createState() => _SuggestionPickerSheetState();
}

class _SuggestionPickerSheetState extends State<_SuggestionPickerSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  List<MealSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await NutritionService.getMealSuggestions(
        goal: widget.goal,
        diseases: widget.diseases,
        mealType: widget.mealType,
        timeAware: false,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'فشل في تحميل الاقتراحات: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الـ sheet
          Row(
            children: [
              Expanded(
                child: Text(
                  '${getMealEmoji(widget.mealType)} اقتراحات ${widget.mealType}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'اختر وجبة من الاقتراحات التالية:',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 16),
          // المحتوى حسب الحالة
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadSuggestions,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : _suggestions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد اقتراحات متاحة',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'حاول اختيار نوع وجبة آخر',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return MealSuggestionCard(
                        meal: suggestion,
                        onAddToMeal: () {
                          widget.onSaveSuggestion(
                            suggestion,
                            widget.day,
                            widget.mealType,
                            context,
                          );
                        },
                        onTap: () {
                          widget.onSaveSuggestion(
                            suggestion,
                            widget.day,
                            widget.mealType,
                            context,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
