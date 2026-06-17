// lib/widgets/progress_card.dart

import 'package:flutter/material.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/constants/design_constants.dart';

class ProgressCard extends StatelessWidget {
  final String title;
  final String icon;
  final double percentage;
  final String valueText;
  final String subText;
  final Color gradientStart;
  final Color gradientEnd;
  final bool isAnimated;
  final String? unit;
  final String? description;

  const ProgressCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.percentage,
    required this.valueText,
    required this.subText,
    required this.gradientStart,
    required this.gradientEnd,
    this.isAnimated = true,
    this.unit,
    this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isAnimated ? percentage / 100 : 0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final displayPercent = (value * 100).toInt();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStart, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: DesignConstants.borderRadiusCard,
            boxShadow: [
              BoxShadow(
                color: gradientStart.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
                spreadRadius: 1,
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
                  // ✅ العنوان مع الأيقونة
                  Row(
                    children: [
                      Container(
                        padding: DesignConstants.edgeInsetsCompact,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: DesignConstants.borderRadiusItem,
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: DesignConstants.spacingLg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: DesignConstants.fontMd,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (description != null) ...[
                              const SizedBox(height: DesignConstants.spacingXs),
                              Text(
                                description!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: DesignConstants.fontXs,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // ✅ نسبة التقدم الدائرية
                      Container(
                        width: 55,
                        height: 55,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 4,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              '$displayPercent%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: DesignConstants.fontSm,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: DesignConstants.spacingXxl),

                  // ✅ شريط التقدم الرئيسي
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'نسبة التقدم',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: DesignConstants.fontSm,
                            ),
                          ),
                          Text(
                            '$displayPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: DesignConstants.fontLg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignConstants.spacingSm),
                      ClipRRect(
                        borderRadius: DesignConstants.borderRadiusSmall,
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: DesignConstants.spacingXxl),

                  // ✅ القيمة والتفاصيل
                  Container(
                    padding: DesignConstants.edgeInsetsItem,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: DesignConstants.borderRadiusItem,
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                valueText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: DesignConstants.fontXl,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (unit != null) ...[
                                const SizedBox(height: DesignConstants.spacingXs),
                                Text(
                                  unit!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: DesignConstants.fontXs,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: DesignConstants.spacingLg),
                            child: Text(
                              subText,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: DesignConstants.fontSm,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ✅ تأثير الموجة في الأسفل
                  const SizedBox(height: DesignConstants.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
