// lib/widgets/nutrition/nutrient_circle_chart.dart
// Progress circles for nutrition analysis (protein/carbs/fat)

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class NutrientCircleChart extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final String label;
  final int percentage;
  final double size;

  const NutrientCircleChart({
    super.key,
    required this.value,
    required this.color,
    required this.label,
    required this.percentage,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value.clamp(0, 1),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 8,
              ),
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

/// Row of three nutrient circles (protein/carbs/fat)
class NutrientChartRow extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;

  const NutrientChartRow({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: NutrientCircleChart(
            value: targetProtein > 0 ? protein / targetProtein : 0,
            color: AppColors.primary,
            label: 'بروتين',
            percentage: targetProtein > 0
                ? (protein / targetProtein * 100).round()
                : 0,
          ),
        ),
        Expanded(
          child: NutrientCircleChart(
            value: targetCarbs > 0 ? carbs / targetCarbs : 0,
            color: AppColors.calories,
            label: 'كارب',
            percentage: targetCarbs > 0
                ? (carbs / targetCarbs * 100).round()
                : 0,
          ),
        ),
        Expanded(
          child: NutrientCircleChart(
            value: targetFat > 0 ? fat / targetFat : 0,
            color: AppColors.warning,
            label: 'دهون',
            percentage: targetFat > 0
                ? (fat / targetFat * 100).round()
                : 0,
          ),
        ),
      ],
    );
  }
}