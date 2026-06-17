// lib/widgets/nutrition/selected_food_item.dart
// Dismissible selected food row with delete action

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'meal_helpers.dart';

class SelectedFoodItem extends StatelessWidget {
  final Map<String, dynamic> food;
  final int index;
  final VoidCallback onRemove;

  const SelectedFoodItem({
    super.key,
    required this.food,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = food['category'] as String? ?? '';
    final color = getCategoryColor(category);

    return Dismissible(
      key: Key('food_${food['name']}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Emoji indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  getCategoryEmoji(category),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Name and calories
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'] as String? ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(food['calories'] ?? 0).round()} سعرة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.calories,
                    ),
                  ),
                ],
              ),
            ),

            // Macros
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMacroChip(
                  '${(food['protein'] ?? 0).round()}',
                  AppColors.primary,
                ),
                const SizedBox(width: 4),
                _buildMacroChip(
                  '${(food['carbs'] ?? 0).round()}',
                  AppColors.calories,
                ),
                const SizedBox(width: 4),
                _buildMacroChip(
                  '${(food['fat'] ?? 0).round()}',
                  AppColors.medications,
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Delete button
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}