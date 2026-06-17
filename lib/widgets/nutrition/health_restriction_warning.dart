// lib/widgets/nutrition/health_restriction_warning.dart
// Warning banner for health-based food restrictions

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class HealthRestrictionWarning extends StatelessWidget {
  final Set<String> avoidedFoods;
  final Set<String> avoidedDrinks;
  final Set<String>? recommendedFoods;
  final bool isLoading;

  const HealthRestrictionWarning({
    super.key,
    required this.avoidedFoods,
    this.avoidedDrinks = const {},
    this.recommendedFoods,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRestrictions =
        avoidedFoods.isNotEmpty || avoidedDrinks.isNotEmpty;

    if (isLoading) {
      return _buildSkeleton(theme);
    }

    if (!hasRestrictions) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'لا توجد قيود صحية على الطعام',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'توجد قيود صحية',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (avoidedFoods.isNotEmpty)
            _buildChipRow(
              context,
              '🥗 أطعمة ممنوعة:',
              avoidedFoods.toList(),
              AppColors.danger,
            ),
          if (avoidedDrinks.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildChipRow(
              context,
              '🥤 مشروبات ممنوعة:',
              avoidedDrinks.toList(),
              AppColors.danger,
            ),
          ],
          if (recommendedFoods != null && recommendedFoods!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildChipRow(
              context,
              '✅ أطعمة موصى بها:',
              recommendedFoods!.toList(),
              AppColors.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChipRow(
    BuildContext context,
    String label,
    List<String> items,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
        ...items.take(3).map(
              (item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        if (items.length > 3)
          Text(
            '+${items.length - 3}',
            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
      ],
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 120,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}