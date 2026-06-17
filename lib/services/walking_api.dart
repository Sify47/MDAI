// lib/services/walking_api.dart
// 🚀 مُعاد كتابتها باستخدام BaseApiService + CacheManager لتقليل استدعاءات API

import 'dart:convert';
import 'package:vita/utils/prefs_helper.dart';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import '../models/walking_model.dart';

class WalkingService {
  // ✅ لم نعد بحاجة إلى baseUrl مكرر - نستخدم BaseApiService

  // ============================================
  // 🏗️ مفاتيح الكاش
  // ============================================
  static String _impactCacheKey(int uid) => 'walking_impact_$uid';
  static String _allActivitiesCacheKey() => 'walking_all_activities';
  static String _todayActivitiesCacheKey() => 'walking_today_activities';
  static String _weekActivitiesCacheKey() => 'walking_week_activities';
  static String _statsCacheKey() => 'walking_stats';

  /// إبطال كل كاش المشي
  static void _invalidateAllWalkingCache() {
    CacheManager.instance.invalidatePattern('walking_');
  }

  // ============================================
  // ✅ حساب تأثير الأعراض والأدوية على المشي
  // ============================================
  static Future<Map<String, dynamic>> calculateWalkingImpact() async {
    print('\n🟡 [WalkingService] حساب تأثير الأعراض والأدوية');

    try {
      final userId = PrefsHelper.getUserId();
      if (userId == null) {
        print('❌ [WalkingService] no user id');
        return {
          'success': false,
          'base_goal': 8000,
          'adjusted_goal': 8000,
          'total_impact_percentage': 0,
          'impact_details': [],
        };
      }

      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _impactCacheKey(userId),
            fetch: () async {
              final response = await BaseApiService.get(
                'walking/calculate-impact',
                queryParams: {'user_id': userId},
              );

              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return null;
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );

      if (result != null) {
        print('✅ تم حساب التأثير بنجاح');
        print('📊 الهدف الأساسي: ${result['base_goal']}');
        print('📊 الهدف المعدل: ${result['adjusted_goal']}');
        print('📊 نسبة التأثير: ${result['total_impact_percentage']}%');
        return result;
      }

      return {
        'success': false,
        'base_goal': 8000,
        'adjusted_goal': 8000,
        'total_impact_percentage': 0,
        'impact_details': [],
      };
    } catch (e) {
      print('❌ خطأ: $e');
      return {
        'success': false,
        'base_goal': 8000,
        'adjusted_goal': 8000,
        'total_impact_percentage': 0,
        'impact_details': [],
      };
    }
  }

