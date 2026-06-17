// lib/widgets/integration/ai_cause_breakdown_widget.dart
// 🧠 AI Cause Breakdown Widget - Visualizes CauseAnalysisResult
// Shows probability bars for each contributing factor with animated widths

import 'package:flutter/material.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/constants/design_constants.dart';
import 'package:vita/services/integration/symptom_cause_analyzer.dart';

class AICauseBreakdownWidget extends StatelessWidget {
  final CauseAnalysisResult result;
  final bool isAnimated;

  const AICauseBreakdownWidget({
    Key? key,
    required this.result,
    this.isAnimated = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = result.rankedFactors;

    return Container(
      padding: DesignConstants.edgeInsetsExtraWide,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: DesignConstants.borderRadiusFeatured,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: DesignConstants.spacingLg),
          if (!result.hasSufficientData)
            _buildInsufficientDataBanner(theme)
          else ...[
            // 📈 Probability Bars
            ...ranked.map((factor) => _buildFactorBar(context, factor)),
            const SizedBox(height: DesignConstants.spacingLg),
            // 📝 Summary
            _buildSummarySection(theme),
            // 🔝 Top Causes
            if (result.topCauses.isNotEmpty) ...[
              const SizedBox(height: DesignConstants.spacingMd),
              _buildTopCausesSection(theme),
            ],
            // 💡 Recommendations
            if (result.recommendations.isNotEmpty) ...[
              const SizedBox(height: DesignConstants.spacingMd),
              _buildRecommendationsSection(theme),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final severityColor = _getSeverityColor(result.severity);

    return Row(
      children: [
        Container(
          padding: DesignConstants.edgeInsetsItem,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.psychology,
            color: AppColors.warning,
            size: 24,
          ),
        ),
        const SizedBox(width: DesignConstants.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🧠 تحليل أسباب العرض',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                result.symptomName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        // Severity badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: severityColor.withOpacity(0.12),
            borderRadius: DesignConstants.borderRadiusButton,
            border: Border.all(color: severityColor.withOpacity(0.3)),
          ),
          child: Text(
            result.severity,
            style: TextStyle(
              fontSize: DesignConstants.fontXs,
              color: severityColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsufficientDataBanner(ThemeData theme) {
    return Container(
      padding: DesignConstants.edgeInsetsCard,
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: DesignConstants.borderRadiusCard,
        border: Border.all(color: AppColors.info.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: DesignConstants.spacingSm),
          Expanded(
            child: Text(
              'بيانات غير كافية للتحليل الدقيق. سجل المزيد من البيانات الغذائية والطبية.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorBar(BuildContext context, FactorScore factor) {
    final theme = Theme.of(context);
    final barColor = _getBarColor(factor.weightedScore);
    final percentage = (factor.weightedScore.clamp(0.0, 1.0) * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Factor name row
          Row(
            children: [
              if (factor.icon != null) ...[
                Text(factor.icon!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  factor.factorName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: DesignConstants.fontMd,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Animated progress bar
          ClipRRect(
            borderRadius: DesignConstants.borderRadiusSmall,
            child: isAnimated
                ? TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: factor.weightedScore.clamp(0.0, 1.0),
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        backgroundColor: barColor.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      );
                    },
                  )
                : LinearProgressIndicator(
                    value: factor.weightedScore.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: barColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
          ),
          // Evidence dots
          if (factor.evidence.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: DesignConstants.paddingItem),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: factor.evidence.take(2).map((evidence) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: DesignConstants.fontSm,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            evidence,
                            style: TextStyle(
                              fontSize: DesignConstants.fontSm,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme) {
    return Container(
      padding: DesignConstants.edgeInsetsCard,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withOpacity(0.3),
        borderRadius: DesignConstants.borderRadiusCard,
        border: Border.all(color: AppColors.primaryContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
          const SizedBox(width: DesignConstants.spacingSm),
          Expanded(
            child: Text(
              result.summary,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCausesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🔍 الأسباب المحتملة',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingSm),
        Wrap(
          spacing: DesignConstants.spacingSm,
          runSpacing: DesignConstants.spacingSm,
          children: result.topCauses.map((cause) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: DesignConstants.borderRadiusButton,
                border: Border.all(color: AppColors.danger.withOpacity(0.2)),
              ),
              child: Text(
                cause,
                style: TextStyle(
                  fontSize: DesignConstants.fontSm,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 التوصيات',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingSm),
        ...result.recommendations.take(4).map((rec) {
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignConstants.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingSm),
                Expanded(
                  child: Text(
                    rec,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getBarColor(double score) {
    if (score > 0.6) return AppColors.danger;
    if (score > 0.3) return AppColors.warning;
    return AppColors.success;
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'شديد':
      case 'حاد':
      case 'critical':
        return AppColors.danger;
      case 'متوسط':
      case 'moderate':
        return AppColors.warning;
      case 'خفيف':
      case 'mild':
      default:
        return AppColors.success;
    }
  }
}
