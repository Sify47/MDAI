// lib/services/smart_meal_reminder_service.dart
/// 🧠 خدمة التذكيرات الذكية للوجبات
///
/// تقوم بجدولة تذكيرات يومية في أوقات الوجبات الرئيسية،
/// وتتحقق مما إذا تم تسجيل الوجبة فعلياً قبل إرسال التذكير.
///
/// أوقات التذكير:
/// - فطور (Breakfast): 6:00-9:00 ← تذكير الساعة 10:00 إذا لم يتم تسجيلها
/// - غداء (Lunch): 12:00-15:00 ← تذكير الساعة 15:30 إذا لم يتم تسجيلها
/// - عشاء (Dinner): 18:00-21:00 ← تذكير الساعة 21:30 إذا لم يتم تسجيلها
/// - سناك (Snack): تذكير الساعة 17:00

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:vita/services/nutrition_api.dart';
import 'package:vita/services/notification_service.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'package:vita/widgets/nutrition/meal_helpers.dart';

class SmartMealReminderService {
  static final SmartMealReminderService _instance =
      SmartMealReminderService._internal();
  factory SmartMealReminderService() => _instance;
  SmartMealReminderService._internal();

  /// مفاتيح التخزين في SharedPreferences
  static const String _keyEnabled = 'smart_meal_reminder_enabled';
  static const String _keyRemindBreakfast = 'smart_remind_breakfast';
  static const String _keyRemindLunch = 'smart_remind_lunch';
  static const String _keyRemindDinner = 'smart_remind_dinner';
  static const String _keyRemindSnack = 'smart_remind_snack';
  static const String _keyLastRemindedDate = 'smart_meal_last_reminded_date';

  /// معرفات الإشعارات الفريدة
  static const int _notifBreakfast = 40001;
  static const int _notifLunch = 40002;
  static const int _notifDinner = 40003;
  static const int _notifSnack = 40004;

  // ============================================
  // ✅ إعدادات التذكيرات
  // ============================================

  /// هل التذكيرات الذكية مفعلة
  static Future<bool> isEnabled() async =>
      await PrefsHelper.getBool(_keyEnabled) ?? true;

  static Future<void> setEnabled(bool value) async {
    await PrefsHelper.setBool(_keyEnabled, value);
  }

  /// تذكير الفطور
  static Future<bool> shouldRemindBreakfast() async =>
      await PrefsHelper.getBool(_keyRemindBreakfast) ?? true;
  static Future<void> setRemindBreakfast(bool value) async {
    await PrefsHelper.setBool(_keyRemindBreakfast, value);
  }

  /// تذكير الغداء
  static Future<bool> shouldRemindLunch() async =>
      await PrefsHelper.getBool(_keyRemindLunch) ?? true;
  static Future<void> setRemindLunch(bool value) async {
    await PrefsHelper.setBool(_keyRemindLunch, value);
  }

  /// تذكير العشاء
  static Future<bool> shouldRemindDinner() async =>
      await PrefsHelper.getBool(_keyRemindDinner) ?? true;
  static Future<void> setRemindDinner(bool value) async {
    await PrefsHelper.setBool(_keyRemindDinner, value);
  }

  /// تذكير السناك
  static Future<bool> shouldRemindSnack() async =>
      await PrefsHelper.getBool(_keyRemindSnack) ?? true;
  static Future<void> setRemindSnack(bool value) async {
    await PrefsHelper.setBool(_keyRemindSnack, value);
  }

  // ============================================
  // ✅ جدولة التذكيرات اليومية
  // ============================================

