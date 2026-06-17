// lib/services/advanced_symptom_analysis.dart

import 'package:vita/models/nutrition_model.dart';
import 'package:vita/models/medication_model.dart';
import 'package:vita/models/symptom_model.dart';
import 'package:vita/services/nutrition_api.dart';
import 'package:vita/services/medication_api.dart';
import 'package:vita/services/symptom_api.dart';
import 'package:vita/services/water_service.dart';
import 'package:vita/services/walking_api.dart';
import 'package:vita/services/weight_service.dart';
import 'package:vita/utils/nutrition_calculator.dart';

class AdvancedSymptomAnalysis {
  final UserNutritionData userData;
  final String symptomName;
  final String severity;

  AdvancedSymptomAnalysis({
    required this.userData,
    required this.symptomName,
    required this.severity,
  });

  Map<String, double> _getTargetMacros() {
    final targetCalories = userData.targetCalories > 0
        ? userData.targetCalories
        : 2000.0;
    final macros = NutritionCalculator.calculateMacros(
      calories: targetCalories,
      goal: userData.goal,
      diseases: userData.diseases,
    );
    return {
      'protein': macros['protein'] ?? 60.0,
      'carbs': macros['carbs'] ?? 250.0,
      'fat': macros['fat'] ?? 70.0,
    };
  }

  double get _targetProtein => _getTargetMacros()['protein'] ?? 60.0;
  double get _targetCarbs => _getTargetMacros()['carbs'] ?? 250.0;
  double get _targetFat => _getTargetMacros()['fat'] ?? 70.0;

  Future<Map<String, dynamic>> analyze() async {
    final Map<String, dynamic> result = {
      'analysis': '',
      'possible_causes': <String>[],
      'suggested_actions': <String>[],
      'warning_signs': <String>[],
      'food_recommendations': {},
      'lifestyle_factors': {},
      'nutritional_deficiencies': <String>[],
      'medication_effects': <String>[],
      'activity_factors': <String>[],
      'weight_factors': <String>[],
      'pattern_factors': <String>[],
    };

    final futures = <Future<void>>[
      _getFoodRecommendationsForSymptom().then((v) => result['food_recommendations'] = v),
      _analyzeNutrition().then((v) {
        result['nutritional_deficiencies'] = v['deficiencies'];
      }),
      _analyzeMedications().then((v) => result['medication_effects'] = v['effects']),
      _analyzeLifestyle().then((v) => result['lifestyle_factors'] = v),
      _analyzeActivity().then((v) => result['activity_factors'] = v),
      _analyzeWeight().then((v) => result['weight_factors'] = v),
      _analyzePattern().then((v) => result['pattern_factors'] = v),
    ];

    await Future.wait(futures);

    final symptomSpecificAnalysis = _getSymptomSpecificAnalysis();
    result['analysis'] = symptomSpecificAnalysis['analysis'];
    result['possible_causes'] = symptomSpecificAnalysis['causes'];
    result['suggested_actions'] = symptomSpecificAnalysis['actions'];
    result['warning_signs'] = symptomSpecificAnalysis['warningSigns'];

    // Merge activity factors into suggested actions
    final activityFactors = result['activity_factors'] as List<String>;
    if (activityFactors.isNotEmpty) {
      final actions = result['suggested_actions'] as List<String>;
      for (var factor in activityFactors) {
        if (!actions.contains(factor)) {
          actions.add(factor);
        }
      }
    }

    // Merge weight factors into possible causes
    final weightFactors = result['weight_factors'] as List<String>;
    if (weightFactors.isNotEmpty) {
      final causes = result['possible_causes'] as List<String>;
      for (var factor in weightFactors) {
        if (!causes.contains(factor)) {
          causes.add(factor);
        }
      }
    }

    // Merge pattern factors into warning signs
    final patternFactors = result['pattern_factors'] as List<String>;
    if (patternFactors.isNotEmpty) {
      final warningSigns = result['warning_signs'] as List<String>;
      for (var factor in patternFactors) {
        if (!warningSigns.contains(factor)) {
          warningSigns.add(factor);
        }
      }
    }

    return result;
  }

