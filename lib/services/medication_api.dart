// lib/services/medication_api.dart
// 🚀 مُعاد كتابتها باستخدام BaseApiService + CacheManager لتقليل استدعاءات API

import 'dart:convert';
import 'package:vita/models/medicine_model.dart';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';
import '../models/medication_model.dart';
import 'notification_service.dart';

class MedicationService {
  // ✅ لم نعد بحاجة إلى baseUrl مكرر - نستخدم BaseApiService

  // ============================================
  // 🏗️ مفاتيح الكاش
  // ============================================
  static String _medicationsCacheKey() => 'medications_list';
  static String _todayMedicationsCacheKey() => 'medications_today_list';
  static String _allDosesCacheKey() => 'medications_all_doses';
  static String _todayDosesCacheKey() => 'medications_today_doses';
  static String _upcomingDosesCacheKey() => 'medications_upcoming_doses';

  /// إبطال كل كاش الأدوية
  static void _invalidateAllMedicationCache() {
    CacheManager.instance.invalidatePattern('medications_');
  }

  // ============================================
  // 📦 1. APIs الأدوية العامة (Medicine Database)
  // ============================================

  static Future<List<Medicine>> searchMedicines(String query) async {
    try {
      final response = await BaseApiService.get(
        'medications/search-medicines',
        queryParams: {'q': query},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Medicine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في البحث: $e');
      return [];
    }
  }

  static Future<List<Medicine>> getAllMedicines() async {
    try {
      final response = await BaseApiService.get('medications/all-medicines');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => Medicine.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب الأدوية: $e');
      return [];
    }
  }

  static Future<Medicine?> getMedicineById(int id) async {
    try {
      final response = await BaseApiService.get('medications/get-medicine/$id');

      if (response.statusCode == 200) {
        return Medicine.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('🔥 خطأ في جلب الدواء: $e');
      return null;
    }
  }

  // ============================================
  // 💊 2. APIs أدوية المستخدم (User Medications)
  // ============================================

  static Future<List<UserMedication>> getMedications() async {
    try {
      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: _medicationsCacheKey(),
        fetch: () async {
          final response = await BaseApiService.get('medications/');
          if (response.statusCode == 200) {
            return json.decode(response.body) as List<dynamic>;
          }
          throw Exception('فشل في تحميل الأدوية: ${response.statusCode}');
        },
        ttl: const Duration(minutes: 3),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        return result.map((json) => UserMedication.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب الأدوية: $e');
      return [];
    }
  }

  static Future<UserMedication?> addMedication(
    Map<String, dynamic> medicationData,
  ) async {
    try {
      final response = await BaseApiService.post(
        'medications/',
        body: medicationData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // ✅ إبطال كاش الأدوية
        _invalidateAllMedicationCache();

        final Map<String, dynamic> jsonData = json.decode(response.body);
        final medication = UserMedication.fromJson(jsonData);

        await NotificationService.scheduleMedicationNotifications(medication);

        return medication;
      }
      return null;
    } catch (e) {
      print('🔥 خطأ: $e');
      return null;
    }
  }

  static Future<bool> deleteMedication(int id) async {
    try {
      final medications = await getMedications();
      final medication = medications.firstWhere(
        (med) => med.id == id,
        orElse: () => throw Exception('الدواء غير موجود'),
      );

      await NotificationService.cancelMedicationNotifications(medication);

      final response = await BaseApiService.delete('medications/$id');

      if (response.statusCode == 200) {
        _invalidateAllMedicationCache();
        return true;
      }
      return false;
    } catch (e) {
      print('🔥 خطأ في الحذف: $e');
      return false;
    }
  }

  static Future<List<UserMedication>> getTodaysMedications() async {
    try {
      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: _todayMedicationsCacheKey(),
        fetch: () async {
          final response = await BaseApiService.get('medications/today/list');
          if (response.statusCode == 200) {
            return json.decode(response.body) as List<dynamic>;
          }
          return <dynamic>[];
        },
        ttl: const Duration(minutes: 3),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        return result.map((json) => UserMedication.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ: $e');
      return [];
    }
  }

  // ============================================
  // 📅 3. APIs الجرعات (Doses)
  // ============================================

  static Future<List<MedicationDose>> getAllDoses() async {
    try {
      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: _allDosesCacheKey(),
        fetch: () async {
          final response = await BaseApiService.get('medications/doses/all');
          if (response.statusCode == 200) {
            return json.decode(response.body) as List<dynamic>;
          }
          return <dynamic>[];
        },
        ttl: const Duration(minutes: 3),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        return result.map((json) => MedicationDose.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب كل الجرعات: $e');
      return [];
    }
  }

  static Future<List<MedicationDose>> getTodayDoses() async {
    try {
      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: _todayDosesCacheKey(),
        fetch: () async {
          final response = await BaseApiService.get('medications/doses/today');
          if (response.statusCode == 200) {
            return json.decode(response.body) as List<dynamic>;
          }
          return <dynamic>[];
        },
        ttl: const Duration(minutes: 2),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        return result.map((json) => MedicationDose.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب جرعات اليوم: $e');
      return [];
    }
  }

  static Future<List<MedicationDose>> getUpcomingDoses() async {
    try {
      final result = await CacheManager.instance.getOrFetch<List<dynamic>>(
        key: _upcomingDosesCacheKey(),
        fetch: () async {
          final response = await BaseApiService.get(
            'medications/doses/upcoming',
          );
          if (response.statusCode == 200) {
            return json.decode(response.body) as List<dynamic>;
          }
          return <dynamic>[];
        },
        ttl: const Duration(minutes: 2),
        staleWhileRevalidate: true,
      );

      if (result != null) {
        return result.map((json) => MedicationDose.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('🔥 خطأ في جلب الجرعات القادمة: $e');
      return [];
    }
  }

  // ============================================
  // ✅ 4. APIs تسجيل تناول الجرعات
  // ============================================

  static Future<Map<String, dynamic>> markDoseAsTaken(
    String medicationId,
  ) async {
    try {
      final response = await BaseApiService.post(
        'medications/$medicationId/take',
        body: {
          'medication_id': int.parse(medicationId),
          'taken_time': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        // ✅ إبطال كاش الجرعات بعد التسجيل
        CacheManager.instance.invalidate(_todayDosesCacheKey());
        CacheManager.instance.invalidate(_upcomingDosesCacheKey());
        CacheManager.instance.invalidate(_allDosesCacheKey());

        try {
          final medication = await getMedicineById(int.parse(medicationId));
          if (medication != null) {
            final med = await getMedications().then(
              (list) =>
                  list.firstWhere((m) => m.medicineInfo?.id == medication.id),
            );

            int medicationIdHash;
            if (med.id is int) {
              medicationIdHash = med.id as int;
            } else {
              medicationIdHash = int.parse(med.id.toString());
            }

            final now = DateTime.now();

            for (int i = 0; i < med.times.length; i++) {
              final timeParts = med.times[i].split(':');
              final hour = int.parse(timeParts[0]);

              if (hour == now.hour) {
                await NotificationService.cancelNotification(
                  medicationIdHash * 100 + i * 10 + 2,
                );
              }
            }
          }
        } catch (e) {
          print('⚠️ خطأ في إلغاء الإشعارات: $e');
        }

        return result;
      } else {
        return {'success': false, 'message': 'فشل في تسجيل الجرعة'};
      }
    } catch (e) {
      print('🔥 خطأ في تسجيل الجرعة: $e');
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  static Future<Map<String, dynamic>> updateMissedDoses() async {
    try {
      final response = await BaseApiService.post(
        'medications/doses/update-missed',
      );

      if (response.statusCode == 200) {
        _invalidateAllMedicationCache();
        final data = json.decode(response.body);
        return {'success': true, ...data};
      } else {
        return {'success': false, 'message': 'فشل في التحديث'};
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {'success': false, 'message': 'خطأ في الاتصال'};
    }
  }

  static Future<void> rescheduleAllNotifications() async {
    try {
      final medications = await getMedications();

      for (var med in medications) {
        await NotificationService.scheduleMedicationNotifications(med);
      }
      print('✅ تم إعادة جدولة كل الإشعارات');
    } catch (e) {
      print('🔥 خطأ في إعادة جدولة الإشعارات: $e');
    }
  }
}
