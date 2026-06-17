// lib/models/diabetes_models.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum BloodSugarType { fasting, beforeMeal, afterMeal, random, bedtime }

enum BloodSugarUnit { mgdl, mmol }

enum MeasurementContext { home, clinic, hospital }

enum SymptomSeverity { mild, moderate, severe }

class BloodSugarMeasurement {
  final int? id;
  final int userId;
  final double value;
  final BloodSugarType type;
  final BloodSugarUnit unit;
  final DateTime measuredAt;
  final MeasurementContext context;
  final String? notes;
  final String? mealDescription;
  final String? medicationTaken;
  final DateTime createdAt;

  BloodSugarMeasurement({
    this.id,
    required this.userId,
    required this.value,
    required this.type,
    required this.unit,
    required this.measuredAt,
    this.context = MeasurementContext.home,
    this.notes,
    this.mealDescription,
    this.medicationTaken,
    required this.createdAt,
  });

  factory BloodSugarMeasurement.fromJson(Map<String, dynamic> json) {
    return BloodSugarMeasurement(
      id: json['id'],
      userId: json['user_id'],
      value: json['value'].toDouble(),
      type: BloodSugarType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BloodSugarType.random,
      ),
      unit: BloodSugarUnit.values.firstWhere(
        (e) => e.name == json['unit'],
        orElse: () => BloodSugarUnit.mgdl,
      ),
      measuredAt: DateTime.parse(json['measured_at']),
      context: MeasurementContext.values.firstWhere(
        (e) => e.name == json['context'],
        orElse: () => MeasurementContext.home,
      ),
      notes: json['notes'],
      mealDescription: json['meal_description'],
      medicationTaken: json['medication_taken'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'value': value,
      'type': type.name,
      'unit': unit.name,
      'measured_at': measuredAt.toIso8601String(),
      'context': context.name,
      'notes': notes,
      'meal_description': mealDescription,
      'medication_taken': medicationTaken,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedValue {
    return '${value.toStringAsFixed(1)} ${unit == BloodSugarUnit.mgdl ? 'mg/dL' : 'mmol/L'}';
  }

  String get formattedTime {
    return DateFormat('hh:mm a').format(measuredAt);
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd').format(measuredAt);
  }

  String get typeLabel {
    switch (type) {
      case BloodSugarType.fasting:
        return 'صائم';
      case BloodSugarType.beforeMeal:
        return 'قبل الوجبة';
      case BloodSugarType.afterMeal:
        return 'بعد الوجبة';
      case BloodSugarType.random:
        return 'عشوائي';
      case BloodSugarType.bedtime:
        return 'قبل النوم';
    }
  }

  String get contextLabel {
    switch (context) {
      case MeasurementContext.home:
        return 'منزلي';
      case MeasurementContext.clinic:
        return 'عيادة';
      case MeasurementContext.hospital:
        return 'مستشفى';
    }
  }

  String get status {
    if (unit == BloodSugarUnit.mgdl) {
      if (type == BloodSugarType.fasting) {
        if (value < 70) return 'منخفض';
        if (value <= 100) return 'طبيعي';
        if (value <= 125) return 'ما قبل السكري';
        return 'مرتفع';
      } else if (type == BloodSugarType.afterMeal) {
        if (value < 140) return 'طبيعي';
        if (value <= 199) return 'ما قبل السكري';
        return 'مرتفع';
      } else {
        if (value < 70) return 'منخفض';
        if (value <= 140) return 'طبيعي';
        if (value <= 180) return 'مرتفع قليلاً';
        return 'مرتفع جداً';
      }
    } else {
      // mmol/L
      if (type == BloodSugarType.fasting) {
        if (value < 3.9) return 'منخفض';
        if (value <= 5.6) return 'طبيعي';
        if (value <= 6.9) return 'ما قبل السكري';
        return 'مرتفع';
      } else if (type == BloodSugarType.afterMeal) {
        if (value < 7.8) return 'طبيعي';
        if (value <= 11.0) return 'ما قبل السكري';
        return 'مرتفع';
      } else {
        if (value < 3.9) return 'منخفض';
        if (value <= 7.8) return 'طبيعي';
        if (value <= 10.0) return 'مرتفع قليلاً';
        return 'مرتفع جداً';
      }
    }
  }

  Color get statusColor {
    final statusText = status;
    switch (statusText) {
      case 'منخفض':
        return Colors.red;
      case 'طبيعي':
        return Colors.green;
      case 'ما قبل السكري':
        return Colors.orange;
      case 'مرتفع قليلاً':
        return Colors.orangeAccent;
      case 'مرتفع':
      case 'مرتفع جداً':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class DiabetesMedication {
  final int? id;
  final int userId;
  final String name;
  final String dosage;
  final String frequency;
  final String? instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  DiabetesMedication({
    this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.instructions,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
  });

  factory DiabetesMedication.fromJson(Map<String, dynamic> json) {
    return DiabetesMedication(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      instructions: json['instructions'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'instructions': instructions,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedStartDate {
    return DateFormat('yyyy-MM-dd').format(startDate);
  }

  String get formattedEndDate {
    return endDate != null
        ? DateFormat('yyyy-MM-dd').format(endDate!)
        : 'مستمر';
  }

  String get status {
    if (!isActive) return 'متوقف';
    if (endDate != null && endDate!.isBefore(DateTime.now())) {
      return 'منتهي';
    }
    return 'نشط';
  }

  Color get statusColor {
    switch (status) {
      case 'نشط':
        return Colors.green;
      case 'متوقف':
        return Colors.grey;
      case 'منتهي':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class DiabetesSymptom {
  final int? id;
  final int userId;
  final String symptomType; // New field
  final String symptomName; // New field
  final SymptomSeverity severity;
  final DateTime occurredAt;
  final String? notes;
  final String? triggers;
  final String? reliefMethods;
  final int durationMinutes;
  final DateTime createdAt;

  DiabetesSymptom({
    this.id,
    required this.userId,
    required this.symptomType,
    required this.symptomName,
    required this.severity,
    required this.occurredAt,
    this.notes,
    this.triggers,
    this.reliefMethods,
    required this.durationMinutes,
    required this.createdAt,
  });

  factory DiabetesSymptom.fromJson(Map<String, dynamic> json) {
    return DiabetesSymptom(
      id: json['id'],
      userId: json['user_id'],
      symptomType: json['symptom_type'],
      symptomName: json['symptom_name'],
      severity: SymptomSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => SymptomSeverity.mild,
      ),
      occurredAt: DateTime.parse(json['occurred_at']),
      notes: json['notes'],
      triggers: json['triggers'],
      reliefMethods: json['relief_methods'],
      durationMinutes: json['duration_minutes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'symptom_type': symptomType,
      'symptom_name': symptomName,
      'severity': severity.name,
      'occurred_at': occurredAt.toIso8601String(),
      'notes': notes,
      'triggers': triggers,
      'relief_methods': reliefMethods,
      'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedTime {
    return DateFormat('hh:mm a').format(occurredAt);
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd').format(occurredAt);
  }

  String get severityLabel {
    switch (severity) {
      case SymptomSeverity.mild:
        return 'خفيف';
      case SymptomSeverity.moderate:
        return 'متوسط';
      case SymptomSeverity.severe:
        return 'شديد';
    }
  }

  Color get severityColor {
    switch (severity) {
      case SymptomSeverity.mild:
        return Colors.blue;
      case SymptomSeverity.moderate:
        return Colors.orange;
      case SymptomSeverity.severe:
        return Colors.red;
    }
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes دقيقة';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) {
        return '$hours ساعة';
      } else {
        return '$hours ساعة و $minutes دقيقة';
      }
    }
  }
}

class DiabetesAnalysis {
  final DateTime date;
  final double averageBloodSugar;
  final int measurementCount;
  final int highReadings;
  final int lowReadings;
  final int normalReadings;
  final List<String> commonSymptoms;
  final List<String> medicationAdherence;

  DiabetesAnalysis({
    required this.date,
    required this.averageBloodSugar,
    required this.measurementCount,
    required this.highReadings,
    required this.lowReadings,
    required this.normalReadings,
    required this.commonSymptoms,
    required this.medicationAdherence,
  });

  factory DiabetesAnalysis.fromJson(Map<String, dynamic> json) {
    return DiabetesAnalysis(
      date: DateTime.parse(json['date']),
      averageBloodSugar: json['average_blood_sugar'].toDouble(),
      measurementCount: json['measurement_count'],
      highReadings: json['high_readings'],
      lowReadings: json['low_readings'],
      normalReadings: json['normal_readings'],
      commonSymptoms: List<String>.from(json['common_symptoms']),
      medicationAdherence: List<String>.from(json['medication_adherence']),
    );
  }

  double get controlPercentage {
    if (measurementCount == 0) return 0.0;
    return (normalReadings / measurementCount) * 100;
  }

  String get controlStatus {
    final percentage = controlPercentage;
    if (percentage >= 80) return 'ممتاز';
    if (percentage >= 60) return 'جيد';
    if (percentage >= 40) return 'متوسط';
    return 'ضعيف';
  }

  Color get controlStatusColor {
    switch (controlStatus) {
      case 'ممتاز':
        return Colors.green;
      case 'جيد':
        return Colors.lightGreen;
      case 'متوسط':
        return Colors.orange;
      case 'ضعيف':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
