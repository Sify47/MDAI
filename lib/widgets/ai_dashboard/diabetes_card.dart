// lib/widgets/ai_dashboard/diabetes_card.dart
// 🩸 بطاقة تحليل السكر

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class DiabetesCard extends StatelessWidget {
  final double controlPercentage;
  final double averageBloodSugar;
  final int measurementCount;

  const DiabetesCard({
    Key? key,
    required this.controlPercentage,
    required this.averageBloodSugar,
    required this.measurementCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (statusColor, statusMessage, statusIcon) = _getStatus();

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
          _buildHeader(theme, isDark, statusColor),
          const SizedBox(height: 16),
          _buildStatsRow(theme),
          const SizedBox(height: 16),
          _buildStatusBanner(statusColor, statusMessage, statusIcon),
        ],
      ),
    );
  }

  (Color, String, IconData) _getStatus() {
    if (controlPercentage >= 80)
      return (AppColors.success, 'ممتاز! سكرك تحت السيطرة', Icons.emoji_events);
    if (controlPercentage >= 60)
      return (AppColors.warning, 'جيد، يمكنك تحسين السيطرة', Icons.trending_up);
    return (AppColors.danger, 'يحتاج تحسين - راجع طبيبك', Icons.warning);
  }

  Widget _buildHeader(ThemeData theme, bool isDark, Color statusColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.monitor_heart,
            color: AppColors.danger,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '🩸 تتبع السكر',
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
            '${controlPercentage.round()}%',
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
          'المتوسط',
          '${averageBloodSugar.round()}',
          'mg/dL',
          AppColors.info,
        ),
        _buildSmallStat(
          theme,
          'القياسات',
          '$measurementCount',
          'مرة',
          theme.colorScheme.primary,
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

  Widget _buildStatusBanner(Color color, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
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
