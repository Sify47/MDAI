// lib/widgets/ai_dashboard/challenges_card.dart
// 🏆 بطاقة التحديات والمكافآت

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/challenges_rewards_service.dart';
import '../../models/ai_models.dart';

class ChallengesCard extends StatefulWidget {
  const ChallengesCard({Key? key}) : super(key: key);

  @override
  State<ChallengesCard> createState() => ChallengesCardState();
}

class ChallengesCardState extends State<ChallengesCard> {
  List<NutritionChallenge> _activeChallenges = [];
  UserGamificationStats? _gamificationStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ChallengesRewardsService.getActiveChallenges(),
        ChallengesRewardsService.getGamificationStats(),
      ]);
      if (mounted) {
        setState(() {
          _activeChallenges = results[0] as List<NutritionChallenge>;
          _gamificationStats = results[1] as UserGamificationStats?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل التحديات';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.amber.shade900.withOpacity(0.3), Colors.orange.shade900.withOpacity(0.3)]
              : [Colors.amber.withOpacity(0.05), Colors.orange.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDark),
          const SizedBox(height: 16),
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_activeChallenges.isNotEmpty)
            ..._activeChallenges.take(2).map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildChallengeItem(c, theme, isDark),
            ))
          else
            _buildEmptyState(theme, isDark),
          if (_gamificationStats != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildGamificationBar(theme, isDark),
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
            color: Colors.amber.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          '🏆 التحديات',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (_activeChallenges.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_activeChallenges.length} نشط',
              style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? '',
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: loadData,
            child: const Icon(Icons.refresh, color: AppColors.danger, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text('📋', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            'ابدأ تحدياً جديداً!',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'اختر تحدياً من المكتبة لبدء رحلتك',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeItem(NutritionChallenge challenge, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: challenge.difficultyColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(challenge.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  challenge.title,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: challenge.difficultyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  challenge.difficulty.name,
                  style: TextStyle(fontSize: 9, color: challenge.difficultyColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (challenge.progress > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: challenge.progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: challenge.difficultyColor.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(challenge.difficultyColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  challenge.progressLabel,
                  style: TextStyle(fontSize: 10, color: challenge.difficultyColor),
                ),
                const Spacer(),
                Text(
                  challenge.remainingLabel,
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Icon(Icons.stars, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${challenge.xpReward} XP', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(challenge.remainingLabel, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGamificationBar(ThemeData theme, bool isDark) {
    final stats = _gamificationStats!;
    final currentLevel = stats.currentLevel;
    final nextLevelAt = stats.xpToNextLevel;
    final totalXp = stats.totalXp;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text('Lv.$currentLevel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$totalXp XP', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    if (nextLevelAt > 0)
                      Text('المستوى ${currentLevel + 1}', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
                if (nextLevelAt > 0) ...[
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (totalXp / nextLevelAt).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: Colors.amber.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}