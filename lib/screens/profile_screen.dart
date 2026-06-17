// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:vita/screens/auth/login_screen.dart';
import 'package:vita/screens/notification_history_screen.dart';
import 'package:vita/screens/profile/health_data_screen.dart';
import 'package:vita/screens/profile/help_support_screen.dart';
import 'package:vita/screens/profile/personal_info_screen.dart';
import 'package:vita/screens/quiz/daily_quiz_dashboard.dart';
import 'package:vita/screens/quiz/quiz_analysis_screen.dart';
import 'package:vita/screens/settings/quiet_hours_settings.dart';
import 'package:vita/screens/settings/theme_settings_screen.dart';
import 'package:vita/services/auth_api.dart';
import 'package:vita/services/nutrition_api.dart';
import 'package:vita/utils/prefs_helper.dart';
import '../../constants/colors.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late AnimationController _fadeController;

  // متغيرات بيانات المستخدم
  User? _currentUser;
  Map<String, dynamic> _nutritionData = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.elasticOut,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _headerController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToPersonalInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
    );
  }

  void _navigateToHealthData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HealthDataScreen()),
    );
  }

  void _navigateToHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
    );
  }

  // تحميل بيانات المستخدم
  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await PrefsHelper.getUser();

      if (!mounted) return;

      if (user != null) {
        setState(() {
          _currentUser = user;
        });

        try {
          final nutrition = await NutritionService.getUserNutritionData();

          if (!mounted) return;

          if (nutrition != null) {
            setState(() {
              _nutritionData = {
                'weight': nutrition.weight,
                'height': nutrition.height,
                'targetWeight': nutrition.targetWeight,
                'goal': nutrition.goal,
                'diseases': nutrition.diseases,
              };
            });
          }
        } catch (e) {
          print('⚠️ خطأ في تحميل بيانات التغذية: $e');
        }
      } else {
        final localData = PrefsHelper.getUserData();

        if (!mounted) return;

        setState(() {
          _nutritionData = localData;
        });
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'فشل في تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationHistoryScreen(),
      ),
    );
  }

  // ✅ شاشة تأكيد تسجيل الخروج المحسنة
  Future<void> _showLogoutDialog() async {
    _fadeController.forward();

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            _fadeController.reverse();
            return true;
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: _buildLogoutDialogContent(),
          ),
        );
      },
    );

    _fadeController.reverse();
  }

  Widget _buildLogoutDialogContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ رأس مخصص مع تأثيرات متحركة
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.danger,
                          AppColors.danger.withOpacity(0.8),
                          const Color(0xFFFF6B6B),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        // أيقونة متحركة
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                  size: 56,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'هل أنت متأكد من تسجيل الخروج؟',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ محتوى الـ Dialog
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // ✅ معلومات المستخدم المحسنة
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [Colors.grey[850]!, Colors.grey[800]!]
                                  : [Colors.grey[50]!, Colors.white],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              // صورة المستخدم
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      AppColors.success,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _currentUser?.name.isNotEmpty == true
                                        ? _currentUser!.name[0].toUpperCase()
                                        : 'م',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentUser?.name ?? 'مستخدم',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 14,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _currentUser?.email ??
                                                'email@example.com',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.5),
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ✅ تحذير محسن
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.warning,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'سيتم حفظ بياناتك محلياً ويمكنك تسجيل الدخول مرة أخرى في أي وقت',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ✅ أزرار التحكم المحسنة
                        Row(
                          children: [
                            // زر الإلغاء
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  _fadeController.reverse();
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.close,
                                        size: 18,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'إلغاء',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // زر تأكيد تسجيل الخروج
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  Navigator.pop(context);
                                  await _performLogout();
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.danger,
                                        AppColors.danger.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.danger.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'تسجيل الخروج',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ تنفيذ عملية تسجيل الخروج مع تأثيرات محسنة
  Future<void> _performLogout() async {
    if (!mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    // عرض مؤشر تحميل محسن
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (context) => _buildLogoutProgressDialog(),
      );
    }

    try {
      await AuthService.logout();
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      print('⚠️ خطأ في تسجيل الخروج من API: $e');
    }

    await PrefsHelper.logout();

    if (!mounted) return;

    // إغلاق مؤشر التحميل
    Navigator.of(context).pop();

    // عرض رسالة نجاح محسنة
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تم تسجيل الخروج بنجاح',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // التوجه لشاشة تسجيل الدخول مع انتقال محسن
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  // ✅ شاشة التحميل المحسنة أثناء تسجيل الخروج
  Widget _buildLogoutProgressDialog() {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.danger),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'جاري تسجيل الخروج...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى الانتظار قليلاً',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ThemeSettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'جاري تحميل الملف الشخصي...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : _errorMessage != null
              ? _buildError(theme)
              : AnimationLimiter(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ScaleTransition(
                          scale: _headerAnimation,
                          child: _buildProfileHeader(theme),
                        ),
                        const SizedBox(height: 24),
                        _buildQuickStats(theme),
                        const SizedBox(height: 24),
                        _buildSettingsList(theme),
                        const SizedBox(height: 24),
                        _buildLogoutButton(theme),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'فشل في تحميل البيانات',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final userName = _currentUser?.name ?? 'مستخدم';
    final userEmail = _currentUser?.email ?? 'email@example.com';

    String firstLetter = userName.isNotEmpty ? userName[0] : 'أ';

    String diseasesText = '';
    if (_nutritionData['diseases'] != null) {
      final diseases = _nutritionData['diseases'];
      if (diseases is List && diseases.isNotEmpty) {
        final diseaseList = List<String>.from(diseases);
        if (diseaseList.isNotEmpty) {
          diseasesText = diseaseList.take(2).join('، ');
          if (diseaseList.length > 2) diseasesText += ' وأخرى';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, AppColors.success],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    firstLetter,
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (diseasesText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      diseasesText,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    int age = 0;
    if (_currentUser?.birthDate != null) {
      final today = DateTime.now();
      age = today.year - _currentUser!.birthDate.year;
      if (today.month < _currentUser!.birthDate.month ||
          (today.month == _currentUser!.birthDate.month &&
              today.day < _currentUser!.birthDate.day)) {
        age--;
      }
    }

    final currentWeight = _nutritionData['weight']?.round() ?? 0;
    final targetWeight = _nutritionData['targetWeight']?.round() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme: theme,
            icon: Icons.monitor_weight,
            value: '$currentWeight كجم',
            label: 'الوزن الحالي',
            color: AppColors.calories,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme: theme,
            icon: Icons.flag,
            value: '$targetWeight كجم',
            label: 'الوزن المستهدف',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            theme: theme,
            icon: Icons.calendar_today,
            value: '$age',
            label: 'العمر',
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(ThemeData theme) {
    final settings = [
      {
        'icon': Icons.person_outline,
        'title': 'المعلومات الشخصية',
        'subtitle': 'الاسم، البريد، رقم الهاتف',
        'color': theme.colorScheme.primary,
        'onTap': _navigateToPersonalInfo, // ✅ إضافة هذا
      },
      {
        'icon': Icons.health_and_safety,
        'title': 'البيانات الصحية',
        'subtitle': 'الوزن، الطول، الأمراض المزمنة',
        'color': AppColors.success,
        'onTap': _navigateToHealthData, // ✅ إضافة هذا
      },

      {
        'icon': Icons.notifications_none,
        'title': 'الإشعارات',
        'subtitle': 'تذكير الأدوية، تنبيهات القراءات',
        'color': AppColors.warning,
        'onTap': _navigateToNotifications,
      },
      {
        'icon': Icons.security_outlined,
        'title': 'الأمان والخصوصية',
        'subtitle': 'تغيير كلمة المرور، المصادقة',
        'color': AppColors.danger,
      },
      {
        'icon': Icons.language_outlined,
        'title': 'اللغة',
        'subtitle': 'العربية - English',
        'color': AppColors.medications,
      },
      {
        'icon': Icons.nightlight_round,
        'title': '🔇 ساعات الهدوء',
        'subtitle': 'تحديد الأوقات التي لا تريد استقبال إشعارات فيها',
        'color': AppColors.info,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuietHoursSettings()),
          );
        },
      },
      {
        'icon': Icons.analytics,
        'title': '📊 تحليل نمط الحياة',
        'subtitle': 'عرض نتائج الكويز ومقارنة التقييمات الشهرية',
        'color': AppColors.info,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuizAnalysisScreen()),
          );
        },
      },
      {
        'icon': Icons.quiz_outlined,
        'title': 'الكويز اليومي',
        'subtitle': 'عرض نتائج الكويز اليومي',
        'color': AppColors.info,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyQuizDashboard()),
          );
        },
      },
      {
        'icon': Icons.help_outline,
        'title': 'مساعدة ودعم',
        'subtitle': 'الأسئلة الشائعة، تواصل معنا',
        'color': AppColors.walking,
        'onTap': _navigateToHelpSupport, // ✅ إضافة هذا
      },
    ];

    return Column(
      children: List.generate(
        settings.length,
        (index) => AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 500),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildSettingItem(settings[index], index, theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    Map<String, dynamic> setting,
    int index,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.06),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (setting['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(setting['icon'], color: setting['color'], size: 22),
        ),
        title: Text(
          setting['title'],
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          setting['subtitle'],
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        onTap: setting['onTap'] as VoidCallback?,
      ),
    );
  }

  // ✅ زر تسجيل الخروج المحسن بشكل كبير
  Widget _buildLogoutButton(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: _isLoggingOut
                      ? [Colors.grey[400]!, Colors.grey[500]!]
                      : [AppColors.danger, AppColors.danger.withOpacity(0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withOpacity(
                      _isLoggingOut ? 0.1 : 0.3,
                    ),
                    spreadRadius: 1,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoggingOut ? null : _showLogoutDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: _isLoggingOut
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'تسجيل الخروج',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
