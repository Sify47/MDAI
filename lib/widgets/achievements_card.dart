import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../constants/colors.dart';
import '../constants/design_constants.dart';

class AchievementsCard extends StatelessWidget {
  final List<Achievement> achievements;

  const AchievementsCard({Key? key, required this.achievements})
    : super(key: key);

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

    return Container(
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
              if (achievements.isNotEmpty)
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
                    '${achievements.length} إنجاز',
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
          if (achievements.isEmpty)
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
                    const SizedBox(height: 8),
                    Text(
                      'ابدأ رحلتك وحقق أهدافك!',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...achievements.asMap().entries.map((entry) {
              final index = entry.key;
              final achievement = entry.value;
              final color = _getTypeColor(achievement.type, context);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, opacity, child) {
                  return FadeTransition(
                    opacity: AlwaysStoppedAnimation(opacity),
                    child: Transform.translate(
                      offset: Offset(-20 * (1 - opacity), 0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: DesignConstants.edgeInsetsHorizontalItem,
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
                },
              );
            }),
        ],
      ),
    );
  }
}
