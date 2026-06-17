// lib/services/sync_service.dart

import 'dart:async';
import 'package:vita/services/medication_api.dart';
import 'package:vita/services/notification_service.dart';
import 'package:vita/utils/prefs_helper.dart';

class SyncService {
  static Timer? _syncTimer;
  static Timer? _waterCheckTimer;

  // ✅ بدء المزامنة الدورية
  static Future<void> startPeriodicSync() async {
    print('🔄 [SyncService] بدء المزامنة الدورية...');

    // مزامنة كل 6 ساعات
    _syncTimer = Timer.periodic(const Duration(hours: 6), (timer) async {
      print('🔄 [SyncService] مزامنة دورية مع الـ Backend...');
      await _syncAll();
    });

    // التحقق من الماء كل ساعة (بين 8 صباحاً و 10 مساءً)
    _waterCheckTimer = Timer.periodic(const Duration(hours: 1), (timer) async {
      final now = DateTime.now();
      if (now.hour >= 8 && now.hour <= 22) {
        await NotificationService.checkAndSendWaterReminder();
      }
    });

    print('✅ [SyncService] تم بدء المزامنة الدورية');
  }

  // ✅ مزامنة كل شيء
  static Future<void> _syncAll() async {
    try {
      // 1. مزامنة الإشعارات مع الـ Backend
      await NotificationService.syncScheduledNotificationsWithBackend();

      // 2. مزامنة الأدوية
      await _syncMedications();

      // 3. فحص الجرعات الفائتة
      await _checkMissedDoses();

      print('✅ [SyncService] اكتملت المزامنة الدورية');
    } catch (e) {
      print('❌ [SyncService] خطأ في المزامنة الدورية: $e');
    }
  }

  // ✅ مزامنة الأدوية
  static Future<void> _syncMedications() async {
    try {
      final medications = await MedicationService.getMedications();
      if (medications != null && medications.isNotEmpty) {
        await NotificationService.rescheduleAllNotifications(medications);
        print('✅ [SyncService] تمت مزامنة ${medications.length} دواء');
      }
    } catch (e) {
      print('❌ [SyncService] خطأ في مزامنة الأدوية: $e');
    }
  }

  // ✅ فحص الجرعات الفائتة
  static Future<void> _checkMissedDoses() async {
    try {
      await MedicationService.updateMissedDoses();
      print('✅ [SyncService] تم فحص الجرعات الفائتة');
    } catch (e) {
      print('❌ [SyncService] خطأ في فحص الجرعات الفائتة: $e');
    }
  }

  // ✅ مزامنة فورية عند فتح التطبيق
  static Future<void> syncOnAppStart() async {
    print('🔄 [SyncService] مزامنة عند بدء التطبيق...');

    try {
      // 1. فحص الجرعات الفائتة (مع timeout)
      await MedicationService.updateMissedDoses().timeout(
        const Duration(seconds: 5),
      );
      print('✅ [SyncService] تم فحص الجرعات الفائتة');

      // 2. مزامنة الإشعارات مع الـ Backend (مع timeout)
      await NotificationService.syncScheduledNotificationsWithBackend().timeout(
        const Duration(seconds: 5),
      );
      print('✅ [SyncService] تمت مزامنة الإشعارات');

      // 3. مزامنة الأدوية وإعادة جدولة الإشعارات (مع timeout)
      final medications = await MedicationService.getMedications().timeout(
        const Duration(seconds: 5),
      );
      if (medications != null && medications.isNotEmpty) {
        await NotificationService.rescheduleAllNotifications(
          medications,
        ).timeout(const Duration(seconds: 10));
        print(
          '✅ [SyncService] تمت مزامنة ${medications.length} دواء وإعادة جدولة الإشعارات',
        );
      }

      // 4. تنظيف الإشعارات القديمة (مرة في الأسبوع) (مع timeout)
      final lastCleanup = await PrefsHelper.getLastCleanupDate().timeout(
        const Duration(seconds: 3),
      );
      final now = DateTime.now();
      if (lastCleanup == null ||
          now.difference(lastCleanup) > const Duration(days: 7)) {
        await NotificationService.cleanupOldNotifications().timeout(
          const Duration(seconds: 10),
        );
        await PrefsHelper.setLastCleanupDate(now);
        print('✅ [SyncService] تم تنظيف الإشعارات القديمة');
      }

      print('✅ [SyncService] اكتملت المزامنة عند بدء التطبيق');
    } on TimeoutException {
      print('⚠️ [SyncService] تجاوزت المزامنة عند بدء التطبيق المهلة الزمنية');
    } catch (e) {
      print('❌ [SyncService] خطأ في المزامنة عند بدء التطبيق: $e');
    }
  }

  // ✅ مزامنة الماء فقط (تستخدم عند تسجيل شرب ماء)
  static Future<void> syncWaterOnly() async {
    try {
      await NotificationService.checkAndSendWaterReminder();
      print('✅ [SyncService] تمت مزامنة الماء');
    } catch (e) {
      print('❌ [SyncService] خطأ في مزامنة الماء: $e');
    }
  }

  // ✅ إيقاف المزامنة
  static void stopPeriodicSync() {
    _syncTimer?.cancel();
    _waterCheckTimer?.cancel();
    _syncTimer = null;
    _waterCheckTimer = null;
    print('✅ [SyncService] تم إيقاف المزامنة الدورية');
  }

  // ✅ التحقق من حالة المزامنة
  static bool isSyncRunning() {
    return _syncTimer != null && _syncTimer!.isActive;
  }
}
