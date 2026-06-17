// lib/services/nutrition_api.dart
// 🚀 مُعاد كتابتها باستخدام BaseApiService + CacheManager لتقليل استدعاءات API

import 'dart:convert';
import 'package:vita/models/weight_history_model.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import '../models/nutrition_model.dart';

class NutritionService {
  // ✅ لم نعد بحاجة إلى baseUrl مكرر - نستخدم BaseApiService.getFullUrl()

  static int userId = PrefsHelper.getUserId() ?? 1;

  /// ✅ دالة لتحديث userId وإبطال الكاش القديم
  static void setUserId(int id) {
    if (userId != id) {
      CacheManager.instance.invalidateUser(userId);
      userId = id;
    }
  }

  /// 🏗️ مفتاح الكاش لبيانات المستخدم الغذائية
  static String _nutritionCacheKey(int uid) => 'nutrition_userdata_$uid';

  /// 🏗️ مفتاح الكاش لوجبات اليوم
  static String _todayMealsCacheKey(int uid) => 'nutrition_todaymeals_$uid';

  /// 🏗️ مفتاح الكاش لسجل الوزن
  static String _weightHistoryCacheKey(int uid) => 'nutrition_weighthistory_$uid';

  /// 🏗️ مفتاح الكاش لتحليل اليوم
  static String _dailyAnalysisCacheKey(int uid) => 'nutrition_dailyanalysis_$uid';

  // ============================================
  // ✅ 1. حفظ بيانات المستخدم الغذائية (معدلة)
  // ============================================