  // ============================================
  // GET /walking - جلب كل الأنشطة
  // ============================================
  static Future<List<WalkingActivity>> getAllActivities() async {
    try {
      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: _allActivitiesCacheKey(),
        fetch: () async {
          final response = await BaseApiService.get('walking/');
          if (response.statusCode == 200) {
            return json.decode(response.body) as List<dynamic>;
          }
          return <dynamic>[];
        },
        ttl: const Duration(minutes: 3),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        return result.map((json) => WalkingActivity.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب الأنشطة: $e');
      return [];
    }
  }

  // ============================================
  // GET /walking/today - جلب أنشطة اليوم
  // ============================================
  static Future<List<WalkingActivity>> getTodayActivities({bool forceRefresh = false}) async {
    try {
      final localDate = DateTime.now().toIso8601String().split('T')[0];

      // ✅ إذا كان forceRefresh مفعّلاً، أبطِل الكاش أولاً لضمان جلب بيانات جديدة
      if (forceRefresh) {
        CacheManager.instance.invalidate(_todayActivitiesCacheKey());
      }

      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: _todayActivitiesCacheKey(),
        fetch: () async {
          final response = await BaseApiService.get(
            'walking/today',
            queryParams: {'date_str': localDate},
          );
          if (response.statusCode == 200) {
            return json.decode(response.body) as List<dynamic>;
          }
          return <dynamic>[];
        },
        ttl: const Duration(minutes: 2),
        staleWhileRevalidate: !forceRefresh,
      );

      if (result != null) {
        return result.map((json) => WalkingActivity.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب أنشطة اليوم: $e');
      return [];
    }
  }

  // ============================================
  // GET /walking/week - جلب أنشطة الأسبوع
  // ============================================
  static Future<List<WalkingActivity>> getWeekActivities() async {
    try {
      final localDate = DateTime.now().toIso8601String().split('T')[0];

      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: _weekActivitiesCacheKey(),
        fetch: () async {
          final response = await BaseApiService.get(
            'walking/week',
            queryParams: {'date_str': localDate},
          );
          if (response.statusCode == 200) {
            return json.decode(response.body) as List<dynamic>;
          }
          return <dynamic>[];
        },
        ttl: const Duration(minutes: 5),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        return result.map((json) => WalkingActivity.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب أنشطة الأسبوع: $e');
      return [];
    }
  }

  // ============================================
  // GET /walking/stats - إحصائيات المشي
  // ============================================
  static Future<WalkingStats?> getWalkingStats() async {
    try {
      final localDate = DateTime.now().toIso8601String().split('T')[0];

      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _statsCacheKey(),
            fetch: () async {
              final response = await BaseApiService.get(
                'walking/stats',
                queryParams: {'date_str': localDate},
              );
              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return null;
            },
            ttl: const Duration(minutes: 3),
            staleWhileRevalidate: true,
          );

      if (result != null) {
        return WalkingStats.fromJson(result);
      }
      return null;
    } catch (e) {
      print('🔥 خطأ في جلب الإحصائيات: $e');
      return null;
    }
  }

  // ============================================
  // POST /walking - إضافة نشاط جديد
  // ============================================
  static Future<WalkingActivity?> addActivity(
    Map<String, dynamic> activityData,
  ) async {
    try {
      final userId = PrefsHelper.getUserId();
      if (userId == null) {
        print('❌ لا يوجد مستخدم مسجل');
        return null;
      }

      // ✅ تحويل التاريخ إلى الصيغة الصحيحة (YYYY-MM-DD فقط)
      String formattedDate;
      if (activityData['activity_date'] is DateTime) {
        formattedDate = (activityData['activity_date'] as DateTime)
            .toIso8601String()
            .split('T')[0];
      } else if (activityData['activity_date'] is String) {
        final dateStr = activityData['activity_date'] as String;
        formattedDate = dateStr.split('T')[0];
      } else {
        formattedDate = DateTime.now().toIso8601String().split('T')[0];
      }

      final requestData = {
        'user_id': userId,
        'steps': activityData['steps'] ?? 0,
        'distance_km': activityData['distance_km'] ?? 0,
        'duration_minutes': activityData['duration_minutes'] ?? 0,
        'calories_burned': activityData['calories_burned'] ?? 0,
        'activity_date': formattedDate,
        'activity_time': activityData['activity_time'] ?? '00:00',
        'notes': activityData['notes'] ?? '',
        'activity_type': activityData['activity_type'] ?? 'walking',
      };

      print('📤 [WalkingService] إرسال طلب');
      print('📦 [WalkingService] البيانات: $requestData');

      final response = await BaseApiService.post('walking/', body: requestData);

      print('📥 [WalkingService] حالة إضافة النشاط: ${response.statusCode}');
      print('📄 [WalkingService] الاستجابة: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // ✅ إبطال الكاش لأن البيانات تغيرت
        _invalidateAllWalkingCache();

        final jsonData = json.decode(response.body);
        return WalkingActivity.fromJson(jsonData);
      }
      return null;
    } catch (e) {
      print('🔥 خطأ في إضافة النشاط: $e');
      return null;
    }
  }

  // ============================================
  // DELETE /walking/{id} - حذف نشاط
  // ============================================
  static Future<bool> deleteActivity(int id) async {
    try {
      final response = await BaseApiService.delete('walking/$id');

      if (response.statusCode == 200) {
        _invalidateAllWalkingCache();
        return true;
      }
      return false;
    } catch (e) {
      print('🔥 خطأ في حذف النشاط: $e');
      return false;
    }
  }

  // ============================================
  // GET /walking/activities - جلب أنشطة لفترة
  // ============================================
  static Future<List<WalkingActivity>> getActivitiesForPeriod(int days) async {
    print('🔍 [WalkingService] جلب أنشطة المشي لآخر $days أيام');

    try {
      final allActivities = await getAllActivities();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      return allActivities.where((activity) {
        return activity.activityDate.isAfter(cutoffDate);
      }).toList();
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }
}
