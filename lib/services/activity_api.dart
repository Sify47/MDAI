// lib/services/activity_api.dart

import 'dart:convert';
import 'package:vita/utils/prefs_helper.dart';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import '../models/activity_model.dart';

class ActivityService {
  // 🟢 Runtime getter — NOT static final (fixes compile-time evaluation bug!)
  static int get _userId => PrefsHelper.getUserId() ?? 1;

  // ============================================
  // 🏷️ Cache Keys
  // ============================================
  static String _categoriesCacheKey(int uid) => 'activities_categories_$uid';
  static String _todayActivitiesCacheKey(int uid) => 'activities_today_$uid';
  static String _upcomingCacheKey(int uid, int hours) =>
      'activities_upcoming_${uid}_$hours';
  static String _activityByIdCacheKey(int uid, int id) =>
      'activities_${uid}_$id';
  static String _dailyStatsCacheKey(int uid, String? date) =>
      'activities_daily_stats_${uid}_${date ?? 'today'}';
  static String _weeklyStatsCacheKey(int uid) => 'activities_weekly_stats_$uid';
  static String _monthlyStatsCacheKey(int uid, int? year, int? month) =>
      'activities_monthly_stats_${uid}_${year ?? 'all'}_${month ?? 'all'}';

  /// مسح جميع كاش الأنشطة لهذا المستخدم
  static void _invalidateAllActivitiesCache() {
    final uid = _userId;
    CacheManager.instance.invalidatePattern('activities_${uid}_');
    CacheManager.instance.invalidatePattern('activities_categories_');
  }

