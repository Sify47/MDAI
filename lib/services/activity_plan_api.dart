// lib/services/activity_plan_api.dart

import 'dart:convert';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import 'package:vita/utils/prefs_helper.dart';
import '../models/activity_plan_model.dart';

class ActivityPlanService {
  static const String _pathPrefix = 'api/plans';

  static int get _userId => PrefsHelper.getUserId()!;

  static String get _cachePrefix => 'activity_plans_${_userId}_';

  // ============================================
  // ✅ 1. جلب كل الخطط
  // ============================================
  static Future<List<ActivityPlan>> getPlans({bool? isActive}) async {
    print('\n🟡 [ActivityPlanService] جلب الخطط');

    try {
      final result = await CacheManager.instance.getOrFetch<List<ActivityPlan>>(
        key: '${_cachePrefix}list${isActive != null ? '_active_$isActive' : ''}',
        fetch: () async {
          String path = '$_pathPrefix/?user_id=$_userId';
          if (isActive != null) {
            path += '&is_active=$isActive';
          }

          final response = await BaseApiService.get(path);
          print('📥 حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            final List<dynamic> jsonData = json.decode(response.body);
            print('✅ تم جلب ${jsonData.length} خطة');
            return jsonData.map((json) => ActivityPlan.fromJson(json)).toList();
          }
          return <ActivityPlan>[];
        },
        ttl: const Duration(minutes: 5),
      );

      return result ?? [];
    } catch (e) {
      print('🔥 خطأ في جلب الخطط: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 2. جلب خطة محددة
  // ============================================
  static Future<ActivityPlan?> getPlanById(int id) async {
    print('\n🟡 [ActivityPlanService] جلب خطة $id');

    try {
      final result = await CacheManager.instance.getOrFetch<ActivityPlan>(
        key: '${_cachePrefix}plan_$id',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/$id?user_id=$_userId',
          );

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            return ActivityPlan.fromJson(jsonData);
          }
          return null;
        },
        ttl: const Duration(minutes: 5),
      );

      return result;
    } catch (e) {
      print('🔥 خطأ في جلب الخطة: $e');
      return null;
    }
  }

  // ============================================
  // ✅ 3. إضافة خطة جديدة
  // ============================================
  static Future<Map<String, dynamic>> addPlan(
    Map<String, dynamic> data,
  ) async {
    print('\n🟡 [ActivityPlanService] إضافة خطة جديدة');
    print('📦 البيانات: $data');

    try {
      final requestData = {'user_id': _userId, ...data};

      final response = await BaseApiService.post(
        '$_pathPrefix/',
        body: requestData,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Invalidate plans cache
        CacheManager.instance.invalidatePattern(_cachePrefix);

        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'message': 'تم إضافة الخطة بنجاح',
          'data': jsonData,
        };
      } else {
        return {'success': false, 'message': 'فشل في إضافة الخطة'};
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'message': 'حدث خطأ: $e'};
    }
  }

  // ============================================
  // ✅ 4. تحديث خطة
  // ============================================
  static Future<Map<String, dynamic>> updatePlan(
    int id,
    Map<String, dynamic> data,
  ) async {
    print('\n🟡 [ActivityPlanService] تحديث خطة $id');

    try {
      final response = await BaseApiService.put(
        '$_pathPrefix/$id?user_id=$_userId',
        body: data,
      );

      if (response.statusCode == 200) {
        // Invalidate plans cache
        CacheManager.instance.invalidatePattern(_cachePrefix);

        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'data': ActivityPlan.fromJson(jsonData),
          'message': 'تم تحديث الخطة بنجاح',
        };
      } else {
        return {'success': false, 'message': 'فشل في تحديث الخطة'};
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }

  // ============================================
  // ✅ 5. حذف خطة
  // ============================================
  static Future<Map<String, dynamic>> deletePlan(int id) async {
    print('\n🟡 [ActivityPlanService] حذف خطة $id');

    try {
      final response = await BaseApiService.delete(
        '$_pathPrefix/$id?user_id=$_userId',
      );

      if (response.statusCode == 200) {
        // Invalidate plans cache
        CacheManager.instance.invalidatePattern(_cachePrefix);

        return {
          'success': true,
          'message': 'تم حذف الخطة',
        };
      } else {
        return {'success': false, 'message': 'فشل في حذف الخطة'};
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    }
  }
}