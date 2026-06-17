// lib/models/dashboard_model.dart

class DashboardData {
  final UserData user;
  final ProgressData progress;
  final CaloriesData calories;
  final WalkingData walking;
  final MedicationsData medications;
  final SymptomsData symptoms;
  final List<Achievement> achievements;
  final WorkSchedule workSchedule;

  // حقول التقدم المتوقع
  final double expectedWeightChange;
  final double predictedWeight;
  final String progressMessage;

  // ✅ حقول المقارنة
  final double expectedWeightFromCalories;
  final double weightDifference;
  final String weightAdvice;

  // ✅ ML Prediction
  final MLPredictionData? mlPrediction;

  DashboardData({
    required this.user,
    required this.progress,
    required this.calories,
    required this.walking,
    required this.medications,
    required this.symptoms,
    required this.achievements,
    required this.workSchedule,
    required this.expectedWeightChange,
    required this.predictedWeight,
    required this.progressMessage,
    this.expectedWeightFromCalories = 0,
    this.weightDifference = 0,
    this.weightAdvice = '',
    this.mlPrediction,
  });

  DashboardData copyWith({
    UserData? user,
    ProgressData? progress,
    CaloriesData? calories,
    WalkingData? walking,
    MedicationsData? medications,
    SymptomsData? symptoms,
    List<Achievement>? achievements,
    WorkSchedule? workSchedule,
    double? expectedWeightChange,
    double? predictedWeight,
    String? progressMessage,
    double? expectedWeightFromCalories,
    double? weightDifference,
    String? weightAdvice,
    MLPredictionData? mlPrediction,
  }) {
    return DashboardData(
      user: user ?? this.user,
      progress: progress ?? this.progress,
      calories: calories ?? this.calories,
      walking: walking ?? this.walking,
      medications: medications ?? this.medications,
      symptoms: symptoms ?? this.symptoms,
      achievements: achievements ?? this.achievements,
      workSchedule: workSchedule ?? this.workSchedule,
      expectedWeightChange: expectedWeightChange ?? this.expectedWeightChange,
      predictedWeight: predictedWeight ?? this.predictedWeight,
      progressMessage: progressMessage ?? this.progressMessage,
      expectedWeightFromCalories:
          expectedWeightFromCalories ?? this.expectedWeightFromCalories,
      weightDifference: weightDifference ?? this.weightDifference,
      weightAdvice: weightAdvice ?? this.weightAdvice,
      mlPrediction: mlPrediction ?? this.mlPrediction,
    );
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      user: UserData.fromJson(json['user']),
      progress: ProgressData.fromJson(json['progress']),
      calories: CaloriesData.fromJson(json['calories']),
      walking: WalkingData.fromJson(json['walking']),
      medications: MedicationsData.fromJson(json['medications']),
      symptoms: SymptomsData.fromJson(json['symptoms']),
      achievements: (json['achievements'] as List)
          .map((e) => Achievement.fromJson(e))
          .toList(),
      workSchedule: WorkSchedule.fromJson(json['work_schedule']),
      expectedWeightChange: json['expected_weight_change'].toDouble(),
      predictedWeight: json['predicted_weight'].toDouble(),
      progressMessage: json['progress_message'],
      // ✅ قراءة حقول المقارنة
      expectedWeightFromCalories:
          json['expected_weight_from_calories']?.toDouble() ?? 0,
      weightDifference: json['weight_difference']?.toDouble() ?? 0,
      weightAdvice: json['weight_advice'] ?? '',
    );
  }
}

// ✅ نموذج بيانات توقع ML
class MLPredictionData {
  final double predictedWeight;
  final double confidence;
  final String method;
  final List<String> modelsUsed;
  final List<WeeklyPrediction> predictionsByWeek;
  final int weeksToTarget;
  final bool isAvailable;

  MLPredictionData({
    required this.predictedWeight,
    required this.confidence,
    required this.method,
    required this.modelsUsed,
    required this.predictionsByWeek,
    required this.weeksToTarget,
    this.isAvailable = true,
  });

