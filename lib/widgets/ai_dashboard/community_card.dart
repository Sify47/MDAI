// lib/widgets/ai_dashboard/community_card.dart
// 👥 بطاقة تحليل المجتمع الصحي

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class CommunityCard extends StatelessWidget {
  final int totalPosts;
  final int totalLikes;
  final int totalComments;
  final int trendingPostsCount;

  const CommunityCard({
    Key? key,
    required this.totalPosts,
    required this.totalLikes,
    required this.totalComments,
    required this.trendingPostsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
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
          _buildHeader(theme, isDark),
          const SizedBox(height: 16),
          _buildStatsRow(theme),
          const SizedBox(height: 16),
          _buildTrendingBanner(),
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
            color: AppColors.info.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.people, color: AppColors.info, size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          '👥 المجتمع الصحي',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSmallStat(theme, 'منشورات', '$totalPosts', AppColors.primary),
        _buildSmallStat(theme, 'إعجابات', '$totalLikes', AppColors.danger),
        _buildSmallStat(theme, 'تعليقات', '$totalComments', AppColors.success),
      ],
    );
  }

  Widget _buildSmallStat(
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up, color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'منشورات مميزة: $trendingPostsCount',
              style: const TextStyle(
                color: AppColors.info,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
