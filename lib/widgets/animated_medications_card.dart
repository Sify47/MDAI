import 'package:flutter/material.dart';
import 'package:vita/screens/medications/add_medication_screen.dart';
import 'package:vita/screens/medications/medications_dashboard.dart';
import '../models/dashboard_model.dart';
import '../constants/colors.dart';
import '../constants/design_constants.dart';

class AnimatedMedicationsCard extends StatefulWidget {
  final MedicationsData medications;

  const AnimatedMedicationsCard({Key? key, required this.medications})
    : super(key: key);

  @override
  State<AnimatedMedicationsCard> createState() =>
      _AnimatedMedicationsCardState();
}

class _AnimatedMedicationsCardState extends State<AnimatedMedicationsCard>
    with TickerProviderStateMixin {
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;
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

    _itemControllers = List.generate(
      widget.medications.list.length,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + (index * 100)),
      ),
    );

    _itemAnimations = _itemControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);
    }).toList();

    _cardController.forward();

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
    _cardController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Color _getStatusColor(String status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case 'taken':
        return theme.colorScheme.primary.withOpacity(0.1);
      case 'pending':
        return AppColors.warning.withOpacity(0.1);
      case 'missed':
        return theme.colorScheme.error.withOpacity(0.1);
      default:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'taken':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'missed':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusIconColor(String status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case 'taken':
        return theme.colorScheme.primary;
      case 'pending':
        return AppColors.warning;
      case 'missed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  String _getStatusText(Medication med) {
    if (med.status == 'taken') return 'تم';
    if (med.status == 'pending' && med.hoursRemaining != null) {
      return '⏰ ${med.hoursRemaining} س';
    }
    return 'متبقي';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final takenCount = widget.medications.taken;
    final totalCount = widget.medications.totalToday;
    final completionRate = totalCount > 0 ? takenCount / totalCount : 0;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: DesignConstants.edgeInsetsCompact,
                      decoration: BoxDecoration(
                        color: AppColors.medications.withOpacity(0.1),
                        borderRadius: DesignConstants.borderRadiusItem,
                      ),
                      child: const Text('💊', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: DesignConstants.spacingMd),
                    Text(
                      'أدوية اليوم',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignConstants.paddingItem,
                    vertical: DesignConstants.paddingCompact - 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.medications.withOpacity(0.1),
                    borderRadius: DesignConstants.borderRadiusFeatured,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: DesignConstants.iconSmall,
                        color: AppColors.medications,
                      ),
                      SizedBox(width: DesignConstants.spacingSm - 2),
                      Text(
                        '$takenCount/$totalCount',
                        style: TextStyle(
                          fontSize: DesignConstants.fontMd,
                          fontWeight: FontWeight.bold,
                          color: AppColors.medications,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingMd),

            if (totalCount > 0) ...[
              ClipRRect(
                borderRadius: DesignConstants.borderRadiusSmall,
                child: LinearProgressIndicator(
                  value: completionRate as double,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.medications,
                  ),
                ),
              ),
              const SizedBox(height: DesignConstants.spacingLg),
            ],

            if (widget.medications.list.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      DesignConstants.emptyStateIcon(
                        context,
                        icon: Icons.medication_outlined,
                        size: 56,
                      ),
                      const SizedBox(height: DesignConstants.spacingMd),
                      Text(
                        'لا توجد أدوية اليوم',
                        style: DesignConstants.emptyStateTitleStyle(context),
                      ),
                      const SizedBox(height: DesignConstants.spacingSm),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddMedicationScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: DesignConstants.iconSmall),
                        label: const Text('إضافة دواء جديد'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.medications,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(widget.medications.list.length, (index) {
                final med = widget.medications.list[index];
                final statusColor = _getStatusIconColor(med.status, context);
                final bgColor = _getStatusColor(med.status, context);

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
                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: DesignConstants.spacingSm,
                          ),
                          padding: DesignConstants.edgeInsetsItem,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: DesignConstants.borderRadiusItem,
                            border: Border.all(
                              color: statusColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: DesignConstants.edgeInsetsCompact,
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(med.status),
                                  color: statusColor,
                                  size: DesignConstants.iconMedium,
                                ),
                              ),
                              const SizedBox(width: DesignConstants.spacingMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${med.name} ${med.dose}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: DesignConstants.spacingXs),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: DesignConstants.iconSmall,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(width: DesignConstants.spacingXs),
                                        Text(
                                          med.time,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.6),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: DesignConstants.paddingItem,
                                        vertical: DesignConstants.paddingCompact - 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: DesignConstants.borderRadiusButton,
                                      ),
                                      child: Text(
                                        _getStatusText(med),
                                        style: TextStyle(
                                          fontSize: DesignConstants.fontSm,
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            const SizedBox(height: DesignConstants.spacingLg),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedButton(
                  context,
                  icon: Icons.add,
                  label: 'إضافة دواء',
                  color: AppColors.medications,
                  filled: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddMedicationScreen(),
                      ),
                    );
                  },
                ),
                _buildAnimatedButton(
                  context,
                  label: 'كل الأدوية',
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  filled: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicationsDashboard(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedButton(
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
                  label: Text(label, style: const TextStyle(fontSize: DesignConstants.fontSm)),
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
                  label: Text(label, style: const TextStyle(fontSize: DesignConstants.fontSm)),
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
