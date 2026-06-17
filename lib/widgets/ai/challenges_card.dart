// lib/widgets/ai/challenges_card.dart
// ITEM 5: Nutrition Challenges System UI

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/design_constants.dart';
import '../../models/ai_models.dart';
import '../../services/challenges_rewards_service.dart';
import '../nutrition/nutrition_card.dart';

/// A card displaying active nutrition challenges with progress tracking
class ChallengesCard extends StatefulWidget {
  const ChallengesCard({super.key});

  @override
  State<ChallengesCard> createState() => _ChallengesCardState();
}

class _ChallengesCardState extends State<ChallengesCard> {
  List<NutritionChallenge>? _activeChallenges;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final active = await ChallengesRewardsService.getActiveChallenges();

      if (!mounted) return;
      setState(() {
        _activeChallenges = active;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل في تحميل التحديات';
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
          else if (_activeChallenges == null || _activeChallenges!.isEmpty)
            _buildEmptyState(theme)
          else
            _buildChallengeList(theme),
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
            color: AppColors.tertiary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.emoji_events_outlined,
            color: AppColors.tertiary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '🏆 التحديات النشطة',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'عرض جميع التحديات',
          child: TextButton(
            onPressed: () {
              _showAllChallengesDialog();
            },
            child: const Text('عرض الكل'),
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
          color: AppColors.tertiary,
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
            onPressed: _loadChallenges,
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
          const Icon(Icons.emoji_events_outlined,
              size: 40, color: AppColors.info),
          const SizedBox(height: 8),
          Text(
            'لا توجد تحديات نشطة حالياً',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _startNewChallenge,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('بدء تحدي جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tertiary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeList(ThemeData theme) {
    return Column(
      children: _activeChallenges!.map((challenge) {
        return _buildChallengeItem(theme, challenge);
      }).toList(),
    );
  }

  Widget _buildChallengeItem(ThemeData theme, NutritionChallenge challenge) {
    final difficultyColor = _difficultyColor(challenge.difficulty);
    final categoryLabel = _categoryLabel(challenge.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: DesignConstants.borderRadiusItem,
        border: Border.all(
          color: difficultyColor.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(challenge.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      challenge.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.1),
                  borderRadius: DesignConstants.borderRadiusButton,
                ),
                child: Text(
                  categoryLabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: difficultyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: challenge.progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: difficultyColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                challenge.progress >= 1.0
                    ? AppColors.success
                    : difficultyColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${(challenge.progress * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: difficultyColor,
                ),
              ),
              const Spacer(),
              Text(
                '${challenge.xpReward} XP',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: AppColors.calories,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAllChallengesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AllChallengesSheet(),
    );
  }

  Future<void> _startNewChallenge() async {
    final library = ChallengesRewardsService.getChallengeLibrary();
    final available =
        library.where((c) => c.status == ChallengeStatus.notStarted).toList();

    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد تحديات متاحة حالياً')),
      );
      return;
    }

    if (!mounted) return;
    final picked = await showDialog<NutritionChallenge>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('اختر تحدياً'),
        children: available.map((c) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, c),
            child: ListTile(
              leading: Text(c.icon, style: const TextStyle(fontSize: 24)),
              title: Text(c.title),
              subtitle: Text('${c.xpReward} XP • ${c.durationDays} يوم'),
              dense: true,
            ),
          );
        }).toList(),
      ),
    );

    if (picked != null) {
      await ChallengesRewardsService.startChallenge(picked.id);
      _loadChallenges();
    }
  }

  Color _difficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return AppColors.success;
      case ChallengeDifficulty.medium:
        return AppColors.warning;
      case ChallengeDifficulty.hard:
        return AppColors.danger;
      case ChallengeDifficulty.expert:
        return const Color(0xFF9C27B0);
    }
  }

  String _categoryLabel(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.daily:
        return 'يومي';
      case ChallengeCategory.weekly:
        return 'أسبوعي';
      case ChallengeCategory.monthly:
        return 'شهري';
      case ChallengeCategory.special:
        return 'خاص';
    }
  }
}

/// Bottom sheet showing all challenges from the library
class _AllChallengesSheet extends StatefulWidget {
  @override
  State<_AllChallengesSheet> createState() => _AllChallengesSheetState();
}

class _AllChallengesSheetState extends State<_AllChallengesSheet> {
  List<NutritionChallenge>? _library;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lib = ChallengesRewardsService.getChallengeLibrary();
    final active = await ChallengesRewardsService.getActiveChallenges();
    final activeIds = active.map((c) => c.id).toSet();

    setState(() {
      _library = lib.map((c) {
        if (activeIds.contains(c.id)) {
          return c.copyWith(status: ChallengeStatus.inProgress);
        }
        return c;
      }).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '📋 جميع التحديات',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _library?.length ?? 0,
                    itemBuilder: (ctx, index) {
                      final c = _library![index];
                      final isActive =
                          c.status == ChallengeStatus.inProgress;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Text(c.icon,
                              style: const TextStyle(fontSize: 28)),
                          title: Text(c.title),
                          subtitle: Text(
                            '${c.xpReward} XP • ${c.durationDays} يوم',
                          ),
                          trailing: isActive
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'نشط',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () async {
                                    await ChallengesRewardsService
                                        .startChallenge(c.id);
                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('ابدأ'),
                                ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}