// lib/screens/activities/widgets/exercise_selector.dart
/// أداة اختيار التمارين من مكتبة التمارين (أكثر من 120 تمرين)
/// مع إمكانية البحث والتصفية حسب مجموعة العضلات

import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../data/gym_exercises.dart';
import '../../../models/gym_exercise.dart';

/// واجهة لإرجاع التمرين المختار مع بياناته
class ExerciseSelectionResult {
  final GymExercise exercise;
  final int sets;
  final int reps;
  final double weightKg;
  final int restSeconds;

  const ExerciseSelectionResult({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.restSeconds,
  });

  int get calculatedCalories {
    // تقدير زمن التمرين بناءً على المجموعات والعدات
    final workSeconds = sets * (reps * 1.5);
    final totalRestSeconds = (sets - 1) * restSeconds;
    final totalMinutes = (workSeconds + totalRestSeconds) / 60.0;
    final hours = totalMinutes / 60.0;
    final calories = exercise.metValue * weightKg * hours;
    return calories.round().clamp(1, 9999);
  }

  Map<String, dynamic> toJson() => {
    'exercise_name_ar': exercise.nameAr,
    'exercise_name_en': exercise.nameEn,
    'exercise_id': exercise.id,
    'muscle_group': exercise.muscleGroup.nameAr,
    'met_value': exercise.metValue,
    'sets': sets,
    'reps': reps,
    'weight_kg': weightKg,
    'rest_seconds': restSeconds,
    'calories_burned': calculatedCalories,
  };
}

/// أداة اختيار التمرين - تظهر كنافذة منبثقة (Dialog/BottomSheet)
class ExerciseSelectorWidget extends StatefulWidget {
  final List<GymExercise> initialExercises;
  final String? initialExerciseId;
  final int? initialSets;
  final int? initialReps;
  final double? initialWeightKg;
  final int? initialRestSeconds;

  const ExerciseSelectorWidget({
    super.key,
    this.initialExercises = const [],
    this.initialExerciseId,
    this.initialSets,
    this.initialReps,
    this.initialWeightKg,
    this.initialRestSeconds,
  });

  @override
  State<ExerciseSelectorWidget> createState() => _ExerciseSelectorWidgetState();
}

