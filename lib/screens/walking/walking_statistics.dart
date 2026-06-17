import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../constants/colors.dart';
import '../../models/walking_model.dart';
import '../../services/walking_api.dart';

class WalkingStatistics extends StatefulWidget {
  const WalkingStatistics({Key? key}) : super(key: key);

  @override
  State<WalkingStatistics> createState() => _WalkingStatisticsState();
}

class _WalkingStatisticsState extends State<WalkingStatistics>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _selectedPeriod = 'week'; // week, month, year

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
        WalkingService.getAllActivities(),
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
        _errorMessage = 'فشل في تحميل الإحصائيات';
        _isLoading = false;
      });
    }
  }

  List<WalkingActivity> _getFilteredActivities() {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _activities
            .where((a) => a.activityDate.isAfter(weekAgo))
            .toList();
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return _activities
            .where((a) => a.activityDate.isAfter(monthAgo))
            .toList();
      case 'year':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        return _activities
            .where((a) => a.activityDate.isAfter(yearAgo))
            .toList();
      default:
        return _activities;
    }
  }

  Map<String, dynamic> _getPeriodStats() {
    final filtered = _getFilteredActivities();

    int totalSteps = filtered.fold(0, (sum, a) => sum + a.steps);
    double totalDistance = filtered.fold(0.0, (sum, a) => sum + a.distanceKm);
    int totalCalories = filtered.fold(0, (sum, a) => sum + a.caloriesBurned);
    int avgSteps = filtered.isNotEmpty
        ? (totalSteps / filtered.length).round()
        : 0;

    Map<DateTime, int> stepsByDay = {};
    for (var activity in filtered) {
      final date = DateTime(
        activity.activityDate.year,
        activity.activityDate.month,
        activity.activityDate.day,
      );
      stepsByDay[date] = (stepsByDay[date] ?? 0) + activity.steps;
    }

    final sortedDays = stepsByDay.keys.toList()..sort();

    return {
      'totalSteps': totalSteps,
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'avgSteps': avgSteps,
      'stepsByDay': stepsByDay,
      'sortedDays': sortedDays,
    };
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
          title: Text('📊 إحصائيات المشي'),
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
                        _buildPeriodSelector(theme),
                        const SizedBox(height: 24),
                        _buildStatsSummary(theme),
                        const SizedBox(height: 24),
                        _buildChart(theme),
                        const SizedBox(height: 24),
                        _buildAchievements(theme),
                        const SizedBox(height: 24),
                        _buildActivityLog(theme),
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
            'جاري تحميل الإحصائيات...',
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

  Widget _buildPeriodSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPeriodButton('أسبوع', 'week', theme),
          _buildPeriodButton('شهر', 'month', theme),
          _buildPeriodButton('سنة', 'year', theme),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value, ThemeData theme) {
    bool isSelected = _selectedPeriod == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(ThemeData theme) {
    final stats = _getPeriodStats();
    final totalSteps = stats['totalSteps'] as int;
    final totalDistance = stats['totalDistance'] as double;
    final totalCalories = stats['totalCalories'] as int;
    final avgSteps = stats['avgSteps'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.walking, theme.colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.walking.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'إجمالي الخطوات',
                _formatNumber(totalSteps),
                'خطوة',
                Colors.white,
                theme,
              ),
              _buildStatItem(
                'إجمالي المسافة',
                totalDistance.toStringAsFixed(1),
                'كم',
                Colors.white,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white30, height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'السعرات المحروقة',
                _formatNumber(totalCalories),
                'سعرة',
                Colors.white,
                theme,
              ),
              _buildStatItem(
                'متوسط يومي',
                _formatNumber(avgSteps),
                'خطوة',
                Colors.white,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChart(ThemeData theme) {
    final stats = _getPeriodStats();
    final stepsByDay = stats['stepsByDay'] as Map<DateTime, int>;
    final sortedDays = stats['sortedDays'] as List<DateTime>;

    if (sortedDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
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
        child: Center(
          child: Text(
            'لا توجد بيانات كافية للرسم البياني',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    final maxSteps = stepsByDay.values.reduce((a, b) => a > b ? a : b);
    final maxHeight = 140.0;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع الخطوات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(sortedDays.length, (index) {
                final day = sortedDays[index];
                final steps = stepsByDay[day] ?? 0;
                final height = maxSteps > 0
                    ? (steps / maxSteps) * maxHeight
                    : 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: height as double),
                          duration: Duration(milliseconds: 800 + (index * 50)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Container(
                              height: value,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    steps >= 6000
                                        ? AppColors.success
                                        : steps >= 4000
                                        ? AppColors.warning
                                        : AppColors.danger,
                                    AppColors.walking,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getDayLabel(day, theme),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          '${(steps / 1000).toStringAsFixed(1)}k',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: steps >= 6000
                                ? AppColors.success
                                : steps >= 4000
                                ? AppColors.warning
                                : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(DateTime date, ThemeData theme) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'اليوم';
    }
    return '${date.day}/${date.month}';
  }

  Widget _buildAchievements(ThemeData theme) {
    final stats = _getPeriodStats();
    final totalSteps = stats['totalSteps'] as int;
    final totalDistance = stats['totalDistance'] as double;

    List<Map<String, String>> achievements = [
      {'icon': '🏆', 'title': 'أفضل يوم', 'value': _getBestDay(), 'date': ''},
      {
        'icon': '🔥',
        'title': 'إجمالي الخطوات',
        'value': _formatNumber(totalSteps),
        'date': 'هذه الفترة',
      },
      {
        'icon': '⭐',
        'title': 'المسافة المقطوعة',
        'value': '${totalDistance.toStringAsFixed(1)} كم',
        'date': 'هذه الفترة',
      },
    ];

    if (_stats != null) {
      achievements.add({
        'icon': '🎯',
        'title': 'أفضل يوم',
        'value': '${_formatNumber(_stats!.bestDaySteps)} خطوة',
        'date': _formatDate(_stats!.bestDay),
      });
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 إنجازاتك',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: achievements.take(4).map((achievement) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.walking.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.walking.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      achievement['icon']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      achievement['title']!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      achievement['value']!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (achievement['date']!.isNotEmpty)
                      Text(
                        achievement['date']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getBestDay() {
    if (_activities.isEmpty) return 'لا يوجد';

    final stepsByDay = <DateTime, int>{};
    for (var activity in _activities) {
      final date = DateTime(
        activity.activityDate.year,
        activity.activityDate.month,
        activity.activityDate.day,
      );
      stepsByDay[date] = (stepsByDay[date] ?? 0) + activity.steps;
    }

    if (stepsByDay.isEmpty) return 'لا يوجد';

    final bestDay = stepsByDay.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return '${_formatNumber(bestDay.value)} خطوة';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildActivityLog(ThemeData theme) {
    final filtered = _getFilteredActivities().take(10).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
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
        child: Center(
          child: Column(
            children: [
              Icon(Icons.directions_walk, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'لا توجد نشاطات في هذه الفترة',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 آخر النشاطات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) =>
                Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
            itemBuilder: (context, index) {
              final activity = filtered[index];
              final date = activity.activityDate;
              final today = DateTime.now();

              String dateLabel;
              if (date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day) {
                dateLabel = 'اليوم';
              } else if (date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day - 1) {
                dateLabel = 'أمس';
              } else {
                dateLabel = '${date.day}/${date.month}';
              }

              return ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.walking.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_walk,
                    color: AppColors.walking,
                  ),
                ),
                title: Text(
                  dateLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${_formatNumber(activity.steps)} خطوة • ${activity.distanceKm.toStringAsFixed(1)} كم',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${activity.durationMinutes} د',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
