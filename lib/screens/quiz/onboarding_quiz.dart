// lib/screens/quiz/onboarding_quiz.dart

import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../../constants/colors.dart';
import '../../services/quiz_service.dart';
import '../../models/quiz_models.dart';
import '../../utils/prefs_helper.dart';
import 'quiz_results_screen.dart';

class OnboardingQuiz extends StatefulWidget {
  const OnboardingQuiz({Key? key}) : super(key: key);

  @override
  State<OnboardingQuiz> createState() => _OnboardingQuizState();
}

class _OnboardingQuizState extends State<OnboardingQuiz>
    with TickerProviderStateMixin {
  List<QuizQuestion> _questions = [];
  Map<int, int> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  int _currentPage = 0;
  int _questionsPerPage = 5; // 5 أسئلة في كل صفحة (أسهل للعرض)

  final Map<String, Map<String, dynamic>> _categories = {
    'sleep': {'name': 'النوم', 'icon': '😴', 'color': const Color(0xFF6C5CE7)},
    'nutrition': {
      'name': 'التغذية',
      'icon': '🍎',
      'color': const Color(0xFF00B894),
    },
    'activity': {
      'name': 'النشاط البدني',
      'icon': '🏃',
      'color': const Color(0xFFE17055),
    },
    'mental': {
      'name': 'الصحة النفسية',
      'icon': '🧠',
      'color': const Color(0xFFA29BFE),
    },
    'physical': {
      'name': 'الأعراض الجسدية',
      'icon': '🤕',
      'color': const Color(0xFFFDCB6E),
    },
    'habits': {
      'name': 'العادات اليومية',
      'icon': '📱',
      'color': const Color(0xFF74B9FF),
    },
    'social': {
      'name': 'الصحة الاجتماعية',
      'icon': '👥',
      'color': const Color(0xFF55EFC4),
    },
    'medication': {
      'name': 'الأدوية',
      'icon': '💊',
      'color': const Color(0xFFFD79A8),
    },
    'environment': {
      'name': 'البيئة',
      'icon': '🌍',
      'color': const Color(0xFF0984E3),
    },
  };

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final questions = await QuizService.getQuestions();

    if (questions.isNotEmpty) {
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'فشل في تحميل الأسئلة';
        _isLoading = false;
      });
    }
  }

  // حساب عدد الصفحات
  int get _totalPages {
    if (_questions.isEmpty) return 0;
    return (_questions.length / _questionsPerPage).ceil();
  }

  // الحصول على أسئلة الصفحة الحالية
  List<QuizQuestion> get _currentPageQuestions {
    final startIndex = _currentPage * _questionsPerPage;
    final endIndex = (startIndex + _questionsPerPage) > _questions.length
        ? _questions.length
        : startIndex + _questionsPerPage;

    if (startIndex >= _questions.length) return [];
    return _questions.sublist(startIndex, endIndex);
  }

  // التحقق من اكتمال الصفحة الحالية
  bool get _isCurrentPageComplete {
    for (var question in _currentPageQuestions) {
      if (!_answers.containsKey(question.id)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submitQuiz() async {
    if (_answers.length < _questions.length) {
      _showError('⚠️ الرجاء الإجابة على جميع الأسئلة');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final answerList = _answers.entries.map((entry) {
      return QuizAnswerSubmit(
        questionId: entry.key,
        selectedOptionId: entry.value,
      );
    }).toList();

    final result = await QuizService.submitQuiz(
      answers: answerList,
      isOnboarding: true,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (result != null) {
      if (!mounted) return;

      final analysis = await QuizService.analyzeQuiz();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              QuizResultsScreen(
                sessionId: result.id,
                totalScore: result.totalScore,
                categoryScores: result.categoryScores,
                isOnboarding: true,
                analysis: analysis,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        ),
      );
    } else {
      _showError('❌ حدث خطأ أثناء حفظ الإجابات');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _nextPage() {
    if (!_isCurrentPageComplete) {
      _showError('⚠️ الرجاء الإجابة على جميع الأسئلة قبل المتابعة');
      return;
    }

    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final answeredCount = _answers.length;
    final totalCount = _questions.length;
    final progressPercent = totalCount > 0
        ? (answeredCount / totalCount * 100).toInt()
        : 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Text(
                'تقييم نمط الحياة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$answeredCount / $totalCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'جاري تحميل الأسئلة...',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadQuestions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // شريط التقدم
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تقييم نمط الحياة',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'الصفحة ${_currentPage + 1} من $_totalPages',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$answeredCount من $totalCount أسئلة',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            '$progressPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // مؤشر الصفحات (نقاط)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (index) {
                        bool isActive = index == _currentPage;
                        bool isCompleted = _isPageComplete(index);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.success
                                  : isActive
                                  ? AppColors.primary
                                  : isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // الأسئلة
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _currentPageQuestions.length,
                      itemBuilder: (context, index) {
                        final question = _currentPageQuestions[index];
                        final absoluteIndex =
                            (_currentPage * _questionsPerPage) + index + 1;
                        return _buildQuestionCard(
                          question,
                          absoluteIndex,
                          isDark,
                        );
                      },
                    ),
                  ),

                  // أزرار التنقل
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          if (_currentPage > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _previousPage,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.grey[600]!
                                        : Colors.grey[400]!,
                                  ),
                                ),
                                child: const Text('السابق'),
                              ),
                            ),
                          if (_currentPage > 0) const SizedBox(width: 12),
                          Expanded(
                            flex: _currentPage == 0 ? 2 : 1,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _currentPage == _totalPages - 1
                                          ? '✨ إرسال'
                                          : 'التالي',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // التحقق من اكتمال صفحة معينة
  bool _isPageComplete(int pageIndex) {
    final startIndex = pageIndex * _questionsPerPage;
    final endIndex = (startIndex + _questionsPerPage) > _questions.length
        ? _questions.length
        : startIndex + _questionsPerPage;

    for (int i = startIndex; i < endIndex; i++) {
      if (!_answers.containsKey(_questions[i].id)) {
        return false;
      }
    }
    return true;
  }

  Widget _buildQuestionCard(
    QuizQuestion question,
    int questionNumber,
    bool isDark,
  ) {
    final categoryInfo =
        _categories[question.category] ??
        {'name': question.category, 'icon': '📋', 'color': AppColors.primary};
    final selectedId = _answers[question.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رقم السؤال والفئة
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'سؤال $questionNumber',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (categoryInfo['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        categoryInfo['icon'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        categoryInfo['name'],
                        style: TextStyle(
                          color: categoryInfo['color'],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // نص السؤال
            Text(
              question.questionText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 16),

            // الخيارات
            ...question.options.map((option) {
              final isSelected = selectedId == option.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _answers[question.id] = option.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.08)
                          : isDark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : isDark
                            ? Colors.grey[700]!
                            : Colors.grey[200]!,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio button مخصص
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : isDark
                                  ? Colors.grey[500]!
                                  : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.optionText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
