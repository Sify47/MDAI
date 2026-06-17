// lib/services/personalization_service.dart
// Local storage & analysis service for user taste preferences,
// meal variety tracking, and nutrition gap hints.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nutrition_model.dart';
import '../models/preferences_model.dart';

class PersonalizationService {
  static const String _tastePrefsKey = 'personalization_taste_prefs';
  static const String _varietyKey = 'personalization_meal_variety';
  static const String _cuisineListKey = 'personalization_cuisine_options';

  // ============================================
  // ✅ TASTE PREFERENCES
  // ============================================

  /// Load taste preferences from local storage
  static Future<TastePreferences> getTastePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_tastePrefsKey);
    if (data == null) return TastePreferences();
    try {
      return TastePreferences.fromJson(Map<String, dynamic>.from(json.decode(data)));
    } catch (_) {
      return TastePreferences();
    }
  }

  /// Save taste preferences to local storage
  static Future<void> saveTastePreferences(TastePreferences prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_tastePrefsKey, json.encode(prefs.toJson()));
  }

  /// Get predefined cuisine options for the picker
  static List<String> getCuisineOptions() {
    return [
      'مصري',
      'إيطالي',
      'آسيوي',
      'صحي',
      'بحر متوسط',
      'هندي',
      'مكسيكي',
      'لبناني',
      'تركي',
      'ياباني',
    ];
  }

  // ============================================
  // ✅ MEAL VARIETY TRACKING
  // ============================================

  /// Load the history of eaten meals for variety tracking
  static Future<List<MealVarietyRecord>> getMealVarietyRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_varietyKey);
    if (data == null) return [];
    try {
      final List<dynamic> list = json.decode(data);
      return list
          .map((e) => MealVarietyRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Record that a meal was eaten today
  static Future<void> recordMealEaten(String mealName) async {
    final records = await getMealVarietyRecords();
    // Remove old entry for same meal name if exists
    records.removeWhere((r) => r.mealName == mealName);
    records.add(MealVarietyRecord(
      mealName: mealName,
      lastEatenDate: DateTime.now(),
    ));
    await _saveMealVarietyRecords(records);
  }

  /// Check if a meal has been eaten recently (within the configured variety days)
  static Future<bool> isMealRecentlyEaten(
    String mealName,
    TastePreferences tastePrefs,
  ) async {
    if (tastePrefs.mealVarietyDays <= 0) return false;
    final records = await getMealVarietyRecords();
    final record = records.where((r) => r.mealName == mealName).toList();
    if (record.isEmpty) return false;
    final mostRecent = record
        .map((r) => r.lastEatenDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final cutoff = DateTime.now().subtract(Duration(days: tastePrefs.mealVarietyDays));
    return mostRecent.isAfter(cutoff);
  }

  /// Get recently eaten meal names for use in filtering
  static Future<Set<String>> getRecentlyEatenMealNames(
    int varietyDays,
  ) async {
    if (varietyDays <= 0) return {};
    final records = await getMealVarietyRecords();
    final cutoff = DateTime.now().subtract(Duration(days: varietyDays));
    return records
        .where((r) => r.lastEatenDate.isAfter(cutoff))
        .map((r) => r.mealName.toLowerCase().trim())
        .toSet();
  }

  static Future<void> _saveMealVarietyRecords(
    List<MealVarietyRecord> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _varietyKey,
      json.encode(records.map((r) => r.toJson()).toList()),
    );
  }

  // ============================================
  // ✅ NUTRITION GAP ANALYSIS
  // ============================================

  /// Analyze daily meals against target macros and return nutrition gaps
  static List<NutritionGap> analyzeNutritionGaps({
    required double currentCalories,
    required double currentProtein,
    required double currentCarbs,
    required double currentFat,
    required double targetCalories,
    required double targetProtein,
    required double targetCarbs,
    required double targetFat,
  }) {
    final gaps = <NutritionGap>[];
    const double threshold = 0.7; // Below 70% of target = gap

    // Protein gap
    if (targetProtein > 0 && currentProtein < targetProtein * threshold) {
      gaps.add(NutritionGap(
        foodGroup: 'بروتين',
        displayName: 'بروتين',
        icon: '🥩',
        priority: GapPriority.high,
        currentAmount: currentProtein,
        targetAmount: targetProtein,
        suggestion: 'تناول مصادر بروتين إضافية مثل الدجاج، البيض، السمك، أو البقوليات',
      ));
    }

    // Carbs gap
    if (targetCarbs > 0 && currentCarbs < targetCarbs * threshold) {
      gaps.add(NutritionGap(
        foodGroup: 'كارب',
        displayName: 'كربوهيدرات',
        icon: '🍚',
        priority: GapPriority.medium,
        currentAmount: currentCarbs,
        targetAmount: targetCarbs,
        suggestion: 'أضف مصدر كربوهيدرات مثل الأرز، المكرونة، أو البطاطس',
      ));
    }

    // Fat gap
    if (targetFat > 0 && currentFat < targetFat * threshold) {
      gaps.add(NutritionGap(
        foodGroup: 'دهون',
        displayName: 'دهون صحية',
        icon: '🥑',
        priority: GapPriority.medium,
        currentAmount: currentFat,
        targetAmount: targetFat,
        suggestion: 'أضف دهون صحية مثل زيت الزيتون، الأفوكادو، أو المكسرات',
      ));
    }

    // Calorie gap (overall energy)
    if (targetCalories > 0 && currentCalories < targetCalories * threshold) {
      gaps.add(NutritionGap(
        foodGroup: 'سعرات',
        displayName: 'سعرات حرارية',
        icon: '🔥',
        priority: GapPriority.high,
        currentAmount: currentCalories,
        targetAmount: targetCalories,
        suggestion: 'تحتاج لوجبة إضافية متزنة لسد احتياجك اليومي من الطاقة',
      ));
    }

    // Sort by priority
    gaps.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return gaps;
  }

  /// Analyze food categories from today's meals to find missing food groups
  static List<NutritionGap> analyzeMissingFoodGroups({
    required List<Meal> todayMeals,
    required List<Food> allFoods,
  }) {
    final gaps = <NutritionGap>[];

    // Collect all food categories eaten today
    final eatenCategories = <String>{};
    for (final meal in todayMeals) {
      for (final food in meal.foods) {
        // Find the food object to get its category
        final matchedFood = allFoods.where((f) => f.id == food.foodId).toList();
        if (matchedFood.isNotEmpty) {
          eatenCategories.add(matchedFood.first.category);
        } else {
          // Try matching by name
          final matchedByName = allFoods.where(
            (f) => f.name == food.name || f.nameEn == food.name,
          ).toList();
          if (matchedByName.isNotEmpty) {
            eatenCategories.add(matchedByName.first.category);
          }
        }
      }
    }

    // Expected food groups in Arabic
    const allGroups = {
      'بروتين': ('بروتين', '🥩', 'مصادر البروتين مثل اللحوم، الدجاج، السمك، البيض، والبقوليات'),
      'كارب': ('كربوهيدرات', '🍚', 'مصادر الكربوهيدرات مثل الأرز، الخبز، المكرونة، والشوفان'),
      'خضار': ('خضروات', '🥬', 'الخضروات الطازجة أو المطبوخة للحصول على الألياف والفيتامينات'),
      'فاكهة': ('فاكهة', '🍎', 'الفواكه الطازجة للحصول على الفيتامينات ومضادات الأكسدة'),
      'دهون': ('دهون صحية', '🥑', 'الدهون الصحية مثل زيت الزيتون، المكسرات، والأفوكادو'),
    };

    for (final entry in allGroups.entries) {
      final groupName = entry.key;
      final (displayName, icon, suggestion) = entry.value;

      if (!eatenCategories.contains(groupName)) {
        gaps.add(NutritionGap(
          foodGroup: groupName,
          displayName: displayName,
          icon: icon,
          priority: GapPriority.medium,
          currentAmount: 0,
          targetAmount: 1,
          suggestion: 'لم تتناول أي $displayName اليوم. $suggestion',
        ));
      }
    }

    return gaps;
  }

  /// Generate a personalized tip based on taste preferences and recent meals
  static Future<String> getPersonalizedTip(
    TastePreferences tastePrefs,
  ) async {
    final recentlyEaten = await getRecentlyEatenMealNames(tastePrefs.mealVarietyDays);

    if (tastePrefs.dislikedIngredients.isNotEmpty && recentlyEaten.isNotEmpty) {
      return 'جرّب وجبة جديدة اليوم لتنويع طعامك وتجنب تكرار نفس الوجبات';
    }

    if (tastePrefs.spicyPreference >= 4) {
      final spicySuggestions = [
        'يمكنك تجربة إضافة التوابل الحارة المعتدلة لوجباتك اليوم',
        'جرب الشطة أو الفلفل الأسود لإضافة نكهة مميزة لطعامك',
      ];
      return spicySuggestions[DateTime.now().millisecondsSinceEpoch % spicySuggestions.length];
    }

    if (tastePrefs.sweetTooth >= 4) {
      return 'بدلاً من الحلويات، جرب الفواكه الطازجة لإرضاء رغبتك في السكر';
    }

    return 'حافظ على توازن وجباتك بين البروتين والكارب والخضار';
  }
}