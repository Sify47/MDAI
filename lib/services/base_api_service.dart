/// خدمة API الأساسية
///
/// توفر وظائف مشتركة لجميع خدمات API مع إدارة أمنية محسنة
/// مع دعم التخزين المؤقت (Caching) لتقليل استدعاءات API

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:vita/config/environment.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'package:vita/services/cache_manager.dart';

class BaseApiService {
  /// الحصول على عنوان URL الكامل للمسار المحدد
  /// المسار يجب أن يكون المسار الكامل بعد الـ base URL
  /// مثال: 'api/nutrition/user-data', 'medications/', 'walking/today'
  static String getFullUrl(String path) {
    // إزالة الـ slash الزائدة في البداية
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // بناء URL كامل - بدون إضافة /api/v1 لأن المسار يأتي كامل من الخدمات
    final baseUrl = EnvironmentConfig.apiBaseUrl;
    final url = '$baseUrl/$cleanPath';

    // تسجيل URL للتطوير فقط
    if (EnvironmentConfig.debugMode) {
      developer.log('🌐 API URL: $url', name: 'BaseApiService');
    }

    return url;
  }

  /// الحصول على headers الافتراضية مع التوكن
  static Future<Map<String, String>> getHeaders({
    bool includeAuth = true,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'VitaHealth-App/1.0',
    };

    // إضافة التوكن إذا مطلوب
    if (includeAuth) {
      final token = await _getAuthToken();
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    // إضافة headers إضافية إذا وجدت
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// الحصول على التوكن من التخزين المحلي
  static Future<String> _getAuthToken() async {
    try {
      final token = PrefsHelper.getToken();
      return token ?? '';
    } catch (e) {
      if (EnvironmentConfig.debugMode) {
        developer.log('❌ Failed to get auth token: $e', name: 'BaseApiService');
      }
      return '';
    }
  }

  /// تنفيذ طلب GET
  static Future<http.Response> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse(getFullUrl(path));
      final finalUrl = queryParams != null
          ? url.replace(queryParameters: _stringifyQueryParams(queryParams))
          : url;

      final headers = await getHeaders(includeAuth: includeAuth);

      if (EnvironmentConfig.debugMode) {
        developer.log('📤 GET Request: $finalUrl', name: 'BaseApiService');
        developer.log('📤 Headers: $headers', name: 'BaseApiService');
      }

      final response = await http
          .get(finalUrl, headers: headers)
          .timeout(Duration(seconds: EnvironmentConfig.apiTimeoutSeconds));

      _logResponse('GET', finalUrl.toString(), response);
      return response;
    } catch (e) {
      _logError('GET', path, e);
      rethrow;
    }
  }

  // ============================================
  // ✅ GET مع تخزين مؤقت (للبيانات القراءة فقط)
  // ============================================

