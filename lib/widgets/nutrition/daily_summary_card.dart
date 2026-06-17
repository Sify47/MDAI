// lib/widgets/nutrition/daily_summary_card.dart
// Gradient summary card for daily nutrition targets

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class DailySummaryCard extends StatelessWidget {
  final double targetCalories;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  const DailySummaryCard({
    super.key,
    required this.targetCalories,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, AppColors.success],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'ملخص اليوم',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('السعرات', totalCalories.round().toString(), 'سعرة'),
              _buildSummaryItem('بروتين', totalProtein.round().toString(), 'جرام'),
              _buildSummaryItem('كارب', totalCarbs.round().toString(), 'جرام'),
              _buildSummaryItem('دهون', totalFat.round().toString(), 'جرام'),
            ],
          ),
          const SizedBox(height: 12),
          // Calorie progress
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: targetCalories > 0
                  ? (totalCalories / targetCalories).clamp(0, 1)
                  : 0,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(targetCalories > 0 ? (totalCalories / targetCalories * 100).clamp(0, 100) : 0).round()}% من الهدف اليومي',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
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
        Text(
          unit,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}