  /// جدولة جميع تذكيرات الوجبات الذكية
  static Future<void> scheduleAllMealReminders() async {
    if (!await isEnabled()) {
      debugPrint('🧠 [SmartMealReminder] التذكيرات الذكية معطلة');
      return;
    }

    debugPrint('🧠 [SmartMealReminder] جدولة تذكيرات الوجبات الذكية...');

    // تذكير الفطور - الساعة 10:00 صباحاً
    if (await shouldRemindBreakfast()) {
      await NotificationService.scheduleDailyNotification(
        id: _notifBreakfast,
        title: '🌅 تذكير بالفطور',
        body: 'لم تسجل وجبة الفطور بعد! اختر وجبة فطور صحية لبداية نشيطة.',
        type: 'meal_reminder',
        subtype: 'breakfast',
        hour: 10,
        minute: 0,
        channelKey: NotificationService.channelMealReminders,
        actionButtons: [
          NotificationActionButton(
            key: 'LOG_BREAKFAST',
            label: '🍽️ تسجيل الفطور',
            color: const Color(0xFF2196F3),
          ),
          NotificationActionButton(
            key: 'SNOOZE_MEAL',
            label: '⏰ لاحقاً',
            color: Colors.grey,
          ),
        ],
        payload: {'type': 'meal_reminder', 'meal_type': 'فطور'},
      );
    }

    // تذكير الغداء - الساعة 3:30 مساءً
    if (await shouldRemindLunch()) {
      await NotificationService.scheduleDailyNotification(
        id: _notifLunch,
        title: '☀️ تذكير بالغداء',
        body: 'لم تسجل وجبة الغداء بعد! تناول وجبة متوازنة للحفاظ على نشاطك.',
        type: 'meal_reminder',
        subtype: 'lunch',
        hour: 15,
        minute: 30,
        channelKey: NotificationService.channelMealReminders,
        actionButtons: [
          NotificationActionButton(
            key: 'LOG_LUNCH',
            label: '🍽️ تسجيل الغداء',
            color: const Color(0xFF4CAF50),
          ),
          NotificationActionButton(
            key: 'SNOOZE_MEAL',
            label: '⏰ لاحقاً',
            color: Colors.grey,
          ),
        ],
        payload: {'type': 'meal_reminder', 'meal_type': 'غداء'},
      );
    }

    // تذكير السناك - الساعة 5:00 مساءً
    if (await shouldRemindSnack()) {
      await NotificationService.scheduleDailyNotification(
        id: _notifSnack,
        title: '🍎 تذكير بسناك صحي',
        body: 'وجبة خفيفة صحية بين الوجبات تساعد على تنظيم السكر والطاقة.',
        type: 'meal_reminder',
        subtype: 'snack',
        hour: 17,
        minute: 0,
        channelKey: NotificationService.channelMealReminders,
        actionButtons: [
          NotificationActionButton(
            key: 'LOG_SNACK',
            label: '🍎 تسجيل السناك',
            color: const Color(0xFFFF9800),
          ),
          NotificationActionButton(
            key: 'SNOOZE_MEAL',
            label: '⏰ لاحقاً',
            color: Colors.grey,
          ),
        ],
        payload: {'type': 'meal_reminder', 'meal_type': 'سناك'},
      );
    }

    // تذكير العشاء - الساعة 9:30 مساءً
    if (await shouldRemindDinner()) {
      await NotificationService.scheduleDailyNotification(
        id: _notifDinner,
        title: '🌙 تذكير بالعشاء',
        body: 'لم تسجل وجبة العشاء بعد！ اختر وجبة خفيفة ومتوازنة قبل النوم.',
        type: 'meal_reminder',
        subtype: 'dinner',
        hour: 21,
        minute: 30,
        channelKey: NotificationService.channelMealReminders,
        actionButtons: [
          NotificationActionButton(
            key: 'LOG_DINNER',
            label: '🍽️ تسجيل العشاء',
            color: const Color(0xFF9C27B0),
          ),
          NotificationActionButton(
            key: 'SNOOZE_MEAL',
            label: '⏰ لاحقاً',
            color: Colors.grey,
          ),
        ],
        payload: {'type': 'meal_reminder', 'meal_type': 'عشاء'},
      );
    }

    debugPrint('✅ [SmartMealReminder] تم جدولة جميع تذكيرات الوجبات');
  }

  /// إلغاء جميع تذكيرات الوجبات
  static Future<void> cancelAllMealReminders() async {
    await NotificationService.cancelNotification(_notifBreakfast);
    await NotificationService.cancelNotification(_notifLunch);
    await NotificationService.cancelNotification(_notifDinner);
    await NotificationService.cancelNotification(_notifSnack);
    debugPrint('✅ [SmartMealReminder] تم إلغاء جميع تذكيرات الوجبات');
  }

