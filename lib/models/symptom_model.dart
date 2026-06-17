// lib/models/symptom_model.dart

import 'dart:convert';

import 'package:flutter/material.dart';

class Symptom {
  final int id;
  final String name;
  final String? icon;
  final String severity;
  final DateTime dateTime;
  final String? notes;
  final String? analysis;
  final List<String>? possibleCauses;
  final List<String>? suggestedActions;
  final List<String>? warningSigns;
  final Map<String, dynamic>? foodRecommendations; // ✅ إضافة التوصيات الغذائية

  Symptom({
    required this.id,
    required this.name,
    this.icon,
    required this.severity,
    required this.dateTime,
    this.notes,
    this.analysis,
    this.possibleCauses,
    this.suggestedActions,
    this.warningSigns,
    this.foodRecommendations,
  });

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
      severity: json['severity']?.toString() ?? 'خفيف',
      dateTime: json['date_time'] != null
          ? DateTime.parse(json['date_time'])
          : DateTime.now(),
      notes: json['notes']?.toString(),
      analysis: json['analysis']?.toString(),
      possibleCauses: _toStringList(json['possible_causes']),
      suggestedActions: _toStringList(json['suggested_actions']),
      warningSigns: _toStringList(json['warning_signs']),
      foodRecommendations: json['food_recommendations'] is Map
          ? Map<String, dynamic>.from(json['food_recommendations'])
          : null,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      try {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return [value];
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'severity': severity,
      'date_time': dateTime.toIso8601String(),
      'notes': notes,
      'analysis': analysis,
      'possible_causes': possibleCauses,
      'suggested_actions': suggestedActions,
      'warning_signs': warningSigns,
      'food_recommendations': foodRecommendations,
    };
  }

  Color getSeverityColor() {
    switch (severity) {
      case 'خفيف':
        return Colors.green;
      case 'متوسط':
        return Colors.orange;
      case 'شديد':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
