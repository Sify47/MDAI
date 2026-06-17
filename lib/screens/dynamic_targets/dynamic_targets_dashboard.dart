// lib/screens/dynamic_targets/dynamic_targets_dashboard.dart
// شاشة الأهداف الديناميكية الرئيسية - تعرض أهداف اليوم مع مقارنة الأداء

import 'package:flutter/material.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/constants/design_constants.dart';
import 'package:vita/models/dynamic_target_model.dart';
import 'package:vita/services/dynamic_targets_service.dart';
import 'package:vita/screens/dynamic_targets/performance_history_screen.dart';
import 'package:vita/screens/dynamic_targets/achievements_screen.dart';
import 'package:vita/screens/dynamic_targets/target_comparison_screen.dart';

class DynamicTargetsDashboard extends StatefulWidget {
  const DynamicTargetsDashboard({Key? key}) : super(key: key);

  @override
  State<DynamicTargetsDashboard> createState() =>
      _DynamicTargetsDashboardState();
}

class _DynamicTargetsDashboardState extends State<DynamicTargetsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  DynamicDailyTarget? _todayTargets;
  PerformanceHistory? _todayPerformance;
  PerformanceSummary? _performanceSummary;
  AchievementStats? _achievementStats;
  DynamicTargetComparison? _comparison;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _refreshAnimation = CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeOutCubic,
    );
    _refreshController.forward();
    _loadAllData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        DynamicTargetsService.getTodayTargets(),
        DynamicTargetsService.getTodayPerformance(),
        DynamicTargetsService.getPerformanceSummary(days: 7),
        DynamicTargetsService.getAchievements(),
        DynamicTargetsService.getTargetComparison(),
      ]);

      if (!mounted) return;

      setState(() {
        if (results[0]['success'] == true) {
          _todayTargets = results[0]['data'] as DynamicDailyTarget;
        }
        if (results[1]['success'] == true) {
          _todayPerformance = results[1]['data'] as PerformanceHistory;
        }
        if (results[2]['success'] == true) {
          _performanceSummary = results[2]['data'] as PerformanceSummary;
        }
        if (results[3]['success'] == true) {
          _achievementStats = results[3]['data'] as AchievementStats;
        }
        if (results[4]['success'] == true) {
          _comparison = results[4]['data'] as DynamicTargetComparison;
        }
        _isLoading = false;
      });
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
          title: const Text('الأهداف الديناميكية'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadAllData,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _buildBody(context, theme, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, bool isDark) {
    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_errorMessage != null) {
      return _buildErrorState(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ بطاقة الأهداف اليومية
            _buildTodayTargetsCard(context, theme, isDark),
            const SizedBox(height: 16),

            // ✅ أداء اليوم
            if (_todayPerformance != null) ...[
              _buildTodayPerformanceCard(context, theme, isDark),
              const SizedBox(height: 16),
            ],

            // ✅ ملخص الأداء الأسبوعي
            if (_performanceSummary != null) ...[
              _buildPerformanceSummaryCard(context, theme, isDark),
              const SizedBox(height: 16),
            ],

            // ✅ الإنجازات
            if (_achievementStats != null &&
                _achievementStats!.totalMilestones > 0) ...[
              _buildAchievementsPreview(context, theme, isDark),
              const SizedBox(height: 16),
            ],

            // ✅ أزرار التصفح
            _buildNavigationButtons(context, theme, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الأهداف الديناميكية...',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء تحميل البيانات',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAllData,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTargetsCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final targets = _todayTargets;
    if (targets == null) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: DesignConstants.borderRadiusCard,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 48,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'لم يتم حساب الأهداف بعد',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'سيتم حساب الأهداف تلقائياً كل صباح',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final result =
                        await DynamicTargetsService.recalculateTargets();
                    if (result['success'] == true && mounted) {
                      _loadAllData();
                    }
                  },
                  child: const Text('حساب الأهداف الآن'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: DesignConstants.borderRadiusCard,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.08),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      borderRadius: DesignConstants.borderRadiusItem,
                    ),
                    child: const Text('🎯', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'أهداف اليوم',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          targets.date,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // عامل التكيف
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPerformanceFactorColor(
                        targets.performanceFactor,
                      ).withOpacity(0.15),
                      borderRadius: DesignConstants.borderRadiusButton,
                    ),
                    child: Text(
                      'تكيف: ${(targets.performanceFactor * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getPerformanceFactorColor(
                          targets.performanceFactor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // السعرات الحرارية
              _buildTargetRow(
                context: context,
                icon: '🔥',
                label: 'السعرات',
                value: '${targets.targetCalories?.toStringAsFixed(0) ?? "—"}',
                unit: 'سعرة',
                baseValue: targets.baseCalories,
                impactPct: targets.caloriesImpactPct,
                color: AppColors.calories,
              ),
              const Divider(height: 24),

              // الخطوات
              _buildTargetRow(
                context: context,
                icon: '🚶',
                label: 'الخطوات',
                value: '${targets.targetSteps?.toStringAsFixed(0) ?? "—"}',
                unit: 'خطوة',
                baseValue: targets.baseSteps,
                impactPct: targets.stepsImpactPct,
                color: AppColors.walking,
              ),
              const Divider(height: 24),

              // الماء
              _buildTargetRow(
                context: context,
                icon: '💧',
                label: 'الماء',
                value: '${targets.targetWater?.toStringAsFixed(1) ?? "—"}',
                unit: 'لتر',
                baseValue: targets.baseWater,
                impactPct: targets.waterImpactPct,
                color: AppColors.info,
              ),
              const Divider(height: 24),

              // البروتين
              _buildTargetRow(
                context: context,
                icon: '🥩',
                label: 'البروتين',
                value: '${targets.targetProtein?.toStringAsFixed(0) ?? "—"}',
                unit: 'جم',
                baseValue: targets.baseProtein,
                impactPct: targets.proteinImpactPct,
                color: AppColors.nutrition,
              ),
              const Divider(height: 24),

              // الكربوهيدرات
              _buildTargetRow(
                context: context,
                icon: '🍚',
                label: 'الكربوهيدرات',
                value: '${targets.targetCarbs?.toStringAsFixed(0) ?? "—"}',
                unit: 'جم',
                baseValue: targets.baseCarbs,
                impactPct: targets.carbsImpactPct,
                color: AppColors.warning,
              ),
              const Divider(height: 24),

              // الدهون
              _buildTargetRow(
                context: context,
                icon: '🧈',
                label: 'الدهون',
                value: '${targets.targetFat?.toStringAsFixed(0) ?? "—"}',
                unit: 'جم',
                baseValue: targets.baseFat,
                impactPct: targets.fatImpactPct,
                color: AppColors.danger,
              ),

              const SizedBox(height: 16),

              // تفاصيل إضافية
              if (targets.impactDetails != null &&
                  targets.impactDetails!.isNotEmpty)
                _buildImpactDetails(context, theme, targets.impactDetails!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetRow({
    required BuildContext context,
    required String icon,
    required String label,
    required String value,
    required String unit,
    double? baseValue,
    required double impactPct,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final hasImpact = impactPct != 0.0;
    final impactSign = impactPct > 0 ? '+' : '';
    final impactColor = impactPct > 0
        ? AppColors.success
        : impactPct < 0
        ? AppColors.danger
        : theme.colorScheme.onSurface.withOpacity(0.5);

    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value $unit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasImpact && baseValue != null)
                Text(
                  'الأساس: ${baseValue.toStringAsFixed(0)} | $impactSign${impactPct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: impactColor),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactDetails(
    BuildContext context,
    ThemeData theme,
    List<Map<String, dynamic>> details,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'تفاصيل التعديلات',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...details.map(
            (detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                    '• ${detail['factor_name'] ?? detail['type'] ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${detail['impact'] ?? detail['adjustment'] ?? 0}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          ((detail['impact'] ?? detail['adjustment'] ?? 0)
                                  as num) >
                              0
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPerformanceCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final perf = _todayPerformance!;
    final score = perf.overallScore ?? 0.0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withOpacity(0.15),
                    borderRadius: DesignConstants.borderRadiusItem,
                  ),
                  child: Text(
                    _getScoreEmoji(score),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أداء اليوم',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getPerformanceDescription(score),
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
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withOpacity(0.15),
                    borderRadius: DesignConstants.borderRadiusButton,
                  ),
                  child: Text(
                    '${(score * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(score),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // مؤشرات الأداء مع القيم الفعلية والمستهدفة
            _buildAdherenceBar(
              '🔥 السعرات',
              perf.caloriesAdherence,
              AppColors.calories,
              actualValue: perf.actualCalories,
              targetValue: perf.targetCalories,
              unit: 'سعرة',
            ),
            const SizedBox(height: 8),
            _buildAdherenceBar(
              '🚶 الخطوات',
              perf.stepsAdherence,
              AppColors.walking,
              actualValue: perf.actualSteps,
              targetValue: perf.targetSteps,
              unit: 'خطوة',
            ),
            const SizedBox(height: 8),
            _buildAdherenceBar(
              '💧 الماء',
              perf.waterAdherence,
              AppColors.info,
              actualValue: perf.actualWater,
              targetValue: perf.targetWater,
              unit: 'لتر',
            ),
            const SizedBox(height: 8),
            _buildAdherenceBar(
              '💊 الأدوية',
              perf.medicationAdherence,
              AppColors.medications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceBar(
    String label,
    double? adherence,
    Color color, {
    double? actualValue,
    double? targetValue,
    String? unit,
  }) {
    final pct = (adherence ?? 0.0);
    final hasValues = actualValue != null && targetValue != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              hasValues
                  ? '${actualValue!.toStringAsFixed(0)}/${targetValue!.toStringAsFixed(0)} ${unit ?? ''}'
                  : '${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        if (hasValues)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${(pct * 100).toStringAsFixed(0)}% من الهدف',
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
            ),
          ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSummaryCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final summary = _performanceSummary!;
    final trendIcon = summary.trend == 'improving'
        ? '📈'
        : summary.trend == 'declining'
        ? '📉'
        : '📊';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.15),
                    borderRadius: DesignConstants.borderRadiusItem,
                  ),
                  child: Text(trendIcon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملخص الأداء (آخر ${summary.periodDays} أيام)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        summary.trend == 'improving'
                            ? 'في تحسن مستمر 👏'
                            : summary.trend == 'declining'
                            ? 'بحاجة للتحسين'
                            : 'مستقر',
                        style: TextStyle(
                          fontSize: 12,
                          color: summary.trend == 'improving'
                              ? AppColors.success
                              : summary.trend == 'declining'
                              ? AppColors.danger
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
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
                    color: _getScoreColor(
                      summary.avgOverallScore,
                    ).withOpacity(0.15),
                    borderRadius: DesignConstants.borderRadiusButton,
                  ),
                  child: Text(
                    '${(summary.avgOverallScore * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(summary.avgOverallScore),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMiniStat(
                  '🔥',
                  'السعرات',
                  '${(summary.avgCaloriesAdherence * 100).toStringAsFixed(0)}%',
                ),
                const SizedBox(width: 8),
                _buildMiniStat(
                  '🚶',
                  'الخطوات',
                  '${(summary.avgStepsAdherence * 100).toStringAsFixed(0)}%',
                ),
                const SizedBox(width: 8),
                _buildMiniStat(
                  '💧',
                  'الماء',
                  '${(summary.avgWaterAdherence * 100).toStringAsFixed(0)}%',
                ),
                const SizedBox(width: 8),
                _buildMiniStat(
                  '💊',
                  'الأدوية',
                  '${(summary.avgMedicationAdherence * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: DesignConstants.borderRadiusItem,
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsPreview(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    final stats = _achievementStats!;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      child: InkWell(
        borderRadius: DesignConstants.borderRadiusCard,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AchievementsScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: DesignConstants.borderRadiusItem,
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإنجازات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${stats.totalMilestones} إنجاز • ${stats.totalPoints} نقطة',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (stats.streakDays > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: DesignConstants.borderRadiusButton,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.streakDays} يوم',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_left,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildNavButton(
            context: context,
            icon: '📊',
            label: 'الأداء',
            subtitle: 'تاريخ الأداء',
            color: AppColors.info,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PerformanceHistoryScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildNavButton(
            context: context,
            icon: '🏆',
            label: 'الإنجازات',
            subtitle: '${_achievementStats?.totalMilestones ?? 0} إنجاز',
            color: AppColors.warning,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildNavButton(
            context: context,
            icon: '⚖️',
            label: 'المقارنة',
            subtitle: 'ثابت vs ديناميكي',
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TargetComparisonScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required String icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: DesignConstants.borderRadiusCard,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== Helper Methods ==========

  Color _getScoreColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.warning;
    return AppColors.danger;
  }

  String _getScoreEmoji(double score) {
    if (score >= 0.9) return '🌟';
    if (score >= 0.8) return '⭐';
    if (score >= 0.6) return '👍';
    if (score >= 0.4) return '💪';
    return '⚠️';
  }

  String _getPerformanceDescription(double score) {
    if (score >= 0.9) return 'أداء ممتاز! استمر';
    if (score >= 0.8) return 'أداء جيد جداً';
    if (score >= 0.6) return 'أداء جيد، يمكن التحسن';
    if (score >= 0.4) return 'بحاجة لبذل المزيد من الجهد';
    return 'ضعيف، حاول تحسين التزامك';
  }

  Color _getPerformanceFactorColor(double factor) {
    if (factor >= 1.05) return AppColors.success;
    if (factor >= 1.0) return AppColors.info;
    if (factor >= 0.9) return AppColors.warning;
    return AppColors.danger;
  }
}
