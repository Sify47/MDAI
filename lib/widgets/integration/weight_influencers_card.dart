// lib/widgets/integration/weight_influencers_card.dart
// ⚖️ Weight Influencers Card - Visualizes WeightAnalysisResult
// Shows trend indicator, BMI, weight change, and ranked factor bars

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/design_constants.dart';
import '../../services/integration/weight_influencers_service.dart';

class WeightInfluencersCard extends StatefulWidget {
  final WeightAnalysisResult result;
  final bool isAnimated;

  const WeightInfluencersCard({
    Key? key,
    required this.result,
    this.isAnimated = true,
  }) : super(key: key);

  @override
  State<WeightInfluencersCard> createState() => _WeightInfluencersCardState();
}

class _WeightInfluencersCardState extends State<WeightInfluencersCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    debugPrint(
      '🔍 [WeightInfluencersCard] initState: isAnimated=${widget.isAnimated}, '
      'hasResult=true, '
      'hasSufficientData=${widget.result.hasSufficientData}, '
      'rankedCount=${widget.result.rankedInfluencers.length}, '
      'bmi=${widget.result.bmi?.toStringAsFixed(1) ?? "null"}, '
      'trend=${widget.result.trend}',
    );
    // ✅ Start animation only if widget is still mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ranked = widget.result.rankedInfluencers;
    final textOnCard = isDark
        ? Colors.white
        : theme.colorScheme.onSecondaryContainer;

    debugPrint(
      '🔍 [WeightInfluencersCard] build: isDark=$isDark, '
      'textColor=${isDark ? "Colors.white" : "onSecondaryContainer"}',
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_controller),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A3A3A), const Color(0xFF0D2E2E)]
                  : [AppColors.secondary, AppColors.onSecondaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: DesignConstants.borderRadiusCard,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, textOnCard),
                  const SizedBox(height: 20),
                  // Stats row (BMI, Change, Trend)
                  _buildStatsRow(theme, textOnCard),
                  const SizedBox(height: 24),
                  // Summary
                  _buildSummarySection(theme, textOnCard),
                  const SizedBox(height: 20),
                  // Factor influencers
                  if (ranked.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 20,
                          decoration: BoxDecoration(
                            color: textOnCard,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'العوامل المؤثرة في وزنك',
                          style: TextStyle(
                            color: textOnCard,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'التأثير',
                          style: TextStyle(
                            color: textOnCard.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...ranked.asMap().entries.map(
                      (entry) => _buildInfluencerBar(
                        context,
                        entry.value,
                        entry.key,
                        ranked.length,
                      ),
                    ),
                  ],
                  if (!widget.result.hasSufficientData) ...[
                    const SizedBox(height: 16),
                    _buildNoDataBanner(textOnCard),
                  ],
                  const SizedBox(height: 8),
                  _buildFooterNote(theme, textOnCard),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color textOnCard) {
    final trendIcon = _getTrendIcon(widget.result.trend);
    final trendColor = _getTrendColor(widget.result.trend);
    final trendLabel = _getTrendLabel(widget.result.trend);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: textOnCard.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textOnCard.withOpacity(0.2), width: 1),
          ),
          child: const Text('⚖️', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تحليل الوزن الذكي',
                style: TextStyle(
                  color: textOnCard,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'تحليل العوامل المؤثرة في رحلة وزنك',
                style: TextStyle(
                  color: textOnCard.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Trend indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: trendColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: trendColor.withOpacity(0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(trendIcon, color: trendColor, size: 18),
              const SizedBox(width: 6),
              Text(
                trendLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme, Color textOnCard) {
    final hasBmi = widget.result.bmi != null;
    final hasChange30d = widget.result.weightChange30d != null;
    final hasChange7d = widget.result.weightChange7d != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: textOnCard.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textOnCard.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // BMI
          if (hasBmi) ...[
            Expanded(
              child: _buildStatItem(
                icon: Icons.monitor_weight_outlined,
                label: 'مؤشر الكتلة',
                value: widget.result.bmi!.toStringAsFixed(1),
                subLabel: _getBmiCategory(widget.result.bmi!),
                color: _getBmiColor(widget.result.bmi!),
                labelColor: textOnCard,
              ),
            ),
            Container(width: 1, height: 50, color: textOnCard.withOpacity(0.2)),
          ],
          // 30-day change
          if (hasChange30d) ...[
            Expanded(
              child: _buildStatItem(
                icon: Icons.calendar_month,
                label: 'تغير 30 يوم',
                value:
                    '${widget.result.weightChange30d!.abs().toStringAsFixed(1)}%',
                subLabel: widget.result.weightChange30d! >= 0
                    ? 'زيادة'
                    : 'نقصان',
                color: widget.result.weightChange30d! >= 0
                    ? AppColors.warning
                    : AppColors.success,
                changeValue: widget.result.weightChange30d!,
                labelColor: textOnCard,
              ),
            ),
            if (hasChange7d)
              Container(
                width: 1,
                height: 50,
                color: textOnCard.withOpacity(0.2),
              ),
          ],
          // 7-day change
          if (hasChange7d) ...[
            Expanded(
              child: _buildStatItem(
                icon: Icons.date_range,
                label: 'تغير 7 أيام',
                value:
                    '${widget.result.weightChange7d!.abs().toStringAsFixed(1)}%',
                subLabel: widget.result.weightChange7d! >= 0
                    ? 'زيادة'
                    : 'نقصان',
                color: widget.result.weightChange7d! >= 0
                    ? AppColors.warning
                    : AppColors.success,
                changeValue: widget.result.weightChange7d!,
                labelColor: textOnCard,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required String subLabel,
    Color? color,
    double? changeValue,
    Color labelColor = Colors.white,
  }) {
    final textColor = color ?? labelColor;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: textColor, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            subLabel,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(ThemeData theme, Color textOnCard) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [textOnCard.withOpacity(0.12), textOnCard.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textOnCard.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textOnCard.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome, color: textOnCard, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.result.summary,
              style: TextStyle(
                color: textOnCard,
                fontSize: 14,
                height: 1.5,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfluencerBar(
    BuildContext context,
    WeightInfluencer influencer,
    int index,
    int total,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textOnCard = isDark
        ? Colors.white
        : theme.colorScheme.onSecondaryContainer;
    final directionColor = _getDirectionColor(influencer.direction);
    final directionIcon = _getDirectionIcon(influencer.direction);
    final impactPercent = (influencer.impactScore.clamp(0.0, 1.0) * 100)
        .toInt();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Opacity(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(20 * (1 - animation), 0),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Factor header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: directionColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      influencer.icon,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    influencer.factorName,
                    style: TextStyle(
                      color: textOnCard,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Impact percentage
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: directionColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(directionIcon, color: directionColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$impactPercent%',
                        style: TextStyle(
                          color: directionColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Animated impact bar with gradient
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: textOnCard.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.isAnimated
                    ? TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: influencer.impactScore.clamp(0.0, 1.0),
                        ),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    directionColor,
                                    directionColor.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      )
                    : FractionallySizedBox(
                        widthFactor: influencer.impactScore.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                directionColor,
                                directionColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
            ),
            // Evidence
            if (influencer.evidence.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.only(left: 40),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: influencer.evidence.take(2).map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: textOnCard.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 4, color: directionColor),
                          const SizedBox(width: 6),
                          Text(
                            e,
                            style: TextStyle(
                              color: textOnCard.withOpacity(0.7),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildNoDataBanner(Color textOnCard) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: textOnCard.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textOnCard.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بيانات غير كافية',
                  style: TextStyle(
                    color: textOnCard,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'يحتاج التحليل إلى المزيد من البيانات (7-14 يوماً) للحصول على نتائج دقيقة',
                  style: TextStyle(
                    color: textOnCard.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote(ThemeData theme, Color textOnCard) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 4, color: textOnCard.withOpacity(0.4)),
          const SizedBox(width: 8),
          Text(
            'التحليل يعتمد على بياناتك المسجلة',
            style: TextStyle(color: textOnCard.withOpacity(0.5), fontSize: 10),
          ),
          const SizedBox(width: 8),
          Icon(Icons.circle, size: 4, color: textOnCard.withOpacity(0.4)),
        ],
      ),
    );
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up':
        return AppColors.warning;
      case 'down':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getTrendLabel(String trend) {
    switch (trend) {
      case 'up':
        return 'ارتفاع الوزن';
      case 'down':
        return 'انخفاض الوزن';
      default:
        return 'مستقر';
    }
  }

  IconData _getDirectionIcon(String direction) {
    switch (direction) {
      case 'up':
        return Icons.arrow_upward;
      case 'down':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }

  Color _getDirectionColor(String direction) {
    switch (direction) {
      case 'up':
        return AppColors.warning;
      case 'down':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'نقص وزن';
    if (bmi < 25) return 'وزن طبيعي';
    if (bmi < 30) return 'وزن زائد';
    return 'سمنة';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return AppColors.info;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.danger;
  }
}
