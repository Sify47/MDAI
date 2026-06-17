// lib/widgets/nutrition/empty_nutrition_state.dart
// Reusable empty state widget with icon, message, and optional CTA

import 'package:flutter/material.dart';

class EmptyNutritionState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final double iconSize;

  const EmptyNutritionState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButtonPressed,
    this.iconSize = 80,
  });

  /// Preconfigured empty state for no meals logged
  factory EmptyNutritionState.noMeals({VoidCallback? onAddMeal}) {
    return EmptyNutritionState(
      icon: Icons.restaurant,
      title: 'لا توجد وجبات مسجلة',
      subtitle: 'قم بتسجيل وجباتك لتتبع غذائك اليومي',
      buttonLabel: 'تسجيل وجبة',
      onButtonPressed: onAddMeal,
    );
  }

  /// Preconfigured empty state for no suggestions
  factory EmptyNutritionState.noSuggestions({VoidCallback? onRetry}) {
    return EmptyNutritionState(
      icon: Icons.restaurant,
      title: 'لا توجد اقتراحات متاحة',
      subtitle: 'لم نجد وجبات مناسبة لهدفك وحالتك الصحية حالياً',
      buttonLabel: 'إعادة المحاولة',
      onButtonPressed: onRetry,
    );
  }

  /// Preconfigured empty state for no history
  factory EmptyNutritionState.noHistory({VoidCallback? onPickDate}) {
    return EmptyNutritionState(
      icon: Icons.restaurant,
      title: 'لا توجد وجبات مسجلة',
      subtitle: 'لم يتم تسجيل أي وجبات في هذا التاريخ',
      buttonLabel: 'اختر تاريخ آخر',
      onButtonPressed: onPickDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add, size: 18),
                label: Text(buttonLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}