// lib/screens/nutrition/add_meal_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vita/utils/nutrition_calculator.dart';
import '../../../constants/colors.dart';
import '../../../models/nutrition_model.dart';
import '../../../models/meal_plan_model.dart';
import '../../../models/symptom_model.dart';
import '../../../models/medication_model.dart';
import '../../../services/nutrition_api.dart';
import '../../../services/meal_planner_service.dart';
import '../../../services/symptom_api.dart';
import '../../../services/medication_api.dart';
import '../../../widgets/nutrition/loading_shimmers.dart';
import '../../../widgets/nutrition/health_restriction_warning.dart';
import '../../../widgets/nutrition/selected_foods_section.dart';
import '../../../widgets/nutrition/nutrient_progress_row.dart';
import '../../../widgets/nutrition/nutrition_card.dart';
import '../../../widgets/nutrition/meal_helpers.dart';
import 'create_favorite_screen.dart';

class AddMealScreen extends StatefulWidget {
  final UserNutritionData userData;
  final String? preSelectedMealType;
  final List<Map<String, dynamic>>? preSelectedFoods;

  const AddMealScreen({
    Key? key,
    required this.userData,
    this.preSelectedMealType,
    this.preSelectedFoods,
  }) : super(key: key);

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  String _selectedMealType = 'فطور';
  final List<Map<String, dynamic>> _selectedFoods = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<Food> _foodsDatabase = [];
  List<Food> _filteredFoods = [];
  bool _isLoading = true;
  String _selectedCategory = 'الكل';

  // ✅ متغيرات القيود الصحية
  Set<String> _avoidedFoods = {};
  final Set<String> _avoidedDrinks = {};
  Set<String> _recommendedFoods = {};
  bool _isLoadingRestrictions = false;
  Map<String, double> _macros = {};
  double _targetCalories = 0;

  // ✅ Debounce timer للبحث
  Timer? _debounceTimer;

  final List<String> _categories = [
    'الكل',
    'كارب',
    'بروتين',
    'خضار',
    'فاكهة',
    'دهون',
  ];

  // ✅ الوجبات المفضلة
  List<FavoriteMeal> _favorites = [];
  bool _isLoadingFavorites = false;

  // ✅ المغذيات المستهدفة
  double get _targetProtein => _macros['protein'] ?? 0;
  double get _targetCarbs => _macros['carbs'] ?? 0;
  double get _targetFat => _macros['fat'] ?? 0;

