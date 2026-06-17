// lib/widgets/nutrition/meal_helpers.dart
// Shared helper functions for meal type and food category styling

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

/// Returns the color associated with a meal type (فطور/غداء/عشاء/سناك)
Color getMealTypeColor(String type) {
  switch (type) {
    case 'فطور':
      return AppColors.calories;
    case 'غداء':
      return AppColors.primary;
    case 'عشاء':
      return AppColors.medications;
    case 'سناك':
      return AppColors.success;
    default:
      return AppColors.textSecondary;
  }
}

/// Returns the emoji for a meal type
String getMealEmoji(String type) {
  switch (type) {
    case 'فطور':
      return '🌅';
    case 'غداء':
      return '☀️';
    case 'عشاء':
      return '🌙';
    case 'سناك':
      return '🍎';
    default:
      return '🍽️';
  }
}

/// Returns the Material IconData for a meal type
IconData getMealIcon(String type) {
  switch (type) {
    case 'فطور':
      return Icons.free_breakfast;
    case 'غداء':
      return Icons.lunch_dining;
    case 'عشاء':
      return Icons.dinner_dining;
    case 'سناك':
      return Icons.cookie;
    default:
      return Icons.restaurant;
  }
}

/// Returns the color associated with a food category using AppColors
Color getCategoryColor(String category) {
  switch (category) {
    case 'كارب':
      return AppColors.calories;
    case 'بروتين':
      return AppColors.primary;
    case 'خضار':
      return AppColors.success;
    case 'فاكهة':
      return AppColors.warning;
    case 'دهون':
      return AppColors.medications;
    case 'مشروبات':
      return Colors.cyan;
    default:
      return AppColors.textSecondary;
  }
}

/// Returns the emoji for a food category
String getCategoryEmoji(String category) {
  switch (category) {
    case 'كارب':
      return '🍚';
    case 'بروتين':
      return '🥩';
    case 'خضار':
      return '🥬';
    case 'فاكهة':
      return '🍎';
    case 'دهون':
      return '🥑';
    case 'مشروبات':
      return '🥤';
    default:
      return '🍽️';
  }
}

/// Returns the goal color (تخسيس/تثبيت/زيادة)
Color getGoalColor(String goal) {
  switch (goal) {
    case 'تخسيس':
      return Colors.green;
    case 'تثبيت':
      return Colors.blue;
    case 'زيادة':
      return Colors.orange;
    default:
      return AppColors.textSecondary;
  }
}

/// Standard meal types list
const List<String> mealTypes = ['فطور', 'غداء', 'عشاء', 'سناك'];

/// Standard food categories list
const List<String> foodCategories = [
  'الكل',
  'كارب',
  'بروتين',
  'خضار',
  'فاكهة',
  'دهون',
];