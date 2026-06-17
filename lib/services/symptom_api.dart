// lib/services/symptom_api.dart

import 'dart:convert';
import 'package:vita/utils/prefs_helper.dart';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import '../models/symptom_model.dart';

class SymptomService {
  // دالة مساعدة لتحويل أي نوع إلى List<String>
  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      try {
        final decoded = json.decode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return [value];
    }
    return [];
  }

  // ============================================
  // 🏷️ Cache Keys
  // ============================================
  static String _symptomsCacheKey(int uid, String params) =>
      'symptoms_list_${uid}_$params';
  static String _symptomByIdCacheKey(int uid, int id) => 'symptom_${uid}_$id';
  static String _statsCacheKey(int uid, int days) =>
      'symptom_stats_${uid}_${days}days';
  static String _timelineCacheKey(int uid) => 'symptom_timeline_$uid';

  /// مسح جميع كاش الأعراض لهذا المستخدم
  static void _invalidateAllSymptomCache() {
    CacheManager.instance.invalidatePattern('symptom_');
  }

  // ============================================
  // ✅ 1. جلب كل الأعراض
  // ============================================
  static Future<List<Symptom>> getSymptoms({
    int limit = 50,
    int skip = 0,
    String? severity,
    DateTime? fromDate,
    DateTime? toDate,
    bool forceRefresh = false, // ✅ إضافة parameter للإجبار على التحديث
  }) async {
    print('\n🟡 [SymptomService] ===== جلب الأعراض =====');

    try {
      final userId = PrefsHelper.getUserId();
      final uid = userId ?? 1;

      // بناء parameters
      final parameters = <String, String>{
        'user_id': uid.toString(),
        'limit': limit.toString(),
        'skip': skip.toString(),
      };

      if (severity != null) {
        parameters['severity'] = severity;
      }
      if (fromDate != null) {
        parameters['from_date'] =
            '${fromDate.year}-${fromDate.month}-${fromDate.day}';
      }
      if (toDate != null) {
        parameters['to_date'] = '${toDate.year}-${toDate.month}-${toDate.day}';
      }

      // Cache key based on params
      final paramsKey =
          'l${limit}_s${skip}_sev${severity ?? ''}_f${fromDate?.toIso8601String() ?? ''}_t${toDate?.toIso8601String() ?? ''}';

      // ✅ إبطال الكاش إذا كان forceRefresh
      if (forceRefresh) {
        final cacheKey = _symptomsCacheKey(uid, paramsKey);
        print(
          '🔄 [SymptomService] Force refresh — invalidating cache: $cacheKey',
        );
        CacheManager.instance.invalidate(cacheKey);
      }

      final result = await CacheManager.instance.getOrFetch<List<Symptom>>(
        key: _symptomsCacheKey(uid, paramsKey),
        fetch: () async {
          final response = await BaseApiService.get(
            'api/symptoms/',
            queryParams: parameters,
          );

          if (response.statusCode == 200) {
            final List<dynamic> jsonData = json.decode(response.body);
            print('✅ [SymptomService] تم جلب ${jsonData.length} عرض');

            final symptoms = jsonData
                .map((json) {
                  try {
                    return Symptom.fromJson(json);
                  } catch (e) {
                    print('⚠️ [SymptomService] خطأ في تحويل عنصر: $e');
                    return null;
                  }
                })
                .whereType<Symptom>()
                .toList();

            return symptoms;
          } else {
            print(
              '❌ [SymptomService] فشل في جلب الأعراض: ${response.statusCode}',
            );
            return <Symptom>[];
          }
        },
        ttl: const Duration(minutes: 3),
        staleWhileRevalidate: true,
      );

      return result ?? [];
    } catch (e) {
      print('🔥 [SymptomService] خطأ في جلب الأعراض: $e');
      return [];
    } finally {
      print('🟡 [SymptomService] ===== انتهاء جلب الأعراض =====\n');
    }
  }

  // ============================================
  // ✅ 2. جلب عرض معين بالـ ID
  // ============================================
  static Future<Symptom?> getSymptomById(int id) async {
    print('\n🟡 [SymptomService] ===== جلب عرض بالـ ID =====');
    print('🔍 [SymptomService] ID: $id');

    try {
      final userId = PrefsHelper.getUserId();
      final uid = userId ?? 1;

      final result = await CacheManager.instance.getOrFetch<Symptom>(
        key: _symptomByIdCacheKey(uid, id),
        fetch: () async {
          final response = await BaseApiService.get('api/symptoms/$id');

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            print('✅ [SymptomService] تم جلب العرض بنجاح');
            return Symptom.fromJson(jsonData);
          } else if (response.statusCode == 404) {
            print('❌ [SymptomService] العرض غير موجود');
            return null;
          } else {
            print(
              '❌ [SymptomService] فشل في جلب العرض: ${response.statusCode}',
            );
            return null;
          }
        },
        ttl: const Duration(minutes: 5),
        staleWhileRevalidate: true,
      );

      return result;
    } catch (e) {
      print('🔥 [SymptomService] خطأ في جلب العرض: $e');
      return null;
    } finally {
      print('🟡 [SymptomService] ===== انتهاء جلب العرض =====\n');
    }
  }

  // ============================================
  // ✅ 3. إضافة عرض جديد
  // ============================================
  static Future<Map<String, dynamic>> addSymptom(
    Map<String, dynamic> data,
  ) async {
    print('\n🟡 [SymptomService] ===== إضافة عرض جديد =====');

    try {
      final userId = PrefsHelper.getUserId();
      print('📦 [SymptomService] البيانات: $data');

      final requestData = {'user_id': userId ?? 1, ...data};

      final response = await BaseApiService.post(
        'api/symptoms/',
        body: requestData,
      );

      print('📥 [SymptomService] حالة الاستجابة: ${response.statusCode}');
      print('📄 [SymptomService] محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ [SymptomService] تم إضافة العرض بنجاح');
        _invalidateAllSymptomCache();

        return {
          'success': true,
          'data': Symptom.fromJson(jsonData),
          'message': 'تم إضافة العرض بنجاح',
        };
      } else {
        String errorMessage = 'فشل في إضافة العرض';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['detail'] ?? errorMessage;
        } catch (_) {}

        print('❌ [SymptomService] $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('🔥 [SymptomService] خطأ في إضافة العرض: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    } finally {
      print('🟡 [SymptomService] ===== انتهاء إضافة العرض =====\n');
    }
  }

  // ============================================
  // ✅ 4. تحديث عرض
  // ============================================
  static Future<Map<String, dynamic>> updateSymptom(
    int id,
    Map<String, dynamic> data,
  ) async {
    print('\n🟡 [SymptomService] ===== تحديث عرض =====');
    print('🔍 [SymptomService] ID: $id');

    try {
      final response = await BaseApiService.put('api/symptoms/$id', body: data);

      print('📥 [SymptomService] حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ [SymptomService] تم تحديث العرض بنجاح');
        _invalidateAllSymptomCache();

        return {
          'success': true,
          'data': Symptom.fromJson(jsonData),
          'message': 'تم تحديث العرض بنجاح',
        };
      } else if (response.statusCode == 404) {
        print('❌ [SymptomService] العرض غير موجود');
        return {'success': false, 'message': 'العرض غير موجود'};
      } else {
        print('❌ [SymptomService] فشل في تحديث العرض');
        return {'success': false, 'message': 'فشل في تحديث العرض'};
      }
    } catch (e) {
      print('🔥 [SymptomService] خطأ في تحديث العرض: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    } finally {
      print('🟡 [SymptomService] ===== انتهاء تحديث العرض =====\n');
    }
  }

  // ============================================
  // ✅ 5. حذف عرض
  // ============================================
  static Future<Map<String, dynamic>> deleteSymptom(int id) async {
    print('\n🟡 [SymptomService] ===== حذف عرض =====');
    print('🔍 [SymptomService] ID: $id');

    try {
      final response = await BaseApiService.delete('api/symptoms/$id');

      print('📥 [SymptomService] حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ [SymptomService] تم حذف العرض بنجاح');
        _invalidateAllSymptomCache();

        return {
          'success': true,
          'message': jsonData['message'] ?? 'تم حذف العرض بنجاح',
          'id': jsonData['id'],
        };
      } else if (response.statusCode == 404) {
        print('❌ [SymptomService] العرض غير موجود');
        return {'success': false, 'message': 'العرض غير موجود'};
      } else {
        print('❌ [SymptomService] فشل في حذف العرض');
        return {'success': false, 'message': 'فشل في حذف العرض'};
      }
    } catch (e) {
      print('🔥 [SymptomService] خطأ في حذف العرض: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    } finally {
      print('🟡 [SymptomService] ===== انتهاء حذف العرض =====\n');
    }
  }

  // ============================================
  // ✅ 6. تحليل العرض من قاعدة البيانات
  // ============================================
  static Future<Map<String, dynamic>> analyzeSymptom(
    Map<String, dynamic> data,
  ) async {
    print('\n🟡 [SymptomService] ===== تحليل عرض =====');

    try {
      final userId = PrefsHelper.getUserId();
      print('📦 [SymptomService] البيانات: $data');

      final requestData = {...data, 'user_id': userId ?? 1};

      final response = await BaseApiService.post(
        'api/symptoms/analyze',
        body: requestData,
      );

      print('📥 [SymptomService] حالة الاستجابة: ${response.statusCode}');
      print('📄 [SymptomService] محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ [SymptomService] تم تحليل العرض بنجاح');

        return {
          'success': true,
          'analysis': jsonData['analysis'] ?? 'لا يوجد تحليل',
          'possible_causes': _toStringList(jsonData['possible_causes']),
          'suggested_actions': _toStringList(jsonData['suggested_actions']),
          'warning_signs': _toStringList(jsonData['warning_signs']),
          'food_recommendations': jsonData['food_recommendations'] ?? {},
        };
      } else {
        print('❌ [SymptomService] فشل في تحليل العرض');
        return {'success': false, 'message': 'فشل في تحليل العرض'};
      }
    } catch (e) {
      print('🔥 [SymptomService] خطأ في تحليل العرض: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    } finally {
      print('🟡 [SymptomService] ===== انتهاء تحليل العرض =====\n');
    }
  }

  // ============================================
  // ✅ 7. جلب تأثير الأعراض على المشي والسعرات
  // ============================================
  static Future<Map<String, dynamic>> getSymptomImpact(
    String symptomName,
    String severity,
  ) async {
    print('\n🟡 [SymptomService] جلب تأثير العرض على المشي');

    try {
      final response = await BaseApiService.get(
        'api/symptoms/impact',
        queryParams: {'symptom': symptomName, 'severity': severity},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'impact_on_steps': data['impact_on_steps'] ?? 0,
          'calories_adjustment': data['calories_adjustment'] ?? 0,
          'description': data['description'] ?? '',
        };
      }
      return {'success': false, 'impact_on_steps': 0, 'calories_adjustment': 0};
    } catch (e) {
      print('🔥 خطأ في جلب تأثير العرض: $e');
      return {'success': false, 'impact_on_steps': 0, 'calories_adjustment': 0};
    }
  }

  // ============================================
  // ✅ 8. جلب تأثير الأدوية على المشي
  // ============================================
  static Future<Map<String, dynamic>> getMedicineImpact(int medicineId) async {
    print('\n🟡 [SymptomService] جلب تأثير الدواء على المشي');
    print('💊 medicine_id: $medicineId');

    try {
      final response = await BaseApiService.get(
        'api/symptoms/medicine-impact',
        queryParams: {'medicine_id': medicineId.toString()},
      );

      print('📥 [SymptomService] حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [SymptomService] تم جلب تأثير الدواء بنجاح');

        return {
          'success': true,
          'impact_on_steps': data['impact_on_steps'] ?? 0,
          'calories_adjustment': data['calories_adjustment'] ?? 0,
          'description': data['description'] ?? '',
          'foods_to_avoid': _toStringList(data['foods_to_avoid']),
          'foods_to_eat': _toStringList(data['foods_to_eat']),
          'drinks_to_avoid': _toStringList(data['drinks_to_avoid']),
          'drinks_recommended': _toStringList(data['drinks_recommended']),
          'timing_instructions': data['timing_instructions'] ?? '',
          'general_tips': data['general_tips'] ?? '',
        };
      } else if (response.statusCode == 404) {
        print('⚠️ [SymptomService] الدواء غير موجود');
        return {
          'success': false,
          'impact_on_steps': 0,
          'calories_adjustment': 0,
          'message': 'الدواء غير موجود',
        };
      } else {
        print('❌ [SymptomService] فشل في جلب تأثير الدواء');
        return {
          'success': false,
          'impact_on_steps': 0,
          'calories_adjustment': 0,
          'message': 'فشل في جلب تأثير الدواء',
        };
      }
    } catch (e) {
      print('🔥 [SymptomService] خطأ في جلب تأثير الدواء: $e');
      return {
        'success': false,
        'impact_on_steps': 0,
        'calories_adjustment': 0,
        'message': 'خطأ في الاتصال: $e',
      };
    }
  }

  // ============================================
  // ✅ 9. جلب إحصائيات الأعراض
  // ============================================
  static Future<Map<String, dynamic>> getSymptomsStats({int days = 30}) async {
    print('\n🟡 [SymptomService] ===== جلب إحصائيات الأعراض =====');

    try {
      final userId = PrefsHelper.getUserId();
      final uid = userId ?? 1;

      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _statsCacheKey(uid, days),
            fetch: () async {
              final response = await BaseApiService.get(
                'api/symptoms/stats/summary',
                queryParams: {
                  'user_id': uid.toString(),
                  'days': days.toString(),
                },
              );

              if (response.statusCode == 200) {
                final jsonData = json.decode(response.body);
                print('✅ [SymptomService] تم جلب الإحصائيات بنجاح');

                return {
                  'success': true,
                  'total_symptoms': jsonData['total_symptoms'] ?? 0,
                  'severity_distribution':
                      jsonData['severity_distribution'] ?? {},
                  'most_frequent': jsonData['most_frequent'] ?? [],
                  'period_days': jsonData['period_days'] ?? days,
                };
              } else {
                print('❌ [SymptomService] فشل في جلب الإحصائيات');
                return {'success': false, 'message': 'فشل في جلب الإحصائيات'};
              }
            },
            ttl: const Duration(minutes: 10),
            staleWhileRevalidate: true,
          );

      return result ?? {'success': false, 'message': 'لا توجد بيانات'};
    } catch (e) {
      print('🔥 [SymptomService] خطأ في جلب الإحصائيات: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    } finally {
      print('🟡 [SymptomService] ===== انتهاء جلب الإحصائيات =====\n');
    }
  }

  // ============================================
  // ✅ 10. جلب توزيع الأعراض حسب الوقت
  // ============================================
  static Future<Map<String, dynamic>> getSymptomsTimeline() async {
    print('\n🟡 [SymptomService] ===== جلب توزيع الأعراض =====');

    try {
      final userId = PrefsHelper.getUserId();
      final uid = userId ?? 1;

      final result = await CacheManager.instance
          .getOrFetch<Map<String, dynamic>>(
            key: _timelineCacheKey(uid),
            fetch: () async {
              final response = await BaseApiService.get(
                'api/symptoms/stats/timeline',
                queryParams: {'user_id': uid.toString()},
              );

              if (response.statusCode == 200) {
                final jsonData = json.decode(response.body);
                print('✅ [SymptomService] تم جلب التوزيع بنجاح');

                return {'success': true, 'timeline': jsonData};
              } else {
                print('❌ [SymptomService] فشل في جلب التوزيع');
                return {'success': false, 'message': 'فشل في جلب التوزيع'};
              }
            },
            ttl: const Duration(minutes: 10),
            staleWhileRevalidate: true,
          );

      return result ?? {'success': false, 'message': 'لا توجد بيانات'};
    } catch (e) {
      print('🔥 [SymptomService] خطأ في جلب التوزيع: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    } finally {
      print('🟡 [SymptomService] ===== انتهاء جلب التوزيع =====\n');
    }
  }

  // ============================================
  // ✅ 11. البحث عن الأعراض
  // ============================================
  static Future<List<Symptom>> searchSymptoms(String query) async {
    print('\n🟡 [SymptomService] ===== بحث عن أعراض =====');
    print('🔍 [SymptomService] كلمة البحث: $query');

    try {
      final allSymptoms = await getSymptoms(limit: 100);

      final results = allSymptoms.where((symptom) {
        return symptom.name.contains(query) ||
            (symptom.notes?.contains(query) ?? false);
      }).toList();

      print('✅ [SymptomService] تم العثور على ${results.length} نتيجة');
      return results;
    } catch (e) {
      print('🔥 [SymptomService] خطأ في البحث: $e');
      return [];
    } finally {
      print('🟡 [SymptomService] ===== انتهاء البحث =====\n');
    }
  }

  // ============================================
  // ✅ 12. جلب نصائح لأعراض معينة
  // ============================================
  static Future<Map<String, dynamic>> getSymptomTips(
    String symptomName,
    String severity,
  ) async {
    print('\n🟡 [SymptomService] ===== جلب نصائح لعرض =====');
    print('🔍 [SymptomService] العرض: $symptomName, الشدة: $severity');

    try {
      final userId = PrefsHelper.getUserId();
      final response = await BaseApiService.get(
        'api/symptoms/tips',
        queryParams: {
          'user_id': (userId ?? 1).toString(),
          'symptom': symptomName,
          'severity': severity,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ [SymptomService] تم جلب النصائح بنجاح');

        return {
          'success': true,
          'tips': jsonData['tips'] ?? [],
          'when_to_see_doctor': jsonData['when_to_see_doctor'] ?? [],
          'home_remedies': jsonData['home_remedies'] ?? [],
        };
      } else {
        print('❌ [SymptomService] فشل في جلب النصائح');
        return {'success': false, 'message': 'فشل في جلب النصائح'};
      }
    } catch (e) {
      print('🔥 [SymptomService] خطأ في جلب النصائح: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    } finally {
      print('🟡 [SymptomService] ===== انتهاء جلب النصائح =====\n');
    }
  }

  // ============================================
  // ✅ 13. حذف عدة أعراض دفعة واحدة
  // ============================================
  static Future<Map<String, dynamic>> deleteMultipleSymptoms(
    List<int> ids,
  ) async {
    print('\n🟡 [SymptomService] ===== حذف عدة أعراض =====');
    print('🔍 [SymptomService] IDs: $ids');

    try {
      int successCount = 0;
      int failCount = 0;

      for (int id in ids) {
        final result = await deleteSymptom(id);
        if (result['success'] == true) {
          successCount++;
        } else {
          failCount++;
        }
      }

      print('✅ [SymptomService] تم حذف $successCount أعراض بنجاح');
      if (failCount > 0) {
        print('⚠️ [SymptomService] فشل حذف $failCount أعراض');
      }

      return {
        'success': successCount > 0,
        'success_count': successCount,
        'fail_count': failCount,
        'message': 'تم حذف $successCount من أصل ${ids.length} أعراض',
      };
    } catch (e) {
      print('🔥 [SymptomService] خطأ في الحذف المتعدد: $e');
      return {'success': false, 'message': 'خطأ في الاتصال: $e'};
    } finally {
      print('🟡 [SymptomService] ===== انتهاء الحذف المتعدد =====\n');
    }
  }

  // ============================================
  // ✅ 14. تصدير الأعراض كـ JSON
  // ============================================
  static Future<Map<String, dynamic>> exportSymptoms() async {
    print('\n🟡 [SymptomService] ===== تصدير الأعراض =====');

    try {
      final symptoms = await getSymptoms(limit: 1000);
      final userId = PrefsHelper.getUserId();

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'total_count': symptoms.length,
        'symptoms': symptoms.map((s) => s.toJson()).toList(),
      };

      print('✅ [SymptomService] تم تصدير ${symptoms.length} عرض');

      return {
        'success': true,
        'data': exportData,
        'message': 'تم تصدير ${symptoms.length} عرض بنجاح',
      };
    } catch (e) {
      print('🔥 [SymptomService] خطأ في التصدير: $e');
      return {'success': false, 'message': 'خطأ في التصدير: $e'};
    } finally {
      print('🟡 [SymptomService] ===== انتهاء التصدير =====\n');
    }
  }

  // ============================================
  // ✅ 15. الحصول على الأعراض حسب التاريخ
  // ============================================
  static Future<List<Symptom>> getSymptomsByDate(DateTime date) async {
    print('\n🟡 [SymptomService] ===== جلب أعراض حسب التاريخ =====');
    print('📅 [SymptomService] التاريخ: $date');

    try {
      final allSymptoms = await getSymptoms();

      final filtered = allSymptoms.where((symptom) {
        return symptom.dateTime.year == date.year &&
            symptom.dateTime.month == date.month &&
            symptom.dateTime.day == date.day;
      }).toList();

      print('✅ [SymptomService] تم العثور على ${filtered.length} عرض');
      return filtered;
    } catch (e) {
      print('🔥 [SymptomService] خطأ: $e');
      return [];
    } finally {
      print('🟡 [SymptomService] ===== انتهاء =====\n');
    }
  }
}
