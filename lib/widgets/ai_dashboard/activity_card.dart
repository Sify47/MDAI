// lib/widgets/ai_dashboard/activity_card.dart
// 🏃 بطاقة الأنشطة البدنية

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/activity_api.dart';
import '../../models/activity_model.dart';

class ActivityCard extends StatefulWidget {
  const ActivityCard({Key? key}) : super(key: key);

  @override
  State<ActivityCard> createState() => ActivityCardState();
}

class ActivityCardState extends State<ActivityCard> {
  List<Activity> _todayActivities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  Future<void> loadActivities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final activities = await ActivityService.getTodayActivities();
      if (mounted) {
        setState(() {
          _todayActivities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل الأنشطة';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.green.shade900.withOpacity(0.3),
                  Colors.teal.shade900.withOpacity(0.3),
                ]
              : [Colors.green.withOpacity(0.05), Colors.teal.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDark),
          const SizedBox(height: 16),
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_todayActivities.isNotEmpty)
            ..._todayActivities
                .take(3)
                .map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildActivityItem(activity, theme, isDark),
                  ),
                )
          else
            _buildEmptyState(theme),
          if (_todayActivities.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Text(
                  '+${_todayActivities.length - 3} نشاط آخر',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final completed = _todayActivities
        .where((a) => a.isCompleted)
        .length;
    final total = _todayActivities.length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_run,
            color: Colors.green,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '🏃 أنشطتك اليوم',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (total > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$completed/$total',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? '',
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: loadActivities,
            child: const Icon(Icons.refresh, color: AppColors.danger, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_walk, size: 32, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'لا توجد أنشطة مسجلة اليوم',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ابدأ بتسجيل نشاطك الأول',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Activity activity, ThemeData theme, bool isDark) {
    final isCompleted = activity.isCompleted;
    final name = activity.title;
    final duration = activity.durationMinutes;
    final calories = activity.caloriesBurned ?? 0;

    IconData activityIcon;
    Color activityColor;
    switch (activity.category?.name ?? '') {
      case 'مشي':
      case 'walking':
        activityIcon = Icons.directions_walk;
        activityColor = Colors.green;
        break;
      case 'جري':
      case 'running':
        activityIcon = Icons.run_circle;
        activityColor = Colors.orange;
        break;
      case 'تمارين':
      case 'exercise':
        activityIcon = Icons.fitness_center;
        activityColor = Colors.red;
        break;
      case 'يوغا':
      case 'yoga':
        activityIcon = Icons.self_improvement;
        activityColor = Colors.purple;
        break;
      default:
        activityIcon = Icons.sports_handball;
        activityColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isCompleted
            ? Border.all(color: Colors.green.withOpacity(0.2))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activityColor.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(activityIcon, color: activityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (duration > 0) ...[
                      Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$duration د',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (calories > 0) ...[
                      Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: Colors.orange.withOpacity(0.7),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$calories سعرة',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 16),
            ),
        ],
      ),
    );
  }
}
