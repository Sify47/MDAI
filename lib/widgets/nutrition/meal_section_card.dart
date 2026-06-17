// lib/widgets/nutrition/meal_section_card.dart
// Meal type section with header, suggestion card, and "more options" button

import 'package:flutter/material.dart';
import '../../models/nutrition_model.dart';
import 'meal_helpers.dart';
import 'meal_suggestion_card.dart';
import 'nutrition_card.dart';

class MealSectionCard extends StatelessWidget {
  final String title;
  final List<MealSuggestion> meals;
  final double targetCalories;
  final VoidCallback? onShowAll;
  final void Function(MealSuggestion)? onAddToMeal;
  final void Function(MealSuggestion)? onTapMeal;

  const MealSectionCard({
    super.key,
    required this.title,
    required this.meals,
    required this.targetCalories,
    this.onShowAll,
    this.onAddToMeal,
    this.onTapMeal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (meals.isEmpty) {
      return NutritionCard.flat(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(getMealIcon(title), size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'لا توجد وجبات $title متاحة',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final selectedMeal = meals[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${targetCalories.toStringAsFixed(0)} سعرة',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main suggestion card
        MealSuggestionCard(
          meal: selectedMeal,
          onAddToMeal: onAddToMeal != null
              ? () => onAddToMeal!(selectedMeal)
              : null,
          onTap: onTapMeal != null ? () => onTapMeal!(selectedMeal) : null,
        ),

        // More options
        if (meals.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: TextButton.icon(
              onPressed: onShowAll,
              icon: const Icon(Icons.more_horiz, size: 18),
              label: Text('${meals.length - 1} خيارات أخرى'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
