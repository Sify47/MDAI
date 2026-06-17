// lib/screens/quiz/quiz_analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:confetti/confetti.dart';
import 'package:vita/models/nutrition_model.dart';
import 'package:vita/screens/medications/medications_dashboard.dart';
import 'package:vita/screens/nutrition/nutrition_dashboard.dart';
import 'package:vita/screens/symptoms/symptoms_dashboard.dart';
import 'package:vita/screens/walking/walking_dashboard.dart';
import 'package:vita/utils/prefs_helper.dart';
import '../../constants/colors.dart';
import '../../services/quiz_service.dart';
import '../../models/quiz_models.dart';
import 'onboarding_quiz.dart';

class QuizAnalysisScreen extends StatefulWidget {
  const QuizAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<QuizAnalysisScreen> createState() => _QuizAnalysisScreenState();
}

class _QuizAnalysisScreenState extends State<QuizAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  QuizAnalysisResult? _analysis;
  QuizComparisonResult? _comparison;
  List<QuizSessionResponse> _sessions = [];
  bool _isLoading = true;
  bool _hasQuizData = false;
  String? _error;

  final Map<String, Map<String, dynamic>> _categories = {
    'sleep': {'name': 'النوم', 'icon': '🛌', 'color': const Color(0xFF6C5CE7)},
    'nutrition': {
      'name': 'التغذية',
      'icon': '🍎',
      'color': const Color(0xFF00B894),
    },
    'activity': {
      'name': 'النشاط البدني',
      'icon': '🏃',
      'color': const Color(0xFFE17055),
    },
    'mental': {
      'name': 'الصحة النفسية',
      'icon': '🧠',
      'color': const Color(0xFFA29BFE),
    },
    'physical': {
      'name': 'الأعراض الجسدية',
      'icon': '🤕',
      'color': const Color(0xFFFDCB6E),
    },
    'habits': {
      'name': 'العادات اليومية',
      'icon': '📱',
      'color': const Color(0xFF74B9FF),
    },
    'social': {
      'name': 'الصحة الاجتماعية',
      'icon': '👥',
      'color': const Color(0xFF55EFC4),
    },
    'medication': {
      'name': 'الأدوية',
      'icon': '💊',
      'color': const Color(0xFFFD79A8),
    },
    'environment': {
      'name': 'البيئة',
      'icon': '🌍',
      'color': const Color(0xFF0984E3),
    },
  };

  // ✅ الألوان المخصصة للوضع الفاتح والداكن
  final Map<String, Color> _lightColors = {
    'sleep': const Color(0xFF6C5CE7),
    'nutrition': const Color(0xFF00B894),
    'activity': const Color(0xFFE17055),
    'mental': const Color(0xFFA29BFE),
    'physical': const Color(0xFFFDCB6E),
    'habits': const Color(0xFF74B9FF),
    'social': const Color(0xFF55EFC4),
    'medication': const Color(0xFFFD79A8),
    'environment': const Color(0xFF0984E3),
  };

  final Map<String, Color> _darkColors = {
    'sleep': const Color(0xFF8B7FF0),
    'nutrition': const Color(0xFF55D6B2),
    'activity': const Color(0xFFF39C6D),
    'mental': const Color(0xFFB8B0FF),
    'physical': const Color(0xFFFFE082),
    'habits': const Color(0xFF8FC7FF),
    'social': const Color(0xFF75F0D8),
    'medication': const Color(0xFFFF9EC4),
    'environment': const Color(0xFF4DA6FF),
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _confettiController = ConfettiController(
      // Changed from AnimationController
      duration: const Duration(seconds: 5),
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        QuizService.analyzeQuiz(),
        QuizService.compareSessions(),
        QuizService.getSessions(),
      ]);

      final analysis = results[0] as QuizAnalysisResult;
      final comparison = results[1] as QuizComparisonResult;
      final sessions = results[2] as List<QuizSessionResponse>;

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _comparison = comparison;
          _sessions = sessions;
          _hasQuizData = analysis.hasAnalysis;
          _isLoading = false;

          if (comparison.hasComparison && comparison.scoreChange! > 0) {
            _confettiController.play();
            Future.delayed(const Duration(seconds: 3), () {
              _confettiController.stop();
            });
          }
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل تحليل الكويز: $e');
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ في تحميل البيانات';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToFeature(String category) {
    final userNutritionData = _getUserNutritionData();

    switch (category) {
      case 'nutrition':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NutritionDashboard(userData: userNutritionData),
          ),
        );
        break;
      case 'physical':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SymptomsDashboard()),
        );
        break;
      case 'activity':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WalkingDashboard(userData: userNutritionData),
          ),
        );
        break;
      case 'medication':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicationsDashboard()),
        );
        break;
      default:
        ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('✨ هذه الميزة ستكون متاحة قريباً'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.info,
          ),
        );
    }
  }

  // ✅ إضافة دالة مساعدة لجلب بيانات المستخدم
  UserNutritionData _getUserNutritionData() {
    final userData = PrefsHelper.getUserData();
    return UserNutritionData(
      id: PrefsHelper.getUserId() ?? 1,
      weight: (userData['weight'] ?? 70.0).toDouble(),
      height: (userData['height'] ?? 170.0).toDouble(),
      age: userData['age'] ?? 30,
      gender: userData['gender'] ?? 'ذكر',
      goal: userData['goal'] ?? 'تخسيس',
      activityLevel: userData['activityLevel'] ?? 'متوسط',
      weightLossRate: (userData['weightLossRate'] ?? 0.5).toString(),
      targetWeight: (userData['targetWeight'] ?? 70.0).toDouble(),
      diseases: List<String>.from(userData['diseases'] ?? []),
      targetCalories: (userData['targetCalories'] ?? 2000.0).toDouble(),
      bmr: (userData['bmr'] ?? 1500.0).toDouble(),
      tdee: (userData['tdee'] ?? 2000.0).toDouble(),
      createdAt: DateTime.now(),
      waterIntake: (userData['waterIntake'] ?? 2.5).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('📊 تحليل نمط الحياة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_comparison?.hasComparison == true &&
                _comparison!.scoreChange! > 0)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [
                    Colors.red,
                    Colors.green,
                    Colors.blue,
                    Colors.yellow,
                    Colors.pink,
                    Colors.orange,
                  ],
                  numberOfParticles: 30,
                ),
              ),
            _isLoading
                ? _buildLoading(theme, isDark)
                : _error != null
                ? _buildError(theme, isDark)
                : _hasQuizData
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      color: theme.colorScheme.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildWelcomeCard(theme, isDark),
                            const SizedBox(height: 16),
                            if (_comparison?.hasComparison == true)
                              _buildComparisonCard(theme, _comparison!, isDark),
                            const SizedBox(height: 16),
                            _buildOverallRatingCard(theme, _analysis!, isDark),
                            const SizedBox(height: 16),
                            _buildCategoriesChartCard(theme, isDark),
                            const SizedBox(height: 16),
                            _buildStrengthsWeaknessesCard(theme, isDark),
                            const SizedBox(height: 16),
                            _buildRecommendationsCard(theme, isDark),
                            const SizedBox(height: 16),
                            _buildQuizHistoryCard(theme, isDark),
                            const SizedBox(height: 24),
                            _buildNextQuizCard(theme, isDark),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  )
                : _buildNoQuizData(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحليل بياناتك...',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.red[300] : Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoQuizData(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]
                    : AppColors.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 64,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لم تقم بإجراء أي كويز بعد',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'قم بإجراء كويز التقييم الأولي للحصول على تحليل شامل لنمط حياتك',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingQuiz()),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('ابدأ الكويز الآن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
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

  Widget _buildWelcomeCard(ThemeData theme, bool isDark) {
    final session = _sessions.isNotEmpty ? _sessions.first : null;
    final sessionDate = session?.sessionDate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تحليل نمط حياتك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sessionDate != null
                      ? 'آخر تحديث: ${_formatDate(sessionDate)}'
                      : 'بناءً على آخر تقييم لك',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (_sessions.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_sessions.length} جلسات',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    ThemeData theme,
    QuizComparisonResult comparison,
    bool isDark,
  ) {
    final isImproved =
        comparison.scoreChange != null && comparison.scoreChange! > 0;
    final changeColor = isImproved ? AppColors.success : AppColors.danger;
    final changeIcon = isImproved ? Icons.trending_up : Icons.trending_down;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [changeColor.withOpacity(0.15), const Color(0xFF1E1E1E)]
                    : [changeColor.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: changeColor.withOpacity(isDark ? 0.3 : 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(changeIcon, color: changeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'المقارنة مع التقييم السابق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildComparisonItem(
                      'السابق',
                      comparison.previousTotalScore?.toString() ?? '0',
                      'نقطة',
                      isDark ? Colors.grey[400]! : Colors.grey,
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(isDark ? 0.2 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(changeIcon, color: changeColor, size: 28),
                    ),
                    _buildComparisonItem(
                      'الحالي',
                      comparison.currentTotalScore?.toString() ?? '0',
                      'نقطة',
                      changeColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isImproved ? Icons.emoji_events : Icons.info_outline,
                        color: changeColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          comparison.message ??
                              (isImproved
                                  ? '🎉 أحسنت! لقد تحسنت نتائجك عن المرة السابقة'
                                  : '⚠️ نتائجك تراجعت قليلاً، يمكنك تحسينها باتباع التوصيات'),
                          style: TextStyle(
                            fontSize: 13,
                            color: changeColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComparisonItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.7)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildOverallRatingCard(
    ThemeData theme,
    QuizAnalysisResult analysis,
    bool isDark,
  ) {
    final rating = analysis.overallRating;
    final ratingColor = rating['color'] != null
        ? Color(
            int.parse(rating['color'].substring(1, 7), radix: 16) + 0xFF000000,
          )
        : AppColors.primary;
    final totalScore = analysis.totalScore ?? 0;
    final maxScore = 34 * 3;
    final percentage = maxScore > 0 ? (totalScore / maxScore) * 100 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'التقييم العام',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 12,
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(ratingColor),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$totalScore',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: ratingColor,
                        ),
                      ),
                      Text(
                        'من $maxScore',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: ratingColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rating['level'] ?? 'متوسط',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ratingColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 150,
                    child: Text(
                      rating['message'] ?? 'نمط حياتك يحتاج إلى بعض التحسينات',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesChartCard(ThemeData theme, bool isDark) {
    final categories = _analysis?.categoriesAnalysis ?? {};
    if (categories.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تحليل الفئات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final keys = categories.keys.toList();
                        if (value.toInt() >= 0 && value.toInt() < keys.length) {
                          final key = keys[value.toInt()];
                          final info = _categories[key] ?? {'icon': '📋'};
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              info['icon'],
                              style: const TextStyle(fontSize: 18),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: categories.entries.map((entry) {
                  final index = categories.keys.toList().indexOf(entry.key);
                  final percentage = (entry.value['percentage'] ?? 0)
                      .toDouble();
                  final baseColor = isDark
                      ? (_darkColors[entry.key] ?? AppColors.primary)
                      : (_lightColors[entry.key] ?? AppColors.primary);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: percentage,
                        color: baseColor,
                        width: 30,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthsWeaknessesCard(ThemeData theme, bool isDark) {
    final strengths = _analysis?.strengthAreas ?? [];
    final weaknesses = _analysis?.weaknessAreas ?? [];

    if (strengths.isEmpty && weaknesses.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💪 نقاط القوة والضعف',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (strengths.isNotEmpty) ...[
            Text(
              '✅ نقاط القوة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: strengths.map((category) {
                final info =
                    _categories[category] ?? {'name': category, 'icon': '📋'};
                final baseColor = isDark
                    ? (_darkColors[category] ?? AppColors.success)
                    : (_lightColors[category] ?? AppColors.success);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(info['icon'], style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        info['name'],
                        style: TextStyle(fontSize: 12, color: baseColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (weaknesses.isNotEmpty) ...[
            Text(
              '⚠️ تحتاج للتحسين',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weaknesses.map((category) {
                final info =
                    _categories[category] ?? {'name': category, 'icon': '📋'};
                final baseColor = isDark
                    ? (_darkColors[category] ?? AppColors.warning)
                    : (_lightColors[category] ?? AppColors.warning);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: baseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(info['icon'], style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        info['name'],
                        style: TextStyle(fontSize: 12, color: baseColor),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ التوصيات المخصصة - ألوان متناسقة في الوضع الفاتح والداكن
  Widget _buildRecommendationsCard(ThemeData theme, bool isDark) {
    final weaknesses = _analysis?.weaknessAreas ?? [];
    if (weaknesses.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هيدر الكارد
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.info.withOpacity(0.8),
                        AppColors.info.withOpacity(0.6),
                      ]
                    : [AppColors.info, AppColors.info.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.tips_and_updates,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'توصيات مخصصة لك',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${weaknesses.length} مجال يحتاج إلى تحسين',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🔥 أولوية عالية',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // قائمة التوصيات
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: weaknesses.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final info =
                    _categories[category] ?? {'name': category, 'icon': '📋'};
                final isLast = index == weaknesses.length - 1;
                final baseColor = isDark
                    ? (_darkColors[category] ?? AppColors.warning)
                    : (_lightColors[category] ?? const Color(0xFFE17055));

                return _buildAnimatedRecommendationCard(
                  theme,
                  info,
                  category,
                  index,
                  isLast,
                  isDark,
                  baseColor,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRecommendationCard(
    ThemeData theme,
    Map<String, dynamic> info,
    String category,
    int index,
    bool isLast,
    bool isDark,
    Color baseColor,
  ) {
    final isAvailable = _isFeatureAvailable(category);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(20 * (1 - opacity), 0),
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: baseColor.withOpacity(isDark ? 0.3 : 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الأيقونة الدائرية
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [baseColor, baseColor.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: baseColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            info['icon'],
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // المحتوى
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // العنوان والرقم
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: baseColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: baseColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    info['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : baseColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // نص التوصية
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: baseColor.withOpacity(
                                  isDark ? 0.1 : 0.05,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: baseColor.withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.format_quote,
                                    size: 16,
                                    color: baseColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getRecommendationText(category),
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: isDark
                                            ? Colors.grey[300]
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.format_quote,
                                    size: 16,
                                    color: baseColor.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ✅ زر الإجراء (يظهر فقط للميزات المتوفرة)
                            if (isAvailable)
                              InkWell(
                                onTap: () => _navigateToFeature(category),
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        baseColor,
                                        baseColor.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getActionIcon(category),
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getActionText(category),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ],
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
          ),
        );
      },
    );
  }

  // ✅ التحقق من توفر الميزة في النظام (nutrition, physical, activity, medication فقط)
  bool _isFeatureAvailable(String category) {
    const availableFeatures = {
      'nutrition',
      'physical',
      'activity',
      'medication',
    };
    return availableFeatures.contains(category);
  }

  IconData _getActionIcon(String category) {
    switch (category) {
      case 'nutrition':
        return Icons.restaurant;
      case 'physical':
        return Icons.sick;
      case 'activity':
        return Icons.directions_walk;
      case 'medication':
        return Icons.medication;
      default:
        return Icons.play_arrow;
    }
  }

  String _getActionText(String category) {
    switch (category) {
      case 'nutrition':
        return 'تسجيل وجبة';
      case 'physical':
        return 'تسجيل عرض';
      case 'activity':
        return 'محاكاة المشي';
      case 'medication':
        return 'الأدوية';
      default:
        return 'عرض';
    }
  }

  String _getRecommendationText(String category) {
    switch (category) {
      case 'sleep':
        return 'نظم مواعيد نومك، تجنب الشاشات قبل النوم بساعة';
      case 'nutrition':
        return 'زد من تناول الخضروات والفواكه، اشرب 8 أكواب ماء يومياً';
      case 'activity':
        return 'حاول ممارسة الرياضة 30 دقيقة يومياً، استخدم الدرج بدل المصعد';
      case 'mental':
        return 'مارس تمارين التنفس العميق، خصص وقتاً للاسترخاء';
      case 'physical':
        return 'سجل أعراضك يومياً، استشر طبيبك إذا استمرت';
      case 'habits':
        return 'قلل وقت الشاشات، حاول أن تنام مبكراً';
      case 'social':
        return 'خصص وقتاً للتواصل مع العائلة والأصدقاء';
      case 'medication':
        return 'استخدم التذكيرات لمواعيد الأدوية';
      case 'environment':
        return 'حسن تهوية منزلك، قلل مصادر التوتر';
      default:
        return 'تابع تقدمك في التطبيق';
    }
  }

  Widget _buildQuizHistoryCard(ThemeData theme, bool isDark) {
    if (_sessions.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 تاريخ التقييمات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sessions.length > 5 ? 5 : _sessions.length,
            separatorBuilder: (_, __) =>
                Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
            itemBuilder: (context, index) {
              final session = _sessions[index];
              final scoreColor = session.totalScore > 70
                  ? AppColors.success
                  : session.totalScore > 40
                  ? AppColors.warning
                  : AppColors.danger;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: session.isOnboarding
                      ? (isDark
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.1))
                      : (isDark
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.success.withOpacity(0.1)),
                  child: Icon(
                    session.isOnboarding ? Icons.quiz : Icons.refresh,
                    size: 20,
                    color: session.isOnboarding
                        ? AppColors.primary
                        : AppColors.success,
                  ),
                ),
                title: Text(
                  session.isOnboarding ? 'التقييم الأولي' : 'تقييم شهري',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  _formatDate(session.sessionDate),
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                trailing: Text(
                  '${session.totalScore} نقطة',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNextQuizCard(ThemeData theme, bool isDark) {
    final lastSession = _sessions.isNotEmpty ? _sessions.first : null;
    final needToTakeQuiz = lastSession == null;

    int daysRemaining = 0;
    bool shouldTakeQuiz = false;
    String statusMessage = '';
    IconData statusIcon = Icons.check_circle;
    Color statusColor = AppColors.success;

    if (lastSession != null) {
      final now = DateTime.now();
      final daysSinceLastQuiz = now.difference(lastSession.sessionDate).inDays;
      daysRemaining = 28 - daysSinceLastQuiz;

      if (daysRemaining <= 0) {
        shouldTakeQuiz = true;
        statusMessage = '📢 حان وقت إجراء التقييم الشهري!';
        statusIcon = Icons.notifications_active;
        statusColor = AppColors.warning;
      } else if (daysRemaining <= 7) {
        statusMessage = '⏰ باقي $daysRemaining أيام على التقييم الشهري';
        statusIcon = Icons.timer;
        statusColor = AppColors.info;
      } else {
        statusMessage = '✅ تم التقييم منذ ${daysSinceLastQuiz} يوم';
        statusIcon = Icons.check_circle;
        statusColor = AppColors.success;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: shouldTakeQuiz
              ? isDark
                    ? [
                        Colors.orange.withOpacity(0.15),
                        Colors.red.withOpacity(0.1),
                      ]
                    : [
                        Colors.orange.withOpacity(0.1),
                        Colors.red.withOpacity(0.05),
                      ]
              : isDark
              ? [
                  AppColors.success.withOpacity(0.15),
                  Colors.green.withOpacity(0.1),
                ]
              : [
                  AppColors.success.withOpacity(0.1),
                  Colors.green.withOpacity(0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isDark ? 0.2 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shouldTakeQuiz ? 'تقييم شهري جديد' : 'التقييم القادم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusMessage,
                      style: TextStyle(fontSize: 13, color: statusColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: shouldTakeQuiz || needToTakeQuiz
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingQuiz(),
                        ),
                      ).then((_) => _loadData());
                    }
                  : null,
              icon: Icon(
                shouldTakeQuiz ? Icons.play_arrow : Icons.lock_outline,
                size: 18,
              ),
              label: Text(
                shouldTakeQuiz || needToTakeQuiz
                    ? 'إجراء التقييم الآن'
                    : 'التقييم متاح بعد ${daysRemaining} يوم',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: shouldTakeQuiz
                    ? AppColors.primary
                    : (isDark ? Colors.grey[700] : Colors.grey[400]),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final quizDate = DateTime(date.year, date.month, date.day);

    if (quizDate == today) {
      return 'اليوم';
    } else if (quizDate == today.subtract(const Duration(days: 1))) {
      return 'أمس';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
