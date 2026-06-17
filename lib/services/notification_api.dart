// lib/services/notification_api.dart

import 'dart:convert';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';

class NotificationApi {
  static const String _pathPrefix = 'api/notifications';
  static const String _cachePrefix = 'notifications_';

  // ✅ تسجيل إشعار
  static Future<Map<String, dynamic>> logNotification({
    required int userId,
    required String notificationType,
    String? notificationSubtype,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestData = {
        'user_id': userId,
        'notification_type': notificationType,
        'notification_subtype': notificationSubtype,
        'title': title,
        'body': body,
        'scheduled_time': scheduledTime.toIso8601String(),
        'extra_data': metadata,
      };

      final response = await BaseApiService.post(
        '$_pathPrefix/log',
        body: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return {'success': true, 'id': jsonData['id']};
      }
      return {'success': false};
    } catch (e) {
      print('❌ خطأ في تسجيل الإشعار: $e');
      return {'success': false};
    }
  }

  // ✅ تشغيل التذكيرات اليومية
  static Future<Map<String, dynamic>> runDailyReminders() async {
    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/run-daily-reminders',
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false};
    }
  }

  // ✅ جلب إشعارات اليوم
  static Future<Map<String, dynamic>?> getTodayNotifications() async {
    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: '${_cachePrefix}today',
            fetch: () async {
              final response = await BaseApiService.get('$_pathPrefix/today');

              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return null;
            },
            ttl: const Duration(minutes: 2),
            staleWhileRevalidate: true,
          );

      return result;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ✅ تحديث استجابة المستخدم
  static Future<Map<String, dynamic>> updateNotificationAction({
    required int notificationId,
    required String action,
  }) async {
    try {
      final response = await BaseApiService.put(
        '$_pathPrefix/$notificationId/action',
        body: {
          'action_taken': action,
          'action_time': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        // Invalidate today's notifications cache
        CacheManager.instance.invalidate('${_cachePrefix}today');
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false};
    }
  }

  // ✅ تنظيف الإشعارات القديمة
  static Future<Map<String, dynamic>> cleanupOldNotifications({
    int daysOld = 90,
  }) async {
    try {
      final response = await BaseApiService.delete(
        '$_pathPrefix/cleanup?days_old=$daysOld',
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false};
    }
  }

  // ✅ جلب إحصائيات الإشعارات
  static Future<Map<String, dynamic>?> getNotificationStats({
    int daysBack = 30,
  }) async {
    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: '${_cachePrefix}stats_${daysBack}days',
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/stats?days_back=$daysBack',
              );

              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return null;
            },
            ttl: const Duration(minutes: 10),
            staleWhileRevalidate: true,
          );

      return result;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ✅ جلب قائمة الإشعارات الفعلية (للشاشة التي تعرض الإشعارات)
  static Future<Map<String, dynamic>?> getNotificationsList({
    int limit = 50,
    int offset = 0,
    String? notificationType,
  }) async {
    try {
      String url = '$_pathPrefix/list?limit=$limit&offset=$offset';
      if (notificationType != null) {
        url += '&notification_type=$notificationType';
      }

      final response = await BaseApiService.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ خطأ في جلب قائمة الإشعارات: $e');
      return null;
    }
  }
}
