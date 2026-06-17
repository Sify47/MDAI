// lib/services/notification_service.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:vita/services/notification_api.dart';
import 'package:vita/services/quiz_service.dart';
import 'package:vita/services/water_service.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medication_model.dart';
import 'medication_api.dart';
import 'activity_api.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static late GlobalKey<NavigatorState> navigatorKey;

  static const String channelMedicationReminders = 'medication_reminders';
  static const String channelMedicationAlerts = 'medication_alerts';
  static const String channelWaterReminders = 'water_reminders';
  static const String channelActivityReminders = 'activity_reminders';
  static const String channelQuizReminders = 'quiz_reminders';
  static const String channelMealReminders = 'meal_reminders';

  static int get _userId => PrefsHelper.getUserId() ?? 1;

  static void initializeListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: channelMedicationReminders,
        channelName: 'تذكيرات الأدوية',
        channelDescription: 'قناة لتذكيرات مواعيد الأدوية',
        defaultColor: const Color(0xFF2196F3),
        ledColor: const Color(0xFF2196F3),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        groupKey: 'medications',
      ),
      NotificationChannel(
        channelKey: channelMedicationAlerts,
        channelName: 'تنبيهات الأدوية',
        channelDescription: 'تنبيهات فورية لتناول الأدوية',
        defaultColor: const Color(0xFF4CAF50),
        ledColor: const Color(0xFF4CAF50),
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        groupKey: 'medications',
      ),
      NotificationChannel(
        channelKey: channelWaterReminders,
        channelName: 'تذكيرات شرب الماء',
        channelDescription: 'تذكيرات لشرب الماء بانتظام',
        defaultColor: const Color(0xFF00BCD4),
        ledColor: const Color(0xFF00BCD4),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        groupKey: 'water',
      ),
      NotificationChannel(
        channelKey: channelActivityReminders,
        channelName: 'تذكيرات الأنشطة',
        channelDescription: 'تذكيرات للمواعيد والأنشطة اليومية',
        defaultColor: const Color(0xFFFF9800),
        ledColor: const Color(0xFFFF9800),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        groupKey: 'activities',
      ),
      NotificationChannel(
        channelKey: channelQuizReminders,
        channelName: 'تذكيرات الكويز اليومي',
        channelDescription: 'تذكيرات لكويز الصباح والمساء',
        defaultColor: const Color(0xFF9C27B0),
        ledColor: const Color(0xFF9C27B0),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        groupKey: 'quiz',
      ),
      NotificationChannel(
        channelKey: channelMealReminders,
        channelName: 'تذكيرات الوجبات',
        channelDescription: 'تذكيرات ذكية لتسجيل الوجبات في أوقاتها',
        defaultColor: const Color(0xFFFF9800),
        ledColor: const Color(0xFFFF9800),
        importance: NotificationImportance.High,
        channelShowBadge: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        groupKey: 'meals',
      ),
    ]);

    initializeListeners();

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // ============================================
  // ✅ التحقق من صحة وقت الإشعار (مع مراعاة ساعات الهدوء)
  // ============================================
  static bool _isValidNotificationTime(DateTime scheduledTime) {
    if (PrefsHelper.isInQuietHours(scheduledTime)) {
      print(
        '🔇 [NotificationService] تم تجاهل الإشعار في ساعات الهدوء: $scheduledTime',
      );
      return false;
    }
    if (scheduledTime.isBefore(DateTime.now())) {
      print(
        '⚠️ [NotificationService] تم تجاهل إشعار بوقت سابق: $scheduledTime',
      );
      return false;
    }
    return true;
  }

  static Future<int?> _logNotification({
    required int userId,
    required String type,
    String? subtype,
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await NotificationApi.logNotification(
        userId: userId,
        notificationType: type,
        notificationSubtype: subtype,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        metadata: metadata,
      );
      if (result['success'] == true) {
        return result['id'];
      }
    } catch (e) {
      print('❌ خطأ في تسجيل الإشعار: $e');
    }
    return null;
  }

  static Future<void> _updateNotificationActionInBackend(
    int notificationId,
    String action,
  ) async {
    try {
      await NotificationApi.updateNotificationAction(
        notificationId: notificationId,
        action: action,
      );
    } catch (e) {
      print('❌ خطأ في تحديث الـ Backend: $e');
    }
  }

  @pragma("vm-entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('📝 تم إنشاء الإشعار: ${receivedNotification.id}');
  }

  @pragma("vm-entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    print('👁️ تم عرض الإشعار: ${receivedNotification.id}');
  }

  static Future<void> _markDoseAsTakenFromNotification(
    String medicationId,
    int? notificationId,
  ) async {
    try {
      final result = await MedicationService.markDoseAsTaken(medicationId);
      if (result['success'] == true) {
        print('✅ تم تسجيل الجرعة بنجاح من الإشعار');
        if (notificationId != null) {
          await _updateNotificationActionInBackend(notificationId, 'taken');
        }
      }
    } catch (e) {
      print('🔥 خطأ في تسجيل الجرعة: $e');
    }
  }

  static Future<void> _markWaterAsLoggedFromNotification(
    double amount,
    int? notificationId,
  ) async {
    try {
      final result = await WaterService.logWater(amount);
      if (result['success'] == true) {
        print('✅ تم تسجيل شرب الماء بنجاح من الإشعار');
        if (notificationId != null) {
          await _updateNotificationActionInBackend(notificationId, 'taken');
        }
      }
    } catch (e) {
      print('🔥 خطأ في تسجيل شرب الماء: $e');
    }
  }

  static Future<void> _completeActivityFromNotification(
    int activityId,
    int? notificationId,
  ) async {
    try {
      final result = await ActivityService.completeActivity(activityId);
      if (result['success'] == true) {
        print('✅ تم إكمال النشاط بنجاح من الإشعار');
        if (notificationId != null) {
          await _updateNotificationActionInBackend(notificationId, 'completed');
        }
      }
    } catch (e) {
      print('🔥 خطأ في إكمال النشاط: $e');
    }
  }

  @pragma("vm-entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    final payload = receivedAction.payload;
    if (payload != null) {
      final medicationId = payload['medication_id'];
      final activityIdStr = payload['activity_id'];
      final notificationId = payload['notification_id'] != null
          ? int.tryParse(payload['notification_id']!)
          : null;
      final backendId = payload['backend_id'] != null
          ? int.tryParse(payload['backend_id']!)
          : null;
      final buttonKey = receivedAction.buttonKeyPressed;

      if (backendId != null) {
        if (buttonKey == 'TAKE') {
          await _updateNotificationActionInBackend(backendId, 'taken');
        } else if (buttonKey == 'DRINK_WATER') {
          await _updateNotificationActionInBackend(backendId, 'taken');
        } else if (buttonKey == 'COMPLETE_ACTIVITY') {
          await _updateNotificationActionInBackend(backendId, 'completed');
        } else if (buttonKey == 'SNOOZE') {
          await _updateNotificationActionInBackend(backendId, 'snoozed');
        }
      }

      if (buttonKey == 'TAKE' && medicationId != null) {
        await _markDoseAsTakenFromNotification(medicationId, notificationId);
        await cancelNotification(receivedAction.id!);
      } else if (buttonKey == 'DRINK_WATER') {
        await _markWaterAsLoggedFromNotification(0.25, notificationId);
        await cancelNotification(receivedAction.id!);
      } else if (buttonKey == 'COMPLETE_ACTIVITY' && activityIdStr != null) {
        final activityId = int.tryParse(activityIdStr);
        if (activityId != null) {
          await _completeActivityFromNotification(activityId, notificationId);
          await cancelNotification(receivedAction.id!);
        }
      } else if (buttonKey == 'SNOOZE') {
        if (notificationId != null) {
          await _updateNotificationActionInBackend(notificationId, 'snoozed');
        }
      } else if (buttonKey == 'TAKE_MORNING_QUIZ' ||
          buttonKey == 'TAKE_EVENING_QUIZ') {
        // معالجة أخذ الكويز من الإشعار
        final timeOfDay = buttonKey == 'TAKE_MORNING_QUIZ'
            ? 'morning'
            : 'evening';
        print('📝 [NotificationService] فتح شاشة الكويز $timeOfDay من الإشعار');

        // تحديث حالة الإشعار في الخادم
        if (backendId != null) {
          await _updateNotificationActionInBackend(backendId, 'quiz_opened');
        }

        // إلغاء الإشعار
        await cancelNotification(receivedAction.id!);

        // فتح شاشة الكويز (في التطبيق الحقيقي، سيتم التعامل مع هذا عبر Navigator)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamed(
            '/daily-quiz',
            arguments: {'timeOfDay': timeOfDay},
          );
        });
      } else if (buttonKey == 'REMIND_LATER') {
        // تذكير لاحق للكويز
        print('⏰ [NotificationService] تذكير لاحق للكويز');
        if (backendId != null) {
          await _updateNotificationActionInBackend(backendId, 'snoozed');
        }

        // جدولة تذكير جديد بعد 30 دقيقة
        final newTime = DateTime.now().add(const Duration(minutes: 30));
        if (_isValidNotificationTime(newTime)) {
          await scheduleDailyNotification(
            id: receivedAction.id! + 1000, // ID جديد لتجنب التعارض
            title: receivedAction.title ?? '⏰ تذكير الكويز',
            body: receivedAction.body ?? 'حان وقت الكويز مرة أخرى!',
            type: 'quiz',
            subtype: payload?['time_of_day'] ?? 'reminder',
            hour: newTime.hour,
            minute: newTime.minute,
            channelKey: channelQuizReminders,
            payload: payload,
          );
        }

        await cancelNotification(receivedAction.id!);
      } else {
        if (notificationId != null) {
          await _updateNotificationActionInBackend(notificationId, 'dismissed');
        }
      }
    }
  }

  @pragma("vm-entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    final payload = receivedAction.payload;
    if (payload != null && payload['notification_id'] != null) {
      final notificationId = int.tryParse(payload['notification_id']!);
      if (notificationId != null) {
        await _updateNotificationActionInBackend(notificationId, 'dismissed');
      }
    }
  }

  static Future<bool> requestPermissions() async {
    return await AwesomeNotifications().isNotificationAllowed() ||
        await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  static Future<void> syncScheduledNotificationsWithBackend() async {
    print('🔄 مزامنة الإشعارات مع الـ Backend...');

    try {
      final result = await NotificationApi.runDailyReminders();
      if (result['success'] == true) {
        print('✅ تم تشغيل التذكيرات اليومية على الـ Backend');
      }

      final todayNotifications = await NotificationApi.getTodayNotifications();
      if (todayNotifications != null &&
          todayNotifications['upcoming'] != null) {
        final upcomingList = todayNotifications['upcoming'];

        if (upcomingList is List) {
          for (var notification in upcomingList) {
            if (notification is Map<String, dynamic>) {
              final existingId = notification['id'];
              final scheduledTime = DateTime.parse(
                notification['scheduled_time'],
              );
              final title = notification['title'];
              final body = notification['body'];
              final type = notification['notification_type'];

              await _createLocalNotificationIfNeeded(
                backendId: existingId,
                title: title,
                body: body,
                scheduledTime: scheduledTime,
                type: type,
                payload: notification['extra_data'] as Map<String, dynamic>?,
              );
            } else {
              print('⚠️ تنسيق غير متوقع للإشعار: ${notification.runtimeType}');
            }
          }
        }
      }

      print('✅ تمت مزامنة الإشعارات بنجاح');
    } catch (e) {
      print('❌ خطأ في المزامنة: $e');
    }
  }

  static Future<void> _createLocalNotificationIfNeeded({
    required int backendId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String type,
    Map<String, dynamic>? payload,
  }) async {
    final existingKey = 'notif_$backendId';
    final exists = await PrefsHelper.getBool(existingKey) ?? false;

    if (exists) return;

    // ✅ التحقق من وقت الإشعار
    DateTime finalTime = scheduledTime;
    if (!_isValidNotificationTime(scheduledTime)) {
      finalTime = PrefsHelper.adjustToSafeTime(scheduledTime);
    }

    final int notificationId = backendId.remainder(2147483647);

    String channelKey;
    switch (type) {
      case 'medication':
        channelKey = channelMedicationAlerts;
        break;
      case 'water':
        channelKey = channelWaterReminders;
        break;
      case 'activity':
        channelKey = channelActivityReminders;
        break;
      default:
        channelKey = channelMedicationReminders;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: channelKey,
        title: title,
        body: body,
        payload: {
          'backend_id': backendId.toString(),
          'type': type,
          ...?payload?.map((k, v) => MapEntry(k, v.toString())),
        },
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(date: finalTime),
    );

    await PrefsHelper.setBool(existingKey, true);
    print('✅ تم إنشاء إشعار محلي من الـ Backend: $title في $finalTime');
  }

  // ============================================
  // ✅ جدولة إشعار يومي (مع مراعاة ساعات الهدوء)
  // ============================================
  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required String type,
    String? subtype,
    required int hour,
    required int minute,
    String? summary,
    String channelKey = channelMedicationReminders,
    Map<String, String?>? payload,
    List<NotificationActionButton>? actionButtons,
  }) async {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // ✅ التحقق من ساعات الهدوء
    if (!_isValidNotificationTime(scheduledTime)) {
      scheduledTime = PrefsHelper.adjustToSafeTime(scheduledTime);
    }

    final int safeId = id.remainder(2147483647);

    final notificationId = await _logNotification(
      userId: _userId,
      type: type,
      subtype: subtype,
      title: title,
      body: body,
      scheduledTime: scheduledTime,
      metadata: payload,
    );

    final fullPayload = {
      ...?payload,
      'notification_id': notificationId?.toString(),
      'backend_id': notificationId?.toString(),
    };

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: safeId,
        channelKey: channelKey,
        title: title,
        body: body,
        summary: summary,
        payload: fullPayload,
        notificationLayout: NotificationLayout.Default,
        displayOnForeground: true,
        displayOnBackground: true,
        category: NotificationCategory.Alarm,
      ),
      actionButtons: actionButtons,
      schedule: NotificationCalendar(
        hour: scheduledTime.hour,
        minute: scheduledTime.minute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  // في notification_service.dart

  static Future<void> scheduleMonthlyQuizReminder() async {
    final lastSession = await QuizService.getLastSession();

    if (lastSession != null) {
      final now = DateTime.now();
      final daysSinceLastQuiz = now.difference(lastSession.sessionDate).inDays;

      if (daysSinceLastQuiz < 28) {
        final nextQuizDate = lastSession.sessionDate.add(
          const Duration(days: 28),
        );
        final daysRemaining = 28 - daysSinceLastQuiz;

        // تذكير قبل 3 أيام
        final reminderDate = nextQuizDate.subtract(const Duration(days: 3));
        if (reminderDate.isAfter(now)) {
          await scheduleDailyNotification(
            id: 30000,
            title: '📋 تذكير بالتقييم الشهري',
            body: 'باقي 3 أيام على موعد تقييمك الشهري. جهز نفسك!',
            type: 'quiz',
            subtype: 'reminder',
            hour: reminderDate.hour,
            minute: reminderDate.minute,
            channelKey: channelActivityReminders,
          );
        }
      }
    }
  }

  static Future<void> scheduleIntervalNotification({
    required int id,
    required String title,
    required String body,
    required String type,
    String? subtype,
    required Duration interval,
    String? summary,
    String channelKey = channelMedicationReminders,
    Map<String, String?>? payload,
    List<NotificationActionButton>? actionButtons,
  }) async {
    final int safeId = id.remainder(2147483647);
    final scheduledTime = DateTime.now().add(interval);

    // ✅ التحقق من ساعات الهدوء للإشعارات المتكررة
    DateTime finalTime = scheduledTime;
    if (!_isValidNotificationTime(scheduledTime)) {
      finalTime = PrefsHelper.adjustToSafeTime(scheduledTime);
    }

    final notificationId = await _logNotification(
      userId: _userId,
      type: type,
      subtype: subtype,
      title: title,
      body: body,
      scheduledTime: finalTime,
      metadata: payload,
    );

    final fullPayload = {
      ...?payload,
      'notification_id': notificationId?.toString(),
      'backend_id': notificationId?.toString(),
    };

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: safeId,
        channelKey: channelKey,
        title: title,
        body: body,
        summary: summary,
        payload: fullPayload,
        notificationLayout: NotificationLayout.Default,
        displayOnForeground: true,
        displayOnBackground: true,
        category: NotificationCategory.Alarm,
      ),
      actionButtons: actionButtons,
      schedule: NotificationInterval(
        interval: Duration(seconds: interval.inSeconds),
        timeZone: tz.local.name,
        preciseAlarm: true,
        repeats: true,
        allowWhileIdle: true,
      ),
    );
  }

  static Future<void> scheduleWaterReminders() async {
    await scheduleIntervalNotification(
      id: 10000,
      title: '💧 تذكير بشرب الماء',
      body: 'حان وقت شرب الماء! حافظ على ترطيب جسمك.',
      type: 'water',
      subtype: 'regular',
      interval: const Duration(hours: 5),
      channelKey: channelWaterReminders,
      actionButtons: [
        NotificationActionButton(
          key: 'DRINK_WATER',
          label: '💧 شربت',
          color: Colors.green,
        ),
        NotificationActionButton(
          key: 'SNOOZE',
          label: '⏰ تذكير بعد ساعة',
          color: Colors.orange,
          autoDismissible: true,
        ),
      ],
      payload: {'type': 'water_reminder'},
    );

    await scheduleDailyNotification(
      id: 10001,
      title: '☀️ صباح النشاط',
      body: 'ابدأ يومك بكوب من الماء لتنشيط الجسم',
      type: 'water',
      subtype: 'morning',
      hour: 8,
      minute: 0,
      channelKey: channelWaterReminders,
      actionButtons: [
        NotificationActionButton(
          key: 'DRINK_WATER',
          label: '💧 شربت',
          color: Colors.green,
        ),
      ],
      payload: {'type': 'water_morning'},
    );

    await scheduleDailyNotification(
      id: 10002,
      title: '🌙 نهاية اليوم',
      body: 'لا تنس شرب آخر كوب ماء اليوم',
      type: 'water',
      subtype: 'evening',
      hour: 20,
      minute: 0,
      channelKey: channelWaterReminders,
      actionButtons: [
        NotificationActionButton(
          key: 'DRINK_WATER',
          label: '💧 شربت',
          color: Colors.green,
        ),
      ],
      payload: {'type': 'water_evening'},
    );
  }

  static Future<void> scheduleDailyActivityReminders() async {
    await scheduleDailyNotification(
      id: 20000,
      title: '📋 أنشطة اليوم',
      body: 'لا تنس مراجعة أنشطتك اليومية والتخطيط ليومك',
      type: 'activity',
      subtype: 'morning_reminder',
      hour: 9,
      minute: 0,
      channelKey: channelActivityReminders,
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW_ACTIVITIES',
          label: '📋 عرض الأنشطة',
          color: Colors.blue,
        ),
      ],
      payload: {'type': 'daily_reminder'},
    );

    await scheduleDailyNotification(
      id: 20001,
      title: '📝 تسجيل الأنشطة',
      body: 'لا تنس تسجيل أنشطتك اليومية ومتابعة تقدمك',
      type: 'activity',
      subtype: 'evening_reminder',
      hour: 20,
      minute: 0,
      channelKey: channelActivityReminders,
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW_ACTIVITIES',
          label: '📋 عرض الأنشطة',
          color: Colors.blue,
        ),
      ],
      payload: {'type': 'evening_reminder'},
    );
  }

  // ============================================
  // 📝 تذكيرات الكويز اليومي
  // ============================================
  static Future<void> scheduleDailyQuizReminders() async {
    print('📝 [NotificationService] جدولة تذكيرات الكويز اليومي');

    // تذكير كويز الصباح - الساعة 8 صباحاً
    await scheduleDailyNotification(
      id: 30000,
      title: '🌅 كويز الصباح',
      body: 'حان وقت كويز الصباح! خذ دقيقتين للإجابة على أسئلة الصباح',
      type: 'quiz',
      subtype: 'morning',
      hour: 8,
      minute: 0,
      channelKey: channelQuizReminders,
      actionButtons: [
        NotificationActionButton(
          key: 'TAKE_MORNING_QUIZ',
          label: '📝 أخذ الكويز',
          color: Colors.orange,
        ),
        NotificationActionButton(
          key: 'REMIND_LATER',
          label: '⏰ تذكير لاحق',
          color: Colors.grey,
        ),
      ],
      payload: {'type': 'morning_quiz', 'time_of_day': 'morning'},
    );

    // تذكير كويز المساء - الساعة 7 مساءً
    await scheduleDailyNotification(
      id: 30001,
      title: '🌙 كويز المساء',
      body: 'حان وقت كويز المساء! خذ دقيقتين للإجابة على أسئلة المساء',
      type: 'quiz',
      subtype: 'evening',
      hour: 19,
      minute: 0,
      channelKey: channelQuizReminders,
      actionButtons: [
        NotificationActionButton(
          key: 'TAKE_EVENING_QUIZ',
          label: '📝 أخذ الكويز',
          color: Colors.purple,
        ),
        NotificationActionButton(
          key: 'REMIND_LATER',
          label: '⏰ تذكير لاحق',
          color: Colors.grey,
        ),
      ],
      payload: {'type': 'evening_quiz', 'time_of_day': 'evening'},
    );

    print('✅ تم جدولة تذكيرات الكويز اليومي');
  }

  static Future<void> scheduleMedicationNotifications(
    UserMedication medication,
  ) async {
    final int medicationId = _getMedicationIdAsInt(medication);

    for (int i = 0; i < medication.times.length; i++) {
      final timeStr = medication.times[i];
      final timeParts = timeStr.split(':');
      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      int reminderHour = hour;
      int reminderMinute = minute - 30;
      if (reminderMinute < 0) {
        reminderHour -= 1;
        reminderMinute += 60;
      }

      if (reminderHour >= 0) {
        await scheduleDailyNotification(
          id: medicationId * 100 + i * 10 + 1,
          title: '⏰ تذكير: ${medication.name}',
          body: 'باقي 30 دقيقة على موعد ${medication.name}',
          type: 'medication',
          subtype: 'reminder',
          hour: reminderHour,
          minute: reminderMinute,
          channelKey: channelMedicationReminders,
          actionButtons: [
            NotificationActionButton(
              key: 'TAKE',
              label: '💊 أخذ الجرعة',
              color: Colors.green,
            ),
          ],
          payload: {
            'medication_id': medication.id.toString(),
            'medication_name': medication.name,
            'time': timeStr,
            'type': 'reminder',
          },
        );
      }

      await scheduleDailyNotification(
        id: medicationId * 100 + i * 10 + 2,
        title: '💊 حان موعد ${medication.name}',
        body: 'حان وقت تناول ${medication.dosage} من ${medication.name}',
        type: 'medication',
        subtype: 'alert',
        hour: hour,
        minute: minute,
        channelKey: channelMedicationAlerts,
        actionButtons: [
          NotificationActionButton(
            key: 'TAKE',
            label: '💊 أخذ الجرعة',
            color: Colors.green,
          ),
        ],
        payload: {
          'medication_id': medication.id.toString(),
          'medication_name': medication.name,
          'time': timeStr,
          'type': 'alert',
        },
      );
    }
  }

  static Future<void> cancelMedicationNotifications(
    UserMedication medication,
  ) async {
    final int medicationId = _getMedicationIdAsInt(medication);
    for (int i = 0; i < medication.times.length; i++) {
      await cancelNotification(medicationId * 100 + i * 10 + 1);
      await cancelNotification(medicationId * 100 + i * 10 + 2);
    }
  }

  static Future<void> scheduleActivityNotification({
    required int activityId,
    required String title,
    required String description,
    required DateTime startTime,
    int reminderMinutes = 15,
  }) async {
    print('📅 [NotificationService] جدولة إشعار للنشاط: $title');

    final reminderTime = startTime.subtract(Duration(minutes: reminderMinutes));

    // إشعار التذكير
    if (reminderTime.isAfter(DateTime.now())) {
      final reminderNotificationId = await _logNotification(
        userId: _userId,
        type: 'activity',
        subtype: 'reminder',
        title: '⏰ تذكير: $title',
        body: description.isNotEmpty
            ? description
            : 'باقي $reminderMinutes دقيقة على بدء النشاط',
        scheduledTime: reminderTime,
        metadata: {
          'activity_id': activityId,
          'activity_title': title,
          'reminder_minutes': reminderMinutes,
        },
      );

      // ✅ التحقق من وقت الإشعار
      DateTime finalReminderTime = reminderTime;
      if (!_isValidNotificationTime(reminderTime)) {
        finalReminderTime = PrefsHelper.adjustToSafeTime(reminderTime);
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: activityId * 100 + 1,
          channelKey: channelActivityReminders,
          title: '⏰ تذكير: $title',
          body: description.isNotEmpty
              ? description
              : 'باقي $reminderMinutes دقيقة على بدء النشاط',
          payload: {
            'type': 'activity_reminder',
            'activity_id': activityId.toString(),
            'activity_title': title,
            'notification_id': reminderNotificationId?.toString(),
            'backend_id': reminderNotificationId?.toString(),
          },
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'VIEW_ACTIVITY',
            label: '👁️ عرض',
            color: Colors.blue,
          ),
        ],
        schedule: NotificationCalendar.fromDate(date: finalReminderTime),
      );
    }

    // إشعار بدء النشاط
    if (startTime.isAfter(DateTime.now())) {
      final startNotificationId = await _logNotification(
        userId: _userId,
        type: 'activity',
        subtype: 'start',
        title: '🏃 حان وقت: $title',
        body: description.isNotEmpty ? description : 'حان وقت بدء النشاط',
        scheduledTime: startTime,
        metadata: {'activity_id': activityId, 'activity_title': title},
      );

      DateTime finalStartTime = startTime;
      if (!_isValidNotificationTime(startTime)) {
        finalStartTime = PrefsHelper.adjustToSafeTime(startTime);
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: activityId * 100 + 2,
          channelKey: channelActivityReminders,
          title: '🏃 حان وقت: $title',
          body: description.isNotEmpty ? description : 'حان وقت بدء النشاط',
          payload: {
            'type': 'activity_start',
            'activity_id': activityId.toString(),
            'activity_title': title,
            'notification_id': startNotificationId?.toString(),
            'backend_id': startNotificationId?.toString(),
          },
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'COMPLETE_ACTIVITY',
            label: '✅ إكمال',
            color: Colors.green,
          ),
          NotificationActionButton(
            key: 'SNOOZE',
            label: '⏰ تذكير بعد 15 دقيقة',
            color: Colors.orange,
          ),
        ],
        schedule: NotificationCalendar.fromDate(date: finalStartTime),
      );
    }

    print('✅ [NotificationService] تم جدولة إشعارات للنشاط: $title');
  }

  static Future<void> cancelActivityNotifications(int activityId) async {
    await cancelNotification(activityId * 100 + 1);
    await cancelNotification(activityId * 100 + 2);
    print('✅ [NotificationService] تم إلغاء إشعارات النشاط $activityId');
  }

  static Future<void> checkAndSendWaterReminder() async {
    print('💧 [NotificationService] التحقق من كمية الماء...');

    try {
      final todayData = await WaterService.getTodayWater();
      if (todayData != null) {
        final total = (todayData['total'] ?? 0.0).toDouble();
        final goal = (todayData['daily_goal'] ?? 2.5).toDouble();
        final now = DateTime.now();

        // ✅ التحقق من وقت الإشعار
        if (now.hour >= 18 &&
            total < goal * 0.7 &&
            !PrefsHelper.isInQuietHours(now)) {
          await showImmediateNotification(
            title: '⚠️ كمية الماء اليوم قليلة',
            body: 'شربت $total لتر من $goal لتر. حافظ على ترطيب جسمك!',
            type: 'water',
            subtype: 'alert',
            channelKey: channelWaterReminders,
            actionButtons: [
              NotificationActionButton(
                key: 'DRINK_WATER',
                label: '💧 شربت',
                color: Colors.green,
              ),
            ],
            payload: {'type': 'water_check'},
          );
          print('✅ [NotificationService] تم إرسال تذكير الماء');
        }
      }
    } catch (e) {
      print('❌ [NotificationService] خطأ في التحقق من كمية الماء: $e');
    }
  }

  static Future<void> cleanupOldNotifications() async {
    print('🧹 [NotificationService] تنظيف الإشعارات القديمة...');

    try {
      final result = await NotificationApi.cleanupOldNotifications(daysOld: 90);
      if (result['success'] == true) {
        print(
          '✅ [NotificationService] تم تنظيف ${result['deleted_count']} إشعار قديم من الـ Backend',
        );
      }

      await cancelAllNotifications();
      await PrefsHelper.clearNotificationKeys();

      print('✅ [NotificationService] تم تنظيف الإشعارات القديمة من الجهاز');
    } catch (e) {
      print('❌ [NotificationService] خطأ في تنظيف الإشعارات: $e');
    }
  }

  static Future<void> rescheduleAllNotifications(
    List<UserMedication> medications,
  ) async {
    try {
      print('🔄 [NotificationService] إعادة جدولة كل الإشعارات...');

      await cancelAllNotifications();

      for (var med in medications) {
        await scheduleMedicationNotifications(med);
      }

      await scheduleWaterReminders();
      await scheduleDailyActivityReminders();
      await scheduleDailyQuizReminders();
      await syncScheduledNotificationsWithBackend();

      print('✅ [NotificationService] تم إعادة جدولة كل الإشعارات');
    } catch (e) {
      print('🔥 [NotificationService] خطأ في إعادة جدولة الإشعارات: $e');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
    print('✅ [NotificationService] تم إلغاء الإشعار $id');
  }

  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    print('✅ [NotificationService] تم إلغاء كل الإشعارات');
  }

  static int _getMedicationIdAsInt(UserMedication medication) {
    if (medication.id is int) {
      return medication.id as int;
    } else {
      return int.parse(medication.id.toString());
    }
  }

  static int _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(1000000);
  }

  static Future<void> testNotification() async {
    final testTime = DateTime.now().add(const Duration(seconds: 10));
    final testId = _generateUniqueId();

    print('🧪 [NotificationService] تجربة إشعار في: $testTime (ID: $testId)');

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: testId,
        channelKey: channelMedicationAlerts,
        title: '🧪 إشعار تجريبي',
        body: 'اضغط على زر أخذ الجرعة للتجربة',
        payload: {
          'type': 'test',
          'medication_id': '1',
          'medication_name': 'دواء تجريبي',
          'backend_id': '999',
        },
        category: NotificationCategory.Alarm,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'TAKE',
          label: '💊 أخذ الجرعة',
          color: Colors.green,
        ),
      ],
      schedule: NotificationCalendar.fromDate(date: testTime),
    );

    print('✅ [NotificationService] تم جدولة الإشعار التجريبي');
  }

  static Future<void> showImmediateNotification({
    required String title,
    required String body,
    required String type,
    String? subtype,
    String? summary,
    String channelKey = channelMedicationAlerts,
    Map<String, String?>? payload,
    List<NotificationActionButton>? actionButtons,
  }) async {
    // ✅ التحقق من ساعات الهدوء قبل إرسال إشعار فوري
    if (PrefsHelper.isInQuietHours(DateTime.now())) {
      print(
        '🔇 [NotificationService] تم تجاهل الإشعار الفوري في ساعات الهدوء: $title',
      );
      return;
    }

    print('🔔 [NotificationService] إشعار فوري: $title');

    final notificationId = await _logNotification(
      userId: _userId,
      type: type,
      subtype: subtype,
      title: title,
      body: body,
      scheduledTime: DateTime.now(),
      metadata: payload,
    );

    final fullPayload = {
      ...?payload,
      'notification_id': notificationId?.toString(),
      'backend_id': notificationId?.toString(),
    };

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _generateUniqueId(),
        channelKey: channelKey,
        title: title,
        body: body,
        summary: summary,
        payload: fullPayload,
        notificationLayout: NotificationLayout.Default,
        displayOnForeground: true,
        displayOnBackground: true,
        criticalAlert: true,
        category: NotificationCategory.Alarm,
      ),
      actionButtons: actionButtons,
    );

    print('✅ [NotificationService] تم إرسال الإشعار الفوري');
  }
}
