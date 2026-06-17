// lib/widgets/ai/ai_recommendation_card.dart
// ITEM 1 & 2: Smart Meal Recommendations + Dynamic Recipe Adaptation UI

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/design_constants.dart';
import '../../models/ai_models.dart';
import '../../services/ai_recommendation_service.dart';
import '../../services/nutrition_api.dart';
import '../nutrition/nutrition_card.dart';

/// A card that displays AI-powered meal recommendations with explanations
class AiRecommendationCard extends StatefulWidget {
  final String goal;
  final List<String> diseases;
  final List<String> preferences;
  final double targetCalories;
  final VoidCallback? onMealSelected;

  const AiRecommendationCard({
    super.key,
    required this.goal,
    required this.diseases,
    this.preferences = const [],
    required this.targetCalories,
    this.onMealSelected,
  });

  @override
  State<AiRecommendationCard> createState() => _AiRecommendationCardState();
}

class _AiRecommendationCardState extends State<AiRecommendationCard> {
  List<AiMealRecommendation>? _recommendations;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  MealTimeContext _getTimeContext() {
    final hour = DateTime.now().hour;
    if (hour < 11) return MealTimeContext.morning;
    if (hour < 14) return MealTimeContext.midday;
    if (hour < 18) return MealTimeContext.afternoon;
    if (hour < 21) return MealTimeContext.evening;
    return MealTimeContext.lateNight;
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to enrich context with actual user nutrition data
      final userData = await NutritionService.getUserNutritionData();
      final targetProtein = widget.targetCalories * 0.3 / 4; // ~30% protein
      final targetCarbs = widget.targetCalories * 0.45 / 4;  // ~45% carbs
      final targetFat = widget.targetCalories * 0.25 / 9;    // ~25% fat

      final context = RecommendationContext(
        timeContext: _getTimeContext(),
        currentCalories: 0,
        currentProtein: 0,
        currentCarbs: 0,
        currentFat: 0,
        targetCalories: widget.targetCalories,
        targetProtein: targetProtein,
        targetCarbs: targetCarbs,
        targetFat: targetFat,
        diseases: widget.diseases,
        goal: widget.goal,
        recentlyEatenMeals: {},
        avoidedFoods: widget.preferences.where((p) => p.startsWith('تجنب')).toSet(),
        preferredCuisines: widget.preferences.where((p) => !p.startsWith('تجنب')).toSet(),
        waterIntake: (userData?.waterIntake ?? 0).round(),
        todayMealTypes: const [],
      );

      final recs = await AiRecommendationService.getSmartRecommendations(
        context: context,
        maxResults: 5,
      );

      if (!mounted) return;
      setState(() {
        _recommendations = recs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل في تحميل التوصيات';
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
            _buildLoadingState(theme)
          else if (_error != null)
            _buildErrorState(theme)
          else if (_recommendations == null || _recommendations!.isEmpty)
            _buildEmptyState(theme)
          else
            _buildRecommendationsList(theme),
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
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_awesome,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '🤖 توصيات الذكاء الاصطناعي',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'تحديث التوصيات',
          child: IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadRecommendations,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.05),
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadRecommendations,
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
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'قم بتسجيل وجبات اليوم أولاً للحصول على توصيات مخصصة',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList(ThemeData theme) {
    return Column(
      children: _recommendations!.map((rec) {
        return _buildRecommendationItem(theme, rec);
      }).toList(),
    );
  }

  Widget _buildRecommendationItem(
    ThemeData theme,
    AiMealRecommendation rec,
  ) {
    // Determine color scheme based on relevance score
    final scoreColor = rec.relevanceScore >= 0.8
        ? AppColors.success
        : rec.relevanceScore >= 0.5
            ? AppColors.warning
            : AppColors.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: DesignConstants.borderRadiusItem,
        border: Border.all(
          color: scoreColor.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        borderRadius: DesignConstants.borderRadiusItem,
        onTap: () {
          widget.onMealSelected?.call();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getMealEmoji(rec.mealType),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.mealName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rec.mealType,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: DesignConstants.borderRadiusButton,
                    border: Border.all(
                      color: scoreColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${(rec.relevanceScore * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${rec.calories.round()} سعرة • بروتين ${rec.protein.round()}غ • كارب ${rec.carbs.round()}غ • دهون ${rec.fat.round()}غ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: _getReasonColor(rec.primaryReason).withOpacity(0.08),
                borderRadius: DesignConstants.borderRadiusButton,
              ),
              child: Text(
                rec.reasonLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: _getReasonColor(rec.primaryReason),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (rec.aiExplanation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Semantics(
                label: rec.aiExplanation,
                child: Text(
                  rec.aiExplanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getMealEmoji(String mealType) {
    switch (mealType) {
      case 'فطور':
        return '🌅';
      case 'غداء':
        return '☀️';
      case 'عشاء':
        return '🌙';
      case 'سناك':
        return '🍿';
      default:
        return '🍽️';
    }
  }

  Color _getReasonColor(RecommendationReason reason) {
    switch (reason) {
      case RecommendationReason.fillsNutritionGap:
        return AppColors.danger;
      case RecommendationReason.matchesTastePreference:
        return AppColors.primary;
      case RecommendationReason.suitableForHealthCondition:
        return AppColors.tertiary;
      case RecommendationReason.varietySuggestion:
        return AppColors.secondary;
      case RecommendationReason.timeAppropriate:
        return AppColors.info;
      case RecommendationReason.favorite:
        return const Color(0xFFE91E63);
      case RecommendationReason.calorieTarget:
        return AppColors.calories;
      case RecommendationReason.diseaseSpecific:
        return AppColors.danger;
      case RecommendationReason.dailyBalance:
        return AppColors.success;
      case RecommendationReason.hydrationReminder:
        return AppColors.info;
    }
  }
}