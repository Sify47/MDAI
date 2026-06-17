// lib/services/predictive_prevention_api.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vita/utils/prefs_helper.dart';

class PredictivePreventionApi {
  static final String _baseUrl =
      'http://10.0.2.2:8000/api/predictive-prevention';
  // static final String _baseUrl = 'http://65.75.201.173:8000/api/predictive-prevention';

  // ✅ دالة مساعدة لجلب التوكن والهيدرز
  static Future<Map<String, String>> _getHeaders() async {
    final token = await PrefsHelper.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // تحليل المخاطر الصحية
  static Future<List<Map<String, dynamic>>> analyzeHealthRisks() async {
    try {
      final userId = await PrefsHelper.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/analyze?user_id=$userId');
      final response = await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          'Failed to analyze health risks: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error analyzing health risks: $e');
      rethrow;
    }
  }

  // حفظ تحليل المخاطر
  static Future<Map<String, dynamic>> createHealthRisk({
    required String riskType,
    required String riskLevel,
    required double probability,
    required double confidence,
    required List<String> factors,
    required String timeframe,
    required String description,
    required List<String> recommendations,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = await PrefsHelper.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final headers = await _getHeaders();
      final body = {
        'user_id': userId,
        'risk_type': riskType,
        'risk_level': riskLevel,
        'probability': probability,
        'confidence': confidence,
        'factors': factors,
        'timeframe': timeframe,
        'description': description,
        'recommendations': recommendations,
        'metadata': metadata ?? {},
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/risks'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create health risk: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating health risk: $e');
      rethrow;
    }
  }

  // جلب تحليلات المخاطر
  static Future<List<Map<String, dynamic>>> getHealthRisks({
    String? riskType,
    String? riskLevel,
    int? limit,
  }) async {
    try {
      final userId = await PrefsHelper.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final headers = await _getHeaders();
      final queryParams = <String, String>{'user_id': userId.toString()};

      if (riskType != null) queryParams['risk_type'] = riskType;
      if (riskLevel != null) queryParams['risk_level'] = riskLevel;
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse(
        '$_baseUrl/risks',
      ).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to get health risks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting health risks: $e');
      rethrow;
    }
  }

  // إنشاء خطة وقائية
  static Future<Map<String, dynamic>> createPreventionPlan({
    required int riskId,
    required String planName,
    required String description,
    required List<Map<String, dynamic>> actions,
    required int timelineDays,
    String priority = 'medium',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = await PrefsHelper.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final headers = await _getHeaders();
      final body = {
        'user_id': userId,
        'risk_id': riskId,
        'plan_name': planName,
        'description': description,
        'actions': actions,
        'timeline_days': timelineDays,
        'priority': priority,
        'metadata': metadata ?? {},
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/plans'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create prevention plan: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating prevention plan: $e');
      rethrow;
    }
  }

  // جلب الخطط الوقائية
  static Future<List<Map<String, dynamic>>> getPreventionPlans({
    String? status,
    String? priority,
  }) async {
    try {
      final userId = await PrefsHelper.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final headers = await _getHeaders();
      final queryParams = <String, String>{'user_id': userId.toString()};

      if (status != null) queryParams['status'] = status;
      if (priority != null) queryParams['priority'] = priority;

      final uri = Uri.parse(
        '$_baseUrl/plans',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
          'Failed to get prevention plans: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error getting prevention plans: $e');
      rethrow;
    }
  }

  // تحديث تقدم الخطة
  static Future<void> updatePlanProgress({
    required int planId,
    required double progressPercentage,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{'progress_percentage': progressPercentage};

      if (status != null) {
        body['status'] = status;
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/plans/$planId/progress'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update plan progress: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating plan progress: $e');
      rethrow;
    }
  }

