import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../models/medication_model.dart';
import '../../../services/medication_api.dart';

class MedicationStatisticsScreen extends StatefulWidget {
  final List<UserMedication> medications;

  const MedicationStatisticsScreen({super.key, required this.medications});

  @override
  State<MedicationStatisticsScreen> createState() =>
      _MedicationStatisticsScreenState();
}

class _MedicationStatisticsScreenState extends State<MedicationStatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _selectedPeriod = 'أسبوع'; // أسبوع, شهر, سنة
  List<MedicationDose> _allDoses = [];
  bool _isLoading = true;
  String? _errorMessage;

  // إحصائيات محسوبة
  int _totalDoses = 0;
  int _takenDoses = 0;
  int _missedDoses = 0;
  int _pendingDoses = 0;
  double _adherenceRate = 0.0;

  // بيانات الرسم البياني
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
    _loadDosesData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // تحميل بيانات الجرعات
  Future<void> _loadDosesData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final doses = await MedicationService.getAllDoses();

      if (!mounted) return;

      setState(() {
        _allDoses = doses;
        _calculateStatistics();
        _prepareChartData();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'فشل في تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  // حساب الإحصائيات
  void _calculateStatistics() {
    _totalDoses = _allDoses.length;
    _takenDoses = _allDoses.where((d) => d.status == 'taken').length;
    _missedDoses = _allDoses.where((d) => d.status == 'missed').length;
    _pendingDoses = _allDoses.where((d) => d.status == 'pending').length;
    _adherenceRate = _totalDoses > 0 ? _takenDoses / _totalDoses : 0;
  }

  // تحضير بيانات الرسم البياني حسب الفترة
  void _prepareChartData() {
    final now = DateTime.now();
    List<Map<String, dynamic>> data = [];

    switch (_selectedPeriod) {
      case 'أسبوع':
        // آخر 7 أيام
        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final dayDoses = _allDoses.where(
            (d) =>
                d.scheduledTime.year == day.year &&
                d.scheduledTime.month == day.month &&
                d.scheduledTime.day == day.day,
          );

          int total = dayDoses.length;
          int taken = dayDoses.where((d) => d.status == 'taken').length;
          double rate = total > 0 ? taken / total : 0;

          data.add({
            'label': _getDayName(day.weekday),
            'rate': rate,
            'total': total,
            'taken': taken,
          });
        }
        break;

      case 'شهر':
        // آخر 4 أسابيع
        for (int i = 3; i >= 0; i--) {
          final weekStart = now.subtract(Duration(days: i * 7 + 6));
          final weekEnd = now.subtract(Duration(days: i * 7));

          final weekDoses = _allDoses.where(
            (d) =>
                d.scheduledTime.isAfter(weekStart) &&
                d.scheduledTime.isBefore(weekEnd),
          );

          int total = weekDoses.length;
          int taken = weekDoses.where((d) => d.status == 'taken').length;
          double rate = total > 0 ? taken / total : 0;

          data.add({
            'label': 'أسبوع ${4 - i}',
            'rate': rate,
            'total': total,
            'taken': taken,
          });
        }
        break;

      case 'سنة':
        // آخر 12 شهر
        for (int i = 11; i >= 0; i--) {
          final month = now.month - i;
          final year = now.year + (month <= 0 ? -1 : 0);
          final monthIndex = month <= 0 ? month + 12 : month;

          final monthDoses = _allDoses.where(
            (d) =>
                d.scheduledTime.year == year &&
                d.scheduledTime.month == monthIndex,
          );

          int total = monthDoses.length;
          int taken = monthDoses.where((d) => d.status == 'taken').length;
          double rate = total > 0 ? taken / total : 0;

          data.add({
            'label': _getMonthName(monthIndex),
            'rate': rate,
            'total': total,
            'taken': taken,
          });
        }
        break;
    }

    _chartData = data;
  }

  String _getDayName(int weekday) {
    const days = [
      '',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[weekday];
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return months[month];
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
          title: Text('📊 إحصائيات الأدوية'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              onPressed: _loadDosesData,
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? _buildLoading(theme)
              : _errorMessage != null
              ? _buildError(theme)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPeriodSelector(theme),
                        const SizedBox(height: 16),
                        _buildMainStatsCard(theme),
                        const SizedBox(height: 16),
                        _buildWeeklyChart(theme),
                        const SizedBox(height: 16),
                        _buildMedicationBreakdown(theme),
                        const SizedBox(height: 16),
                        _buildPerformanceAnalysis(theme),
                        const SizedBox(height: 16),
                        _buildImprovementTips(theme),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الإحصائيات...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDosesData,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // اختيار الفترة
  Widget _buildPeriodSelector(ThemeData theme) {
    final periods = ['أسبوع', 'شهر', 'سنة'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(40),
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
        children: periods.map((period) {
          bool isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  _prepareChartData();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // بطاقة الإحصائيات الرئيسية
  Widget _buildMainStatsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.medications, theme.colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.medications.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'معدل الالتزام العام',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            '${(_adherenceRate * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMainStatItem('إجمالي', '$_totalDoses', theme),
              _buildMainStatItem('تم', '$_takenDoses', theme),
              _buildMainStatItem('فات', '$_missedDoses', theme),
              _buildMainStatItem('متبقي', '$_pendingDoses', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  // رسم بياني للالتزام
  Widget _buildWeeklyChart(ThemeData theme) {
    if (_chartData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'لا توجد بيانات كافية',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

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
          Text(
            'الالتزام ($_selectedPeriod)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_chartData.length, (index) {
                final data = _chartData[index];
                final rate = data['rate'] as double;
                final maxHeight = 150.0;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // شريط الرسم البياني
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: rate * maxHeight),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, height, child) {
                          return Container(
                            height: height,
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.medications,
                                  theme.colorScheme.primary,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // اليوم
                      Text(
                        data['label'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      // النسبة المئوية
                      Text(
                        '${(rate * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      // عدد الجرعات
                      Text(
                        '${data['taken']}/${data['total']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // تفصيل أداء كل دواء
  Widget _buildMedicationBreakdown(ThemeData theme) {
    if (widget.medications.isEmpty) {
      return const SizedBox();
    }

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
          Text(
            'أداء كل دواء',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.medications.map((med) {
            final medDoses = _allDoses
                .where((d) => d.medicationId == med.id)
                .toList();
            final medTotal = medDoses.length;
            final medTaken = medDoses.where((d) => d.status == 'taken').length;
            final medRate = medTotal > 0 ? medTaken / medTotal : 0.0;
            final rateColor = medRate > 0.8
                ? AppColors.success
                : medRate > 0.5
                ? AppColors.warning
                : AppColors.danger;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getColorFromHex(
                            med.color,
                            theme,
                          ).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            med.icon,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: medRate.clamp(0.0, 1.0),
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  rateColor,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: rateColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(medRate * 100).round()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: rateColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getColorFromHex(String? hexColor, ThemeData theme) {
    if (hexColor == null) return AppColors.medications;
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('0xFF$hexColor'));
    } else if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    }
    return AppColors.medications;
  }

  // تحليل الأداء
  Map<String, dynamic> _calculatePerformanceMetrics() {
    final dosesByHour = <int, List<MedicationDose>>{};
    for (var dose in _allDoses) {
      final hour = dose.scheduledTime.hour;
      dosesByHour.putIfAbsent(hour, () => []);
      dosesByHour[hour]!.add(dose);
    }

    String bestTime = 'غير متوفر';
    double bestRate = 0;

    dosesByHour.forEach((hour, doses) {
      final taken = doses.where((d) => d.status == 'taken').length;
      final rate = taken / doses.length;
      if (rate > bestRate) {
        bestRate = rate;
        bestTime = '$hour:00';
      }
    });

    String worstTime = 'غير متوفر';
    double worstRate = 1;

    dosesByHour.forEach((hour, doses) {
      if (doses.length > 5) {
        final taken = doses.where((d) => d.status == 'taken').length;
        final rate = taken / doses.length;
        if (rate < worstRate) {
          worstRate = rate;
          worstTime = '$hour:00';
        }
      }
    });

    return {
      'bestTime': bestTime,
      'bestRate': bestRate,
      'worstTime': worstTime,
      'worstRate': worstRate,
    };
  }

  Widget _buildPerformanceAnalysis(ThemeData theme) {
    final metrics = _calculatePerformanceMetrics();
    final bestTime = metrics['bestTime'] as String;
    final bestRate = metrics['bestRate'] as double;
    final worstTime = metrics['worstTime'] as String;
    final worstRate = metrics['worstRate'] as double;

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
          Text(
            'تحليل الأداء',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalysisItem(
            'أفضل وقت',
            bestTime,
            'التزام ${(bestRate * 100).round()}%',
            AppColors.success,
            theme,
          ),
          _buildAnalysisItem(
            'أسوأ وقت',
            worstTime,
            'التزام ${(worstRate * 100).round()}%',
            AppColors.warning,
            theme,
          ),
          _buildAnalysisItem(
            'الأوقات الأكثر نسياناً',
            'جرعة المساء',
            'فاتت $_missedDoses جرعة',
            AppColors.danger,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(
    String label,
    String value,
    String detail,
    Color color,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // نصائح لتحسين الالتزام
  Widget _buildImprovementTips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            AppColors.medications.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'لتحسين التزامك',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_adherenceRate < 0.7)
            _buildTipItem('⚠️', 'نسبة التزامك منخفضة، حاول تحسينها', theme),
          _buildTipItem('📱', 'استخدم المنبه لتذكر مواعيد الأدوية', theme),
          _buildTipItem('🏠', 'ضع الدواء في مكان واضح', theme),
          _buildTipItem('👨‍👩‍👧', 'اطلب من أحد أفراد العائلة تذكيرك', theme),
        ],
      ),
    );
  }

  Widget _buildTipItem(String icon, String tip, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
