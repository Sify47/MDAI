class WalkingActivity {
  final int id;
  final int? userId; // ✅ إضافة userId (للمستقبل)
  final int steps;
  final double distanceKm;
  final int durationMinutes;
  final int caloriesBurned;
  final String activityType; // ✅ نوع النشاط: walking, running, cycling, swimming, strength, yoga
  final DateTime activityDate;
  final String? activityTime;
  final String? notes;

  WalkingActivity({
    required this.id,
    this.userId, // ✅ إضافة userId
    required this.steps,
    required this.distanceKm,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.activityType = 'walking', // ✅ القيمة الافتراضية
    required this.activityDate,
    this.activityTime,
    this.notes,
  });

  factory WalkingActivity.fromJson(Map<String, dynamic> json) {
    return WalkingActivity(
      id: json['id'] ?? 0,
      userId: json['user_id'], // ✅ إضافة userId
      steps: json['steps'] ?? 0,
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
      durationMinutes: json['duration_minutes'] ?? 0,
      caloriesBurned: json['calories_burned'] ?? 0,
      activityType: json['activity_type'] ?? 'walking',
      activityDate: DateTime.parse(
        json['activity_date'] ?? DateTime.now().toIso8601String(),
      ),
      activityTime: json['activity_time'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId, // ✅ إضافة userId
      'steps': steps,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'activity_type': activityType,
      'activity_date': activityDate.toIso8601String().split('T')[0],
      'activity_time': activityTime ?? '00:00',
      'notes': notes ?? '',
    };
  }
}

class WalkingStats {
  final int totalActivities;
  final int totalSteps;
  final double totalDistance;
  final int totalCalories;
  final int todaySteps;
  final int weekSteps;
  final int monthSteps;
  final int averageSteps;
  final String? bestDay;
  final int bestDaySteps;

  WalkingStats({
    required this.totalActivities,
    required this.totalSteps,
    required this.totalDistance,
    required this.totalCalories,
    required this.todaySteps,
    required this.weekSteps,
    required this.monthSteps,
    required this.averageSteps,
    this.bestDay,
    required this.bestDaySteps,
  });

  factory WalkingStats.fromJson(Map<String, dynamic> json) {
    return WalkingStats(
      totalActivities: json['total_activities'] ?? 0,
      totalSteps: json['total_steps'] ?? 0,
      totalDistance: (json['total_distance'] ?? 0).toDouble(),
      totalCalories: json['total_calories'] ?? 0,
      todaySteps: json['today_steps'] ?? 0,
      weekSteps: json['week_steps'] ?? 0,
      monthSteps: json['month_steps'] ?? 0,
      averageSteps: json['average_steps'] ?? 0,
      bestDay: json['best_day'],
      bestDaySteps: json['best_day_steps'] ?? 0,
    );
  }
}
