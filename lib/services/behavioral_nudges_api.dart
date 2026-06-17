// lib/services/behavioral_nudges_api.dart
// 🚀 مُعاد كتابتها باستخدام BaseApiService + CacheManager لتقليل استدعاءات API

import 'dart:convert';
import 'package:vita/utils/prefs_helper.dart';
import '../services/base_api_service.dart';
import '../services/cache_manager.dart';

class BehavioralNudgesApi {
  static const String _pathPrefix = 'api/behavioral-nudges';

  /// 🟢 Runtime getter — NOT static final (fixes compile-time evaluation bug!)
  static int get _userId {
    final id = PrefsHelper.getUserId();
    if (id == null) throw Exception('User ID not found');
    return id;
  }

  // ============================================
  // 🏷️ Cache Keys
  // ============================================
  static String _nudgesCacheKey(
    int uid,
    String? status,
    String? type,
    String? priority,
  ) => 'nudges_${uid}_${status ?? 'all'}_${type ?? 'all'}_${priority ?? 'all'}';
  static String _pendingNudgesCacheKey(int uid) => 'nudges_pending_$uid';
  static String _patternsCacheKey(int uid) => 'nudges_patterns_$uid';
  static String _statisticsCacheKey(int uid) => 'nudges_statistics_$uid';
  static String _todayNudgesCacheKey(int uid) => 'nudges_today_$uid';
  static String _nudgesByPriorityCacheKey(int uid) => 'nudges_priority_$uid';

  /// مسح جميع كاش التحفيزات لهذا المستخدم
  static void _invalidateAllNudgesCache() {
    final uid = _userId;
    CacheManager.instance.invalidatePattern('nudges_${uid}_');
  }

