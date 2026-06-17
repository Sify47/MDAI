// lib/services/water_api.dart

import 'dart:convert';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import 'package:vita/utils/prefs_helper.dart';

class WaterService {
  static const String _pathPrefix = 'api/water';
  static const String _aiPathPrefix = 'api/ai';

  static int get _userId => PrefsHelper.getUserId() ?? 1;

  // Cache keys
  static String get _waterRecKey => 'water_recommendation_$_userId';
  static String get _todayWaterKey => 'water_today_$_userId';
  static String get _statsCacheKey => 'water_stats_$_userId';
  static String get _settingsKey => 'water_settings_$_userId';
  static String _monthlyKey(int year, int month) =>
      'water_monthly_${_userId}_${year}_$month';
  static String get _recommendedKey => 'water_recommended_$_userId';
  static String get _allPattern => 'water_${_userId}_';

  // ============================================
  // ✅ جلب توصية الماء من AI
  // ============================================
  static Future<Map<String, dynamic>?> getWaterRecommendation() async {
    print('\n🟡 [WaterService] جلب توصية الماء من AI');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _waterRecKey,
            fetch: () async {
              final response = await BaseApiService.get(
                '$_aiPathPrefix/water-recommendation/$_userId',
              );

              if (response.statusCode == 200) {
                final jsonData = json.decode(response.body);
                print('✅ تم جلب توصية الماء بنجاح');
                return jsonData as Map<String, dynamic>;
              }
              return null;
            },
            ttl: const Duration(hours: 1),
            persist: true,
          );
      return result;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ تسجيل شرب ماء
  // ============================================
  static Future<Map<String, dynamic>> logWater(
    double amount, {
    String? notes,
  }) async {
    print('\n🟡 [WaterService] تسجيل شرب ماء: $amount لتر');

    try {
      final requestData = {
        'amount': amount,
        'time': DateTime.now().toIso8601String(),
        'notes': notes,
      };

      final response = await BaseApiService.post(
        '$_pathPrefix/log?user_id=$_userId',
        body: requestData,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ تم تسجيل شرب الماء بنجاح');

        // مسح الكاش المتعلق بالماء بالكامل (بما في ذلك today key)
        CacheManager.instance.invalidatePattern(_allPattern);
        CacheManager.instance.invalidate(_todayWaterKey);

        return {'success': true, 'data': jsonData};
      }
      return {'success': false, 'message': 'فشل في تسجيل شرب الماء'};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }

  // ============================================
  // ✅ جلب سجل الماء لليوم
  // ============================================
  static Future<Map<String, dynamic>?> getTodayWater() async {
    print('\n🟡 [WaterService] جلب سجل الماء لليوم');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _todayWaterKey,
            fetch: () async {
              // ✅ جلب التوصية من AI أولاً
              final recommendation = await getWaterRecommendation();

              final response = await BaseApiService.get(
                '$_pathPrefix/today/$_userId',
              );

              print('📥 حالة الاستجابة: ${response.statusCode}');

              if (response.statusCode == 200) {
                final jsonData = json.decode(response.body);

                // ✅ تحديث الهدف بناءً على توصية AI
                if (recommendation != null &&
                    recommendation['success'] == true) {
                  jsonData['daily_goal'] = recommendation['recommended_water'];
                  jsonData['recommendation_reason'] = recommendation['reason'];
                }

                print('✅ تم جلب سجل الماء بنجاح');
                print('📊 الإجمالي: ${jsonData['total']} لتر');
                print('📊 الهدف (AI): ${jsonData['daily_goal']} لتر');
                return jsonData as Map<String, dynamic>;
              }
              return null;
            },
            ttl: const Duration(minutes: 2),
            staleWhileRevalidate: true,
            persist: false,
          );
      return result;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ✅ جلب تاريخ شرب الماء لفترة محددة
  static Future<List<Map<String, dynamic>>> getWaterHistory({
    int days = 30,
  }) async {
    print('💧 [WaterService] جلب تاريخ شرب الماء لآخر $days أيام');

    try {
      final stats = await getWaterStats('month');
      if (stats != null && stats['stats'] != null) {
        final List<dynamic> statsList = stats['stats'];
        return statsList
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  static Future<double> getTodayWaterAmount() async {
    final data = await getTodayWater();
    if (data != null) {
      return (data['total'] ?? 0.0).toDouble();
    }
    return 0.0;
  }

  // ============================================
  // ✅ جلب إحصائيات الماء (أسبوعي/شهري/سنوي)
  // ============================================
  static Future<Map<String, dynamic>?> getWaterStats(String period) async {
    print('\n🟡 [WaterService] جلب إحصائيات الماء: $period');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: '${_statsCacheKey}_$period',
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/stats/$_userId',
                queryParams: {'period': period},
              );

              print('📥 حالة الاستجابة: ${response.statusCode}');

              if (response.statusCode == 200) {
                final jsonData = json.decode(response.body);
                print('✅ تم جلب الإحصائيات بنجاح');
                return jsonData as Map<String, dynamic>;
              }
              return null;
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
            persist: false,
          );
      return result;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ تحديث إعدادات شرب الماء
  // ============================================
  static Future<Map<String, dynamic>> updateWaterSettings({
    double? dailyGoal,
    int? reminderInterval,
    String? reminderStart,
    String? reminderEnd,
    bool? enableNotifications,
    double? cupSize,
  }) async {
    print('\n🟡 [WaterService] تحديث إعدادات شرب الماء');

    try {
      final requestData = <String, dynamic>{};
      if (dailyGoal != null) requestData['daily_goal'] = dailyGoal;
      if (reminderInterval != null)
        requestData['reminder_interval'] = reminderInterval;
      if (reminderStart != null) requestData['reminder_start'] = reminderStart;
      if (reminderEnd != null) requestData['reminder_end'] = reminderEnd;
      if (enableNotifications != null)
        requestData['enable_notifications'] = enableNotifications;
      if (cupSize != null) requestData['cup_size'] = cupSize;

      final response = await BaseApiService.put(
        '$_pathPrefix/settings/$_userId',
        body: requestData,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ تم تحديث الإعدادات بنجاح');

        // مسح الكاش
        CacheManager.instance.invalidatePattern(_allPattern);

        return {'success': true, 'message': jsonData['message']};
      }
      return {'success': false, 'message': 'فشل في تحديث الإعدادات'};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }

  // ============================================
  // ✅ حذف تسجيل ماء
  // ============================================
  static Future<Map<String, dynamic>> deleteWaterIntake(int intakeId) async {
    print('\n🟡 [WaterService] حذف تسجيل ماء: $intakeId');

    try {
      final response = await BaseApiService.delete('$_pathPrefix/$intakeId');

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ تم حذف التسجيل بنجاح');

        // مسح الكاش
        CacheManager.instance.invalidatePattern(_allPattern);

        return {'success': true, 'message': jsonData['message']};
      }
      return {'success': false, 'message': 'فشل في حذف التسجيل'};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }

  // ============================================
  // ✅ جلب إعدادات شرب الماء الحالية
  // ============================================
  static Future<Map<String, dynamic>?> getWaterSettings() async {
    print('\n🟡 [WaterService] جلب إعدادات شرب الماء');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _settingsKey,
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/settings/$_userId',
              );

              print('📥 حالة الاستجابة: ${response.statusCode}');

              if (response.statusCode == 200) {
                final jsonData = json.decode(response.body);
                print('✅ تم جلب الإعدادات بنجاح');
                return jsonData as Map<String, dynamic>;
              }
              return null;
            },
            ttl: const Duration(minutes: 10),
            staleWhileRevalidate: true,
            persist: true,
          );
      return result;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ جلب سجل الماء لشهر كامل
  // ============================================
  static Future<List<Map<String, dynamic>>?> getMonthlyWaterLog(
    int year,
    int month,
  ) async {
    print('\n🟡 [WaterService] جلب سجل الماء لشهر $month/$year');

    try {
      final result = await CacheManager.instance
          .getOrFetch<List<Map<String, dynamic>>>(
            key: _monthlyKey(year, month),
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/monthly/$_userId',
                queryParams: {
                  'year': year.toString(),
                  'month': month.toString(),
                },
              );

              print('📥 حالة الاستجابة: ${response.statusCode}');

              if (response.statusCode == 200) {
                final jsonData = json.decode(response.body);
                print('✅ تم جلب السجل الشهري بنجاح');
                return List<Map<String, dynamic>>.from(jsonData['data']);
              }
              return null;
            },
            ttl: const Duration(minutes: 10),
            staleWhileRevalidate: true,
            persist: false,
          );
      return result;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ حساب كمية الماء الموصى بها
  // ============================================
  static Future<Map<String, dynamic>?> getRecommendedWaterIntake() async {
    print('\n🟡 [WaterService] حساب كمية الماء الموصى بها');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _recommendedKey,
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/recommended/$_userId',
              );

              print('📥 حالة الاستجابة: ${response.statusCode}');

              if (response.statusCode == 200) {
                final jsonData = json.decode(response.body);
                print('✅ تم حساب الكمية الموصى بها بنجاح');
                return jsonData as Map<String, dynamic>;
              }
              return null;
            },
            ttl: const Duration(hours: 6),
            staleWhileRevalidate: true,
            persist: true,
          );
      return result;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ إضافة تذكير ماء مخصص
  // ============================================
  static Future<Map<String, dynamic>> addCustomReminder({
    required String time,
    required String label,
    required bool isActive,
  }) async {
    print('\n🟡 [WaterService] إضافة تذكير ماء مخصص');

    try {
      final requestData = {'time': time, 'label': label, 'is_active': isActive};

      final response = await BaseApiService.post(
        '$_pathPrefix/reminders/$_userId',
        body: requestData,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ تم إضافة التذكير بنجاح');

        // مسح الكاش
        CacheManager.instance.invalidatePattern(_allPattern);

        return {'success': true, 'data': jsonData};
      }
      return {'success': false, 'message': 'فشل في إضافة التذكير'};
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }
}