  /// تنفيذ طلب GET مع التخزين المؤقت
  ///
  /// [cacheKey] - مفتاح الكاش (افتراضي: مسار API)
  /// [ttl] - مدة الصلاحية (افتراضي: 5 دقائق)
  /// [persist] - حفظ على القرص (Hive) أيضاً
  static Future<Map<String, dynamic>> getCached(
    String path, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
    String? cacheKey,
    Duration ttl = const Duration(minutes: 5),
    bool persist = true,
  }) async {
    final key = cacheKey ?? 'api_${path}_${queryParams?.toString() ?? ''}';

    final result = await CacheManager.instance.getOrFetch<Map<String, dynamic>>(
      key: key,
      fetch: () async {
        final response = await get(
          path,
          queryParams: queryParams,
          includeAuth: includeAuth,
        );
        return validateResponse(response);
      },
      ttl: ttl,
      persist: persist,
      staleWhileRevalidate: true,
    );

    if (result != null) {
      return result;
    }

    // Fallback: جلب مباشر إذا كان cache فارغاً
    final response = await get(
      path,
      queryParams: queryParams,
      includeAuth: includeAuth,
    );
    return validateResponse(response);
  }

  /// تنفيذ طلب GET مع تخزين مؤقت وإرجاع قائمة
  static Future<List<dynamic>> getCachedList(
    String path, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
    String? cacheKey,
    Duration ttl = const Duration(minutes: 5),
    bool persist = true,
  }) async {
    final key = cacheKey ?? 'api_list_${path}_${queryParams?.toString() ?? ''}';

    final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
      key: key,
      fetch: () async {
        final response = await get(
          path,
          queryParams: queryParams,
          includeAuth: includeAuth,
        );
        final parsed = jsonDecode(response.body);
        if (parsed is List<dynamic>) {
          return parsed;
        }
        throw FormatException('Expected List, got ${parsed.runtimeType}');
      },
      ttl: ttl,
      persist: persist,
      staleWhileRevalidate: true,
    );

    if (result != null) {
      return result;
    }

    // Fallback
    final response = await get(
      path,
      queryParams: queryParams,
      includeAuth: includeAuth,
    );
    final parsed = jsonDecode(response.body);
    if (parsed is List<dynamic>) {
      return parsed;
    }
    throw FormatException('Expected List, got ${parsed.runtimeType}');
  }

  /// إبطال الكاش لمسار محدد
  static void invalidateCache(String pattern) {
    CacheManager.instance.invalidatePattern(pattern);
    if (EnvironmentConfig.debugMode) {
      developer.log(
        '🗑️ [Cache] Invalidated: $pattern',
        name: 'BaseApiService',
      );
    }
  }

  /// إبطال كل الكاش
  static Future<void> clearAllCache() async {
    await CacheManager.instance.clearAll();
    if (EnvironmentConfig.debugMode) {
      developer.log('🗑️ [Cache] All cache cleared', name: 'BaseApiService');
    }
  }

  /// تنفيذ طلب POST
  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse(getFullUrl(path));
      final headers = await getHeaders(includeAuth: includeAuth);

      final bodyJson = body != null ? jsonEncode(body) : null;

      if (EnvironmentConfig.debugMode) {
        developer.log('📤 POST Request: $url', name: 'BaseApiService');
        developer.log('📤 Headers: $headers', name: 'BaseApiService');
        developer.log('📤 Body: $bodyJson', name: 'BaseApiService');
      }

      final response = await http
          .post(url, headers: headers, body: bodyJson)
          .timeout(Duration(seconds: EnvironmentConfig.apiTimeoutSeconds));

      _logResponse('POST', url.toString(), response);
      return response;
    } catch (e) {
      _logError('POST', path, e);
      rethrow;
    }
  }

  /// تنفيذ طلب PUT
  static Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse(getFullUrl(path));
      final headers = await getHeaders(includeAuth: includeAuth);

      final bodyJson = body != null ? jsonEncode(body) : null;

      if (EnvironmentConfig.debugMode) {
        developer.log('📤 PUT Request: $url', name: 'BaseApiService');
        developer.log('📤 Headers: $headers', name: 'BaseApiService');
        developer.log('📤 Body: $bodyJson', name: 'BaseApiService');
      }

      final response = await http
          .put(url, headers: headers, body: bodyJson)
          .timeout(Duration(seconds: EnvironmentConfig.apiTimeoutSeconds));

      _logResponse('PUT', url.toString(), response);
      return response;
    } catch (e) {
      _logError('PUT', path, e);
      rethrow;
    }
  }

  /// تنفيذ طلب DELETE
  static Future<http.Response> delete(
    String path, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse(getFullUrl(path));
      final headers = await getHeaders(includeAuth: includeAuth);

      final bodyJson = body != null ? jsonEncode(body) : null;

      if (EnvironmentConfig.debugMode) {
        developer.log('📤 DELETE Request: $url', name: 'BaseApiService');
        developer.log('📤 Headers: $headers', name: 'BaseApiService');
        developer.log('📤 Body: $bodyJson', name: 'BaseApiService');
      }

      final response = await http
          .delete(url, headers: headers, body: bodyJson)
          .timeout(Duration(seconds: EnvironmentConfig.apiTimeoutSeconds));

      _logResponse('DELETE', url.toString(), response);
      return response;
    } catch (e) {
      _logError('DELETE', path, e);
      rethrow;
    }
  }

  /// تنفيذ طلب PATCH
  static Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse(getFullUrl(path));
      final headers = await getHeaders(includeAuth: includeAuth);

      final bodyJson = body != null ? jsonEncode(body) : null;

      if (EnvironmentConfig.debugMode) {
        developer.log('📤 PATCH Request: $url', name: 'BaseApiService');
        developer.log('📤 Headers: $headers', name: 'BaseApiService');
        developer.log('📤 Body: $bodyJson', name: 'BaseApiService');
      }

      final response = await http
          .patch(url, headers: headers, body: bodyJson)
          .timeout(Duration(seconds: EnvironmentConfig.apiTimeoutSeconds));

      _logResponse('PATCH', url.toString(), response);
      return response;
    } catch (e) {
      _logError('PATCH', path, e);
      rethrow;
    }
  }

  /// تحويل query parameters إلى strings
  static Map<String, String> _stringifyQueryParams(
    Map<String, dynamic> params,
  ) {
    return params.map((key, value) {
      if (value == null) return MapEntry(key, '');
      return MapEntry(key, value.toString());
    });
  }

  /// تسجيل الاستجابة
  static void _logResponse(String method, String url, http.Response response) {
    if (!EnvironmentConfig.debugMode) return;

    final statusCode = response.statusCode;
    final statusEmoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';

    developer.log('''
$statusEmoji $method Response:
  URL: $url
  Status: $statusCode ${response.reasonPhrase}
  Headers: ${response.headers}
  Body: ${response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body}
''', name: 'BaseApiService');
  }

  /// تسجيل الأخطاء
  static void _logError(String method, String path, dynamic error) {
    if (!EnvironmentConfig.debugMode) return;

    developer.log('''
🔥 $method Error:
  Path: $path
  Error: $error
  Stack Trace: ${error is Error ? error.stackTrace : ''}
''', name: 'BaseApiService');
  }

  /// التحقق من صحة الاستجابة
  static Map<String, dynamic> validateResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw FormatException('Failed to parse response JSON: $e');
      }
    } else {
      throw HttpException(
        'API Error: ${response.statusCode} ${response.reasonPhrase}',
        response.statusCode,
      );
    }
  }
}

/// استثناء مخصص لأخطاء HTTP
class HttpException implements Exception {
  final String message;
  final int statusCode;

  HttpException(this.message, this.statusCode);

  @override
  String toString() => 'HttpException: $message (Status: $statusCode)';
}
