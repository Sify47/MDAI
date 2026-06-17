// lib/widgets/ai_dashboard/loading_shimmer.dart
// 🌀 تأثير التحميل Shimmer - محدث مع تحميل تدريجي لكل كارد

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum ShimmerCardType {
  healthScore, // دائرة كبيرة مع تفاصيل
  nutrition, // رسم بياني
  tips, // قائمة نصائح
  stats, // بطاقة إحصائيات
  chart, // رسم بياني خطي
}

class DashboardLoadingShimmer extends StatelessWidget {
  final ShimmerCardType? specificType;

  const DashboardLoadingShimmer({Key? key, this.specificType})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: specificType != null
          ? _buildSpecificShimmer(specificType!, isDark)
          : _buildFullPageShimmer(isDark),
    );
  }

  Widget _buildFullPageShimmer(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildShimmerCard(isDark, 180),
        const SizedBox(height: 16),
        _buildShimmerCard(isDark, 140),
        const SizedBox(height: 16),
        _buildShimmerCard(isDark, 200),
        const SizedBox(height: 16),
        _buildShimmerCard(isDark, 160),
      ],
    );
  }

  Widget _buildSpecificShimmer(ShimmerCardType type, bool isDark) {
    switch (type) {
      case ShimmerCardType.healthScore:
        return _buildHealthScoreShimmer(isDark);
      case ShimmerCardType.nutrition:
        return _buildNutritionShimmer(isDark);
      case ShimmerCardType.tips:
        return _buildTipsShimmer(isDark);
      case ShimmerCardType.stats:
        return _buildStatsShimmer(isDark);
      case ShimmerCardType.chart:
        return _buildChartShimmer(isDark);
    }
  }

  Widget _buildShimmerCard(bool isDark, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _buildHealthScoreShimmer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.grey[700] : Colors.grey[200],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: List.generate(
                    3,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 30,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionShimmer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsShimmer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 160,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsShimmer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(
          3,
          (_) => Expanded(
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.grey[700] : Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 50,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartShimmer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