  Future<Map<String, dynamic>> _getFoodRecommendationsForSymptom() async {
    final Map<String, Map<String, dynamic>> foodRecommendationsDB = {
      'صداع': {
        'foods_to_eat': [
          'موز',
          'بطيخ',
          'زنجبيل',
          'شوفان',
          'لوز',
          'سبانخ',
          'سمك',
        ],
        'foods_to_avoid': [
          'أجبان قديمة',
          'لحوم مصنعة',
          'شوكولاتة',
          'كافيين',
          'أطعمة مالحة',
        ],
        'drinks_recommended': ['ماء', 'شاي زنجبيل', 'عصير بطيخ', 'شاي نعناع'],
        'drinks_to_avoid': ['قهوة', 'مشروبات غازية', 'كحول'],
        'general_tips':
            'تناول وجبات منتظمة وتجنب الجوع الطويل، اشرب كمية كافية من الماء',
      },
      'دوخة': {
        'foods_to_eat': ['زنجبيل', 'موز', 'بطاطس', 'عسل', 'شوفان', 'تفاح'],
        'foods_to_avoid': ['أطعمة مالحة', 'كافيين', 'كحول', 'أطعمة دهنية'],
        'drinks_recommended': [
          'شاي زنجبيل',
          'ماء جوز الهند',
          'عصير برتقال',
          'شاي نعناع',
        ],
        'drinks_to_avoid': ['قهوة', 'مشروبات غازية', 'كحول'],
        'general_tips':
            'تناول وجبات صغيرة متكررة، اشرب سوائل كافية، تجنب الوقوف المفاجئ',
      },
      'غثيان': {
        'foods_to_eat': [
          'زنجبيل',
          'موز',
          'تفاح',
          'أرز',
          'خبز محمص',
          'شوربة خضار',
        ],
        'foods_to_avoid': [
          'أطعمة دهنية',
          'أطعمة حارة',
          'أجبان',
          'لحوم مصنعة',
          'مقليات',
        ],
        'drinks_recommended': ['شاي زنجبيل', 'ماء', 'عصير تفاح', 'شاي نعناع'],
        'drinks_to_avoid': ['قهوة', 'عصائر حمضية', 'مشروبات غازية', 'كحول'],
        'general_tips':
            'تناول أطعمة خفيفة وسهلة الهضم، اشرب سوائل ببطء، تجنب الروائح القوية',
      },
      'تعب': {
        'foods_to_eat': [
          'موز',
          'تمر',
          'شوفان',
          'بيض',
          'عسل',
          'مكسرات',
          'سبانخ',
        ],
        'foods_to_avoid': [
          'أطعمة سكرية',
          'أطعمة مصنعة',
          'مقليات',
          'كافيين بكميات كبيرة',
        ],
        'drinks_recommended': ['ماء', 'عصير برتقال', 'حليب لوز', 'شاي أعشاب'],
        'drinks_to_avoid': ['مشروبات طاقة', 'قهوة بكثرة', 'كحول'],
        'general_tips':
            'تناول وجبات متوازنة، اشرب ماء كافياً، احصل على قسط كاف من النوم',
      },
      'إرهاق': {
        'foods_to_eat': [
          'موز',
          'تمر',
          'شوفان',
          'بيض',
          'عسل',
          'مكسرات',
          'سبانخ',
          'عدس',
        ],
        'foods_to_avoid': ['أطعمة سكرية', 'أطعمة مصنعة', 'مقليات', 'كافيين'],
        'drinks_recommended': ['ماء', 'عصير برتقال', 'حليب لوز', 'شاي أعشاب'],
        'drinks_to_avoid': ['مشروبات طاقة', 'قهوة', 'كحول'],
        'general_tips': 'تناول وجبات صغيرة متكررة، اشرب ماء، قلل من السكريات',
      },
      'ألم بطن': {
        'foods_to_eat': [
          'موز',
          'أرز',
          'تفاح',
          'خبز محمص',
          'شوربة جزر',
          'زنجبيل',
        ],
        'foods_to_avoid': [
          'أطعمة حارة',
          'أطعمة دهنية',
          'بقوليات',
          'مقليات',
          'ألبان',
          'مخللات',
        ],
        'drinks_recommended': [
          'شاي زنجبيل',
          'ماء دافئ',
          'شاي بابونج',
          'عصير تفاح',
        ],
        'drinks_to_avoid': ['قهوة', 'مشروبات غازية', 'عصائر حمضية', 'كحول'],
        'general_tips': 'تناول وجبات صغيرة، تجنب الأطعمة المسببة للغازات',
      },
      'إسهال': {
        'foods_to_eat': [
          'موز',
          'أرز',
          'تفاح',
          'خبز محمص',
          'شوربة جزر',
          'بطاطس مسلوقة',
        ],
        'foods_to_avoid': [
          'ألبان',
          'أطعمة دهنية',
          'بقوليات',
          'مقليات',
          'خضار نيئة',
        ],
        'drinks_recommended': [
          'ماء',
          'شاي بابونج',
          'عصير تفاح',
          'محلول معالجة الجفاف',
        ],
        'drinks_to_avoid': ['قهوة', 'عصائر حمضية', 'مشروبات غازية', 'كحول'],
        'general_tips': 'تجنب الجفاف بشرب السوائل، التزم بنظام BRAT الغذائي',
      },
      'إمساك': {
        'foods_to_eat': [
          'خوخ',
          'توت',
          'برتقال',
          'خضار ورقية',
          'شوفان',
          'بذور الكتان',
          'كمثرى',
          'كيوي',
        ],
        'foods_to_avoid': [
          'أطعمة مصنعة',
          'أجبان',
          'لحوم حمراء',
          'موز غير ناضج',
          'أرز أبيض',
        ],
        'drinks_recommended': ['ماء', 'عصير خوخ', 'عصير برتقال', 'شاي أخضر'],
        'drinks_to_avoid': ['قهوة بكثرة', 'مشروبات غازية', 'كحول'],
        'general_tips':
            'زد من الألياف تدريجياً، اشرب ماء كثيراً، مارس الرياضة يومياً',
      },
      'حرارة': {
        'foods_to_eat': [
          'شوربة خضار',
          'بطيخ',
          'برتقال',
          'زبادي',
          'عسل',
          'كيوي',
          'فراولة',
        ],
        'foods_to_avoid': [
          'أطعمة دهنية',
          'لحوم حمراء',
          'مقليات',
          'أطعمة مالحة',
          'أطعمة حارة',
        ],
        'drinks_recommended': [
          'ماء',
          'عصير برتقال',
          'شاي أعشاب',
          'عصير ليمون بعسل',
        ],
        'drinks_to_avoid': ['قهوة', 'مشروبات غازية', 'كحول'],
        'general_tips':
            'اشرب سوائل كثيرة، تناول أطعمة خفيفة، استشر طبيبك إذا استمرت الحرارة',
      },
      'ألم صدر': {
        'foods_to_eat': [
          'خضار ورقية',
          'أسماك دهنية',
          'زيت زيتون',
          'مكسرات',
          'شوفان',
          'توت',
          'رمان',
        ],
        'foods_to_avoid': [
          'أطعمة دهنية',
          'لحوم حمراء',
          'أطعمة مالحة',
          'مقليات',
          'حلويات',
        ],
        'drinks_recommended': ['ماء', 'شاي أخضر', 'عصير رمان', 'عصير توت'],
        'drinks_to_avoid': ['قهوة', 'مشروبات غازية', 'كحول'],
        'general_tips':
            '🚨 هذا عرض خطير، استشر الطبيب فوراً. تجنب الأطعمة التي تزيد الالتهاب',
      },
      'ضيق تنفس': {
        'foods_to_eat': [
          'زنجبيل',
          'ثوم',
          'بصل',
          'خضار ورقية',
          'سمك',
          'زيت زيتون',
          'كركم',
        ],
        'foods_to_avoid': [
          'ألبان',
          'أطعمة دهنية',
          'أطعمة مالحة',
          'لحوم مصنعة',
          'مقليات',
        ],
        'drinks_recommended': [
          'شاي زنجبيل',
          'ماء دافئ',
          'شاي أخضر',
          'عصير جزر',
        ],
        'drinks_to_avoid': ['قهوة', 'مشروبات غازية', 'كحول'],
        'general_tips':
            '🚨 هذا عرض خطير، استشر الطبيب فوراً. اجلس في وضعية مريحة',
      },
      'زغللة العين': {
        'foods_to_eat': [
          'جزر',
          'سبانخ',
          'توت',
          'برتقال',
          'لوز',
          'بيض',
          'بطاطا حلوة',
        ],
        'foods_to_avoid': [
          'أطعمة سكرية',
          'أطعمة مالحة',
          'أطعمة مصنعة',
          'كافيين بكثرة',
        ],
        'drinks_recommended': ['ماء', 'عصير جزر', 'شاي أخضر', 'عصير توت'],
        'drinks_to_avoid': ['قهوة', 'مشروبات غازية', 'كحول'],
        'general_tips':
            'إذا كانت الزغللة مفاجئة، هذا عرض خطير. قس ضغط الدم والسكر',
      },
      'تنميل الأطراف': {
        'foods_to_eat': [
          'موز',
          'بطاطس',
          'أفوكادو',
          'لوز',
          'سبانخ',
          'أسماك',
          'بيض',
          'عدس',
        ],
        'foods_to_avoid': [
          'أطعمة سكرية',
          'أطعمة مالحة',
          'كافيين بكثرة',
          'كحول',
          'أطعمة مصنعة',
        ],
        'drinks_recommended': [
          'ماء',
          'عصير برتقال',
          'حليب جوز الهند',
          'شاي أعشاب',
        ],
        'drinks_to_avoid': ['قهوة', 'مشروبات غازية', 'كحول'],
        'general_tips':
            'تناول أطعمة غنية بفيتامين B، اشرب ماء كافياً، استشر طبيب أعصاب',
      },
    };

    for (var entry in foodRecommendationsDB.entries) {
      if (symptomName.contains(entry.key) || entry.key.contains(symptomName)) {
        return entry.value;
      }
    }

    return {
      'foods_to_eat': ['خضروات', 'فواكه', 'بروتين صحي', 'حبوب كاملة'],
      'foods_to_avoid': ['أطعمة مصنعة', 'سكريات', 'دهون مشبعة'],
      'drinks_recommended': ['ماء', 'شاي أعشاب'],
      'drinks_to_avoid': ['مشروبات غازية', 'كحول'],
      'general_tips': 'حافظ على نظام غذائي متوازن، اشرب كمية كافية من الماء',
    };
  }

