import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/walking_model.dart';
import '../../services/walking_api.dart';

class WalkingChallenges extends StatefulWidget {
  const WalkingChallenges({Key? key}) : super(key: key);

  @override
  State<WalkingChallenges> createState() => _WalkingChallengesState();
}

class _WalkingChallengesState extends State<WalkingChallenges>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  List<WalkingActivity> _activities = [];
  WalkingStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        WalkingService.getWeekActivities(),
        WalkingService.getWalkingStats(),
      ]);

      if (!mounted) return;

      final activities = results[0] as List<WalkingActivity>;
      final stats = results[1] as WalkingStats?;

      setState(() {
        _activities = activities;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'فشل في تحميل التحديات';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getTodayStats() {
    final now = DateTime.now();
    final todayActivities = _activities
        .where(
          (a) =>
              a.activityDate.year == now.year &&
              a.activityDate.month == now.month &&
              a.activityDate.day == now.day,
        )
        .toList();

    int todaySteps = todayActivities.fold(0, (sum, a) => sum + a.steps);
    int todayDuration = todayActivities.fold(
      0,
      (sum, a) => sum + a.durationMinutes,
    );

    return {'steps': todaySteps, 'duration': todayDuration};
  }

  Map<String, dynamic> _getWeekStats() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekActivities = _activities
        .where((a) => a.activityDate.isAfter(weekAgo))
        .toList();

    int weekSteps = weekActivities.fold(0, (sum, a) => sum + a.steps);
    int weekDays = weekActivities
        .map(
          (a) => DateTime(
            a.activityDate.year,
            a.activityDate.month,
            a.activityDate.day,
          ),
        )
        .toSet()
        .length;

    return {'steps': weekSteps, 'days': weekDays};
  }

  int _getLongestStreak() {
    if (_activities.isEmpty) return 0;

    final sortedActivities = _activities.toList()
      ..sort((a, b) => a.activityDate.compareTo(b.activityDate));

    final uniqueDays =
        sortedActivities
            .map(
              (a) => DateTime(
                a.activityDate.year,
                a.activityDate.month,
                a.activityDate.day,
              ),
            )
            .toSet()
            .toList()
          ..sort();

    if (uniqueDays.isEmpty) return 0;

    int currentStreak = 1;
    int longestStreak = 1;

    for (int i = 1; i < uniqueDays.length; i++) {
      final diff = uniqueDays[i].difference(uniqueDays[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak
            ? currentStreak
            : longestStreak;
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  Map<String, dynamic> _getBestDay() {
    if (_activities.isEmpty) {
      return {'steps': 0, 'date': null};
    }

    final stepsByDay = <DateTime, int>{};
    for (var activity in _activities) {
      final date = DateTime(
        activity.activityDate.year,
        activity.activityDate.month,
        activity.activityDate.day,
      );
      stepsByDay[date] = (stepsByDay[date] ?? 0) + activity.steps;
    }

    if (stepsByDay.isEmpty) return {'steps': 0, 'date': null};

    final bestDay = stepsByDay.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return {'steps': bestDay.value, 'date': bestDay.key};
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
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
          title: Text('🏆 تحديات المشي'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              onPressed: _loadData,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? _buildLoading(theme)
              : _errorMessage != null
              ? _buildError(theme)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildSectionTitle('تحديات يومية', theme),
                        const SizedBox(height: 12),
                        _buildDailyChallenge(
                          title: '8,000 خطوة',
                          progress: _getTodayStats()['steps'] / 8000,
                          current: _getTodayStats()['steps'],
                          target: 8000,
                          reward: '50 نقطة',
                          color: AppColors.walking,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildDailyChallenge(
                          title: '30 دقيقة مشي متواصل',
                          progress: _getTodayStats()['duration'] / 30,
                          current: _getTodayStats()['duration'],
                          target: 30,
                          reward: '30 نقطة',
                          color: AppColors.success,
                          completed: _getTodayStats()['duration'] >= 30,
                          theme: theme,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('تحديات أسبوعية', theme),
                        const SizedBox(height: 12),
                        _buildWeeklyChallenge(
                          title: '50,000 خطوة',
                          progress: _getWeekStats()['steps'] / 50000,
                          current: _getWeekStats()['steps'],
                          target: 50000,
                          reward: '200 نقطة',
                          daysLeft: 7 - (_getWeekStats()['days'] as int),
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildWeeklyChallenge(
                          title: 'مشي 5 أيام',
                          progress: _getWeekStats()['days'] / 5,
                          current: _getWeekStats()['days'],
                          target: 5,
                          reward: '150 نقطة',
                          daysLeft: 5 - (_getWeekStats()['days'] as int),
                          theme: theme,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('الإنجازات المكتسبة', theme),
                        const SizedBox(height: 12),
                        _buildEarnedAchievement(
                          icon: '🥇',
                          title: 'المثابرة',
                          description: 'مشي 7 أيام متتالية',
                          date: _getLongestStreak() >= 7
                              ? 'تم التحقيق'
                              : 'لم يتحقق بعد',
                          achieved: _getLongestStreak() >= 7,
                          theme: theme,
                        ),
                        _buildEarnedAchievement(
                          icon: '🎯',
                          title: 'هدف العشرة آلاف',
                          description: '10,000 خطوة في يوم واحد',
                          date: _getBestDay()['steps'] >= 10000
                              ? 'تم التحقيق'
                              : 'لم يتحقق بعد',
                          achieved: _getBestDay()['steps'] >= 10000,
                          theme: theme,
                        ),
                        _buildEarnedAchievement(
                          icon: '🔥',
                          title: 'البداية القوية',
                          description: 'أول 5 أيام مشي',
                          date: _activities.length >= 5
                              ? 'تم التحقيق'
                              : 'لم يتحقق بعد',
                          achieved: _activities.length >= 5,
                          theme: theme,
                        ),
                        if (_stats != null)
                          _buildEarnedAchievement(
                            icon: '📊',
                            title: 'إجمالي الخطوات',
                            description:
                                '${_formatNumber(_stats!.totalSteps)} خطوة',
                            date: 'إجمالي',
                            achieved: true,
                            theme: theme,
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل التحديات...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
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
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDailyChallenge({
    required String title,
    required double progress,
    required int current,
    required int target,
    required String reward,
    required Color color,
    required ThemeData theme,
    bool completed = false,
  }) {
    final safeProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reward,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: safeProgress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: completed ? AppColors.success : color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatNumber(current)} / ${_formatNumber(target)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (completed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✅ مكتمل',
                    style: TextStyle(color: AppColors.success, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChallenge({
    required String title,
    required double progress,
    required int current,
    required int target,
    required String reward,
    required int daysLeft,
    required ThemeData theme,
  }) {
    final safeProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.walking.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reward,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.walking,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: safeProgress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: safeProgress >= 1.0
                            ? AppColors.success
                            : AppColors.walking,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatNumber(current)} / ${_formatNumber(target)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (safeProgress >= 1.0)
                const Text(
                  '✅ مكتمل',
                  style: TextStyle(color: AppColors.success, fontSize: 12),
                )
              else
                Text(
                  'متبقي $daysLeft أيام',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarnedAchievement({
    required String icon,
    required String title,
    required String description,
    required String date,
    required ThemeData theme,
    bool achieved = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.06),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: achieved
                  ? AppColors.walking.withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 26,
                  color: achieved
                      ? AppColors.walking
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: achieved
                        ? null
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: achieved
                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: achieved
                        ? theme.colorScheme.onSurface.withOpacity(0.5)
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          if (achieved)
            Icon(Icons.emoji_events, color: AppColors.walking, size: 28)
          else
            Icon(
              Icons.lock,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              size: 22,
            ),
        ],
      ),
    );
  }
}
