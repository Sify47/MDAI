// lib/widgets/analytics/animated_stat_card.dart

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/design_constants.dart';

class AnimatedStatCard extends StatefulWidget {
  final String title;
  final String icon;
  final String value;
  final String subtitle;
  final int percentage;
  final Color color;
  final VoidCallback? onTap;
  final bool showTrend;
  final double trendValue; // قيمة الاتجاه (موجب = زيادة، سالب = نقصان)
  final String? additionalInfo;

  const AnimatedStatCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.value,
    required this.subtitle,
    required this.percentage,
    required this.color,
    this.onTap,
    this.showTrend = false,
    this.trendValue = 0,
    this.additionalInfo,
  }) : super(key: key);

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _valueAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _progressAnimation = Tween<double>(begin: 0, end: widget.percentage / 100)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _valueAnimation = Tween<double>(begin: 0, end: double.tryParse(widget.value) ?? 0)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getFormattedValue() {
    if (widget.value.contains('%') || widget.value.contains('.')) {
      return widget.value;
    }
    final numericValue = double.tryParse(widget.value);
    if (numericValue != null && numericValue > 999) {
      if (numericValue > 999999) {
        return '${(numericValue / 1000000).toStringAsFixed(1)}M';
      }
      return '${(numericValue / 1000).toStringAsFixed(1)}K';
    }
    return widget.value;
  }

  Widget _buildTrendIndicator() {
    if (!widget.showTrend) return const SizedBox();

    final isPositive = widget.trendValue > 0;
    final trendPercent = widget.trendValue.abs();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isPositive ? AppColors.success : AppColors.danger).withOpacity(0.1),
        borderRadius: DesignConstants.borderRadiusButton,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: isPositive ? AppColors.success : AppColors.danger,
          ),
          const SizedBox(width: 2),
          Text(
            '${trendPercent.round()}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: DesignConstants.edgeInsetsCard,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.cardColor,
                  isDark
                      ? theme.cardColor
                      : widget.color.withOpacity(0.02),
                ],
              ),
              borderRadius: DesignConstants.borderRadiusCard,
              boxShadow: DesignConstants.cardShadow(context),
              border: Border.all(
                color: widget.color.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الرأس مع الأيقونة والعنوان
                Row(
                  children: [
                    // أيقونة متحركة
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color,
                            widget.color.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: DesignConstants.borderRadiusItem,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.icon,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                              fontSize: DesignConstants.fontSm,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          _buildTrendIndicator(),
                        ],
                      ),
                    ),
                    // شارة النسبة المئوية
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: DesignConstants.borderRadiusButton,
                        border: Border.all(
                          color: widget.color.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '${widget.percentage}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DesignConstants.spacingLg),

                // القيمة مع تأثير العداد
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedBuilder(
                      animation: _valueAnimation,
                      builder: (context, child) {
                        String displayValue = _getFormattedValue();
                        if (displayValue != widget.value) {
                          return Text(
                            displayValue,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: widget.color,
                              height: 1,
                            ),
                          );
                        }
                        return Text(
                          _valueAnimation.value.toInt().toString(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                            height: 1,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: DesignConstants.spacingMd),

                // معلومات إضافية
                if (widget.additionalInfo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      widget.additionalInfo!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),

                // شريط التقدم المتحرك
                Stack(
                  children: [
                    Container(
                      height: 8,
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
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.color,
                                  widget.color.withOpacity(0.6),
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

                const SizedBox(height: DesignConstants.spacingSm),

                // النسبة المئوية والهدف
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.color.withOpacity(0.1),
                            borderRadius: DesignConstants.borderRadiusButton,
                          ),
                          child: Text(
                            '${(_progressAnimation.value * 100).round()}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: widget.color,
                            ),
                          ),
                        );
                      },
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'هدف ${widget.percentage}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // إضافة تأثير نبض عند الاقتراب من الهدف
                if (widget.percentage >= 80 && widget.percentage < 100)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: DesignConstants.borderRadiusButton,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'قريب من الهدف!',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (widget.percentage >= 100)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: DesignConstants.borderRadiusButton,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 12,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'تم تحقيق الهدف! 🎉',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ نسخة مبسطة مع تأثيرات أقل (للاستخدام في القوائم)
class CompactAnimatedStatCard extends StatelessWidget {
  final String title;
  final String icon;
  final String value;
  final Color color;
  final int percentage;
  final VoidCallback? onTap;

  const CompactAnimatedStatCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.value,
    required this.color,
    required this.percentage,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: DesignConstants.edgeInsetsItem,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: DesignConstants.borderRadiusCard,
          boxShadow: DesignConstants.lightCardShadow(context),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: DesignConstants.borderRadiusItem,
              ),
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                DesignConstants.buildTag(
                  text: '$percentage%',
                  color: color,
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: color,
                  minHeight: 3,
                  // width: 50,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}