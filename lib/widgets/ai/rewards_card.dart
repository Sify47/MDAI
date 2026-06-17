// lib/widgets/ai/rewards_card.dart
// ITEM 6: Reward System (Badges & Gamification) UI

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/design_constants.dart';
import '../../models/ai_models.dart';
import '../../services/challenges_rewards_service.dart';
import '../nutrition/nutrition_card.dart';

/// A card displaying the user's gamification stats: level, XP, badges, streak
class RewardsCard extends StatefulWidget {
  const RewardsCard({super.key});

  @override
  State<RewardsCard> createState() => _RewardsCardState();
}

class _RewardsCardState extends State<RewardsCard> {
  UserGamificationStats? _stats;
  List<NutritionBadge>? _earnedBadges;
  bool _isLoading = true;
  String? _error;
  int _currentWeekXp = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await ChallengesRewardsService.getGamificationStats();
      final badges = await ChallengesRewardsService.getEarnedBadges();
      final weekXp = await ChallengesRewardsService.getCurrentWeekXp();

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _earnedBadges = badges;
        _currentWeekXp = weekXp;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل في تحميل الإحصائيات';
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
          else if (_stats == null)
            _buildEmptyState(theme)
          else
            _buildStatsContent(theme),
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
            color: AppColors.calories.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.stars_rounded,
            color: AppColors.calories,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '🎖️ المكافآت والإنجازات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'تحديث الإحصائيات',
          child: IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadStats,
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
          color: AppColors.calories,
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.05),
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadStats,
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
      child: Column(
        children: [
          const Icon(Icons.stars_rounded,
              size: 40, color: AppColors.info),
          const SizedBox(height: 8),
          Text(
            'ابدأ بتسجيل وجباتك لكسب النقاط والشارات',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.info,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(ThemeData theme) {
    final stats = _stats!;
    final levelProgress = ChallengesRewardsService.getLevelProgress(
      stats.totalXp,
      stats.currentLevel,
    );

    return Column(
      children: [
        // Level & XP Section
        _buildLevelSection(theme, stats, levelProgress),
        const SizedBox(height: 12),

        // Streak Section
        _buildStreakSection(theme, stats),
        const SizedBox(height: 12),

        // Badges Section
        if (_earnedBadges != null && _earnedBadges!.isNotEmpty) ...[
          _buildBadgesSection(theme),
          const SizedBox(height: 12),
        ],

        // Stats Row
        _buildStatsRow(theme, stats),
      ],
    );
  }

  Widget _buildLevelSection(
    ThemeData theme,
    UserGamificationStats stats,
    double levelProgress,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.04),
          ],
        ),
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Row(
        children: [
          // Level icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${stats.currentLevel}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المستوى ${stats.currentLevel}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: levelProgress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats.totalXp} XP / ${_stats!.xpToNextLevel} XP للمستوى التالي',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(
    ThemeData theme,
    UserGamificationStats stats,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.calories.withOpacity(0.05),
        borderRadius: DesignConstants.borderRadiusItem,
        border: Border.all(
          color: AppColors.calories.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            stats.currentStreak > 0
                ? Icons.local_fire_department
                : Icons.local_fire_department_outlined,
            color: stats.currentStreak > 0
                ? AppColors.calories
                : theme.colorScheme.onSurface.withOpacity(0.3),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.currentStreak > 0
                      ? '🔥 سجل مستمر: ${stats.currentStreak} يوم'
                      : 'ابدأ سجلك المستمر اليوم!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'أطول سجل: ${stats.longestStreak} يوم',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _currentWeekXp > 0
                  ? AppColors.success.withOpacity(0.1)
                  : theme.colorScheme.onSurface.withOpacity(0.05),
              borderRadius: DesignConstants.borderRadiusButton,
            ),
            child: Text(
              '$_currentWeekXp XP/أسبوع',
              style: TextStyle(
                fontSize: 10,
                color: _currentWeekXp > 0
                    ? AppColors.success
                    : theme.colorScheme.onSurface.withOpacity(0.3),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🪪 الشارات',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _earnedBadges!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, index) {
              final badge = _earnedBadges![index];
              return Semantics(
                label: 'شارة: ${badge.name}',
                child: Tooltip(
                  message: badge.description,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: badge.typeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: badge.typeColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        badge.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(ThemeData theme, UserGamificationStats stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.emoji_events_outlined,
            '${stats.challengesCompleted}',
            'التحديات',
            AppColors.tertiary,
          ),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          _buildStatItem(
            Icons.military_tech_outlined,
            '${stats.badgesEarned}',
            'الشارات',
            AppColors.primary,
          ),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          _buildStatItem(
            Icons.local_fire_department,
            '${stats.currentStreak}',
            'الأيام',
            AppColors.calories,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}