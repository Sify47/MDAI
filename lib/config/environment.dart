/// ملف إدارة متغيرات البيئة
/// 
/// هذا الملف يوفر وصولاً آمناً لمتغيرات البيئة مع قيم افتراضية
/// للاستخدام في التطوير والإنتاج

import 'package:flutter/foundation.dart';

class EnvironmentConfig {
  // إعدادات API
  static String get apiBaseUrl {
    if (kReleaseMode) {
      // في وضع الإنتاج، استخدم URL الإنتاج
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://65.75.201.173:8000',
      );
    } else {
      // في وضع التطوير، استخدم URL التطوير
      return const String.fromEnvironment(
        'API_BASE_URL',
        // defaultValue: 'http://65.75.201.173:8000',
        defaultValue: 'http://10.0.2.2:8000',
      );
    }
  }

  static int get apiTimeoutSeconds {
    return const int.fromEnvironment(
      'API_TIMEOUT_SECONDS',
      defaultValue: 30,
    );
  }

  // إعدادات الأمان
  static String get encryptionKey {
    return const String.fromEnvironment(
      'ENCRYPTION_KEY',
      defaultValue: 'default-encryption-key-for-development',
    );
  }

  static String get jwtSecret {
    return const String.fromEnvironment(
      'JWT_SECRET',
      defaultValue: 'default-jwt-secret-for-development',
    );
  }

  // إعدادات التطوير
  static bool get debugMode {
    return const bool.fromEnvironment(
      'DEBUG',
      defaultValue: !kReleaseMode,
    );
  }

  static String get logLevel {
    return const String.fromEnvironment(
      'LOG_LEVEL',
      defaultValue: kReleaseMode ? 'warning' : 'debug',
    );
  }

  // مفاتيح API الخارجية
  static String get googleMapsApiKey {
    return const String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: '',
    );
  }

  static String get openAiApiKey {
    return const String.fromEnvironment(
      'OPENAI_API_KEY',
      defaultValue: '',
    );
  }

  // إعدادات Firebase
  static String get firebaseApiKey {
    return const String.fromEnvironment(
      'FIREBASE_API_KEY',
      defaultValue: '',
    );
  }

  static String get firebaseAuthDomain {
    return const String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: '',
    );
  }

  static String get firebaseProjectId {
    return const String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: '',
    );
  }

  static String get firebaseStorageBucket {
    return const String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: '',
    );
  }

  static String get firebaseMessagingSenderId {
    return const String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '',
    );
  }

  static String get firebaseAppId {
    return const String.fromEnvironment(
      'FIREBASE_APP_ID',
      defaultValue: '',
    );
  }

  // وظائف مساعدة
  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => !kReleaseMode;
  
  static String get environmentName {
    if (kReleaseMode) {
      return 'Production';
    } else if (kDebugMode) {
      return 'Development';
    } else if (kProfileMode) {
      return 'Profile';
    } else {
      return 'Unknown';
    }
  }

  /// طباعة معلومات البيئة (للتطوير فقط)
  static void printEnvironmentInfo() {
    if (!debugMode) return;
    
    debugPrint('''
╔══════════════════════════════════════════════════════════╗
║                    Environment Info                      ║
╠══════════════════════════════════════════════════════════╣
║ Environment: $environmentName
║ API Base URL: $apiBaseUrl
║ Debug Mode: $debugMode
║ Log Level: $logLevel
║ Is Production: $isProduction
╚══════════════════════════════════════════════════════════╝
''');
  }
}