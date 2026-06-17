// lib/services/meal_planner_service.dart
// Local storage service for Meal Planner: templates, favorites, weekly plans

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_plan_model.dart';

class MealPlannerService {
  static const String _templatesKey = 'meal_planner_templates';
  static const String _favoritesKey = 'meal_planner_favorites';
  static const String _planKeyPrefix = 'meal_plan_';

  // ============================================
  // ✅ TEMPLATES
  // ============================================

  static Future<List<MealTemplate>> getTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_templatesKey);
    if (data == null) return [];
    try {
      final List<dynamic> list = json.decode(data);
      return list.map((e) => MealTemplate.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTemplate(MealTemplate template) async {
    final templates = await getTemplates();
    templates.add(template);
    await _saveTemplates(templates);
  }

  static Future<void> deleteTemplate(String id) async {
    final templates = await getTemplates();
    templates.removeWhere((t) => t.id == id);
    await _saveTemplates(templates);
  }

  static Future<void> _saveTemplates(List<MealTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(templates.map((t) => t.toJson()).toList());
    await prefs.setString(_templatesKey, data);
  }

  // ============================================
  // ✅ FAVORITES
  // ============================================

  static Future<List<FavoriteMeal>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_favoritesKey);
    if (data == null) return [];
    try {
      final List<dynamic> list = json.decode(data);
      return list.map((e) => FavoriteMeal.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isFavorite(String id) async {
    final favorites = await getFavorites();
    return favorites.any((f) => f.id == id);
  }

  static Future<void> addFavorite(FavoriteMeal meal) async {
    final favorites = await getFavorites();
    // Avoid duplicates
    favorites.removeWhere((f) => f.id == meal.id);
    favorites.add(meal);
    await _saveFavorites(favorites);
  }

  static Future<void> removeFavorite(String id) async {
    final favorites = await getFavorites();
    favorites.removeWhere((f) => f.id == id);
    await _saveFavorites(favorites);
  }

  static Future<void> _saveFavorites(List<FavoriteMeal> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(favorites.map((f) => f.toJson()).toList());
    await prefs.setString(_favoritesKey, data);
  }

  // ============================================
  // ✅ WEEKLY PLANS
  // ============================================

  /// Get the week key for a given date: "2026-W21"
  static String _weekKey(DateTime date) {
    // ISO week calculation
    final y = date.year;
    final w = ((date.difference(DateTime(y, 1, 1)).inDays + DateTime(y, 1, 1).weekday - 1) / 7).ceil();
    return '$y-W${w.toString().padLeft(2, '0')}';
  }

  /// Get start of week (Monday) for a date
  static DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static String _dayKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _planStorageKey(DateTime date) => '$_planKeyPrefix${_weekKey(date)}';

  static Future<List<PlannedMeal>> getPlannedMealsForDay(DateTime date) async {
    final allPlans = await getPlannedMealsForWeek(date);
    final key = _dayKey(date);
    return allPlans.where((p) => p.dayKey == key).toList();
  }

  static Future<List<PlannedMeal>> getPlannedMealsForWeek(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _planStorageKey(date);
    final data = prefs.getString(storageKey);
    if (data == null) return [];
    try {
      final List<dynamic> list = json.decode(data);
      return list.map((e) => PlannedMeal.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addPlannedMeal(PlannedMeal meal) async {
    final plans = await getPlannedMealsForWeek(DateTime.parse(meal.dayKey));
    plans.add(meal);
    await _saveWeekPlans(DateTime.parse(meal.dayKey), plans);
  }

  static Future<void> removePlannedMeal(String id, DateTime date) async {
    final plans = await getPlannedMealsForWeek(date);
    plans.removeWhere((p) => p.id == id);
    await _saveWeekPlans(date, plans);
  }

  static Future<void> updatePlannedMeal(PlannedMeal updated) async {
    final plans = await getPlannedMealsForWeek(DateTime.parse(updated.dayKey));
    final idx = plans.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      plans[idx] = updated;
      await _saveWeekPlans(DateTime.parse(updated.dayKey), plans);
    }
  }

  static Future<void> _saveWeekPlans(DateTime date, List<PlannedMeal> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _planStorageKey(date);
    final data = json.encode(plans.map((p) => p.toJson()).toList());
    await prefs.setString(storageKey, data);
  }

  // ============================================
  // ✅ HELPERS
  // ============================================

  static String generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Get list of day keys for the current week (Mon-Sun)
  static List<DateTime> getCurrentWeekDays() {
    final now = DateTime.now();
    final start = _weekStart(now);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  /// Get list of day keys for a given week start
  static List<DateTime> getWeekDays(DateTime weekStart) {
    return List.generate(7, (i) => weekStart.add(Duration(days: i)));
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Arabic day names
  static const List<String> dayNamesArabic = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];

  /// Short Arabic day names
  static const List<String> dayNamesShort = [
    'إثن', 'ثلث', 'أرب', 'خمس', 'جمع', 'سبت', 'أحد',
  ];
}