  Map<String, dynamic> _getSymptomSpecificAnalysis() {
    final analyses = {
      'صداع': {
        'analysis': 'الصداع قد يكون نتيجة للإجهاد، الجفاف، أو ارتفاع ضغط الدم.',
        'causes': [
          'الإجهاد والتعب',
          'الجفاف',
          'ارتفاع ضغط الدم',
          'الصداع النصفي',
          'إجهاد العين',
        ],
        'actions': [
          'قس ضغط الدم',
          'اشرب كمية كافية من الماء',
          'استرح في مكان هادئ ومظلم',
          'تجنب الشاشات',
        ],
        'warningSigns': [
          'إذا كان مصحوباً بزغللة',
          'إذا كان مفاجئاً وشديداً',
          'إذا صاحبه تيبس في الرقبة',
        ],
      },
      'دوخة': {
        'analysis':
            'الدوخة قد تكون بسبب انخفاض السكر، الجفاف، أو مشاكل في الأذن الداخلية.',
        'causes': [
          'انخفاض السكر',
          'الجفاف',
          'مشاكل الأذن الداخلية',
          'فقر الدم',
          'القلق والتوتر',
        ],
        'actions': [
          'قس السكر إذا كنت مريض سكري',
          'اشرب ماء',
          'اجلس أو استلق فوراً',
          'تناول وجبة خفيفة',
        ],
        'warningSigns': [
          'إذا كانت مصحوبة بإغماء',
          'إذا كانت مع كلام غير مفهوم',
          'إذا تكررت بشكل مفاجئ',
        ],
      },
      'غثيان': {
        'analysis':
            'الغثيان قد يكون بسبب اضطراب في المعدة، دوار الحركة، أو كأثر جانبي لدواء.',
        'causes': [
          'اضطراب في المعدة',
          'دوار الحركة',
          'أثر جانبي لدواء',
          'حمل (للنساء)',
          'تسمم غذائي',
        ],
        'actions': [
          'اشرب شاي زنجبيل',
          'تناول بسكويت مالح',
          'تجنب الروائح القوية',
          'خذ نفساً عميقاً',
        ],
        'warningSigns': [
          'إذا كان مصحوباً بألم شديد',
          'إذا استمر لأكثر من يوم',
          'إذا كان مع جفاف',
        ],
      },
      'تعب': {
        'analysis': 'التعب قد يكون بسبب نقص النوم، سوء التغذية، أو فقر الدم.',
        'causes': [
          'قلة النوم',
          'سوء التغذية',
          'فقر الدم',
          'قلة النشاط البدني',
          'الضغط النفسي',
        ],
        'actions': [
          'نم 7-8 ساعات',
          'تناول وجبة متوازنة',
          'اشرب ماء',
          'مارس رياضة خفيفة',
        ],
        'warningSigns': [
          'إذا كان مصحوباً بضيق تنفس',
          'إذا استمر لأكثر من أسبوعين',
          'إذا كان مع فقدان وزن',
        ],
      },
      'إرهاق': {
        'analysis':
            'الإرهاق قد يكون بسبب الإجهاد المزمن، سوء التغذية، أو مشاكل صحية كامنة.',
        'causes': [
          'الإجهاد المزمن',
          'سوء التغذية',
          'فقر الدم',
          'قصور الغدة الدرقية',
          'السكري',
        ],
        'actions': [
          'خذ قسطاً من الراحة',
          'تناول وجبات صغيرة متكررة',
          'اشرب ماء',
          'مارس التأمل',
        ],
        'warningSigns': [
          'إذا كان مصحوباً بألم صدر',
          'إذا استمر لأكثر من أسبوعين',
          'إذا كان مع ضيق تنفس',
        ],
      },
      'ألم بطن': {
        'analysis':
            'ألم البطن قد يكون بسبب عسر الهضم، الغازات، أو التهاب المعدة.',
        'causes': [
          'عسر الهضم',
          'الغازات',
          'التهاب المعدة',
          'إمساك',
          'قرحة المعدة',
        ],
        'actions': [
          'اشرب شاي نعناع دافئ',
          'تناول أطعمة خفيفة',
          'تجنب الأطعمة الحارة والدهنية',
          'استرح',
        ],
        'warningSigns': [
          'إذا كان الألم شديداً',
          'إذا كان مصحوباً بحمى',
          'إذا كان مع قيء مستمر',
        ],
      },
      'إسهال': {
        'analysis':
            'الإسهال قد يكون بسبب عدوى فيروسية، تسمم غذائي، أو كأثر جانبي لدواء.',
        'causes': [
          'عدوى فيروسية',
          'تسمم غذائي',
          'أثر جانبي لدواء',
          'مشاكل في القولون',
          'توتر',
        ],
        'actions': [
          'اشرب سوائل كثيرة',
          'تجنب الجفاف',
          'اتبع نظام BRAT',
          'استشر طبيبك إذا استمر',
        ],
        'warningSigns': [
          'إذا استمر لأكثر من 3 أيام',
          'إذا كان مع دم',
          'إذا كان مع حمى عالية',
        ],
      },
      'إمساك': {
        'analysis':
            'الإمساك قد يكون بسبب نقص الألياف، قلة شرب الماء، أو قلة الحركة.',
        'causes': [
          'نقص الألياف',
          'قلة شرب الماء',
          'قلة الحركة',
          'تأخر التبرز',
          'بعض الأدوية',
        ],
        'actions': [
          'زد من الألياف تدريجياً',
          'اشرب ماء كثيراً',
          'مارس الرياضة يومياً',
          'لا تؤجل التبرز',
        ],
        'warningSigns': [
          'إذا استمر لأكثر من 3 أسابيع',
          'إذا كان مع ألم شديد',
          'إذا كان مع نزيف',
        ],
      },
      'حرارة': {
        'analysis':
            'الحرارة قد تكون بسبب عدوى فيروسية أو بكتيرية، أو التهاب في الجسم.',
        'causes': [
          'عدوى فيروسية',
          'عدوى بكتيرية',
          'التهاب في الحلق',
          'عدوى المسالك البولية',
          'الإنفلونزا',
        ],
        'actions': [
          'اشرب سوائل كثيرة',
          'تناول خافض حرارة',
          'استرح',
          'استشر طبيبك إذا استمرت',
        ],
        'warningSigns': [
          'إذا كانت فوق 40°م',
          'إذا استمرت لأكثر من 3 أيام',
          'إذا كانت مع تيبس الرقبة',
        ],
      },
      'ألم صدر': {
        'analysis': '🚨 ألم الصدر عرض خطير قد يشير لمشكلة في القلب أو الرئتين.',
        'causes': [
          'مشكلة في القلب',
          'التهاب في الرئة',
          'القلق والتوتر',
          'مشكلة في المريء',
          'التهاب الغضروف',
        ],
        'actions': [
          'اتصل بالطوارئ فوراً',
          'لا تتحرك كثيراً',
          'اجلس في وضع مريح',
          'تناول الأسبرين إذا وصفه الطبيب',
        ],
        'warningSigns': [
          'إذا كان مع عرق غزير',
          'إذا كان مع ضيق تنفس',
          'إذا امتد إلى الذراع أو الفك',
        ],
      },
      'ضيق تنفس': {
        'analysis':
            '🚨 ضيق التنفس عرض خطير قد يشير لمشكلة في القلب أو الرئتين.',
        'causes': [
          'الربو',
          'التهاب الرئة',
          'مشكلة في القلب',
          'القلق والتوتر',
          'فقر الدم',
        ],
        'actions': [
          'اجلس في وضع مستقيم',
          'استخدم البخاخ إذا كان موجوداً',
          'اتصل بالطوارئ فوراً',
          'تنفس ببطء',
        ],
        'warningSigns': [
          'إذا كان مفاجئاً',
          'إذا كان مع ازرقاق الشفاه',
          'إذا كان مع ألم صدر',
        ],
      },
      'زغللة العين': {
        'analysis':
            'زغللة العين قد تكون بسبب ارتفاع أو انخفاض الضغط، أو مشكلة في العين.',
        'causes': [
          'ارتفاع ضغط الدم',
          'انخفاض السكر',
          'مشكلة في العين',
          'الصداع النصفي',
          'إجهاد العين',
        ],
        'actions': [
          'قس ضغط الدم',
          'قس السكر إذا كنت مريض سكري',
          'استرح',
          'استشر طبيب عيون',
        ],
        'warningSigns': [
          'إذا كانت مفاجئة',
          'إذا كانت مع صداع شديد',
          'إذا كانت مع ضعف في الكلام',
        ],
      },
      'تنميل الأطراف': {
        'analysis':
            'تنميل الأطراف قد يكون بسبب نقص فيتامين B، أو مشكلة في الأعصاب.',
        'causes': [
          'نقص فيتامين B12',
          'مشكلة في الأعصاب',
          'السكري',
          'نقص البوتاسيوم',
          'ضغط على العصب',
        ],
        'actions': [
          'تناول أطعمة غنية بفيتامين B',
          'اشرب ماء كافياً',
          'استشر طبيب أعصاب',
          'حرك الأطراف برفق',
        ],
        'warningSigns': [
          'إذا كان مفاجئاً',
          'إذا كان مع ضعف في الأطراف',
          'إذا كان مع صعوبة في الكلام',
        ],
      },
    };

    for (var entry in analyses.entries) {
      if (symptomName.contains(entry.key) || entry.key.contains(symptomName)) {
        final analysis = entry.value;
        return {
          'analysis': analysis['analysis'],
          'causes': analysis['causes'],
          'actions': analysis['actions'],
          'warningSigns': analysis['warningSigns'],
        };
      }
    }

    return {
      'analysis':
          'هذا العرض يحتاج متابعة. إذا استمر أو ازداد سوءاً، استشر طبيبك.',
      'causes': ['سبب غير محدد', 'يحتاج متابعة طبية', 'راجع الأعراض المصاحبة'],
      'actions': [
        'راقب الأعراض',
        'استشر طبيبك إذا استمرت',
        'خذ قسطاً من الراحة',
      ],
      'warningSigns': [
        'إذا تفاقمت الأعراض',
        'إذا ظهرت أعراض جديدة',
        'إذا استمر لأكثر من 3 أيام',
      ],
    };
  }

