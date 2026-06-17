// lib/services/ai_recommendation_service.dart
// AI-Powered Nutrition Services:
// ITEM 1: Smart Meal Recommendations Engine
// ITEM 2: Dynamic Recipe Adaptation
//
// Uses local analysis of user data, preferences, health conditions,
// and eating patterns to generate context-aware recommendations.

import '../models/ai_models.dart';
import '../models/nutrition_model.dart';
import 'nutrition_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiRecommendationService {
  static const String _prefKey = 'ai_recommendation_cache';
  static const String _adaptationPrefKey = 'ai_adaptation_history';
  static const String _lastRefreshKey = 'ai_last_refresh';

  // ═══════════════════════════════════════════════════════════
  // ITEM 1: SMART MEAL RECOMMENDATIONS ENGINE
  // ═══════════════════════════════════════════════════════════

  /// Generate AI-powered meal recommendations based on full user context
  static Future<List<AiMealRecommendation>> getSmartRecommendations({
    required RecommendationContext context,
    List<MealSuggestion>? availableMeals,
    int maxResults = 10,
    bool forceRefresh = false,
  }) async {
    // Load meals if not provided
    final meals = availableMeals ?? await _loadMealSuggestions(context);

    if (meals.isEmpty) return [];

    // Score each meal
    final scored = <_ScoredMeal>[];
    for (final meal in meals) {
      final score = await _scoreMeal(meal, context);
      if (score != null) scored.add(score);
    }

    // Sort by score descending
    scored.sort((a, b) => b.score.compareTo(a.score));

    // Build recommendations from top results
    final recommendations = scored
        .take(maxResults)
        .map((s) => _buildRecommendation(s.meal, s, context))
        .toList();

    // Cache recommendations
    await _cacheRecommendations(recommendations);

    return recommendations;
  }

  /// Get cached recommendations quickly (for home screen display)
  static Future<List<AiMealRecommendation>?> getCachedRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_prefKey);
    if (data == null) return null;
    try {
      final List<dynamic> list = data.split('|||').map((s) {
        final parts = s.split('::');
        if (parts.length < 6) return null;
        return AiMealRecommendation(
          mealId: int.tryParse(parts[0]) ?? 0,
          mealName: parts[1],
          mealType: parts[2],
          calories: double.tryParse(parts[3]) ?? 0,
          protein: double.tryParse(parts[4]) ?? 0,
          carbs: double.tryParse(parts[5]) ?? 0,
          fat: double.tryParse(parts[6]) ?? 0,
          ingredients: parts.length > 7 ? parts[7].split(',') : [],
          description: parts.length > 8 ? parts[8] : '',
          relevanceScore: double.tryParse(parts.length > 9 ? parts[9] : '0') ?? 0,
          primaryReason: RecommendationReason.values[
              int.tryParse(parts.length > 10 ? parts[10] : '0') ?? 0],
          aiExplanation: parts.length > 11 ? parts[11] : '',
          imageUrl: parts.length > 12 ? parts[12] : null,
        );
      }).whereType<AiMealRecommendation>().toList();
      return list.cast<AiMealRecommendation>();
    } catch (_) {
      return null;
    }
  }

  /// Get personalized meal recommendation by meal type
  static Future<List<AiMealRecommendation>> getRecommendationsForMealType({
    required String mealType,
    required String goal,
    List<String>? diseases,
    int maxResults = 5,
  }) async {
    final meals = await NutritionService.getMealSuggestions(
      goal: goal,
      diseases: diseases,
    );

    final filtered = meals.where((m) => m.type == mealType).toList();
    if (filtered.isEmpty) return [];

    final now = DateTime.now();
    final context = RecommendationContext(
      timeContext: _getTimeContext(now),
      currentCalories: 0,
      currentProtein: 0,
      currentCarbs: 0,
      currentFat: 0,
      targetCalories: 2000,
      targetProtein: 100,
      targetCarbs: 250,
      targetFat: 70,
      diseases: diseases ?? [],
      goal: goal,
    );

    final scored = <_ScoredMeal>[];
    for (final meal in filtered) {
      final score = await _scoreMeal(meal, context);
      if (score != null) scored.add(score);
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored
        .take(maxResults)
        .map((s) => _buildRecommendation(s.meal, s, context))
        .toList();
  }

  /// Get a daily meal plan suggestion based on AI analysis
  static Future<Map<String, AiMealRecommendation>> getSuggestedDailyPlan({
    required RecommendationContext context,
  }) async {
    final plan = <String, AiMealRecommendation>{};
    final mealTypes = ['فطور', 'غداء', 'عشاء', 'سناك'];

    for (final type in mealTypes) {
      if (!context.hasEatenMealType(type) || type == 'سناك') {
        final recs = await getRecommendationsForMealType(
          mealType: type,
          goal: context.goal,
          diseases: context.diseases,
          maxResults: 1,
        );
        if (recs.isNotEmpty) {
          plan[type] = recs.first;
        }
      }
    }

    return plan;
  }

  // ═══════════════════════════════════════════════════════════
  // ITEM 2: DYNAMIC RECIPE ADAPTATION
  // ═══════════════════════════════════════════════════════════

  /// Adapt a recipe based on user's health needs and preferences
  static Future<List<AdaptedRecipe>> adaptRecipe({
    required MealSuggestion meal,
    required String goal,
    required List<String> diseases,
    List<String>? dislikedIngredients,
    double? targetCalories,
  }) async {
    final adaptations = <AdaptedRecipe>[];
    final substitutions = <IngredientSubstitution>[];
    final originalIngredients = meal.ingredients
        .map((i) => (i['name'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList();

    // Check for health-based substitutions
    if (diseases.contains('السكري')) {
      substitutions.addAll(_getDiabetesSubstitutions(meal, originalIngredients));
    }
    if (diseases.contains('الكوليسترول') || diseases.contains('القلب')) {
      substitutions.addAll(_getHeartHealthSubstitutions(meal, originalIngredients));
    }
    if (diseases.contains('ضغط الدم')) {
      substitutions.addAll(_getBloodPressureSubstitutions(meal, originalIngredients));
    }
    if (diseases.contains('الأنيميا')) {
      substitutions.addAll(_getAnemiaSubstitutions(meal, originalIngredients));
    }

    // Remove disliked ingredients
    if (dislikedIngredients != null && dislikedIngredients.isNotEmpty) {
      for (final disliked in dislikedIngredients) {
        final match = originalIngredients.where(
          (i) => i.toLowerCase().contains(disliked.toLowerCase()),
        );
        for (final ingredient in match) {
          substitutions.add(IngredientSubstitution(
            originalIngredient: ingredient,
            suggestedIngredient: _getAlternativeForIngredient(ingredient),
            reason: 'استبدال مكون غير مفضل لديك',
            caloriesImpact: _getCalorieImpact(ingredient, _getAlternativeForIngredient(ingredient)),
            isHealthier: true,
          ));
        }
      }
    }

    // Build adapted ingredients list
    final adaptedIngredients = List<String>.from(originalIngredients);
    for (final sub in substitutions) {
      final idx = adaptedIngredients.indexWhere(
        (i) => i.toLowerCase().contains(sub.originalIngredient.toLowerCase()),
      );
      if (idx != -1) {
        adaptedIngredients[idx] = sub.suggestedIngredient;
      }
    }

    // Calculate adapted nutrition
    final totalCalorieImpact =
        substitutions.fold(0.0, (sum, s) => sum + s.caloriesImpact);
    final adaptedCalories = (meal.calories + totalCalorieImpact).clamp(100, 2000);

    // Scale recipe if target calories provided
    double scaleFactor = 1.0;
    if (targetCalories != null && meal.calories > 0) {
      scaleFactor = (targetCalories / meal.calories).clamp(0.5, 1.5);
    }

    // Generate adaptation reason
    final reasonParts = <String>[];
    if (substitutions.where((s) => s.isHealthier).length > 1) {
      reasonParts.add('تم تعديل الوصفة لتناسب حالتك الصحية');
    }
    if (scaleFactor != 1.0) {
      reasonParts.add('تم تعديل الكميات لتناسب هدفك من السعرات');
    }
    if (dislikedIngredients != null && dislikedIngredients.isNotEmpty) {
      reasonParts.add('تم استبدال المكونات الغير مفضلة لديك');
    }
    if (reasonParts.isEmpty) {
      reasonParts.add('الوصفة مناسبة لحالتك');
    }

    // Save adaptation to history
    await _saveAdaptationHistory(meal, adaptedCalories.toDouble());

    adaptations.add(AdaptedRecipe(
      originalMealId: meal.id,
      originalName: meal.name,
      adaptedName: scaleFactor != 1.0
          ? '${meal.name} (معدلة)'
          : meal.name,
      originalCalories: meal.calories,
      adaptedCalories: adaptedCalories * scaleFactor,
      originalProtein: meal.protein,
      adaptedProtein: meal.protein * scaleFactor,
      originalCarbs: meal.carbs,
      adaptedCarbs: meal.carbs * scaleFactor,
      originalFat: meal.fat,
      adaptedFat: meal.fat * scaleFactor,
      originalIngredients: originalIngredients,
      adaptedIngredients: adaptedIngredients,
      substitutions: substitutions,
      adaptationReason: reasonParts.join('، '),
      cookingTips: _getCookingTips(diseases).join('، '),
      servingSuggestions: _getServingSuggestions(goal),
    ));

    return adaptations;
  }

  /// Get adaptation history for display
  static Future<List<Map<String, dynamic>>> getAdaptationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_adaptationPrefKey);
    if (data == null) return [];
    try {
      final List<dynamic> list = data.split('|||').map((s) {
        final parts = s.split('::');
        return {
          'meal_name': parts[0],
          'original_calories': double.tryParse(parts[1]) ?? 0,
          'adapted_calories': double.tryParse(parts[2]) ?? 0,
          'timestamp': parts.length > 3 ? parts[3] : '',
        };
      }).toList();
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  /// Score a single meal against the recommendation context
  static Future<_ScoredMeal?> _scoreMeal(
    MealSuggestion meal,
    RecommendationContext context,
  ) async {
    double score = 0.5; // Base score
    final reasons = <RecommendationReason>{};
    final explanations = <String>[];

    // Factor 1: Nutrition gap filling (0-2 points)
    if (context.mostDeficientNutrient != null) {
      if (context.mostDeficientNutrient == 'بروتين' && meal.protein > 20) {
        score += 0.3;
        reasons.add(RecommendationReason.fillsNutritionGap);
        explanations.add('غني بالبروتين لسد الفجوة الغذائية');
      } else if (context.mostDeficientNutrient == 'كارب' && meal.carbs > 30) {
        score += 0.3;
        reasons.add(RecommendationReason.fillsNutritionGap);
        explanations.add('غني بالكربوهيدرات لسد الفجوة الغذائية');
      } else if (context.mostDeficientNutrient == 'دهون' && meal.fat > 15) {
        score += 0.2;
        reasons.add(RecommendationReason.fillsNutritionGap);
        explanations.add('يحتوي على دهون صحية لسد الفجوة');
      }
    }

    // Factor 2: Meal type timing appropriateness (0-1 point)
    final suggestedType = context.suggestedMealType;
    if (suggestedType != null && meal.type == suggestedType) {
      score += 0.4;
      reasons.add(RecommendationReason.timeAppropriate);
      explanations.add('مناسب لوجبة $suggestedType');
    }

    // Factor 3: Calorie target alignment (0-1 point)
    final remainingCalories = context.targetCalories - context.currentCalories;
    if (remainingCalories > 0) {
      final calorieFit = meal.calories / remainingCalories;
      if (calorieFit >= 0.3 && calorieFit <= 0.8) {
        score += 0.3;
        reasons.add(RecommendationReason.calorieTarget);
        explanations.add('متناسب مع السعرات المتبقية');
      }
    }

    // Factor 4: Health condition suitability (0-1.5 points)
    if (context.diseases.isNotEmpty) {
      bool suitable = true;
      for (final disease in context.diseases) {
        if (!meal.suitableFor.contains(disease)) {
          suitable = false;
          break;
        }
      }
      if (suitable) {
        score += 0.3;
        reasons.add(RecommendationReason.diseaseSpecific);
        explanations.add('مناسب لحالتك الصحية');

        // Bonus for exact disease match
        if (meal.suitableFor.length >= context.diseases.length) {
          score += 0.2;
          reasons.add(RecommendationReason.suitableForHealthCondition);
        }
      } else {
        score -= 0.3; // Penalty for unsuitable
      }
    }

    // Factor 5: Variety (0-0.5 points) - prefer not recently eaten
    if (!context.recentlyEatenMeals.contains(meal.name.toLowerCase().trim())) {
      score += 0.2;
      reasons.add(RecommendationReason.varietySuggestion);
      explanations.add('وجبة جديدة لم تتناولها مؤخراً');
    } else {
      score -= 0.1;
    }

    // Factor 6: Taste preference match (0-0.5 points)
    if (context.preferredCuisines.isNotEmpty) {
      for (final cuisine in context.preferredCuisines) {
        if (meal.name.contains(cuisine) ||
            meal.description.contains(cuisine)) {
          score += 0.2;
          reasons.add(RecommendationReason.matchesTastePreference);
          break;
        }
      }
    }

    // Factor 7: Avoided foods check
    if (context.avoidedFoods.isNotEmpty) {
      for (final ingredient in meal.ingredients) {
        final name = (ingredient['name'] ?? '').toString().toLowerCase();
        for (final avoided in context.avoidedFoods) {
          if (name.contains(avoided.toLowerCase())) {
            return null; // Exclude this meal entirely
          }
        }
      }
    }

    // Factor 8: Daily balance
    final remainingCarbsRatio = context.targetCarbs > 0
        ? (context.targetCarbs - context.currentCarbs) / context.targetCarbs
        : 0.5;
    if (remainingCarbsRatio < 0.3 && meal.carbs > 40) {
      score -= 0.2; // Already had enough carbs
    }

    // Clamp score
    score = score.clamp(0.0, 2.0);

    if (score < 0.3) return null; // Too low score

    // Determine primary reason
    final reasonList = reasons.toList();
    final primaryReason = reasonList.isNotEmpty
        ? reasonList.first
        : RecommendationReason.dailyBalance;

    final explanation = explanations.isNotEmpty
        ? explanations.join('، ')
        : 'توصية عامة بناءً on احتياجاتك';

    return _ScoredMeal(
      meal: meal,
      score: score,
      normalizedScore: score / 2.0, // Normalize to 0-1
      primaryReason: primaryReason,
      allReasons: reasonList,
      explanation: explanation,
    );
  }

  /// Build an AiMealRecommendation from scored meal data
  static AiMealRecommendation _buildRecommendation(
    MealSuggestion meal,
    _ScoredMeal scored,
    RecommendationContext context,
  ) {
    return AiMealRecommendation(
      mealId: meal.id,
      mealName: meal.name,
      mealType: meal.type,
      calories: meal.calories,
      protein: meal.protein,
      carbs: meal.carbs,
      fat: meal.fat,
      ingredients: meal.ingredients.map((i) => i['name']?.toString() ?? '').toList(),
      imageUrl: meal.imageUrl.isNotEmpty ? meal.imageUrl : null,
      description: meal.description,
      relevanceScore: scored.normalizedScore,
      primaryReason: scored.primaryReason,
      secondaryReasons: scored.allReasons,
      aiExplanation: scored.explanation,
      isFromFavorite: false,
      isDietBreakSuggestion: context.calorieProgress > 0.8,
    );
  }

  /// Load meal suggestions from the existing service
  static Future<List<MealSuggestion>> _loadMealSuggestions(
    RecommendationContext context,
  ) async {
    return await NutritionService.getMealSuggestions(
      goal: context.goal,
      diseases: context.diseases,
    );
  }

  /// Determine meal time context from current time
  static MealTimeContext _getTimeContext(DateTime time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 11) return MealTimeContext.morning;
    if (hour >= 11 && hour < 14) return MealTimeContext.midday;
    if (hour >= 14 && hour < 18) return MealTimeContext.afternoon;
    if (hour >= 18 && hour < 21) return MealTimeContext.evening;
    return MealTimeContext.lateNight;
  }

  /// Cache recommendations to SharedPrefs
  static Future<void> _cacheRecommendations(
    List<AiMealRecommendation> recs,
  ) async {
    try {
      final data = recs.map((r) => [
        r.mealId,
        r.mealName,
        r.mealType,
        r.calories,
        r.protein,
        r.carbs,
        r.fat,
        r.ingredients.join(','),
        r.description,
        r.relevanceScore,
        r.primaryReason.index,
        r.aiExplanation,
        r.imageUrl ?? '',
      ].join('::')).join('|||');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, data);
      await prefs.setString(_lastRefreshKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  /// Save adaptation history
  static Future<void> _saveAdaptationHistory(
    MealSuggestion meal,
    double adaptedCalories,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_adaptationPrefKey) ?? '';
      final entry =
          '${meal.name}::${meal.calories}::$adaptedCalories::${DateTime.now().toIso8601String()}';
      final updated = existing.isEmpty
          ? entry
          : '$entry|||$existing';
      // Keep only last 20 entries
      final entries = updated.split('|||');
      if (entries.length > 20) {
        await prefs.setString(_adaptationPrefKey, entries.take(20).join('|||'));
      } else {
        await prefs.setString(_adaptationPrefKey, updated);
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════
  // HEALTH-BASED SUBSTITUTIONS
  // ═══════════════════════════════════════════════════════════

  static List<IngredientSubstitution> _getDiabetesSubstitutions(
    MealSuggestion meal, List<String> ingredients) {
    final subs = <IngredientSubstitution>[];
    final lowerIngredients = ingredients.map((i) => i.toLowerCase()).toList();

    for (final ingredient in lowerIngredients) {
      if (ingredient.contains('أرز')) {
        subs.add(IngredientSubstitution(
          originalIngredient: 'أرز',
          suggestedIngredient: 'أرز بني',
          reason: 'الأرز البني أفضل لمرضى السكري (مؤشر جلايسيمي منخفض)',
          caloriesImpact: -20,
          isHealthier: true,
        ));
      } else if (ingredient.contains('خبز') || ingredient.contains('عيش')) {
        subs.add(IngredientSubstitution(
          originalIngredient: 'خبز أبيض',
          suggestedIngredient: 'خبز أسمر',
          reason: 'الخبز الأسمر يحتوي على ألياف أكثر ويرفع السكر بشكل تدريجي',
          caloriesImpact: -30,
          isHealthier: true,
        ));
      } else if (ingredient.contains('سكر') || ingredient.contains('عسل')) {
        subs.add(IngredientSubstitution(
          originalIngredient: 'سكر',
          suggestedIngredient: 'ستيفيا',
          reason: 'الستيفيا محلي طبيعي آمن لمرضى السكري',
          caloriesImpact: -50,
          isHealthier: true,
        ));
      } else if (ingredient.contains('بطاطس')) {
        subs.add(IngredientSubstitution(
          originalIngredient: 'بطاطس',
          suggestedIngredient: 'بطاطا حلوة',
          reason: 'البطاطا الحلوة تحتوي على ألياف أكثر ومؤشر جلايسيمي أقل',
          caloriesImpact: -10,
          isHealthier: true,
        ));
      }
    }
    return subs;
  }

  static List<IngredientSubstitution> _getHeartHealthSubstitutions(
    MealSuggestion meal, List<String> ingredients) {
    final subs = <IngredientSubstitution>[];
    final lowerIngredients = ingredients.map((i) => i.toLowerCase()).toList();

    for (final ingredient in lowerIngredients) {
      if (ingredient.contains('زبدة') || ingredient.contains('سمن')) {
        subs.add(IngredientSubstitution(
          originalIngredient: 'زبدة',
          suggestedIngredient: 'زيت زيتون',
          reason: 'زيت الزيتون غني بالدهون الصحية للقلب',
          caloriesImpact: -30,
          isHealthier: true,
        ));
      } else if (ingredient.contains('لحمة') && ingredient.contains('حمراء') ||
          ingredient.contains('لحم')) {
        subs.add(IngredientSubstitution(
          originalIngredient: 'لحم أحمر',
          suggestedIngredient: 'دجاج منزوع الجلد',
          reason: 'الدجاج أقل في الدهون المشبعة',
          caloriesImpact: -60,
          isHealthier: true,
        ));
      } else if (ingredient.contains('جبن')) {
        subs.add(IngredientSubstitution(
          originalIngredient: 'جبن كامل الدسم',
          suggestedIngredient: 'جبن قليل الدسم',
          reason: 'الجبن قليل الدسم يحتوي على دهون مشبعة أقل',
          caloriesImpact: -40,
          isHealthier: true,
        ));
      } else if (ingredient.contains('مقلي') || ingredient.contains('محمر')) {
        subs.add(IngredientSubstitution(
          originalIngredient: 'مقلي',
          suggestedIngredient: 'مشوي',
          reason: 'الشوي أفضل للقلب من القلي',
          caloriesImpact: -80,
          isHealthier: true,
        ));
      }
    }
    return subs;
  }

  static List<IngredientSubstitution> _getBloodPressureSubstitutions(
    MealSuggestion meal, List<String> ingredients) {
    final subs = <IngredientSubstitution>[];
    final lowerIngredients = ingredients.map((i) => i.toLowerCase()).toList();

    for (final ingredient in lowerIngredients) {
      if (ingredient.contains('ملح')) {
        subs.add(IngredientSubstitution(
          originalIngredient: 'ملح',
          suggestedIngredient: 'ليمون وبهارات',
          reason: 'استخدام الليمون والبهارات بدلاً من الملح لضبط الضغط',
          caloriesImpact: 0,
          isHealthier: true,
        ));
      } else if (ingredient.contains('مخلل') || ingredient.contains('زيتون')) {
        subs.add(IngredientSubstitution(
          originalIngredient: 'مخلل',
          suggestedIngredient: 'خضروات طازجة',
          reason: 'المخللات غنية بالصوديوم الذي يرفع الضغط',
          caloriesImpact: -20,
          isHealthier: true,
        ));
      }
    }
    return subs;
  }

  static List<IngredientSubstitution> _getAnemiaSubstitutions(
    MealSuggestion meal, List<String> ingredients) {
    final subs = <IngredientSubstitution>[];
    final lowerIngredients = ingredients.map((i) => i.toLowerCase()).toList();

    // Add iron-rich ingredient suggestions
    bool hasIronSource = false;
    for (final ingredient in lowerIngredients) {
      if (ingredient.contains('سبانخ') || ingredient.contains('لحمة') ||
          ingredient.contains('كبد') || ingredient.contains('بقول')) {
        hasIronSource = true;
        break;
      }
    }

    if (!hasIronSource) {
      subs.add(IngredientSubstitution(
        originalIngredient: 'خضروات',
        suggestedIngredient: 'سبانخ',
        reason: 'السبانخ غنية بالحديد المفيد للأنيميا',
        caloriesImpact: -10,
        isHealthier: true,
      ));
    }
    return subs;
  }

  /// Get a generic alternative for a disliked ingredient
  static String _getAlternativeForIngredient(String ingredient) {
    final lower = ingredient.toLowerCase();
    if (lower.contains('بصل')) return 'كراث';
    if (lower.contains('ثوم')) return 'زنجبيل';
    if (lower.contains('فلفل')) return 'فلفل حلو';
    if (lower.contains('جبن')) return 'جبن قليل الدسم';
    if (lower.contains('زبدة')) return 'زيت زيتون';
    if (lower.contains('سكر')) return 'عسل نحل';
    if (lower.contains('أرز')) return 'كينوا';
    if (lower.contains('لحمة')) return 'دجاج';
    return ingredient;
  }

  /// Estimate calorie impact of a substitution
  static double _getCalorieImpact(String original, String replacement) {
    final orig = original.toLowerCase();
    final repl = replacement.toLowerCase();
    if (orig.contains('زبدة') || orig.contains('سمن')) return -50;
    if (orig.contains('سكر')) return -40;
    if (orig.contains('جبن')) return -30;
    if (orig.contains('لحمة')) return -60;
    if (orig.contains('أرز') && repl.contains('كينوا')) return -10;
    if (orig.contains('خبز')) return -20;
    return -10;
  }

  /// Get cooking tips based on health conditions
  static List<String> _getCookingTips(List<String> diseases) {
    final tips = <String>[];
    if (diseases.contains('السكري')) {
      tips.add('يفضل طهي الطعام ببطء على نار هادئة');
      tips.add('تجنب إضافة السكر أو المحليات الصناعية');
    }
    if (diseases.contains('ضغط الدم')) {
      tips.add('قلل من استخدام الملح واستخدم الأعشاب للنكهة');
    }
    if (diseases.contains('الكوليسترول')) {
      tips.add('استخدم زيت الزيتون أو زيت الكانولا');
      tips.add('تجنب القلي العميق');
    }
    if (tips.isEmpty) {
      tips.add('يوصى بالطهي بالبخار أو الشوي للحفاظ على القيمة الغذائية');
    }
    return tips;
  }

  /// Get serving suggestions based on goal
  static List<String> _getServingSuggestions(String goal) {
    switch (goal) {
      case 'تخسيس':
        return ['قدم الوجبة في طبق صغير', 'ابدأ بكوب ماء قبل الوجبة', 'تناول الطعام ببطء'];
      case 'زيادة':
        return ['أضف مصدر بروتين إضافي', 'تناول وجبة خفيفة بين الوجبات'];
      default:
        return ['قدم مع سلطة خضراء', 'أضف القليل من الليمون للنكهة'];
    }
  }
}

/// Internal helper class for scoring meals
class _ScoredMeal {
  final MealSuggestion meal;
  final double score;
  final double normalizedScore;
  final RecommendationReason primaryReason;
  final List<RecommendationReason> allReasons;
  final String explanation;

  _ScoredMeal({
    required this.meal,
    required this.score,
    required this.normalizedScore,
    required this.primaryReason,
    required this.allReasons,
    required this.explanation,
  });
}