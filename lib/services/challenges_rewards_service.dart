// lib/services/challenges_rewards_service.dart
// ITEM 5: Nutrition Challenges System
// ITEM 6: Reward System (Badges & Gamification)
//
// Manages user challenges, badge awards, XP tracking,
// streak monitoring, and level progression.
// All models are immutable; uses copyWith() for updates.

import 'dart:convert';
import '../models/ai_models.dart';
import 'nutrition_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengesRewardsService {
  static const String _challengesPrefKey = 'nutrition_active_challenges';
  static const String _completedChallengesKey = 'nutrition_completed_challenges';
  static const String _badgesPrefKey = 'nutrition_earned_badges';
  static const String _gamificationPrefKey = 'nutrition_gamification_stats';
  static const String _xpHistoryKey = 'nutrition_xp_history';

  // Extra fields not in UserGamificationStats model
  static const String _totalMealsKey = 'nutrition_total_meals_logged';
  static const String _xpThisWeekKey = 'nutrition_xp_this_week';
  static const String _xpWeekStartKey = 'nutrition_xp_week_start';
  static const String _lastActiveKey = 'nutrition_last_active_date';

  // ═══════════════════════════════════════════════════════════
  // ITEM 5: NUTRITION CHALLENGES SYSTEM
  // ═══════════════════════════════════════════════════════════

  /// Get all available challenges from the library
  static List<NutritionChallenge> getChallengeLibrary() {
    final challenges = ChallengeLibrary.getDefaultChallenges();
    // Clone with fresh expiry dates from now
    final now = DateTime.now();
    return challenges.map((c) {
      final newExpiry = _calculateExpiryFromCategory(c.category, now);
      return c.copyWith(expiresAt: newExpiry);
    }).toList();
  }

  static DateTime _calculateExpiryFromCategory(ChallengeCategory cat, DateTime now) {
    switch (cat) {
      case ChallengeCategory.daily:
        return now.add(const Duration(days: 1));
      case ChallengeCategory.weekly:
        return now.add(const Duration(days: 7));
      case ChallengeCategory.monthly:
        return now.add(const Duration(days: 30));
      case ChallengeCategory.special:
        return now.add(const Duration(days: 14));
    }
  }

  /// Get the user's currently active challenges
  static Future<List<NutritionChallenge>> getActiveChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_challengesPrefKey);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((e) => NutritionChallenge.fromJson(e as Map<String, dynamic>))
          .where((c) =>
              c.status == ChallengeStatus.inProgress ||
              c.status == ChallengeStatus.notStarted)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get the user's completed challenges (not yet claimed)
  static Future<List<NutritionChallenge>> getCompletedChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_completedChallengesKey);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((e) => NutritionChallenge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Start a new challenge from the library
  static Future<bool> startChallenge(String challengeId) async {
    final library = getChallengeLibrary();
    final challenge = library.where((c) => c.id == challengeId).firstOrNull;
    if (challenge == null) return false;

    final startedChallenge = challenge.copyWith(
      status: ChallengeStatus.inProgress,
      progress: 0.0,
      startedAt: DateTime.now(),
    );

    final activeChallenges = await getActiveChallenges();
    activeChallenges.add(startedChallenge);

    await _saveActiveChallenges(activeChallenges);
    return true;
  }

  /// Claim a completed challenge (mark as claimed + award XP + badge)
  static Future<bool> claimChallenge(String challengeId) async {
    final completed = await getCompletedChallenges();
    final index = completed.indexWhere((c) => c.id == challengeId);
    if (index == -1) return false;

    final challenge = completed[index];
    if (challenge.status != ChallengeStatus.completed) return false;

    // Mark as claimed
    completed[index] = challenge.copyWith(status: ChallengeStatus.claimed);

    // Award XP for completion
    final xpGained = _calculateChallengeXp(challenge);
    await addXp(xpGained, 'أكمل التحدي: ${challenge.title}');

    // Award associated badge if any
    if (challenge.badgeId != null) {
      await awardBadge(challenge.badgeId!);
    }

    // Track completed challenge count
    await _incrementCompletedChallenges();

    await _saveCompletedChallenges(completed);
    return true;
  }

  /// Update progress for a specific challenge (0.0 - 1.0 incremental)
  static Future<void> updateChallengeProgress(
    String challengeId,
    double increment,
  ) async {
    final activeChallenges = await getActiveChallenges();
    final index = activeChallenges.indexWhere((c) => c.id == challengeId);
    if (index == -1) return;

    final challenge = activeChallenges[index];
    final newProgress = (challenge.progress + increment).clamp(0.0, 1.0);

    // Check if completed (progress reached 1.0)
    if (newProgress >= 1.0) {
      activeChallenges[index] = challenge.copyWith(
        progress: 1.0,
        status: ChallengeStatus.completed,
        completedAt: DateTime.now(),
      );

      // Move to completed list
      final completed = await getCompletedChallenges();
      completed.add(activeChallenges[index]);
      await _saveCompletedChallenges(completed);

      // Remove from active
      activeChallenges.removeAt(index);
    } else {
      activeChallenges[index] = challenge.copyWith(
        progress: newProgress,
      );
    }

    await _saveActiveChallenges(activeChallenges);
  }

  /// Update all active challenges based on today's nutrition data
  static Future<void> updateDailyChallenges() async {
    final activeChallenges = await getActiveChallenges();
    if (activeChallenges.isEmpty) return;

    final todayMeals = await NutritionService.getTodayMeals();
    if (todayMeals == null) return;

    final _ = (todayMeals['total_calories'] as num?)?.toDouble() ?? 0;
    final totalProtein = (todayMeals['total_protein'] as num?)?.toDouble() ?? 0;
    final totalCarbs = (todayMeals['total_carbs'] as num?)?.toDouble() ?? 0;
    final totalFat = (todayMeals['total_fat'] as num?)?.toDouble() ?? 0;
    final mealsList = todayMeals['meals'] as List? ?? [];
    final mealsCount = mealsList.length;

    for (final challenge in activeChallenges) {
      switch (challenge.id) {
        case 'ch_daily_veggies_5':
          // Each vegetable serving logged = progress
          // Simplified: if meals logged, increment
          if (mealsCount > 0) {
            await updateChallengeProgress(challenge.id, 0.2);
          }
          break;
        case 'ch_daily_water_8':
          // TODO: Integrate with water tracking
          break;
        case 'ch_daily_no_sugar':
          // Simplified: if meals exist, mark as attempted
          if (mealsCount > 0) {
            await updateChallengeProgress(challenge.id, 0.2);
          }
          break;
        case 'ch_daily_mindful':
          if (mealsCount >= 3) {
            await updateChallengeProgress(challenge.id, 1.0);
          }
          break;
        case 'ch_weekly_balanced':
          if (totalProtein > 0 && totalCarbs > 0 && totalFat > 0) {
            await updateChallengeProgress(challenge.id, 1.0 / 7);
          }
          break;
        case 'ch_weekly_protein':
          final targetProtein = 60.0; // Simplified target
          if (totalProtein >= targetProtein) {
            await updateChallengeProgress(challenge.id, 1.0 / 7);
          }
          break;
        case 'ch_weekly_hydration':
          // TODO: Integrate with water tracking
          await updateChallengeProgress(challenge.id, 1.0 / 7);
          break;
        case 'ch_monthly_streak':
          if (mealsCount >= 1) {
            await updateChallengeProgress(challenge.id, 1.0 / 30);
          }
          break;
        case 'ch_monthly_variety':
          if (mealsCount > 0) {
            await updateChallengeProgress(challenge.id, 1.0 / 30);
          }
          break;
        case 'ch_special_meal_master':
          if (mealsCount >= 3) {
            await updateChallengeProgress(challenge.id, 0.2);
          }
          break;
      }
    }
  }

  /// Get a specific challenge by ID (from active or completed)
  static Future<NutritionChallenge?> getChallengeById(String challengeId) async {
    final active = await getActiveChallenges();
    final match = active.where((c) => c.id == challengeId).firstOrNull;
    if (match != null) return match;

    final completed = await getCompletedChallenges();
    return completed.where((c) => c.id == challengeId).firstOrNull;
  }

  /// Get daily challenges from active list
  static Future<List<NutritionChallenge>> getDailyChallenges() async {
    final active = await getActiveChallenges();
    return active.where((c) => c.category == ChallengeCategory.daily).toList();
  }

  /// Get weekly challenges from active list
  static Future<List<NutritionChallenge>> getWeeklyChallenges() async {
    final active = await getActiveChallenges();
    return active.where((c) => c.category == ChallengeCategory.weekly).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // ITEM 6: REWARD SYSTEM (BADGES & GAMIFICATION)
  // ═══════════════════════════════════════════════════════════

  /// Get all available badges from the library
  static List<NutritionBadge> getBadgeLibrary() {
    return BadgeLibrary.getDefaultBadges();
  }

  /// Get the user's earned badges
  static Future<List<NutritionBadge>> getEarnedBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_badgesPrefKey);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map((e) => NutritionBadge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Award a badge to the user (mark as earned)
  static Future<bool> awardBadge(String badgeId) async {
    final library = getBadgeLibrary();
    final badge = library.where((b) => b.id == badgeId).firstOrNull;
    if (badge == null) return false;

    // Check if already earned
    final earned = await getEarnedBadges();
    if (earned.any((b) => b.id == badgeId)) return false;

    final awardedBadge = badge.copyWith(
      isEarned: true,
      earnedAt: DateTime.now(),
    );

    earned.add(awardedBadge);
    await _saveEarnedBadges(earned);

    // Award XP for badge
    final xpGained = _calculateBadgeXp(badge);
    await addXp(xpGained, 'حصل على شارة: ${badge.name}');

    // Check for badge milestone awards
    await _checkBadgeMilestones(earned.length);

    return true;
  }

  /// Check and award badges based on current stats
  static Future<void> checkAndAwardBadges(UserGamificationStats stats) async {
    final library = getBadgeLibrary();
    final earned = await getEarnedBadges();
    final earnedIds = earned.map((b) => b.id).toSet();
    final totalMeals = await getTotalMealsLogged();

    for (final badge in library) {
      if (earnedIds.contains(badge.id)) continue;

      bool shouldAward = false;

      switch (badge.id) {
        case 'badge_streak_3':
          shouldAward = stats.currentStreak >= 3;
          break;
        case 'badge_streak_7':
          shouldAward = stats.currentStreak >= 7;
          break;
        case 'badge_streak_30':
          shouldAward = stats.currentStreak >= 30;
          break;
        case 'badge_streak_100':
          shouldAward = stats.currentStreak >= 100;
          break;
        case 'badge_first_meal':
          shouldAward = totalMeals >= 1;
          break;
        case 'badge_veggie_lover':
          shouldAward = false; // Requires meal ingredient tracking
          break;
        case 'badge_protein_master':
          shouldAward = stats.challengesCompleted >= 2;
          break;
        case 'badge_calorie_king':
          shouldAward = stats.currentStreak >= 7;
          break;
        case 'badge_50_meals':
          shouldAward = totalMeals >= 50;
          break;
        case 'badge_100_meals':
          shouldAward = totalMeals >= 100;
          break;
        case 'badge_500_meals':
          shouldAward = totalMeals >= 500;
          break;
        case 'badge_balanced_week':
          shouldAward = stats.challengesCompleted >= 1;
          break;
        case 'badge_hydration_hero':
          shouldAward = false; // Requires water tracking integration
          break;
        case 'badge_sugar_free':
          shouldAward = stats.challengesCompleted >= 1;
          break;
        case 'badge_month_streak':
          shouldAward = stats.currentStreak >= 30;
          break;
        case 'badge_variety_expert':
          shouldAward = stats.challengesCompleted >= 3;
          break;
        case 'badge_chef':
          shouldAward = stats.challengesCompleted >= 5;
          break;
        case 'badge_early_adopter':
          shouldAward = totalMeals >= 1;
          break;
        case 'badge_consistency':
          shouldAward = stats.longestStreak >= 7;
          break;
        case 'badge_midnight_logger':
          shouldAward = false; // Requires checking meal log time
          break;
      }

      if (shouldAward) {
        await awardBadge(badge.id);
      }
    }
  }

  /// Get user gamification stats
  static Future<UserGamificationStats> getGamificationStats() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_gamificationPrefKey);
    if (data == null) {
      return UserGamificationStats();
    }

    try {
      return UserGamificationStats.fromJson(jsonDecode(data));
    } catch (_) {
      return UserGamificationStats();
    }
  }

  /// Add XP and potentially level up
  static Future<void> addXp(int amount, String reason) async {
    final stats = await getGamificationStats();

    final newTotalXp = stats.totalXp + amount;
    final newLevel = UserGamificationStats.calculateLevel(newTotalXp);
    final leveledUp = newLevel > stats.currentLevel;

    final updatedStats = stats.copyWith(
      totalXp: newTotalXp,
      currentLevel: newLevel,
      xpToNextLevel: UserGamificationStats.xpForNextLevel(newLevel),
    );

    // Record XP history
    await _recordXpEvent(amount, reason);

    // Track weekly XP
    await _addWeeklyXp(amount);

    // Save stats
    await _saveGamificationStats(updatedStats);

    // Level up bonus XP (once per level)
    if (leveledUp) {
      await addXp(50, '🌟 ترقية إلى المستوى $newLevel!');
    }
  }

  /// Update streak information (call daily)
  static Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await getGamificationStats();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastActiveStr = prefs.getString(_lastActiveKey);
    int newCurrentStreak = stats.currentStreak;
    int newLongestStreak = stats.longestStreak;

    if (lastActiveStr == null) {
      newCurrentStreak = 1;
      newLongestStreak = 1;
    } else {
      final lastActive = DateTime.parse(lastActiveStr);
      final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
      final diff = today.difference(lastActiveDay).inDays;

      if (diff == 1) {
        // Consecutive day
        newCurrentStreak = stats.currentStreak + 1;
        if (newCurrentStreak > stats.longestStreak) {
          newLongestStreak = newCurrentStreak;
        }
      } else if (diff > 1) {
        // Streak broken
        if (stats.currentStreak > stats.longestStreak) {
          newLongestStreak = stats.currentStreak;
        }
        newCurrentStreak = 1;
      }
      // diff == 0 means same day, no change
    }

    final updatedStats = stats.copyWith(
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
    );

    await prefs.setString(_lastActiveKey, today.toIso8601String());
    await _saveGamificationStats(updatedStats);

    // Streak milestone bonuses
    if (newCurrentStreak == 7) {
      await addXp(100, '🔥 أسبوع كامل من التسجيل!');
      await awardBadge('badge_streak_7');
    } else if (newCurrentStreak == 30) {
      await addXp(500, '🏆 شهر كامل من الالتزام!');
      await awardBadge('badge_streak_30');
    } else if (newCurrentStreak == 100) {
      await addXp(2000, '👑 مئة يوم متتالية!');
      await awardBadge('badge_streak_100');
    } else if (newCurrentStreak % 7 == 0 && newCurrentStreak > 0) {
      await addXp(50, '📅 ${newCurrentStreak ~/ 7} أسابيع متتالية!');
    }

    // Auto-check badges after streak update
    final finalStats = await getGamificationStats();
    await checkAndAwardBadges(finalStats);
  }

  /// Record that a meal was logged (awards XP + checks badges)
  static Future<void> recordMealLogged() async {
    final prefs = await SharedPreferences.getInstance();
    final totalMeals = (prefs.getInt(_totalMealsKey) ?? 0) + 1;
    await prefs.setInt(_totalMealsKey, totalMeals);

    // XP for logging meals
    await addXp(10, '🍽️ تسجيل وجبة');

    // Update streak
    await updateStreak();

    // Check milestone badges
    if (totalMeals == 1) {
      await awardBadge('badge_first_meal');
    } else if (totalMeals == 50) {
      await awardBadge('badge_50_meals');
    } else if (totalMeals == 100) {
      await awardBadge('badge_100_meals');
    } else if (totalMeals == 500) {
      await awardBadge('badge_500_meals');
    }
  }

  /// Get total meals logged
  static Future<int> getTotalMealsLogged() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalMealsKey) ?? 0;
  }

  /// Increment the completed challenges counter
  static Future<void> _incrementCompletedChallenges() async {
    final stats = await getGamificationStats();
    final updated = stats.copyWith(
      challengesCompleted: stats.challengesCompleted + 1,
    );
    await _saveGamificationStats(updated);
  }

  /// Check and award badge milestones based on count
  static Future<void> _checkBadgeMilestones(int badgeCount) async {
    if (badgeCount == 5) {
      // First milestone - could add badge for this
    }
  }

  /// Get this week's XP
  static Future<int> getCurrentWeekXp() async {
    final prefs = await SharedPreferences.getInstance();
    final weekStart = prefs.getString(_xpWeekStartKey);
    final now = DateTime.now();
    final thisWeekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);

    // Reset if new week
    if (weekStart == null || DateTime.parse(weekStart).isBefore(thisWeekStart)) {
      await prefs.setString(_xpWeekStartKey, thisWeekStart.toIso8601String());
      await prefs.setInt(_xpThisWeekKey, 0);
      return 0;
    }

    return prefs.getInt(_xpThisWeekKey) ?? 0;
  }

  /// Add XP to weekly counter
  static Future<void> _addWeeklyXp(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getCurrentWeekXp();
    await prefs.setInt(_xpThisWeekKey, current + amount);
  }

  /// Get XP needed for next level
  static int getXpForNextLevel(int currentLevel) {
    return UserGamificationStats.xpForNextLevel(currentLevel);
  }

  /// Level progress percentage (0.0 - 1.0)
  static double getLevelProgress(int totalXp, int currentLevel) {
    final xpForThisLevel = currentLevel > 1
        ? UserGamificationStats.xpForNextLevel(currentLevel - 1)
        : 0;
    final xpForCurrentLevel = UserGamificationStats.xpForNextLevel(currentLevel);
    final xpInLevel = totalXp - xpForThisLevel;
    final xpNeeded = xpForCurrentLevel - xpForThisLevel;
    if (xpNeeded <= 0) return 1.0;
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  }

  /// Get recent XP history events
  static Future<List<Map<String, dynamic>>> getXpHistory({int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_xpHistoryKey);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .cast<Map<String, dynamic>>()
          .take(limit)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════

  static Future<void> _saveActiveChallenges(List<NutritionChallenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();
    final data = challenges.map((c) => c.toJson()).toList();
    await prefs.setString(_challengesPrefKey, jsonEncode(data));
  }

  static Future<void> _saveCompletedChallenges(List<NutritionChallenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();
    final data = challenges.map((c) => c.toJson()).toList();
    await prefs.setString(_completedChallengesKey, jsonEncode(data));
  }

  static Future<void> _saveEarnedBadges(List<NutritionBadge> badges) async {
    final prefs = await SharedPreferences.getInstance();
    final data = badges.map((b) => b.toJson()).toList();
    await prefs.setString(_badgesPrefKey, jsonEncode(data));
  }

  static Future<void> _saveGamificationStats(UserGamificationStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gamificationPrefKey, jsonEncode(stats.toJson()));
  }

  static Future<void> _recordXpEvent(int amount, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_xpHistoryKey);
    List<Map<String, dynamic>> history;

    if (data != null) {
      try {
        history = (jsonDecode(data) as List).cast<Map<String, dynamic>>();
      } catch (_) {
        history = [];
      }
    } else {
      history = [];
    }

    history.insert(0, {
      'amount': amount,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 100 events
    final toSave = history.length > 100 ? history.sublist(0, 100) : history;
    await prefs.setString(_xpHistoryKey, jsonEncode(toSave));
  }

  static int _calculateChallengeXp(NutritionChallenge challenge) {
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:
        return 50;
      case ChallengeDifficulty.medium:
        return 100;
      case ChallengeDifficulty.hard:
        return 200;
      case ChallengeDifficulty.expert:
        return 500;
    }
  }

  static int _calculateBadgeXp(NutritionBadge badge) {
    switch (badge.type) {
      case BadgeType.streak:
        return 150;
      case BadgeType.achievement:
        return 100;
      case BadgeType.milestone:
        return 200;
      case BadgeType.challenge:
        return 100;
      case BadgeType.special:
        return 300;
      case BadgeType.hidden:
        return 500;
    }
  }
}