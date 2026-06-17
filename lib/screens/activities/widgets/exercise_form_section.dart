// lib/screens/activities/widgets/exercise_form_section.dart
/// أداة مشتركة لقسم التمارين المتعددة - تستخدم في شاشتي الإضافة والتعديل
/// تدعم قائمة متعددة من التمارين مع إضافة/حذف/تعديل

import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../data/gym_exercises.dart';
import '../../../models/activity_model.dart';
import '../../../models/gym_exercise.dart';
import 'exercise_selector.dart';

/// نتيجة اختيار التمرين مع بياناته المحسوبة
class ExerciseFormResult {
  final GymExercise exercise;
  final int sets;
  final int reps;
  final double weightKg;
  final int restSeconds;
  final int calculatedCalories;
  final int orderIndex;

  const ExerciseFormResult({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.restSeconds,
    required this.calculatedCalories,
    this.orderIndex = 0,
  });

  /// تحويل من ActivityExercise (من API) إلى ExerciseFormResult
  factory ExerciseFormResult.fromActivityExercise(
    ActivityExercise ae, {
    int index = 0,
  }) {
    // محاولة إيجاد التمرين في المكتبة
    final libraryExercise = GymExerciseLibrary.findById(
      ae.exerciseId ?? '',
    );

    return ExerciseFormResult(
      exercise: libraryExercise ??
          GymExercise(
            id: ae.exerciseId ?? 'unknown',
            nameAr: ae.exerciseNameAr ?? ae.exerciseNameEn ?? '',
            nameEn: ae.exerciseNameEn ?? ae.exerciseNameAr ?? '',
            muscleGroup: MuscleGroup.values.firstWhere(
              (mg) =>
                  mg.nameAr == ae.muscleGroup ||
                  mg.nameEn == ae.muscleGroupEn,
              orElse: () => MuscleGroup.fullBody,
            ),
            metValue: ae.metValue ?? 5.0,
            description: '',
          ),
      sets: ae.sets ?? 4,
      reps: ae.reps ?? 10,
      weightKg: ae.weightKg ?? 0,
      restSeconds: ae.restSeconds ?? 60,
      calculatedCalories: ae.caloriesBurned ?? 0,
      orderIndex: ae.orderIndex ?? index,
    );
  }

  /// تحويل إلى JSON صالح لواجهة API للتمارين المتعددة
  Map<String, dynamic> toJson() => {
    'exercise_id': exercise.id,
    'exercise_name_ar': exercise.nameAr,
    'exercise_name_en': exercise.nameEn,
    'muscle_group': exercise.muscleGroup.nameAr,
    'muscle_group_en': exercise.muscleGroup.nameEn,
    'met_value': exercise.metValue,
    'sets': sets,
    'reps': reps,
    'weight_kg': weightKg,
    'rest_seconds': restSeconds,
    'calories_burned': calculatedCalories,
    'order_index': orderIndex,
  };
}

/// قسم تفاصيل التمارين المُشترك بين شاشات الإضافة والتعديل
/// يدير قائمة متعددة من التمارين مع إضافة/تعديل/حذف
class ExerciseFormSection extends StatefulWidget {
  /// القيم الأولية (للتعديل - قائمة تمارين موجودة)
  final List<ExerciseFormResult> initialExercises;

  /// يُستدعى عند تغيير أي تمرين في القائمة
  final ValueChanged<List<ExerciseFormResult>> onChanged;

