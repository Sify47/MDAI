// lib/widgets/animated_activities_card.dart

import 'package:flutter/material.dart';
import '../constants/design_constants.dart';
import '../models/activity_model.dart';

class AnimatedActivitiesCard extends StatefulWidget {
  final List<Activity> activities;

  const AnimatedActivitiesCard({Key? key, required this.activities})
    : super(key: key);

  @override
  State<AnimatedActivitiesCard> createState() => _AnimatedActivitiesCardState();
}

class _AnimatedActivitiesCardState extends State<AnimatedActivitiesCard>
    with TickerProviderStateMixin {
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;

  int get total => widget.activities.length;
  int get completed => widget.activities.where((a) => a.isCompleted).length;
  double get completionRate => total == 0 ? 0 : completed / total;

  @override
  void initState() {
    super.initState();

    _itemControllers = List.generate(
      widget.activities.take(3).length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + (index * 100)),
      ),
    );

    _itemAnimations = _itemControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    }).toList();

    for (var i = 0; i < _itemControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedActivities = widget.activities.take(3).toList();

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
              boxShadow: DesignConstants.cardShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: DesignConstants.edgeInsetsCompact,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: DesignConstants.borderRadiusItem,
                          ),
                          child: Icon(
                            Icons.list_alt,
                            color: theme.colorScheme.primary,
                            size: DesignConstants.iconLarge - 6,
                          ),
                        ),
                        const SizedBox(width: DesignConstants.spacingMd),
                        Text(
                          '📋 أنشطة اليوم',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (total > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.paddingItem,
                          vertical: DesignConstants.paddingCompact,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: DesignConstants.borderRadiusFeatured,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: DesignConstants.iconSmall - 2,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: DesignConstants.spacingXs + 2),
                            Text(
                              '$completed/$total',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: DesignConstants.fontMd,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DesignConstants.spacingLg),

                if (total > 0) ...[
                  ClipRRect(
                    borderRadius: DesignConstants.borderRadiusSmall,
                    child: LinearProgressIndicator(
                      value: completionRate,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingLg),
                ],

                if (widget.activities.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignConstants.spacingXxl + 8,
                      ),
                      child: Column(
                        children: [
                          DesignConstants.emptyStateIcon(
                            context,
                            icon: Icons.event_busy_outlined,
                            size: 56,
                          ),
                          const SizedBox(height: DesignConstants.spacingMd),
                          Text(
                            'لا توجد أنشطة اليوم',
                            style: DesignConstants.emptyStateTitleStyle(context),
                          ),
                          const SizedBox(height: DesignConstants.spacingSm),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add, size: DesignConstants.iconSmall),
                            label: const Text('إضافة نشاط جديد'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(displayedActivities.length, (index) {
                    final activity = displayedActivities[index];
                    final isCompleted = activity.isCompleted;

                    return AnimatedBuilder(
                      animation: _itemAnimations[index],
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _itemAnimations[index],
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              15 * (1 - _itemAnimations[index].value),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: DesignConstants.spacingMd,
                              ),
                              child: Container(
                                padding: DesignConstants.edgeInsetsHorizontalItem,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? theme.colorScheme.primary.withOpacity(
                                          0.05,
                                        )
                                      : theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.5),
                                  borderRadius: DesignConstants.borderRadiusItem,
                                  border: Border.all(
                                    color: isCompleted
                                        ? theme.colorScheme.primary.withOpacity(
                                            0.2,
                                          )
                                        : theme.colorScheme.outline.withOpacity(
                                            0.1,
                                          ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isCompleted
                                            ? theme.colorScheme.primary
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isCompleted
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.outline,
                                          width: 1.8,
                                        ),
                                      ),
                                      child: isCompleted
                                          ? const Icon(
                                              Icons.check,
                                              size: DesignConstants.iconSmall,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: DesignConstants.spacingMd + 2),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activity.title,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  decoration: isCompleted
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                  color: isCompleted
                                                      ? theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withOpacity(0.5)
                                                      : null,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (activity.description.isNotEmpty)
                                            Text(
                                              activity.description,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.5),
                                                    fontSize: DesignConstants.fontSm,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: DesignConstants.borderRadiusCard,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: DesignConstants.fontXs,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.5),
                                          ),
                                          const SizedBox(width: DesignConstants.spacingXs),
                                          Text(
                                            '${activity.startTime.hour.toString().padLeft(2, '0')}:${activity.startTime.minute.toString().padLeft(2, '0')}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  fontSize: DesignConstants.fontSm,
                                                  fontWeight: FontWeight.w500,
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
                        );
                      },
                    );
                  }),

                if (widget.activities.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: DesignConstants.spacingMd),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.9, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DesignConstants.paddingCard,
                                  vertical: DesignConstants.paddingCompact,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: DesignConstants.borderRadiusButton,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+ ${widget.activities.length - 3} أنشطة أخرى',
                                    style: TextStyle(
                                      fontSize: DesignConstants.fontMd - 1,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: DesignConstants.spacingXs + 2),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: DesignConstants.fontMd - 1,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
