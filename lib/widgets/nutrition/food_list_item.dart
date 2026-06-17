// lib/widgets/nutrition/food_list_item.dart
// Single food item row with health indicators

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/nutrition_model.dart';
import 'meal_helpers.dart';
import 'nutrition_card.dart';

class FoodListItem extends StatelessWidget {
  final Food food;
  final bool isSelected;
  final bool isRecommended;
  final bool isRestricted;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;

  const FoodListItem({
    super.key,
    required this.food,
    this.isSelected = false,
    this.isRecommended = false,
    this.isRestricted = false,
    this.onAdd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = getCategoryColor(food.category);

    final borderColor = isRestricted
        ? AppColors.danger.withOpacity(0.3)
        : null;

    return NutritionCard(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 8),
      border: borderColor != null
          ? Border.all(color: borderColor)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Category emoji container
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  getCategoryEmoji(food.category),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'موصى به',
                            style: TextStyle(fontSize: 10, color: AppColors.success),
                          ),
                        ),
                      if (isRestricted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ممنوع',
                            style: TextStyle(fontSize: 10, color: AppColors.danger),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${food.calories.round()} سعرة / ${food.unit}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Add/Selected button
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: AppColors.success,
                  size: 18,
                ),
              )
            else
              ElevatedButton(
                onPressed: isRestricted ? null : onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRestricted
                      ? Colors.grey[300]
                      : theme.colorScheme.primary,
                  foregroundColor: isRestricted ? Colors.grey : Colors.white,
                  minimumSize: const Size(60, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  disabledBackgroundColor: Colors.grey[200],
                ),
                child: Text(isRestricted ? 'ممنوع' : 'إضافة'),
              ),
          ],
        ),
      ),
    );
  }
}