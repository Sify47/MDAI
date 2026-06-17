// lib/models/weight_history_model.dart

class WeightHistory {
  final int id;
  final int userNutritionId;
  final double weight;
  final DateTime date;
  final DateTime createdAt;

  WeightHistory({
    required this.id,
    required this.userNutritionId,
    required this.weight,
    required this.date,
    required this.createdAt,
  });

  factory WeightHistory.fromJson(Map<String, dynamic> json) {
    return WeightHistory(
      id: json['id'] ?? 0, // ✅ استخدام القيم الافتراضية
      userNutritionId: json['user_nutrition_id'] ?? 0,
      weight: (json['weight'] ?? 0.0).toDouble(),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_nutrition_id': userNutritionId,
      'weight': weight,
      'date': date.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }
}
