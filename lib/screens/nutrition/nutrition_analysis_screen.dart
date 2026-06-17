// lib/screens/nutrition/nutrition_analysis_screen.dart

import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../widgets/nutrition/empty_nutrition_state.dart';
import '../../../widgets/nutrition/nutrition_card.dart';
import '../../../widgets/nutrition/meal_helpers.dart';

class NutritionAnalysisScreen extends StatelessWidget {
  final dynamic userData;
  final Map<String, dynamic> meals;

  const NutritionAnalysisScreen({
    Key? key,
    required this.userData,
    required this.meals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          title: Semantics(
            label: 'شاشة تحليل الغذاء',
            header: true,
            child: Text('📊 تحليل الغذاء'),
          ),
        ),
        body: SafeArea(
          child: meals.isEmpty || (meals['meals'] as List?)?.isEmpty == true
              ? EmptyNutritionState.noMeals()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Semantics(
                        label: 'ملخص السعرات الحرارية اليوم',
                        child: _buildSummaryCard(theme),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        label: 'توزيع المغذيات',
                        child: _buildNutrientChart(theme),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        label: 'تفصيل الوجبات',
                        child: _buildMealsBreakdown(theme),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        label: 'توصيات غذائية',
                        child: _buildRecommendations(theme),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final totalCalories =
        meals['totalCalories'] ?? meals['total_calories'] ?? 0;
    final protein = meals['protein'] ?? meals['total_protein'] ?? 0;
    final carbs = meals['carbs'] ?? meals['total_carbs'] ?? 0;
    final fat = meals['fat'] ?? meals['total_fat'] ?? 0;

    return NutritionCard.gradient(
      child: Column(
        children: [
          const Text(
            'ملخص اليوم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Semantics(
                label: 'السعرات $totalCalories سعرة',
                child: _buildSummaryItem(
                  'السعرات',
                  totalCalories.round().toString(),
                  'سعرة',
                ),
              ),
              Semantics(
                label: 'بروتين $protein جرام',
                child: _buildSummaryItem('بروتين', protein.round().toString(), 'جرام'),
              ),
              Semantics(
                label: 'كارب $carbs جرام',
                child: _buildSummaryItem('كارب', carbs.round().toString(), 'جرام'),
              ),
              Semantics(
                label: 'دهون $fat جرام',
                child: _buildSummaryItem('دهون', fat.round().toString(), 'جرام'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildNutrientChart(ThemeData theme) {
    final protein = meals['protein'] ?? meals['total_protein'] ?? 0.0;
    final carbs = meals['carbs'] ?? meals['total_carbs'] ?? 0.0;
    final fat = meals['fat'] ?? meals['total_fat'] ?? 0.0;

    final targetProtein = 100.0;
    final targetCarbs = 250.0;
    final targetFat = 70.0;

    final proteinPercentage = targetProtein > 0
        ? (protein / targetProtein * 100).round()
        : 0;
    final carbsPercentage = targetCarbs > 0
        ? (carbs / targetCarbs * 100).round()
        : 0;
    final fatPercentage = targetFat > 0 ? (fat / targetFat * 100).round() : 0;

    return NutritionCard.defaultStyle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع المغذيات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'بروتين $proteinPercentage%',
                  child: _buildProgressCircle(
                    value: targetProtein > 0 ? protein / targetProtein : 0,
                    color: theme.colorScheme.primary,
                    label: 'بروتين',
                    percentage: proteinPercentage,
                    theme: theme,
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  label: 'كارب $carbsPercentage%',
                  child: _buildProgressCircle(
                    value: targetCarbs > 0 ? carbs / targetCarbs : 0,
                    color: AppColors.calories,
                    label: 'كارب',
                    percentage: carbsPercentage,
                    theme: theme,
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  label: 'دهون $fatPercentage%',
                  child: _buildProgressCircle(
                    value: targetFat > 0 ? fat / targetFat : 0,
                    color: AppColors.warning,
                    label: 'دهون',
                    percentage: fatPercentage,
                    theme: theme,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCircle({
    required double value,
    required Color color,
    required String label,
    required int percentage,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
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

  Widget _buildMealsBreakdown(ThemeData theme) {
    final mealsList = meals['meals'] as List? ?? [];

    if (mealsList.isEmpty) {
      return NutritionCard.defaultStyle(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.restaurant, size: 50, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'لا توجد وجبات مسجلة',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return NutritionCard.defaultStyle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفصيل الوجبات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...mealsList.map<Widget>(
            (meal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: getMealTypeColor(
                        meal['type'] ?? '',
                      ).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        getMealEmoji(meal['type'] ?? ''),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal['type'] ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          meal['name'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${meal['total_calories'] ?? 0} سعرة',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.calories,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(ThemeData theme) {
    return NutritionCard.tips(
      accentColor: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'توصيات غذائية',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRecommendationItem(
            '✅ تناول المزيد من الخضروات مع كل وجبة',
            Icons.eco,
            AppColors.success,
            theme,
          ),
          _buildRecommendationItem(
            '💧 اشرب كوب ماء قبل كل وجبة',
            Icons.water_drop,
            theme.colorScheme.primary,
            theme,
          ),
          _buildRecommendationItem(
            '🥗 قلل من النشويات في العشاء',
            Icons.nightlight,
            AppColors.warning,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    String text,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
