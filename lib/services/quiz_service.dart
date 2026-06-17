// lib/services/quiz_service.dart
// 🚀 مُعاد كتابتها باستخدام BaseApiService + CacheManager لتقليل استدعاءات API

import 'dart:convert';
import 'package:vita/utils/prefs_helper.dart';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import '../models/quiz_models.dart';

class QuizService {
  // ✅ لم نعد بحاجة إلى baseUrl مكرر - نستخدم BaseApiService.getFullUrl()

  /// 🟢 Runtime getter — NOT static final (fixes compile-time evaluation bug!)
  static int get _userId => PrefsHelper.getUserId() ?? 1;

  static String get _token => PrefsHelper.getToken() ?? '';

  // ============================================
  // 🏷️ Cache Keys
  // ============================================
  static String _questionsCacheKey(int uid, String? cat) =>
      'quiz_${uid}_questions_${cat ?? 'all'}';
  static String _sessionsCacheKey(int uid, int limit) =>
      'quiz_${uid}_sessions_$limit';
  static String _lastSessionCacheKey(int uid) => 'quiz_${uid}_lastsession';
  static String _comparisonCacheKey(int uid, int? prevId) =>
      'quiz_${uid}_comparison_${prevId ?? 'latest'}';
  static String _analysisCacheKey(int uid) => 'quiz_${uid}_analysis';
  static String _dailyQuestionsCacheKey(int uid, String? time, String? cat) =>
      'quiz_${uid}_daily_questions_${time ?? 'all'}_${cat ?? 'all'}';
  static String _todayStatusCacheKey(int uid) =>
      'quiz_${uid}_daily_status_today';
  static String _weeklyStatusCacheKey(int uid) =>
      'quiz_${uid}_daily_status_weekly';
  static String _dailySessionsCacheKey(int uid) => 'quiz_${uid}_daily_sessions';

  /// مسح جميع كاش الكويز لهذا المستخدم
  static void _invalidateAllQuizCache() {
    final uid = _userId;
    CacheManager.instance.invalidatePattern('quiz_${uid}_');
  }

