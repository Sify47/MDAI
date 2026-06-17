// lib/services/analysis_api.dart
// 🚀 مُعاد كتابتها باستخدام BaseApiService + CacheManager لتقليل استدعاءات API

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:vita/config/environment.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import '../models/analysis_model.dart';

class AnalysisService {
  // ✅ لم نعد بحاجة إلى baseUrl مكرر - نستخدم BaseApiService.getFullUrl()

  /// 🟢 Runtime getter — NOT static final (fixes compile-time evaluation bug!)
  static int get _userId => PrefsHelper.getUserId() ?? 1;

  // ============================================
  // 🏷️ Cache Keys
  // ============================================
  static String _historyCacheKey(int uid) => 'analysis_history_$uid';
  static String _historyByIdCacheKey(int uid, int id) =>
      'analysis_history_${uid}_$id';
  static String _typesCacheKey() => 'analysis_types';

  /// مسح جميع كاش التحاليل لهذا المستخدم
  static void _invalidateAllAnalysisCache() {
    final uid = _userId;
    CacheManager.instance.invalidatePattern('analysis_${uid}_');
  }

  // ============================================
  // ✅ رفع وتحليل ملف (Multipart — لا يمكن تخزينه في كاش)
  // ============================================
  static Future<Map<String, dynamic>> uploadAndAnalyzeFile(
    File file,
    String fileName,
  ) async {
    print('\n🟡 [AnalysisService] ===== بدء رفع وتحليل ملف =====');
    print('📁 الملف: $fileName');
    print('📁 حجم الملف: ${await file.length()} bytes');

    try {
      final url = BaseApiService.getFullUrl('api/analysis/upload');
      print('📤 [AnalysisService] إرسال طلب رفع ملف...');

      // ✅ استخدام BaseApiService.getHeaders() للحصول على التوكن
      final headers = await BaseApiService.getHeaders();

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.fields['user_id'] = _userId.toString();
      print('✅ [AnalysisService] user_id: ${_userId}');

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
        ),
      );
      print('✅ [AnalysisService] تم إضافة الملف للطلب');

      print('⏳ [AnalysisService] جاري إرسال الطلب...');
      var streamedResponse = await request.send().timeout(
        Duration(seconds: EnvironmentConfig.apiTimeoutSeconds),
      );
      print(
        '📥 [AnalysisService] تم استلام الرد: ${streamedResponse.statusCode}',
      );

      var responseData = await streamedResponse.stream.bytesToString();
      print('📄 [AnalysisService] محتوى الرد: $responseData');

      if (responseData.isEmpty) {
        print('❌ [AnalysisService] استجابة فارغة من الخادم');
        return {'success': false, 'message': 'استجابة فارغة من الخادم'};
      }

      Map<String, dynamic> jsonData;
      try {
        jsonData = json.decode(responseData);
        print('✅ [AnalysisService] تم تحويل JSON بنجاح');
        print('📊 [AnalysisService] JSON keys: ${jsonData.keys.join(', ')}');
      } catch (e) {
        print('❌ [AnalysisService] فشل في تحويل JSON: $e');
        return {'success': false, 'message': 'فشل في تحليل استجابة الخادم: $e'};
      }

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        print('✅ [AnalysisService] تم رفع وتحليل الملف بنجاح');
        _invalidateAllAnalysisCache();

        int? historyId;
        if (jsonData.containsKey('history_id') &&
            jsonData['history_id'] != null) {
          print(
            '🔍 [AnalysisService] history_id موجود: ${jsonData['history_id']}',
          );
          if (jsonData['history_id'] is int) {
            historyId = jsonData['history_id'];
          } else if (jsonData['history_id'] is String) {
            historyId = int.tryParse(jsonData['history_id'].toString());
            print(
              '🔄 [AnalysisService] تم تحويل history_id من String إلى int: $historyId',
            );
          }
        } else {
          print('⚠️ [AnalysisService] history_id غير موجود في الاستجابة');
        }

