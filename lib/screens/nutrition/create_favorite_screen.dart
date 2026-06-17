// lib/screens/nutrition/create_favorite_screen.dart
// ⭐ إنشاء وجبة مفضلة جديدة بتأليف أطعمة من قاعدة البيانات

import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/nutrition_model.dart';
import '../../models/meal_plan_model.dart';
import '../../services/nutrition_api.dart';
import '../../services/meal_planner_service.dart';
import '../../widgets/nutrition/food_search_bar.dart';
import '../../widgets/nutrition/food_list_item.dart';
import '../../widgets/nutrition/selected_foods_section.dart';
import '../../widgets/nutrition/nutrition_card.dart';
import '../../widgets/nutrition/meal_helpers.dart';

class CreateFavoriteScreen extends StatefulWidget {
  const CreateFavoriteScreen({super.key});

  @override
  State<CreateFavoriteScreen> createState() => _CreateFavoriteScreenState();
}

class _CreateFavoriteScreenState extends State<CreateFavoriteScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _mealNameController = TextEditingController();
  String _selectedMealType = 'غداء';
  String _selectedCategory = 'الكل';
  List<Food> _foodsDatabase = [];
  List<Food> _filteredFoods = [];
  final List<Map<String, dynamic>> _selectedFoods = [];
  bool _isLoading = true;
  Timer? _debounceTimer;

  final List<String> _categories = [
    'الكل',
    'كارب',
    'بروتين',
    'خضار',
    'فاكهة',
    'دهون',
  ];

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mealNameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterFoods();
    });
  }

  Future<void> _loadFoods() async {
    setState(() => _isLoading = true);
    try {
      final foods = await NutritionService.getFoods();
      if (mounted) {
        setState(() {
          _foodsDatabase = foods;
          _filteredFoods = foods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل في تحميل الأطعمة: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _filterFoods() {
    setState(() {
      _filteredFoods = _foodsDatabase.where((food) {
        final matchesSearch =
            _searchController.text.isEmpty ||
            food.name.contains(_searchController.text);
        final matchesCategory =
            _selectedCategory == 'الكل' || food.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _toggleFood(Food food) {
    setState(() {
      final existingIndex = _selectedFoods.indexWhere(
        (f) => f['food_id'] == food.id,
      );
      if (existingIndex >= 0) {
        _selectedFoods.removeAt(existingIndex);
      } else {
        _selectedFoods.add({
          'food_id': food.id,
          'name': food.name,
          'calories': food.calories,
          'protein': food.protein,
          'carbs': food.carbs,
          'fat': food.fat,
          'unit': food.unit,
          'quantity': 1.0,
        });
      }
    });
  }

  double get _totalCalories => _selectedFoods.fold(
    0.0,
    (sum, f) => sum + (f['calories'] ?? 0).toDouble(),
  );

  double get _totalProtein => _selectedFoods.fold(
    0.0,
    (sum, f) => sum + (f['protein'] ?? 0).toDouble(),
  );

  double get _totalCarbs =>
      _selectedFoods.fold(0.0, (sum, f) => sum + (f['carbs'] ?? 0).toDouble());

  double get _totalFat =>
      _selectedFoods.fold(0.0, (sum, f) => sum + (f['fat'] ?? 0).toDouble());

  Future<void> _saveFavorite() async {
    if (_mealNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ الرجاء إدخال اسم للوجبة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_selectedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ الرجاء اختيار طعام واحد على الأقل'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final meal = FavoriteMeal(
      id: MealPlannerService.generateId(),
      name: _mealNameController.text.trim(),
      type: _selectedMealType,
      calories: _totalCalories,
      protein: _totalProtein,
      carbs: _totalCarbs,
      fat: _totalFat,
    );

    await MealPlannerService.addFavorite(meal);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حفظ "${meal.name}" في المفضلة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
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
          title: Semantics(
            label: 'إنشاء وجبة مفضلة',
            header: true,
            child: Text('⭐ إنشاء وجبة مفضلة'),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // تفاصيل الوجبة (الاسم والنوع)
                  _buildMealDetailsCard(theme, isDark),
                  // شريط البحث
                  FoodSearchBar(
                    searchController: _searchController,
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (cat) {
                      setState(() => _selectedCategory = cat);
                      _filterFoods();
                    },
                    categories: _categories,
                  ),
                  // الأطعمة المختارة
                  if (_selectedFoods.isNotEmpty)
                    _buildSelectedFoodsSummary(theme, isDark),
                  // قائمة الأطعمة
                  Expanded(
                    child: _filteredFoods.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'لا توجد أطعمة',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _filteredFoods.length,
                            itemBuilder: (context, index) {
                              final food = _filteredFoods[index];
                              final isSelected = _selectedFoods.any(
                                (f) => f['food_id'] == food.id,
                              );
                              return FoodListItem(
                                food: food,
                                isSelected: isSelected,
                                onTap: () => _toggleFood(food),
                                onAdd: () => _toggleFood(food),
                              );
                            },
                          ),
                  ),
                ],
              ),
        bottomNavigationBar: _selectedFoods.isNotEmpty
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveFavorite,
                        icon: const Icon(Icons.favorite, size: 20),
                        label: Text(
                          'حفظ "${_mealNameController.text.trim().isEmpty ? 'بدون اسم' : _mealNameController.text.trim()}" في المفضلة',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildMealDetailsCard(ThemeData theme, bool isDark) {
    return NutritionCard.flat(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل الوجبة',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _mealNameController,
            decoration: const InputDecoration(
              labelText: 'اسم الوجبة',
              hintText: 'مثال: فطور صحي متكامل',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedMealType,
            decoration: const InputDecoration(
              labelText: 'نوع الوجبة',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: mealTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text('${getMealEmoji(t)} $t'),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedMealType = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFoodsSummary(ThemeData theme, bool isDark) {
    return NutritionCard.flat(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                '${_selectedFoods.length} طعام مختار',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_totalCalories.toInt()} سعرة',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.calories,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'بروتين: ${_totalProtein.toStringAsFixed(1)}g • كارب: ${_totalCarbs.toStringAsFixed(1)}g • دهون: ${_totalFat.toStringAsFixed(1)}g',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _selectedFoods.map((f) {
              return Chip(
                label: Text(
                  f['name'] ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedFoods.removeWhere(
                      (item) => item['food_id'] == f['food_id'],
                    );
                  });
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
