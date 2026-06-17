// lib/screens/activities/activity_statistics.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../constants/colors.dart';
import '../../services/activity_api.dart';

class ActivityStatistics extends StatefulWidget {
  const ActivityStatistics({Key? key}) : super(key: key);

  @override
  State<ActivityStatistics> createState() => _ActivityStatisticsState();
}

class _ActivityStatisticsState extends State<ActivityStatistics>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic> _dailyStats = {};
  Map<String, dynamic> _weeklyStats = {};
  Map<String, dynamic> _monthlyStats = {};
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
    _loadStats();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ActivityService.getDailyStats(),
        ActivityService.getWeeklyStats(),
        ActivityService.getMonthlyStats(),
      ]).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      setState(() {
        _dailyStats = results[0];
        _weeklyStats = results[1];
        _monthlyStats = results[2];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      String message = 'فشل في تحميل الإحصائيات';
      if (e is TimeoutException) {
        message = 'انتهت المهلة الزمنية. تحقق من اتصالك وحاول مرة أخرى';
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
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
          title: Text('📊 إحصائيات الأنشطة'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              onPressed: _loadStats,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? _buildShimmerLoading(theme)
              : _errorMessage != null
              ? _buildError(theme)
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimationLimiter(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 500),
                            childAnimationBuilder: (widget) => SlideAnimation(
                              verticalOffset: 30,
                              child: FadeInAnimation(child: widget),
                            ),
                            children: [
                              _buildDailyStats(theme),
                              const SizedBox(height: 16),
                              _buildWeeklyStats(theme),
                              const SizedBox(height: 16),
                              _buildMonthlyStats(theme),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      3,
                      (_) => Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 40,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
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

  Widget _buildSectionHeader(
    ThemeData theme,
    String emoji,
    String title,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyStats(ThemeData theme) {
    final totalActivities = _dailyStats['total_activities'] ?? 0;
    final completedActivities = _dailyStats['completed_activities'] ?? 0;
    final completionRate = _dailyStats['completion_rate'] ?? 0;
    final activitiesByCategory =
        _dailyStats['activities_by_category'] as Map? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.colorScheme.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            theme,
            '📅',
            'إحصائيات اليوم',
            theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                title: 'إجمالي',
                value: '$totalActivities',
                icon: Icons.list,
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              _buildStatCard(
                title: 'مكتمل',
                value: '$completedActivities',
                icon: Icons.check_circle,
                color: AppColors.success,
                theme: theme,
              ),
              _buildStatCard(
                title: 'نسبة',
                value: '$completionRate%',
                icon: Icons.percent,
                color: AppColors.warning,
                theme: theme,
              ),
            ],
          ),
          if (activitiesByCategory.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'التوزيع حسب الفئة',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ...activitiesByCategory.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key, style: theme.textTheme.bodySmall),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          _buildExerciseStats(theme, _dailyStats, 'اليوم'),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats(ThemeData theme) {
    final totalActivities = _weeklyStats['total_activities'] ?? 0;
    final completedActivities = _weeklyStats['completed_activities'] ?? 0;
    final completionRate = _weeklyStats['completion_rate'] ?? 0;
    final dailyStats = _weeklyStats['daily_stats'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.05),
            AppColors.success.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            theme,
            '📆',
            'إحصائيات الأسبوع',
            AppColors.success,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                title: 'إجمالي',
                value: '$totalActivities',
                icon: Icons.list,
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              _buildStatCard(
                title: 'مكتمل',
                value: '$completedActivities',
                icon: Icons.check_circle,
                color: AppColors.success,
                theme: theme,
              ),
              _buildStatCard(
                title: 'نسبة',
                value: '$completionRate%',
                icon: Icons.percent,
                color: AppColors.warning,
                theme: theme,
              ),
            ],
          ),
          if (dailyStats.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'الأداء اليومي',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ...dailyStats.map(
              (day) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            day['date']?.toString().substring(5) ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value:
                                  ((day['total'] as num?)?.toDouble() ?? 0) > 0
                                  ? ((day['completed'] as num?)?.toDouble() ??
                                            0) /
                                        ((day['total'] as num?)?.toDouble() ??
                                            1)
                                  : 0.0,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${day['completed']}/${day['total']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          _buildExerciseStats(theme, _weeklyStats, 'الأسبوع'),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats(ThemeData theme) {
    final totalActivities = _monthlyStats['total_activities'] ?? 0;
    final completedActivities = _monthlyStats['completed_activities'] ?? 0;
    final completionRate = _monthlyStats['completion_rate'] ?? 0;
    final categories = _monthlyStats['categories'] as Map? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.05),
            AppColors.info.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, '📊', 'إحصائيات الشهر', AppColors.info),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                title: 'إجمالي',
                value: '$totalActivities',
                icon: Icons.list,
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              _buildStatCard(
                title: 'مكتمل',
                value: '$completedActivities',
                icon: Icons.check_circle,
                color: AppColors.success,
                theme: theme,
              ),
              _buildStatCard(
                title: 'نسبة',
                value: '$completionRate%',
                icon: Icons.percent,
                color: AppColors.warning,
                theme: theme,
              ),
            ],
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'التوزيع حسب الفئة',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ...categories.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key, style: theme.textTheme.bodySmall),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${entry.value}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          _buildExerciseStats(theme, _monthlyStats, 'الشهر'),
        ],
      ),
    );
  }

  Widget _buildExerciseStats(
    ThemeData theme,
    Map<String, dynamic> stats,
    String periodLabel,
  ) {
    final exerciseCount = stats['total_exercise_activities'] ?? 0;
    if (exerciseCount == 0) return const SizedBox.shrink();

    final totalVolume = stats['total_volume'] ?? 0;
    final totalExerciseCalories = stats['total_exercise_calories'] ?? 0;
    final muscleGroups = stats['muscle_group_distribution'] as Map? ?? {};
    final topExercises = stats['most_performed_exercises'] as Map? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 16,
                color: Color(0xFF7C4DFF),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '🏋️ تمارين $periodLabel',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard(
              title: 'تمارين',
              value: '$exerciseCount',
              icon: Icons.fitness_center,
              color: const Color(0xFF7C4DFF),
              theme: theme,
            ),
            _buildStatCard(
              title: 'حجم',
              value: _formatVolume(totalVolume),
              icon: Icons.monitor_weight,
              color: const Color(0xFFFF6D00),
              theme: theme,
            ),
            _buildStatCard(
              title: 'سعرات',
              value: '$totalExerciseCalories',
              icon: Icons.local_fire_department,
              color: const Color(0xFFFF3D00),
              theme: theme,
            ),
          ],
        ),
        if (muscleGroups.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '💪 توزيع العضلات',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...muscleGroups.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key, style: theme.textTheme.bodySmall),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.value}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7C4DFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (topExercises.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '⭐ أشهر التمارين',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...topExercises.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(entry.key, style: theme.textTheme.bodySmall),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.value} مرة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatVolume(dynamic volume) {
    final num vol = (volume is num) ? volume : 0;
    if (vol >= 10000) {
      return '${(vol / 1000).toStringAsFixed(1)}k';
    } else if (vol >= 1000) {
      return '${(vol / 1000).toStringAsFixed(2)}k';
    }
    return vol.toStringAsFixed(0);
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