class _ExerciseSelectorWidgetState extends State<ExerciseSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  MuscleGroup? _selectedGroup;
  List<GymExercise> _filteredExercises = [];

  // مقابض بيانات التمرين المختار
  GymExercise? _selectedExercise;
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _restController = TextEditingController();

  int? _calculatedCalories;

  @override
  void initState() {
    super.initState();
    _filteredExercises = GymExerciseLibrary.allExercises;

    // تحميل القيم الأولية
    if (widget.initialExerciseId != null) {
      _selectedExercise = GymExerciseLibrary.findById(
        widget.initialExerciseId!,
      );
    }
    if (widget.initialSets != null) {
      _setsController.text = widget.initialSets.toString();
    }
    if (widget.initialReps != null) {
      _repsController.text = widget.initialReps.toString();
    }
    if (widget.initialWeightKg != null) {
      _weightController.text = widget.initialWeightKg.toString();
    }
    if (widget.initialRestSeconds != null) {
      _restController.text = widget.initialRestSeconds.toString();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    super.dispose();
  }

  void _filterExercises() {
    final query = _searchController.text;
    setState(() {
      if (_selectedGroup != null) {
        _filteredExercises = GymExerciseLibrary.getByMuscleGroup(
          _selectedGroup!,
        );
        if (query.isNotEmpty) {
          _filteredExercises = _filteredExercises
              .where((e) => e.matches(query))
              .toList();
        }
      } else {
        _filteredExercises = GymExerciseLibrary.search(query);
      }
    });
  }

  void _calculateCalories() {
    if (_selectedExercise == null) return;

    final sets = int.tryParse(_setsController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;

    if (sets <= 0 || reps <= 0 || weight <= 0) {
      setState(() => _calculatedCalories = null);
      return;
    }

    // تقدير زمن التمرين
    final workSeconds = sets * (reps * 1.5);
    final restSeconds = int.tryParse(_restController.text) ?? 60;
    final totalRestSeconds = (sets - 1) * restSeconds;
    final totalMinutes = (workSeconds + totalRestSeconds) / 60.0;
    final hours = totalMinutes / 60.0;
    final calories = _selectedExercise!.metValue * weight * hours;

    setState(() {
      _calculatedCalories = calories.round().clamp(1, 9999);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🏋️ اختر تمرينك',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // مربع البحث
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '🔍 بحث عن تمرين...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _filterExercises();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => _filterExercises(),
              ),
              const SizedBox(height: 12),

              // شيب التصفية حسب العضلة
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(null, 'الكل', Icons.all_inclusive),
                    ...MuscleGroup.values.map(
                      (group) => _buildFilterChip(group, group.nameAr, null),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // قائمة التمارين المصفاة
              SizedBox(
                height: 200,
                child: _filteredExercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'لا توجد تمارين مطابقة',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
                          final isSelected =
                              _selectedExercise?.id == exercise.id;
                          return _buildExerciseItem(exercise, isSelected);
                        },
                      ),
              ),

              // حقول إدخال المجموعات والعدات والوزن
              if (_selectedExercise != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_selectedExercise!.nameAr} (${_selectedExercise!.nameEn})',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'MET: ${_selectedExercise!.metValue}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // المجموعات والعدات
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _setsController,
                              decoration: InputDecoration(
                                labelText: 'المجموعات',
                                hintText: 'مثال: 4',
                                prefixIcon: const Icon(Icons.repeat, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _calculateCalories(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _repsController,
                              decoration: InputDecoration(
                                labelText: 'العدات',
                                hintText: 'مثال: 10',
                                prefixIcon: const Icon(
                                  Icons.exposure,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _calculateCalories(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // الوزن والراحة
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _weightController,
                              decoration: InputDecoration(
                                labelText: 'الوزن (كجم)',
                                hintText: 'مثال: 60',
                                prefixIcon: const Icon(
                                  Icons.monitor_weight,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _calculateCalories(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _restController,
                              decoration: InputDecoration(
                                labelText: 'الراحة (ثانية)',
                                hintText: 'مثال: 60',
                                prefixIcon: const Icon(Icons.timer, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => _calculateCalories(),
                            ),
                          ),
                        ],
                      ),

                      // عرض السعرات المحروقة
                      if (_calculatedCalories != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '🔥 السعرات المحروقة المتوقعة: ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$_calculatedCalories سعرة',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // أزرار الإجراءات
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(null),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('إلغاء'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmSelection,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('تأكيد التمرين'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(MuscleGroup? group, String label, IconData? icon) {
    final isSelected = _selectedGroup == group;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 16)
            else
              Text(group!.iconEmoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedGroup = selected ? group : null;
            _filterExercises();
          });
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        backgroundColor: Theme.of(context).cardColor,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey[300]!,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildExerciseItem(GymExercise exercise, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedExercise = exercise;
            _calculateCalories();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Text(
                exercise.muscleGroup.iconEmoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.nameAr,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                        color: isSelected ? AppColors.primary : null,
                      ),
                    ),
                    Text(
                      exercise.nameEn,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'MET ${exercise.metValue}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : AppColors.warning,
                  ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedExercise == null) return;

    final sets = int.tryParse(_setsController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final rest = int.tryParse(_restController.text) ?? 60;

    if (sets <= 0 || reps <= 0 || weight <= 0) {
      // ✅ استخدام try/catch لأن context قد لا يكون مرتبطاً بـ Scaffold (bottom sheet)
      _showSnackBarSafe('❌ الرجاء إدخال المجموعات والعدات والوزن');
      return;
    }

    final result = ExerciseSelectionResult(
      exercise: _selectedExercise!,
      sets: sets,
      reps: reps,
      weightKg: weight,
      restSeconds: rest,
    );

    // ✅ Check mounted قبل pop
    if (context.mounted) {
      Navigator.of(context).pop(result);
    }
  }

  /// يحاول عرض SnackBar بشكل آمن (يتجنب referenceBox.attached error في bottom sheet)
  void _showSnackBarSafe(String message) {
    if (!context.mounted) return;
    try {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // تجاهل الخطأ - قد يكون context غير مرتبط بـ Scaffold في bottom sheet
    }
  }
}

/// دالة مساعدة لعرض منتقي التمارين
Future<ExerciseSelectionResult?> showExerciseSelector({
  required BuildContext context,
  String? initialExerciseId,
  int? initialSets,
  int? initialReps,
  double? initialWeightKg,
  int? initialRestSeconds,
}) {
  return showModalBottomSheet<ExerciseSelectionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => ExerciseSelectorWidget(
      initialExerciseId: initialExerciseId,
      initialSets: initialSets,
      initialReps: initialReps,
      initialWeightKg: initialWeightKg,
      initialRestSeconds: initialRestSeconds,
    ),
  );
}
