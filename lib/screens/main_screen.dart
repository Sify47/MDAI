// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/screens/services_screen.dart';
import 'home_screen_with_animations.dart';
import 'profile_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../services/quiz_service.dart';
import 'quiz/onboarding_quiz.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;
  bool _hasCheckedQuiz = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkMonthlyQuiz();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _checkMonthlyQuiz() async {
    if (_hasCheckedQuiz) return;
    _hasCheckedQuiz = true;

    try {
      final lastSession = await QuizService.getLastSession();

      if (lastSession != null) {
        final now = DateTime.now();
        final lastDate = lastSession.sessionDate;
        final daysSinceLastQuiz = now.difference(lastDate).inDays;

        // إذا مر 28 يوم (4 أسابيع) على آخر كويز
        if (daysSinceLastQuiz >= 28) {
          // الانتظار قليلاً ثم عرض التنبيه
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showQuizReminder();
            }
          });
        }
      }
    } catch (e) {
      print('❌ خطأ في التحقق من الكويز الشهري: $e');
    }
  }

  void _showQuizReminder() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('📋 تحديث التقييم'),
        content: const Text(
          'مر شهر على آخر تقييم لك. هل ترغب في إجراء تقييم جديد لمتابعة تطورك الصحي؟',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingQuiz()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إجراء التقييم'),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _fabController.forward(from: 0);
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const HomeScreenWithAnimations();
      case 1:
        return const ServicesScreen();
      case 2:
        return const ProfileScreen();
      default:
        return const HomeScreenWithAnimations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _getCurrentScreen(),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
