// lib/widgets/nutrition/selected_foods_section.dart
// Card showing selected foods list with quick nutrient totals

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'nutrition_card.dart';
import 'selected_food_item.dart';

class SelectedFoodsSection extends StatelessWidget {
  final List<Map<String, dynamic>> selectedFoods;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final ValueChanged<int> onRemoveFood;
  final VoidCallback? onClearAll;

  const SelectedFoodsSection({
    super.key,
    required this.selectedFoods,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.onRemoveFood,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NutritionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.nutrition.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_menu, color: AppColors.nutrition, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'الأطعمة المختارة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (onClearAll != null && selectedFoods.isNotEmpty)
                TextButton.icon(
                  onPressed: onClearAll,
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text('مسح الكل'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.calories.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedFoods.length} أطعمة',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.calories,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (selectedFoods.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.add_circle_outline, size: 32, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'لم تختر أي أطعمة بعد',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      'اختر الأطعمة من القائمة أدناه',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Foods list
            ...selectedFoods.asMap().entries.map(
                  (entry) => SelectedFoodItem(
                    food: entry.value,
                    index: entry.key,
                    onRemove: () => onRemoveFood(entry.key),
                  ),
                ),

            const SizedBox(height: 12),

            // Quick nutrient totals
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickNutrient(
                    'سعرات',
                    totalCalories.round().toString(),
                    AppColors.calories,
                  ),
                  _buildQuickNutrient(
                    'بروتين',
                    '${totalProtein.round()}جم',
                    AppColors.primary,
                  ),
                  _buildQuickNutrient(
                    'كارب',
                    '${totalCarbs.round()}جم',
                    AppColors.calories,
                  ),
                  _buildQuickNutrient(
                    'دهون',
                    '${totalFat.round()}جم',
                    AppColors.medications,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickNutrient(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}