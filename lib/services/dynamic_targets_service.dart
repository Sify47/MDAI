// lib/services/dynamic_targets_service.dart

import 'dart:convert';
import 'package:vita/utils/prefs_helper.dart';
import '../models/dynamic_target_model.dart';
import '../services/base_api_service.dart';

class DynamicTargetsService {
  static const String _pathPrefix = 'api/dynamic-targets';
  static int get _userId => PrefsHelper.getUserId() ?? 0;

  // ============================================
  // ✅ 1. جلب أهداف اليوم
  // ============================================
  static Future<Map<String, dynamic>> getTodayTargets() async {
    print('📤 [DynamicTargets] جلب أهداف اليوم');
    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/today?user_id=$_userId',
      );
      print('📥 حالة: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': DynamicDailyTarget.fromJson(data)};
      }
      if (response.statusCode == 404) {
        return {'success': false, 'message': 'لا توجد أهداف لليوم'};
      }
      return {'success': false, 'message': response.body};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ 2. جلب أهداف تاريخ معين
  // ============================================
  static Future<Map<String, dynamic>> getTargetsByDate(String date) async {
    print('📤 [DynamicTargets] جلب أهداف تاريخ: $date');
    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/date/$date?user_id=$_userId',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': DynamicDailyTarget.fromJson(data)};
      }
      if (response.statusCode == 404) {
        return {'success': false, 'message': 'لا توجد أهداف لهذا التاريخ'};
      }
      return {'success': false, 'message': response.body};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ 3. جلب تفاصيل حساب الأهداف
  // ============================================
  static Future<Map<String, dynamic>> getTargetBreakdown() async {
    print('📤 [DynamicTargets] جلب تفاصيل حساب الأهداف');
    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/breakdown?user_id=$_userId',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final breakdowns = data
              .map((e) => DynamicTargetBreakdown.fromJson(e))
              .toList();
          return {'success': true, 'data': breakdowns};
        }
        return {'success': false, 'message': 'تنسيق استجابة غير متوقع'};
      }
      return {'success': false, 'message': response.body};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ 4. جلب تاريخ الأهداف
  // ============================================
  static Future<Map<String, dynamic>> getTargetHistory({int days = 7}) async {
    print('📤 [DynamicTargets] جلب تاريخ الأهداف ($days أيام)');
    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/history?user_id=$_userId&days=$days',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': DynamicTargetHistory.fromJson(data)};
      }
      return {'success': false, 'message': 'لا توجد بيانات تاريخية'};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ 5. مقارنة الأهداف الديناميكية مع الثابتة
  // ============================================
  static Future<Map<String, dynamic>> getTargetComparison() async {
    print('📤 [DynamicTargets] مقارنة الأهداف');
    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/comparison?user_id=$_userId',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': DynamicTargetComparison.fromJson(data),
        };
      }
      if (response.statusCode == 404) {
        return {'success': false, 'message': 'لا توجد بيانات للمقارنة'};
      }
      return {'success': false, 'message': response.body};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ 6. جلب أداء اليوم
  // ============================================
  static Future<Map<String, dynamic>> getTodayPerformance() async {
    print('📤 [DynamicTargets] جلب أداء اليوم');
    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/performance/today?user_id=$_userId',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['overall_score'] != null) {
          return {'success': true, 'data': PerformanceHistory.fromJson(data)};
        }
        return {'success': false, 'message': 'لا توجد بيانات أداء لليوم'};
      }
      return {'success': false, 'message': response.body};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ 7. جلب أداء تاريخ معين
  // ============================================
  static Future<Map<String, dynamic>> getPerformanceByDate(String date) async {
    print('📤 [DynamicTargets] جلب أداء تاريخ: $date');
    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/performance/$date?user_id=$_userId',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': PerformanceHistory.fromJson(data)};
      }
      return {'success': false, 'message': 'لا توجد بيانات أداء لهذا التاريخ'};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ 8. جلب ملخص الأداء
  // ============================================
  static Future<Map<String, dynamic>> getPerformanceSummary({
    int days = 7,
  }) async {
    print('📤 [DynamicTargets] جلب ملخص الأداء ($days أيام)');
    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/performance/summary?user_id=$_userId&days=$days',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': PerformanceSummary.fromJson(data)};
      }
      return {'success': false, 'message': 'لا توجد بيانات ملخص'};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ 9. جلب الإنجازات
  // ============================================
  static Future<Map<String, dynamic>> getAchievements() async {
    print('📤 [DynamicTargets] جلب الإنجازات');
    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/achievements?user_id=$_userId',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': AchievementStats.fromJson(data)};
      }
      return {'success': false, 'message': 'لا توجد إنجازات'};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ 10. إعادة حساب الأهداف
  // ============================================
  static Future<Map<String, dynamic>> recalculateTargets() async {
    print('📤 [DynamicTargets] إعادة حساب الأهداف');
    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/recalculate?user_id=$_userId',
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'تم إعادة الحساب بنجاح',
        };
      }
      return {'success': false, 'message': response.body};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ دوال مساعدة للواجهة
  // ============================================

  /// حساب نسبة التقدم نحو الهدف
  static double calculateProgress(double current, double target) {
    if (target <= 0) return 0;
    return (current / target).clamp(0.0, 1.0);
  }

  /// الحصول على لون حسب النسبة المئوية
  static int getProgressColor(double percentage) {
    if (percentage >= 1.0) return 0xFF4CAF50;
    if (percentage >= 0.75) return 0xFF8BC34A;
    if (percentage >= 0.5) return 0xFFFFC107;
    if (percentage >= 0.25) return 0xFFFF9800;
    return 0xFFF44336;
  }

  /// الحصول على نص وصف الأداء
  static String getPerformanceDescription(double score) {
    if (score >= 90) return 'ممتاز 🌟';
    if (score >= 75) return 'جيد جداً 👍';
    if (score >= 60) return 'جيد 💪';
    if (score >= 40) return 'متوسط 📈';
    return 'بحاجة للتحسين 📊';
  }

  /// الحصول على أيقونة الإنجاز حسب النوع
  static String getMilestoneIcon(String type) {
    switch (type) {
      case 'streak':
        return '🔥';
      case 'adherence':
        return '💪';
      case 'calories':
        return '🎯';
      case 'steps':
        return '👣';
      case 'water':
        return '💧';
      case 'medication':
        return '💊';
      default:
        return '🏆';
    }
  }
}
