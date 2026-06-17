// lib/screens/quiz/daily_quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/services/quiz_service.dart';
import 'package:vita/models/quiz_models.dart';
import 'package:vita/constants/colors.dart';

class DailyQuizScreen extends StatefulWidget {
  final QuizTimeOfDay timeOfDay;

  const DailyQuizScreen({super.key, required this.timeOfDay});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  List<DailyQuizQuestion> _questions = [];
  Map<int, int> _answers = {}; // question_id -> option_id
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _notes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // ✅ التحقق من الوقت قبل تحميل الأسئلة
    if (!_isTimeValid()) {
      _showTimeExpiredAndClose();
      return;
    }

    _loadQuestions();
  }

  // ✅ التحقق من صحة الوقت
  bool _isTimeValid() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    if (widget.timeOfDay == QuizTimeOfDay.morning) {
      // كويز الصباح: متاح فقط قبل 12:00 ظهراً
      return currentHour < 12 || (currentHour == 12 && currentMinute == 0);
    } else {
      // كويز المساء: متاح فقط قبل 12:00 منتصف الليل
      return currentHour < 23 || (currentHour == 23 && currentMinute <= 59);
    }
  }

  // ✅ عرض رسالة وإغلاق الصفحة إذا انتهى الوقت
  void _showTimeExpiredAndClose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.timer_off, color: Colors.red),
              const SizedBox(width: 12),
              Text(
                'انتهى وقت ${widget.timeOfDay == QuizTimeOfDay.morning ? 'كويز الصباح' : 'كويز المساء'}',
              ),
            ],
          ),
          content: const Text(
            'انتهت المهلة المحددة للإجابة على هذا الكويز. يمكنك المشاركة في الكويز في موعده غداً.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // إغلاق الـ Dialog
                Navigator.pop(context); // إغلاق الصفحة
              },
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final timeOfDayStr = widget.timeOfDay == QuizTimeOfDay.morning
          ? 'morning'
          : widget.timeOfDay == QuizTimeOfDay.evening
          ? 'evening'
          : null;

      final questions = await QuizService.getDailyQuestions(
        timeOfDay: timeOfDayStr,
      );

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading daily questions: $e');
      setState(() {
        _errorMessage = 'فشل في تحميل الأسئلة: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى الإجابة على جميع الأسئلة'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final timeOfDayStr = widget.timeOfDay == QuizTimeOfDay.morning
          ? 'morning'
          : 'evening';

      final session = await QuizService.submitDailyQuiz(
        timeOfDay: timeOfDayStr,
        answers: _answers,
        notes: _notes,
      );

      if (session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ كويز ${widget.timeOfDay == QuizTimeOfDay.morning ? 'الصباح' : 'المساء'} بنجاح',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, session);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في حفظ الكويز'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildQuestionCard(DailyQuizQuestion question, int index) {
    final selectedOptionId = _answers[question.id];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    'سؤال ${index + 1}',
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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getCategoryLabel(question.category),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // نص السؤال
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // الخيارات
            ...question.options.map((option) {
              final isSelected = selectedOptionId == option.id;
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
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade200,
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
                                  : Colors.grey.shade400,
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
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade800,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              fontSize: 14,
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

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'sleep':
        return '😴 النوم';
      case 'mood':
        return '😊 المزاج';
      case 'energy':
        return '⚡ الطاقة';
      case 'nutrition':
        return '🍎 التغذية';
      case 'activity':
        return '🏃 النشاط';
      case 'planning':
        return '📋 التخطيط';
      case 'health':
        return '🩺 الصحة';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeOfDayLabel = widget.timeOfDay == QuizTimeOfDay.morning
        ? 'الصباح'
        : widget.timeOfDay == QuizTimeOfDay.evening
        ? 'المساء'
        : 'اليوم';

    final timeOfDayIcon = widget.timeOfDay == QuizTimeOfDay.morning
        ? '🌅'
        : widget.timeOfDay == QuizTimeOfDay.evening
        ? '🌙'
        : '⏰';

    final progressPercent = _questions.isEmpty
        ? 0
        : ((_answers.length / _questions.length) * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(timeOfDayIcon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'كويز $timeOfDayLabel',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (_answers.isNotEmpty && !_isSubmitting)
            TextButton(
              onPressed: _submitQuiz,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'حفظ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadQuestions,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // شريط التقدم
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
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
                            Text(
                              'كويز $timeOfDayLabel',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_answers.length} من ${_questions.length} أسئلة تمت الإجابة عليها',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
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

                // الأسئلة
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      return _buildQuestionCard(_questions[index], index);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إضافة ملاحظات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'أضف ملاحظاتك هنا...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (value) {
                      _notes = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم حفظ الملاحظات'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('حفظ'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.note_add),
        label: const Text('ملاحظات'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
