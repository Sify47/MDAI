// lib/widgets/ai_dashboard/quiz_card.dart
// 📝 بطاقة تحليل الكويز اليومي

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class QuizCard extends StatelessWidget {
  final bool morningDone;
  final bool eveningDone;
  final double weeklyConsistency;
  final String moodTrend;

  const QuizCard({
    Key? key,
    required this.morningDone,
    required this.eveningDone,
    required this.weeklyConsistency,
    required this.moodTrend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalDone = (morningDone ? 1 : 0) + (eveningDone ? 1 : 0);
    final progress = totalDone / 2.0;

    final (statusColor, statusMessage) = _getStatus(totalDone);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDark, statusColor, progress),
          const SizedBox(height: 16),
          _buildStatsRow(theme),
          const SizedBox(height: 16),
          _buildMoodBanner(),
        ],
      ),
    );
  }

  (Color, String) _getStatus(int totalDone) {
    if (totalDone == 2) return (AppColors.success, 'ممتاز! أكملت الكويزات');
    if (totalDone == 1) return (AppColors.warning, 'أكمل الكويز المتبقي');
    return (AppColors.danger, 'ابدأ بكويز الصباح');
  }

  Widget _buildHeader(
    ThemeData theme,
    bool isDark,
    Color statusColor,
    double progress,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.quiz, color: AppColors.success, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '📝 الكويز اليومي',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSmallStat(
          theme,
          'الصباح',
          morningDone ? '✅' : '⏰',
          morningDone ? 'مكتمل' : 'معلق',
          morningDone ? AppColors.success : AppColors.warning,
        ),
        _buildSmallStat(
          theme,
          'المساء',
          eveningDone ? '✅' : '🌙',
          eveningDone ? 'مكتمل' : 'معلق',
          eveningDone ? AppColors.success : AppColors.warning,
        ),
        _buildSmallStat(
          theme,
          'الأسبوع',
          '${(weeklyConsistency * 100).round()}%',
          'انتظام',
          weeklyConsistency >= 0.7 ? AppColors.success : AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildSmallStat(
    ThemeData theme,
    String label,
    String value,
    String subtitle,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildMoodBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.mood, color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'مزاجك: $moodTrend',
              style: const TextStyle(
                color: AppColors.info,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
