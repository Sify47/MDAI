// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:vita/services/notification_service.dart';
import 'package:vita/services/fcm_service.dart';
import 'package:vita/services/smart_meal_reminder_service.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/quiz/daily_quiz_screen.dart';
import 'utils/prefs_helper.dart';
import 'models/quiz_models.dart';
import 'constants/colors.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة Firebase (مطلوبة قبل FCM)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ تهيئة FCM مع معالجة الأخطاء (لا تعرقل runApp)
  FCMService().initialize().catchError((error) {
    debugPrint('🔥 FCM: Initialization error (non-blocking): $error');
  });

  // ✅ فقط التهيئة الأساسية قبل runApp()
  tz.initializeTimeZones();
  await PrefsHelper.init();
  await initializeDateFormatting('ar', null);

  // ✅ جدولة تذكيرات الوجبات الذكية (لا تعرقل runApp)
  SmartMealReminderService.scheduleAllMealReminders().catchError((error) {
    debugPrint('🧠 SmartMealReminder: Scheduling error (non-blocking): $error');
  });

  // تهيئة ThemeProvider
  final themeProvider = ThemeProvider();
  NotificationService.navigatorKey = GlobalKey<NavigatorState>();

  // ✅ runApp() فوراً - أظهر الـ SplashScreen بدون تأخير
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'VITA',
          debugShowCheckedModeBanner: false,
          // ✅ Use unified themes from AppTheme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
          navigatorKey: NotificationService.navigatorKey,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/daily-quiz':
                QuizTimeOfDay timeOfDay = QuizTimeOfDay.morning;
                if (settings.arguments != null &&
                    settings.arguments is Map<String, dynamic>) {
                  final args = settings.arguments as Map<String, dynamic>;
                  final type = args['timeOfDay'] as String?;
                  if (type == 'evening') {
                    timeOfDay = QuizTimeOfDay.evening;
                  } else if (type == 'morning') {
                    timeOfDay = QuizTimeOfDay.morning;
                  }
                }
                return MaterialPageRoute(
                  builder: (context) => DailyQuizScreen(timeOfDay: timeOfDay),
                );
              default:
                return null;
            }
          },
        );
      },
    );
  }
}
