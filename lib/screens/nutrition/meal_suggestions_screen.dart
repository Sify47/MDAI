// lib/screens/nutrition/meal_suggestions_screen.dart

import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../models/nutrition_model.dart';
import '../../../models/symptom_model.dart';
import '../../../models/medication_model.dart';
import '../../../models/preferences_model.dart';
import '../../../services/nutrition_api.dart';
import '../../../services/symptom_api.dart';
import '../../../services/medication_api.dart';
import '../../../services/personalization_service.dart';
import 'add_meal_screen.dart';
import '../../../widgets/nutrition/loading_shimmers.dart';
import '../../../widgets/nutrition/empty_nutrition_state.dart';
import '../../../widgets/nutrition/meal_section_card.dart';
import '../../../widgets/nutrition/daily_summary_card.dart';
import '../../../widgets/nutrition/nutrition_card.dart';
import '../../../widgets/nutrition/meal_helpers.dart';
import '../../../services/meal_planner_service.dart';
import '../../../models/meal_plan_model.dart';

class MealSuggestionsScreen extends StatefulWidget {
  final UserNutritionData userData;

  const MealSuggestionsScreen({super.key, required this.userData});

  @override
  State<MealSuggestionsScreen> createState() => _MealSuggestionsScreenState();
}

class _MealSuggestionsScreenState extends State<MealSuggestionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  List<MealSuggestion> _allSuggestions = [];
  Map<String, List<MealSuggestion>> _organizedMeals = {};
  bool _isLoading = true;
  String _selectedView = 'يومي';

  // ✅ بيانات الوجبات الفعلية لليوم (للملخص اليومي)
  Map<String, dynamic>? _todayMealsData;

  // ✅ متغيرات المفضلة
  Set<String> _favoriteIds = {};

  // متغيرات لتخزين الأطعمة الممنوعة من الأعراض
  Set<String> _avoidedFoodsFromSymptoms = {};
  Set<String> _avoidedDrinksFromSymptoms = {};

  // متغيرات لتخزين الأطعمة الممنوعة من الأدوية
  Set<String> _avoidedFoodsFromMedicines = {};
  Set<String> _avoidedDrinksFromMedicines = {};
  Map<String, String> _medicineTimingInstructions = {};

  // متغيرات التخصيص
  TastePreferences _tastePreferences = TastePreferences();
  Set<String> _recentlyEatenNames = {};
  bool _filterExcludeRecent = true;
  List<NutritionGap> _nutritionGaps = [];
  String _personalizedTip = '';

  List<Symptom> _recentSymptoms = [];
  List<UserMedication> _userMedications = [];

  final List<String> _mealTypes = ['فطور', 'غداء', 'عشاء', 'سناك'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
    _loadAllData();
    _loadFavorites();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // تحميل الاقتراحات والأعراض والأدوية معاً
  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    await Future.wait([
      _loadSuggestions(),
      _loadRecentSymptoms(),
      _loadUserMedications(),
      _loadPersonalizationData(),
      _loadTodayMeals(),
    ]);

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  /// تحميل بيانات الوجبات الفعلية لليوم (للملخص اليومي)
  Future<void> _loadTodayMeals() async {
    try {
      final mealsData = await NutritionService.getTodayMeals();
      if (mounted) {
        setState(() {
          _todayMealsData = mealsData;
        });
      }
    } catch (e) {
      print('⚠️ خطأ في تحميل وجبات اليوم للملخص: $e');
    }
  }

  // ✅ تحميل المفضلة
  Future<void> _loadFavorites() async {
    try {
      final favorites = await MealPlannerService.getFavorites();
      if (mounted) {
        setState(() {
          _favoriteIds = favorites.map((f) => f.id).toSet();
        });
      }
    } catch (_) {}
  }

  // تحميل بيانات التخصيص (التفضيلات، التنوع، النصائح)
  Future<void> _loadPersonalizationData() async {
    try {
      final prefs = await PersonalizationService.getTastePreferences();
      final recentlyEaten =
          await PersonalizationService.getRecentlyEatenMealNames(
        prefs.mealVarietyDays,
      );
      final tip = await PersonalizationService.getPersonalizedTip(prefs);
      // تحليل الفجوات الغذائية من الإحصائيات الظاهرة
      final gaps = PersonalizationService.analyzeNutritionGaps(
        currentCalories: _organizedMeals.values
            .expand((m) => m)
            .fold<double>(0, (sum, m) => sum + m.calories),
        currentProtein: _organizedMeals.values
            .expand((m) => m)
            .fold<double>(0, (sum, m) => sum + m.protein),
        currentCarbs: _organizedMeals.values
            .expand((m) => m)
            .fold<double>(0, (sum, m) => sum + m.carbs),
        currentFat: _organizedMeals.values
            .expand((m) => m)
            .fold<double>(0, (sum, m) => sum + m.fat),
        targetCalories: widget.userData.targetCalories,
        targetProtein: widget.userData.targetCalories * 0.25 / 4,
        targetCarbs: widget.userData.targetCalories * 0.5 / 4,
        targetFat: widget.userData.targetCalories * 0.25 / 9,
      );
      if (mounted) {
        setState(() {
          _tastePreferences = prefs;
          _recentlyEatenNames = recentlyEaten;
          _personalizedTip = tip;
          _nutritionGaps = gaps;
        });
      }
    } catch (_) {}
  }

  /// ✅ تبديل حالة المفضلة لوجبة مع إشعار
  Future<void> _toggleFavorite(MealSuggestion meal) async {
    final id = meal.id.toString();
    final isFav = _favoriteIds.contains(id);
    try {
      if (isFav) {
        await MealPlannerService.removeFavorite(id);
        setState(() => _favoriteIds.remove(id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.favorite_border, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('تم إزالة ${meal.name} من المفضلة')),
                ],
              ),
              backgroundColor: AppColors.textSecondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        await MealPlannerService.addFavorite(FavoriteMeal(
          id: id,
          name: meal.name,
          description: meal.description.length > 100
              ? '${meal.description.substring(0, 100)}...'
              : meal.description,
          type: meal.type,
          calories: meal.calories,
          protein: meal.protein,
          carbs: meal.carbs,
          fat: meal.fat,
          imageUrl: null,
        ));
        setState(() => _favoriteIds.add(id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('تم إضافة ${meal.name} إلى المفضلة')),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (_) {}
  }

  // تحميل اقتراحات الوجبات
  Future<void> _loadSuggestions() async {
    final suggestions = await NutritionService.getMealSuggestions(
      goal: widget.userData.goal,
      diseases: widget.userData.diseases,
    );

    final organized = <String, List<MealSuggestion>>{};
    for (var type in _mealTypes) {
      organized[type] = suggestions.where((s) => s.type == type).toList();
    }

    if (!mounted) return;
    setState(() {
      _allSuggestions = suggestions;
      _organizedMeals = organized;
    });
  }

  // تحميل الأعراض الحديثة
  Future<void> _loadRecentSymptoms() async {
    if (!mounted) return;

    try {
      final symptoms = await SymptomService.getSymptoms(limit: 20);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentSymptoms = symptoms
          .where((s) => s.dateTime.isAfter(sevenDaysAgo))
          .toList();

      if (!mounted) return;
      setState(() {
        _recentSymptoms = recentSymptoms;
      });

      await _extractAvoidedItemsFromSymptoms(recentSymptoms);
    } catch (e) {
      print('❌ خطأ في تحميل الأعراض: $e');
    }
  }

  // تحميل أدوية المستخدم
  Future<void> _loadUserMedications() async {
    if (!mounted) return;

    try {
      final medications = await MedicationService.getMedications();
      if (!mounted) return;
      setState(() {
        _userMedications = medications;
      });

      await _extractAvoidedItemsFromMedicines(medications);
    } catch (e) {
      print('❌ خطأ في تحميل الأدوية: $e');
    }
  }

  // استخراج الأطعمة الممنوعة من الأعراض
  Future<void> _extractAvoidedItemsFromSymptoms(List<Symptom> symptoms) async {
    Set<String> avoidedFoods = {};
    Set<String> avoidedDrinks = {};

    for (var symptom in symptoms) {
      if (symptom.foodRecommendations != null) {
        final recs = symptom.foodRecommendations!;
        if (recs['foods_to_avoid'] != null) {
          avoidedFoods.addAll(
            List<String>.from(
              recs['foods_to_avoid'],
            ).map((f) => f.toLowerCase()),
          );
        }
        if (recs['drinks_to_avoid'] != null) {
          avoidedDrinks.addAll(
            List<String>.from(
              recs['drinks_to_avoid'],
            ).map((d) => d.toLowerCase()),
          );
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _avoidedFoodsFromSymptoms = avoidedFoods;
      _avoidedDrinksFromSymptoms = avoidedDrinks;
    });
  }

  // استخراج الأطعمة الممنوعة من الأدوية
  Future<void> _extractAvoidedItemsFromMedicines(
    List<UserMedication> medications,
  ) async {
    Set<String> avoidedFoods = {};
    Set<String> avoidedDrinks = {};
    Map<String, String> timingInstructions = {};

    for (var med in medications) {
      try {
        final impact = await SymptomService.getMedicineImpact(
          med.medicineId ?? 0,
        );
        if (impact['success']) {
          if (impact['foods_to_avoid'] != null) {
            avoidedFoods.addAll(
              List<String>.from(
                impact['foods_to_avoid'],
              ).map((f) => f.toLowerCase()),
            );
          }
          if (impact['drinks_to_avoid'] != null) {
            avoidedDrinks.addAll(
              List<String>.from(
                impact['drinks_to_avoid'],
              ).map((d) => d.toLowerCase()),
            );
          }
          if (impact['timing_instructions'] != null) {
            timingInstructions[med.name] = impact['timing_instructions'];
          }
        }
      } catch (e) {
        print('⚠️ خطأ في جلب توصيات الدواء ${med.name}: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _avoidedFoodsFromMedicines = avoidedFoods;
      _avoidedDrinksFromMedicines = avoidedDrinks;
      _medicineTimingInstructions = timingInstructions;
    });
  }

  // دمج الأطعمة الممنوعة (أعراض + أدوية)
  Set<String> get _allAvoidedFoods => {
    ..._avoidedFoodsFromSymptoms,
    ..._avoidedFoodsFromMedicines,
  };

  Set<String> get _allAvoidedDrinks => {
    ..._avoidedDrinksFromSymptoms,
    ..._avoidedDrinksFromMedicines,
  };

  // ✅ فلترة الوجبات حسب الأعراض والأدوية - إزالة الوجبات التي تحتوي على أطعمة ممنوعة
  List<MealSuggestion> _filterMealsByHealthStatus(List<MealSuggestion> meals) {
    if (_allAvoidedFoods.isEmpty && _allAvoidedDrinks.isEmpty) return meals;

    final filteredMeals = meals.where((meal) {
      // التحقق من المكونات
      for (var ingredient in meal.ingredients) {
        final ingredientName = (ingredient['name'] ?? ingredient.toString())
            .toLowerCase();

        for (var avoided in _allAvoidedFoods) {
          if (ingredientName.contains(avoided) ||
              avoided.contains(ingredientName)) {
            return false;
          }
        }
      }

      // التحقق من اسم الوجبة
      final mealName = meal.name.toLowerCase();
      for (var avoided in _allAvoidedFoods) {
        if (mealName.contains(avoided)) {
          return false;
        }
      }

      return true;
    }).toList();

    return filteredMeals;
  }

  // دالة التصفية الكاملة للعرض اليومي
  List<MealSuggestion> _filterMealsForDailyView(List<MealSuggestion> meals) {
    // 1. فلترة حسب الحالة الصحية
    meals = _filterMealsByHealthStatus(meals);
    // 2. فلترة حسب المكونات الغير مفضلة
    if (_tastePreferences.dislikedIngredients.isNotEmpty) {
      meals = meals.where((meal) {
        final mealName = meal.name.toLowerCase();
        for (var disliked in _tastePreferences.dislikedIngredients) {
          if (mealName.contains(disliked.toLowerCase())) return false;
          for (var ingredient in meal.ingredients) {
            final ingredientName =
                (ingredient['name'] ?? ingredient.toString()).toLowerCase();
            if (ingredientName.contains(disliked.toLowerCase())) return false;
          }
        }
        return true;
      }).toList();
    }
    // 3. فلترة حسب الوجبات التي تم تناولها مؤخراً (التنوع)
    if (_filterExcludeRecent && _recentlyEatenNames.isNotEmpty) {
      meals = meals.where((meal) {
        return !_recentlyEatenNames.contains(meal.name);
      }).toList();
    }
    return meals;
  }

  String _getCategoryFromIngredient(String ingredient) {
    ingredient = ingredient.toLowerCase();
    if (ingredient.contains('دجاج') ||
        ingredient.contains('لحمة') ||
        ingredient.contains('بيض') ||
        ingredient.contains('تونة') ||
        ingredient.contains('فراخ') ||
        ingredient.contains('سمك') ||
        ingredient.contains('كفتة') ||
        ingredient.contains('كباب')) {
      return 'بروتين';
    } else if (ingredient.contains('أرز') ||
        ingredient.contains('مكرونة') ||
        ingredient.contains('خبز') ||
        ingredient.contains('بطاطس') ||
        ingredient.contains('عيش') ||
        ingredient.contains('كشري') ||
        ingredient.contains('شوفان') ||
        ingredient.contains('كينوا')) {
      return 'كارب';
    } else if (ingredient.contains('خيار') ||
        ingredient.contains('طماطم') ||
        ingredient.contains('خس') ||
        ingredient.contains('بصل') ||
        ingredient.contains('ثوم') ||
        ingredient.contains('فلفل') ||
        ingredient.contains('باذنجان') ||
        ingredient.contains('كوسة') ||
        ingredient.contains('جزر') ||
        ingredient.contains('بقدونس') ||
        ingredient.contains('ملوخية') ||
        ingredient.contains('سبانخ')) {
      return 'خضار';
    } else if (ingredient.contains('زيت') ||
        ingredient.contains('زبدة') ||
        ingredient.contains('لوز') ||
        ingredient.contains('جوز') ||
        ingredient.contains('سمن') ||
        ingredient.contains('طحينة') ||
        ingredient.contains('فستق') ||
        ingredient.contains('بندق')) {
      return 'دهون';
    } else if (ingredient.contains('تفاح') ||
        ingredient.contains('موز') ||
        ingredient.contains('برتقال') ||
        ingredient.contains('فراولة') ||
        ingredient.contains('جوافة') ||
        ingredient.contains('مانجو')) {
      return 'فاكهة';
    } else if (ingredient.contains('زبادي') ||
        ingredient.contains('جبن') ||
        ingredient.contains('حليب') ||
        ingredient.contains('رايب')) {
      return 'بروتين';
    }
    return 'أخرى';
  }

  bool _isAddingSuggestion = false;

  Future<void> _addSuggestionToMeal(MealSuggestion suggestion) async {
    // ✅ منع الإضافة المتكررة لنفس الاقتراح (Bug #2 fix)
    if (_isAddingSuggestion) {
      print('⚠️ [Bug2] تم تجاهل إضافة مكررة لـ ${suggestion.name}');
      return;
    }
    setState(() => _isAddingSuggestion = true);

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
          'category': _getCategoryFromIngredient(ingredientName),
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
        'category': 'وجبة',
        'food_id': 0,
      });
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMealScreen(
          userData: widget.userData,
          preSelectedMealType: suggestion.type,
          preSelectedFoods: foods,
        ),
      ),
    );

    if (result == true && mounted) {
      // تسجيل الوجبة في سجل التنوع
      await PersonalizationService.recordMealEaten(suggestion.name);
      // تحديث قائمة الوجبات المسجلة محلياً
      if (mounted) {
        setState(() {
          _recentlyEatenNames.add(suggestion.name);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('✅ تم إضافة ${suggestion.name} إلى وجباتك')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    if (mounted) {
      setState(() => _isAddingSuggestion = false);
    }
  }

  Widget _buildHealthStatusWarning() {
    final theme = Theme.of(context);
    bool hasSymptoms = _recentSymptoms.isNotEmpty;
    bool hasMedicines = _userMedications.isNotEmpty;

    // عرض عدد الوجبات التي تمت تصفيتها
    int originalCount = _allSuggestions.length;
    int filteredCount = _filterMealsByHealthStatus(_allSuggestions).length;
    int removedCount = originalCount - filteredCount;

    if (!hasSymptoms && !hasMedicines) return const SizedBox();

    String warningText = '';
    if (hasSymptoms && hasMedicines) {
      warningText =
          'تم تصفية الوجبات حسب أعراضك وأدويتك - تم استبعاد الأطعمة التي قد تتعارض مع حالتك';
    } else if (hasSymptoms) {
      warningText =
          'تم تصفية الوجبات حسب أعراضك - تم استبعاد الأطعمة التي قد تزيد الأعراض سوءاً';
    } else if (hasMedicines) {
      warningText =
          'تم تصفية الوجبات حسب أدويتك - تم استبعاد الأطعمة التي قد تتعارض مع أدويتك';
    }

    if (removedCount > 0) {
      warningText += ' (تم استبعاد $removedCount وجبة غير مناسبة)';
    }

    return Semantics(
      label: warningText,
      container: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.health_and_safety, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ تم تصفية الوجبات حسب حالتك الصحية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warningText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesInfo() {
    final theme = Theme.of(context);
    if (_userMedications.isEmpty) return const SizedBox();

    return Semantics(
      label: 'تنبيهات الأدوية - ${_userMedications.length} أدوية',
      container: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '💊 تنبيهات الأدوية',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._userMedications.map((med) {
              final instruction = _medicineTimingInstructions[med.name];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          children: [
                            TextSpan(
                              text: med.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (instruction != null)
                              TextSpan(text: ': $instruction'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
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
            label: 'شاشة اقتراحات الوجبات',
            header: true,
            child: Text('🍽️ اقتراحات الوجبات'),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'إعدادات التخصيص',
              child: IconButton(
                icon: Icon(Icons.tune,
                    color: theme.colorScheme.primary),
                tooltip: 'إعدادات التخصيص',
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                onPressed: () => _showPersonalizationSettings(context),
              ),
            ),
            Semantics(
              button: true,
              label: 'تحديث الاقتراحات',
              child: IconButton(
                icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                tooltip: 'تحديث الاقتراحات',
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
                onPressed: _loadAllData,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Semantics(
                label: 'تبديل عرض الوجبات',
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(20),
                  selectedBorderColor: theme.colorScheme.primary,
                  selectedColor: Colors.white,
                  fillColor: theme.colorScheme.primary,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  isSelected: [
                    _selectedView == 'يومي',
                    _selectedView == 'كل الوجبات',
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedView = index == 0 ? 'يومي' : 'كل الوجبات';
                    });
                  },
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('يومي'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('كل الوجبات'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const SuggestionsShimmer()
              : _allSuggestions.isEmpty
              ? _buildEmptyState(theme)
              : Column(
                  children: [
                    _buildHealthStatusWarning(),
                    _buildMedicinesInfo(),
                    Expanded(
                      child: _selectedView == 'يومي'
                          ? _buildDailyPlanView(theme)
                          : _buildAllMealsView(theme),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDailyPlanView(ThemeData theme) {
    final targetCalories = widget.userData.targetCalories;

    double breakfastPercentage = 0.3;
    double lunchPercentage = 0.35;
    double dinnerPercentage = 0.25;
    double snacksPercentage = 0.1;

    if (widget.userData.goal == 'تخسيس') {
      breakfastPercentage = 0.25;
      lunchPercentage = 0.35;
      dinnerPercentage = 0.25;
      snacksPercentage = 0.15;
    } else if (widget.userData.goal == 'زيادة') {
      breakfastPercentage = 0.3;
      lunchPercentage = 0.35;
      dinnerPercentage = 0.25;
      snacksPercentage = 0.1;
    }

    final breakfastCalories = targetCalories * breakfastPercentage;
    final lunchCalories = targetCalories * lunchPercentage;
    final dinnerCalories = targetCalories * dinnerPercentage;
    final snacksCalories = targetCalories * snacksPercentage;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'ملخص السعرات اليومية',
              child: _buildDailySummary(targetCalories, theme),
            ),
            const SizedBox(height: 20),
            Semantics(
              label: 'قسم الفطور',
              child: _buildMealSection(
                'الفطور',
                _filterMealsForDailyView(_organizedMeals['فطور'] ?? []),
                breakfastCalories,
                theme,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'قسم الغداء',
              child: _buildMealSection(
                'الغداء',
                _filterMealsForDailyView(_organizedMeals['غداء'] ?? []),
                lunchCalories,
                theme,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'قسم العشاء',
              child: _buildMealSection(
                'العشاء',
                _filterMealsForDailyView(_organizedMeals['عشاء'] ?? []),
                dinnerCalories,
                theme,
              ),
            ),
            const SizedBox(height: 16),
            if ((_filterMealsForDailyView(
              _organizedMeals['سناك'] ?? [],
            )).isNotEmpty)
              Semantics(
                label: 'قسم السناك',
                child: _buildMealSection(
                  'سناك',
                  _filterMealsForDailyView(_organizedMeals['سناك']!),
                  snacksCalories,
                  theme,
                ),
              ),
            const SizedBox(height: 20),
            _buildNutritionGapsCard(theme),
            _buildNutritionTips(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary(double targetCalories, ThemeData theme) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    // ✅ استخدام بيانات الوجبات الفعلية من API (getTodayMeals)
    // بدلاً من اقتراحات الوجبات التي كانت تظهر أرقاماً خيالية
    if (_todayMealsData != null) {
      totalCalories = (_todayMealsData!['total_calories'] ?? 0).toDouble();
      totalProtein = (_todayMealsData!['total_protein'] ?? 0).toDouble();
      totalCarbs = (_todayMealsData!['total_carbs'] ?? 0).toDouble();
      totalFat = (_todayMealsData!['total_fat'] ?? 0).toDouble();
    }

    return DailySummaryCard(
      targetCalories: targetCalories,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
    );
  }

  Widget _buildMealSection(
    String title,
    List<MealSuggestion> meals,
    double targetCalories,
    ThemeData theme,
  ) {
    return MealSectionCard(
      title: title,
      meals: meals,
      targetCalories: targetCalories,
      onShowAll: () => _showAllMealsOfType(title, meals, theme),
      onAddToMeal: (meal) => _addSuggestionToMeal(meal),
      onTapMeal: (meal) => _showMealDetails(meal, theme),
    );
  }

  Widget _buildAllMealsView(ThemeData theme) {
    return DefaultTabController(
      length: _mealTypes.length,
      child: Column(
        children: [
          Container(
            color: theme.cardColor,
            child: TabBar(
              tabs: _mealTypes.map((type) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        label: type,
                        child: Text(getMealEmoji(type)),
                      ),
                      const SizedBox(width: 4),
                      Text(type),
                    ],
                  ),
                );
              }).toList(),
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                0.6,
              ),
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: _mealTypes.map((type) {
                final meals = _filterMealsForDailyView(
                  _organizedMeals[type] ?? [],
                );
                return meals.isEmpty
                    ? _buildEmptyTypeState(type, theme)
                    : RefreshIndicator(
                        onRefresh: _loadAllData,
                        color: theme.colorScheme.primary,
                        child: Semantics(
                          label: 'قائمة وجبات $type',
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: meals.length,
                            itemBuilder: (context, index) =>
                                _buildDetailedMealCard(meals[index], theme),
                          ),
                        ),
                      );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTypeState(String type, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(getMealIcon(type), size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد وجبات $type متاحة',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'حاول تغيير الفلتر أو تحديث البيانات',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMealCard(MealSuggestion meal, ThemeData theme) {
    return NutritionCard.defaultStyle(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: getMealTypeColor(meal.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  getMealIcon(meal.type),
                  color: getMealTypeColor(meal.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: 'اسم الوجبة ${meal.name}',
                      child: Text(
                        meal.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (meal.goal != null)
                      Text(
                        'مناسب لـ: ${meal.goal}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: getGoalColor(meal.goal!),
                        ),
                      ),
                  ],
                ),
              ),
              Semantics(
                label: '${meal.calories} سعرة حرارية',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.calories.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${meal.calories} سعرة',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.calories,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: _favoriteIds.contains(meal.id.toString())
                    ? 'إزالة ${meal.name} من المفضلة'
                    : 'إضافة ${meal.name} إلى المفضلة',
                child: IconButton(
                  icon: Icon(
                    _favoriteIds.contains(meal.id.toString())
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _favoriteIds.contains(meal.id.toString())
                        ? Colors.red[400]
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  tooltip: _favoriteIds.contains(meal.id.toString())
                      ? 'إزالة من المفضلة'
                      : 'إضافة إلى المفضلة',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  onPressed: () => _toggleFavorite(meal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            meal.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientDetail(
                  'بروتين',
                  meal.protein,
                  theme.colorScheme.primary,
                  theme,
                ),
                _buildNutrientDetail(
                  'كارب',
                  meal.carbs,
                  AppColors.calories,
                  theme,
                ),
                _buildNutrientDetail('دهون', meal.fat, Colors.orange, theme),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (meal.ingredients.isNotEmpty) ...[
            Text(
              'المكونات:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: meal.ingredients.take(3).map((ingredient) {
                String ingredientName =
                    ingredient['name'] ?? ingredient.toString();
                String quantity = ingredient['quantity'] != null
                    ? ' (${ingredient['quantity']} ${ingredient['unit'] ?? ''})'
                    : '';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$ingredientName$quantity',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }).toList(),
            ),
            if (meal.ingredients.length > 3)
              Semantics(
                button: true,
                label: 'عرض ${meal.ingredients.length - 3} مكونات أخرى',
                child: TextButton(
                  onPressed: () => _showMealDetails(meal, theme),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                  ),
                  child: Text('+ ${meal.ingredients.length - 3} مكونات أخرى'),
                ),
              ),
          ],
          if (meal.suitableFor.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: meal.suitableFor.map((item) {
                return Chip(
                  label: Text(item),
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: 'تسجيل ${meal.name} كوجبة',
              child: ElevatedButton.icon(
                onPressed: () => _addSuggestionToMeal(meal),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('تسجيل هذه الوجبة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientDetail(
    String label,
    double value,
    Color color,
    ThemeData theme,
  ) {
    return Semantics(
      label: '$label $value جرام',
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)} جم',
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
      ),
    );
  }

  void _showAllMealsOfType(
    String title,
    List<MealSuggestion> meals,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Semantics(
                  label: 'مقبض السحب',
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(
                  header: true,
                  label: 'قائمة $title',
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      return NutritionCard.flat(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Semantics(
                          label: '${meals[index].name} - ${meals[index].calories} سعرة',
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: getMealTypeColor(
                                meals[index].type,
                              ).withOpacity(0.2),
                              child: Icon(
                                getMealIcon(meals[index].type),
                                color: getMealTypeColor(meals[index].type),
                                size: 20,
                              ),
                            ),
                            title: Text(meals[index].name),
                            subtitle: Text('${meals[index].calories} سعرة'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  button: true,
                                  label: 'إضافة ${meals[index].name} إلى الوجبات',
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.add_circle,
                                      color: theme.colorScheme.primary,
                                    ),
                                    tooltip: 'إضافة الوجبة',
                                    constraints: const BoxConstraints(
                                      minWidth: 44,
                                      minHeight: 44,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _addSuggestionToMeal(meals[index]);
                                    },
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_left,
                                  color: theme.colorScheme.onSurface.withOpacity(
                                    0.4,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showMealDetails(meals[index], theme);
                            },
                            minLeadingWidth: 44,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMealDetails(MealSuggestion meal, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Semantics(
                    label: 'مقبض السحب',
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: getMealTypeColor(
                                  meal.type,
                                ).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                getMealIcon(meal.type),
                                color: getMealTypeColor(meal.type),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    label: 'اسم الوجبة ${meal.name}',
                                    child: Text(
                                      meal.name,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getMealTypeColor(
                                            meal.type,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          meal.type,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: getMealTypeColor(meal.type),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (meal.goal != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getGoalColor(
                                              meal.goal!,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            meal.goal!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: getGoalColor(meal.goal!),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Semantics(
                              button: true,
                              label: _favoriteIds.contains(meal.id.toString())
                                  ? 'إزالة ${meal.name} من المفضلة'
                                  : 'إضافة ${meal.name} إلى المفضلة',
                              child: IconButton(
                                icon: Icon(
                                  _favoriteIds.contains(meal.id.toString())
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _favoriteIds.contains(meal.id.toString())
                                      ? Colors.red[400]
                                      : theme.colorScheme.onSurface.withOpacity(0.5),
                                  size: 28,
                                ),
                                tooltip: _favoriteIds.contains(meal.id.toString())
                                    ? 'إزالة من المفضلة'
                                    : 'إضافة إلى المفضلة',
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _toggleFavorite(meal);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          label: 'وصف الوجبة',
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              meal.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          label: 'القيم الغذائية للوجبة',
                          child: Text(
                            'القيم الغذائية',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Semantics(
                          label: '${meal.calories} سعرة حرارية',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildNutrientCircle(
                                label: 'سعرات',
                                value: '${meal.calories}',
                                unit: 'سعرة',
                                color: AppColors.calories,
                                theme: theme,
                              ),
                              _buildNutrientCircle(
                                label: 'بروتين',
                                value: '${meal.protein}',
                                unit: 'جم',
                                color: theme.colorScheme.primary,
                                theme: theme,
                              ),
                              _buildNutrientCircle(
                                label: 'كارب',
                                value: '${meal.carbs}',
                                unit: 'جم',
                                color: Colors.orange,
                                theme: theme,
                              ),
                              _buildNutrientCircle(
                                label: 'دهون',
                                value: '${meal.fat}',
                                unit: 'جم',
                                color: Colors.purple,
                                theme: theme,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'المكونات',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...meal.ingredients.map((ingredient) {
                          String ingredientName =
                              ingredient['name'] ?? ingredient.toString();
                          String quantity = ingredient['quantity'] != null
                              ? '${ingredient['quantity']}'
                              : '';
                          String unit = ingredient['unit'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ingredientName,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                if (quantity.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$quantity $unit',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        if (meal.preparation.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'طريقة التحضير',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'طريقة التحضير',
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                meal.preparation,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Semantics(
                          button: true,
                          label: 'تسجيل ${meal.name} كوجبة',
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _addSuggestionToMeal(meal);
                              },
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text(
                                'تسجيل هذه الوجبة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(44, 44),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNutrientCircle({
    required String label,
    required String value,
    required String unit,
    required Color color,
    required ThemeData theme,
  }) {
    return Semantics(
      label: '$label $value $unit',
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                  Text(
                    unit,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTips(ThemeData theme) {
    // استخدام النصيحة المخصصة إذا كانت متوفرة
    final displayTip = _personalizedTip.isNotEmpty
        ? _personalizedTip
        : [
            'اشرب كمية كافية من الماء بين الوجبات',
            'حاول تقسيم طعامك لـ 5-6 وجبات صغيرة',
            'تناول الخضروات في كل وجبة للحصول على الألياف',
            'لا تهمل وجبة الفطور فهي تمدك بالطاقة',
            'قلل من الملح والسكر في طعامك',
            'امضغ الطعام جيداً لتسهيل الهضم',
            'تناول البروتين في كل وجبة لزيادة الشبع',
            'ابتعد عن المشروبات الغازية والعصائر المحلاة',
          ][DateTime.now().millisecondsSinceEpoch % 8];

    return Semantics(
      label: 'نصيحة غذائية: $displayTip',
      child: NutritionCard.tips(
        accentColor: Colors.blue,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tips_and_updates, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 نصيحة غذائية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayTip,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بطاقة الفجوات الغذائية
  Widget _buildNutritionGapsCard(ThemeData theme) {
    if (_nutritionGaps.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: 'فجوات غذائية: ${_nutritionGaps.length} فجوات',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: NutritionCard.tips(
          accentColor: Colors.orange,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    '⚡ فجوات غذائية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._nutritionGaps.take(3).map((gap) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(gap.icon, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gap.displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                gap.suggestion,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// حوار إعدادات التخصيص
  Future<void> _showPersonalizationSettings(BuildContext context) async {
    final prefs = _tastePreferences;
    int sweetTooth = prefs.sweetTooth;
    int spicyPref = prefs.spicyPreference;
    List<String> selectedCuisines = List.from(prefs.preferredCuisines);
    List<String> dislikedIngredients = List.from(prefs.dislikedIngredients);
    int varietyDays = prefs.mealVarietyDays;

    final cuisines = PersonalizationService.getCuisineOptions();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('🔧 إعدادات التخصيص'),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('درجة تفضيل الحلويات'),
                        Slider(
                          min: 1,
                          max: 5,
                          divisions: 4,
                          value: sweetTooth.toDouble(),
                          label: '$sweetTooth',
                          onChanged: (v) =>
                              setDialogState(() => sweetTooth = v.round()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('1',
                                style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const Text('5',
                                style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('درجة تفضيل الأكل الحار'),
                        Slider(
                          min: 1,
                          max: 5,
                          divisions: 4,
                          value: spicyPref.toDouble(),
                          label: '$spicyPref',
                          onChanged: (v) =>
                              setDialogState(() => spicyPref = v.round()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('1',
                                style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const Text('5',
                                style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('المطبخ المفضل',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: cuisines.map((cuisine) {
                            final selected =
                                selectedCuisines.contains(cuisine);
                            return FilterChip(
                              label: Text(cuisine),
                              selected: selected,
                              onSelected: (val) {
                                setDialogState(() {
                                  if (val) {
                                    selectedCuisines.add(cuisine);
                                  } else {
                                    selectedCuisines.remove(cuisine);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text('المكونات غير المرغوب بها',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...dislikedIngredients.map((ing) => Chip(
                              label: Text(ing),
                              onDeleted: () => setDialogState(
                                  () => dislikedIngredients.remove(ing)),
                            )),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'أضف مكون غير مرغوب...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setDialogState(
                                  () => dislikedIngredients.add(val.trim()));
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('أيام التنوع: '),
                            const SizedBox(width: 8),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 0, label: Text('بدون')),
                                ButtonSegment(value: 2, label: Text('يومين')),
                                ButtonSegment(value: 3, label: Text('3 أيام')),
                                ButtonSegment(value: 5, label: Text('5 أيام')),
                              ],
                              selected: {varietyDays},
                              onSelectionChanged: (v) =>
                                  setDialogState(() => varietyDays = v.first),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('حفظ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      final updated = TastePreferences(
        sweetTooth: sweetTooth,
        spicyPreference: spicyPref,
        preferredCuisines: selectedCuisines,
        dislikedIngredients: dislikedIngredients,
        mealVarietyDays: varietyDays,
      );
      await PersonalizationService.saveTastePreferences(updated);
      if (mounted) {
        setState(() => _tastePreferences = updated);
        // إعادة تحميل البيانات المخصصة
        await _loadPersonalizationData();
      }
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return EmptyNutritionState.noSuggestions(onRetry: _loadAllData);
  }
}