  factory MLPredictionData.fromApi(Map<String, dynamic> json) {
    final predictions =
        (json['predictions_by_week'] as List?)
            ?.map(
              (e) => WeeklyPrediction(
                week: e['week'] ?? 0,
                weight: (e['weight'] ?? 0).toDouble(),
              ),
            )
            .toList() ??
        [];

    return MLPredictionData(
      predictedWeight: (json['predicted_weight'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      method: json['method'] ?? 'simple',
      modelsUsed: (json['models_used'] as List?)?.cast<String>() ?? [],
      predictionsByWeek: predictions,
      weeksToTarget: json['weeks_to_target'] ?? 0,
      isAvailable: json['success'] != false,
    );
  }

  factory MLPredictionData.unavailable() {
    return MLPredictionData(
      predictedWeight: 0,
      confidence: 0,
      method: 'غير متاح',
      modelsUsed: [],
      predictionsByWeek: [],
      weeksToTarget: 0,
      isAvailable: false,
    );
  }
}

class WeeklyPrediction {
  final int week;
  final double weight;

  WeeklyPrediction({required this.week, required this.weight});
}

class UserData {
  final String name;
  final int currentWeight;
  final int targetWeight;
  final String goalType;
  final double weeklyRate;
  final double? initialWeight; // ✅ أضف هذا الحقل

  UserData({
    required this.name,
    required this.currentWeight,
    required this.targetWeight,
    required this.goalType,
    required this.weeklyRate,
    this.initialWeight, // ✅ أضف هذا الحقل
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'],
      currentWeight: json['current_weight'],
      targetWeight: json['target_weight'],
      goalType: json['goal_type'],
      weeklyRate: json['weekly_rate'].toDouble(),
      initialWeight: json['initial_weight']
          ?.toDouble(), // ✅ قراءة الوزن الابتدائي
    );
  }
}

// lib/models/dashboard_model.dart

class ProgressData {
  final int lostWeight; // الوزن المفقود (لخسارة الوزن)
  final int gainedWeight; // الوزن المكتسب (لزيادة الوزن)
  final int remainingWeight; // المتبقي لخسارته
  final int remainingToGain; // المتبقي لزيادته
  final int percentage;
  final int weeksRemaining;

  ProgressData({
    required this.lostWeight,
    required this.gainedWeight,
    required this.remainingWeight,
    required this.remainingToGain,
    required this.percentage,
    required this.weeksRemaining,
  });

  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      lostWeight: json['lost_weight'],
      gainedWeight: json['gained_weight'],
      remainingWeight: json['remaining_weight'],
      remainingToGain: json['remaining_to_gain'],
      percentage: json['percentage'],
      weeksRemaining: json['weeks_remaining'],
    );
  }
}

class CaloriesData {
  final int consumed;
  final int target;
  final int percentage;

  CaloriesData({
    required this.consumed,
    required this.target,
    required this.percentage,
  });

  factory CaloriesData.fromJson(Map<String, dynamic> json) {
    return CaloriesData(
      consumed: json['consumed'],
      target: json['target'],
      percentage: json['percentage'],
    );
  }
}

class WalkingData {
  final int steps;
  final int target;
  final int percentage;
  final int caloriesBurned;
  final double distanceKm;
  final int durationMin;
  final LastActivity lastActivity;

  WalkingData({
    required this.steps,
    required this.target,
    required this.percentage,
    required this.caloriesBurned,
    required this.distanceKm,
    required this.durationMin,
    required this.lastActivity,
  });

  factory WalkingData.fromJson(Map<String, dynamic> json) {
    return WalkingData(
      steps: json['steps'],
      target: json['target'],
      percentage: json['percentage'],
      caloriesBurned: json['calories_burned'],
      distanceKm: json['distance_km'].toDouble(),
      durationMin: json['duration_min'],
      lastActivity: LastActivity.fromJson(json['last_activity']),
    );
  }
}

class LastActivity {
  final String type;
  final String time;

  LastActivity({required this.type, required this.time});

  factory LastActivity.fromJson(Map<String, dynamic> json) {
    return LastActivity(type: json['type'], time: json['time']);
  }
}

class MedicationsData {
  final int totalToday;
  final int taken;
  final int remaining;
  final List<Medication> list;

  MedicationsData({
    required this.totalToday,
    required this.taken,
    required this.remaining,
    required this.list,
  });

  factory MedicationsData.fromJson(Map<String, dynamic> json) {
    return MedicationsData(
      totalToday: json['total_today'],
      taken: json['taken'],
      remaining: json['remaining'],
      list: (json['list'] as List).map((e) => Medication.fromJson(e)).toList(),
    );
  }
}

class Medication {
  final String name;
  final String dose;
  final String time;
  final String status;
  final int? hoursRemaining;

  Medication({
    required this.name,
    required this.dose,
    required this.time,
    required this.status,
    this.hoursRemaining,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'],
      dose: json['dose'],
      time: json['time'],
      status: json['status'],
      hoursRemaining: json['hours_remaining'],
    );
  }
}

class SymptomsData {
  final List<Symptom> latest;
  final bool newToday;

  SymptomsData({required this.latest, required this.newToday});

  factory SymptomsData.fromJson(Map<String, dynamic> json) {
    return SymptomsData(
      latest: (json['latest'] as List).map((e) => Symptom.fromJson(e)).toList(),
      newToday: json['new_today'],
    );
  }
}

class Symptom {
  final String symptom;
  final String severity;
  final String date;
  final bool analyzed;

  Symptom({
    required this.symptom,
    required this.severity,
    required this.date,
    required this.analyzed,
  });

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      symptom: json['symptom'],
      severity: json['severity'],
      date: json['date'],
      analyzed: json['analyzed'],
    );
  }
}

class Achievement {
  final String text;
  final String type;

  Achievement({required this.text, required this.type});

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(text: json['text'], type: json['type']);
  }
}

class WorkSchedule {
  final String day;
  final String workHours;
  final List<String> reminderTimes;

  WorkSchedule({
    required this.day,
    required this.workHours,
    required this.reminderTimes,
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      day: json['day'],
      workHours: json['work_hours'],
      reminderTimes: List<String>.from(json['reminder_times']),
    );
  }
}
