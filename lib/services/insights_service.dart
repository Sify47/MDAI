// lib/services/insights_service.dart
// 💡 خدمة الرؤى التلقائية - Auto Insights Service

import 'dart:convert';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import 'package:vita/utils/prefs_helper.dart';

class InsightsService {
  static const String _pathPrefix = 'api/insights';

  static int get _userId => PrefsHelper.getUserId() ?? 1;

  // ============================================
  // ✅ الرؤى اليومية
  // ============================================
  static Future<Map<String, dynamic>?> getDailyInsights() async {
    print('\n💡 [InsightsService] جلب الرؤى اليومية');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
        key: 'insights_daily_$_userId',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/daily/$_userId',
          );

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body) as Map<String, dynamic>;
            print('✅ تم جلب الرؤى اليومية بنجاح');
            return jsonData;
          }
          print('❌ فشل جلب الرؤى اليومية: ${response.statusCode}');
          return null;
        },
        ttl: const Duration(minutes: 5),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('❌ خطأ في جلب الرؤى اليومية: $e');
      return null;
    }
  }

  // ============================================
  // ✅ التحليل الأسبوعي
  // ============================================
  static Future<Map<String, dynamic>?> getWeeklyAnalysis() async {
    print('\n💡 [InsightsService] جلب التحليل الأسبوعي');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
        key: 'insights_weekly_$_userId',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/weekly/$_userId',
          );

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body) as Map<String, dynamic>;
            print('✅ تم جلب التحليل الأسبوعي بنجاح');
            return jsonData;
          }
          print('❌ فشل جلب التحليل الأسبوعي: ${response.statusCode}');
          return null;
        },
        ttl: const Duration(minutes: 10),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('❌ خطأ في جلب التحليل الأسبوعي: $e');
      return null;
    }
  }

  // ============================================
  // ✅ الملخص الصحي
  // ============================================
  static Future<Map<String, dynamic>?> getHealthSummary() async {
    print('\n💡 [InsightsService] جلب الملخص الصحي');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
        key: 'insights_summary_$_userId',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/summary/$_userId',
          );

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body) as Map<String, dynamic>;
            print('✅ تم جلب الملخص الصحي بنجاح');
            return jsonData;
          }
          print('❌ فشل جلب الملخص الصحي: ${response.statusCode}');
          return null;
        },
        ttl: const Duration(minutes: 15),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('❌ خطأ في جلب الملخص الصحي: $e');
      return null;
    }
  }

  // ============================================
  // ✅ مسح ذاكرة التخزين المؤقت للرؤى
  // ============================================
  static void clearCache() {
    CacheManager.instance.invalidatePattern('insights_$_userId');
    print('💡 [InsightsService] 🧹 تم مسح ذاكرة التخزين المؤقت');
  }
}
