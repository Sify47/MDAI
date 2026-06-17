// lib/services/cache_manager.dart
// 🚀 نظام التخزين المؤقت ثنائي الطبقة (ذاكرة + Hive) مع نمط Stale-While-Revalidate

import 'dart:collection';
import 'cache_service.dart';

/// 🧠 CacheManager - مدير التخزين المؤقت
///
/// يجمع بين:
/// 1. **Memory Cache** - تخزين في الذاكرة (أسرع وصول)
/// 2. **Persistent Cache** - تخزين دائم عبر CacheService (Hive)
/// 3. **Stale-While-Revalidate** - إظهار البيانات المخزنة مع تحديثها في الخلفية
/// 4. **Debouncing** - منع تكرار الطلبات المتطابقة
/// 5. **Fallback on Error** - استخدام cache عند فشل الشبكة
///
/// مثال:
/// ```dart
/// final nutritionData = await CacheManager.instance.getOrFetch(
///   key: 'nutrition_user_42',
///   fetch: () => NutritionService.getUserNutritionData(),
///   ttl: Duration(minutes: 5),
/// );
/// ```
class CacheManager {
  // ============================================
  // 🔷 Singleton
  // ============================================
  CacheManager._internal();
  static final CacheManager instance = CacheManager._internal();

  // ============================================
  // 🔷 Memory Cache
  // ============================================
  final LinkedHashMap<String, _CacheEntry> _memoryCache = LinkedHashMap(
    equals: _equals,
    hashCode: _hashCode,
  );

  /// الحد الأقصى لعدد العناصر في الذاكرة
  static const int _maxMemoryEntries = 100;

  /// مدة التخزين في الذاكرة (قصير)
  static const Duration _defaultMemoryTtl = Duration(minutes: 2);

  // ============================================
  // 🔷 In-Flight Requests (منع التكرار)
  // ============================================
  final Map<String, Future<dynamic>> _inFlight = {};

  // ============================================
  // 🔷 إحصائيات
  // ============================================
  int hits = 0;
  int misses = 0;
  int saves = 0;

  /// إعادة تعيين الإحصائيات
  void resetStats() {
    hits = 0;
    misses = 0;
    saves = 0;
  }

  /// إحصائيات الأداء
  Map<String, dynamic> get stats => {
    'memory_size': _memoryCache.length,
    'disk_size': CacheService.size,
    'hits': hits,
    'misses': misses,
    'saves': saves,
    'hit_rate': (hits + misses) > 0 ? (hits / (hits + misses) * 100) : 0.0,
  };

  // ============================================
  // 🔷 الحصول على بيانات مع تخزين مؤقت (Stale-While-Revalidate)
  // ============================================

  /// الحصول على بيانات من cache أو جلبها من API
  ///
  /// [key] - مفتاح فريد للبيانات
  /// [fetch] - دالة جلب البيانات (تُستدعى فقط عند الحاجة)
  /// [ttl] - مدة صلاحية cache (افتراضي 5 دقائق)
  /// [persist] - هل يتم تخزين البيانات في Hive أيضاً؟ (افتراضي true)
  /// [staleWhileRevalidate] - إظهار البيانات القديمة مع التحديث في الخلفية
  Future<T?> getOrFetch<T>({
    required String key,
    required Future<T?> Function() fetch,
    Duration ttl = const Duration(minutes: 5),
    bool persist = true,
    bool staleWhileRevalidate = true,
  }) async {
    // 1️⃣ التحقق من الذاكرة أولاً (الأسرع)
    final memoryHit = _getFromMemory<T>(key);
    if (memoryHit != null) {
      hits++;
      return memoryHit;
    }

    // 2️⃣ التحقق من القرص (Hive) إذا كان persist مفعلاً
    if (persist) {
      final diskHit = await _getFromDisk<T>(key);
      if (diskHit != null) {
        // إضافة إلى الذاكرة للوصول السريع
        _addToMemory(key, diskHit, _defaultMemoryTtl);

        // إذا كان Stale-While-Revalidate مفعلاً والبيانات قديمة:
        // أظهر البيانات المخزنة وجلب الجديدة في الخلفية
        if (staleWhileRevalidate) {
          _scheduleBackgroundRefresh(key, fetch, ttl, persist);
        }

        hits++;
        return diskHit;
      }
    }

    // 3️⃣ التحقق من وجود طلب قيد التنفيذ (Debounce)
    final inFlight = _inFlight[key];
    if (inFlight != null) {
      try {
        return await inFlight as T;
      } catch (_) {
        // إذا فشل الطلب القيد التنفيذ، نواصل
      }
    }

    // 4️⃣ جلب البيانات من API
    misses++;
    final future = fetch();
    _inFlight[key] = future;

    try {
      final data = await future;
      if (data != null) {
        // حفظ في الذاكرة
        _addToMemory(key, data, ttl);

        // حفظ على القرص
        if (persist) {
          await _saveToDisk(key, data, ttl);
        }

        saves++;
      } else {
        // البيانات غير موجودة (404) - لا نخزن null في cache
        print('ℹ️ [CacheManager] Fetch returned null for: $key (not cached)');
      }
      return data;
    } catch (e) {
      // 5️⃣ Fallback: استخدام أي بيانات موجودة (حتى لو منتهية)
      final expired = _getExpiredFromDisk(key);
      if (expired != null) {
        print('⚠️ [CacheManager] Fallback to expired data for: $key');
        return expired as T;
      }
      rethrow;
    } finally {
      _inFlight.remove(key);
    }
  }

