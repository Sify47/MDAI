// lib/data/gym_exercises.dart
/// مكتبة تمارين الجيم - أكثر من ١٢٠ تمرين مقسمة حسب العضلات مع قيم MET
///
/// المصادر: معادلة MET العامة (Compendium of Physical Activities)
/// يتم استخدام هذه القيم لحساب السعرات المحروقة بدقة لكل تمرين

import '../models/gym_exercise.dart';

class GymExerciseLibrary {
  /// جميع التمارين
  static final List<GymExercise> allExercises = [
    // ==========================================
    // 🏋️ الصدر (Chest) - 18 تمرين
    // ==========================================
    ..._chestExercises,
    // ==========================================
    // 🔙 الظهر (Back) - 16 تمرين
    // ==========================================
    ..._backExercises,
    // ==========================================
    // 💪 الأكتاف (Shoulders) - 14 تمرين
    // ==========================================
    ..._shoulderExercises,
    // ==========================================
    // 💪 البايسبس (Biceps) - 10 تمارين
    // ==========================================
    ..._bicepsExercises,
    // ==========================================
    // 💪 الترايسبس (Triceps) - 10 تمارين
    // ==========================================
    ..._tricepsExercises,
    // ==========================================
    // 🦵 الأرجل (Legs) - 18 تمرين
    // ==========================================
    ..._legExercises,
    // ==========================================
    // 🍑 المؤخرة (Glutes) - 8 تمارين
    // ==========================================
    ..._gluteExercises,
    // ==========================================
    // 🧘 البطن (Abs) - 14 تمرين
    // ==========================================
    ..._absExercises,
    // ==========================================
    // 🏃 كارديو (Cardio) - 10 تمارين
    // ==========================================
    ..._cardioExercises,
    // ==========================================
    // 🧬 كامل الجسم (Full Body) - 6 تمارين
    // ==========================================
    ..._fullBodyExercises,
  ];

  /// الحصول على التمارين حسب مجموعة العضلات
  static List<GymExercise> getByMuscleGroup(MuscleGroup group) {
    return allExercises.where((e) => e.muscleGroup == group).toList();
  }

  /// البحث عن تمارين
  static List<GymExercise> search(String query) {
    if (query.isEmpty) return allExercises;
    return allExercises.where((e) => e.matches(query)).toList();
  }