  // ============================================
  // ✅ 1. جلب فئات الأنشطة
  // ============================================
  static Future<List<ActivityCategory>> getCategories() async {
    print('\n🟡 [ActivityService] جلب فئات الأنشطة');

    try {
      final result = await CacheManager.instance
          .getOrFetch<List<ActivityCategory>>(
            key: _categoriesCacheKey(_userId),
            fetch: () async {
              final response = await BaseApiService.get(
                'api/activities/categories',
              );

              if (response.statusCode == 200) {
                final List<dynamic> jsonData = json.decode(response.body);
                print('✅ تم جلب ${jsonData.length} فئة');
                return jsonData
                    .map((json) => ActivityCategory.fromJson(json))
                    .toList();
              }
              return <ActivityCategory>[];
            },
            ttl: const Duration(minutes: 30), // الفئات نادراً ما تتغير
            staleWhileRevalidate: true,
          );
      return result ?? [];
    } catch (e) {
      print('🔥 خطأ في جلب الفئات: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 2. جلب الأنشطة
  // ============================================
  static Future<List<Activity>> getActivities({
    DateTime? date,
    int? categoryId,
    bool? isCompleted,
    int limit = 50,
    int skip = 0,
  }) async {
    print('\n🟡 [ActivityService] جلب الأنشطة');

    try {
      final uid = _userId;
      final queryParams = <String, String>{
        'user_id': uid.toString(),
        'limit': limit.toString(),
        'skip': skip.toString(),
      };

      if (date != null) {
        queryParams['date'] = '${date.year}-${date.month}-${date.day}';
      }
      if (categoryId != null) {
        queryParams['category_id'] = categoryId.toString();
      }
      if (isCompleted != null) {
        queryParams['is_completed'] = isCompleted.toString();
      }

      final response = await BaseApiService.get(
        'api/activities/',
        queryParams: queryParams,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('✅ تم جلب ${jsonData.length} نشاط');
        return jsonData.map((json) => Activity.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب الأنشطة: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 3. جلب أنشطة اليوم (مخزنة في الكاش)
  // ============================================
  static Future<List<Activity>> getTodayActivities() async {
    print('\n🟡 [ActivityService] جلب أنشطة اليوم');

    try {
      final uid = _userId;
      final result = await CacheManager.instance.getOrFetch<List<Activity>>(
        key: _todayActivitiesCacheKey(uid),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/activities/today',
            queryParams: {'user_id': uid.toString()},
          );

          if (response.statusCode == 200) {
            final List<dynamic> jsonData = json.decode(response.body);
            print('✅ تم جلب ${jsonData.length} نشاط لليوم');
            return jsonData.map((json) => Activity.fromJson(json)).toList();
          }
          return <Activity>[];
        },
        ttl: const Duration(minutes: 2),
        staleWhileRevalidate: true,
      );
      return result ?? [];
    } catch (e) {
      print('🔥 خطأ في جلب أنشطة اليوم: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 4. جلب الأنشطة القادمة
  // ============================================
  static Future<List<Activity>> getUpcomingActivities({int hours = 24}) async {
    print('\n🟡 [ActivityService] جلب الأنشطة القادمة');

    try {
      final uid = _userId;
      final result = await CacheManager.instance.getOrFetch<List<Activity>>(
        key: _upcomingCacheKey(uid, hours),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/activities/upcoming',
            queryParams: {'user_id': uid.toString(), 'hours': hours.toString()},
          );

          if (response.statusCode == 200) {
            final List<dynamic> jsonData = json.decode(response.body);
            print('✅ تم جلب ${jsonData.length} نشاط قادم');
            return jsonData.map((json) => Activity.fromJson(json)).toList();
          }
          return <Activity>[];
        },
        ttl: const Duration(minutes: 5),
        staleWhileRevalidate: true,
      );
      return result ?? [];
    } catch (e) {
      print('🔥 خطأ في جلب الأنشطة القادمة: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 5. جلب نشاط محدد
  // ============================================
  static Future<Activity?> getActivityById(int id) async {
    print('\n🟡 [ActivityService] جلب نشاط $id');

    try {
      final uid = _userId;
      final result = await CacheManager.instance.getOrFetch<Activity>(
        key: _activityByIdCacheKey(uid, id),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/activities/$id',
            queryParams: {'user_id': uid.toString()},
          );

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            return Activity.fromJson(jsonData);
          }
          return null;
        },
        ttl: const Duration(minutes: 5),
        staleWhileRevalidate: true,
      );
      return result;
    } catch (e) {
      print('🔥 خطأ في جلب النشاط: $e');
      return null;
    }
  }

  // ============================================
  // ✅ 6. إضافة نشاط جديد
  // ============================================
  static Future<Map<String, dynamic>> addActivity(
    Map<String, dynamic> data,
  ) async {
    print('\n🟡 [ActivityService] إضافة نشاط جديد');
    print('📦 البيانات: $data');

    try {
      final requestData = {'user_id': _userId, ...data};

      final response = await BaseApiService.post(
        'api/activities/',
        body: requestData,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      print('📄 محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ تم إضافة النشاط بنجاح');
        _invalidateAllActivitiesCache();
        return {
          'success': true,
          'message': 'تم إضافة النشاط بنجاح',
          'data': jsonData,
        };
      } else {
        return {'success': false, 'message': 'فشل في إضافة النشاط'};
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }

  // ============================================
  // ✅ 7. تحديث نشاط
  // ============================================
  static Future<Map<String, dynamic>> updateActivity(
    int id,
    Map<String, dynamic> data,
  ) async {
    print('\n🟡 [ActivityService] تحديث نشاط $id');

    try {
      final response = await BaseApiService.put(
        'api/activities/$id',
        body: {'user_id': _userId, ...data},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _invalidateAllActivitiesCache();
        return {
          'success': true,
          'data': Activity.fromJson(jsonData),
          'message': 'تم تحديث النشاط بنجاح',
        };
      } else {
        return {'success': false, 'message': 'فشل في تحديث النشاط'};
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // ============================================
  // ✅ 8. تحديد نشاط كمكتمل
  // ============================================
  static Future<Map<String, dynamic>> completeActivity(int id) async {
    print('\n🟡 [ActivityService] إكمال نشاط $id');

    try {
      final response = await BaseApiService.patch(
        'api/activities/$id/complete',
        body: {'user_id': _userId},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _invalidateAllActivitiesCache();
        return {
          'success': true,
          'message': jsonData['message'] ?? 'تم إكمال النشاط',
        };
      } else {
        return {'success': false, 'message': 'فشل في إكمال النشاط'};
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // ============================================
  // ✅ 9. حذف نشاط
  // ============================================
  static Future<Map<String, dynamic>> deleteActivity(int id) async {
    print('\n🟡 [ActivityService] حذف نشاط $id');

    try {
      final response = await BaseApiService.delete(
        'api/activities/$id',
        body: {'user_id': _userId},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _invalidateAllActivitiesCache();
        return {
          'success': true,
          'message': jsonData['message'] ?? 'تم حذف النشاط',
        };
      } else {
        return {'success': false, 'message': 'فشل في حذف النشاط'};
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // ============================================
  // ✅ 10. إحصائيات يومية
  // ============================================
  static Future<Map<String, dynamic>> getDailyStats({DateTime? date}) async {
    print('\n🟡 [ActivityService] جلب إحصائيات يومية');

    try {
      final uid = _userId;
      final dateStr = date != null
          ? '${date.year}-${date.month}-${date.day}'
          : null;
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _dailyStatsCacheKey(uid, dateStr),
            fetch: () async {
              final queryParams = <String, String>{'user_id': uid.toString()};
              if (dateStr != null) queryParams['date'] = dateStr;

              final response = await BaseApiService.get(
                'api/activities/stats/daily',
                queryParams: queryParams,
              );

              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return <String, dynamic>{};
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );
      return result ?? {};
    } catch (e) {
      print('🔥 خطأ: $e');
      return {};
    }
  }

  // ============================================
  // ✅ 11. إحصائيات أسبوعية
  // ============================================
  static Future<Map<String, dynamic>> getWeeklyStats() async {
    print('\n🟡 [ActivityService] جلب إحصائيات أسبوعية');

    try {
      final uid = _userId;
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _weeklyStatsCacheKey(uid),
            fetch: () async {
              final response = await BaseApiService.get(
                'api/activities/stats/weekly',
                queryParams: {'user_id': uid.toString()},
              );

              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return <String, dynamic>{};
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );
      return result ?? {};
    } catch (e) {
      print('🔥 خطأ: $e');
      return {};
    }
  }

  // ============================================
  // ✅ 12. إحصائيات شهرية
  // ============================================
  static Future<Map<String, dynamic>> getMonthlyStats({
    int? year,
    int? month,
  }) async {
    print('\n🟡 [ActivityService] جلب إحصائيات شهرية');

    try {
      final uid = _userId;
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _monthlyStatsCacheKey(uid, year, month),
            fetch: () async {
              final queryParams = <String, String>{'user_id': uid.toString()};
              if (year != null) queryParams['year'] = year.toString();
              if (month != null) queryParams['month'] = month.toString();

              final response = await BaseApiService.get(
                'api/activities/stats/monthly',
                queryParams: queryParams,
              );

              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return <String, dynamic>{};
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );
      return result ?? {};
    } catch (e) {
      print('🔥 خطأ: $e');
      return {};
    }
  }

  // ============================================
  // ✅ 13. جلب تمارين النشاط
  // ============================================
  static Future<List<ActivityExercise>> getActivityExercises(
    int activityId,
  ) async {
    print('\n🟡 [ActivityService] جلب تمارين النشاط $activityId');

    try {
      final response = await BaseApiService.get(
        'api/activities/$activityId/exercises',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('✅ تم جلب ${jsonData.length} تمرين');
        return jsonData.map((json) => ActivityExercise.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب التمارين: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 14. إضافة تمرين لنشاط
  // ============================================
  static Future<Map<String, dynamic>> addActivityExercise(
    int activityId,
    Map<String, dynamic> exerciseData,
  ) async {
    print('\n🟡 [ActivityService] إضافة تمرين للنشاط $activityId');

    try {
      final response = await BaseApiService.post(
        'api/activities/$activityId/exercises',
        body: exerciseData,
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        _invalidateAllActivitiesCache();
        return {
          'success': true,
          'message': 'تم إضافة التمرين بنجاح',
          'data': ActivityExercise.fromJson(jsonData),
        };
      } else {
        return {'success': false, 'message': 'فشل في إضافة التمرين'};
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }

  // ============================================
  // ✅ 15. استبدال جميع تمارين النشاط (Bulk Replace)
  // ============================================
  static Future<Map<String, dynamic>> bulkReplaceExercises(
    int activityId,
    List<Map<String, dynamic>> exercises,
  ) async {
    print('\n🟡 [ActivityService] استبدال تمارين النشاط $activityId');

    try {
      final response = await BaseApiService.put(
        'api/activities/$activityId/exercises/bulk',
        body: {'exercises': exercises},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        _invalidateAllActivitiesCache();
        return {
          'success': true,
          'message': 'تم تحديث التمارين بنجاح',
          'data': jsonData
              .map((json) => ActivityExercise.fromJson(json))
              .toList(),
        };
      } else {
        return {'success': false, 'message': 'فشل في تحديث التمارين'};
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }

  // ============================================
  // ✅ 16. تحديث تمرين محدد
  // ============================================
  static Future<Map<String, dynamic>> updateActivityExercise(
    int activityId,
    int exerciseId,
    Map<String, dynamic> exerciseData,
  ) async {
    print('\n🟡 [ActivityService] تحديث تمرين $exerciseId');

    try {
      final response = await BaseApiService.put(
        'api/activities/$activityId/exercises/$exerciseId',
        body: exerciseData,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _invalidateAllActivitiesCache();
        return {
          'success': true,
          'message': 'تم تحديث التمرين بنجاح',
          'data': ActivityExercise.fromJson(jsonData),
        };
      } else {
        return {'success': false, 'message': 'فشل في تحديث التمرين'};
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }

  // ============================================
  // ✅ 17. حذف تمرين من النشاط
  // ============================================
  static Future<Map<String, dynamic>> deleteActivityExercise(
    int activityId,
    int exerciseId,
  ) async {
    print('\n🟡 [ActivityService] حذف تمرين $exerciseId من النشاط $activityId');

    try {
      final response = await BaseApiService.delete(
        'api/activities/$activityId/exercises/$exerciseId',
      );

      if (response.statusCode == 200) {
        _invalidateAllActivitiesCache();
        return {'success': true, 'message': 'تم حذف التمرين بنجاح'};
      } else {
        return {'success': false, 'message': 'فشل في حذف التمرين'};
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }
}
