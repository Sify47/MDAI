// lib/screens/dynamic_targets/performance_history_screen.dart
// شاشة تاريخ الأداء - تعرض سجل الالتزام اليومي مع الرسوم البيانية

import 'package:flutter/material.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/constants/design_constants.dart';
import 'package:vita/models/dynamic_target_model.dart';
import 'package:vita/services/dynamic_targets_service.dart';

class PerformanceHistoryScreen extends StatefulWidget {
  const PerformanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PerformanceHistoryScreen> createState() =>
      _PerformanceHistoryScreenState();
}

class _PerformanceHistoryScreenState extends State<PerformanceHistoryScreen> {
  PerformanceSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedDays = 14;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await DynamicTargetsService.getPerformanceSummary(
        days: _selectedDays,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _summary = result['data'] as PerformanceSummary;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تاريخ الأداء'),
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.date_range),
              onSelected: (days) {
                setState(() => _selectedDays = days);
                _loadData();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 7, child: Text('آخر 7 أيام')),
                const PopupMenuItem(value: 14, child: Text('آخر 14 يوم')),
                const PopupMenuItem(value: 30, child: Text('آخر 30 يوم')),
              ],
            ),
          ],
        ),
        body: _buildBody(theme, isDark),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final summary = _summary;
    if (summary == null || summary.dailyRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد بيانات أداء كافية',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم عرض الأداء بعد تسجيل البيانات',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ ملخص الأداء
            _buildSummaryCard(theme, summary),
            const SizedBox(height: 16),

            // ✅ متوسط الالتزام
            _buildAveragesCard(theme, summary),
            const SizedBox(height: 16),

            // ✅ السجلات اليومية
            Text(
              'السجلات اليومية',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...summary.dailyRecords.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDailyRecordCard(theme, record),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, PerformanceSummary summary) {
    final trendIcon = summary.trend == 'improving'
        ? '📈'
        : summary.trend == 'declining'
        ? '📉'
        : '📊';
    final trendColor = summary.trend == 'improving'
        ? AppColors.success
        : summary.trend == 'declining'
        ? AppColors.danger
        : theme.colorScheme.onSurface.withOpacity(0.6);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: DesignConstants.borderRadiusItem,
                  ),
                  child: Text(trendIcon, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملخص ${summary.periodDays} أيام',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'عامل التكيف: ${(summary.performanceFactor * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(
                      summary.avgOverallScore,
                    ).withOpacity(0.15),
                    borderRadius: DesignConstants.borderRadiusButton,
                  ),
                  child: Text(
                    '${(summary.avgOverallScore * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(summary.avgOverallScore),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'الاتجاه: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  summary.trend == 'improving'
                      ? 'في تحسن مستمر 👏'
                      : summary.trend == 'declining'
                      ? 'بحاجة للتحسين'
                      : 'مستقر',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAveragesCard(ThemeData theme, PerformanceSummary summary) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'متوسط الالتزام',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAverageRow(
              '🔥 السعرات',
              summary.avgCaloriesAdherence,
              AppColors.calories,
            ),
            const SizedBox(height: 12),
            _buildAverageRow(
              '🚶 الخطوات',
              summary.avgStepsAdherence,
              AppColors.walking,
            ),
            const SizedBox(height: 12),
            _buildAverageRow(
              '💧 الماء',
              summary.avgWaterAdherence,
              AppColors.info,
            ),
            const SizedBox(height: 12),
            _buildAverageRow(
              '💊 الأدوية',
              summary.avgMedicationAdherence,
              AppColors.medications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageRow(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyRecordCard(ThemeData theme, PerformanceHistory record) {
    final score = record.overallScore ?? 0.0;
    final dateStr = record.date;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(score * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(score),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMiniBar(
                  '🔥',
                  record.caloriesAdherence,
                  AppColors.calories,
                ),
                const SizedBox(width: 6),
                _buildMiniBar('🚶', record.stepsAdherence, AppColors.walking),
                const SizedBox(width: 6),
                _buildMiniBar('💧', record.waterAdherence, AppColors.info),
                const SizedBox(width: 6),
                _buildMiniBar(
                  '💊',
                  record.medicationAdherence,
                  AppColors.medications,
                ),
              ],
            ),
            if (record.actualCalories != null ||
                record.actualSteps != null ||
                record.actualWater != null) ...[
              const SizedBox(height: 8),
              Text(
                'فعلي: ${record.actualCalories?.toStringAsFixed(0) ?? "—"} سعرة / ${record.actualSteps?.toStringAsFixed(0) ?? "—"} خطوة / ${record.actualWater?.toStringAsFixed(1) ?? "—"} لتر',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBar(String icon, double? value, Color color) {
    final pct = (value ?? 0.0).clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.warning;
    return AppColors.danger;
  }
}