  /// البحث بالاسم (للربط مع البيانات المحفوظة)
  static GymExercise? findById(String id) {
    try {
      return allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// الحصول على قيمة MET لتمرين
  static double getMetValue(String exerciseId) {
    return findById(exerciseId)?.metValue ?? 4.0;
  }

  // ==========================================
  // تمارين الصدر
  // ==========================================
  static final List<GymExercise> _chestExercises = [
    const GymExercise(
      id: 'bench_press',
      nameAr: 'تمرين الضغط بالبار',
      nameEn: 'Barbell Bench Press',
      muscleGroup: MuscleGroup.chest,
      metValue: 5.5,
      description: 'استلق على بنش مسطح وادفع البار لأعلى',
    ),
    const GymExercise(
      id: 'dumbbell_press',
      nameAr: 'تمرين الضغط بالدمبل',
      nameEn: 'Dumbbell Bench Press',
      muscleGroup: MuscleGroup.chest,
      metValue: 5.0,
      description: 'استلق على بنش مسطح وادفع الدمبل لأعلى',
    ),
    const GymExercise(
      id: 'incline_bench_press',
      nameAr: 'تمرين الضغط المائل بالبار',
      nameEn: 'Incline Barbell Bench Press',
      muscleGroup: MuscleGroup.chest,
      metValue: 5.5,
      description: 'استلق على بنش مائل 30-45 درجة',
    ),
    const GymExercise(
      id: 'incline_dumbbell_press',
      nameAr: 'تمرين الضغط المائل بالدمبل',
      nameEn: 'Incline Dumbbell Press',
      muscleGroup: MuscleGroup.chest,
      metValue: 5.3,
    ),
    const GymExercise(
      id: 'decline_bench_press',
      nameAr: 'تمرين الضغط المنخفض بالبار',
      nameEn: 'Decline Barbell Bench Press',
      muscleGroup: MuscleGroup.chest,
      metValue: 5.3,
    ),
    const GymExercise(
      id: 'cable_fly',
      nameAr: 'تمارين الكابل فلاي',
      nameEn: 'Cable Fly',
      muscleGroup: MuscleGroup.chest,
      metValue: 4.0,
      description: 'استخدم جهاز الكابل مع شد الذراعين للأمام',
    ),
    const GymExercise(
      id: 'dumbbell_fly',
      nameAr: 'تمارين الدمبل فلاي',
      nameEn: 'Dumbbell Fly',
      muscleGroup: MuscleGroup.chest,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'pec_deck',
      nameAr: 'جهاز الصدر (Pec Deck)',
      nameEn: 'Pec Deck Machine',
      muscleGroup: MuscleGroup.chest,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'push_up',
      nameAr: 'تمرين الضغط (بوش أب)',
      nameEn: 'Push-ups',
      muscleGroup: MuscleGroup.chest,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'wide_push_up',
      nameAr: 'تمرين الضغط الواسع',
      nameEn: 'Wide Push-ups',
      muscleGroup: MuscleGroup.chest,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'decline_push_up',
      nameAr: 'تمرين الضغط المائل للأسفل',
      nameEn: 'Decline Push-ups',
      muscleGroup: MuscleGroup.chest,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'chest_dip',
      nameAr: 'تمرين الغطس للصدر',
      nameEn: 'Chest Dip',
      muscleGroup: MuscleGroup.chest,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'smith_machine_bench',
      nameAr: 'جهاز سميث - ضغط صدر',
      nameEn: 'Smith Machine Bench Press',
      muscleGroup: MuscleGroup.chest,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'machine_chest_press',
      nameAr: 'جهاز ضغط الصدر',
      nameEn: 'Machine Chest Press',
      muscleGroup: MuscleGroup.chest,
      metValue: 4.5,
    ),
    const GymExercise(
      id: 'cable_crossover',
      nameAr: 'كابل كروس أوفر',
      nameEn: 'Cable Crossover',
      muscleGroup: MuscleGroup.chest,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'floor_press',
      nameAr: 'ضغط صدر من الأرض',
      nameEn: 'Floor Press',
      muscleGroup: MuscleGroup.chest,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'hex_press',
      nameAr: 'ضغط هكس بالدمبل',
      nameEn: 'Hex Press',
      muscleGroup: MuscleGroup.chest,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'svend_press',
      nameAr: 'ضغط سفيند',
      nameEn: 'Svend Press',
      muscleGroup: MuscleGroup.chest,
      metValue: 4.0,
    ),
  ];

  // ==========================================
  // تمارين الظهر
  // ==========================================
  static final List<GymExercise> _backExercises = [
    const GymExercise(
      id: 'lat_pulldown',
      nameAr: 'السحب العالي',
      nameEn: 'Lat Pulldown',
      muscleGroup: MuscleGroup.back,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'barbell_row',
      nameAr: 'التجديف بالبار',
      nameEn: 'Barbell Row',
      muscleGroup: MuscleGroup.back,
      metValue: 5.5,
    ),
    const GymExercise(
      id: 'pull_up',
      nameAr: 'السحب (عقلة)',
      nameEn: 'Pull-ups',
      muscleGroup: MuscleGroup.back,
      metValue: 6.0,
    ),
    const GymExercise(
      id: 'dumbbell_row',
      nameAr: 'التجديف بالدمبل',
      nameEn: 'Dumbbell Row',
      muscleGroup: MuscleGroup.back,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 't_bar_row',
      nameAr: 'التجديف بـ T-Bar',
      nameEn: 'T-Bar Row',
      muscleGroup: MuscleGroup.back,
      metValue: 5.5,
    ),
    const GymExercise(
      id: 'seated_cable_row',
      nameAr: 'التجديف بالكابل جلوس',
      nameEn: 'Seated Cable Row',
      muscleGroup: MuscleGroup.back,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'deadlift',
      nameAr: 'الرفعة الميتة',
      nameEn: 'Deadlift',
      muscleGroup: MuscleGroup.back,
      metValue: 6.5,
    ),
    const GymExercise(
      id: 'romanian_deadlift',
      nameAr: 'الرفعة الميتة الرومانية',
      nameEn: 'Romanian Deadlift',
      muscleGroup: MuscleGroup.back,
      metValue: 5.5,
    ),
    const GymExercise(
      id: 'chin_up',
      nameAr: 'السحب العكسي (عقلة عكسية)',
      nameEn: 'Chin-ups',
      muscleGroup: MuscleGroup.back,
      metValue: 5.5,
    ),
    const GymExercise(
      id: 'reverse_fly',
      nameAr: 'رفرفة عكسية',
      nameEn: 'Reverse Fly',
      muscleGroup: MuscleGroup.back,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'face_pull',
      nameAr: 'سحب الوجه',
      nameEn: 'Face Pull',
      muscleGroup: MuscleGroup.back,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'straight_arm_pulldown',
      nameAr: 'سحب الكابل بذراعين ممدودتين',
      nameEn: 'Straight Arm Pulldown',
      muscleGroup: MuscleGroup.back,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'machine_row',
      nameAr: 'جهاز التجديف',
      nameEn: 'Machine Row',
      muscleGroup: MuscleGroup.back,
      metValue: 4.5,
    ),
    const GymExercise(
      id: 'good_morning',
      nameAr: 'تمرين صباح الخير',
      nameEn: 'Good Morning',
      muscleGroup: MuscleGroup.back,
      metValue: 4.5,
    ),
    const GymExercise(
      id: 'hyperextension',
      nameAr: 'فرد الظهر (هابراكستنشن)',
      nameEn: 'Hyperextension',
      muscleGroup: MuscleGroup.back,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'wide_grip_pulldown',
      nameAr: 'سحب علوي بقبضة واسعة',
      nameEn: 'Wide Grip Pulldown',
      muscleGroup: MuscleGroup.back,
      metValue: 5.0,
    ),
  ];

  // ==========================================
  // تمارين الأكتاف
  // ==========================================
  static final List<GymExercise> _shoulderExercises = [
    const GymExercise(
      id: 'overhead_press',
      nameAr: 'ضغط الأكتاف بالبار',
      nameEn: 'Overhead Press (OHP)',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 5.5,
    ),
    const GymExercise(
      id: 'dumbbell_shoulder_press',
      nameAr: 'ضغط الأكتاف بالدمبل',
      nameEn: 'Dumbbell Shoulder Press',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'lateral_raise',
      nameAr: 'رفع جانبي',
      nameEn: 'Lateral Raise',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'front_raise',
      nameAr: 'رفع أمامي',
      nameEn: 'Front Raise',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'rear_delt_fly',
      nameAr: 'رفرفة الأكتاف الخلفية',
      nameEn: 'Rear Delt Fly',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'arnold_press',
      nameAr: 'ضغط أرنولد',
      nameEn: 'Arnold Press',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'upright_row',
      nameAr: 'سحب عمودي',
      nameEn: 'Upright Row',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 4.5,
    ),
    const GymExercise(
      id: 'shrug',
      nameAr: 'تمرين الرقبة (شرج)',
      nameEn: 'Barbell Shrug',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'dumbbell_shrug',
      nameAr: 'تمرين الرقبة بالدمبل',
      nameEn: 'Dumbbell Shrug',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'cable_lateral_raise',
      nameAr: 'رفع جانبي بالكابل',
      nameEn: 'Cable Lateral Raise',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'smith_machine_ohp',
      nameAr: 'سميث مشين - ضغط أكتاف',
      nameEn: 'Smith Machine OHP',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'plate_front_raise',
      nameAr: 'رفع أمامي بالطبق',
      nameEn: 'Plate Front Raise',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'handstand_push_up',
      nameAr: 'ضغط بالوقوف على اليدين',
      nameEn: 'Handstand Push-up',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'pike_push_up',
      nameAr: 'ضغط بايك',
      nameEn: 'Pike Push-up',
      muscleGroup: MuscleGroup.shoulders,
      metValue: 4.0,
    ),
  ];

  // ==========================================
  // تمارين البايسبس
  // ==========================================
  static final List<GymExercise> _bicepsExercises = [
    const GymExercise(
      id: 'barbell_curl',
      nameAr: 'تمرين البايسبس بالبار',
      nameEn: 'Barbell Curl',
      muscleGroup: MuscleGroup.biceps,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'dumbbell_curl',
      nameAr: 'تمرين البايسبس بالدمبل',
      nameEn: 'Dumbbell Curl',
      muscleGroup: MuscleGroup.biceps,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'hammer_curl',
      nameAr: 'تمرين المطرقة',
      nameEn: 'Hammer Curl',
      muscleGroup: MuscleGroup.biceps,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'preacher_curl',
      nameAr: 'بايسبس على بنش براير',
      nameEn: 'Preacher Curl',
      muscleGroup: MuscleGroup.biceps,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'cable_curl',
      nameAr: 'بايسبس بالكابل',
      nameEn: 'Cable Curl',
      muscleGroup: MuscleGroup.biceps,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'concentration_curl',
      nameAr: 'بايسبس تركيز',
      nameEn: 'Concentration Curl',
      muscleGroup: MuscleGroup.biceps,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'incline_curl',
      nameAr: 'بايسبس على بنش مائل',
      nameEn: 'Incline Dumbbell Curl',
      muscleGroup: MuscleGroup.biceps,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'ez_bar_curl',
      nameAr: 'بايسبس بـ EZ Bar',
      nameEn: 'EZ Bar Curl',
      muscleGroup: MuscleGroup.biceps,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'reverse_curl',
      nameAr: 'بايسبس عكسي',
      nameEn: 'Reverse Curl',
      muscleGroup: MuscleGroup.biceps,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'spider_curl',
      nameAr: 'سبايدر كيرل',
      nameEn: 'Spider Curl',
      muscleGroup: MuscleGroup.biceps,
      metValue: 4.0,
    ),
  ];

  // ==========================================
  // تمارين الترايسبس
  // ==========================================
  static final List<GymExercise> _tricepsExercises = [
    const GymExercise(
      id: 'tricep_pushdown',
      nameAr: 'تمرين الترايسبس بالكابل',
      nameEn: 'Tricep Pushdown',
      muscleGroup: MuscleGroup.triceps,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'skull_crusher',
      nameAr: 'سكل كرشر (تكبير الجماجم)',
      nameEn: 'Skull Crusher (Lying Tricep Extension)',
      muscleGroup: MuscleGroup.triceps,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'close_grip_bench',
      nameAr: 'ضغط صدر بقبضة ضيقة',
      nameEn: 'Close Grip Bench Press',
      muscleGroup: MuscleGroup.triceps,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'overhead_tricep_extension',
      nameAr: 'فرد ترايسبس خلف الرأس',
      nameEn: 'Overhead Tricep Extension',
      muscleGroup: MuscleGroup.triceps,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'tricep_dip',
      nameAr: 'غطس ترايسبس',
      nameEn: 'Tricep Dip',
      muscleGroup: MuscleGroup.triceps,
      metValue: 4.5,
    ),
    const GymExercise(
      id: 'kickback',
      nameAr: 'تمرين الكيك باك',
      nameEn: 'Dumbbell Kickback',
      muscleGroup: MuscleGroup.triceps,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'cable_overhead_extension',
      nameAr: 'فرد ترايسبس بالكابل من فوق',
      nameEn: 'Cable Overhead Tricep Extension',
      muscleGroup: MuscleGroup.triceps,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'diamond_push_up',
      nameAr: 'ضغط دايموند (ماسي)',
      nameEn: 'Diamond Push-up',
      muscleGroup: MuscleGroup.triceps,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'tricep_machine',
      nameAr: 'جهاز الترايسبس',
      nameEn: 'Tricep Machine',
      muscleGroup: MuscleGroup.triceps,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'bench_dip',
      nameAr: 'غطس من على بنش',
      nameEn: 'Bench Dip',
      muscleGroup: MuscleGroup.triceps,
      metValue: 4.0,
    ),
  ];

  // ==========================================
  // تمارين الأرجل
  // ==========================================
  static final List<GymExercise> _legExercises = [
    const GymExercise(
      id: 'squat',
      nameAr: 'القرفصاء (سكوات)',
      nameEn: 'Barbell Back Squat',
      muscleGroup: MuscleGroup.legs,
      metValue: 6.0,
    ),
    const GymExercise(
      id: 'front_squat',
      nameAr: 'القرفصاء الأمامي',
      nameEn: 'Front Squat',
      muscleGroup: MuscleGroup.legs,
      metValue: 6.0,
    ),
    const GymExercise(
      id: 'goblet_squat',
      nameAr: 'القرفصاء الكأسية',
      nameEn: 'Goblet Squat',
      muscleGroup: MuscleGroup.legs,
      metValue: 5.5,
    ),
    const GymExercise(
      id: 'leg_press',
      nameAr: 'ضغط الأرجل',
      nameEn: 'Leg Press',
      muscleGroup: MuscleGroup.legs,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'leg_extension',
      nameAr: 'تمديد الأرجل',
      nameEn: 'Leg Extension',
      muscleGroup: MuscleGroup.legs,
      metValue: 4.5,
    ),
    const GymExercise(
      id: 'leg_curl',
      nameAr: 'ثني الأرجل',
      nameEn: 'Leg Curl',
      muscleGroup: MuscleGroup.legs,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'lunges',
      nameAr: 'الاندفاع (طعنات)',
      nameEn: 'Walking Lunges',
      muscleGroup: MuscleGroup.legs,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'bulgarian_split_squat',
      nameAr: 'قرفصاء بلغاري',
      nameEn: 'Bulgarian Split Squat',
      muscleGroup: MuscleGroup.legs,
      metValue: 5.5,
    ),
    const GymExercise(
      id: 'hack_squat',
      nameAr: 'هيك سكوات',
      nameEn: 'Hack Squat',
      muscleGroup: MuscleGroup.legs,
      metValue: 5.5,
    ),
    const GymExercise(
      id: 'calf_raise_standing',
      nameAr: 'رفع السمانة واقف',
      nameEn: 'Standing Calf Raise',
      muscleGroup: MuscleGroup.legs,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'calf_raise_seated',
      nameAr: 'رفع السمانة جالس',
      nameEn: 'Seated Calf Raise',
      muscleGroup: MuscleGroup.legs,
      metValue: 3.0,
    ),
    const GymExercise(
      id: 'step_up',
      nameAr: 'صعود الصندوق',
      nameEn: 'Step-ups',
      muscleGroup: MuscleGroup.legs,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'pistol_squat',
      nameAr: 'قرفصاء بستول (رجل واحدة)',
      nameEn: 'Pistol Squat',
      muscleGroup: MuscleGroup.legs,
      metValue: 6.0,
    ),
    const GymExercise(
      id: 'sissy_squat',
      nameAr: 'قرفصاء سيسي',
      nameEn: 'Sissy Squat',
      muscleGroup: MuscleGroup.legs,
      metValue: 4.5,
    ),
    const GymExercise(
      id: 'box_jump',
      nameAr: 'القفز على الصندوق',
      nameEn: 'Box Jump',
      muscleGroup: MuscleGroup.legs,
      metValue: 6.0,
    ),
    const GymExercise(
      id: 'squat_jump',
      nameAr: 'قفز قرفصاء',
      nameEn: 'Jump Squat',
      muscleGroup: MuscleGroup.legs,
      metValue: 6.5,
    ),
    const GymExercise(
      id: 'smith_machine_squat',
      nameAr: 'سميث مشين - سكوات',
      nameEn: 'Smith Machine Squat',
      muscleGroup: MuscleGroup.legs,
      metValue: 5.5,
    ),
    const GymExercise(
      id: 'adductor_machine',
      nameAr: 'جهاز تقريب الأرجل',
      nameEn: 'Adductor Machine',
      muscleGroup: MuscleGroup.legs,
      metValue: 3.0,
    ),
  ];

  // ==========================================
  // تمارين المؤخرة
  // ==========================================
  static final List<GymExercise> _gluteExercises = [
    const GymExercise(
      id: 'hip_thrust',
      nameAr: 'دفع الحوض (هيب ثراست)',
      nameEn: 'Hip Thrust',
      muscleGroup: MuscleGroup.glutes,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'glute_bridge',
      nameAr: 'جسر المؤخرة',
      nameEn: 'Glute Bridge',
      muscleGroup: MuscleGroup.glutes,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'cable_kickback',
      nameAr: 'رفع رجل للخلف بالكابل',
      nameEn: 'Cable Kickback',
      muscleGroup: MuscleGroup.glutes,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'donkey_kick',
      nameAr: 'رفع رجل لأعلى (دونكي كيك)',
      nameEn: 'Donkey Kick',
      muscleGroup: MuscleGroup.glutes,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'fire_hydrant',
      nameAr: 'رفع رجل جانبي',
      nameEn: 'Fire Hydrant',
      muscleGroup: MuscleGroup.glutes,
      metValue: 3.0,
    ),
    const GymExercise(
      id: 'sumo_squat',
      nameAr: 'قرفصاء سومو',
      nameEn: 'Sumo Squat',
      muscleGroup: MuscleGroup.glutes,
      metValue: 5.0,
    ),
    const GymExercise(
      id: 'curtsey_lunge',
      nameAr: 'طعنة كورتسي',
      nameEn: 'Curtsey Lunge',
      muscleGroup: MuscleGroup.glutes,
      metValue: 4.5,
    ),
    const GymExercise(
      id: 'single_leg_glute_bridge',
      nameAr: 'جسر المؤخرة برجل واحدة',
      nameEn: 'Single Leg Glute Bridge',
      muscleGroup: MuscleGroup.glutes,
      metValue: 4.0,
    ),
  ];

  // ==========================================
  // تمارين البطن
  // ==========================================
  static final List<GymExercise> _absExercises = [
    const GymExercise(
      id: 'crunch',
      nameAr: 'تمرين البطن (كرانش)',
      nameEn: 'Crunch',
      muscleGroup: MuscleGroup.abs,
      metValue: 3.0,
    ),
    const GymExercise(
      id: 'plank',
      nameAr: 'تمرين البلانك',
      nameEn: 'Plank',
      muscleGroup: MuscleGroup.abs,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'leg_raise',
      nameAr: 'رفع الأرجل',
      nameEn: 'Leg Raise',
      muscleGroup: MuscleGroup.abs,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'russian_twist',
      nameAr: 'اللف الروسي',
      nameEn: 'Russian Twist',
      muscleGroup: MuscleGroup.abs,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'hanging_leg_raise',
      nameAr: 'رفع الأرجل من التعليق',
      nameEn: 'Hanging Leg Raise',
      muscleGroup: MuscleGroup.abs,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'cable_crunch',
      nameAr: 'كرانش بالكابل',
      nameEn: 'Cable Crunch',
      muscleGroup: MuscleGroup.abs,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'ab_wheel',
      nameAr: 'العجلة (عجلة البطن)',
      nameEn: 'Ab Wheel Rollout',
      muscleGroup: MuscleGroup.abs,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'bicycle_crunch',
      nameAr: 'كرانش الدراجة',
      nameEn: 'Bicycle Crunch',
      muscleGroup: MuscleGroup.abs,
      metValue: 3.5,
    ),
    const GymExercise(
      id: 'v_up',
      nameAr: 'تمرين V-Up',
      nameEn: 'V-Up',
      muscleGroup: MuscleGroup.abs,
      metValue: 4.0,
    ),
    const GymExercise(
      id: 'mountain_climber',
      nameAr: 'متسلق الجبال',
      nameEn: 'Mountain Climber',
      muscleGroup: MuscleGroup.abs,
      metValue: 4.5,
    ),
    const GymExercise(
      id: 'dead_bug',
      nameAr: 'الحشرة الميتة',
      nameEn: 'Dead Bug',
      muscleGroup: MuscleGroup.abs,
      metValue: 3.0,
    ),
    const GymExercise(
      id: 'side_plank',
      nameAr: 'بلانك جانبي',
      nameEn: 'Side Plank',
      muscleGroup: MuscleGroup.abs,
      metValue: 3.0,
    ),
    const GymExercise(
      id: 'toes_to_bar',
      nameAr: 'لمس البار بالأرجل',
      nameEn: 'Toes to Bar',
      muscleGroup: MuscleGroup.abs,
      metValue: 4.5,
    ),
    const GymExercise(
      id: 'decline_crunch',
      nameAr: 'كرانش مائل للأسفل',
      nameEn: 'Decline Crunch',
      muscleGroup: MuscleGroup.abs,
      metValue: 3.5,
    ),
  ];

  // ==========================================
  // تمارين كارديو
  // ==========================================
  static final List<GymExercise> _cardioExercises = [
    const GymExercise(
      id: 'treadmill',
      nameAr: 'جهاز المشي',
      nameEn: 'Treadmill',
      muscleGroup: MuscleGroup.cardio,
      metValue: 8.0,
    ),
    const GymExercise(
      id: 'stationary_bike',
      nameAr: 'الدراجة الثابتة',
      nameEn: 'Stationary Bike',
      muscleGroup: MuscleGroup.cardio,
      metValue: 7.0,
    ),
    const GymExercise(
      id: 'elliptical',
      nameAr: 'جهاز الإليبتيكال',
      nameEn: 'Elliptical Trainer',
      muscleGroup: MuscleGroup.cardio,
      metValue: 6.0,
    ),
    const GymExercise(
      id: 'rowing_machine',
      nameAr: 'جهاز التجديف',
      nameEn: 'Rowing Machine',
      muscleGroup: MuscleGroup.cardio,
      metValue: 7.5,
    ),
    const GymExercise(
      id: 'jump_rope',
      nameAr: 'نط الحبل',
      nameEn: 'Jump Rope',
      muscleGroup: MuscleGroup.cardio,
      metValue: 10.0,
    ),
    const GymExercise(
      id: 'burpee',
      nameAr: 'بيربي',
      nameEn: 'Burpees',
      muscleGroup: MuscleGroup.cardio,
      metValue: 8.0,
    ),
    const GymExercise(
      id: 'stair_climber',
      nameAr: 'جهاز صعود الدرج',
      nameEn: 'Stair Climber',
      muscleGroup: MuscleGroup.cardio,
      metValue: 8.0,
    ),
    const GymExercise(
      id: 'jumping_jack',
      nameAr: 'مقافز (Jumping Jacks)',
      nameEn: 'Jumping Jacks',
      muscleGroup: MuscleGroup.cardio,
      metValue: 5.5,
    ),
    const GymExercise(
      id: 'battle_ropes',
      nameAr: 'حبال المعركة',
      nameEn: 'Battle Ropes',
      muscleGroup: MuscleGroup.cardio,
      metValue: 6.5,
    ),
    const GymExercise(
      id: 'kettlebell_swing',
      nameAr: 'تأرجح الكيتلبل',
      nameEn: 'Kettlebell Swing',
      muscleGroup: MuscleGroup.cardio,
      metValue: 6.5,
    ),
  ];

  // ==========================================
  // تمارين كامل الجسم
  // ==========================================
  static final List<GymExercise> _fullBodyExercises = [
    const GymExercise(
      id: 'clean_and_jerk',
      nameAr: 'النتر والخطف',
      nameEn: 'Clean and Jerk',
      muscleGroup: MuscleGroup.fullBody,
      metValue: 7.0,
    ),
    const GymExercise(
      id: 'snatch',
      nameAr: 'الخطف',
      nameEn: 'Snatch',
      muscleGroup: MuscleGroup.fullBody,
      metValue: 7.5,
    ),
    const GymExercise(
      id: 'power_clean',
      nameAr: 'النتر القوي',
      nameEn: 'Power Clean',
      muscleGroup: MuscleGroup.fullBody,
      metValue: 7.0,
    ),
    const GymExercise(
      id: 'thruster',
      nameAr: 'ثراستر',
      nameEn: 'Thruster',
      muscleGroup: MuscleGroup.fullBody,
      metValue: 6.5,
    ),
    const GymExercise(
      id: 'manmaker',
      nameAr: 'مان ميكر',
      nameEn: 'Man Maker',
      muscleGroup: MuscleGroup.fullBody,
      metValue: 7.5,
    ),
    const GymExercise(
      id: 'bear_crawl',
      nameAr: 'زحف الدب',
      nameEn: 'Bear Crawl',
      muscleGroup: MuscleGroup.fullBody,
      metValue: 5.5,
    ),
  ];

  /// عدد التمارين الكلي
  static int get totalCount => allExercises.length;
}