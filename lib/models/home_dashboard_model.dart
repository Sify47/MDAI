// Simplified dashboard model for home screen

class HomeDashboardData {
  final UserData user;
  final MedicationsData medications;
  final WalkingData walking;
  final NutritionData nutrition;
  final SymptomsData symptoms;
  final WeightData weight;
  final WaterData water;
  final int healthScore;
  final DateTime lastUpdated;

  HomeDashboardData({
    required this.user,
    required this.medications,
    required this.walking,
    required this.nutrition,
    required this.symptoms,
    required this.weight,
    required this.water,
    required this.healthScore,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'medications': medications.toJson(),
      'walking': walking.toJson(),
      'nutrition': nutrition.toJson(),
      'symptoms': symptoms.toJson(),
      'weight': weight.toJson(),
      'water': water.toJson(),
      'healthScore': healthScore,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory HomeDashboardData.fromJson(Map<String, dynamic> json) {
    return HomeDashboardData(
      user: UserData.fromJson(json['user']),
      medications: MedicationsData.fromJson(json['medications']),
      walking: WalkingData.fromJson(json['walking']),
      nutrition: NutritionData.fromJson(json['nutrition']),
      symptoms: SymptomsData.fromJson(json['symptoms']),
      weight: WeightData.fromJson(json['weight']),
      water: WaterData.fromJson(json['water']),
      healthScore: json['healthScore'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

class UserData {
  final String name;
  final int age;
  final double weight;
  final double height;
  final String gender;
  final List<String> healthConditions;

  UserData({
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.healthConditions,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'healthConditions': healthConditions,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'],
      age: json['age'],
      weight: json['weight'].toDouble(),
      height: json['height'].toDouble(),
      gender: json['gender'],
      healthConditions: List<String>.from(json['healthConditions']),
    );
  }
}

class MedicationsData {
  final int todayCount;
  final double adherenceRate;
  final Medication? nextMedication;
  final List<Medication> latest;

  MedicationsData({
    required this.todayCount,
    required this.adherenceRate,
    this.nextMedication,
    required this.latest,
  });

  Map<String, dynamic> toJson() {
    return {
      'todayCount': todayCount,
      'adherenceRate': adherenceRate,
      'nextMedication': nextMedication?.toJson(),
      'latest': latest.map((e) => e.toJson()).toList(),
    };
  }

  factory MedicationsData.fromJson(Map<String, dynamic> json) {
    return MedicationsData(
      todayCount: json['todayCount'],
      adherenceRate: json['adherenceRate'].toDouble(),
      nextMedication: json['nextMedication'] != null
          ? Medication.fromJson(json['nextMedication'])
          : null,
      latest: (json['latest'] as List)
          .map((e) => Medication.fromJson(e))
          .toList(),
    );
  }
}

class Medication {
  final String name;
  final String dosage;
  final DateTime time;

  Medication({
    required this.name,
    required this.dosage,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'time': time.toIso8601String(),
    };
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'],
      dosage: json['dosage'],
      time: DateTime.parse(json['time']),
    );
  }
}

class WalkingData {
  final int steps;
  final int goal;
  final double progress;
  final int percentage;
  final List<WalkingActivity> latest;

  WalkingData({
    required this.steps,
    required this.goal,
    required this.progress,
    required this.percentage,
    required this.latest,
  });

  Map<String, dynamic> toJson() {
    return {
      'steps': steps,
      'goal': goal,
      'progress': progress,
      'percentage': percentage,
      'latest': latest.map((e) => e.toJson()).toList(),
    };
  }

  factory WalkingData.fromJson(Map<String, dynamic> json) {
    return WalkingData(
      steps: json['steps'],
      goal: json['goal'],
      progress: json['progress'].toDouble(),
      percentage: json['percentage'],
      latest: (json['latest'] as List)
          .map((e) => WalkingActivity.fromJson(e))
          .toList(),
    );
  }
}

class WalkingActivity {
  final DateTime date;
  final int steps;
  final double distance;

  WalkingActivity({
    required this.date,
    required this.steps,
    required this.distance,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'steps': steps,
      'distance': distance,
    };
  }

  factory WalkingActivity.fromJson(Map<String, dynamic> json) {
    return WalkingActivity(
      date: DateTime.parse(json['date']),
      steps: json['steps'],
      distance: json['distance'].toDouble(),
    );
  }
}

class NutritionData {
  final int calories;
  final int goal;
  final double progress;
  final int percentage;
  final List<Meal> latest;

  NutritionData({
    required this.calories,
    required this.goal,
    required this.progress,
    required this.percentage,
    required this.latest,
  });

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'goal': goal,
      'progress': progress,
      'percentage': percentage,
      'latest': latest.map((e) => e.toJson()).toList(),
    };
  }

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
      calories: json['calories'],
      goal: json['goal'],
      progress: json['progress'].toDouble(),
      percentage: json['percentage'],
      latest: (json['latest'] as List)
          .map((e) => Meal.fromJson(e))
          .toList(),
    );
  }
}

class Meal {
  final String name;
  final int calories;
  final DateTime time;

