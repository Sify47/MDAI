// lib/models/preferences_model.dart
// User taste preferences, variety settings, and nutrition gap analysis models

/// Taste preferences for personalizing meal suggestions
class TastePreferences {
  /// 1-5 scale: 1 = dislikes sweet, 5 = loves sweet
  int sweetTooth;

  /// 1-5 scale: 1 = no spice tolerance, 5 = loves spicy
  int spicyPreference;

  /// Preferred cuisines (e.g., 'مصري', 'إيطالي', 'آسيوي', 'صحي')
  List<String> preferredCuisines;

  /// Ingredients the user dislikes and wants to avoid
  List<String> dislikedIngredients;

  /// Number of days to avoid repeating the same meal (0 = disabled)
  int mealVarietyDays;

  TastePreferences({
    this.sweetTooth = 3,
    this.spicyPreference = 3,
    this.preferredCuisines = const [],
    this.dislikedIngredients = const [],
    this.mealVarietyDays = 3,
  });

  factory TastePreferences.fromJson(Map<String, dynamic> json) {
    return TastePreferences(
      sweetTooth: json['sweet_tooth'] ?? 3,
      spicyPreference: json['spicy_preference'] ?? 3,
      preferredCuisines:
          List<String>.from(json['preferred_cuisines'] ?? []),
      dislikedIngredients:
          List<String>.from(json['disliked_ingredients'] ?? []),
      mealVarietyDays: json['meal_variety_days'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() => {
    'sweet_tooth': sweetTooth,
    'spicy_preference': spicyPreference,
    'preferred_cuisines': preferredCuisines,
    'disliked_ingredients': dislikedIngredients,
    'meal_variety_days': mealVarietyDays,
  };
}

/// A detected nutrition gap in the user's daily intake
class NutritionGap {
  /// The food group that is missing/insufficient
  final String foodGroup;

  /// Arabic name for display
  final String displayName;

  /// Icon/emoji for the food group
  final String icon;

  /// Priority level
  final GapPriority priority;

  /// Human-readable suggestion in Arabic
  final String suggestion;

  /// Current consumed amount
  final double currentAmount;

  /// Recommended target amount
  final double targetAmount;

  const NutritionGap({
    required this.foodGroup,
    required this.displayName,
    required this.icon,
    required this.priority,
    required this.suggestion,
    required this.currentAmount,
    required this.targetAmount,
  });
}

/// Priority for nutrition gaps
enum GapPriority { high, medium, low }

/// A meal variety tracking entry — records when a meal was last eaten
class MealVarietyRecord {
  final String mealName;
  final DateTime lastEatenDate;

  const MealVarietyRecord({
    required this.mealName,
    required this.lastEatenDate,
  });

  factory MealVarietyRecord.fromJson(Map<String, dynamic> json) {
    return MealVarietyRecord(
      mealName: json['meal_name'] ?? '',
      lastEatenDate: json['last_eaten_date'] != null
          ? DateTime.parse(json['last_eaten_date'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'meal_name': mealName,
    'last_eaten_date': lastEatenDate.toIso8601String(),
  };
}