  // ============================================
  // 🔷 إبطال البيانات المخزنة
  // ============================================

  /// إبطال مفتاح واحد
  void invalidate(String key) {
    _memoryCache.remove(key);
    CacheService.remove(key);
  }

  /// إبطال مجموعة من المفاتيح حسب النمط
  void invalidatePattern(String pattern) {
    // إزالة من الذاكرة
    _memoryCache.removeWhere((key, _) => key.startsWith(pattern));

    // إزالة من Hive - نضطر لمسح الكل لأن Hive لا يدعم pattern
    CacheService.remove(pattern);
  }

  /// إبطال جميع البيانات المتعلقة بمستخدم معين
  void invalidateUser(int userId) {
    invalidatePattern('user_${userId}_');
  }

  /// إبطال الكاش الخاص بالغذاء
  void invalidateNutrition() {
    invalidatePattern('nutrition_');
  }

  /// إبطال الكاش الخاص بالأدوية
  void invalidateMedications() {
    invalidatePattern('medication_');
  }

  /// إبطال الكاش الخاص بالمشي
  void invalidateWalking() {
    invalidatePattern('walking_');
  }

  /// إبطال الكاش الخاص بالأعراض
  void invalidateSymptoms() {
    invalidatePattern('symptom_');
  }

  /// إبطال الكاش الخاص بالأنشطة
  void invalidateActivities() {
    invalidatePattern('activity_');
  }

  /// مسح جميع الكاش
  Future<void> clearAll() async {
    _memoryCache.clear();
    await CacheService.clear();
    _inFlight.clear();
    print('🗑️ [CacheManager] All cache cleared');
  }

  // ============================================
  // 🔷 دوال مساعدة داخلية
  // ============================================

  /// الحصول من الذاكرة
  T? _getFromMemory<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null) return null;

    if (DateTime.now().isBefore(entry.expiry)) {
      return entry.data as T;
    }

    // انتهت الصلاحية - نزيل من الذاكرة
    _memoryCache.remove(key);
    return null;
  }

  /// الحصول من القرص (Hive)
  Future<T?> _getFromDisk<T>(String key) async {
    final raw = CacheService.get(key);
    if (raw != null && raw is T) {
      return raw;
    }
    return null;
  }

  /// الحصول على بيانات منتهية الصلاحية من القرص (للاستخدام كـ Fallback)
  T? _getExpiredFromDisk<T>(String key) {
    try {
      final expired = CacheService.getExpired(key);
      if (expired != null && expired is T) {
        return expired;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// إضافة إلى الذاكرة
  void _addToMemory(String key, dynamic data, Duration ttl) {
    if (_memoryCache.length >= _maxMemoryEntries) {
      // إزالة أقدم عنصر
      _memoryCache.remove(_memoryCache.keys.first);
    }
    _memoryCache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(ttl),
    );
  }

  /// حفظ على القرص
  Future<void> _saveToDisk(String key, dynamic data, Duration ttl) async {
    await CacheService.set(key: key, data: data, ttl: ttl);
  }

  /// جدولة تحديث في الخلفية
  void _scheduleBackgroundRefresh<T>(
    String key,
    Future<T?> Function() fetch,
    Duration ttl,
    bool persist,
  ) {
    Future.delayed(Duration.zero, () async {
      try {
        final freshData = await fetch();
        if (freshData != null) {
          _addToMemory(key, freshData, ttl);
          if (persist) {
            await _saveToDisk(key, freshData, ttl);
          }
          print('🔄 [CacheManager] Background refresh completed: $key');
        }
      } catch (e) {
        // فشل التحديث في الخلفية - هذا مقبول، نستمر بالبيانات القديمة
        print('⚠️ [CacheManager] Background refresh failed: $key - $e');
      }
    });
  }

  // ============================================
  // 🔷 دمج بين fetch و update
  // ============================================

  /// جلب البيانات مع إجبار التحديث (تجاوز cache)
  Future<T?> fetchFresh<T>({
    required String key,
    required Future<T> Function() fetch,
    bool persist = true,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    // إبطال cache أولاً
    invalidate(key);

    // جلب جديد
    return getOrFetch(
      key: key,
      fetch: fetch,
      ttl: ttl,
      persist: persist,
      staleWhileRevalidate: false,
    );
  }
}

// ============================================
// 🔷 فئات مساعدة
// ============================================

/// مدخل في الذاكرة المؤقتة
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});
}

/// دالة مساوية للمفاتيح
bool _equals(String a, String b) => a == b;

/// دالة hashCode للمفاتيح
int _hashCode(String key) => key.hashCode;