  Meal({
    required this.name,
    required this.calories,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'time': time.toIso8601String(),
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: json['name'],
      calories: json['calories'],
      time: DateTime.parse(json['time']),
    );
  }
}

class SymptomsData {
  final int todayCount;
  final int severity;
  final List<Symptom> latest;

  SymptomsData({
    required this.todayCount,
    required this.severity,
    required this.latest,
  });

  Map<String, dynamic> toJson() {
    return {
      'todayCount': todayCount,
      'severity': severity,
      'latest': latest.map((e) => e.toJson()).toList(),
    };
  }

  factory SymptomsData.fromJson(Map<String, dynamic> json) {
    return SymptomsData(
      todayCount: json['todayCount'],
      severity: json['severity'],
      latest: (json['latest'] as List)
          .map((e) => Symptom.fromJson(e))
          .toList(),
    );
  }
}

class Symptom {
  final String name;
  final int severity;
  final DateTime time;

  Symptom({
    required this.name,
    required this.severity,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'severity': severity,
      'time': time.toIso8601String(),
    };
  }

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      name: json['name'],
      severity: json['severity'],
      time: DateTime.parse(json['time']),
    );
  }
}

class WeightData {
  final double current;
  final double target;
  final double progress;
  final int percentage;
  final List<WeightRecord> latest;

  WeightData({
    required this.current,
    required this.target,
    required this.progress,
    required this.percentage,
    required this.latest,
  });

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'target': target,
      'progress': progress,
      'percentage': percentage,
      'latest': latest.map((e) => e.toJson()).toList(),
    };
  }

  factory WeightData.fromJson(Map<String, dynamic> json) {
    return WeightData(
      current: json['current'].toDouble(),
      target: json['target'].toDouble(),
      progress: json['progress'].toDouble(),
      percentage: json['percentage'],
      latest: (json['latest'] as List)
          .map((e) => WeightRecord.fromJson(e))
          .toList(),
    );
  }
}

class WeightRecord {
  final DateTime date;
  final double weight;

  WeightRecord({
    required this.date,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'weight': weight,
    };
  }

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      date: DateTime.parse(json['date']),
      weight: json['weight'].toDouble(),
    );
  }
}

class WaterData {
  final double intake;
  final double goal;
  final double progress;
  final int percentage;

  WaterData({
    required this.intake,
    required this.goal,
    required this.progress,
    required this.percentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'intake': intake,
      'goal': goal,
      'progress': progress,
      'percentage': percentage,
    };
  }

  factory WaterData.fromJson(Map<String, dynamic> json) {
    return WaterData(
      intake: json['intake'].toDouble(),
      goal: json['goal'].toDouble(),
      progress: json['progress'].toDouble(),
      percentage: json['percentage'],
    );
  }
}