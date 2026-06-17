// lib/services/diabetes_api.dart

import 'dart:convert';
import 'package:vita/utils/prefs_helper.dart';
import 'package:http/http.dart' as http;
import '../models/diabetes_models.dart';

class DiabetesApi {
  static const String baseUrl = 'http://10.0.2.2:8000'; // للأندرويد
  // static const String baseUrl = 'http://127.0.0.1:8000'; // للويب
  // static const String baseUrl = 'http://65.75.201.173:8000';

  static String _getUrl(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final url = '$baseUrl/api/diabetes$cleanPath';
    print('🌐 Diabetes API URL: $url');
    return url;
  }

  // ✅ دالة مساعدة لجلب التوكن والهيدرات
  static Future<Map<String, String>> _getHeaders() async {
    final token = await PrefsHelper.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // 📊 1. قياسات السكر في الدم
  // ============================================

  Future<List<BloodSugarMeasurement>> getBloodSugarMeasurements(
    int userId,
  ) async {
    try {
      final url = _getUrl('/measurements?user_id=$userId');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((json) => BloodSugarMeasurement.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب قياسات السكر: $e');
      return [];
    }
  }

  Future<BloodSugarMeasurement?> addBloodSugarMeasurement(
    int userId,
    double value,
    BloodSugarType type,
    BloodSugarUnit unit,
    DateTime measuredAt,
    MeasurementContext context,
    String? notes,
    String? mealDescription,
    String? medicationTaken,
  ) async {
    try {
      final url = _getUrl('/measurements');
      final headers = await _getHeaders();

      final body = json.encode({
        'user_id': userId,
        'value': value,
        'type': type.name,
        'unit': unit.name,
        'measured_at': measuredAt.toIso8601String(),
        'context': context.name,
        'notes': notes,
        'meal_description': mealDescription,
        'medication_taken': medicationTaken,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return BloodSugarMeasurement.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('🔥 خطأ في إضافة قياس السكر: $e');
      return null;
    }
  }

  Future<bool> updateBloodSugarMeasurement(
    int measurementId,
    double? value,
    BloodSugarType? type,
    String? notes,
  ) async {
    try {
      final url = _getUrl('/measurements/$measurementId');
      final headers = await _getHeaders();

      final body = json.encode({
        if (value != null) 'value': value,
        if (type != null) 'type': type.name,
        if (notes != null) 'notes': notes,
      });

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('🔥 خطأ في تحديث قياس السكر: $e');
      return false;
    }
  }

  Future<bool> deleteBloodSugarMeasurement(int measurementId) async {
    try {
      final url = _getUrl('/measurements/$measurementId');
      final headers = await _getHeaders();

      final response = await http.delete(Uri.parse(url), headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print('🔥 خطأ في حذف قياس السكر: $e');
      return false;
    }
  }

  // ============================================
  // 💊 2. أدوية السكري
  // ============================================

  Future<List<DiabetesMedication>> getDiabetesMedications(int userId) async {
    try {
      final url = _getUrl('/medications?user_id=$userId');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((json) => DiabetesMedication.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب أدوية السكري: $e');
      return [];
    }
  }

  Future<DiabetesMedication?> addDiabetesMedication(
    int userId,
    String name,
    String dosage,
    String frequency,
    String? instructions,
    DateTime startDate,
    DateTime? endDate,
    bool isActive,
  ) async {
    try {
      final url = _getUrl('/medications');
      final headers = await _getHeaders();

      final body = json.encode({
        'user_id': userId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'instructions': instructions,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_active': isActive,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return DiabetesMedication.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('🔥 خطأ في إضافة دواء السكري: $e');
      return null;
    }
  }

  Future<bool> updateDiabetesMedication(
    int medicationId,
    String? name,
    String? dosage,
    String? frequency,
    String? instructions,
    bool? isActive,
  ) async {
    try {
      final url = _getUrl('/medications/$medicationId');
      final headers = await _getHeaders();

      final body = json.encode({
        if (name != null) 'name': name,
        if (dosage != null) 'dosage': dosage,
        if (frequency != null) 'frequency': frequency,
        if (instructions != null) 'instructions': instructions,
        if (isActive != null) 'is_active': isActive,
      });

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('🔥 خطأ في تحديث دواء السكري: $e');
      return false;
    }
  }

  Future<bool> deleteDiabetesMedication(int medicationId) async {
    try {
      final url = _getUrl('/medications/$medicationId');
      final headers = await _getHeaders();

      final response = await http.delete(Uri.parse(url), headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print('🔥 خطأ في حذف دواء السكري: $e');
      return false;
    }
  }

  // ============================================
  // 🤒 3. أعراض السكري
  // ============================================

  Future<List<DiabetesSymptom>> getDiabetesSymptoms(int userId) async {
    try {
      final url = _getUrl('/symptoms?user_id=$userId');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => DiabetesSymptom.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب أعراض السكري: $e');
      return [];
    }
  }

  Future<DiabetesSymptom?> addDiabetesSymptom(
    int userId,
    String symptomType,
    String symptomName,
    SymptomSeverity severity,
    DateTime occurredAt,
    String? notes,
    String? triggers,
    String? reliefMethods,
    int durationMinutes,
  ) async {
    try {
      final url = _getUrl('/symptoms');
      final headers = await _getHeaders();

      final body = json.encode({
        'user_id': userId,
        'symptom_type': symptomType,
        'symptom_name': symptomName,
        'severity': severity.name,
        'occurred_at': occurredAt.toIso8601String(),
        'notes': notes,
        'triggers': triggers,
        'relief_methods': reliefMethods,
        'duration_minutes': durationMinutes,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return DiabetesSymptom.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('🔥 خطأ في إضافة عرض السكري: $e');
      return null;
    }
  }

  Future<bool> updateDiabetesSymptom(
    int symptomId,
    String? symptom,
    SymptomSeverity? severity,
    String? notes,
    String? triggers,
    String? reliefMethods,
    int? durationMinutes,
  ) async {
    try {
      final url = _getUrl('/symptoms/$symptomId');
      final headers = await _getHeaders();

      final body = json.encode({
        if (symptom != null) 'symptom': symptom,
        if (severity != null) 'severity': severity.name,
        if (notes != null) 'notes': notes,
        if (triggers != null) 'triggers': triggers,
        if (reliefMethods != null) 'relief_methods': reliefMethods,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
      });

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('🔥 خطأ في تحديث عرض السكري: $e');
      return false;
    }
  }

  Future<bool> deleteDiabetesSymptom(int symptomId) async {
    try {
      final url = _getUrl('/symptoms/$symptomId');
      final headers = await _getHeaders();

      final response = await http.delete(Uri.parse(url), headers: headers);

      return response.statusCode == 200;
    } catch (e) {
      print('🔥 خطأ في حذف عرض السكري: $e');
      return false;
    }
  }

  // ============================================
  // 📈 4. التحليلات والإحصائيات
  // ============================================

  Future<DiabetesAnalysis?> getDiabetesAnalysis(
    int userId,
    String period,
  ) async {
    try {
      final url = _getUrl('/analysis?user_id=$userId&period=$period');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DiabetesAnalysis.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('🔥 خطأ في جلب تحليل السكري: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getBloodSugarTrends(
    int userId,
    String period,
  ) async {
    try {
      final url = _getUrl('/trends?user_id=$userId&period=$period');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('🔥 خطأ في جلب اتجاهات السكر: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDiabetesSummary(int userId) async {
    try {
      final url = _getUrl('/summary?user_id=$userId');
      final headers = await _getHeaders();

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('🔥 خطأ في جلب ملخص السكري: $e');
      return null;
    }
  }
}
