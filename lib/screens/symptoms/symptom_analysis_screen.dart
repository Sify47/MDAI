// lib/screens/symptoms/symptom_analysis_screen.dart

import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

class SymptomAnalysisScreen extends StatelessWidget {
  final Map<String, dynamic> symptomData;
  final VoidCallback? onSave;

  const SymptomAnalysisScreen({
    Key? key,
    required this.symptomData,
    this.onSave,
  }) : super(key: key);

  Color _getSeverityColor(String severity, ThemeData theme) {
    switch (severity) {
      case 'خفيف':
        return AppColors.success;
      case 'متوسط':
        return AppColors.warning;
      case 'شديد':
        return AppColors.danger;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  Map<String, dynamic>? _getFoodRecommendations() {
    return symptomData['food_recommendations'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final severityColor = _getSeverityColor(
      symptomData['severity'] ?? 'متوسط',
      theme,
    );
    final foodRecs = _getFoodRecommendations();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          title: Text('🔍 تحليل العرض'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSymptomCard(theme, severityColor),
                const SizedBox(height: 16),
                _buildSeverityIndicator(theme, severityColor),
                const SizedBox(height: 16),
                _buildAnalysis(theme),
                const SizedBox(height: 16),
                _buildPossibleCauses(theme),
                const SizedBox(height: 16),
                _buildActions(theme),
                const SizedBox(height: 16),
                if (foodRecs != null) ...[
                  _buildFoodRecommendations(foodRecs, theme),
                  const SizedBox(height: 16),
                ],
                _buildWarningSigns(theme),
                const SizedBox(height: 16),
                _buildActionButtons(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomCard(ThemeData theme, Color severityColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                symptomData['icon'] ?? '🤒',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symptomData['symptom'] ?? 'عرض غير محدد',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${symptomData['date']} • ${symptomData['time']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityIndicator(ThemeData theme, Color severityColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            symptomData['severity'] == 'شديد' ? Icons.warning : Icons.info,
            color: severityColor,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'درجة الخطورة: ${symptomData['severity']}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSeverityDescription(symptomData['severity']),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSeverityDescription(String severity) {
    switch (severity) {
      case 'خفيف':
        return 'يمكنك متابعة الأعراض في المنزل مع الراحة';
      case 'متوسط':
        return 'يجب مراقبة الأعراض واستشارة الطبيب إذا استمرت';
      case 'شديد':
        return 'يجب استشارة الطبيب فوراً أو التوجه للطوارئ';
      default:
        return '';
    }
  }

  Widget _buildAnalysis(ThemeData theme) {
    final analysis =
        symptomData['analysis'] ?? _getAnalysisText(symptomData['symptom']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'التحليل المبدئي',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  /// 🧠 قاعدة بيانات الأعراض — مرجع موحد لجميع المعلومات
  static const Map<String, Map<String, dynamic>> _symptomKnowledgeBase = {
    'صداع': {
      'analysis':
          'الصداع قد يكون نتيجة لعدة أسباب منها الإجهاد، الجفاف، أو ارتفاع ضغط الدم. إذا كان مصحوباً بزغللة أو دوخة، قد يشير لارتفاع الضغط.',
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
          'الدوخة قد تكون بسبب انخفاض السكر، الجفاف، أو مشاكل في الأذن الداخلية. إذا كانت مصحوبة بطنين أو فقدان توازن، قد تشير لمشكلة في الأذن.',
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
      'analysis':
          '🚨 ألم الصدر عرض خطير قد يشير لمشكلة في القلب أو الرئتين. يجب التوجه للطوارئ فوراً خاصة إذا كان مصحوباً بعرق غزير أو ضيق تنفس.',
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
      'analysis': '🚨 ضيق التنفس عرض خطير قد يشير لمشكلة في القلب أو الرئتين.',
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

  /// 🔍 بحث مرن — يطابق العرض بالاسم الكامل أو الجزئي
  static Map<String, dynamic>? _lookupSymptom(String symptom) {
    // مطابقة كاملة
    if (_symptomKnowledgeBase.containsKey(symptom)) {
      return _symptomKnowledgeBase[symptom];
    }
    // مطابقة جزئية (العرض يحتوي على المفتاح أو المفتاح يحتوي على العرض)
    for (var entry in _symptomKnowledgeBase.entries) {
      if (symptom.contains(entry.key) || entry.key.contains(symptom)) {
        return entry.value;
      }
    }
    return null;
  }

  String _getAnalysisText(String symptom) {
    final data = _lookupSymptom(symptom);
    if (data != null) {
      return data['analysis'] as String;
    }
    return 'هذا العرض يحتاج متابعة. إذا استمر أو ازداد سوءاً، استشر طبيبك.';
  }

  Widget _buildPossibleCauses(ThemeData theme) {
    List<String> causes = symptomData['possible_causes'] is List
        ? List<String>.from(symptomData['possible_causes'])
        : _getPossibleCauses(symptomData['symptom']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'الأسباب المحتملة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...causes.map(
            (cause) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(cause, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getPossibleCauses(String symptom) {
    final data = _lookupSymptom(symptom);
    if (data != null) {
      return List<String>.from(data['causes']);
    }
    return [
      'يحتاج متابعة طبية',
      'راجع الأعراض المصاحبة',
      'استشر طبيبك إذا استمر',
    ];
  }

  Widget _buildActions(ThemeData theme) {
    List<String> actions = symptomData['suggested_actions'] is List
        ? List<String>.from(symptomData['suggested_actions'])
        : _getSuggestedActions(symptomData['symptom']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'التصرف المقترح',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...actions.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.value, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSuggestedActions(String symptom) {
    final data = _lookupSymptom(symptom);
    if (data != null) {
      return List<String>.from(data['actions']);
    }
    return ['راقب الأعراض', 'استشر طبيبك إذا استمرت', 'خذ قسطاً من الراحة'];
  }

  Widget _buildFoodRecommendations(
    Map<String, dynamic> foodRecs,
    ThemeData theme,
  ) {
    final foodsToEat = foodRecs['foods_to_eat'] as List? ?? [];
    final foodsToAvoid = foodRecs['foods_to_avoid'] as List? ?? [];
    final drinksRecommended = foodRecs['drinks_recommended'] as List? ?? [];
    final drinksToAvoid = foodRecs['drinks_to_avoid'] as List? ?? [];
    final generalTips = foodRecs['general_tips'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.05),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                '🍽️ توصيات غذائية',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (foodsToEat.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'أطعمة مفيدة:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: foodsToEat.map((food) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    food.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (foodsToAvoid.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'أطعمة ممنوعة:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: foodsToAvoid.map((food) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    food.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.danger,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (drinksRecommended.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_drink,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'مشروبات مفيدة:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: drinksRecommended.map((drink) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    drink.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (drinksToAvoid.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'مشروبات ممنوعة:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: drinksToAvoid.map((drink) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    drink.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: AppColors.danger,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (generalTips != null && generalTips.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      generalTips,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarningSigns(ThemeData theme) {
    List<String> warningSigns = symptomData['warning_signs'] is List
        ? List<String>.from(symptomData['warning_signs'])
        : _getDefaultWarningSigns();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                'علامات الخطر',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'إذا صاحب الأعراض أي من العلامات التالية، توجه للطوارئ فوراً:',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...warningSigns.map(
            (sign) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.circle, color: AppColors.danger, size: 8),
                  const SizedBox(width: 10),
                  Expanded(child: Text(sign, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getDefaultWarningSigns() {
    final data = _lookupSymptom(symptomData['symptom'] ?? '');
    if (data != null) {
      return List<String>.from(data['warningSigns']);
    }
    return [
      'صعوبة في التنفس',
      'ألم في الصدر',
      'فقدان الوعي',
      'نزيف غير طبيعي',
      'ارتفاع شديد في الحرارة',
    ];
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              if (onSave != null) {
                onSave!();
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              } else {
                Navigator.pop(context, null);
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('حفظ في السجل'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('📤 جاري تجهيز المشاركة...'),
                  backgroundColor: theme.colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('مشاركة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