  static Future<Map<String, dynamic>> saveUserNutritionData(
    Map<String, dynamic> data,
  ) async {
    print('📤 [NutritionApi] حفظ بيانات المستخدم الغذائية');

    final Map<String, dynamic> requestData = {
      'user_id': data['user_id'] ?? PrefsHelper.getUserId() ?? 1,
      'weight': (data['weight'] ?? 0).toDouble(),
      'height': (data['height'] ?? 0).toDouble(),
      'age': data['age']?.toInt() ?? 0,
      'gender': data['gender'] ?? 'ذكر',
      'goal': data['goal'] ?? 'تخسيس',
      'activity_level': data['activity_level'] ?? 'متوسط',
      'weight_loss_rate': (data['weight_loss_rate'] ?? 0.5).toDouble(),
      'target_weight': (data['target_weight'] ?? data['weight'] ?? 0).toDouble(),
      'diseases': data['diseases'] ?? [],
      'initial_weight': (data['initial_weight'] ?? data['weight'] ?? 0).toDouble(),
      'target_weeks': data['target_weeks']?.toInt() ?? 8,
    };

    print('📦 البيانات: $requestData');

    try {
      final response = await BaseApiService.post(
        'api/nutrition/user-data',
        body: requestData,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ إبطال الكاش لأن البيانات تغيرت
        CacheManager.instance.invalidateNutrition();
        CacheManager.instance.invalidate(_nutritionCacheKey(userId));

        final decoded = json.decode(response.body);
        return {'success': true, 'data': decoded};
      } else if (response.statusCode == 422) {
        print('❌ خطأ في التحقق من البيانات (422)');
        print('📄 التفاصيل: ${response.body}');
        return {
          'success': false,
          'message': 'بيانات غير صالحة: ${response.body}',
        };
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ============================================
  // ✅ 2. جلب بيانات المستخدم الغذائية (مع Cache)
  // ============================================

  static Future<UserNutritionData?> getUserNutritionData() async {
    print('\n🟡 [NutritionService] جلب بيانات المستخدم');

    try {
      final result = await CacheManager.instance.getOrFetch<Map<String, dynamic>>(
        key: _nutritionCacheKey(userId),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/nutrition/user-data',
            queryParams: {'user_id': userId},
          );
          if (response.statusCode == 200) {
            return json.decode(response.body) as Map<String, dynamic>;
          } else if (response.statusCode == 404) {
            return null;
          }
          throw Exception('${response.statusCode}');
        },
        ttl: const Duration(minutes: 5),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        print('✅ تم جلب البيانات (من cache أو API)');
        return UserNutritionData.fromJson(result);
      }

      print('⚠️ لا توجد بيانات للمستخدم');
      return null;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ 2.5 جلب سجل الوزن التاريخي (مع Cache)
  // ============================================

  static Future<List<WeightHistory>> getWeightHistory() async {
    print('\n🟡 [NutritionService] جلب سجل الوزن التاريخي');

    try {
      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: _weightHistoryCacheKey(userId),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/nutrition/weight-history',
            queryParams: {'user_id': userId},
          );

          if (response.statusCode == 200) {
            return json.decode(response.body) as List<dynamic>;
          } else if (response.statusCode == 404) {
            return <dynamic>[];
          }
          throw Exception('${response.statusCode}');
        },
        ttl: const Duration(minutes: 3),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        List<WeightHistory> history = [];
        for (var item in result) {
          try {
            history.add(WeightHistory.fromJson(item));
          } catch (e) {
            print('⚠️ فشل تحويل سجل وزن: $e');
          }
        }
        print('✅ تم جلب ${history.length} سجل وزن');
        return history;
      }

      print('⚠️ لا توجد بيانات وزن للمستخدم');
      return [];
    } catch (e) {
      print('❌ خطأ في getWeightHistory: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 3. جلب قائمة الأطعمة (مع Cache)
  // ============================================

  static Future<List<Food>> getFoods({
    String? category,
    String? search,
    String? suitableFor,
    bool recommendedOnly = false,
  }) async {
    print('\n🟡 [NutritionService] جلب الأطعمة');

    try {
      final params = <String, dynamic>{};
      if (category != null) params['category'] = category;
      if (search != null) params['search'] = search;
      if (suitableFor != null) params['suitable_for'] = suitableFor;
      if (recommendedOnly) params['recommended_only'] = 'true';

      final cacheKey = 'nutrition_foods_${params.toString()}';

      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: cacheKey,
        fetch: () async {
          final response = await BaseApiService.get(
            'api/nutrition/foods',
            queryParams: params.isNotEmpty ? params : null,
          );

          if (response.statusCode == 200) {
            return json.decode(response.body) as List<dynamic>;
          }
          return <dynamic>[];
        },
        ttl: const Duration(minutes: 10),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        print('✅ تم جلب ${result.length} طعام');
        return result.map((json) => Food.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 4. إضافة وجبة (بدون Cache - تكتب البيانات)
  // ============================================

  static Future<Map<String, dynamic>> addMeal(Map<String, dynamic> data) async {
    print('\n🟡 [NutritionService] إضافة وجبة');
    print('📦 البيانات المرسلة: $data');

    try {
      final response = await BaseApiService.post(
        'api/nutrition/meals',
        body: {'user_id': userId, ...data},
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // ✅ إبطال كاش الوجبات لأنها تغيرت
        CacheManager.instance.invalidate(_todayMealsCacheKey(userId));

        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'تم إضافة الوجبة بنجاح',
          'data': responseData,
        };
      }

      String errorMessage = 'فشل في إضافة الوجبة';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['detail'] ?? errorMessage;
      } catch (_) {}

      return {
        'success': false,
        'message': errorMessage,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // ============================================
  // ✅ 5. جلب وجبات اليوم (مع Cache)
  // ============================================

  static Future<Map<String, dynamic>?> getTodayMeals() async {
    print('\n🟡 [NutritionService] جلب وجبات اليوم');

    try {
      final result = await CacheManager.instance.getOrFetch<Map<String, dynamic>>(
        key: _todayMealsCacheKey(userId),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/nutrition/meals/today',
            queryParams: {'user_id': userId},
          );

          if (response.statusCode == 200) {
            return json.decode(response.body) as Map<String, dynamic>;
          }
          return null;
        },
        ttl: const Duration(minutes: 2),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        print('✅ تم جلب الوجبات بنجاح');
        print('📊 إجمالي السعرات: ${result['total_calories']}');
        return result;
      }
      return null;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ 6. جلب وجبات تاريخ معين (مع Cache)
  // ============================================

  static Future<Map<String, dynamic>?> getMealsByDate(DateTime date) async {
    print('\n🟡 [NutritionService] جلب وجبات التاريخ');

    try {
      final dateStr = '${date.year}-${date.month}-${date.day}';
      final cacheKey = 'nutrition_meals_date_${dateStr}_$userId';

      final result = await CacheManager.instance.getOrFetch<Map<String, dynamic>>(
        key: cacheKey,
        fetch: () async {
          final response = await BaseApiService.get(
            'api/nutrition/meals/date',
            queryParams: {'user_id': userId, 'date': dateStr},
          );

          if (response.statusCode == 200) {
            return json.decode(response.body) as Map<String, dynamic>;
          } else if (response.statusCode == 404) {
            return null;
          }
          throw Exception('${response.statusCode}');
        },
        ttl: const Duration(minutes: 5),
        staleWhileRevalidate: false,
      );

      if (result != null) {
        print('✅ تم جلب الوجبات بنجاح');
        print('📊 عدد الوجبات: ${result['meals_count']}');
        return result;
      }
      print('⚠️ لا توجد وجبات لهذا التاريخ');
      return null;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ 7. جلب اقتراحات الوجبات (مع Cache)
  // ============================================

  static Future<List<MealSuggestion>> getMealSuggestions({
    required String goal,
    List<String>? diseases,
    String? mealType,
    bool timeAware = true,
  }) async {
    print('\n🟡 [NutritionService] جلب اقتراحات الوجبات');
    print('📌 الهدف: $goal');

    try {
      final params = <String, dynamic>{'goal': goal};
      if (diseases != null && diseases.isNotEmpty) {
        params['suitable_for'] = diseases.join(',');
      }
      if (mealType != null) {
        params['meal_type'] = mealType;
      }
      if (timeAware) {
        final now = DateTime.now();
        params['current_time'] =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final userId = PrefsHelper.getUserId();
        if (userId != null) {
          params['user_id'] = userId;
        }
      }

      final cacheKey = 'nutrition_suggestions_${params.toString()}';

      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: cacheKey,
        fetch: () async {
          final response = await BaseApiService.get(
            'api/nutrition/meal-suggestions',
            queryParams: params,
          );

          if (response.statusCode == 200) {
            final dynamic responseData = json.decode(response.body);
            if (responseData is List<dynamic>) {
              return responseData;
            } else if (responseData is Map<String, dynamic>) {
              if (responseData.containsKey('suggestions') &&
                  responseData['suggestions'] is List) {
                return responseData['suggestions'] as List<dynamic>;
              }
              return [responseData];
            }
          }
          return <dynamic>[];
        },
        ttl: const Duration(minutes: 15),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        List<MealSuggestion> suggestions = [];
        for (var item in result) {
          try {
            if (item is Map<String, dynamic>) {
              suggestions.add(MealSuggestion.fromJson(item));
            }
          } catch (e) {
            print('⚠️ فشل تحويل عنصر: $e');
          }
        }
        print('✅ تم تحويل ${suggestions.length} وجبة بنجاح');
        return suggestions;
      }

      print('⚠️ لا توجد اقتراحات');
      return [];
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 8. تسجيل شرب الماء (بدون Cache - تكتب البيانات)
  // ============================================

  static Future<Map<String, dynamic>> logWater(double amount) async {
    print('\n🟡 [NutritionService] تسجيل شرب الماء');

    try {
      final response = await BaseApiService.post(
        'api/nutrition/water',
        body: {
          'user_id': userId,
          'amount': amount,
          'date': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'تم تسجيل شرب الماء'};
      }
      return {'success': false, 'message': 'فشل في التسجيل'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // ============================================
  // ✅ 9. حذف وجبة (بدون Cache - تعديل بيانات)
  // ============================================

  static Future<Map<String, dynamic>> deleteMeal(int mealId) async {
    print('\n🟡 [NutritionService] حذف وجبة');

    try {
      final response = await BaseApiService.delete(
        'api/nutrition/meals/$mealId',
      );

      if (response.statusCode == 200) {
        // ✅ إبطال كاش الوجبات
        CacheManager.instance.invalidate(_todayMealsCacheKey(userId));

        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'تم حذف الوجبة',
        };
      }
      return {'success': false, 'message': 'فشل في الحذف'};
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // ============================================
  // ✅ 10. جلب تحليل اليوم (مع Cache)
  // ============================================

  static Future<Map<String, dynamic>?> getDailyAnalysis() async {
    print('\n🟡 [NutritionService] جلب تحليل اليوم');

    try {
      final result = await CacheManager.instance.getOrFetch<Map<String, dynamic>>(
        key: _dailyAnalysisCacheKey(userId),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/nutrition/analysis/daily',
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
        print('✅ تم جلب تحليل اليوم');
        return result;
      }
      return null;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ 11. جلب تحليل اليوم مع إجبار تحديث (تجاوز cache)
  // ============================================

  static Future<Map<String, dynamic>?> refreshDailyAnalysis() async {
    print('\n🟡 [NutritionService] تحديث تحليل اليوم');

    CacheManager.instance.invalidate(_dailyAnalysisCacheKey(userId));
    return getDailyAnalysis();
  }

  /// إبطال جميع الكاش المتعلق بالتغذية
  static void clearNutritionCache() {
    CacheManager.instance.invalidateNutrition();
    print('🗑️ [NutritionService] Cache cleared');
  }
}
