// lib/widgets/nutrition/nutrient_progress_row.dart
// Target nutrients card with progress bars

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class NutrientProgressRow extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;

  const NutrientProgressRow({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    this.unit = 'جم',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${current.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} $unit',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class TargetNutrientsCard extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;

  const TargetNutrientsCard({
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
    final theme = Theme.of(context);

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.nutrition.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.track_changes, color: AppColors.nutrition, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'المستهدف اليومي',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NutrientProgressRow(
            label: 'بروتين',
            current: protein,
            target: targetProtein,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          NutrientProgressRow(
            label: 'كاربوهيدرات',
            current: carbs,
            target: targetCarbs,
            color: AppColors.calories,
          ),
          const SizedBox(height: 12),
          NutrientProgressRow(
            label: 'دهون',
            current: fat,
            target: targetFat,
            color: AppColors.medications,
          ),
        ],
      ),
    );
  }
}