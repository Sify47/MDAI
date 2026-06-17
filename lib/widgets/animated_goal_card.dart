// lib/widgets/animated_goal_card.dart

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/design_constants.dart';
import '../models/dashboard_model.dart';

class AnimatedGoalCard extends StatelessWidget {
  final ProgressData progress;
  final UserData user;
  final double expectedWeightChange;
  final double predictedWeight;
  final String progressMessage;

  // ✅ حقول المقارنة
  final double? expectedWeightFromCalories;
  final double? weightDifference;
  final String? weightAdvice;

  const AnimatedGoalCard({
    Key? key,
    required this.progress,
    required this.user,
    this.expectedWeightChange = 0,
    this.predictedWeight = 0,
    this.progressMessage = '',
    this.expectedWeightFromCalories,
    this.weightDifference,
    this.weightAdvice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoss = user.goalType == 'تخسيس';
    final isDark = theme.brightness == Brightness.dark;
    final remainingText = isLoss ? 'المتبقي للخسارة' : 'المتبقي للزيادة';
    final remainingValue = isLoss
        ? progress.remainingWeight
        : progress.remainingToGain;

    // ألوان متكيفة مع الوضع
    final cardBgColor = isDark
        ? theme.colorScheme.surface.withOpacity(0.05)
        : theme.colorScheme.surface;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? Colors.white70
        : AppColors.textSecondary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacity)),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: DesignConstants.borderRadiusFeatured,
              ),
              color: cardBgColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========== الهيدر ==========
                  _buildHeader(isLoss, isDark),

                  // ========== الأوزان (الحالي والمستهدف) ==========
                  _buildWeightSection(
                    isLoss,
                    textColor,
                    textSecondaryColor,
                    isDark,
                  ),

                  // ========== المتبقي ==========
                  _buildRemainingSection(
                    isLoss,
                    remainingText,
                    remainingValue,
                    textColor,
                    textSecondaryColor,
                    isDark,
                  ),

                  // ========== شريط التقدم ==========
                  _buildProgressSection(textColor, textSecondaryColor),

                  SizedBox(height: DesignConstants.spacingSm),

                  // ========== ✅ مقارنة الوزن (المسجل vs المتوقع) ==========
                  if (expectedWeightFromCalories != null)
                    _buildWeightComparisonSection(textColor, isDark),

                  SizedBox(height: DesignConstants.spacingSm),


                  // ========== رسالة التقدم ==========
                  if (progressMessage.isNotEmpty)
                    _buildProgressMessageSection(),

                  
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // الهيدر
  // ============================================
  Widget _buildHeader(bool isLoss, bool isDark) {
    return Container(
      padding: DesignConstants.edgeInsetsExtraWide,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLoss
              ? [AppColors.primary, AppColors.success]
              : [AppColors.warning, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DesignConstants.radiusFeatured),
          topRight: Radius.circular(DesignConstants.radiusFeatured),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: DesignConstants.edgeInsetsCompact,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: DesignConstants.borderRadiusCard,
            ),
            child: Icon(
              isLoss ? Icons.emoji_events : Icons.fitness_center,
              color: Colors.white,
              size: DesignConstants.iconMedium,
            ),
          ),
          const SizedBox(width: DesignConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoss ? 'رحلة التخسيس' : 'رحلة زيادة الوزن',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: DesignConstants.fontXxl,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: DesignConstants.spacingXs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.paddingCompact,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: DesignConstants.borderRadiusButton,
                  ),
                  child: Text(
                    '${progress.percentage}% مكتمل',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: DesignConstants.fontSm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // قسم الأوزان
  // ============================================
  Widget _buildWeightSection(
    bool isLoss,
    Color textColor,
    Color textSecondaryColor,
    bool isDark,
  ) {
    return Padding(
      padding: DesignConstants.edgeInsetsCard,
      child: Row(
        children: [
          Expanded(
            child: _buildWeightCard(
              title: 'الوزن الحالي',
              weight: user.currentWeight,
              icon: Icons.monitor_weight,
              color: AppColors.primary,
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: DesignConstants.spacingMd),
          Expanded(
            child: _buildWeightCard(
              title: 'الوزن المستهدف',
              weight: user.targetWeight,
              icon: Icons.flag,
              color: AppColors.success,
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightCard({
    required String title,
    required int weight,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color textSecondaryColor,
    required bool isDark,
  }) {
    return Container(
      padding: DesignConstants.edgeInsetsItem,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : AppColors.background,
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: DesignConstants.iconLarge - 6),
          const SizedBox(height: DesignConstants.spacingSm),
          Text(
            title,
            style: TextStyle(color: textSecondaryColor, fontSize: DesignConstants.fontSm),
          ),
          const SizedBox(height: DesignConstants.spacingXs),
          Text(
            '$weight',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text('كجم', style: TextStyle(fontSize: DesignConstants.fontXs)),
        ],
      ),
    );
  }

  // ============================================
  // قسم المتبقي
  // ============================================
  Widget _buildRemainingSection(
    bool isLoss,
    String remainingText,
    int remainingValue,
    Color textColor,
    Color textSecondaryColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.paddingCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: DesignConstants.paddingCard, vertical: DesignConstants.paddingItem),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.background,
          borderRadius: DesignConstants.borderRadiusCard,
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: DesignConstants.edgeInsetsCompact,
              decoration: BoxDecoration(
                color: (isLoss ? AppColors.success : AppColors.warning)
                    .withOpacity(0.15),
                borderRadius: DesignConstants.borderRadiusItem,
              ),
              child: Icon(
                isLoss ? Icons.trending_down : Icons.trending_up,
                color: isLoss ? AppColors.success : AppColors.warning,
                size: DesignConstants.iconLarge - 6,
              ),
            ),
            const SizedBox(width: DesignConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    remainingText,
                    style: TextStyle(color: textSecondaryColor, fontSize: DesignConstants.fontMd),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$remainingValue كجم',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (progress.weeksRemaining > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.paddingItem,
                  vertical: DesignConstants.paddingCompact,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: DesignConstants.borderRadiusCard,
                ),
                child: Column(
                  children: [
                    Text(
                      '${progress.weeksRemaining}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: DesignConstants.fontXxl,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'أسبوع',
                      style: TextStyle(color: textSecondaryColor, fontSize: DesignConstants.fontXs),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // شريط التقدم
  // ============================================
  Widget _buildProgressSection(Color textColor, Color textSecondaryColor) {
    return Padding(
      padding: DesignConstants.edgeInsetsCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🎯 التقدم نحو الهدف',
                style: TextStyle(color: textSecondaryColor, fontSize: DesignConstants.fontMd),
              ),
              Text(
                '${progress.percentage}%',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: DesignConstants.fontLg,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingSm),
          ClipRRect(
            borderRadius: DesignConstants.borderRadiusSmall,
            child: LinearProgressIndicator(
              value: progress.percentage / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ✅ مقارنة الوزن (المسجل vs المتوقع من السعرات)
  // ============================================
  Widget _buildWeightComparisonSection(Color textColor, bool isDark) {
    final isAchieving = (weightDifference ?? 0) <= 0;
    final comparisonColor = isAchieving ? AppColors.success : AppColors.warning;
    final expectedWeight = expectedWeightFromCalories ?? 0;
    final diff = (weightDifference ?? 0).abs();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.paddingCard),
      child: Container(
        padding: DesignConstants.edgeInsetsCard,
        decoration: BoxDecoration(
          color: comparisonColor.withOpacity(0.1),
          borderRadius: DesignConstants.borderRadiusCard,
          border: Border.all(color: comparisonColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: DesignConstants.edgeInsetsCompact,
                  decoration: BoxDecoration(
                    color: comparisonColor.withOpacity(0.2),
                    borderRadius: DesignConstants.borderRadiusSmall,
                  ),
                  child: Icon(
                    isAchieving ? Icons.check_circle : Icons.warning_amber,
                    color: comparisonColor,
                    size: DesignConstants.iconLarge - 8,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingMd),
                Text(
                  isAchieving ? '🎉 أنت متقدم عن المتوقع!' : '📊 مقارنة الوزن',
                  style: TextStyle(
                    color: textColor,
                    fontSize: DesignConstants.fontLg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingLg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '⚖️ الوزن المتوقع',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: DesignConstants.fontSm,
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingXs),
                      Text(
                        '${expectedWeight.toStringAsFixed(1)} كجم',
                        style: TextStyle(
                          color: comparisonColor,
                          fontSize: DesignConstants.fontXxl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '(من سعراتك ونشاطك)',
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: DesignConstants.fontXs - 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingSm),
                  padding: DesignConstants.edgeInsetsCompact,
                  decoration: BoxDecoration(
                    color: comparisonColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAchieving
                        ? Icons.compare_arrows
                        : Icons.compare_arrows_outlined,
                    color: comparisonColor,
                    size: DesignConstants.iconLarge - 8,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '🎯 الوزن المسجل',
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: DesignConstants.fontSm,
                        ),
                      ),
                      const SizedBox(height: DesignConstants.spacingXs),
                      Text(
                        '${user.currentWeight} كجم',
                        style: TextStyle(
                          color: isAchieving
                              ? AppColors.success
                              : AppColors.primary,
                          fontSize: DesignConstants.fontXxl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '(على الميزان)',
                        style: TextStyle(
                          color: textColor.withOpacity(0.5),
                          fontSize: DesignConstants.fontXs - 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignConstants.spacingMd),
            Container(
              padding: DesignConstants.edgeInsetsCompact,
              decoration: BoxDecoration(
                color: comparisonColor.withOpacity(0.15),
                borderRadius: DesignConstants.borderRadiusSmall,
              ),
              child: Row(
                children: [
                  Icon(
                    isAchieving ? Icons.celebration : Icons.info_outline,
                    size: DesignConstants.iconSmall + 2,
                    color: comparisonColor,
                  ),
                  const SizedBox(width: DesignConstants.spacingSm),
                  Expanded(
                    child: Text(
                      weightAdvice ??
                          (isAchieving
                              ? 'ممتاز! أنت متقدم ${diff.toStringAsFixed(1)} كجم عن الهدف'
                              : 'أنت متأخر ${diff.toStringAsFixed(1)} كجم عن الهدف، استمر في متابعة سعراتك'),
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                        fontSize: DesignConstants.fontMd,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  // ============================================
  // رسالة التقدم
  // ============================================
  Widget _buildProgressMessageSection() {
    final isPositive =
        progressMessage.contains('✅') || expectedWeightChange >= 0;
    final messageColor = isPositive ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignConstants.paddingCard,
        0,
        DesignConstants.paddingCard,
        DesignConstants.paddingCard,
      ),
      child: Container(
        padding: DesignConstants.edgeInsetsItem,
        decoration: BoxDecoration(
          color: messageColor.withOpacity(0.1),
          borderRadius: DesignConstants.borderRadiusCard,
          border: Border.all(color: messageColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignConstants.paddingCompact - 2),
              decoration: BoxDecoration(
                color: messageColor.withOpacity(0.2),
                borderRadius: DesignConstants.borderRadiusSmall,
              ),
              child: Icon(
                isPositive ? Icons.check_circle : Icons.warning_amber,
                color: messageColor,
                size: DesignConstants.iconSmall + 2,
              ),
            ),
            const SizedBox(width: DesignConstants.spacingSm),
            Expanded(
              child: Text(
                progressMessage,
                style: TextStyle(color: messageColor, fontSize: DesignConstants.fontMd),
              ),
            ),
          ],
        ),
      ),
    );
  }

  }
