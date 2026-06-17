// lib/widgets/integration/factor_timeline_widget.dart
// 📊 Factor Timeline Widget - Vertical timeline of ranked contributing factors
// Shows icons, evidence bullets, and recommendation chips per factor

import 'package:flutter/material.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/constants/design_constants.dart';
import 'package:vita/services/integration/symptom_cause_analyzer.dart';

class FactorTimelineWidget extends StatelessWidget {
  final CauseAnalysisResult result;

  const FactorTimelineWidget({Key? key, required this.result})
    : super(key: key);

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
          const SizedBox(height: DesignConstants.spacingXxl),
          if (ranked.isEmpty)
            _buildEmptyState(theme)
          else
            ...List.generate(ranked.length, (index) {
              final factor = ranked[index];
              final isLast = index == ranked.length - 1;
              return _buildTimelineItem(theme, factor, index, isLast);
            }),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: DesignConstants.edgeInsetsItem,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.timeline, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: DesignConstants.spacingMd),
        Text(
          '📊 ترتيب العوامل المؤثرة',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignConstants.paddingExtraWide),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: DesignConstants.spacingSm),
            Text(
              'لا توجد بيانات كافية للتحليل',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    ThemeData theme,
    FactorScore factor,
    int index,
    bool isLast,
  ) {
    final barColor = _getFactorColor(factor.weightedScore);
    final percentage = (factor.weightedScore.clamp(0.0, 1.0) * 100).toInt();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline gutter (line + dot)
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Rank number dot
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: barColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: DesignConstants.fontSm,
                        fontWeight: FontWeight.bold,
                        color: barColor,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignConstants.spacingMd),
          // Factor content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : DesignConstants.spacingLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Factor header
                  Row(
                    children: [
                      if (factor.icon != null) ...[
                        Text(
                          factor.icon!,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          factor.factorName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Score badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: barColor.withOpacity(0.12),
                          borderRadius: DesignConstants.borderRadiusButton,
                        ),
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: DesignConstants.fontSm,
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingSm),
                  // Impact bar
                  ClipRRect(
                    borderRadius: DesignConstants.borderRadiusSmall,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: factor.weightedScore.clamp(0.0, 1.0),
                      ),
                      duration: Duration(milliseconds: 600 + (index * 100)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: barColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        );
                      },
                    ),
                  ),
                  // Evidence items
                  if (factor.evidence.isNotEmpty) ...[
                    const SizedBox(height: DesignConstants.spacingSm),
                    ...factor.evidence.map((evidence) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.fiber_manual_record,
                              size: 6,
                              color: barColor.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                evidence,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.65),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  // Weight info
                  Text(
                    'وزن العامل: ${(factor.weight * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: DesignConstants.fontXs,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
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

  Color _getFactorColor(double score) {
    if (score > 0.6) return AppColors.danger;
    if (score > 0.3) return AppColors.warning;
    return AppColors.success;
  }
}
