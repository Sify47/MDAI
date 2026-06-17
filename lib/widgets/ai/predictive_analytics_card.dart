// lib/widgets/ai/predictive_analytics_card.dart
// ITEM 3 & 4: Predictive Nutrition Analytics + Visual Data Exploration UI

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/design_constants.dart';
import '../../models/ai_models.dart';
import '../../models/nutrition_model.dart';
import '../../services/predictive_analytics_service.dart';
import '../../services/nutrition_api.dart';
import '../nutrition/nutrition_card.dart';

/// A card displaying predictive analytics: health score, trends, forecasts
class PredictiveAnalyticsCard extends StatefulWidget {
  final UserNutritionData? userData;

  const PredictiveAnalyticsCard({
    super.key,
    this.userData,
  });

  @override
  State<PredictiveAnalyticsCard> createState() =>
      _PredictiveAnalyticsCardState();
}

class _PredictiveAnalyticsCardState extends State<PredictiveAnalyticsCard> {
  NutritionPredictionReport? _report;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use provided userData or fetch it
      final userData = widget.userData ?? await NutritionService.getUserNutritionData();
      if (userData == null) {
        if (!mounted) return;
        setState(() {
          _error = 'لا توجد بيانات مستخدم متاحة';
          _isLoading = false;
        });
        return;
      }

      final report = await PredictiveAnalyticsService.generatePredictionReport(
        userData: userData,
      );

      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل في تحميل التحليلات التنبؤية';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NutritionCard.defaultStyle(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 12),
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState(theme)
          else if (_report == null)
            _buildEmptyState(theme)
          else
            _buildReportContent(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.analytics_outlined,
            color: AppColors.secondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '📊 التحليلات التنبؤية',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'تحديث التحليلات',
          child: IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadReport,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 100,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.05),
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadReport,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'سجل وجبات كافية للحصول على تحليلات تنبؤية دقيقة',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(ThemeData theme) {
    final report = _report!;

    return Column(
      children: [
        // Health Score Gauge
        _buildHealthScoreSection(theme, report),
        const SizedBox(height: 12),

        // Quick Trends
        if (report.trends.isNotEmpty) ...[
          _buildTrendsSection(theme, report),
          const SizedBox(height: 12),
        ],

        // Weekly Forecast
        if (report.weeklyCalorieForecast.isNotEmpty) ...[
          _buildForecastSection(theme, report),
          const SizedBox(height: 12),
        ],

        // Predicted Deficiencies
        if (report.predictedDeficiencies.isNotEmpty) ...[
          _buildDeficienciesSection(theme, report),
          const SizedBox(height: 12),
        ],

        // Recommendations
        if (report.actionableRecommendations.isNotEmpty) ...[
          _buildRecommendationsSection(theme, report),
        ],
      ],
    );
  }

  Widget _buildHealthScoreSection(
    ThemeData theme,
    NutritionPredictionReport report,
  ) {
    final scoreColor = report.overallScore >= 70
        ? AppColors.success
        : report.overallScore >= 40
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.05),
        borderRadius: DesignConstants.borderRadiusItem,
        border: Border.all(color: scoreColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: report.overallScore / 100,
                    strokeWidth: 6,
                    backgroundColor: scoreColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Text(
                  '${report.overallScore.round()}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'درجة الصحة الغذائية',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.overallAssessment,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(
    ThemeData theme,
    NutritionPredictionReport report,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📈 الاتجاهات',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...report.trends.map((trend) => _buildTrendItem(theme, trend)),
      ],
    );
  }

  Widget _buildTrendItem(ThemeData theme, NutritionTrend trend) {
    final directionColor = trend.direction == TrendDirection.increasing
        ? AppColors.success
        : trend.direction == TrendDirection.decreasing
            ? AppColors.danger
            : AppColors.warning;

    final icon = trend.direction == TrendDirection.increasing
        ? Icons.trending_up
        : trend.direction == TrendDirection.decreasing
            ? Icons.trending_down
            : Icons.trending_flat;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: directionColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trend.metricName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            trend.currentValue.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: directionColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward,
            size: 14,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(width: 4),
          Text(
            trend.predictedValue.toStringAsFixed(1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: directionColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastSection(
    ThemeData theme,
    NutritionPredictionReport report,
  ) {
    final entries = report.weeklyCalorieForecast.entries.toList();
    final maxVal = entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔮 توقعات السعرات للأسبوع القادم',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: DesignConstants.borderRadiusItem,
          ),
          child: Column(
            children: entries.map((entry) {
              final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          minHeight: 14,
                          backgroundColor: AppColors.calories.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.calories,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${entry.value.round()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeficienciesSection(
    ThemeData theme,
    NutritionPredictionReport report,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚠️ نقص متوقع',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...report.predictedDeficiencies.map(
          (d) => _buildDeficiencyItem(theme, d),
        ),
      ],
    );
  }

  Widget _buildDeficiencyItem(
    ThemeData theme,
    PredictedDeficiency deficiency,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: deficiency.riskColor.withOpacity(0.08),
        borderRadius: DesignConstants.borderRadiusItem,
        border: Border.all(
          color: deficiency.riskColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: deficiency.riskColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نقص في ${deficiency.nutrient}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: deficiency.riskColor,
                  ),
                ),
                Text(
                  deficiency.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: deficiency.riskColor.withOpacity(0.1),
              borderRadius: DesignConstants.borderRadiusButton,
            ),
            child: Text(
              deficiency.riskLabel,
              style: TextStyle(
                fontSize: 9,
                color: deficiency.riskColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(
    ThemeData theme,
    NutritionPredictionReport report,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 توصيات قابلة للتنفيذ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...report.actionableRecommendations.map((rec) {
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.05),
              borderRadius: DesignConstants.borderRadiusItem,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    rec,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}