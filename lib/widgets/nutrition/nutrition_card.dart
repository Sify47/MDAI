// lib/widgets/nutrition/nutrition_card.dart
// Reusable card wrapper used across all nutrition screens

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class NutritionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? margin;
  final Border? border;

  const NutritionCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.gradient,
    this.boxShadow,
    this.margin,
    this.border,
  });

  /// Default card with standard shadow and card color
  factory NutritionCard.defaultStyle({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return NutritionCard(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      child: child,
    );
  }

  /// Gradient card with primary-to-success gradient (for summary cards)
  factory NutritionCard.gradient({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return NutritionCard(
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.success],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: child,
    );
  }

  /// Tips card with light gradient border
  factory NutritionCard.tips({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color accentColor = AppColors.primary,
  }) {
    return NutritionCard(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      gradient: LinearGradient(
        colors: [accentColor.withOpacity(0.05), accentColor.withOpacity(0.02)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      border: Border.all(color: accentColor.withOpacity(0.3)),
      child: child,
    );
  }

  /// Card with no shadow (for surface-container styling)
  factory NutritionCard.flat({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
  }) {
    return NutritionCard(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      backgroundColor: backgroundColor,
      boxShadow: [],
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient != null ? null : (backgroundColor ?? theme.cardColor),
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? 20),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
        border: border,
      ),
      child: child,
    );
  }
}
