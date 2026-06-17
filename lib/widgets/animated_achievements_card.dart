import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../constants/colors.dart';
import '../constants/design_constants.dart';

class AnimatedAchievementsCard extends StatefulWidget {
  final List<Achievement> achievements;

  const AnimatedAchievementsCard({Key? key, required this.achievements})
    : super(key: key);

  @override
  State<AnimatedAchievementsCard> createState() =>
      _AnimatedAchievementsCardState();
}

class _AnimatedAchievementsCardState extends State<AnimatedAchievementsCard>
    with TickerProviderStateMixin {
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();

    _itemControllers = List.generate(
      widget.achievements.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500 + (index * 100)),
      ),
    );

    _fadeAnimations = _itemControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    }).toList();

    _slideAnimations = _itemControllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    for (var i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _itemControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Color _getTypeColor(String type, BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case 'success':
        return theme.colorScheme.primary;
      case 'warning':
        return AppColors.warning;
      case 'danger':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.secondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.emoji_events;
      case 'warning':
        return Icons.priority_high;
      case 'danger':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: DesignConstants.edgeInsetsCard,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: DesignConstants.borderRadiusCard,
              boxShadow: DesignConstants.lightCardShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: DesignConstants.borderRadiusSmall,
                      ),
                      child: const Text('🏆', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'إنجازاتك اليوم',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (widget.achievements.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: DesignConstants.borderRadiusButton,
                        ),
                        child: Text(
                          '${widget.achievements.length} إنجاز',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DesignConstants.spacingLg),
                if (widget.achievements.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          DesignConstants.emptyStateIcon(context,
                              icon: Icons.emoji_events_outlined, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد إنجازات اليوم',
                            style: DesignConstants.emptyStateTitleStyle(context),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(widget.achievements.length, (index) {
                    final achievement = widget.achievements[index];
                    final color = _getTypeColor(achievement.type, context);

                    return FadeTransition(
                      opacity: _fadeAnimations[index],
                      child: SlideTransition(
                        position: _slideAnimations[index],
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: DesignConstants.edgeInsetsItem,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: DesignConstants.borderRadiusSmall,
                              border: Border.all(
                                color: color.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getTypeIcon(achievement.type),
                                    color: color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    achievement.text,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (achievement.type == 'success')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '+10',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