  /// ============================================
  /// 🏃 تحليل النشاط البدني وتأثيره على العرض
  /// ============================================
  Future<List<String>> _analyzeActivity() async {
    final activityFactors = <String>[];

    try {
      final walkingImpact = await WalkingService.calculateWalkingImpact();
      final impactPercentage = (walkingImpact['total_impact_percentage'] as num?)?.toDouble() ?? 0.0;
      final baseGoal = (walkingImpact['base_goal'] as num?)?.toDouble() ?? 8000;
      final adjustedGoal = (walkingImpact['adjusted_goal'] as num?)?.toDouble() ?? 8000;

      // Check if activity is significantly impacted
      if (impactPercentage > 20) {
        activityFactors.add(
          '⚠️ تأثير الأعراض على المشي: $impactPercentage% - قلل النشاط البدني مؤقتاً',
        );
      }

      // Get week activities to check step trend
      final weekActivities = await WalkingService.getWeekActivities();
      if (weekActivities.length >= 3) {
        final recentAvg = weekActivities
            .take(3)
            .map((a) => a.steps)
            .reduce((a, b) => a + b) / 3;
        final olderAvg = weekActivities
            .skip(weekActivities.length - 3)
            .map((a) => a.steps)
            .reduce((a, b) => a + b) / 3;

        final stepTrend = recentAvg - olderAvg;

        if (stepTrend < -1000 && recentAvg < baseGoal * 0.5) {
          activityFactors.add('⬇️ انخفاض حاد في النشاط البدني هذا الأسبوع');
          if (symptomName == 'تعب' || symptomName == 'إرهاق') {
            activityFactors.add(
              '🏃 قلة الحركة تؤدي لتفاقم التعب والإرهاق - ابدأ بمشي خفيف',
            );
          }
          if (symptomName == 'إمساك') {
            activityFactors.add(
              '🏃 قلة الحركة تزيد الإمساك - المشي 15 دقيقة يومياً يحسن الحركة',
            );
          }
        }

        if (adjustedGoal < baseGoal * 0.7) {
          activityFactors.add(
            '🎯 تم تعديل هدف المشي إلى $adjustedGoal خطوة (من $baseGoal) نظراً لحالتك الصحية',
          );
        }
      }

      // Check for symptom-specific activity links
      if (symptomName == 'صداع' && impactPercentage > 10) {
        activityFactors.add(
          '🤕 الصداع يؤثر على نشاطك بنسبة $impactPercentage% - خذ قسطاً من الراحة',
        );
      }
      if (symptomName == 'ضيق تنفس' && impactPercentage > 15) {
        activityFactors.add(
          '🫁 ضيق التنفس يحد من نشاطك - تجنب المجهود الزائد',
        );
      }
    } catch (e) {
      activityFactors.add('غير قادر على تحليل تأثير النشاط البدني حالياً');
    }

    return activityFactors;
  }