  // ============================================
  // ✅ الحصول على التحفيزات السلوكية — مع Cache
  // ============================================
  static Future<List<Map<String, dynamic>>> getBehavioralNudges({
    String? status,
    String? nudgeType,
    String? priority,
    int? limit,
  }) async {
    try {
      final userId = _userId;
      final queryParams = <String, String>{'user_id': userId.toString()};

      if (status != null) queryParams['status'] = status;
      if (nudgeType != null) queryParams['nudge_type'] = nudgeType;
      if (priority != null) queryParams['priority'] = priority;
      if (limit != null) queryParams['limit'] = limit.toString();

      final result = await CacheManager.instance
          .getOrFetch<List<Map<String, dynamic>>>(
            key: _nudgesCacheKey(userId, status, nudgeType, priority),
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/',
                queryParams: queryParams,
              );

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                return List<Map<String, dynamic>>.from(data);
              } else {
                throw Exception(
                  'Failed to load behavioral nudges: ${response.statusCode}',
                );
              }
            },
            ttl: const Duration(minutes: 3),
            staleWhileRevalidate: true,
          );

      return result ?? [];
    } catch (e) {
      print('Error getting behavioral nudges: $e');
      rethrow;
    }
  }

  // ============================================
  // ✅ الحصول على التحفيزات المعلقة — مع Cache
  // ============================================
  static Future<List<Map<String, dynamic>>> getPendingNudges() async {
    try {
      final userId = _userId;
      final result = await CacheManager.instance
          .getOrFetch<List<Map<String, dynamic>>>(
            key: _pendingNudgesCacheKey(userId),
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/pending',
                queryParams: {'user_id': userId.toString()},
              );

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                return List<Map<String, dynamic>>.from(data);
              } else {
                throw Exception(
                  'Failed to load pending nudges: ${response.statusCode}',
                );
              }
            },
            ttl: const Duration(minutes: 2),
            staleWhileRevalidate: true,
          );

      return result ?? [];
    } catch (e) {
      print('Error getting pending nudges: $e');
      rethrow;
    }
  }

  // ============================================
  // ✅ إنشاء تحفيز سلوكي جديد (POST — إبطال الكاش)
  // ============================================
  static Future<Map<String, dynamic>> createBehavioralNudge({
    required String title,
    required String message,
    required String nudgeType,
    required String priority,
    required String context,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _userId;
      final body = {
        'user_id': userId,
        'title': title,
        'message': message,
        'nudge_type': nudgeType,
        'priority': priority,
        'context': context,
        'metadata': metadata ?? {},
      };

      final response = await BaseApiService.post('$_pathPrefix/', body: body);

      if (response.statusCode == 200) {
        _invalidateAllNudgesCache();
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create behavioral nudge: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error creating behavioral nudge: $e');
      rethrow;
    }
  }

  // ============================================
  // ✅ وضع علامة على التحفيز كتم تسليمه (PUT — إبطال الكاش)
  // ============================================
  static Future<void> markNudgeAsDelivered(int nudgeId) async {
    try {
      final response = await BaseApiService.put(
        '$_pathPrefix/$nudgeId/deliver',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark nudge as delivered: ${response.statusCode}',
        );
      }
      _invalidateAllNudgesCache();
    } catch (e) {
      print('Error marking nudge as delivered: $e');
      rethrow;
    }
  }

  // ============================================
  // ✅ وضع علامة على التحفيز كتم اتخاذ إجراء (PUT — إبطال الكاش)
  // ============================================
  static Future<void> markNudgeActionTaken(int nudgeId, String actionId) async {
    try {
      final response = await BaseApiService.put(
        '$_pathPrefix/$nudgeId/action-taken',
        body: {'action_id': actionId},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark nudge action taken: ${response.statusCode}',
        );
      }
      _invalidateAllNudgesCache();
    } catch (e) {
      print('Error marking nudge action taken: $e');
      rethrow;
    }
  }

  // ============================================
  // ✅ توليد تحفيزات سلوكية ذكية (POST — إبطال الكاش)
  // ============================================
  static Future<Map<String, dynamic>> generateBehavioralNudges() async {
    try {
      final userId = _userId;
      final response = await BaseApiService.post(
        '$_pathPrefix/generate?user_id=$userId',
      );

      if (response.statusCode == 200) {
        _invalidateAllNudgesCache();
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to generate behavioral nudges: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error generating behavioral nudges: $e');
      rethrow;
    }
  }

  // ============================================
  // ✅ الحصول على الأنماط السلوكية — مع Cache
  // ============================================
  static Future<List<Map<String, dynamic>>> getBehavioralPatterns() async {
    try {
      final userId = _userId;
      final result = await CacheManager.instance
          .getOrFetch<List<Map<String, dynamic>>>(
            key: _patternsCacheKey(userId),
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/patterns',
                queryParams: {'user_id': userId.toString()},
              );

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                return List<Map<String, dynamic>>.from(data);
              } else {
                throw Exception(
                  'Failed to load behavioral patterns: ${response.statusCode}',
                );
              }
            },
            ttl: const Duration(minutes: 10),
            staleWhileRevalidate: true,
          );

      return result ?? [];
    } catch (e) {
      print('Error getting behavioral patterns: $e');
      rethrow;
    }
  }

  // ============================================
  // ✅ الحصول على إحصائيات التحفيزات — مع Cache
  // ============================================
  static Future<Map<String, dynamic>> getNudgeStatistics() async {
    try {
      final userId = _userId;
      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _statisticsCacheKey(userId),
            fetch: () async {
              final response = await BaseApiService.get(
                '$_pathPrefix/statistics',
                queryParams: {'user_id': userId.toString()},
              );

              if (response.statusCode == 200) {
                return jsonDecode(response.body) as Map<String, dynamic>;
              } else {
                throw Exception(
                  'Failed to load nudge statistics: ${response.statusCode}',
                );
              }
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );

      return result ?? {};
    } catch (e) {
      print('Error getting nudge statistics: $e');
      rethrow;
    }
  }

  // ============================================
  // ✅ تجاهل تحفيز (PUT — إبطال الكاش)
  // ============================================
  static Future<void> dismissNudge(int nudgeId) async {
    try {
      final response = await BaseApiService.put(
        '$_pathPrefix/$nudgeId/dismiss',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to dismiss nudge: ${response.statusCode}');
      }
      _invalidateAllNudgesCache();
    } catch (e) {
      print('Error dismissing nudge: $e');
      rethrow;
    }
  }

  // ============================================
  // ✅ الحصول على التحفيزات اليومية — مع Cache
  // ============================================
  static Future<List<Map<String, dynamic>>> getTodayNudges() async {
    try {
      final userId = _userId;
      final result = await CacheManager.instance
          .getOrFetch<List<Map<String, dynamic>>>(
            key: _todayNudgesCacheKey(userId),
            fetch: () async {
              final nudges = await getBehavioralNudges();
              final today = DateTime.now();
              final startOfDay = DateTime(today.year, today.month, today.day);
              return nudges.where((nudge) {
                final createdAt = DateTime.parse(nudge['created_at']);
                return createdAt.isAfter(startOfDay);
              }).toList();
            },
            ttl: const Duration(minutes: 2),
            staleWhileRevalidate: true,
          );

      return result ?? [];
    } catch (e) {
      print('Error getting today nudges: $e');
      rethrow;
    }
  }

  // ============================================
  // ✅ الحصول على التحفيزات حسب الأولوية — مع Cache
  // ============================================
  static Future<Map<String, List<Map<String, dynamic>>>>
  getNudgesByPriority() async {
    try {
      final userId = _userId;
      final result = await CacheManager.instance
          .getOrFetch<Map<String, List<Map<String, dynamic>>>>(
            key: _nudgesByPriorityCacheKey(userId),
            fetch: () async {
              final nudges = await getBehavioralNudges();

              final highPriority = nudges
                  .where((n) => n['priority'] == 'high')
                  .toList();
              final mediumPriority = nudges
                  .where((n) => n['priority'] == 'medium')
                  .toList();
              final lowPriority = nudges
                  .where((n) => n['priority'] == 'low')
                  .toList();

              return {
                'high': highPriority,
                'medium': mediumPriority,
                'low': lowPriority,
              };
            },
            ttl: const Duration(minutes: 3),
            staleWhileRevalidate: true,
          );

      return result ?? {'high': [], 'medium': [], 'low': []};
    } catch (e) {
      print('Error getting nudges by priority: $e');
      rethrow;
    }
  }
}
