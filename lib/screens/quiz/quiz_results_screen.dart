// lib/screens/quiz/quiz_results_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:confetti/confetti.dart';
import 'package:vita/models/quiz_models.dart';
import '../../constants/colors.dart';
import '../../services/quiz_service.dart';
import '../main_screen.dart';

class QuizResultsScreen extends StatefulWidget {
  final int sessionId;
  final int totalScore;
  final Map<String, int> categoryScores;
  final bool isOnboarding;
  final QuizAnalysisResult? analysis;

  const QuizResultsScreen({
    Key? key,
    required this.sessionId,
    required this.totalScore,
    required this.categoryScores,
    required this.isOnboarding,
    this.analysis,
  }) : super(key: key);

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;

  QuizAnalysisResult? _analysis;
  QuizComparisonResult? _comparison;
  bool _isLoadingAnalysis = true;

  final Map<String, Map<String, dynamic>> _categoriesInfo = {
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
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 10),
    );
    _animationController.forward();
    _confettiController.play();
    _loadAnalysis();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoadingAnalysis = true;
    });

    final analysis = widget.analysis ?? await QuizService.analyzeQuiz();
    final comparison = await QuizService.compareSessions();

    setState(() {
      _analysis = analysis;
      _comparison = comparison;
      _isLoadingAnalysis = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGoodScore =
        _analysis?.overallRating['level'] == 'ممتاز' ||
        _analysis?.overallRating['level'] == 'جيد';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // خلفية
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isGoodScore
                      ? [AppColors.success.withOpacity(0.1), Colors.transparent]
                      : [
                          AppColors.warning.withOpacity(0.1),
                          Colors.transparent,
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Confetti (للمستخدمين المتميزين فقط)
            if (isGoodScore && widget.isOnboarding)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: true,
                  colors: const [
                    Colors.red,
                    Colors.green,
                    Colors.blue,
                    Colors.yellow,
                    Colors.pink,
                    Colors.orange,
                  ],
                  numberOfParticles: 20,
                  maxBlastForce: 5,
                  minBlastForce: 2,
                ),
              ),
            // المحتوى الرئيسي
            FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              isGoodScore
                                  ? AppColors.success
                                  : AppColors.warning,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isGoodScore
                                        ? Icons.emoji_events
                                        : Icons.psychology,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.isOnboarding
                                    ? '🎉 اكتمل التقييم!'
                                    : '📊 نتيجة التقييم',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.isOnboarding
                                    ? 'شكراً لمشاركتنا رحلتك الصحية'
                                    : 'إليك تحليل نمط حياتك',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildScoreCard(theme),
                          const SizedBox(height: 24),
                          if (!_isLoadingAnalysis && _analysis != null)
                            _buildOverallAnalysis(theme, _analysis!),
                          const SizedBox(height: 24),
                          if (!_isLoadingAnalysis &&
                              _comparison != null &&
                              _comparison!.hasComparison &&
                              !widget.isOnboarding)
                            _buildComparisonCard(theme, _comparison!),
                          const SizedBox(height: 24),
                          if (!_isLoadingAnalysis && _analysis != null)
                            _buildCategoriesAnalysis(theme, _analysis!),
                          const SizedBox(height: 24),
                          if (!_isLoadingAnalysis && _analysis != null)
                            _buildStrengthsAndWeaknesses(theme, _analysis!),
                          const SizedBox(height: 24),
                          if (!_isLoadingAnalysis && _analysis != null)
                            _buildRecommendations(theme, _analysis!),
                          const SizedBox(height: 32),
                          _buildActionButton(theme),
                          const SizedBox(height: 20),
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
    );
  }

  Widget _buildScoreCard(ThemeData theme) {
    final maxScore = 34 * 3; // 34 سؤال × 3 أقصى درجة
    final percentage = maxScore > 0 ? (widget.totalScore / maxScore) * 100 : 0;
    Color scoreColor = percentage >= 70
        ? AppColors.success
        : percentage >= 40
        ? AppColors.warning
        : AppColors.danger;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.totalScore.toDouble()),
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scoreColor, scoreColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: scoreColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'نتيجة تقييم نمط الحياة',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'من أصل $maxScore نقطة',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${percentage.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallAnalysis(ThemeData theme, QuizAnalysisResult analysis) {
    final rating = analysis.overallRating;
    final ratingColor = rating['color'] != null
        ? Color(
            int.parse(rating['color'].substring(1, 7), radix: 16) + 0xFF000000,
          )
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ratingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics, size: 20, color: ratingColor),
              ),
              const SizedBox(width: 12),
              const Text(
                'التحليل العام',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ratingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rating['level'] ?? 'متوسط',
                  style: TextStyle(
                    color: ratingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'تاريخ التقييم: ${_formatDate(analysis.sessionDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rating['message'] ?? 'نمط حياتك يحتاج إلى بعض التحسينات',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    ThemeData theme,
    QuizComparisonResult comparison,
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
                colors: [changeColor.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: changeColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(changeIcon, color: changeColor),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'المقارنة مع التقييم السابق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCompareItem(
                      'السابق',
                      comparison.previousTotalScore?.toString() ?? '0',
                      'نقطة',
                      Colors.grey,
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(changeIcon, color: changeColor, size: 28),
                    ),
                    _buildCompareItem(
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
                    color: changeColor.withOpacity(0.1),
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

  Widget _buildCompareItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildCategoriesAnalysis(
    ThemeData theme,
    QuizAnalysisResult analysis,
  ) {
    final categories = analysis.categoriesAnalysis;
    if (categories.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pie_chart, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'تحليل الفئات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
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
                          final info = _categoriesInfo[key] ?? {'icon': '📋'};
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
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: categories.entries.map((entry) {
                  final index = categories.keys.toList().indexOf(entry.key);
                  final percentage = (entry.value['percentage'] ?? 0)
                      .toDouble();
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: percentage,
                        color:
                            (_categoriesInfo[entry.key]?['color'] as Color?) ??
                            AppColors.primary,
                        width: 30,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: Colors.grey.withOpacity(0.1),
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

  Widget _buildStrengthsAndWeaknesses(
    ThemeData theme,
    QuizAnalysisResult analysis,
  ) {
    final strengths = analysis.strengthAreas;
    final weaknesses = analysis.weaknessAreas;

    if (strengths.isEmpty && weaknesses.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
          const Text(
            '💪 نقاط القوة والضعف',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (strengths.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'نقاط القوة:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: strengths.map((category) {
                final info =
                    _categoriesInfo[category] ??
                    {
                      'name': category,
                      'icon': '📋',
                      'color': AppColors.success,
                    };
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${info['icon']} ${info['name']}',
                    style: TextStyle(fontSize: 12, color: info['color']),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (weaknesses.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.warning, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'تحتاج للتحسين:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: weaknesses.map((category) {
                final info =
                    _categoriesInfo[category] ??
                    {
                      'name': category,
                      'icon': '📋',
                      'color': AppColors.warning,
                    };
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (info['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${info['icon']} ${info['name']}',
                    style: TextStyle(fontSize: 12, color: info['color']),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations(ThemeData theme, QuizAnalysisResult analysis) {
    final isDark = theme.brightness == Brightness.dark;
    final weaknesses = analysis.weaknessAreas;
    if (weaknesses.isEmpty) return const SizedBox();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.info.withOpacity(0.1), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppColors.info),
                      const SizedBox(width: 12),
                      const Text(
                        '💡 توصيات مخصصة لك',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...weaknesses.map((category) {
                    final info =
                        _categoriesInfo[category] ??
                        {'name': category, 'icon': '📋'};
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  (info['color'] as Color?)?.withOpacity(0.1) ??
                                  AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                info['icon'],
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  info['name'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getRecommendationText(category),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          child: Text(
            widget.isOnboarding ? '✨ ابدأ رحلتك الصحية' : '📊 العودة للرئيسية',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return '${date.day}/${date.month}/${date.year}';
  }
}
