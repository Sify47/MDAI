import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../auth/login_screen.dart';
import '../../utils/prefs_helper.dart';

/// Onboarding model for page data
class _OnboardingPage {
  final String emoji;
  final String title;
  final String description;
  final Color lightColor;
  final Color darkColor;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.description,
    required this.lightColor,
    required this.darkColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animController;
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      emoji: '🏥',
      title: 'مرحباً بك في فيتا',
      description:
          'تطبيقك الصحي الشامل لمتابعة صحتك وإدارة أمراضك المزمنة. كل ما تحتاجه في مكان واحد.',
      lightColor: AppColors.primary,
      darkColor: Color(0xFF90CAF9),
    ),
    _OnboardingPage(
      emoji: '📊',
      title: 'راقب مؤشراتك الصحية',
      description:
          'سجل قياسات السكر والضغط والوزن والكوليسترول. تابع تطورك مع رسوم بيانية واضحة وتحليلات ذكية.',
      lightColor: AppColors.success,
      darkColor: Color(0xFF81C784),
    ),
    _OnboardingPage(
      emoji: '💊',
      title: 'إدارة الأدوية',
      description:
          'نظم مواعيد أدويتك مع تذكيرات ذكية. لا تنس جرعة أبداً مع إشعارات مخصصة حسب جدولك.',
      lightColor: AppColors.medications,
      darkColor: Color(0xFF80CBC4),
    ),
    _OnboardingPage(
      emoji: '🥗',
      title: 'التغذية الذكية',
      description:
          'سجل وجباتك اليومية واحسب السعرات والمغذيات. احصل على توصيات غذائية مخصصة لأهدافك الصحية.',
      lightColor: AppColors.nutrition,
      darkColor: Color(0xFF81C784),
    ),
    _OnboardingPage(
      emoji: '🏃',
      title: 'النشاط والحركة',
      description:
          'تتبع خطواتك اليومية، تمارينك، ومستوى نشاطك. حقق أهدافك اللياقية خطوة بخطوة.',
      lightColor: AppColors.walking,
      darkColor: Color(0xFF90CAF9),
    ),
    _OnboardingPage(
      emoji: '🤖',
      title: 'مساعدك الذكي',
      description:
          'اسأل عن أي شيء صحي واحصل على إجابات فورية مدعومة بالذكاء الاصطناعي. تحليلات وتوصيات مخصصة لك.',
      lightColor: AppColors.calories,
      darkColor: Color(0xFFFFCC80),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      AppColors.darkScaffold,
                      AppColors.darkSurface,
                    ]
                  : [
                      AppColors.background,
                      Colors.white,
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: TextButton.icon(
                      onPressed: _skipOnboarding,
                      icon: Icon(
                        Icons.arrow_forward_rounded,
                        color: isDark
                            ? const Color(0xFF90CAF9)
                            : AppColors.primary,
                        size: 18,
                      ),
                      label: Text(
                        'تخطي',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF90CAF9)
                              : AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      _animController.reset();
                      _animController.forward();
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index);
                    },
                  ),
                ),

                // Progress indicators
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Dots
                      Expanded(
                        child: _buildDots(isDark),
                      ),

                      // Counter
                      Text(
                        '${_currentPage + 1}/${_pages.length}',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // Previous button
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? const Color(0xFF90CAF9)
                                  : AppColors.primary,
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF90CAF9).withValues(alpha: 0.4)
                                    : AppColors.primary.withValues(alpha: 0.4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'السابق',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),

                      // Next / Finish button
                      Expanded(
                        flex: _currentPage > 0 ? 2 : 1,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: ElevatedButton(
                            onPressed: _currentPage == _pages.length - 1
                                ? _finishOnboarding
                                : _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF90CAF9)
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: isDark ? 0 : 2,
                              shadowColor: isDark
                                  ? Colors.transparent
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentPage == _pages.length - 1
                                      ? 'ابدأ الرحلة'
                                      : 'التالي',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentPage == _pages.length - 1
                                      ? Icons.favorite_rounded
                                      : Icons.arrow_back_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = index == _currentPage;
    final pageColor = isDark ? page.darkColor : page.lightColor;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final slideOffset = isActive
            ? Curves.easeOutCubic.transform(_animController.value)
            : 1.0;
        final opacity = isActive
            ? _animController.value.clamp(0.0, 1.0)
            : 1.0;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - slideOffset)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    pageColor.withValues(alpha: 0.15),
                    pageColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: pageColor.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: pageColor.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  page.emoji,
                  style: const TextStyle(fontSize: 72),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Title
            Text(
              page.title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              page.description,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots(bool isDark) {
    return Row(
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: index == _currentPage ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: index == _currentPage
                ? LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF90CAF9),
                            const Color(0xFF64B5F6),
                          ]
                        : [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.7),
                          ],
                  )
                : null,
            color: index == _currentPage
                ? null
                : (isDark
                    ? AppColors.darkBorder
                    : Colors.grey[300]),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() async {
    await PrefsHelper.setFirstLaunch(false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }
}
