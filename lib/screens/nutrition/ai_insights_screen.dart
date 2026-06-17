// lib/screens/nutrition/ai_insights_screen.dart
// Phase C: AI Insights Hub — integrates all 6 AI features (Recommendations, Analytics, Challenges, Rewards)

import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/design_constants.dart';
import '../../../models/nutrition_model.dart';
import '../../../widgets/ai/ai_recommendation_card.dart';
import '../../../widgets/ai/predictive_analytics_card.dart';
import '../../../widgets/ai/challenges_card.dart';
import '../../../widgets/ai/rewards_card.dart';

/// A dedicated screen that assembles all AI-powered nutrition features
/// into a single scrollable hub for quick access and insights.
class AIInsightsScreen extends StatelessWidget {
  final UserNutritionData userData;

  const AIInsightsScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          title: Semantics(
            label: 'رؤى الذكاء الاصطناعي',
            header: true,
            child: Text('🤖 رؤى الذكاء الاصطناعي'),
          ),
          leading: Semantics(
            button: true,
            label: 'رجوع',
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
              tooltip: 'رجوع',
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header description
                Semantics(
                  label: 'ملخص الرؤى الذكية',
                  header: true,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                          AppColors.secondary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: DesignConstants.borderRadiusItem,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: DesignConstants.borderRadiusSmall,
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تحليلات ذكية مخصصة',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'توصيات مخصصة، تحليلات تنبؤية، وتحديات تفاعلية بناءً على بياناتك الصحية',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section 1: AI Meal Recommendations
                DesignConstants.sectionHeader(
                  title: 'توصيات الوجبات الذكية',
                  emoji: '🍽️',
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'توصيات الوجبات المخصصة بالذكاء الاصطناعي',
                  child: AiRecommendationCard(
                    goal: userData.goal,
                    diseases: userData.diseases,
                    preferences: userData.diseases,
                    targetCalories: userData.targetCalories,
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Predictive Analytics
                DesignConstants.sectionHeader(
                  title: 'التحليلات التنبؤية',
                  emoji: '📊',
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'التحليلات التنبؤية والتوقعات الصحية',
                  child: PredictiveAnalyticsCard(userData: userData),
                ),
                const SizedBox(height: 24),

                // Section 3: Active Challenges
                DesignConstants.sectionHeader(
                  title: 'التحديات النشطة',
                  emoji: '🏆',
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'التحديات الغذائية النشطة',
                  child: const ChallengesCard(),
                ),
                const SizedBox(height: 24),

                // Section 4: Rewards & Gamification
                DesignConstants.sectionHeader(
                  title: 'المكافآت والإنجازات',
                  emoji: '🎖️',
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'المكافآت ونظام التحديات',
                  child: const RewardsCard(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