  // الحصول على لوحة تحكم الوقاية
  static Future<Map<String, dynamic>> getPreventionDashboard() async {
    try {
      final userId = await PrefsHelper.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/dashboard?user_id=$userId');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to get prevention dashboard: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error getting prevention dashboard: $e');
      rethrow;
    }
  }

  // الحصول على المخاطر عالية المستوى
  static Future<List<Map<String, dynamic>>> getHighRiskPredictions() async {
    try {
      final risks = await getHealthRisks(riskLevel: 'high', limit: 5);
      return risks;
    } catch (e) {
      print('Error getting high risk predictions: $e');
      rethrow;
    }
  }

  // الحصول على الخطط النشطة
  static Future<List<Map<String, dynamic>>> getActivePreventionPlans() async {
    try {
      final plans = await getPreventionPlans(status: 'in_progress');
      return plans;
    } catch (e) {
      print('Error getting active prevention plans: $e');
      rethrow;
    }
  }

  // lib/services/predictive_prevention_api.dart

  // استبدل دالة analyzeAndCreatePlans بهذه النسخة المعدلة

  // تحليل المخاطر وإنشاء خطط وقائية تلقائياً
  static Future<Map<String, dynamic>> analyzeAndCreatePlans() async {
    try {
      final risks = await analyzeHealthRisks();

      if (risks.isEmpty || risks == null) {
        return {
          'success': true,
          'message': 'لا توجد مخاطر صحية تحتاج إلى خطط وقائية',
          'risks_analyzed': 0,
          'plans_created': 0,
        };
      }

      int plansCreated = 0;
      int risksAnalyzed = 0;

      for (final risk in risks) {
        risksAnalyzed++;

        // ✅ التحقق من وجود risk_id بشكل آمن
        final riskId = risk['id'];
        final riskLevel = risk['risk_level'] ?? 'low';
        final riskType = risk['risk_type'] ?? 'unknown';

        // ✅ التأكد من أن riskId موجود وصالح
        if (riskId == null) {
          print('⚠️ Risk ID is null, skipping risk: $riskType');
          continue;
        }

        // ✅ التحقق من أن riskId من النوع int
        int safeRiskId;
        if (riskId is int) {
          safeRiskId = riskId;
        } else if (riskId is String) {
          safeRiskId = int.tryParse(riskId) ?? 0;
        } else if (riskId is double) {
          safeRiskId = riskId.toInt();
        } else {
          print('⚠️ Risk ID is not a valid number: $riskId');
          continue;
        }

        if (safeRiskId <= 0) {
          print('⚠️ Invalid risk ID: $safeRiskId');
          continue;
        }

        if (riskLevel == 'high' || riskLevel == 'critical') {
          final planName = 'خطة وقائية ل${_getRiskTypeArabic(riskType)}';
          final description =
              'خطة وقائية للتعامل مع خطر ${risk['description'] ?? riskType}';

          final actions = [
            {
              'action': 'مراقبة المؤشرات الصحية',
              'frequency': 'يومياً',
              'duration': '30 يوم',
              'priority': 'high',
            },
            {
              'action': 'اتباع التوصيات الطبية',
              'frequency': 'أسبوعياً',
              'duration': '30 يوم',
              'priority': 'high',
            },
            {
              'action': 'تعديل نمط الحياة',
              'frequency': 'يومياً',
              'duration': '30 يوم',
              'priority': 'medium',
            },
          ];

          try {
            await createPreventionPlan(
              riskId: safeRiskId,
              planName: planName,
              description: description,
              actions: actions,
              timelineDays: 30,
              priority: 'high',
            );
            plansCreated++;
          } catch (e) {
            print('⚠️ Failed to create plan for risk $safeRiskId: $e');
          }
        }
      }

      return {
        'success': true,
        'message': 'تم تحليل المخاطر وإنشاء الخطط الوقائية',
        'risks_analyzed': risksAnalyzed,
        'plans_created': plansCreated,
      };
    } catch (e) {
      print('Error analyzing and creating plans: $e');
      return {
        'success': false,
        'message': 'فشل في تحليل المخاطر وإنشاء الخطط: $e',
        'risks_analyzed': 0,
        'plans_created': 0,
      };
    }
  }

  // الحصول على إحصائيات المخاطر
  static Future<Map<String, dynamic>> getRiskStatistics() async {
    try {
      final dashboard = await getPreventionDashboard();

      return {
        'total_risks': dashboard['total_risks'] ?? 0,
        'high_risk_count': dashboard['high_risk_count'] ?? 0,
        'active_plans': dashboard['active_plans'] ?? 0,
        'completed_plans': dashboard['completed_plans'] ?? 0,
        'risk_by_type': dashboard['risk_by_type'] ?? {},
        'risk_by_level': dashboard['risk_by_level'] ?? {},
      };
    } catch (e) {
      print('Error getting risk statistics: $e');
      rethrow;
    }
  }

  // ✅ دالة مساعدة لترجمة نوع الخطر
  static String _getRiskTypeArabic(String riskType) {
    switch (riskType) {
      case 'diabetes':
        return 'مرض السكري';
      case 'hypertension':
        return 'ارتفاع ضغط الدم';
      case 'obesity':
        return 'السمنة';
      case 'heart_disease':
        return 'أمراض القلب';
      case 'inactivity':
        return 'قلة النشاط البدني';
      case 'malnutrition':
        return 'سوء التغذية';
      case 'stress':
        return 'الإجهاد';
      default:
        return riskType;
    }
  }
}
