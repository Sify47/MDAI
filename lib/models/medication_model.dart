import 'medicine_model.dart';

class UserMedication {
  final String id;
  final int? userId; // ✅ إضافة userId (للمستقبل)
  final int? medicineId;
  final Medicine? medicineInfo;

  // الحقول المتبقية (الخاصة بالمستخدم فقط)
  final int timesPerDay;
  final List<String> times;
  final bool withFood;
  final String? notes;
  final DateTime startDate;
  final DateTime? endDate;
  final int daysActive;
  int takenCount;

  // Getters للوصول السهل لبيانات Medicine
  String get name => medicineInfo?.nameAr ?? 'دواء بدون اسم';
  String get dosage => medicineInfo?.dosageInfo ?? '';
  String get unit => '';
  String get medicationType => medicineInfo?.category ?? 'عام';
  String get color => _getColorFromCategory(medicineInfo?.category);
  String get icon => '💊';

  // الخصائص الإضافية من Medicine
  List<String>? get sideEffects => medicineInfo?.sideEffects;
  List<String>? get warnings => medicineInfo?.warnings;
  List<String>? get interactions => medicineInfo?.interactions;
  String? get description => medicineInfo?.description;
  String? get howToTake => medicineInfo?.howToTake;
  String? get storage => medicineInfo?.storage;
  String? get imageUrl => medicineInfo?.imageUrl;

  UserMedication({
    required this.id,
    this.userId, // ✅ إضافة userId
    this.medicineId,
    this.medicineInfo,
    required this.timesPerDay,
    required this.times,
    required this.withFood,
    this.notes,
    required this.startDate,
    this.endDate,
    required this.daysActive,
    required this.takenCount,
  });

  // دوال مساعدة للتحويل الآمن
  static String _safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    return value.toString();
  }

  static int _safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return defaultValue;
  }

  static bool _safeBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return defaultValue;
  }

  static List<String> _safeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static DateTime _safeDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.now();
  }

  // لون حسب تصنيف الدواء
  static String _getColorFromCategory(String? category) {
    switch (category) {
      case 'أدوية السكري':
        return '#4CAF50';
      case 'أدوية الضغط':
      case 'أدوية القلب':
        return '#2196F3';
      case 'مضادات حيوية':
        return '#F44336';
      case 'مسكنات':
        return '#FF9800';
      case 'مضادات التهاب':
        return '#9C27B0';
      default:
        return '#4CAF50';
    }
  }

  // من JSON (لما نجيب من API)
  factory UserMedication.fromJson(Map<String, dynamic> json) {
    print('🔄 تحويل UserMedication: $json');

    return UserMedication(
      id: _safeString(json['id']),
      userId: _safeInt(json['user_id'], defaultValue: 0), // ✅ إضافة userId
      medicineId: _safeInt(json['medicine_id'], defaultValue: 0),
      medicineInfo: json['medicine_info'] != null
          ? Medicine.fromJson(json['medicine_info'])
          : null,
      timesPerDay: _safeInt(json['times_per_day']),
      times: _safeStringList(json['times']),
      withFood: _safeBool(json['with_food'], defaultValue: true),
      notes: _safeString(json['notes']),
      startDate: _safeDate(json['start_date']),
      endDate: json['end_date'] != null ? _safeDate(json['end_date']) : null,
      daysActive: _safeInt(json['days_active']),
      takenCount: _safeInt(json['taken_today']),
    );
  }

  // إلى JSON (لما نرسل للـ API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId, // ✅ إضافة userId
      'medicine_id': medicineId,
      'times_per_day': timesPerDay,
      'times': times,
      'with_food': withFood,
      'notes': notes,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'days_active': daysActive,
      'taken_count': takenCount,
    };
  }
}


class MedicationDose {
  final String id;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  String status;
  final String dose;

  MedicationDose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    required this.dose,
  });

  factory MedicationDose.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is int) return value.toString();
      if (value is double) return value.toString();
      return value.toString();
    }

    return MedicationDose(
      id: safeString(json['id']),
      medicationId: safeString(json['medication_id']),
      medicationName: json['medication_name'] ?? 'دواء بدون اسم',
      scheduledTime: DateTime.parse(
        json['scheduled_time'] ?? DateTime.now().toIso8601String(),
      ),
      takenTime: json['taken_time'] != null
          ? DateTime.parse(json['taken_time'])
          : null,
      status: json['status'] ?? 'pending',
      dose: json['dose'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medication_id': medicationId,
      'medication_name': medicationName,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime?.toIso8601String(),
      'status': status,
      'dose': dose,
    };
  }
}

class MedicationStatistics {
  final int totalDoses;
  final int takenDoses;
  final int missedDoses;
  final int pendingDoses;
  final double adherenceRate;

  MedicationStatistics({
    required this.totalDoses,
    required this.takenDoses,
    required this.missedDoses,
    required this.pendingDoses,
    required this.adherenceRate,
  });
}
