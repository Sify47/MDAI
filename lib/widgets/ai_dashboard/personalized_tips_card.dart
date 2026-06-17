// lib/widgets/ai_dashboard/personalized_tips_card.dart
// ✨ بطاقة النصائح الصحية الذكية - محدثة مع onTap + شرح AI لكل نصيحة

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class PersonalizedTipsCard extends StatelessWidget {
  final List<Map<String, dynamic>> tips;
  final void Function(Map<String, dynamic> tip)? onTipTap;

  const PersonalizedTipsCard({Key? key, required this.tips, this.onTipTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayTips = tips.length > 5 ? tips.sublist(0, 5) : tips;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Colors.purple.shade900.withOpacity(0.3),
                  Colors.blue.shade900.withOpacity(0.3),
                ]
              : [
                  AppColors.info.withOpacity(0.05),
                  AppColors.success.withOpacity(0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDark),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayTips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildTipItem(context, theme, isDark, displayTips[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.tips_and_updates,
            color: AppColors.warning,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '✨ نصائح مخصصة لك',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.smart_toy,
          size: 20,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ],
    );
  }

  void _showTipExplanation(BuildContext context, Map<String, dynamic> tip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TipExplanationSheet(tip: tip),
    );
  }

  Widget _buildTipItem(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Map<String, dynamic> tip,
  ) {
    return GestureDetector(
      onTap: () {
        _showTipExplanation(context, tip);
        onTipTap?.call(tip);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  tip['icon'] ?? '💡',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip['title'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip['tip'] ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (tip['priority'] == 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'هام',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_left,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

// 💡 شاشة شرح النصيحة مع تحليل AI
class _TipExplanationSheet extends StatelessWidget {
  final Map<String, dynamic> tip;

  const _TipExplanationSheet({required this.tip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = tip['title'] ?? '';
    final tipText = tip['tip'] ?? '';
    final icon = tip['icon'] ?? '💡';
    final category = tip['category'] as String? ?? 'عام';
    final priority = tip['priority'] as int? ?? 0;

    // Generate AI explanation based on category
    final aiExplanation = _generateAiExplanation(
      category,
      title as String,
      tipText as String,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
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

            // Header with icon
            Center(
              child: Column(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    title as String,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category & priority badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (priority == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'مهم',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Tip content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tipText as String,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 16),

            // AI explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(isDark ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withOpacity(isDark ? 0.2 : 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '🧠 لماذا هذه النصيحة؟',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
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
            const SizedBox(height: 16),

            // Action hint
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  'اسحب للأسفل للإغلاق',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _generateAiExplanation(String category, String title, String tipText) {
    switch (category) {
      case 'nutrition':
        return 'هذه النصيحة مبنية على تحليل عاداتك الغذائية الأخيرة. نظامك الغذائي يؤثر مباشرة على طاقتك وصحتك العامة. تطبيق هذه النصيحة سيساعدك على تحسين توازنك الغذائي والوصول لأهدافك الصحية بشكل أسرع.';
      case 'water':
        return 'شرب الماء بانتظام من أهم العادات الصحية. هذه النصيحة تستند إلى كمية الماء التي سجلتها اليوم مقارنة بالهدف الموصى به. الحفاظ على ترطيب الجسم يحسن التركيز والطاقة وصحة البشرة.';
      case 'activity':
        return 'النشاط البدني المنتظم ضروري لصحة القلب والوزن المثالي. هذه النصيحة تأتي بناءً على مستوى نشاطك الحالي. حتى التمارين الخفيفة يومياً تحدث فرقاً كبيراً في صحتك على المدى الطويل.';
      case 'sleep':
        return 'النوم الجيد أساس الصحة النفسية والجسدية. هذه النصيحة مخصصة بناءً على نمط نومك المسجل. تحسين جودة النوم يعزز المناعة والذاكرة والأداء اليومي.';
      case 'mental':
        return 'الصحة النفسية لا تقل أهمية عن الصحة الجسدية. هذه النصيحة تهدف لدعم صحتك النفسية بناءً على حالتك المسجلة. الاهتمام بمشاعرك وأفكارك جزء أساسي من رحلة العافية الشاملة.';
      default:
        return 'هذه النصيحة مخصصة لك بناءً على تحليل بياناتك الصحية ونمط حياتك. تطبيق النصائح المخصصة يساعدك على تحقيق تقدم ملموس في رحلتك الصحية. تذكر أن التغييرات الصغيرة والمستمرة تؤدي إلى نتائج كبيرة.';
    }
  }
}
