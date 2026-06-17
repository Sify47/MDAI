// lib/widgets/comparison_card.dart

import 'package:flutter/material.dart';
import 'package:vita/constants/colors.dart';
import '../constants/design_constants.dart';

class ComparisonCard extends StatelessWidget {
  final double expectedWeight;
  final double actualWeight;
  final double difference;
  final String message;
  final int daysTracked;

  const ComparisonCard({
    Key? key,
    required this.expectedWeight,
    required this.actualWeight,
    required this.difference,
    required this.message,
    required this.daysTracked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isAhead = actualWeight < expectedWeight;
    final percentDiff = expectedWeight > 0
        ? ((difference / expectedWeight) * 100).abs()
        : 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: 0.95 + (animation * 0.05),
          child: Opacity(
            opacity: animation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAhead
                      ? [AppColors.success, AppColors.secondary]
                      : [AppColors.calories, AppColors.danger],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: DesignConstants.borderRadiusFeatured,
                boxShadow: [
                  BoxShadow(
                    color: (isAhead ? AppColors.success : AppColors.calories).withOpacity(
                      0.3,
                    ),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: DesignConstants.edgeInsetsExtraWide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ العنوان مع الشارة
                      Row(
                        children: [
                          Container(
                            padding: DesignConstants.edgeInsetsItem,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: DesignConstants.borderRadiusItem,
                            ),
                            child: Icon(
                              isAhead
                                  ? Icons.emoji_events
                                  : Icons.compare_arrows,
                              color: Colors.white,
                              size: DesignConstants.iconMedium,
                            ),
                          ),
                          const SizedBox(width: DesignConstants.spacingMd),
                          Expanded(
                            child: Text(
                              isAhead ? '🎉 أداء ممتاز!' : '📊 مقارنة التقدم',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: DesignConstants.fontLg,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (daysTracked < 3)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: DesignConstants.paddingCompact,
                                vertical: DesignConstants.paddingCompact - 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: DesignConstants.borderRadiusButton,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.white,
                                    size: DesignConstants.iconSmall,
                                  ),
                                  const SizedBox(width: DesignConstants.spacingXs),
                                  Text(
                                    '${3 - daysTracked} أيام متبقية',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: DesignConstants.fontXs,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: DesignConstants.spacingXl),

                      // ✅ بطاقة المقارنة الرئيسية
                      Container(
                        padding: DesignConstants.edgeInsetsCard,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: DesignConstants.borderRadiusCard,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            // ✅ المتوقع vs الفعلي
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Text(
                                        'المتوقع',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: DesignConstants.fontSm,
                                        ),
                                      ),
                                      const SizedBox(height: DesignConstants.spacingSm),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(
                                          begin: 0,
                                          end: expectedWeight,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 600,
                                        ),
                                        builder: (context, value, child) {
                                          return Text(
                                            '${value.toStringAsFixed(1)} كجم',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: DesignConstants.fontXxl,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: DesignConstants.spacingMd,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white.withOpacity(0.6),
                                    size: DesignConstants.iconMedium,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Text(
                                        'الفعلي',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: DesignConstants.fontSm,
                                        ),
                                      ),
                                      const SizedBox(height: DesignConstants.spacingSm),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(
                                          begin: 0,
                                          end: actualWeight,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 600,
                                        ),
                                        builder: (context, value, child) {
                                          return Text(
                                            '${value.toStringAsFixed(1)} كجم',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: DesignConstants.fontXxl,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: DesignConstants.spacingLg),

                            // ✅ شريط المقارنة
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: DesignConstants.borderRadiusSmall,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width:
                                        (actualWeight / expectedWeight * 100)
                                            .clamp(0, 100) *
                                        MediaQuery.of(context).size.width /
                                        3,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: DesignConstants.borderRadiusSmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: DesignConstants.spacingLg),

                      // ✅ الفرق
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignConstants.paddingItem,
                              vertical: DesignConstants.paddingCompact - 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: DesignConstants.borderRadiusButton,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  difference < 0
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: Colors.white,
                                  size: DesignConstants.iconSmall,
                                ),
                                const SizedBox(width: DesignConstants.spacingSm - 2),
                                Text(
                                  'الفرق: ${difference.abs().toStringAsFixed(1)} كجم',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: DesignConstants.fontSm,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignConstants.paddingItem,
                              vertical: DesignConstants.paddingCompact - 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: DesignConstants.borderRadiusButton,
                            ),
                            child: Text(
                              '${percentDiff.toStringAsFixed(1)}% فرق',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: DesignConstants.fontSm,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: DesignConstants.spacingLg),

                      // ✅ رسالة التقييم
                      Container(
                        padding: DesignConstants.edgeInsetsItem,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: DesignConstants.borderRadiusItem,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAhead ? Icons.check_circle : Icons.info,
                              size: DesignConstants.iconMedium,
                              color: Colors.white,
                            ),
                            const SizedBox(width: DesignConstants.spacingMd),
                            Expanded(
                              child: Text(
                                message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: DesignConstants.fontMd,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ✅ تحذير إذا كانت الأيام قليلة
                      if (daysTracked < 3) ...[
                        const SizedBox(height: DesignConstants.spacingMd),
                        Container(
                          padding: DesignConstants.edgeInsetsItem,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: DesignConstants.borderRadiusSmall,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: AppColors.warning,
                                size: DesignConstants.iconLarge,
                              ),
                              SizedBox(width: DesignConstants.spacingMd),
                              Expanded(
                                child: Text(
                                  'سجل ${3 - daysTracked} أيام إضافية للحصول على تحليل دقيق',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: DesignConstants.fontXs,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ✅ تأثيرات إضافية
                      const SizedBox(height: DesignConstants.spacingSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          8,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                0.2 + (index * 0.05),
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
