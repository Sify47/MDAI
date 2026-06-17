// lib/services/weight_service.dart

import 'dart:convert';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import 'package:vita/utils/prefs_helper.dart';

class WeightService {
  static const String _pathPrefix = 'api/weight';

  static String _historyCacheKey(int limit, int offset) =>
      'weight_history_${limit}_$offset';
  static String get _latestCacheKey => 'weight_latest';
  static String _progressCacheKey(String period) => 'weight_progress_$period';
  static String _statsCacheKey(int days) => 'weight_stats_$days';
  static String _predictCacheKey(int weeks, String goal) =>
      'weight_predict_${weeks}_$goal';
  static String get _allPattern => 'weight_';

  // ============================================
  // ✅ 1. تسجيل وزن جديد
  // ============================================
  static Future<Map<String, dynamic>> logWeight({
    required double weight,
    required DateTime date,
    String? notes,
  }) async {
    print('📝 [WeightService] تسجيل وزن جديد: $weight كجم في $date');

    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/log',
        body: {
          'weight': weight,
          'date': date.toIso8601String().split('T')[0],
          'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ [WeightService] تم تسجيل الوزن بنجاح');

        // تحديث الوزن في PrefsHelper
        await PrefsHelper.updateWeight(weight);

        // مسح الكاش
        CacheManager.instance.invalidatePattern(_allPattern);

        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': response.body};
    } catch (e) {
      print('❌ [WeightService] خطأ: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // ✅ 2. جلب سجل الوزن التاريخي
  // ============================================
  static Future<List<Map<String, dynamic>>> getWeightHistory({
    int limit = 30,
    int offset = 0,
  }) async {
    print('🔍 [WeightService] جلب سجل الوزن التاريخي');

    try {
      final result = await CacheManager.instance
          .getOrFetch<List<Map<String, dynamic>>>(
            key: _historyCacheKey(limit, offset),
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/history',
                queryParams: {
                  'limit': limit.toString(),
                  'offset': offset.toString(),
                },
              );
              if (response.statusCode == 200) {
                final List<dynamic> data = json.decode(response.body);
                print('✅ [WeightService] تم جلب ${data.length} سجل وزن');
                return data
                    .map((item) => Map<String, dynamic>.from(item))
                    .toList();
              }
              return <Map<String, dynamic>>[];
            },
            ttl: const Duration(minutes: 3),
            persist: false,
          );
      return result ?? <Map<String, dynamic>>[];
    } catch (e) {
      print('❌ [WeightService] خطأ: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 3. جلب آخر وزن مسجل
  // ============================================
  static Future<Map<String, dynamic>> getLatestWeight() async {
    print('🔍 [WeightService] جلب آخر وزن مسجل');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _latestCacheKey,
            fetch: () async {
              final response = await BaseApiService.get('$_pathPrefix/latest');
              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return {'success': false, 'weight': null};
            },
            ttl: const Duration(minutes: 5),
            persist: false,
          );
      return result ?? {'success': false, 'weight': null};
    } catch (e) {
      print('❌ [WeightService] خطأ: $e');
      return {'success': false, 'weight': null};
    }
  }

  // ============================================
  // ✅ 4. حساب تقدم الوزن
  // ============================================
  static Future<Map<String, dynamic>> getWeightProgress({
    required String period, // week, month, 3months, custom
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    print('📊 [WeightService] حساب تقدم الوزن - الفترة: $period');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _progressCacheKey(period),
            fetch: () async {
              final params = <String, String>{'period': period};
              if (period == 'custom' && startDate != null && endDate != null) {
                params['start_date'] = startDate.toIso8601String().split(
                  'T',
                )[0];
                params['end_date'] = endDate.toIso8601String().split('T')[0];
              }

              final response = await BaseApiService.get(
                '$_pathPrefix/progress',
                queryParams: params,
              );
              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return {'success': false, 'need_more_data': true};
            },
            ttl: const Duration(minutes: 5),
            persist: false,
          );
      return result ?? {'success': false, 'need_more_data': true};
    } catch (e) {
      print('❌ [WeightService] خطأ: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // ✅ 5. إحصائيات الوزن
  // ============================================
  static Future<Map<String, dynamic>> getWeightStats({int days = 30}) async {
    print('📊 [WeightService] جلب إحصائيات الوزن لآخر $days يوم');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _statsCacheKey(days),
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/stats',
                queryParams: {'days': days.toString()},
              );
              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return {'success': false};
            },
            ttl: const Duration(minutes: 5),
            persist: false,
          );
      return result ?? {'success': false};
    } catch (e) {
      print('❌ [WeightService] خطأ: $e');
      return {'success': false};
    }
  }

  // ============================================
  // ✅ 6. توقع الوزن
  // ============================================
  static Future<Map<String, dynamic>> predictWeight({
    int weeksAhead = 4,
    String goal = 'تخسيس',
  }) async {
    print(
      '🔮 [WeightService] توقع الوزن بعد $weeksAhead أسابيع (الهدف: $goal)',
    );

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _predictCacheKey(weeksAhead, goal),
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/predict',
                queryParams: {
                  'weeks_ahead': weeksAhead.toString(),
                  'goal': goal,
                },
              );
              if (response.statusCode == 200) {
                return json.decode(response.body) as Map<String, dynamic>;
              }
              return {'success': false};
            },
            ttl: const Duration(minutes: 10),
            persist: false,
          );
      return result ?? {'success': false};
    } catch (e) {
      print('❌ [WeightService] خطأ: $e');
      return {'success': false};
    }
  }

  // ============================================
  // ✅ 7. حذف سجل وزن
  // ============================================
  static Future<Map<String, dynamic>> deleteWeightEntry(int weightId) async {
    print('🗑️ [WeightService] حذف سجل وزن ID: $weightId');

    try {
      final response = await BaseApiService.delete('$_pathPrefix/$weightId');

      if (response.statusCode == 200) {
        // مسح الكاش
        CacheManager.instance.invalidatePattern(_allPattern);
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {'success': false};
    } catch (e) {
      print('❌ [WeightService] خطأ: $e');
      return {'success': false};
    }
  }
}
