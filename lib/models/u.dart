class UserNutritionData {
  final double weight;
  final double height;
  final int age;
  final String gender;
  final String goal;
  final String activityLevel;
  final String weightLossRate;
  final double targetWeight;
  final List<String> diseases;
  final double targetCalories; // تمت الإضافة

  UserNutritionData({
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.goal,
    required this.activityLevel,
    required this.weightLossRate,
    required this.targetWeight,
    required this.diseases,
    required this.targetCalories, // تمت الإضافة
  });
}