  /// إعادة جدولة التذكيرات بعد تغيير الإعدادات
  static Future<void> rescheduleAll() async {
    await cancelAllMealReminders();
    await scheduleAllMealReminders();
  }

  // ============================================
  // ✅ التذكير الذكي - التحقق من الوجبات المسجلة
  // ============================================

  /// التحقق الذكي: هل تم تسجيل الوجبات اليوم؟
  /// يمكن استدعاؤها في أي وقت لعرض تذكيرات ذكية بناءً على
  /// الوجبات المسجلة فعلياً
  static Future<void> checkAndSendSmartReminders() async {
    if (!await isEnabled()) return;

    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    // منع التكرار في نفس اليوم
    final lastReminded = await PrefsHelper.getString(_keyLastRemindedDate);
    if (lastReminded == todayKey) {
      debugPrint('🧠 [SmartMealReminder] تم التذكير اليوم بالفعل');
      return;
    }

    try {
      // جلب وجبات اليوم المسجلة من API
      final todayMeals = await NutritionService.getTodayMeals();
      final loggedTypes = <String>{};

      if (todayMeals != null && todayMeals['meals'] != null) {
        final mealsList = todayMeals['meals'] as List;
        for (final meal in mealsList) {
          if (meal is Map<String, dynamic>) {
            final type = meal['type']?.toString();
            if (type != null) loggedTypes.add(type);
          }
        }
      }

      // تحديد التذكيرات المطلوبة بناءً على الوقت الحالي
      final now = DateTime.now();
      final currentHour = now.hour;
      final currentMinute = now.minute;
      final currentTimeMinutes = currentHour * 60 + currentMinute;

      // وقت الفطور: 6:00-10:30
      if (currentTimeMinutes >= 360 && currentTimeMinutes <= 630) {
        if (await shouldRemindBreakfast() && !loggedTypes.contains('فطور')) {
          _sendGentleReminder(
            '🌅',
            'فطور',
            'وجبة فطور صحية تمنحك الطاقة لبداية يوم نشيطة!',
          );
        }
      }
      // وقت الغداء: 12:00-16:00
      else if (currentTimeMinutes >= 720 && currentTimeMinutes <= 960) {
        if (await shouldRemindLunch() && !loggedTypes.contains('غداء')) {
          _sendGentleReminder(
            '☀️',
            'غداء',
            'تناول وجبة غداء متوازنة غنية بالخضار والبروتين.',
          );
        }
      }
      // وقت العشاء: 18:00-22:00
      else if (currentTimeMinutes >= 1080 && currentTimeMinutes <= 1320) {
        if (await shouldRemindDinner() && !loggedTypes.contains('عشاء')) {
          _sendGentleReminder(
            '🌙',
            'عشاء',
            'وجبة عشاء خفيفة تساعد على نوم هادئ وصحي.',
          );
        }
      }

      await PrefsHelper.setString(_keyLastRemindedDate, todayKey);
    } catch (e) {
      debugPrint('❌ [SmartMealReminder] خطأ في التحقق الذكي: $e');
    }
  }

  /// إرسال تذكير فوري ولطيف
  static void _sendGentleReminder(String emoji, String mealType, String tip) {
    final mealEmoji = getMealEmoji(mealType);
    final typeColor = getMealTypeColor(mealType);

    // استخدام الإشعارات الفورية عبر NotificationService
    NotificationService.showImmediateNotification(
      title: '$emoji $mealEmoji تذكير بـ $mealType',
      body: tip,
      type: 'meal_reminder',
      subtype: mealType,
      channelKey: NotificationService.channelMealReminders,
      payload: {'type': 'meal_reminder', 'meal_type': mealType},
      actionButtons: [
        NotificationActionButton(
          key: 'LOG_${mealType.toUpperCase()}',
          label: '🍽️ تسجيل $mealType',
          color: typeColor,
        ),
        NotificationActionButton(
          key: 'SNOOZE_MEAL',
          label: '⏰ لاحقاً',
          color: Colors.grey,
        ),
      ],
    );
  }
}
