// lib/models/meal_plan_model.dart
// Models for Meal Planner: templates, meal plans, favorites

/// Represents a stored meal template (a saved combination of foods)
class MealTemplate {
  final String id;
  final String name;
  final String type; // فطور - غداء - عشاء - سناك
  final List<Map<String, dynamic>> foods; // [{foodId, name, quantity, unit, calories, protein, carbs, fat}]
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime createdAt;

  MealTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.foods,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MealTemplate.fromJson(Map<String, dynamic> json) {
    return MealTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      foods: (json['foods'] as List?)?.map((f) => Map<String, dynamic>.from(f)).toList() ?? [],
      totalCalories: (json['total_calories'] ?? 0).toDouble(),
      totalProtein: (json['total_protein'] ?? 0).toDouble(),
      totalCarbs: (json['total_carbs'] ?? 0).toDouble(),
      totalFat: (json['total_fat'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'foods': foods,
    'total_calories': totalCalories,
    'total_protein': totalProtein,
    'total_carbs': totalCarbs,
    'total_fat': totalFat,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Represents a favorite meal (saved from suggestions or user-created meals)
class FavoriteMeal {
  final String id;
  final String name;
  final String? description;
  final String type; // فطور - غداء - عشاء - سناك
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imageUrl;
  final DateTime createdAt;

  FavoriteMeal({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FavoriteMeal.fromJson(Map<String, dynamic> json) {
    return FavoriteMeal(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      type: json['type'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'image_url': imageUrl,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Represents a planned meal for a specific day
class PlannedMeal {
  final String id;
  final String dayKey; // e.g. "2026-05-22"
  final String type; // فطور - غداء - عشاء - سناك
  final String? templateId; // If planned from a template
  final String name;
  final List<Map<String, dynamic>> foods;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  PlannedMeal({
    required this.id,
    required this.dayKey,
    required this.type,
    this.templateId,
    required this.name,
    required this.foods,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    return PlannedMeal(
      id: json['id'] ?? '',
      dayKey: json['day_key'] ?? '',
      type: json['type'] ?? '',
      templateId: json['template_id'],
      name: json['name'] ?? '',
      foods: (json['foods'] as List?)?.map((f) => Map<String, dynamic>.from(f)).toList() ?? [],
      totalCalories: (json['total_calories'] ?? 0).toDouble(),
      totalProtein: (json['total_protein'] ?? 0).toDouble(),
      totalCarbs: (json['total_carbs'] ?? 0).toDouble(),
      totalFat: (json['total_fat'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'day_key': dayKey,
    'type': type,
    'template_id': templateId,
    'name': name,
    'foods': foods,
    'total_calories': totalCalories,
    'total_protein': totalProtein,
    'total_carbs': totalCarbs,
    'total_fat': totalFat,
  };
}