  /// ============================================
  /// ⚖️ تحليل تغيرات الوزن وتأثيرها على العرض
  /// ============================================
  Future<List<String>> _analyzeWeight() async {
    final weightFactors = <String>[];

    try {
      final weightStats = await WeightService.getWeightStats(days: 30);

      if (weightStats['success'] == true || weightStats.isNotEmpty) {
        final currentWeight = (weightStats['current_weight'] as num?)?.toDouble();
        final previousWeight = (weightStats['previous_weight'] as num?)?.toDouble();
        final bmi = (weightStats['bmi'] as num?)?.toDouble();
        final change30d = (weightStats['change_30d'] as num?)?.toDouble();
        final change7d = (weightStats['change_7d'] as num?)?.toDouble();

        // Rapid weight loss check
        if (change30d != null && change30d < -3.0) {
          weightFactors.add(
            '⚠️ فقدان وزن سريع (${change30d.toStringAsFixed(1)} كجم في 30 يوم) - قد يسبب دوخة وإرهاق',
          );
          if (symptomName == 'دوخة' || symptomName == 'تعب' || symptomName == 'إرهاق') {
            weightFactors.add(
              '⚡ فقدان الوزن السريع يستهلك طاقة الجسم - راجع نظامك الغذائي',
            );
          }
        }

        // Rapid weight gain check
        if (change30d != null && change30d > 2.0) {
          weightFactors.add(
            '⚠️ زيادة وزن سريعة (${change30d.toStringAsFixed(1)} كجم في 30 يوم)',
          );
          if (symptomName == 'ضيق تنفس' || symptomName == 'تعب') {
            weightFactors.add(
              '🫄 زيادة الوزن تزيد الضغط على الجهاز التنفسي والقلب',
            );
          }
        }

        // Recent fluctuation check (7 days)
        if (change7d != null && change7d.abs() > 1.0) {
          weightFactors.add(
            '📊 تذبذب في الوزن هذا الأسبوع (${change7d.toStringAsFixed(1).replaceAll('-', '')} كجم)',
          );
          if (symptomName == 'دوخة') {
            weightFactors.add(
              'مستوى السوائل المتذبذب قد يسبب الدوخة',
            );
          }
        }

        // BMI-related checks
        if (bmi != null) {
          if (bmi > 30) {
            weightFactors.add(
              '🟠 مؤشر كتلة الجسم مرتفع ($bmi) - السمنة تزيد خطر تفاقم الأعراض',
            );
            if (symptomName == 'ألم صدر' || symptomName == 'ضيق تنفس') {
              weightFactors.add(
                '❤️ السمنة تزيد الضغط على القلب - استشر طبيبك ببرنامج تخفيف وزن',
              );
            }
          } else if (bmi < 18.5) {
            weightFactors.add(
              '🟡 مؤشر كتلة الجسم منخفض ($bmi) - نقص الوزن قد يسبب ضعف عام',
            );
            if (symptomName == 'تعب' || symptomName == 'إرهاق') {
              weightFactors.add(
                '🥗 تحتاج لزيادة السعرات الحرارية والبروتين في نظامك الغذائي',
              );
            }
          }
        }

        // Link weight changes to specific symptoms
        if (currentWeight != null && previousWeight != null) {
          final weightDiff = currentWeight - previousWeight;
          if (symptomName == 'غثيان' && weightDiff < -1.0) {
            weightFactors.add(
              '🍽️ فقدان الوزن مع الغثيان يستدعي فحصاً طبياً',
            );
          }
          if (symptomName == 'تعب' && weightDiff.abs() > 2.0) {
            weightFactors.add(
              '📉 تغير الوزن الكبير ($weightDiff كجم) يستهلك طاقة الجسم ويسبب التعب',
            );
          }
        }
      }
    } catch (e) {
      weightFactors.add('غير قادر على تحليل تأثير الوزن حالياً');
    }

    return weightFactors;
  }

