class SugarReading {
  final String id;
  final double value; // mg/dL
  final String type; // 'صائم', 'فاطر', 'عشوائي', 'قبل النوم'
  final DateTime dateTime;
  final String? notes;
  final String? mealDescription; // وصف الوجبة لو نوعها فاطر
  final int? carbGrams; // كمية الكارب بالجرام (اختياري)

  SugarReading({
    required this.id,
    required this.value,
    required this.type,
    required this.dateTime,
    this.notes,
    this.mealDescription,
    this.carbGrams,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'type': type,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
      'mealDescription': mealDescription,
      'carbGrams': carbGrams,
    };
  }

  factory SugarReading.fromJson(Map<String, dynamic> json) {
    return SugarReading(
      id: json['id'],
      value: json['value'].toDouble(),
      type: json['type'],
      dateTime: DateTime.parse(json['dateTime']),
      notes: json['notes'],
      mealDescription: json['mealDescription'],
      carbGrams: json['carbGrams'],
    );
  }

  // تحديد حالة القراءة (طبيعي - مرتفع - منخفض)
  String get status {
    switch (type) {
      case 'صائم':
        if (value < 70) return 'منخفض';
        if (value > 100) return 'مرتفع';
        return 'طبيعي';
      case 'فاطر':
        if (value < 140) return 'طبيعي';
        if (value < 180) return 'مرتفع قليلاً';
        return 'مرتفع';
      case 'عشوائي':
        if (value < 140) return 'طبيعي';
        if (value < 200) return 'مرتفع قليلاً';
        return 'مرتفع';
      case 'قبل النوم':
        if (value < 100) return 'منخفض';
        if (value > 140) return 'مرتفع';
        return 'طبيعي';
      default:
        return 'غير معروف';
    }
  }

  // الحصول على لون الحالة
  String get statusColor {
    switch (status) {
      case 'منخفض':
        return 'danger';
      case 'مرتفع':
        return 'danger';
      case 'مرتفع قليلاً':
        return 'warning';
      default:
        return 'success';
    }
  }
}

class PressureReading {
  final String id;
  final int systolic; // الانقباضي
  final int diastolic; // الانبساطي
  final int? pulse; // النبض
  final String position; // 'جالس', 'واقف', 'راقد'
  final String arm; // 'أيمن', 'أيسر'
  final DateTime dateTime;
  final String? notes;

  PressureReading({
    required this.id,
    required this.systolic,
    required this.diastolic,
    this.pulse,
    required this.position,
    required this.arm,
    required this.dateTime,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'position': position,
      'arm': arm,
      'dateTime': dateTime.toIso8601String(),
      'notes': notes,
    };
  }

  factory PressureReading.fromJson(Map<String, dynamic> json) {
    return PressureReading(
      id: json['id'],
      systolic: json['systolic'],
      diastolic: json['diastolic'],
      pulse: json['pulse'],
      position: json['position'],
      arm: json['arm'],
      dateTime: DateTime.parse(json['dateTime']),
      notes: json['notes'],
    );
  }

  // تحديد حالة القراءة
  String get status {
    if (systolic < 90 || diastolic < 60) return 'منخفض';
    if (systolic < 120 && diastolic < 80) return 'طبيعي';
    if (systolic < 130 && diastolic < 80) return 'مرتفع طبيعي';
    if (systolic < 140 || diastolic < 90) return 'مرتفع قليلاً';
    if (systolic < 180 || diastolic < 120) return 'مرتفع';
    return 'مرتفع جداً';
  }

  // الحصول على لون الحالة
  String get statusColor {
    switch (status) {
      case 'منخفض':
        return 'danger';
      case 'مرتفع':
      case 'مرتفع جداً':
        return 'danger';
      case 'مرتفع قليلاً':
      case 'مرتفع طبيعي':
        return 'warning';
      default:
        return 'success';
    }
  }
}

class HealthStatistics {
  final double averageSugar;
  final double minSugar;
  final double maxSugar;
  final int readingsCount;
  final int normalCount;
  final int highCount;
  final int lowCount;
  final double averageSystolic;
  final double averageDiastolic;
  final int pressureReadingsCount;

  HealthStatistics({
    required this.averageSugar,
    required this.minSugar,
    required this.maxSugar,
    required this.readingsCount,
    required this.normalCount,
    required this.highCount,
    required this.lowCount,
    required this.averageSystolic,
    required this.averageDiastolic,
    required this.pressureReadingsCount,
  });
}
