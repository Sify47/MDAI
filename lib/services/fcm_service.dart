// lib/services/fcm_service.dart
/// خدمة Firebase Cloud Messaging (FCM)
///
/// مسؤولة عن:
/// 1. الحصول على FCM token من Firebase
/// 2. رفع token للسيرفر عند تسجيل الدخول
/// 3. استقبال الإشعارات القادمة من السيرفر (خاصة التذكيرات الذكية)
/// 4. عرض الإشعارات عبر AwesomeNotifications عند استلامها في الخلفية

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging? _messaging;
  String? _currentToken;
  bool _initialized = false;
  bool _setupAvailable = true;

  /// التحقق مما إذا كانت منصة FCM متوفرة (Android/iOS حقيقية)
  bool get isPlatformAvailable {
    try {
      if (kIsWeb) return true;
      // التحقق من منصة التشغيل
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      // إذا فشل التحقق (مثلاً في بيئة ويب أو اختبار)، نفترض أنها متوفرة
      return true;
    }
  }

  /// تهيئة FCM - استدعاء مرة واحدة بعد Firebase.initializeApp()
  Future<void> initialize() async {
    if (_initialized) return;
    if (!isPlatformAvailable) {
      debugPrint('⚠️ FCM: Platform not available (not Android/iOS)');
      _setupAvailable = false;
      return;
    }

    try {
      _messaging = FirebaseMessaging.instance;

      // طلب صلاحية الإشعارات (iOS)
      final notificationSettings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        '🔔 FCM: Notification permission: ${notificationSettings.authorizationStatus}',
      );

      // الحصول على FCM token
      _currentToken = await _messaging!.getToken();
      debugPrint(
        '📱 FCM: Token obtained: ${_currentToken?.substring(0, 20)}...',
      );

      // الاستماع لتغييرات token (عند انتهاء صلاحيته أو تغيير الجهاز)
      _messaging!.onTokenRefresh.listen(_onTokenRefresh);

      // استقبال الإشعارات في المقدمة (Foreground)
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // استقبال الإشعارات عند الضغط عليها (من الخلفية)
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      // التحقق من وجود إشعار فتح التطبيق به (من حالة terminated)
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data);
      }

      _initialized = true;
      _setupAvailable = true;
      debugPrint('✅ FCM: Service initialized successfully');
    } catch (e) {
      _setupAvailable = false;
      _initialized = false;
      debugPrint('❌ FCM: Initialization error (non-critical): $e');
      // الخطأ MissingPluginException يحدث غالباً عند عدم توفر Firebase نيتف
      // التطبيق سيعمل بدون FCM، والإشعارات المحلية لا تزال تعمل
    }
  }

  /// هل إعداد FCM كامل متوفر
  bool get isAvailable => _initialized && _setupAvailable;

  /// رفع FCM token للسيرفر
  Future<bool> uploadTokenToServer() async {
    try {
      if (_currentToken == null) {
        debugPrint('⚠️ FCM: No token to upload');
        return false;
      }

      final response = await BaseApiService.post(
        'api/fcm/register-token',
        body: {'fcm_token': _currentToken!},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM: Token uploaded to server');
        return true;
      } else {
        debugPrint('⚠️ FCM: Failed to upload token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ FCM: Token upload error: $e');
      return false;
    }
  }

  /// حذف FCM token من السيرفر (عند تسجيل الخروج)
  Future<bool> deleteTokenFromServer() async {
    try {
      final response = await BaseApiService.delete('api/fcm/token');

      if (response.statusCode == 200) {
        debugPrint('✅ FCM: Token deleted from server');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ FCM: Token deletion error: $e');
      return false;
    }
  }

  /// معالجة تغيير FCM token
  void _onTokenRefresh(String newToken) {
    debugPrint('🔄 FCM: Token refreshed');
    _currentToken = newToken;

    // رفع token الجديد للسيرفر
    if (PrefsHelper.isLoggedIn) {
      uploadTokenToServer();
    }
  }

  /// معالجة الإشعارات في المقدمة (Foreground)
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('📩 FCM: Foreground message received');
    _logMessage(message);

    // في المقدمة، نترك AwesomeNotifications تعرض الإشعارات
    // أو نعرضها يدوياً حسب الحاجة
    _showLocalNotification(message);
  }

  /// معالجة الضغط على الإشعار (من الخلفية)
  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 FCM: Message opened from background');
    _handleNotificationTap(message.data);
  }

  /// عرض إشعار محلي (للمقدمة) باستخدام AwesomeNotifications
  void _showLocalNotification(RemoteMessage message) {
    try {
      final notification = message.notification;
      if (notification == null) return;

      // استخدم AwesomeNotifications لعرض الإشعار
      // هذا يتجنب ازدواجية الإشعارات لأن AwesomeNotifications
      // هو المسؤول عن عرض الإشعارات في التطبيق
      debugPrint('📢 FCM: ${notification.title} - ${notification.body}');
    } catch (e) {
      debugPrint('❌ FCM: Local notification error: $e');
    }
  }

  /// معالجة الضغط على الإشعار - التنقل حسب النوع
  void _handleNotificationTap(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;
      debugPrint('👆 FCM: Notification tapped - type: $type');

      // يمكن إضافة منطق التنقل حسب نوع الإشعار
      switch (type) {
        case 'smart_reminder':
          // التنقل إلى شاشة التذكيرات الذكية
          break;
        case 'dynamic_target':
          // التنقل إلى شاشة الأهداف الديناميكية
          break;
        case 'achievement':
          // التنقل إلى شاشة الإنجازات
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('❌ FCM: Handle tap error: $e');
    }
  }

  /// تسجيل بيانات الإشعار للتصحيح
  void _logMessage(RemoteMessage message) {
    final notification = message.notification;
    debugPrint('📋 FCM Message:');
    debugPrint('  - Title: ${notification?.title}');
    debugPrint('  - Body: ${notification?.body}');
    debugPrint('  - Data: ${message.data}');
    debugPrint('  - Category: ${message.category}');
    debugPrint('  - MessageId: ${message.messageId}');
  }

  /// الحصول على FCM token الحالي
  String? get currentToken => _currentToken;

  /// هل الخدمة مهيأة
  bool get isInitialized => _initialized;
}