  /// ============================================
  /// 📈 تحليل نمط الأعراض (التكرار والتوزيع)
  /// ============================================
  Future<List<String>> _analyzePattern() async {
    final patternFactors = <String>[];

    try {
      final timelineData = await SymptomService.getSymptomsTimeline();

      if (timelineData['success'] == true && timelineData['timeline'] != null) {
        final timeline = timelineData['timeline'];
        if (timeline is Map<String, dynamic>) {
          _extractPatternFactors(timeline, patternFactors);
        } else if (timeline is List) {
          // Handle if timeline comes as a list
          final totalSymptoms = timeline.length;
          if (totalSymptoms > 10) {
            patternFactors.add(
              '⚠️ لديك $totalSymptoms عرض مسجل - يُوصى باستشارة طبية شاملة',
            );
          }
        }
      }

      // Get recent symptoms to check frequency
      final recentSymptoms = await SymptomService.getSymptoms(limit: 20);
      if (recentSymptoms.length >= 3) {
        final matchingSymptoms = recentSymptoms.where(
          (s) => s.name.contains(symptomName) || symptomName.contains(s.name),
        ).toList();

        // Check frequency
        if (matchingSymptoms.length >= 5) {
          patternFactors.add(
            '🔄 تكرار $symptomName بشكل ملحوظ (${matchingSymptoms.length} مرة) - يُوصى بتتبع الأعراض',
          );
          if (matchingSymptoms.length >= 10) {
            patternFactors.add(
              '🚨 تكرار عالي جداً - قد يشير لحالة مزمنة تحتاج متابعة طبية',
            );
          }
        }

        // Check severity escalation
        final severeCount = matchingSymptoms.where(
          (s) => s.severity == 'شديد' || s.severity == 'severe',
        ).length;
        if (severeCount >= 2) {
          patternFactors.add(
            '📈 تطور في شدة $symptomName - ظهرت حالات شديدة $severeCount مرات',
          );
        }

        // Check if recently worsened
        if (matchingSymptoms.length >= 3) {
          final sorted = List<Symptom>.from(matchingSymptoms)
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
          final latest = sorted.first;
          final earliest = sorted.last;
          final daysDiff = latest.dateTime.difference(earliest.dateTime).inDays;

          if (daysDiff > 0 && daysDiff <= 7) {
            patternFactors.add(
              '⏰ ظهر $symptomName في آخر $daysDiff أيام - تتبع الأعراض مهم',
            );
          }
        }
      }

      // Check for time-of-day patterns (if available via timeline)
      if (patternFactors.isEmpty && timelineData['success'] == true) {
        patternFactors.add('لا يوجد نمط واضح لتكرار الأعراض بعد');
      }
    } catch (e) {
      patternFactors.add('غير قادر على تحليل نمط الأعراض حالياً');
    }

    return patternFactors;
  }

