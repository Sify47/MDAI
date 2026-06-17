// lib/models/gym_exercise.dart
/// نموذج تمارين الجيم مع تصنيف العضلات وقيم MET

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  legs,
  glutes,
  abs,
  cardio,
  fullBody,
}

extension MuscleGroupExtension on MuscleGroup {
  String get nameAr {
    switch (this) {
      case MuscleGroup.chest:
        return 'الصدر';
      case MuscleGroup.back:
        return 'الظهر';
      case MuscleGroup.shoulders:
        return 'الأكتاف';
      case MuscleGroup.biceps:
        return 'البايسبس';
      case MuscleGroup.triceps:
        return 'الترايسبس';
      case MuscleGroup.legs:
        return 'الأرجل';
      case MuscleGroup.glutes:
        return 'المؤخرة';
      case MuscleGroup.abs:
        return 'البطن';
      case MuscleGroup.cardio:
        return 'كارديو';
      case MuscleGroup.fullBody:
        return 'كامل الجسم';
    }
  }

  String get nameEn {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.legs:
        return 'Legs';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.abs:
        return 'Abs';
      case MuscleGroup.cardio:
        return 'Cardio';
      case MuscleGroup.fullBody:
        return 'Full Body';
    }
  }

  String get iconEmoji {
    switch (this) {
      case MuscleGroup.chest:
        return '🏋️';
      case MuscleGroup.back:
        return '🔙';
      case MuscleGroup.shoulders:
        return '💪';
      case MuscleGroup.biceps:
        return '💪';
      case MuscleGroup.triceps:
        return '💪';
      case MuscleGroup.legs:
        return '🦵';
      case MuscleGroup.glutes:
        return '🍑';
      case MuscleGroup.abs:
        return '🧘';
      case MuscleGroup.cardio:
        return '🏃';
      case MuscleGroup.fullBody:
        return '🧬';
    }
  }
}

class GymExercise {
  final String id;
  final String nameAr;
  final String nameEn;
  final MuscleGroup muscleGroup;
  final double metValue;
  final String? description;

  const GymExercise({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.muscleGroup,
    required this.metValue,
    this.description,
  });

  /// البحث في اسم التمرين (عربي أو إنجليزي)
  bool matches(String query) {
    final q = query.toLowerCase().trim();
    return nameAr.toLowerCase().contains(q) ||
        nameEn.toLowerCase().contains(q);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_ar': nameAr,
        'name_en': nameEn,
        'muscle_group': muscleGroup.nameEn,
        'met_value': metValue,
        'description': description,
      };

  factory GymExercise.fromJson(Map<String, dynamic> json) {
    return GymExercise(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      muscleGroup: _parseMuscleGroup(json['muscle_group'] as String),
      metValue: (json['met_value'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }

  static MuscleGroup _parseMuscleGroup(String value) {
    switch (value.toLowerCase()) {
      case 'chest':
        return MuscleGroup.chest;
      case 'back':
        return MuscleGroup.back;
      case 'shoulders':
        return MuscleGroup.shoulders;
      case 'biceps':
        return MuscleGroup.biceps;
      case 'triceps':
        return MuscleGroup.triceps;
      case 'legs':
        return MuscleGroup.legs;
      case 'glutes':
        return MuscleGroup.glutes;
      case 'abs':
        return MuscleGroup.abs;
      case 'cardio':
        return MuscleGroup.cardio;
      case 'fullbody':
      case 'full body':
        return MuscleGroup.fullBody;
      default:
        return MuscleGroup.fullBody;
    }
  }
}