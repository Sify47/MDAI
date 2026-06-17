// lib/widgets/ai_dashboard/nutrition_card.dart
// 📊 بطاقة التحليل الغذائي

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class NutritionCard extends StatelessWidget {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double proteinPct;
  final double carbsPct;
  final double fatPct;
  final List<String> suggestions;
  final int mealsCount;

  const NutritionCard({
    Key? key,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
    required this.suggestions,
    required this.mealsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
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
          _buildHeader(theme, isDark),
          const SizedBox(height: 20),
          _buildCaloriesSection(theme),
          const SizedBox(height: 20),
          const Text(
            'توزيع المغذيات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMacroRow(theme),
          if (suggestions.isNotEmpty) _buildSuggestions(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.analytics,
            color: AppColors.success,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '📊 التحليل الغذائي',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: totalCalories > 0
                ? AppColors.success.withOpacity(0.1)
                : (isDark ? Colors.grey[800] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$mealsCount وجبات',
            style: TextStyle(
              fontSize: 11,
              color: totalCalories > 0
                  ? AppColors.success
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.calories.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.calories.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.calories.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.calories,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إجمالي السعرات المستهلكة',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalCalories.round()}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.calories,
                  ),
                ),
                const Text(
                  'سعرة حرارية',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildMacroDonut(
            theme,
            label: 'بروتين',
            value: totalProtein,
            percentage: proteinPct,
            color: theme.colorScheme.primary,
            recommended: 60,
            unit: 'جم',
          ),
        ),
        Expanded(
          child: _buildMacroDonut(
            theme,
            label: 'كاربوهيدرات',
            value: totalCarbs,
            percentage: carbsPct,
            color: AppColors.calories,
            recommended: 250,
            unit: 'جم',
          ),
        ),
        Expanded(
          child: _buildMacroDonut(
            theme,
            label: 'دهون',
            value: totalFat,
            percentage: fatPct,
            color: AppColors.warning,
            recommended: 70,
            unit: 'جم',
          ),
        ),
      ],
    );
  }

  Widget _buildMacroDonut(
    ThemeData theme, {
    required String label,
    required double value,
    required double percentage,
    required Color color,
    required double recommended,
    required String unit,
  }) {
    final isGood = value >= recommended * 0.8 && value <= recommended * 1.2;
    final statusColor = isGood ? AppColors.success : color;
    final safePercentage = percentage.clamp(0.0, 100.0);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: safePercentage / 100,
                strokeWidth: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${safePercentage.round()}%',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          '${value.round()}/$recommended $unit',
          style: theme.textTheme.bodySmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.tips_and_updates,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'توصيات',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...suggestions.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Text('• ', style: TextStyle(fontSize: 14)),
                Expanded(child: Text(s, style: theme.textTheme.bodySmall)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