  /// استخراج عوامل النمط من بيانات التوقيت
  void _extractPatternFactors(Map<String, dynamic> timeline, List<String> factors) {
    final frequent = timeline['most_frequent'];
    if (frequent is List && frequent.isNotEmpty) {
      final matching = frequent.where(
        (f) => f.toString().contains(symptomName) || symptomName.contains(f.toString()),
      ).toList();
      if (matching.isNotEmpty) {
        factors.add(
          '📊 $symptomName من الأعراض المتكررة لديك',
        );
      }
    }

    // Check severity distribution
    final severityDist = timeline['severity_distribution'];
    if (severityDist is Map<String, dynamic>) {
      final severeCount = (severityDist['severe'] ?? severityDist['شديد'] ?? 0) as num;
      if (severeCount > 0 && severeCount.toInt() >= 2) {
        factors.add(
          '🔥 تكررت الحالات الشديدة ${severeCount.toInt()} مرات',
        );
      }
    }

    // Check total and period
    final total = (timeline['total_symptoms'] ?? 0) as num;
    final period = (timeline['period_days'] ?? 30) as num;
    if (total > 0 && period > 0) {
      final rate = total.toDouble() / period.toDouble();
      if (rate > 1.0) {
        factors.add(
          '📈 معدل ظهور أعراض مرتفع (${rate.toStringAsFixed(1)} عرض/يوم)',
        );
      }
    }

    // Check for symptom clusters (multiple symptoms on same day)
    if (total > 0 && period > 0 && total / period > 0.5) {
      factors.add(
        '🔄 ظهور أعراض متعددة بشكل متقارب - قد تشير لحالة صحية واحدة',
      );
    }
  }