  Future<void> _initializeData() async {
    _targetCalories = widget.userData.targetCalories > 0
        ? widget.userData.targetCalories
        : 2000.0;

    _macros = NutritionCalculator.calculateMacros(
      calories: _targetCalories,
      goal: widget.userData.goal,
      diseases: widget.userData.diseases,
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (widget.preSelectedMealType != null) {
      _selectedMealType = widget.preSelectedMealType!;
    }

    if (widget.preSelectedFoods != null) {
      _preFilterPreSelectedFoods();
    }

    _controller.forward();
    _loadAllData();
    _loadFavorites();

    _searchController.addListener(_onSearchChanged);
  }

  // ✅ Debounced search listener
  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterFoods();
    });
  }

  // ✅ فلترة الأطعمة المحددة مسبقاً
  void _preFilterPreSelectedFoods() {
    if (widget.preSelectedFoods == null) return;

    Future.microtask(() {
      if (_avoidedFoods.isNotEmpty && widget.preSelectedFoods != null) {
        final filtered = widget.preSelectedFoods!.where((food) {
          final foodName = (food['name'] ?? '').toLowerCase();
          for (var avoided in _avoidedFoods) {
            if (foodName.contains(avoided) || avoided.contains(foodName)) {
              return false;
            }
          }
          return true;
        }).toList();

        setState(() {
          _selectedFoods.clear();
          _selectedFoods.addAll(filtered);
        });
      } else if (widget.preSelectedFoods != null) {
        setState(() {
          _selectedFoods.addAll(widget.preSelectedFoods!);
        });
      }
    });
  }

  // ✅ تحميل جميع البيانات
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    await Future.wait([_loadFoods(), _loadHealthRestrictions()]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadFoods() async {
    final foods = await NutritionService.getFoods();
    if (mounted) {
      setState(() {
        _foodsDatabase = foods;
        _filteredFoods = foods;
      });
    }
  }

  // ✅ تحميل القيود الصحية المتقدمة
  Future<void> _loadHealthRestrictions() async {
    setState(() => _isLoadingRestrictions = true);

    try {
      final symptoms = await SymptomService.getSymptoms(limit: 30);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentSymptoms = symptoms
          .where((s) => s.dateTime.isAfter(sevenDaysAgo))
          .toList();

      final medications = await MedicationService.getMedications();

      await _extractAllRestrictions(recentSymptoms, medications);

      _filterFoods();

      _preFilterPreSelectedFoods();
    } catch (e) {
      print('❌ خطأ في تحميل القيود الصحية: $e');
    } finally {
      setState(() => _isLoadingRestrictions = false);
    }
  }

  // ✅ تحميل الوجبات المفضلة
  Future<void> _loadFavorites() async {
    setState(() => _isLoadingFavorites = true);
    try {
      final favorites = await MealPlannerService.getFavorites();
      if (mounted) {
        setState(() => _favorites = favorites);
      }
    } catch (e) {
      print('⚠️ خطأ في تحميل المفضلة: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingFavorites = false);
      }
    }
  }

  // ✅ استخراج جميع القيود (الممنوع والمستحب)
  Future<void> _extractAllRestrictions(
    List<Symptom> symptoms,
    List<UserMedication> medications,
  ) async {
    Set<String> avoidedFoods = {};
    Set<String> recommendedFoods = {};

    // 1. من الأعراض
    for (var symptom in symptoms) {
      if (symptom.foodRecommendations != null) {
        final recs = symptom.foodRecommendations!;

        if (recs['foods_to_avoid'] != null) {
          avoidedFoods.addAll(
            List<String>.from(
              recs['foods_to_avoid'],
            ).map((f) => f.toLowerCase().trim()),
          );
        }

        if (recs['foods_to_eat'] != null) {
          recommendedFoods.addAll(
            List<String>.from(
              recs['foods_to_eat'],
            ).map((f) => f.toLowerCase().trim()),
          );
        }
      }
    }

    // 2. من الأمراض المزمنة
    for (var disease in widget.userData.diseases) {
      final diseaseRestrictions = _getDiseaseRestrictions(disease);
      avoidedFoods.addAll(diseaseRestrictions['avoid']!);
      recommendedFoods.addAll(diseaseRestrictions['recommend']!);
    }

    // 3. من الأدوية
    for (var med in medications) {
      try {
        final impact = await SymptomService.getMedicineImpact(
          med.medicineId ?? 0,
        );
        if (impact['success']) {
          if (impact['foods_to_avoid'] != null) {
            avoidedFoods.addAll(
              List<String>.from(
                impact['foods_to_avoid'],
              ).map((f) => f.toLowerCase().trim()),
            );
          }
          if (impact['foods_to_eat'] != null) {
            recommendedFoods.addAll(
              List<String>.from(
                impact['foods_to_eat'],
              ).map((f) => f.toLowerCase().trim()),
            );
          }
        }
      } catch (e) {
        print('⚠️ خطأ في جلب توصيات الدواء ${med.name}: $e');
      }
    }

    setState(() {
      _avoidedFoods = avoidedFoods;
      _recommendedFoods = recommendedFoods;
    });
  }

  // ✅ قيود الأمراض المزمنة
  Map<String, Set<String>> _getDiseaseRestrictions(String disease) {
    final restrictions = {
      'السكري': {
        'avoid': {'سكر', 'حلويات', 'عصير محلى', 'مشروبات غازية', 'عسل', 'مربى'},
        'recommend': {'شوفان', 'خضار', 'بروتين', 'بقوليات', 'ألياف'},
      },
      'ضغط الدم': {
        'avoid': {
          'ملح',
          'مخللات',
          'أطعمة معلبة',
          'وجبات سريعة',
          'صلصة',
          'جبن مالح',
        },
        'recommend': {'موز', 'خضار', 'ثوم', 'زيت زيتون', 'سمك', 'شوفان'},
      },
      'الكوليسترول': {
        'avoid': {
          'دهون مشبعة',
          'زبدة',
          'سمن',
          'لحوم حمراء',
          'مقليات',
          'صفار بيض',
        },
        'recommend': {'شوفان', 'أسماك', 'زيت زيتون', 'لوز', 'جوز', 'أفوكادو'},
      },
      'القلب': {
        'avoid': {'دهون', 'ملح', 'سكريات', 'لحوم مصنعة', 'مقليات', 'زبدة'},
        'recommend': {'أسماك', 'زيت زيتون', 'خضار', 'فواكه', 'شوفان', 'مكسرات'},
      },
      'الأنيميا': {
        'avoid': {'شاي', 'قهوة', 'أطعمة غنية بالكالسيوم مع الحديد'},
        'recommend': {'سبانخ', 'لحوم حمراء', 'عدس', 'كبدة', 'تمر', 'عسل أسود'},
      },
    };

    return {
      'avoid': restrictions[disease]?['avoid'] ?? <String>{},
      'recommend': restrictions[disease]?['recommend'] ?? <String>{},
    };
  }

  // ✅ فلترة الأطعمة حسب القيود
  bool _isFoodAllowed(Food food) {
    if (_avoidedFoods.isEmpty) return true;

    final foodName = food.name.toLowerCase();
    final category = food.category.toLowerCase();

    for (var avoided in _avoidedFoods) {
      if (foodName.contains(avoided) || avoided.contains(foodName)) {
        return false;
      }
    }

    if (_avoidedFoods.contains(category)) {
      return false;
    }

    return true;
  }

  // ✅ فلترة الأطعمة مع إضافة علامة "موصى به"
  void _filterFoods() {
    setState(() {
      _filteredFoods = _foodsDatabase.where((food) {
        final matchesSearch =
            _searchController.text.isEmpty ||
            food.name.contains(_searchController.text);
        final matchesCategory =
            _selectedCategory == 'الكل' || food.category == _selectedCategory;
        final matchesHealth = _isFoodAllowed(food);

        return matchesSearch && matchesCategory && matchesHealth;
      }).toList();
    });
  }

  // ✅ التحقق مما إذا كان الطعام موصى به
  bool _isFoodRecommended(Food food) {
    if (_recommendedFoods.isEmpty) return false;

    final foodName = food.name.toLowerCase();
    for (var recommended in _recommendedFoods) {
      if (foodName.contains(recommended) || recommended.contains(foodName)) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _notesController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  double get _totalCalories {
    return _selectedFoods.fold(
      0.0,
      (sum, item) => sum + (item['calories'] ?? 0).toDouble(),
    );
  }

  double get _totalProtein {
    return _selectedFoods.fold(
      0.0,
      (sum, item) => sum + (item['protein'] ?? 0.0).toDouble(),
    );
  }

  double get _totalCarbs {
    return _selectedFoods.fold(
      0.0,
      (sum, item) => sum + (item['carbs'] ?? 0.0).toDouble(),
    );
  }

  double get _totalFat {
    return _selectedFoods.fold(
      0.0,
      (sum, item) => sum + (item['fat'] ?? 0.0).toDouble(),
    );
  }

  // ✅ قسم الوجبات المفضلة للإضافة السريعة
  Widget _buildFavoritesQuickAdd(ThemeData theme) {
    if (_favorites.isEmpty && !_isLoadingFavorites) {
      return const SizedBox();
    }

    return NutritionCard.defaultStyle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.calories.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star,
                  color: AppColors.calories,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '⭐ الوجبات المفضلة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Semantics(
                button: true,
                label: 'إنشاء وجبة مفضلة جديدة',
                child: TextButton.icon(
                  onPressed: () => _navigateToCreateFavorite(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('جديد'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: AppColors.calories,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingFavorites)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Semantics(
              label: 'قائمة الوجبات المفضلة - اضغط لإضافة مكوناتها',
              container: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _favorites.map((fav) {
                    final typeColor = getMealTypeColor(fav.type);
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Semantics(
                        button: true,
                        label: '${fav.name} - ${fav.calories.toInt()} سعرة',
                        child: ActionChip(
                          avatar: CircleAvatar(
                            backgroundColor: typeColor.withOpacity(0.2),
                            radius: 14,
                            child: Text(
                              getMealEmoji(fav.type),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fav.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${fav.calories.toInt()} سعرة',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          onPressed: () => _applyFavoriteToMeal(fav),
                          backgroundColor: typeColor.withOpacity(0.08),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          visualDensity: VisualDensity.comfortable,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ تطبيق وجبة مفضلة على الوجبة الحالية
  void _applyFavoriteToMeal(FavoriteMeal fav) {
    setState(() {
      // Add a representative food entry for the favorite meal
      _selectedFoods.add({
        'name': fav.name,
        'calories': fav.calories.round(),
        'protein': fav.protein,
        'carbs': fav.carbs,
        'fat': fav.fat,
        'unit': 'حصة',
        'category': fav.type,
        'food_id': 0,
        'is_favorite': true,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('✅ تم إضافة "${fav.name}" للوجبة')),
          ],
        ),
        backgroundColor: AppColors.calories,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ✅ الانتقال لشاشة إنشاء وجبة مفضلة جديدة
  Future<void> _navigateToCreateFavorite() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateFavoriteScreen()),
    );
    if (result == true) {
      _loadFavorites();
    }
  }

  // ✅ حفظ الوجبة الحالية في المفضلة
  Future<void> _saveMealToFavorites() async {
    if (_selectedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('⚠️ أضف أطعمة أولاً')),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('💾 حفظ في المفضلة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل اسماً للوجبة المفضلة:'),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'مثال: وجبة فطور متكاملة',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.calories,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final favorite = FavoriteMeal(
      id: MealPlannerService.generateId(),
      name: name,
      description: 'وجبة $_selectedMealType محفوظة',
      type: _selectedMealType,
      calories: _totalCalories,
      protein: _totalProtein,
      carbs: _totalCarbs,
      fat: _totalFat,
      imageUrl: null,
      createdAt: DateTime.now(),
    );

    await MealPlannerService.addFavorite(favorite);
    await _loadFavorites();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.star, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('✅ تم حفظ الوجبة في المفضلة')),
            ],
          ),
          backgroundColor: AppColors.calories,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ✅ عرض تحذير القيود الصحية
  Widget _buildHealthRestrictionsWarning(ThemeData theme) {
    if (_avoidedFoods.isEmpty &&
        _avoidedDrinks.isEmpty &&
        !_isLoadingRestrictions) {
      return const SizedBox();
    }
    return Semantics(
      label: 'تحذيرات القيود الصحية',
      container: true,
      child: HealthRestrictionWarning(
        avoidedFoods: _avoidedFoods,
        avoidedDrinks: _avoidedDrinks,
        recommendedFoods: _recommendedFoods.isEmpty ? null : _recommendedFoods,
        isLoading: _isLoadingRestrictions,
      ),
    );
  }

  // ✅ عرض بطاقة المغذيات المستهدفة
  Widget _buildTargetNutrients(ThemeData theme) {
    return Semantics(
      label: 'المغذيات المستهدفة اليومية',
      container: true,
      child: TargetNutrientsCard(
        protein: _totalProtein,
        carbs: _totalCarbs,
        fat: _totalFat,
        targetProtein: _targetProtein,
        targetCarbs: _targetCarbs,
        targetFat: _targetFat,
      ),
    );
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
            label: 'شاشة تسجيل وجبة',
            header: true,
            child: Text('➕ تسجيل وجبة'),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'مساعدة',
              child: IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                onPressed: _showHelpDialog,
                tooltip: 'مساعدة',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? Semantics(
                  label: 'جارٍ التحميل',
                  container: true,
                  child: const AddMealShimmer(),
                )
              : Column(
                  children: [
                    _buildHeader(theme),
                    Expanded(
                      child: FadeTransition(
                        opacity: _controller,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildHealthRestrictionsWarning(theme),
                              Semantics(
                                label: 'الأطعمة المحددة',
                                container: true,
                                child: _buildSelectedFoodsCard(theme),
                              ),
                              const SizedBox(height: 12),
                              _buildFavoritesQuickAdd(theme),
                              const SizedBox(height: 12),
                              _buildTargetNutrients(theme),
                              const SizedBox(height: 12),
                              Semantics(
                                label: 'إضافة طعام',
                                container: true,
                                child: _buildAddFoodSection(theme),
                              ),
                              const SizedBox(height: 12),
                              Semantics(
                                label: 'ملاحظات الوجبة',
                                container: true,
                                child: _buildNotesField(theme),
                              ),
                              const SizedBox(height: 12),
                              Semantics(
                                button: true,
                                label: 'حفظ الوجبة في المفضلة',
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _selectedFoods.isEmpty
                                        ? null
                                        : _saveMealToFavorites,
                                    icon: const Icon(
                                      Icons.star_border,
                                      size: 18,
                                    ),
                                    label: const Text('💾 حفظ في المفضلة'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.calories,
                                      side: BorderSide(
                                        color: AppColors.calories.withOpacity(
                                          0.4,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildBottomBar(theme),
                  ],
                ),
        ),
      ),
    );
  }

  // ✅ دالة لعرض كل الأطعمة مع تمييز الممنوع والموصى به
  void _showAllFoodsDialog() {
    final theme = Theme.of(context);
    final foodsList = List<Food>.from(_filteredFoods);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Semantics(
                      label: 'مقبض السحب',
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.fastfood, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'كل الأطعمة',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${foodsList.length} صنف',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // حقل بحث
                    Semantics(
                      label: 'بحث عن طعام',
                      container: true,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setDialogState(() {
                              foodsList.clear();
                              foodsList.addAll(
                                _filteredFoods.where(
                                  (food) => food.name.contains(value),
                                ),
                              );
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'ابحث عن طعام...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: theme.colorScheme.primary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: foodsList.length,
                        itemBuilder: (context, index) {
                          final food = foodsList[index];
                          final isSelected = _selectedFoods.any(
                            (f) => f['name'] == food.name,
                          );
                          final isRecommended = _isFoodRecommended(food);
                          final isAvoided = !_isFoodAllowed(food);
                          Color categoryColor = getCategoryColor(food.category);

                          return Semantics(
                            label:
                                '${food.name} - ${food.calories.round()} سعرة',
                            container: true,
                            child: NutritionCard.flat(
                              margin: const EdgeInsets.only(bottom: 8),
                              backgroundColor: isRecommended
                                  ? AppColors.success.withOpacity(0.05)
                                  : isAvoided
                                  ? AppColors.danger.withOpacity(0.05)
                                  : null,
                              child: ListTile(
                                leading: Semantics(
                                  label: getCategoryEmoji(food.category),
                                  excludeSemantics: true,
                                  child: Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: categoryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        getCategoryEmoji(food.category),
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        food.name,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                    if (isRecommended)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(
                                            0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'موصى به',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                    if (isAvoided)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger.withOpacity(
                                            0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Text(
                                          'غير مناسب',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.danger,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${food.calories.round()} سعرة / ${food.unit}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                trailing: isSelected
                                    ? Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(
                                            0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: AppColors.success,
                                          size: 18,
                                        ),
                                      )
                                    : isAvoided
                                    ? Semantics(
                                        button: true,
                                        label: 'غير متاح - ${food.name}',
                                        child: OutlinedButton(
                                          onPressed: null,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.danger,
                                            minimumSize: const Size(44, 44),
                                          ),
                                          child: const Text('غير متاح'),
                                        ),
                                      )
                                    : Semantics(
                                        button: true,
                                        label: 'إضافة ${food.name}',
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedFoods.add({
                                                'name': food.name,
                                                'calories': food.calories
                                                    .round(),
                                                'protein': food.protein,
                                                'carbs': food.carbs,
                                                'fat': food.fat,
                                                'unit': food.unit,
                                                'category': food.category,
                                                'food_id': food.id,
                                              });
                                              _filterFoods();
                                            });
                                            setDialogState(() {
                                              foodsList.removeWhere(
                                                (f) => f.name == food.name,
                                              );
                                            });
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '✅ تم إضافة ${food.name}',
                                                ),
                                                backgroundColor:
                                                    AppColors.success,
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.primary,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(44, 44),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: const Text('إضافة'),
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: _buildMealTypeChips(theme)),
      ),
    );
  }

  List<Widget> _buildMealTypeChips(ThemeData theme) {
    return mealTypes.map((type) {
      bool isSelected = _selectedMealType == type;
      Color color = getMealTypeColor(type);
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: FilterChip(
          label: Semantics(
            label: '$type ${isSelected ? "محدد حالياً" : ""}',
            excludeSemantics: true,
            child: Text(type),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedMealType = type;
            });
          },
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          selectedColor: color.withOpacity(0.2),
          checkmarkColor: color,
          labelStyle: TextStyle(
            color: isSelected
                ? color
                : theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          avatar: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 12,
            child: Text(
              getMealEmoji(type),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          visualDensity: VisualDensity.comfortable,
        ),
      );
    }).toList();
  }

  Widget _buildSelectedFoodsCard(ThemeData theme) {
    return Semantics(
      label: 'الأطعمة المحددة في الوجبة',
      container: true,
      child: Semantics(
        label: 'إجمالي ${_totalCalories.toInt()} سعرة حرارية',
        child: SelectedFoodsSection(
          selectedFoods: _selectedFoods,
          totalCalories: _totalCalories,
          totalProtein: _totalProtein,
          totalCarbs: _totalCarbs,
          totalFat: _totalFat,
          onRemoveFood: (index) {
            setState(() {
              _selectedFoods.removeAt(index);
            });
          },
          onClearAll: () {
            setState(() {
              _selectedFoods.clear();
            });
          },
        ),
      ),
    );
  }

  Widget _buildAddFoodSection(ThemeData theme) {
    return NutritionCard.defaultStyle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search, color: AppColors.success),
              ),
              const SizedBox(width: 8),
              Text(
                'أضف طعام',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Semantics(
            label: 'ابحث عن طعام',
            container: true,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن طعام...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Semantics(
            label: 'تصنيفات الأطعمة',
            container: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  bool isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterFoods();
                        });
                      },
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                      checkmarkColor: theme.colorScheme.primary,
                      visualDensity: VisualDensity.comfortable,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          _filteredFoods.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.no_food, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          _avoidedFoods.isNotEmpty
                              ? 'لا توجد أطعمة مسموحة'
                              : 'لا توجد أطعمة',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (_avoidedFoods.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'تم إخفاء الأطعمة التي تتعارض مع حالتك الصحية',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : Semantics(
                  label: 'قائمة الأطعمة المتاحة',
                  container: true,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredFoods.length > 10
                        ? 10
                        : _filteredFoods.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final food = _filteredFoods[index];
                      final isSelected = _selectedFoods.any(
                        (f) => f['name'] == food.name,
                      );
                      final isRecommended = _isFoodRecommended(food);
                      Color categoryColor = getCategoryColor(food.category);

                      return Semantics(
                        label: '${food.name} - ${food.calories.round()} سعرة',
                        container: true,
                        child: ListTile(
                          leading: Semantics(
                            excludeSemantics: true,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  getCategoryEmoji(food.category),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                          title: Row(
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'موصى به',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${food.calories.round()} سعرة / ${food.unit}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                          trailing: isSelected
                              ? Container(
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
                              : Semantics(
                                  button: true,
                                  label: 'إضافة ${food.name}',
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFoods.add({
                                          'name': food.name,
                                          'calories': food.calories.round(),
                                          'protein': food.protein,
                                          'carbs': food.carbs,
                                          'fat': food.fat,
                                          'unit': food.unit,
                                          'category': food.category,
                                          'food_id': food.id,
                                        });
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(44, 44),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text('إضافة'),
                                  ),
                                ),
                          minLeadingWidth: 44,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),

          if (_filteredFoods.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'عرض جميع الأطعمة (${_filteredFoods.length})',
                  child: TextButton(
                    onPressed: _showAllFoodsDialog,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    child: Text('عرض الكل (${_filteredFoods.length})'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesField(ThemeData theme) {
    return NutritionCard.defaultStyle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.note, color: AppColors.warning),
              ),
              const SizedBox(width: 8),
              Text(
                'ملاحظات (اختياري)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'حقل إضافة ملاحظات',
            container: true,
            child: TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'أضف أي ملاحظات عن الوجبة...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.12),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Semantics(
              label: 'إجمالي السعرات ${_totalCalories.toInt()}',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.calories.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('إجمالي', style: TextStyle(fontSize: 10)),
                    Text(
                      _totalCalories.toInt().toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.calories,
                      ),
                    ),
                    const Text('سعرة', style: TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Semantics(
                button: true,
                label: 'حفظ الوجبة',
                child: ElevatedButton(
                  onPressed: _selectedFoods.isEmpty ? null : _saveMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    minimumSize: const Size(44, 44),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save),
                      const SizedBox(width: 8),
                      const Text(
                        'حفظ الوجبة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Semantics(
          label: 'كيفية إضافة وجبة - تعليمات',
          header: true,
          child: const Text('كيفية إضافة وجبة'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('1', 'اختر نوع الوجبة (فطور/غداء/عشاء/سناك)', theme),
            _buildHelpItem('2', 'ابحث عن الأطعمة التي تناولتها', theme),
            _buildHelpItem('3', 'اضغط على "إضافة" لإضافتها للوجبة', theme),
            _buildHelpItem('4', 'كرر الخطوات لكل الأطعمة', theme),
            _buildHelpItem('5', 'أضف ملاحظات (اختياري)', theme),
            _buildHelpItem('6', 'اضغط على "حفظ الوجبة"', theme),
          ],
        ),
        actions: [
          Semantics(
            button: true,
            label: 'إغلاق التعليمات',
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: const Text('حسناً'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String number, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'خطوة $number',
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _saveMeal() async {
    final mealData = {
      'type': _selectedMealType,
      'date_time': DateTime.now().toIso8601String(),
      'notes': _notesController.text,
      'foods': _selectedFoods.map((f) {
        return {
          'food_id': f['food_id'] ?? 0,
          'name': f['name'] ?? '',
          'quantity': (f['quantity'] ?? 1.0).toDouble(),
          'unit': f['unit'] ?? 'جرام',
          'calories': (f['calories'] ?? 0).toDouble(),
          'protein': (f['protein'] ?? 0).toDouble(),
          'carbs': (f['carbs'] ?? 0).toDouble(),
          'fat': (f['fat'] ?? 0).toDouble(),
        };
      }).toList(),
    };

    final result = await NutritionService.addMeal(mealData);

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('✅ ${result['message']}')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context, true);
    }
  }
}
