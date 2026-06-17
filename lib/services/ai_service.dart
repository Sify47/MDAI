// lib/services/ai_service.dart

import 'dart:convert';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import 'package:vita/utils/prefs_helper.dart';

class AIService {
  static const String _pathPrefix = 'api/ai';

  static int get _userId => PrefsHelper.getUserId() ?? 1;

  // ============================================
  // ✅ توقع الوزن بعد عدد محدد من الأسابيع
  // ============================================
  static Future<Map<String, dynamic>?> predictWeight({
    int weeksAhead = 4,
  }) async {
    print('\n🟡 [AIService] توقع الوزن بعد $weeksAhead أسابيع');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
        key: 'ai_predict_weight_${_userId}_${weeksAhead}w',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/predict-weight/$_userId?weeks_ahead=$weeksAhead',
          );

          print('📥 حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            print('✅ تم توقع الوزن بنجاح');
            return jsonData as Map<String, dynamic>;
          }
          return null;
        },
        ttl: const Duration(hours: 1),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('❌ خطأ في توقع الوزن: $e');
      return null;
    }
  }

  // ============================================
  // ✅ تحليل أنماط الأعراض
  // ============================================
  static Future<Map<String, dynamic>?> analyzeSymptomPatterns({
    int daysBack = 30,
  }) async {
    print('\n🟡 [AIService] تحليل أنماط الأعراض لآخر $daysBack يوم');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
        key: 'ai_symptom_patterns_${_userId}_${daysBack}d',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/symptom-patterns/$_userId?days_back=$daysBack',
          );

          print('📥 حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            print('✅ تم تحليل أنماط الأعراض بنجاح');
            return jsonData as Map<String, dynamic>;
          }
          return null;
        },
        ttl: const Duration(hours: 1),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('❌ خطأ في تحليل أنماط الأعراض: $e');
      return null;
    }
  }

  // ============================================
  // ✅ تحليل فعالية دواء معين
  // ============================================
  static Future<Map<String, dynamic>?> analyzeMedicationEffectiveness(
    int medicationId,
  ) async {
    print('\n🟡 [AIService] تحليل فعالية الدواء $medicationId');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
        key: 'ai_med_effect_${_userId}_${medicationId}',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/medication-effectiveness/$_userId/$medicationId',
          );

          print('📥 حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            print('✅ تم تحليل فعالية الدواء بنجاح');
            return jsonData as Map<String, dynamic>;
          }
          return null;
        },
        ttl: const Duration(hours: 2),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('❌ خطأ في تحليل فعالية الدواء: $e');
      return null;
    }
  }

  // ============================================
  // ✅ نصائح غذائية مخصصة
  // ============================================
  static Future<Map<String, dynamic>?> getPersonalizedNutritionAdvice() async {
    print('\n🟡 [AIService] جلب نصائح غذائية مخصصة');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
        key: 'ai_nutrition_advice_$_userId',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/nutrition-advice/$_userId',
          );

          print('📥 حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            print('✅ تم جلب النصائح الغذائية بنجاح');
            return jsonData as Map<String, dynamic>;
          }
          return null;
        },
        ttl: const Duration(hours: 2),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('❌ خطأ في جلب النصائح الغذائية: $e');
      return null;
    }
  }

  // ============================================
  // ✅ لوحة تحكم متكاملة للتحليلات
  // ============================================
  static Future<Map<String, dynamic>?> getAIDashboard() async {
    print('\n🟡 [AIService] جلب لوحة تحكم التحليلات');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
        key: 'ai_dashboard_$_userId',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/dashboard/$_userId',
          );

          print('📥 حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            print('✅ تم جلب لوحة التحكم بنجاح');
            return jsonData as Map<String, dynamic>;
          }
          return null;
        },
        ttl: const Duration(minutes: 10),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('❌ خطأ في جلب لوحة التحكم: $e');
      return null;
    }
  }

  // ============================================
  // ✅ تحليل نمط النوم (ميزة إضافية)
  // ============================================
  static Future<Map<String, dynamic>?> analyzeSleepPatterns() async {
    print('\n🟡 [AIService] تحليل أنماط النوم');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
        key: 'ai_sleep_$_userId',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/sleep-patterns/$_userId',
          );

          print('📥 حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            print('✅ تم تحليل أنماط النوم بنجاح');
            return jsonData as Map<String, dynamic>;
          }
          return null;
        },
        ttl: const Duration(hours: 2),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('❌ خطأ في تحليل أنماط النوم: $e');
      return null;
    }
  }

  // ============================================
  // ✅ توقع الالتزام بالأدوية
  // ============================================
  static Future<Map<String, dynamic>?> predictAdherenceRate() async {
    print('\n🟡 [AIService] توقع نسبة الالتزام بالأدوية');

    try {
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
        key: 'ai_adherence_$_userId',
        fetch: () async {
          final response = await BaseApiService.get(
            '$_pathPrefix/adherence-prediction/$_userId',
          );

          print('📥 حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            print('✅ تم توقع نسبة الالتزام بنجاح');
            return jsonData as Map<String, dynamic>;
          }
          return null;
        },
        ttl: const Duration(hours: 2),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('❌ خطأ في توقع نسبة الالتزام: $e');
      return null;
    }
  }
}