  Future<Map<String, dynamic>> _analyzeNutrition() async {
    final lastWeekMeals = await _getLastWeekMeals();
    final deficiencies = <String>[];
    final recommendations = <String, dynamic>{};

    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int daysWithMeals = 0;

    for (var meal in lastWeekMeals) {
      if (meal['total_protein'] != null) {
        totalProtein += (meal['total_protein'] as num).toDouble();
        totalCarbs += (meal['total_carbs'] as num).toDouble();
        totalFat += (meal['total_fat'] as num).toDouble();
        daysWithMeals++;
      }
    }

    if (daysWithMeals > 0) {
      final avgProtein = totalProtein / daysWithMeals;
      final avgCarbs = totalCarbs / daysWithMeals;
      final avgFat = totalFat / daysWithMeals;

      if (avgProtein < _targetProtein * 0.7) {
        deficiencies.add('نقص البروتين في النظام الغذائي');
        recommendations['protein'] = [
          '🍗 أضف مصادر بروتين: دجاج، سمك، بيض، بقوليات',
          '🥚 تناول البيض في الفطور',
          '🥛 أضف زبادي يوناني أو حليب',
        ];
      }

      if (avgCarbs < _targetCarbs * 0.6) {
        deficiencies.add('انخفاض الكربوهيدرات - قد يسبب تعب وإرهاق');
        recommendations['carbs'] = [
          '🍚 تناول كربوهيدرات معقدة: شوفان، أرز بني، بطاطا حلوة',
          '🌾 أضف الحبوب الكاملة لوجباتك',
        ];
      } else if (avgCarbs > _targetCarbs * 1.3) {
        deficiencies.add('ارتفاع الكربوهيدرات - قد يسبب خمول وزيادة وزن');
        recommendations['carbs_reduce'] = [
          '🍚 قلل من النشويات وزد الخضروات',
          '🥗 استبدل الأرز الأبيض بالخضار',
        ];
      }

      if (avgFat > _targetFat * 1.2) {
        deficiencies.add('ارتفاع الدهون - قد يسبب عسر هضم وغثيان');
        recommendations['fat_reduce'] = [
          '🥑 قلل من الدهون المشبعة والمقلية',
          '🍳 اختر طهي صحي (شوي - سلق) بدل القلي',
        ];
      }

      final foods = await _getRecentFoods();
      if (foods.contains('كافيين') || foods.contains('قهوة')) {
        if (symptomName == 'صداع' || symptomName == 'دوخة') {
          deficiencies.add('استهلاك كافيين مرتفع قد يسبب الصداع والدوخة');
          recommendations['caffeine'] = [
            '☕ قلل من القهوة والشاي، استبدلها بشاي أعشاب',
          ];
        }
      }

      if (foods.contains('سكريات') || foods.contains('حلويات')) {
        if (symptomName == 'تعب' || symptomName == 'إرهاق') {
          deficiencies.add('السكريات تسبب انهيار الطاقة والتعب');
          recommendations['sugar'] = ['🍎 استبدل الحلويات بالفواكه الطازجة'];
        }
      }
    }

    return {'deficiencies': deficiencies, 'recommendations': recommendations};
  }

  Future<List<Map<String, dynamic>>> _getLastWeekMeals() async {
    final meals = <Map<String, dynamic>>[];
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayMeals = await NutritionService.getMealsByDate(date);
      if (dayMeals != null) {
        meals.add(dayMeals);
      }
    }
    return meals;
  }

  Future<Set<String>> _getRecentFoods() async {
    final foods = <String>{};
    final lastWeekMeals = await _getLastWeekMeals();

    for (var day in lastWeekMeals) {
      final dayMeals = day['meals'] as List? ?? [];
      for (var meal in dayMeals) {
        final mealFoods = meal['foods'] as List? ?? [];
        for (var food in mealFoods) {
          final foodName = (food['name'] ?? '').toString().toLowerCase();
          if (foodName.contains('قهوة')) foods.add('كافيين');
          if (foodName.contains('شاي')) foods.add('كافيين');
          if (foodName.contains('حلو') || foodName.contains('سكر'))
            foods.add('سكريات');
          if (foodName.contains('مقلي') || foodName.contains('زيت'))
            foods.add('دهون');
        }
      }
    }
    return foods;
  }

  Future<Map<String, dynamic>> _analyzeMedications() async {
    final medications = await MedicationService.getMedications();
    final effects = <String>[];

    for (var med in medications) {
      final impact = await SymptomService.getMedicineImpact(
        med.medicineId ?? 0,
      );
      if (impact['success'] && impact['side_effects'] != null) {
        final sideEffects = List<String>.from(impact['side_effects']);
        for (var effect in sideEffects) {
          if (effect.contains(symptomName) || symptomName.contains(effect)) {
            effects.add('⚠️ ${med.name} قد يسبب $symptomName كأثر جانبي');
          }
        }
      }
    }

    return {'effects': effects};
  }

  Future<Map<String, dynamic>> _analyzeLifestyle() async {
    final lifestyle = <String, dynamic>{};

    final waterData = await WaterService.getTodayWater();
    final waterIntake = (waterData?['total'] ?? 0.0).toDouble();
    final waterGoal = (waterData?['daily_goal'] ?? 2.5).toDouble();

    if (waterIntake < waterGoal * 0.5) {
      lifestyle['water_deficiency'] =
          'كمية الماء قليلة جداً (شربت $waterIntake من $waterGoal لتر)';
      if (symptomName == 'صداع' ||
          symptomName == 'دوخة' ||
          symptomName == 'تعب') {
        lifestyle['water_effect'] = '⚠️ قلة الماء قد تسبب $symptomName';
      }
    }

    return lifestyle;
  }
}