        return {
          'success': true,
          'data': jsonData,
          'historyId': historyId,
          'message': jsonData['message'] ?? 'تم التحليل بنجاح',
        };
      } else {
        print('❌ [AnalysisService] فشل: ${streamedResponse.statusCode}');
        print(
          '❌ [AnalysisService] رسالة الخطأ: ${jsonData['detail'] ?? 'غير معروف'}',
        );
        return {
          'success': false,
          'message': jsonData['detail'] ?? 'فشل في رفع الملف',
        };
      }
    } catch (e) {
      print('🔥 [AnalysisService] خطأ غير متوقع في رفع الملف: $e');
      print('🔥 [AnalysisService] نوع الخطأ: ${e.runtimeType}');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    } finally {
      print('🟡 [AnalysisService] ===== انتهاء رفع وتحليل ملف =====\n');
    }
  }

  // ============================================
  // ✅ تحليل نص مباشر (POST — لا يمكن تخزينه في كاش)
  // ============================================
  static Future<Map<String, dynamic>> analyzeText(
    String text, {
    String? fileName,
  }) async {
    print('\n🟡 [AnalysisService] ===== بدء تحليل نص مباشر =====');
    print(
      '📝 النص: ${text.substring(0, text.length > 100 ? 100 : text.length)}...',
    );

    try {
      Map<String, dynamic> requestBody = {
        'user_id': _userId,
        'text': text,
        'file_name': fileName ?? 'نص مباشر',
      };
      print('📦 [AnalysisService] جسم الطلب: $requestBody');

      final response = await BaseApiService.post(
        'api/analysis/analyze-text',
        body: requestBody,
      );

      print('📥 [AnalysisService] حالة الاستجابة: ${response.statusCode}');
      print('📄 [AnalysisService] محتوى الاستجابة: ${response.body}');

      var responseBody = response.body;
      if (responseBody.isEmpty) {
        print('❌ [AnalysisService] استجابة فارغة');
        return {'success': false, 'message': 'استجابة فارغة'};
      }

      Map<String, dynamic> jsonData;
      try {
        jsonData = json.decode(responseBody);
        print('✅ [AnalysisService] تم تحويل JSON بنجاح');
      } catch (e) {
        print('❌ [AnalysisService] فشل في تحويل JSON: $e');
        return {'success': false, 'message': 'فشل في تحليل استجابة الخادم'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        _invalidateAllAnalysisCache();

        int? historyId;
        if (jsonData.containsKey('history_id') &&
            jsonData['history_id'] != null) {
          print(
            '🔍 [AnalysisService] history_id موجود: ${jsonData['history_id']}',
          );
          if (jsonData['history_id'] is int) {
            historyId = jsonData['history_id'];
          } else if (jsonData['history_id'] is String) {
            historyId = int.tryParse(jsonData['history_id'].toString());
          }
        }

        return {'success': true, 'data': jsonData, 'historyId': historyId};
      } else {
        print(
          '❌ [AnalysisService] فشل في التحليل: ${jsonData['detail'] ?? 'غير معروف'}',
        );
        return {
          'success': false,
          'message': jsonData['detail'] ?? 'فشل في تحليل النص',
        };
      }
    } catch (e) {
      print('🔥 [AnalysisService] خطأ في تحليل النص: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    } finally {
      print('🟡 [AnalysisService] ===== انتهاء تحليل نص مباشر =====\n');
    }
  }

  // ============================================
  // ✅ جلب تحليل معين — مع Cache
  // ============================================
  static Future<UserAnalysisHistory?> getAnalysisHistoryById(int id) async {
    print('\n🟡 [AnalysisService] ===== بدء جلب تحليل معين =====');
    print('🔍 [AnalysisService] ID: $id');

    try {
      final uid = _userId;
      final result = await CacheManager.instance
          .getOrFetch<UserAnalysisHistory>(
        key: _historyByIdCacheKey(uid, id),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/analysis/history/$id',
            queryParams: {'user_id': uid},
          );

          print('📥 [AnalysisService] حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            var jsonData = json.decode(response.body);
            print('✅ [AnalysisService] تم تحويل JSON بنجاح');

            // ✅ التحقق من وجود extracted_text وتحويله إلى نتائج
            if (jsonData.containsKey('extracted_text') &&
                jsonData['extracted_text'] != null &&
                (jsonData['results'] == null ||
                    (jsonData['results'] as List).isEmpty)) {
              print(
                '🔍 [AnalysisService] extracted_text موجود والنتائج فارغة، جاري تحليل النص...',
              );
              String extractedText = jsonData['extracted_text'] ?? '';

              // تحليل النص المستخرج
              var parsedResults = AnalysisResultParser.parseExtractedText(
                extractedText,
              );
              print(
                '✅ [AnalysisService] تم تحليل النص واستخراج ${parsedResults.length} نتيجة',
              );

              // تحويل النتائج إلى List
              List<Map<String, dynamic>> resultsList = [];
              for (var result in parsedResults) {
                resultsList.add({
                  'indicator': {
                    'name_ar': result['test_name'],
                    'unit': result['unit'],
                  },
                  'value': result['value'],
                  'unit': result['unit'],
                  'status': result['status'],
                });
              }

              // إضافة النتائج إلى jsonData
              jsonData['results'] = resultsList;
              print('✅ [AnalysisService] تم إضافة النتائج إلى jsonData كـ List');
            }

            return UserAnalysisHistory.fromJson(jsonData);
          }
          return null;
        },
        ttl: const Duration(minutes: 10),
        staleWhileRevalidate: true,
      );
      return result;
    } catch (e) {
      print('🔥 [AnalysisService] خطأ في جلب التحليل: $e');
      return null;
    } finally {
      print('🟡 [AnalysisService] ===== انتهاء جلب تحليل معين =====\n');
    }
  }

  // ============================================
  // ✅ جلب سجل التحاليل — مع Cache
  // ============================================
  static Future<List<UserAnalysisHistory>> getUserAnalysisHistory() async {
    print('\n🟡 [AnalysisService] ===== بدء جلب سجل التحاليل =====');

    try {
      final uid = _userId;
      final result = await CacheManager.instance
          .getOrFetch<List<UserAnalysisHistory>>(
        key: _historyCacheKey(uid),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/analysis/history',
            queryParams: {'user_id': uid},
          );

          print('📥 [AnalysisService] حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            var jsonData = json.decode(response.body);
            print('✅ [AnalysisService] تم تحويل JSON بنجاح');

            if (jsonData is List) {
              print('📊 [AnalysisService] عدد التحاليل: ${jsonData.length}');
              return jsonData.map((item) {
                try {
                  return UserAnalysisHistory.fromJson(item);
                } catch (e) {
                  print('❌ [AnalysisService] فشل في تحويل عنصر: $e');
                  rethrow;
                }
              }).toList();
            } else {
              print('❌ [AnalysisService] الاستجابة ليست قائمة');
              return <UserAnalysisHistory>[];
            }
          }
          return <UserAnalysisHistory>[];
        },
        ttl: const Duration(minutes: 5),
        staleWhileRevalidate: true,
      );
      return result ?? [];
    } catch (e) {
      print('🔥 [AnalysisService] خطأ في جلب السجل: $e');
      return [];
    } finally {
      print('🟡 [AnalysisService] ===== انتهاء جلب سجل التحاليل =====\n');
    }
  }

  // ============================================
  // ✅ أنواع التحاليل — مع Cache
  // ============================================
  static Future<List<AnalysisType>> getAnalysisTypes() async {
    print('\n🟡 [AnalysisService] ===== بدء جلب أنواع التحاليل =====');

    try {
      final result = await CacheManager.instance
          .getOrFetch<List<AnalysisType>>(
        key: _typesCacheKey(),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/analysis/types',
          );

          print('📥 [AnalysisService] حالة الاستجابة: ${response.statusCode}');

          if (response.statusCode == 200) {
            var jsonData = json.decode(response.body);
            print('✅ [AnalysisService] تم تحويل JSON بنجاح');

            if (jsonData is List) {
              print('📊 [AnalysisService] عدد الأنواع: ${jsonData.length}');
              return jsonData
                  .map((item) => AnalysisType.fromJson(item))
                  .toList();
            } else {
              print('❌ [AnalysisService] الاستجابة ليست قائمة');
              return <AnalysisType>[];
            }
          }
          return <AnalysisType>[];
        },
        ttl: const Duration(hours: 1), // أنواع التحاليل نادراً ما تتغير
        staleWhileRevalidate: true,
      );
      return result ?? [];
    } catch (e) {
      print('🔥 [AnalysisService] خطأ في جلب الأنواع: $e');
      return [];
    } finally {
      print('🟡 [AnalysisService] ===== انتهاء جلب أنواع التحاليل =====\n');
    }
  }
}

