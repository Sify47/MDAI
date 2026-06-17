// lib/screens/weight_tracking_screen.dart

// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../services/weight_service.dart';
import '../services/integration/weight_influencers_service.dart';
import '../widgets/integration/weight_influencers_card.dart';
import '../constants/colors.dart';
import '../utils/prefs_helper.dart';

class WeightTrackingScreen extends StatefulWidget {
  const WeightTrackingScreen({super.key});

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedPeriod = 'week';
  Map<String, dynamic>? _progressData;
  Map<String, dynamic>? _statsData;
  Map<String, dynamic>? _predictionData;
  List<Map<String, dynamic>> _weightHistory = [];
  WeightAnalysisResult? _weightAnalysisResult;
  bool _weightAnalysisLoading = false;
  bool _isLoading = true;
  bool _isLogging = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy', 'ar');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _loadAllData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadProgress(),
      _loadStats(),
      _loadPrediction(),
      _loadHistory(),
      _loadWeightInfluencers(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadProgress() async {
    try {
      final result = await WeightService.getWeightProgress(
        period: _selectedPeriod,
      );
      if (result['success'] == true && mounted) {
        setState(() => _progressData = result);
      }
    } catch (e) {
      debugPrint('⚠️ WeightTracking: فشل تحميل التقدم - $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final result = await WeightService.getWeightStats(days: 30);
      if (mounted) setState(() => _statsData = result);
    } catch (e) {
      debugPrint('⚠️ WeightTracking: فشل تحميل الإحصائيات - $e');
    }
  }

  Future<void> _loadPrediction() async {
    try {
      final userData = PrefsHelper.getUserData();
      final goal = userData['goal'] ?? 'تخسيس';
      final result = await WeightService.predictWeight(
        weeksAhead: 4,
        goal: goal,
      );
      if (result['success'] == true && mounted) {
        setState(() => _predictionData = result);
      }
    } catch (e) {
      debugPrint('⚠️ WeightTracking: فشل تحميل التوقع - $e');
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await WeightService.getWeightHistory(limit: 30);
      if (mounted) setState(() => _weightHistory = history);
    } catch (e) {
      debugPrint('⚠️ WeightTracking: فشل تحميل التاريخ - $e');
    }
  }

  Future<void> _loadWeightInfluencers() async {
    setState(() => _weightAnalysisLoading = true);
    try {
      final result = await WeightInfluencersService.analyze();
      if (mounted) setState(() => _weightAnalysisResult = result);
    } catch (e) {
      debugPrint('⚠️ WeightTracking: فشل تحليل مؤثرات الوزن - $e');
    } finally {
      if (mounted) setState(() => _weightAnalysisLoading = false);
    }
  }

  Future<void> _logWeight() async {
    if (_weightController.text.isEmpty) return;
    setState(() => _isLogging = true);
    try {
      final weight = double.parse(_weightController.text);
      final notes = _notesController.text;
      final result = await WeightService.logWeight(
        weight: weight,
        date: DateTime.now(),
        notes: notes,
      );
      if (result['success'] == true && mounted) {
        _weightController.clear();
        _notesController.clear();
        await _loadAllData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('✅ تم تسجيل الوزن ${weight.toStringAsFixed(1)} كجم'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'حدث خطأ'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  Future<void> _deleteWeightEntry(int id, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف السجل'),
        content: const Text('هل أنت متأكد من حذف هذا السجل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await WeightService.deleteWeightEntry(id);
    if (result['success'] == true && mounted) {
      setState(() => _weightHistory.removeAt(index));
      await _loadAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ تم حذف السجل'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _changePeriod(String period) {
    if (_selectedPeriod == period) return;
    setState(() => _selectedPeriod = period);
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text(
          '📊 تتبع الوزن',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(height: 16),
                      _buildWeightChart(),
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                      const SizedBox(height: 20),
                      if (_weightAnalysisResult != null)
                        _buildWeightInfluencersSection(),
                      const SizedBox(height: 20),
                      _buildPredictionCard(),
                      const SizedBox(height: 20),
                      _buildQuickLogCard(),
                      const SizedBox(height: 20),
                      _buildHistoryList(),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogWeightDialog,
        child: const Icon(Icons.add),
        tooltip: 'تسجيل وزن',
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPeriodButton('أسبوع', 'week'),
          _buildPeriodButton('شهر', 'month'),
          _buildPeriodButton('3 أشهر', 'quarter'),
          _buildPeriodButton('سنة', 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changePeriod(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final shimmerHighlight = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    return Shimmer.fromColors(
      baseColor: shimmerBase,
      highlightColor: shimmerHighlight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: List.generate(
                4,
                (index) => Expanded(
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    final theme = Theme.of(context);
    final entries = _weightHistory.toList();
    entries.sort((a, b) {
      final dateA = DateTime.tryParse(a['date']?.toString() ?? '');
      final dateB = DateTime.tryParse(b['date']?.toString() ?? '');
      return dateA?.compareTo(dateB ?? DateTime.now()) ?? 0;
    });

    final now = DateTime.now();
    DateTime startDate;
    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'quarter':
        startDate = now.subtract(const Duration(days: 90));
        break;
      default:
        startDate = now.subtract(const Duration(days: 365));
    }

    final filteredEntries = entries.where((entry) {
      final date = DateTime.tryParse(entry['date']?.toString() ?? '');
      return date != null && date.isAfter(startDate);
    }).toList();

    if (filteredEntries.isEmpty) {
      return _buildEmptyChartCard(theme);
    }

    final chartData = <FlSpot>[];
    for (int i = 0; i < filteredEntries.length; i++) {
      final weight = (filteredEntries[i]['weight'] as num?)?.toDouble() ?? 0;
      chartData.add(FlSpot(i.toDouble(), weight));
    }

    final weights = chartData.map((e) => e.y).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.15;
    final minY = (minWeight - padding).clamp(minWeight - 2, minWeight - 0.5);
    final maxY = maxWeight + padding;

    final firstWeight = (filteredEntries.first['weight'] as num?)?.toDouble() ?? 0;
    final lastWeight = (filteredEntries.last['weight'] as num?)?.toDouble() ?? 0;
    final change = lastWeight - firstWeight;
    final isLoss = change < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.trending_up,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقدم الوزن',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      '${_displayDateFormat.format(DateTime.tryParse(filteredEntries.first['date']?.toString() ?? '') ?? DateTime.now())} - ${_displayDateFormat.format(DateTime.tryParse(filteredEntries.last['date']?.toString() ?? '') ?? DateTime.now())}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isLoss ? AppColors.success : AppColors.danger)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isLoss
                      ? '📉 ${change.abs().toStringAsFixed(1)} كجم'
                      : '📈 +${change.toStringAsFixed(1)} كجم',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isLoss ? AppColors.success : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildWeightStatsRow(theme, lastWeight, minWeight, maxWeight),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: (maxY - minY) / 5,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: filteredEntries.length > 10
                          ? (filteredEntries.length / 5)
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= filteredEntries.length)
                          return const SizedBox();
                        final date = DateTime.tryParse(
                          filteredEntries[index]['date']?.toString() ?? '',
                        );
                        if (date == null) return const SizedBox();
                        String label = _selectedPeriod == 'week'
                            ? [
                                'الأحد',
                                'الإثنين',
                                'الثلاثاء',
                                'الأربعاء',
                                'الخميس',
                                'الجمعة',
                                'السبت',
                              ][date.weekday % 7]
                            : '${date.day}/${date.month}';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Transform.rotate(
                            angle: filteredEntries.length > 10 ? -0.3 : 0,
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: filteredEntries.length > 10 ? 8 : 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (filteredEntries.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: index == 0 || index == chartData.length - 1
                                ? 6
                                : 4,
                            color: index == 0
                                ? AppColors.warning
                                : AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      final index = spot.spotIndex;
                      if (index < 0 || index >= filteredEntries.length)
                        return const LineTooltipItem('', TextStyle());
                      final entry = filteredEntries[index];
                      final date =
                          DateTime.tryParse(entry['date']?.toString() ?? '') ??
                          DateTime.now();
                      final notes = entry['notes']?.toString() ?? '';
                      return LineTooltipItem(
                        '${_displayDateFormat.format(date)}\n${spot.y.toStringAsFixed(1)} كجم${notes.isNotEmpty ? '\n📝 $notes' : ''}',
                        TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                    tooltipBorder: BorderSide(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات كافية',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بتسجيل وزنك لعرض التقدم',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showLogWeightDialog,
            icon: const Icon(Icons.add),
            label: const Text('تسجيل وزن الآن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStatsRow(
    ThemeData theme,
    double lastWeight,
    double minWeight,
    double maxWeight,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWeightStat(
            theme,
            'الوزن الحالي',
            lastWeight,
            AppColors.primary,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildWeightStat(theme, 'أقل وزن', minWeight, AppColors.success),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildWeightStat(theme, 'أعلى وزن', maxWeight, AppColors.danger),
        ],
      ),
    );
  }

  Widget _buildWeightStat(
    ThemeData theme,
    String label,
    double value,
    Color color,
  ) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text('كجم', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildStatsRow() {
    final theme = Theme.of(context);
    if (_statsData == null || _statsData!['success'] != true) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'الإحصائيات غير متوفرة',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final avgWeight = (_statsData!['avg_weight'] as num?)?.toDouble() ?? 0;
    final minWeight = (_statsData!['min_weight'] as num?)?.toDouble() ?? 0;
    final maxWeight = (_statsData!['max_weight'] as num?)?.toDouble() ?? 0;
    final totalLogs = _statsData!['total_logs'] ?? 0;

    return Row(
      children: [
        _buildStatItem(
          'المتوسط',
          avgWeight.toStringAsFixed(1),
          'كجم',
          Icons.balance,
          AppColors.primary,
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          'الأقل',
          minWeight.toStringAsFixed(1),
          'كجم',
          Icons.arrow_downward,
          AppColors.success,
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          'الأعلى',
          maxWeight.toStringAsFixed(1),
          'كجم',
          Icons.arrow_upward,
          AppColors.danger,
        ),
        const SizedBox(width: 8),
        _buildStatItem(
          'عدد',
          totalLogs.toString(),
          'تسجيل',
          Icons.list,
          AppColors.info,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightInfluencersSection() {
    if (_weightAnalysisLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_weightAnalysisResult == null) return const SizedBox();
    return WeightInfluencersCard(
      result: _weightAnalysisResult!,
      isAnimated: true,
    );
  }

  Widget _buildPredictionCard() {
    final theme = Theme.of(context);
    if (_predictionData == null || _predictionData!['success'] != true) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.auto_graph, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'توقع الوزن غير متاح حالياً',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'سجل وزنك بانتظام لمدة أسبوع على الأقل',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final userData = PrefsHelper.getUserData();
    final isGainGoal = (userData['goal'] ?? 'تخسيس') == 'زيادة';
    final currentWeight =
        (_predictionData!['current_weight'] as num?)?.toDouble() ?? 0;
    final predictedWeight =
        (_predictionData!['predicted_weight'] as num?)?.toDouble() ?? 0;
    final confidence =
        (_predictionData!['confidence'] as num?)?.toDouble() ?? 0;

    double displayPredictedWeight = predictedWeight;
    String trendMessage = "";
    if (isGainGoal && predictedWeight <= currentWeight) {
      displayPredictedWeight = currentWeight + 0.5;
      trendMessage = "⚠️ لتحقيق هدف الزيادة، تحتاج إلى زيادة سعراتك";
    } else if (!isGainGoal && predictedWeight >= currentWeight) {
      displayPredictedWeight = currentWeight - 0.5;
      trendMessage = "⚠️ لتحقيق هدف التخسيس، تحتاج إلى تقليل سعراتك";
    }

    final willIncrease = displayPredictedWeight > currentWeight;
    final change = (displayPredictedWeight - currentWeight).abs();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_graph,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'توقع الوزن',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (confidence > 0)
                      Text(
                        'دقة التوقع: ${(confidence * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'بعد 4 أسابيع',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (trendMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 18, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trendMessage,
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPredictionItem(
                'الوزن الحالي',
                currentWeight.toStringAsFixed(1),
                'كجم',
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (willIncrease ? AppColors.danger : AppColors.success)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  willIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                  color: willIncrease ? AppColors.danger : AppColors.success,
                  size: 24,
                ),
              ),
              _buildPredictionItem(
                'الوزن المتوقع',
                displayPredictedWeight.toStringAsFixed(1),
                'كجم',
                willIncrease ? AppColors.danger : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 18, color: AppColors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'التغير المتوقع: ${change.abs().toStringAsFixed(1)} كجم ${willIncrease ? 'زيادة' : 'خسارة'} خلال 4 أسابيع',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionItem(
    String label,
    String value,
    String unit, [
    Color? color,
  ]) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.primary,
          ),
        ),
        Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildQuickLogCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.monitor_weight, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تسجيل سريع',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'أدخل وزنك الحالي',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _weightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'الوزن',
                suffixText: 'كجم',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLogging ? null : _logWeight,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: _isLogging
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('تسجيل'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final theme = Theme.of(context);
    if (_weightHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد سجلات وزن بعد',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final recentEntries = _weightHistory.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.history,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'آخر التسجيلات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentEntries.length,
            separatorBuilder: (_, __) => const Divider(height: 12),
            itemBuilder: (context, index) {
              final entry = recentEntries[index];
              final weightId = entry['id'] as int? ?? 0;
              final weight = (entry['weight'] as num?)?.toDouble() ?? 0;
              final date =
                  DateTime.tryParse(entry['date']?.toString() ?? '') ??
                  DateTime.now();
              final notes = entry['notes']?.toString() ?? '';
              return Dismissible(
                key: Key('weight_$weightId'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async => await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف السجل'),
                    content: Text('هل تريد حذف سجل الوزن $weight كجم؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                ),
                onDismissed: (_) => _deleteWeightEntry(
                  weightId,
                  _weightHistory.indexWhere((e) => e['id'] == weightId),
                ),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: AppColors.danger),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.monitor_weight,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${weight.toStringAsFixed(1)} كجم',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (notes.isNotEmpty)
                              Text(
                                notes,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        _displayDateFormat.format(date),
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLogWeightDialog() {
    _weightController.clear();
    _notesController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'تسجيل وزن جديد',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'سجل وزنك الحالي لمتابعة التقدم',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'الوزن (كجم)',
                    hintText: 'أدخل وزنك الحالي',
                    prefixIcon: const Icon(Icons.monitor_weight),
                    suffixText: 'كجم',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    hintText: 'أي ملاحظات إضافية',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLogging
                        ? null
                        : () {
                            Navigator.pop(context);
                            _logWeight();
                          },
                    icon: _isLogging
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLogging ? 'جاري الحفظ...' : 'حفظ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
