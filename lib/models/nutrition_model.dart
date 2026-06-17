// lib/models/nutrition_model.dart

import 'package:flutter/material.dart';

// lib/models/nutrition_model.dart

// lib/models/nutrition_model.dart

class UserNutritionData {
  final int id;
  final double weight;
  final double height;
  final int age;
  final String gender;
  final String goal;
  final String activityLevel;
  final String weightLossRate;
  final double targetWeight;
  final List<String> diseases;
  final double targetCalories;
  final double bmr;
  final double tdee;
  final int? targetWeeks; // ✅ يمكن أن يكون null
  final double? initialWeight; // ✅ يمكن أن يكون null
  final DateTime createdAt;
  final double waterIntake; // ✅ أضف هذا الحقل


  UserNutritionData({
    required this.id,
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.goal,
    required this.activityLevel,
    required this.weightLossRate,
    required this.targetWeight,
    required this.diseases,
    required this.targetCalories,
    required this.bmr,
    required this.tdee,
    this.targetWeeks,
    this.initialWeight,
    required this.createdAt,
    required this.waterIntake, // ✅ أضف هذا
  });

  factory UserNutritionData.fromJson(Map<String, dynamic> json) {
    return UserNutritionData(
      id: json['id'] ?? 0,
      weight: (json['weight'] ?? 0.0).toDouble(),
      height: (json['height'] ?? 0.0).toDouble(),
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'ذكر',
      goal: json['goal'] ?? 'تخسيس',
      activityLevel: json['activity_level'] ?? 'متوسط',
      weightLossRate: (json['weight_loss_rate'] ?? '0.5').toString(),
      targetWeight: (json['target_weight'] ?? 0.0).toDouble(),
      diseases: List<String>.from(json['diseases'] ?? []),
      targetCalories: (json['target_calories'] ?? 0.0).toDouble(),
      bmr: (json['bmr'] ?? 0.0).toDouble(),
      tdee: (json['tdee'] ?? 0.0).toDouble(),
      targetWeeks: json['target_weeks'], // ✅ يمكن أن يكون null
      initialWeight: json['initial_weight'] != null ? (json['initial_weight'] as num).toDouble() : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      waterIntake: (json['water_intake'] ?? 2.5).toDouble(), // ✅ أضف هذا,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'goal': goal,
      'activity_level': activityLevel,
      'weight_loss_rate': weightLossRate,
      'target_weight': targetWeight,
      'diseases': diseases,
      'target_calories': targetCalories,
      'bmr': bmr,
      'tdee': tdee,
      'created_at': createdAt.toIso8601String(),
      'target_weeks': targetWeeks, // ✅ إضافة الوقت المستهدف (بالأسابيع)
      'initial_weight': initialWeight,
      'water_intake': waterIntake, // ✅ أضف هذا
    };
  }
}

class Food {
  final int id;
  final String name;
  final String nameEn;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String unit;
  final String category;
  final String icon;
  final bool isRecommended;
  final List<String> suitableFor; // الأمراض المناسبة

  Food({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.unit,
    required this.category,
    required this.icon,
    this.isRecommended = false,
    this.suitableFor = const [],
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      nameEn: json['name_en'],
      calories: json['calories'].toDouble(),
      protein: json['protein'].toDouble(),
      carbs: json['carbs'].toDouble(),
      fat: json['fat'].toDouble(),
      unit: json['unit'],
      category: json['category'],
      icon: json['icon'] ?? _getCategoryIcon(json['category']),
      isRecommended: json['is_recommended'] ?? false,
      suitableFor: List<String>.from(json['suitable_for'] ?? []),
    );
  }

  static String _getCategoryIcon(String category) {
    switch (category) {
      case 'كارب':
        return '🍚';
      case 'بروتين':
        return '🥩';
      case 'خضار':
        return '🥬';
      case 'فاكهة':
        return '🍎';
      case 'دهون':
        return '🥑';
      case 'مشروبات':
        return '🥤';
      default:
        return '🍽️';
    }
  }

