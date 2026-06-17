// lib/widgets/ai_dashboard/health_score_card.dart
// 🏥 بطاقة درجة الصحة - محدثة مع onTap + شرح AI

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class HealthScoreCard extends StatelessWidget {
  final int score;
  final double nutritionScore;
  final double walkingPercentage;
  final double waterProgress;
  final VoidCallback? onTap;

  const HealthScoreCard({
    Key? key,
    required this.score,
    required this.nutritionScore,
    required this.walkingPercentage,
    required this.waterProgress,
    this.onTap,
  }) : super(key: key);

  Color get _scoreColor => score >= 80
      ? AppColors.success
      : score >= 60
      ? AppColors.warning
      : AppColors.danger;

  String get _healthMessage {
    if (score >= 80) return '🎉 ممتاز! استمر في الحفاظ على صحتك';
    if (score >= 60) return '💪 جيد - يمكنك تحسين بعض العادات';
    return '⚠️ يحتاج إلى اهتمام - راجع نمط حياتك';
  }

  String get _statusLabel {
    if (score >= 80) return 'ممتاز';
    if (score >= 60) return 'جيد';
    return 'يحتاج تحسين';
  }

  String get _aiExplanation {
    if (score >= 80) {
      return 'أحسنت! درجتك الصحية ممتازة. توازنك بين التغذية والنشاط والماء جيد جداً. نصيحتي: استمر في هذا النمط، وحاول تحسين النواحي الأقل قليلاً لتحقيق الكمال.';
    } else if (score >= 60) {
      final weakPoints = <String>[];
      if (nutritionScore < 0.6) weakPoints.add('التغذية');
      if (walkingPercentage < 0.6) weakPoints.add('النشاط البدني');
      if (waterProgress < 0.6) weakPoints.add('شرب الماء');
      final weakStr = weakPoints.isEmpty
          ? 'جميع العوامل بدرجة جيدة'
          : 'نقاط الضعف: ${weakPoints.join('، ')}';
      return 'درجتك الصحية جيدة، لكن هناك مجال للتحسين. $weakStr. التركيز على تحسين هذه الجوانب سيرفع درجتك بشكل ملحوظ.';
    } else {
      return 'درجتك الصحية تحتاج إلى اهتمام. يبدو أن هناك عدة عوامل تحتاج إلى تحسين. أنصحك بالتركيز أولاً على شرب الماء بانتظام وتناول وجبات متوازنة، ثم زيادة النشاط البدني تدريجياً. صحتك تستحق الاهتمام!';
    }
  }

  void _showScoreExplanation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScoreExplanationSheet(
        score: score,
        nutritionScore: nutritionScore,
        walkingPercentage: walkingPercentage,
        waterProgress: waterProgress,
        statusLabel: _statusLabel,
        scoreColor: _scoreColor,
        aiExplanation: _aiExplanation,
        healthMessage: _healthMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        _showScoreExplanation(context);
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_scoreColor.withOpacity(0.85), _scoreColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _scoreColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'صحتك اليوم',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'اضغط للتفاصيل',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '$score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'من 100',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFactor('التغذية', nutritionScore),
                      const SizedBox(height: 8),
                      _buildFactor('النشاط', walkingPercentage),
                      const SizedBox(height: 8),
                      _buildFactor('الماء', waterProgress),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _healthMessage,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactor(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).clamp(0, 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }
}

// 📊 شاشة شرح درجة الصحة مع تحليل AI
class _ScoreExplanationSheet extends StatelessWidget {
  final int score;
  final double nutritionScore;
  final double walkingPercentage;
  final double waterProgress;
  final String statusLabel;
  final Color scoreColor;
  final String aiExplanation;
  final String healthMessage;

  const _ScoreExplanationSheet({
    required this.score,
    required this.nutritionScore,
    required this.walkingPercentage,
    required this.waterProgress,
    required this.statusLabel,
    required this.scoreColor,
    required this.aiExplanation,
    required this.healthMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Center(
              child: Text(
                '📊 تحليل درجتك الصحية',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Score circle
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 10,
                      backgroundColor: scoreColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: scoreColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // AI Explanation Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(isDark ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.info.withOpacity(isDark ? 0.2 : 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '🧠 تحليل الذكاء الاصطناعي',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    aiExplanation,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Factor breakdown
            Text(
              'تفاصيل العوامل',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFactorDetail(
              theme, '🥗 التغذية', nutritionScore,
              nutritionScore >= 0.8
                  ? 'نظامك الغذائي متوازن - استمر في تناول الوجبات الصحية'
                  : nutritionScore >= 0.6
                      ? 'تغذيتك جيدة - حاول إضافة المزيد من الخضروات والبروتين'
                      : 'تغذيتك تحتاج تحسين - ركز على الوجبات المتوازنة',
            ),
            const SizedBox(height: 10),
            _buildFactorDetail(
              theme, '🚶 النشاط البدني', walkingPercentage,
              walkingPercentage >= 0.8
                  ? 'نشاطك ممتاز - حافظ على هذا المستوى'
                  : walkingPercentage >= 0.6
                      ? 'نشاطك جيد - جرب زيادة مدة التمارين قليلاً'
                      : 'نشاطك قليل - حاول المشي 30 دقيقة يومياً',
            ),
            const SizedBox(height: 10),
            _buildFactorDetail(
              theme, '💧 شرب الماء', waterProgress,
              waterProgress >= 0.8
                  ? 'ممتاز! كمية الماء ممتازة لصحتك'
                  : waterProgress >= 0.6
                      ? 'جيد - حاول شرب كوب إضافي من الماء'
                      : 'تحتاج لشرب المزيد من الماء - حدد تذكيرات منتظمة',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorDetail(
    ThemeData theme,
    String label,
    double value,
    String advice,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).clamp(0, 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: value >= 0.8
                      ? AppColors.success
                      : value >= 0.6
                          ? AppColors.warning
                          : AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                value >= 0.8
                    ? AppColors.success
                    : value >= 0.6
                        ? AppColors.warning
                        : AppColors.danger,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            advice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
