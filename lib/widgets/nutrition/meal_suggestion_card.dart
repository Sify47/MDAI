// lib/widgets/nutrition/meal_suggestion_card.dart
// Card for displaying a single meal suggestion

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/nutrition_model.dart';
import 'meal_helpers.dart';
import 'nutrition_card.dart';

class MealSuggestionCard extends StatelessWidget {
  final MealSuggestion meal;
  final VoidCallback? onAddToMeal;
  final VoidCallback? onTap;

  const MealSuggestionCard({
    super.key,
    required this.meal,
    this.onAddToMeal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = getMealTypeColor(meal.type);

    return NutritionCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Meal type icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(getMealIcon(meal.type), color: typeColor, size: 30),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          meal.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (meal.goal != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: getGoalColor(meal.goal!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            meal.goal!,
                            style: TextStyle(
                              fontSize: 10,
                              color: getGoalColor(meal.goal!),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildNutrientChip(
                        '${meal.calories} سعرة',
                        AppColors.calories,
                        theme,
                      ),
                      const SizedBox(width: 8),
                      _buildNutrientChip(
                        '${meal.protein}جم بروتين',
                        AppColors.primary,
                        theme,
                      ),
                      if (meal.ingredients.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildNutrientChip(
                          '${meal.ingredients.length} مكونات',
                          Colors.orange,
                          theme,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: onAddToMeal,
                  tooltip: 'تسجيل الوجبة',
                  splashRadius: 20,
                ),
                Icon(
                  Icons.chevron_left,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