  Color getCategoryColor() {
    switch (category) {
      case 'كارب':
        return Colors.orange;
      case 'بروتين':
        return Colors.blue;
      case 'خضار':
        return Colors.green;
      case 'فاكهة':
        return Colors.amber;
      case 'دهون':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class Meal {
  final int id;
  final int userId;
  final String type; // فطور - غداء - عشاء - سناك
  final List<SelectedFood> foods;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime dateTime;
  final String? notes;

  Meal({
    required this.id,
    required this.userId,
    required this.type,
    required this.foods,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.dateTime,
    this.notes,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      foods: (json['foods'] as List)
          .map((f) => SelectedFood.fromJson(f))
          .toList(),
      totalCalories: json['total_calories'].toDouble(),
      totalProtein: json['total_protein'].toDouble(),
      totalCarbs: json['total_carbs'].toDouble(),
      totalFat: json['total_fat'].toDouble(),
      dateTime: DateTime.parse(json['date_time']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'foods': foods.map((f) => f.toJson()).toList(),
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
      'date_time': dateTime.toIso8601String(),
      'notes': notes,
    };
  }
}

class SelectedFood {
  final int foodId;
  final String name;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  SelectedFood({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory SelectedFood.fromJson(Map<String, dynamic> json) {
    return SelectedFood(
      foodId: json['food_id'],
      name: json['name'],
      quantity: json['quantity'].toDouble(),
      unit: json['unit'],
      calories: json['calories'].toDouble(),
      protein: json['protein'].toDouble(),
      carbs: json['carbs'].toDouble(),
      fat: json['fat'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class DailySummary {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int mealsCount;
  final double waterIntake;
  final List<Meal> meals;

  DailySummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.mealsCount,
    required this.waterIntake,
    required this.meals,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: DateTime.parse(json['date']),
      totalCalories: json['total_calories'].toDouble(),
      totalProtein: json['total_protein'].toDouble(),
      totalCarbs: json['total_carbs'].toDouble(),
      totalFat: json['total_fat'].toDouble(),
      mealsCount: json['meals_count'],
      waterIntake: json['water_intake'].toDouble(),
      meals: (json['meals'] as List).map((m) => Meal.fromJson(m)).toList(),
    );
  }
}

// lib/models/nutrition_model.dart

class MealSuggestion {
  final int id;
  final String name;
  final String description;
  final String type; // الفئة (فطور - غداء - عشاء - سناك)
  final String? goal; // الهدف (تخسيس - تثبيت - زيادة)
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> suitableFor;
  final List<Map<String, dynamic>> ingredients;
  final String preparation;
  final String imageUrl;

  MealSuggestion({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.goal, // إضافة goal كخاصية اختيارية
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.suitableFor,
    required this.ingredients,
    required this.preparation,
    required this.imageUrl,
  });

  factory MealSuggestion.fromJson(Map<String, dynamic> json) {
    return MealSuggestion(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      goal: json['goal'], // قراءة goal من JSON
      calories: _toDouble(json['calories'] ?? 0),
      protein: _toDouble(json['protein'] ?? 0),
      carbs: _toDouble(json['carbs'] ?? 0),
      fat: _toDouble(json['fat'] ?? 0),
      suitableFor: _toStringList(json['suitable_for'] ?? []),
      ingredients: _toIngredientsList(json['ingredients'] ?? []),
      preparation: json['preparation'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  static List<Map<String, dynamic>> _toIngredientsList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        } else if (item is String) {
          return {'name': item, 'quantity': '', 'unit': ''};
        } else {
          return {'name': item.toString(), 'quantity': '', 'unit': ''};
        }
      }).toList();
    }
    if (value is String) {
      return value.split(',').map((item) {
        return {'name': item.trim(), 'quantity': '', 'unit': ''};
      }).toList();
    }
    return [];
  }
}
