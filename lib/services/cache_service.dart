// lib/services/cache_service.dart
// 🗄️ Hive caching layer for offline data persistence and faster loading

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _boxName = 'app_cache';
  static const Duration _defaultTtl = Duration(minutes: 15);
  static const Duration _longTtl = Duration(hours: 2);

  static Box? _box;

  // ============================================
  // ✅ التهيئة - استدعاء مرة واحدة عند بدء التطبيق
  // ============================================
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    print('🗄️ [Cache] Hive initialized successfully');
  }

  // ============================================
  // ✅ حفظ بيانات مع وقت انتهاء الصلاحية
  // ============================================
  static Future<void> set({
    required String key,
    required dynamic data,
    Duration ttl = _defaultTtl,
  }) async {
    try {
      final cacheEntry = {
        'data': data,
        'expires_at': DateTime.now().add(ttl).toIso8601String(),
      };
      await _box?.put(key, json.encode(cacheEntry));
      print('🗄️ [Cache] ✅ Cached: $key (TTL: ${ttl.inMinutes}min)');
    } catch (e) {
      print('🗄️ [Cache] ❌ Failed to cache $key: $e');
    }
  }

  // ============================================
  // ✅ حفظ بيانات لفترة طويلة (للبيانات شبه الثابتة)
  // ============================================
  static Future<void> setLongCache({
    required String key,
    required dynamic data,
  }) async {
    await set(key: key, data: data, ttl: _longTtl);
  }

  // ============================================
  // ✅ قراءة البيانات المخزنة مؤقتاً
  // ============================================
  static dynamic get(String key) {
    try {
      final raw = _box?.get(key);
      if (raw == null) {
        print('🗄️ [Cache] ❌ Miss: $key');
        return null;
      }

      final cacheEntry = json.decode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(cacheEntry['expires_at']);

      if (DateTime.now().isAfter(expiresAt)) {
        print('🗄️ [Cache] ⏰ Expired: $key');
        _box?.delete(key);
        return null;
      }

      print('🗄️ [Cache] ✅ Hit: $key');
      return cacheEntry['data'];
    } catch (e) {
      print('🗄️ [Cache] ❌ Error reading $key: $e');
      return null;
    }
  }

  // ============================================
  // ✅ حذف مفتاح محدد
  // ============================================
  static Future<void> remove(String key) async {
    await _box?.delete(key);
    print('🗄️ [Cache] 🗑️ Removed: $key');
  }

  // ============================================
  // ✅ مسح جميع البيانات المخزنة
  // ============================================
  static Future<void> clear() async {
    await _box?.clear();
    print('🗄️ [Cache] 🧹 All cache cleared');
  }

  // ============================================
  // ✅ مسح البيانات منتهية الصلاحية فقط
  // ============================================
  static Future<void> clearExpired() async {
    try {
      final keys = _box?.keys.toList() ?? [];
      int cleared = 0;

      for (final key in keys) {
        final raw = _box?.get(key);
        if (raw != null) {
          try {
            final cacheEntry = json.decode(raw) as Map<String, dynamic>;
            final expiresAt = DateTime.parse(cacheEntry['expires_at']);
            if (DateTime.now().isAfter(expiresAt)) {
              await _box?.delete(key);
              cleared++;
            }
          } catch (_) {
            await _box?.delete(key);
            cleared++;
          }
        }
      }

      print('🗄️ [Cache] 🧹 Cleared $cleared expired entries');
    } catch (e) {
      print('🗄️ [Cache] ❌ Error clearing expired: $e');
    }
  }

  // ============================================
  // ✅ الحصول على بيانات منتهية الصلاحية (للاستخدام في Fallback)
  // ============================================
  static dynamic getExpired(String key) {
    try {
      final raw = _box?.get(key);
      if (raw == null) return null;
      final cacheEntry = json.decode(raw) as Map<String, dynamic>;
      return cacheEntry['data'];
    } catch (e) {
      print('🗄️ [Cache] ❌ Error reading expired $key: $e');
      return null;
    }
  }

  // ============================================
  // ✅ الحصول على حجم الذاكرة المؤقتة
  // ============================================
  static int get size => _box?.length ?? 0;

  // ============================================
  // ✅ التحقق من وجود مفتاح وصلاحيته
  // ============================================
  static bool has(String key) {
    return get(key) != null;
  }

  // ============================================
  // ✅ حفظ بيانات المستخدم (تبقى حتى تسجيل الخروج)
  // ============================================
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    await set(
      key: 'user_data_${userData['id']}',
      data: userData,
      ttl: const Duration(days: 7),
    );
  }

  // ============================================
  // ✅ حفظ آخر استجابة للـ API
  // ============================================
  static Future<void> cacheApiResponse({
    required String endpoint,
    required Map<String, dynamic> response,
    Duration ttl = _defaultTtl,
  }) async {
    await set(key: 'api_$endpoint', data: response, ttl: ttl);
  }

  // ============================================
  // ✅ استرجاع آخر استجابة للـ API
  // ============================================
  static Map<String, dynamic>? getCachedApiResponse(String endpoint) {
    final data = get('api_$endpoint');
    if (data != null && data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }
}
