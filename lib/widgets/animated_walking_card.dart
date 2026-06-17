import 'package:flutter/material.dart';
import 'package:vita/models/nutrition_model.dart';
import 'package:vita/screens/walking/add_walking_activity.dart';
import 'package:vita/screens/walking/walking_dashboard.dart';
import 'package:vita/utils/prefs_helper.dart';
import '../models/dashboard_model.dart';
import '../constants/colors.dart';
import '../constants/design_constants.dart';

class AnimatedWalkingCard extends StatefulWidget {
  final WalkingData walking;
  final UserNutritionData userData;
  final VoidCallback? onRefresh;

  const AnimatedWalkingCard({
    Key? key,
    required this.walking,
    required this.userData,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<AnimatedWalkingCard> createState() => _AnimatedWalkingCardState();
}

class _AnimatedWalkingCardState extends State<AnimatedWalkingCard>
    with TickerProviderStateMixin {
  late AnimationController _stepsController;
  late Animation<int> _stepsAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _cardAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _stepsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _stepsAnimation = IntTween(begin: 0, end: widget.walking.steps).animate(
      CurvedAnimation(parent: _stepsController, curve: Curves.easeOutCubic),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _progressAnimation =
        Tween<double>(begin: 0, end: widget.walking.percentage / 100).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );

    _cardController.forward();
    _stepsController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _stepsController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userData = PrefsHelper.getUserData();
    final goalSteps = userData['dailyStepsGoal'] ?? 8000;
    final stepsPercentage = widget.walking.steps / goalSteps;

    return ScaleTransition(
      scale: _cardAnimation,
      child: Container(
        padding: DesignConstants.edgeInsetsCard,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: DesignConstants.borderRadiusCard,
          boxShadow: DesignConstants.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: DesignConstants.edgeInsetsCompact,
                  decoration: BoxDecoration(
                    color: AppColors.walking.withOpacity(0.1),
                    borderRadius: DesignConstants.borderRadiusSmall,
                  ),
                  child: const Text('🏃', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: DesignConstants.spacingMd),
                Text(
                  'نشاط المشي اليوم',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.paddingItem,
                    vertical: DesignConstants.paddingCompact - 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.walking.withOpacity(0.1),
                    borderRadius: DesignConstants.borderRadiusButton,
                  ),
                  child: Text(
                    'الهدف ${goalSteps ~/ 1000}ألف',
                    style: TextStyle(
                      fontSize: DesignConstants.fontXs,
                      color: AppColors.walking,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingXl),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnimatedStat(
                  context,
                  '👣',
                  _stepsAnimation,
                  'خطوة',
                  theme,
                ),
                _buildPulseStat(
                  context,
                  '🔥',
                  '${widget.walking.caloriesBurned}',
                  'سعرة',
                  AppColors.walking,
                ),
                _buildPulseStat(
                  context,
                  '📏',
                  '${widget.walking.distanceKm}',
                  'كم',
                  theme.colorScheme.secondary,
                ),
                _buildPulseStat(
                  context,
                  '⏱️',
                  '${widget.walking.durationMin}',
                  'دقيقة',
                  theme.colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingXl),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تقدم الهدف',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Text(
                          '${(_progressAnimation.value * 100).round()}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.walking,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: DesignConstants.spacingSm),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: DesignConstants.borderRadiusSmall,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.walking,
                                  AppColors.walking.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: DesignConstants.borderRadiusSmall,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: DesignConstants.spacingMd),

                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.walking.steps} / $goalSteps خطوة',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignConstants.paddingCompact,
                            vertical: DesignConstants.paddingCompact - 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.walking.withOpacity(0.1),
                            borderRadius: DesignConstants.borderRadiusItem,
                          ),
                          child: Text(
                            '${(stepsPercentage * 100).round()}%',
                            style: TextStyle(
                              fontSize: DesignConstants.fontXs,
                              color: AppColors.walking,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: DesignConstants.spacingMd),

                Container(
                  padding: DesignConstants.edgeInsetsItem,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: DesignConstants.borderRadiusSmall,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: DesignConstants.iconSmall,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: DesignConstants.spacingSm),
                      Text(
                        'آخر نشاط: ${widget.walking.lastActivity.type} - ${widget.walking.lastActivity.time}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingLg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.add,
                  label: 'إضافة نشاط',
                  color: AppColors.walking,
                  filled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddWalkingActivity(),
                      ),
                    ).then((_) {
                      if (widget.onRefresh != null) {
                        widget.onRefresh!();
                      }
                    });
                  },
                ),
                _buildActionButton(
                  context,
                  label: 'الإحصائيات',
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  filled: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WalkingDashboard(userData: widget.userData),
                      ),
                    ).then((_) {
                      if (widget.onRefresh != null) {
                        widget.onRefresh!();
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStat(
    BuildContext context,
    String icon,
    Animation<int> animation,
    String label,
    ThemeData theme,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: DesignConstants.spacingSm - 2),
            Text(
              animation.value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: DesignConstants.fontXl,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPulseStat(
    BuildContext context,
    String icon,
    String value,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: DesignConstants.spacingSm - 2),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: DesignConstants.fontXl,
                  color: color,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    IconData? icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: filled
              ? ElevatedButton.icon(
                  onPressed: onTap,
                  icon: icon != null
                      ? Icon(icon, size: DesignConstants.iconSmall)
                      : const SizedBox.shrink(),
                  label: Text(label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.paddingCard,
                      vertical: DesignConstants.paddingItem,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignConstants.borderRadiusButton,
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: onTap,
                  icon: icon != null
                      ? Icon(icon, size: DesignConstants.iconSmall)
                      : const SizedBox.shrink(),
                  label: Text(label),
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.paddingCard,
                      vertical: DesignConstants.paddingItem,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
