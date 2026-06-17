// lib/screens/nutrition/meal_history_screen.dart

import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../models/nutrition_model.dart';
import '../../../services/nutrition_api.dart';
import 'nutrition_analysis_screen.dart';
import '../../../widgets/nutrition/loading_shimmers.dart';
import '../../../widgets/nutrition/empty_nutrition_state.dart';
import '../../../widgets/nutrition/nutrition_card.dart';
import '../../../widgets/nutrition/meal_helpers.dart';

class MealHistoryScreen extends StatefulWidget {
  final UserNutritionData userData;

  const MealHistoryScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _dailySummary;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await NutritionService.getMealsByDate(_selectedDate);

      if (!mounted) return;

      setState(() {
        _dailySummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'فشل في تحميل الوجبات';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMeals();
    }
  }

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
          title: Text('📅 تاريخ الوجبات'),
          actions: [
            Semantics(
              button: true,
              label: 'اختيار تاريخ',
              child: IconButton(
                icon: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () => _selectDate(context),
                tooltip: 'اختيار تاريخ',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
            Semantics(
              button: true,
              label: 'تحديث الوجبات',
              child: IconButton(
                icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                onPressed: _loadMeals,
                tooltip: 'تحديث',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? const HistoryShimmer()
              : _errorMessage != null
              ? _buildError(theme)
              : _dailySummary == null ||
                    (_dailySummary!['meals'] as List?)?.isEmpty == true
              ? _buildEmptyState(theme)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDateHeader(theme),
                      const SizedBox(height: 16),
                      _buildSummaryCard(theme),
                      const SizedBox(height: 16),
                      _buildMealsList(theme),
                      const SizedBox(height: 16),
                      _buildAnalysisButton(theme),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              button: true,
              label: 'إعادة المحاولة',
              child: ElevatedButton(
                onPressed: _loadMeals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  minimumSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('إعادة المحاولة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return EmptyNutritionState.noHistory(
      onPickDate: () => _selectDate(context),
    );
  }

  Widget _buildDateHeader(ThemeData theme) {
    return NutritionCard.defaultStyle(
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final meals = _dailySummary!['meals'] as List? ?? [];
    final totalCalories = _dailySummary!['total_calories'] ?? 0;
    final mealsCount = meals.length;
    final waterIntake = _dailySummary!['water_intake'] ?? 0.0;

    return NutritionCard.gradient(
      child: Column(
        children: [
          const Text(
            'ملخص اليوم',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                'السعرات',
                totalCalories.round().toString(),
                'سعرة',
              ),
              _buildSummaryItem('وجبات', mealsCount.toString(), ''),
              _buildSummaryItem('ماء', waterIntake.toStringAsFixed(1), 'لتر'),
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
        if (unit.isNotEmpty)
          Text(
            unit,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
      ],
    );
  }

  Widget _buildMealsList(ThemeData theme) {
    final meals = _dailySummary!['meals'] as List? ?? [];

    return NutritionCard.defaultStyle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الوجبات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...meals.map((meal) => _buildMealItem(meal, theme)),
        ],
      ),
    );
  }

  Widget _buildMealItem(Map<String, dynamic> meal, ThemeData theme) {
    final mealType = meal['type'] ?? '';
    Color mealColor = getMealTypeColor(mealType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mealColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  getMealEmoji(mealType),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealType,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(meal['total_calories'] ?? 0).round()} سعرة',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.calories,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'حذف الوجبة',
                child: IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: () => _deleteMeal(meal['id']),
                  tooltip: 'حذف الوجبة',
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(meal['foods'] as List? ?? []).map(
            (food) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• ${food['name']} (${food['quantity']} ${food['unit']})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMeal(int mealId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الوجبة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              minimumSize: const Size(44, 44),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);

      final result = await NutritionService.deleteMeal(mealId);

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          _loadMeals();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result['message']}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result['message']}'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildAnalysisButton(ThemeData theme) {
    return Semantics(
      button: true,
      label: 'تحليل الغذاء',
      child: ElevatedButton(
        onPressed: () {
          if (_dailySummary != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NutritionAnalysisScreen(
                  userData: widget.userData,
                  meals: _dailySummary!,
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'تحليل الغذاء',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
