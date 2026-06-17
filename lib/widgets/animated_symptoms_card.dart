// lib/widgets/animated_symptoms_card.dart

import 'package:flutter/material.dart';
import 'package:vita/models/nutrition_model.dart';
import 'package:vita/screens/symptoms/add_symptom_screen.dart';
import 'package:vita/services/nutrition_api.dart';
import '../models/dashboard_model.dart';
import '../constants/colors.dart';
import '../constants/design_constants.dart';

class AnimatedSymptomsCard extends StatefulWidget {
  final SymptomsData symptoms;

  const AnimatedSymptomsCard({Key? key, required this.symptoms})
    : super(key: key);

  @override
  State<AnimatedSymptomsCard> createState() => _AnimatedSymptomsCardState();
}

class _AnimatedSymptomsCardState extends State<AnimatedSymptomsCard>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _itemAnimations;
  UserNutritionData? _userNutritionData;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _cardAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _itemControllers = List.generate(
      widget.symptoms.latest.length,
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

  Future<void> _loadUserData() async {
    try {
      final userData = await NutritionService.getUserNutritionData();
      if (userData != null && mounted) {
        setState(() {
          _userNutritionData = userData;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
    }
  }

  Color _getSeverityColor(String severity, BuildContext context) {
    final theme = Theme.of(context);
    switch (severity) {
      case 'خفيف':
        return AppColors.success;
      case 'متوسط':
        return AppColors.warning;
      case 'شديد':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: DesignConstants.borderRadiusItem,
                      ),
                      child: const Text('🤒', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: DesignConstants.spacingMd),
                    Text(
                      'آخر الأعراض',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!widget.symptoms.newToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.paddingItem,
                      vertical: DesignConstants.paddingCompact - 3,
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
                          size: DesignConstants.iconSmall,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: DesignConstants.spacingSm - 2),
                        Text(
                          'لا توجد أعراض جديدة',
                          style: TextStyle(
                            fontSize: DesignConstants.fontSm,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingLg),

            if (widget.symptoms.latest.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      DesignConstants.emptyStateIcon(
                        context,
                        icon: Icons.medical_services_outlined,
                        size: 56,
                      ),
                      const SizedBox(height: DesignConstants.spacingMd),
                      Text(
                        'لا توجد أعراض مسجلة',
                        style: DesignConstants.emptyStateTitleStyle(context),
                      ),
                      const SizedBox(height: DesignConstants.spacingSm),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddSymptomScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: DesignConstants.iconSmall),
                        label: const Text('تسجيل عرض جديد'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(widget.symptoms.latest.length, (index) {
                final symptom = widget.symptoms.latest[index];
                final severityColor = _getSeverityColor(
                  symptom.severity,
                  context,
                );

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
                            bottom: DesignConstants.spacingMd,
                          ),
                          padding: DesignConstants.edgeInsetsItem,
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.08),
                            borderRadius: DesignConstants.borderRadiusItem,
                            border: Border.all(
                              color: severityColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: severityColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: severityColor.withOpacity(0.3),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: DesignConstants.spacingMd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      symptom.symptom,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: DesignConstants.spacingXs),
                                    Text(
                                      '${symptom.severity} • ${symptom.date}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (symptom.analyzed)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: DesignConstants.paddingItem,
                                    vertical: DesignConstants.paddingCompact - 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: DesignConstants.borderRadiusButton,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.analytics_outlined,
                                        size: DesignConstants.iconSmall,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: DesignConstants.spacingXs),
                                      Text(
                                        'تم التحليل',
                                        style: TextStyle(
                                          fontSize: DesignConstants.fontXs,
                                          color: theme.colorScheme.primary,
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
                    );
                  },
                );
              }),
            const SizedBox(height: DesignConstants.spacingMd),

            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddSymptomScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, size: DesignConstants.iconLarge),
                      label: const Text('تسجيل عرض جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignConstants.paddingExtraWide,
                          vertical: DesignConstants.paddingItem,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: DesignConstants.borderRadiusButton,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