// ============================================
// ✅ محلل النصوص (Helper Class) — بدون تغيير
// ============================================
class AnalysisResultParser {
  static List<Map<String, dynamic>> parseExtractedText(String text) {
    print('\n🔍 [AnalysisResultParser] بدء تحليل النص المستخرج');
    List<Map<String, dynamic>> results = [];

    if (text.isEmpty) {
      print('⚠️ [AnalysisResultParser] النص فارغ');
      return results;
    }

    // أنماط البحث للمؤشرات الشائعة (عربي + إنجليزي)
    final patterns = {
      'الهيموجلوبين': RegExp(
        r'الهيموجلوبين[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'Hemoglobin': RegExp(
        r'Hemoglobin[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'HGB': RegExp(r'HGB[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),

      'السكر': RegExp(
        r'السكر[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'Glucose': RegExp(
        r'Glucose[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'FBS': RegExp(r'FBS[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),

      'الكوليسترول': RegExp(
        r'الكوليسترول[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'Cholesterol': RegExp(
        r'Cholesterol[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'CHOL': RegExp(
        r'CHOL[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),

      'HDL': RegExp(r'HDL[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),
      'LDL': RegExp(r'LDL[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),

      'الدهون الثلاثية': RegExp(
        r'الدهون الثلاثية[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'Triglycerides': RegExp(
        r'Triglycerides[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'TG': RegExp(r'TG[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),

      'WBC': RegExp(r'WBC[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),
      'RBC': RegExp(r'RBC[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),
      'PLT': RegExp(r'PLT[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),
      'Platelets': RegExp(
        r'Platelets[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),

      'ALT': RegExp(r'ALT[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),
      'AST': RegExp(r'AST[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),

      'Creatinine': RegExp(
        r'Creatinine[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'Cr': RegExp(r'Cr[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),
      'Urea': RegExp(
        r'Urea[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'BUN': RegExp(r'BUN[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),

      'TSH': RegExp(r'TSH[:\s]*([\d.]+)\s*([a-zA-Z/]+)', caseSensitive: false),
      'Vitamin D': RegExp(
        r'Vitamin D[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
      'Vitamin B12': RegExp(
        r'Vitamin B12[:\s]*([\d.]+)\s*([a-zA-Z/]+)',
        caseSensitive: false,
      ),
    };

    // المعدلات الطبيعية
    final normalRanges = {
      'الهيموجلوبين': {'min': 13.0, 'max': 17.0, 'unit': 'g/dL'},
      'Hemoglobin': {'min': 13.0, 'max': 17.0, 'unit': 'g/dL'},
      'HGB': {'min': 13.0, 'max': 17.0, 'unit': 'g/dL'},

      'السكر': {'min': 70, 'max': 140, 'unit': 'mg/dL'},
      'Glucose': {'min': 70, 'max': 140, 'unit': 'mg/dL'},
      'FBS': {'min': 70, 'max': 100, 'unit': 'mg/dL'},

      'الكوليسترول': {'max': 200, 'unit': 'mg/dL'},
      'Cholesterol': {'max': 200, 'unit': 'mg/dL'},
      'CHOL': {'max': 200, 'unit': 'mg/dL'},

      'HDL': {'min': 40, 'unit': 'mg/dL'},
      'LDL': {'max': 130, 'unit': 'mg/dL'},

      'الدهون الثلاثية': {'max': 150, 'unit': 'mg/dL'},
      'Triglycerides': {'max': 150, 'unit': 'mg/dL'},
      'TG': {'max': 150, 'unit': 'mg/dL'},

      'WBC': {'min': 4.0, 'max': 11.0, 'unit': 'ألف/ملم3'},
      'RBC': {'min': 4.5, 'max': 5.5, 'unit': 'مليون/ملم3'},
      'Platelets': {'min': 150, 'max': 450, 'unit': 'ألف/ملم3'},
      'PLT': {'min': 150, 'max': 450, 'unit': 'ألف/ملم3'},

      'ALT': {'max': 40, 'unit': 'U/L'},
      'AST': {'max': 40, 'unit': 'U/L'},

      'Creatinine': {'min': 0.6, 'max': 1.2, 'unit': 'mg/dL'},
      'Cr': {'min': 0.6, 'max': 1.2, 'unit': 'mg/dL'},
      'Urea': {'min': 7, 'max': 20, 'unit': 'mg/dL'},
      'BUN': {'min': 7, 'max': 20, 'unit': 'mg/dL'},

      'TSH': {'min': 0.4, 'max': 4.5, 'unit': 'mIU/L'},
      'Vitamin D': {'min': 30, 'max': 100, 'unit': 'ng/mL'},
      'Vitamin B12': {'min': 200, 'max': 900, 'unit': 'pg/mL'},
    };

    for (var entry in patterns.entries) {
      final match = entry.value.firstMatch(text);
      if (match != null) {
        try {
          final testName = entry.key;
          final value = double.tryParse(match.group(1) ?? '') ?? 0;
          final unit = match.group(2) ?? '';

          print('✅ [AnalysisResultParser] وجدت: $testName = $value $unit');

          // تحديد الحالة
          String status = 'normal';

          if (normalRanges.containsKey(testName)) {
            final range = normalRanges[testName]!;

            if (range.containsKey('min') && value < (range['min'] as num)) {
              status = 'low';
            } else if (range.containsKey('max') &&
                value > (range['max'] as num)) {
              status = 'high';
            }
          }

          results.add({
            'test_name': testName,
            'value': value,
            'unit': unit,
            'status': status,
          });
        } catch (e) {
          print('❌ [AnalysisResultParser] خطأ في تحليل ${entry.key}: $e');
        }
      }
    }

    print('📊 [AnalysisResultParser] تم استخراج ${results.length} نتيجة');
    return results;
  }
}

int min(int a, int b) => a < b ? a : b;
