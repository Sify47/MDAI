// lib/screens/quiz/daily_quiz_dashboard.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vita/services/quiz_service.dart';
import 'package:vita/models/quiz_models.dart';
import 'daily_quiz_screen.dart';

class DailyQuizDashboard extends StatefulWidget {
  const DailyQuizDashboard({super.key});

  @override
  State<DailyQuizDashboard> createState() => _DailyQuizDashboardState();
}

class _DailyQuizDashboardState extends State<DailyQuizDashboard> {
  DailyQuizStatus? _todayStatus;
  List<DailyQuizStatus> _weeklyStatus = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ⏰ إعدادات وقت الكويز
  static const TimeOfDay _morningQuizDeadline = TimeOfDay(
    hour: 12,
    minute: 0,
  ); // 12:00 PM
  static const TimeOfDay _eveningQuizDeadline = TimeOfDay(
    hour: 23,
    minute: 59,
  ); // 11:59 PM

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _todayStatus = await QuizService.getTodayQuizStatus();
      _weeklyStatus = await QuizService.getWeeklyQuizStatus();
    } catch (e) {
      print('❌ [Bug4] خطأ في تحميل بيانات الكويز: $e');
      if (mounted) {
        setState(() {
          _errorMessage =
              'تعذر تحميل بيانات الكويز اليومي. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ التحقق من وقت الكويز - هل مازال متاحاً؟
  bool _isQuizTimeAvailable(QuizTimeOfDay timeOfDay) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentTime = TimeOfDay(hour: currentHour, minute: currentMinute);

    if (timeOfDay == QuizTimeOfDay.morning) {
      // كويز الصباح متاح فقط قبل 12:00 ظهراً
      return currentTime.hour < _morningQuizDeadline.hour ||
          (currentTime.hour == _morningQuizDeadline.hour &&
              currentTime.minute < _morningQuizDeadline.minute);
    } else {
      // كويز المساء متاح فقط قبل 11:59 مساءً
      return currentTime.hour < _eveningQuizDeadline.hour ||
          (currentTime.hour == _eveningQuizDeadline.hour &&
              currentTime.minute < _eveningQuizDeadline.minute);
    }
  }

  // ✅ الحصول على وقت انتهاء الكويز
  String _getDeadlineTime(QuizTimeOfDay timeOfDay) {
    if (timeOfDay == QuizTimeOfDay.morning) {
      return '12:00 ظهراً';
    } else {
      return '12:00 منتصف الليل';
    }
  }

  // ✅ الحصول على الوقت المتبقي للكويز
  String _getRemainingTime(QuizTimeOfDay timeOfDay) {
    final now = DateTime.now();
    DateTime deadline;

    if (timeOfDay == QuizTimeOfDay.morning) {
      deadline = DateTime(now.year, now.month, now.day, 12, 0);
    } else {
      deadline = DateTime(now.year, now.month, now.day, 23, 59);
    }

    if (now.isAfter(deadline)) {
      return 'انتهى الوقت';
    }

    final difference = deadline.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return 'متبقي $hours ساعة و $minutes دقيقة';
    } else if (minutes > 0) {
      return 'متبقي $minutes دقيقة';
    } else {
      return 'ينتهي قريباً';
    }
  }

  // ✅ الحصول على لون حالة الكويز
  Color _getQuizStatusColor(QuizTimeOfDay timeOfDay, bool isCompleted) {
    if (isCompleted) return Colors.green;

    final isAvailable = _isQuizTimeAvailable(timeOfDay);
    if (isAvailable) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  // ✅ الحصول على نص حالة الكويز
  String _getQuizStatusText(QuizTimeOfDay timeOfDay, bool isCompleted) {
    if (isCompleted) return 'مكتمل ✓';

    final isAvailable = _isQuizTimeAvailable(timeOfDay);
    if (isAvailable) {
      return 'متاح';
    } else {
      return 'انتهى الوقت';
    }
  }

  Widget _buildTodayCard() {
    if (_todayStatus == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'كويز اليوم',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('EEEE, d MMMM', 'ar').format(DateTime.now()),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // صباح
            _buildTimeOfDayCard(
              icon: '🌅',
              title: 'كويز الصباح',
              isCompleted: _todayStatus!.morningCompleted,
              completedAt: _todayStatus!.morningCompletedAt,
              score: _todayStatus!.morningScore,
              timeOfDay: QuizTimeOfDay.morning,
            ),
            const SizedBox(height: 16),
            // مساء
            _buildTimeOfDayCard(
              icon: '🌙',
              title: 'كويز المساء',
              isCompleted: _todayStatus!.eveningCompleted,
              completedAt: _todayStatus!.eveningCompletedAt,
              score: _todayStatus!.eveningScore,
              timeOfDay: QuizTimeOfDay.evening,
            ),
            const SizedBox(height: 20),
            // شريط التقدم
            LinearProgressIndicator(
              value: _todayStatus!.completionPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              color: _todayStatus!.isFullyCompleted
                  ? Colors.green
                  : _todayStatus!.isPartiallyCompleted
                  ? Colors.orange
                  : Colors.blue,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_todayStatus!.completionPercentage.toInt()}% مكتمل',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  _todayStatus!.isFullyCompleted
                      ? '🎉 مكتمل اليوم'
                      : _todayStatus!.isPartiallyCompleted
                      ? '🚧 قيد الإكمال'
                      : '⏳ لم يبدأ بعد',
                  style: TextStyle(
                    fontSize: 12,
                    color: _todayStatus!.isFullyCompleted
                        ? Colors.green
                        : _todayStatus!.isPartiallyCompleted
                        ? Colors.orange
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeOfDayCard({
    required String icon,
    required String title,
    required bool isCompleted,
    required DateTime? completedAt,
    required int? score,
    required QuizTimeOfDay timeOfDay,
  }) {
    final isAvailable = _isQuizTimeAvailable(timeOfDay);
    final canStart = !isCompleted && isAvailable;
    final statusColor = _getQuizStatusColor(timeOfDay, isCompleted);
    final statusText = _getQuizStatusText(timeOfDay, isCompleted);
    final remainingTime = _getRemainingTime(timeOfDay);
    final deadlineTime = _getDeadlineTime(timeOfDay);

    return GestureDetector(
      onTap: () {
        if (canStart) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DailyQuizScreen(timeOfDay: timeOfDay),
            ),
          ).then((_) => _loadData());
        } else if (!isCompleted && !isAvailable) {
          _showTimeExpiredDialog(timeOfDay);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (isCompleted && completedAt != null)
                    Text(
                      'مكتمل ${DateFormat('h:mm a', 'ar').format(completedAt)}',
                      style: TextStyle(fontSize: 12, color: statusColor),
                    )
                  else if (!isCompleted && isAvailable)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⏰ $remainingTime',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'ينتهي في $deadlineTime',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    )
                  else if (!isCompleted && !isAvailable)
                    Text(
                      '⌛ انتهت مهلة الإجابة - عاود غداً',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (isCompleted && score != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (canStart)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ابدأ الآن',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'منتهي',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ عرض رسالة عند انتهاء الوقت
  void _showTimeExpiredDialog(QuizTimeOfDay timeOfDay) {
    final quizName = timeOfDay == QuizTimeOfDay.morning
        ? 'كويز الصباح'
        : 'كويز المساء';
    final deadlineTime = _getDeadlineTime(timeOfDay);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.timer_off, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text('انتهى وقت $quizName'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.access_time, size: 40, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              'انتهت مهلة الإجابة على $quizName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'آخر موعد للإجابة كان $deadlineTime',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك الإجابة على الكويز في موعده غداً',
              style: TextStyle(color: Colors.blue.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyStatus.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الأداء الأسبوعي',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('آخر 7 أيام', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _weeklyStatus.length,
                itemBuilder: (context, index) {
                  final status = _weeklyStatus[index];
                  final dayName = DateFormat('E', 'ar').format(status.date);
                  final dayNumber = DateFormat('d').format(status.date);

                  return Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // شريط الصباح
                        Container(
                          width: 20,
                          height: status.morningCompleted ? 60 : 20,
                          decoration: BoxDecoration(
                            color: status.morningCompleted
                                ? Colors.blue.shade400
                                : Colors.grey.shade300,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // شريط المساء
                        Container(
                          width: 20,
                          height: status.eveningCompleted ? 60 : 20,
                          decoration: BoxDecoration(
                            color: status.eveningCompleted
                                ? Colors.green.shade400
                                : Colors.grey.shade300,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dayNumber,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('صباح'),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('مساء'),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('غير مكتمل'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final completedDays = _weeklyStatus
        .where((status) => status.isFullyCompleted)
        .length;

    final totalScore = _weeklyStatus.fold<int>(0, (sum, status) {
      return sum + status.morningScore + status.eveningScore;
    });

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              value: completedDays.toString(),
              label: 'أيام مكتملة',
              icon: '📅',
              color: Colors.blue,
            ),
            _buildStatItem(
              value: totalScore.toString(),
              label: 'مجموع النقاط',
              icon: '⭐',
              color: Colors.amber,
            ),
            _buildStatItem(
              value: _weeklyStatus.length.toString(),
              label: 'أيام متابعة',
              icon: '📊',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required String icon,
    required Color color,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كويز الصباح والمساء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
          // ✅ إضافة معلومات الوقت
          PopupMenuButton(
            tooltip: 'معلومات عن أوقات الكويز',
            icon: const Icon(Icons.info_outline),
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny, size: 18),
                    SizedBox(width: 8),
                    Text('كويز الصباح: حتى 12:00 ظهراً'),
                  ],
                ),
              ),
              const PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.nightlight_round, size: 18),
                    SizedBox(width: 8),
                    Text('كويز المساء: حتى 12:00 منتصف الليل'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                children: [
                  _buildTodayCard(),
                  _buildStatsCard(),
                  _buildWeeklyChart(),
                  const SizedBox(height: 20),
                  _buildInfoSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ✅ قسم المعلومات والنصائح
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⏰ كويز الصباح متاح حتى الساعة 12:00 ظهراً\n🌙 كويز المساء متاح حتى الساعة 12:00 منتصف الليل',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '💡 نصائح للاستفادة القصوى:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTipItem(
            '✅',
            'أجب على كويز الصباح بعد الاستيقاظ مباشرة - متاح حتى الظهر',
          ),
          _buildTipItem(
            '✅',
            'أجب على كويز المساء قبل النوم - متاح حتى منتصف الليل',
          ),
          _buildTipItem('✅', 'كن صادقاً في إجاباتك للحصول على تحليل دقيق'),
          _buildTipItem('✅', 'راجع تحليلاتك الأسبوعية لتحسين عاداتك'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}