  // ============================================
  // ✅ 1. جلب جميع الأسئلة (الكويز الشهري) — مع Cache
  // ============================================
  static Future<List<QuizQuestion>> getQuestions({String? category}) async {
    print('\n📋 [QuizService] جلب الأسئلة');

    try {
      final uid = _userId;
      final result = await CacheManager.instance.getOrFetch<List<QuizQuestion>>(
        key: _questionsCacheKey(uid, category),
        fetch: () async {
          final queryParams = <String, dynamic>{'user_id': uid};
          if (category != null) queryParams['category'] = category;

          final response = await BaseApiService.get(
            'api/quiz/questions',
            queryParams: queryParams,
          );

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            return data.map((q) => QuizQuestion.fromJson(q)).toList();
          }
          return <QuizQuestion>[];
        },
        ttl: const Duration(minutes: 10),
        staleWhileRevalidate: true,
      );
      return result ?? [];
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 2. إرسال إجابات الكويز (الشهري)
  // ============================================
  static Future<QuizSessionResponse?> submitQuiz({
    required List<QuizAnswerSubmit> answers,
    required bool isOnboarding,
  }) async {
    print('\n📝 [QuizService] إرسال إجابات الكويز');

    try {
      final body = QuizSessionSubmit(
        answers: answers,
        isOnboarding: isOnboarding,
      ).toJson();

      final response = await BaseApiService.post(
        'api/quiz/submit',
        body: {'user_id': _userId, ...body},
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _invalidateAllQuizCache();
        return QuizSessionResponse.fromJson(data);
      } else {
        print('❌ فشل إرسال الكويز: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ 3. جلب سجل الكويزات (الشهري) — مع Cache
  // ============================================
  static Future<List<QuizSessionResponse>> getSessions({int limit = 10}) async {
    print('\n📋 [QuizService] جلب سجل الكويزات');

    try {
      final uid = _userId;
      final result = await CacheManager.instance
          .getOrFetch<List<QuizSessionResponse>>(
            key: _sessionsCacheKey(uid, limit),
            fetch: () async {
              final response = await BaseApiService.get(
                'api/quiz/sessions',
                queryParams: {'user_id': uid, 'limit': limit},
              );

              if (response.statusCode == 200) {
                final List<dynamic> data = json.decode(response.body);
                return data
                    .map((s) => QuizSessionResponse.fromJson(s))
                    .toList();
              }
              return <QuizSessionResponse>[];
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );
      return result ?? [];
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 4. جلب آخر جلسة (الشهري) — مع Cache
  // ============================================
  static Future<QuizSessionResponse?> getLastSession() async {
    print('\n📋 [QuizService] جلب آخر جلسة كويز');

    try {
      final uid = _userId;
      final result = await CacheManager.instance
          .getOrFetch<QuizSessionResponse>(
            key: _lastSessionCacheKey(uid),
            fetch: () async {
              final response = await BaseApiService.get(
                'api/quiz/last-session',
                queryParams: {'user_id': uid},
              );

              if (response.statusCode == 200) {
                final data = json.decode(response.body);
                return QuizSessionResponse.fromJson(data);
              }
              return null;
            },
            ttl: const Duration(minutes: 3),
            staleWhileRevalidate: true,
          );
      return result;
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // ============================================
  // ✅ 5. مقارنة الجلسات — مع Cache
  // ============================================
  static Future<QuizComparisonResult> compareSessions({
    int? previousSessionId,
  }) async {
    print('\n📊 [QuizService] مقارنة جلسات الكويز');

    try {
      final uid = _userId;
      final result = await CacheManager.instance
          .getOrFetch<QuizComparisonResult>(
            key: _comparisonCacheKey(uid, previousSessionId),
            fetch: () async {
              final queryParams = <String, dynamic>{'user_id': uid};
              if (previousSessionId != null) {
                queryParams['previous_session_id'] = previousSessionId;
              }

              final response = await BaseApiService.get(
                'api/quiz/compare',
                queryParams: queryParams,
              );

              if (response.statusCode == 200) {
                final data = json.decode(response.body);
                return QuizComparisonResult.fromJson(data);
              }
              return QuizComparisonResult(hasComparison: false);
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );
      return result ?? QuizComparisonResult(hasComparison: false);
    } catch (e) {
      print('❌ خطأ: $e');
      return QuizComparisonResult(hasComparison: false);
    }
  }

  // ============================================
  // ✅ 6. تحليل الكويز — مع Cache
  // ============================================
  static Future<QuizAnalysisResult> analyzeQuiz() async {
    print('\n📊 [QuizService] تحليل الكويز');

    try {
      final uid = _userId;
      final result = await CacheManager.instance.getOrFetch<QuizAnalysisResult>(
        key: _analysisCacheKey(uid),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/quiz/analysis',
            queryParams: {'user_id': uid},
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return QuizAnalysisResult.fromJson(data);
          }
          return QuizAnalysisResult(hasAnalysis: false);
        },
        ttl: const Duration(minutes: 10),
        staleWhileRevalidate: true,
      );
      return result ?? QuizAnalysisResult(hasAnalysis: false);
    } catch (e) {
      print('❌ خطأ: $e');
      return QuizAnalysisResult(hasAnalysis: false);
    }
  }

  // ============================================
  // 🌅🌙 7. الكويز اليومي (Daily Quiz)
  // ============================================

  // 7.1 جلب أسئلة الكويز اليومي — مع Cache
  static Future<List<DailyQuizQuestion>> getDailyQuestions({
    String? timeOfDay,
    String? category,
  }) async {
    print('\n📋 [QuizService] جلب أسئلة الكويز اليومي');

    try {
      final uid = _userId;
      final result = await CacheManager.instance
          .getOrFetch<List<DailyQuizQuestion>>(
            key: _dailyQuestionsCacheKey(uid, timeOfDay, category),
            fetch: () async {
              final queryParams = <String, dynamic>{'user_id': uid};
              if (timeOfDay != null && timeOfDay.isNotEmpty) {
                queryParams['time_of_day'] = timeOfDay;
              }
              if (category != null && category.isNotEmpty) {
                queryParams['category'] = category;
              }

              final response = await BaseApiService.get(
                'api/quiz/daily-questions',
                queryParams: queryParams,
              );

              print('📥 حالة الاستجابة: ${response.statusCode}');

              if (response.statusCode == 200) {
                final List<dynamic> data = json.decode(response.body);
                return data.map((q) => DailyQuizQuestion.fromJson(q)).toList();
              }
              return <DailyQuizQuestion>[];
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );
      return result ?? [];
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  // 7.2 إرسال إجابات الكويز اليومي
  static Future<DailyQuizSession?> submitDailyQuiz({
    required String timeOfDay,
    required Map<int, int> answers,
    String? notes,
  }) async {
    print('\n📝 [QuizService] إرسال إجابات الكويز اليومي');

    try {
      // ✅ تحويل Map<int, int> إلى Map<String, int>
      final answersAsString = answers.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      final body = {
        'user_id': _userId,
        'time_of_day': timeOfDay,
        'answers': answersAsString,
        'notes': notes,
      };

      print('📦 البيانات المرسلة: $body');

      final response = await BaseApiService.post(
        'api/quiz/daily-sessions',
        body: body,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        _invalidateAllQuizCache();
        return DailyQuizSession.fromJson(data);
      } else {
        print('❌ فشل إرسال الكويز اليومي: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  // 7.3 جلب حالة الكويز اليومي لليوم الحالي — مع Cache
  static Future<DailyQuizStatus> getTodayQuizStatus() async {
    print('\n📋 [QuizService] جلب حالة الكويز اليومي لليوم');

    try {
      final uid = _userId;
      final result = await CacheManager.instance.getOrFetch<DailyQuizStatus>(
        key: _todayStatusCacheKey(uid),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/quiz/daily-status/today',
            queryParams: {'user_id': uid},
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return DailyQuizStatus.fromJson(data);
          }
          return DailyQuizStatus(
            date: DateTime.now(),
            morningCompleted: false,
            eveningCompleted: false,
            morningScore: 0,
            eveningScore: 0,
          );
        },
        ttl: const Duration(minutes: 2),
        staleWhileRevalidate: true,
      );
      return result ??
          DailyQuizStatus(
            date: DateTime.now(),
            morningCompleted: false,
            eveningCompleted: false,
            morningScore: 0,
            eveningScore: 0,
          );
    } catch (e) {
      print('❌ خطأ: $e');
      return DailyQuizStatus(
        date: DateTime.now(),
        morningCompleted: false,
        eveningCompleted: false,
        morningScore: 0,
        eveningScore: 0,
      );
    }
  }

  // 7.4 جلب حالة الكويز اليومي للأسبوع — مع Cache
  static Future<List<DailyQuizStatus>> getWeeklyQuizStatus() async {
    print('\n📋 [QuizService] جلب حالة الكويز اليومي للأسبوع');

    try {
      final uid = _userId;
      final result = await CacheManager.instance
          .getOrFetch<List<DailyQuizStatus>>(
            key: _weeklyStatusCacheKey(uid),
            fetch: () async {
              final response = await BaseApiService.get(
                'api/quiz/daily-status/weekly',
                queryParams: {'user_id': uid},
              );

              if (response.statusCode == 200) {
                final List<dynamic> data = json.decode(response.body);
                return data.map((s) => DailyQuizStatus.fromJson(s)).toList();
              }
              return <DailyQuizStatus>[];
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );
      return result ?? [];
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  // 7.5 جلب جلسات الكويز اليومي — مع Cache
  static Future<List<DailyQuizSession>> getDailyQuizSessions({
    DateTime? startDate,
    DateTime? endDate,
    String? timeOfDay,
  }) async {
    print('\n📋 [QuizService] جلب جلسات الكويز اليومي');

    try {
      final uid = _userId;
      final result = await CacheManager.instance
          .getOrFetch<List<DailyQuizSession>>(
            key: _dailySessionsCacheKey(uid),
            fetch: () async {
              final queryParams = <String, dynamic>{'user_id': uid};
              if (startDate != null) {
                queryParams['start_date'] = startDate.toIso8601String().split(
                  'T',
                )[0];
              }
              if (endDate != null) {
                queryParams['end_date'] = endDate.toIso8601String().split(
                  'T',
                )[0];
              }
              if (timeOfDay != null) {
                queryParams['time_of_day'] = timeOfDay;
              }

              final response = await BaseApiService.get(
                'api/quiz/daily-sessions',
                queryParams: queryParams,
              );

              if (response.statusCode == 200) {
                final List<dynamic> data = json.decode(response.body);
                return data.map((s) => DailyQuizSession.fromJson(s)).toList();
              }
              return <DailyQuizSession>[];
            },
            ttl: const Duration(minutes: 5),
            staleWhileRevalidate: true,
          );
      return result ?? [];
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }
}
