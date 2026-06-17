import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../constants/colors.dart';
import '../utils/prefs_helper.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';
import '../services/chat_history_service.dart';
import '../services/medication_api.dart';
import '../services/fcm_service.dart';
import 'onboarding/onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'main_screen.dart';
import 'initial_setup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _setupAnimations();

    // ✅ تهيئة الخدمات في الخلفية (بدون await - لا تمنع عرض الـ Splash)
    _initializeInBackground();

    // ✅ التحقق من حالة المستخدم (بدون تأخير اصطناعي)
    _checkUserStatus();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ✅ تنفيذ مستقبل مع مهلة زمنية - لا يرمي خطأ إذا تجاوز المهلة
  Future<T?> _withTimeout<T>(Future<T> future, Duration duration) async {
    try {
      return await future.timeout(duration);
    } on TimeoutException {
      print('⚠️ [Splash] تجاوز المهلة (${duration.inSeconds}ث)');
      return null;
    } catch (e) {
      print('⚠️ [Splash] خطأ: $e');
      return null;
    }
  }

  /// ✅ تهيئة الخدمات في الخلفية - لا تمنع عرض الـ SplashScreen
  Future<void> _initializeInBackground() async {
    // تهيئة الإشعارات
    await _withTimeout(
      NotificationService.initialize(),
      const Duration(seconds: 5),
    );

    // طلب صلاحيات الإشعارات
    await _withTimeout(
      NotificationService.requestPermissions(),
      const Duration(seconds: 3),
    );

    // تحديث الجرعات الفائتة
    await _withTimeout(
      MedicationService.updateMissedDoses(),
      const Duration(seconds: 5),
    );

    // جدولة تذكيرات الماء
    await _withTimeout(
      NotificationService.scheduleWaterReminders(),
      const Duration(seconds: 5),
    );

    // جدولة تذكيرات الأنشطة
    await _withTimeout(
      NotificationService.scheduleDailyActivityReminders(),
      const Duration(seconds: 5),
    );

    // جدولة تذكيرات الكويز اليومي
    await _withTimeout(
      NotificationService.scheduleDailyQuizReminders(),
      const Duration(seconds: 5),
    );

    // بدء المزامنة الدورية
    await _withTimeout(
      SyncService.startPeriodicSync(),
      const Duration(seconds: 3),
    );

    // مزامنة عند بدء التطبيق
    await _withTimeout(
      SyncService.syncOnAppStart(),
      const Duration(seconds: 10),
    );

    // تهيئة حفظ المحادثات
    await _withTimeout(ChatHistoryService().init(), const Duration(seconds: 3));

    // رفع FCM token للسيرفر (إذا كان المستخدم مسجل دخول)
    if (PrefsHelper.isLoggedIn) {
      await _withTimeout(
        FCMService().uploadTokenToServer(),
        const Duration(seconds: 5),
      );
    }

    print('✅ [Splash] اكتملت تهيئة الخلفية');
  }

  Future<void> _checkUserStatus() async {
    // ✅ انتظار animation فقط (بدون تأخير اصطناعي إضافي)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // تشخيص - عرض القيم الحالية
    PrefsHelper.printAllPrefs();

    // 1. أول مرة يفتح التطبيق؟ → Onboarding
    if (PrefsHelper.isFirstLaunch) {
      print('🚀 التوجيه: أول مرة → Onboarding');
      _navigateTo(const OnboardingScreen());
      return;
    }

    // 2. هل المستخدم مسجل دخول؟
    if (PrefsHelper.isLoggedIn) {
      // 2.1 أول مرة يسجل دخول؟ → Initial Setup
      if (PrefsHelper.isFirstTimeUser) {
        print('🚀 التوجيه: مسجل + أول مرة → Initial Setup');
        _navigateTo(const InitialSetup());
      } else {
        // 2.2 مستخدم قديم → Main Screen
        print('🚀 التوجيه: مسجل + قديم → Main Screen');
        _navigateTo(const MainScreen());
      }
    } else {
      // 3. مش مسجل دخول → Login
      print('🚀 التوجيه: مش مسجل → Login');
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // خلفية متدرجة محسنة
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.85),
                  AppColors.background,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // عناصر زخرفية في الخلفية
          ..._buildBackgroundDecorations(),

          // المحتوى الرئيسي
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // الشعار المحسن
                          _buildLogo(),

                          const SizedBox(height: 40),

                          // اسم التطبيق
                          Text(
                            'مساعدي الصحي',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // الشعار
                          Text(
                            'صحتك في عناية ذكية',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.85),
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 60),

                          // مؤشر التحميل المحسن
                          _buildLoadingIndicator(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // النص السفلي
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Text(
                'Vita',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            spreadRadius: -2,
            blurRadius: 40,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // حلقة داخلية
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.success.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
          ),
          // الأيقونة
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.success],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: Text('🏥', style: TextStyle(fontSize: 48)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundDecorations() {
    return [
      // دائرة زخرفية علوية
      Positioned(
        top: -80,
        right: -60,
        child: Container(
          width: 250,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      // دائرة زخرفية سفلية
      Positioned(
        bottom: -40,
        left: -40,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      // نقاط زخرفية
      Positioned(top: 120, right: 40, child: _buildDot()),
      Positioned(top: 160, right: 80, child: _buildDot()),
      Positioned(bottom: 200, left: 50, child: _buildDot()),
    ];
  }

  Widget _buildDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.15),
      ),
    );
  }
}