  const ExerciseFormSection({
    Key? key,
    this.initialExercises = const [],
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ExerciseFormSection> createState() => _ExerciseFormSectionState();
}

class _ExerciseFormSectionState extends State<ExerciseFormSection> {
  late List<ExerciseFormResult> _exercises;

  /// قائمة التمارين الحالية (للوصول إليها من الخارج إن لزم)
  List<ExerciseFormResult> get currentExercises => List.unmodifiable(_exercises);

  @override
  void initState() {
    super.initState();
    _exercises = List.from(widget.initialExercises);
    // تحديث order_index بناءً على الترتيب
    _normalizeOrderIndex();
  }

  @override
  void didUpdateWidget(ExerciseFormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialExercises != widget.initialExercises) {
      _exercises = List.from(widget.initialExercises);
      _normalizeOrderIndex();
      _notifyChanged();
    }
  }

  void _normalizeOrderIndex() {
    for (int i = 0; i < _exercises.length; i++) {
      _exercises[i] = ExerciseFormResult(
        exercise: _exercises[i].exercise,
        sets: _exercises[i].sets,
        reps: _exercises[i].reps,
        weightKg: _exercises[i].weightKg,
        restSeconds: _exercises[i].restSeconds,
        calculatedCalories: _exercises[i].calculatedCalories,
        orderIndex: i,
      );
    }
  }

  void _notifyChanged() {
    widget.onChanged(List.from(_exercises));
  }

  Future<void> _addExercise() async {
    final result = await showExerciseSelector(context: context);
    if (result != null && mounted) {
      final formResult = ExerciseFormResult(
        exercise: result.exercise,
        sets: result.sets,
        reps: result.reps,
        weightKg: result.weightKg,
        restSeconds: result.restSeconds,
        calculatedCalories: result.calculatedCalories,
        orderIndex: _exercises.length,
      );
      setState(() => _exercises.add(formResult));
      _notifyChanged();
    }
  }

  Future<void> _editExercise(int index) async {
    if (index < 0 || index >= _exercises.length) return;
    final existing = _exercises[index];

    final result = await showExerciseSelector(
      context: context,
      initialExerciseId: existing.exercise.id,
      initialSets: existing.sets,
      initialReps: existing.reps,
      initialWeightKg: existing.weightKg,
      initialRestSeconds: existing.restSeconds,
    );

    if (result != null && mounted) {
      final formResult = ExerciseFormResult(
        exercise: result.exercise,
        sets: result.sets,
        reps: result.reps,
        weightKg: result.weightKg,
        restSeconds: result.restSeconds,
        calculatedCalories: result.calculatedCalories,
        orderIndex: index,
      );
      setState(() => _exercises[index] = formResult);
      _notifyChanged();
    }
  }

  void _removeExercise(int index) {
    if (index < 0 || index >= _exercises.length) return;
    setState(() {
      _exercises.removeAt(index);
      _normalizeOrderIndex();
    });
    _notifyChanged();
  }

  int get _totalCalories =>
      _exercises.fold(0, (sum, e) => sum + e.calculatedCalories);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان + عدد التمارين
          Row(
            children: [
              const Icon(
                Icons.fitness_center,
                size: 18,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Text(
                '🏋️ التمارين المضافة (${_exercises.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // قائمة التمارين
          if (_exercises.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 32,
                    color: AppColors.warning.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لم تضف أي تمارين بعد',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.warning.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return _ExerciseCard(
                  exercise: exercise,
                  onTap: () => _editExercise(index),
                  onDelete: () => _removeExercise(index),
                );
              },
            ),

          const SizedBox(height: 12),

          // زر إضافة تمرين
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                _exercises.isEmpty
                    ? 'اختر تمرين من المكتبة (أكثر من 120 تمرين)'
                    : '➕ إضافة تمرين آخر',
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.warning),
                foregroundColor: AppColors.warning,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // إجمالي السعرات المحروقة
          if (_exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🔥 إجمالي السعرات المحروقة: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$_totalCalories سعرة',
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
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseFormResult exercise;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ex = exercise.exercise;

    return Dismissible(
      key: ValueKey('${ex.id}_${exercise.orderIndex}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('حذف التمرين'),
            content: Text('هل تريد حذف "${ex.nameAr}" من القائمة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              // أيقونة المجموعة العضلية
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    ex.muscleGroup.iconEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // معلومات التمرين
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.nameAr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise.sets} sets × ${exercise.reps} reps | '
                      '${exercise.weightKg}kg | راحة ${exercise.restSeconds}ث',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 12,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${exercise.calculatedCalories} سعرة',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'MET ${ex.metValue}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // زر الحذف
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.danger.withOpacity(0.7),
                onPressed: onDelete,
                tooltip: 'حذف التمرين',
              ),

              // مؤشر للتعديل
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
