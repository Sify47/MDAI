// lib/models/quiz_models.dart

class QuizQuestion {
  final int id;
  final String questionText;
  final String category;
  final int defaultOrder;
  final bool isActive;
  final List<QuizOption> options;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.category,
    required this.defaultOrder,
    required this.isActive,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      questionText: json['question_text'],
      category: json['category'],
      defaultOrder: json['default_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      options: (json['options'] as List? ?? [])
          .map((o) => QuizOption.fromJson(o))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'category': category,
      'default_order': defaultOrder,
      'is_active': isActive,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

class QuizOption {
  final int id;
  final String optionText;
  final int scoreValue;
  final int order;

  QuizOption({
    required this.id,
    required this.optionText,
    required this.scoreValue,
    required this.order,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'],
      optionText: json['option_text'],
      scoreValue: json['score_value'] ?? 0,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'option_text': optionText,
      'score_value': scoreValue,
      'order': order,
    };
  }
}

class QuizAnswerSubmit {
  final int questionId;
  final int selectedOptionId;

  QuizAnswerSubmit({required this.questionId, required this.selectedOptionId});

  Map<String, dynamic> toJson() {
    return {'question_id': questionId, 'selected_option_id': selectedOptionId};
  }
}

class QuizSessionSubmit {
  final List<QuizAnswerSubmit> answers;
  final bool isOnboarding;

  QuizSessionSubmit({required this.answers, required this.isOnboarding});

  Map<String, dynamic> toJson() {
    return {
      'answers': answers.map((a) => a.toJson()).toList(),
      'is_onboarding': isOnboarding,
    };
  }
}

class QuizSessionResponse {
  final int id;
  final DateTime sessionDate;
  final bool isOnboarding;
  final int totalScore;
  final Map<String, int> categoryScores;

  QuizSessionResponse({
    required this.id,
    required this.sessionDate,
    required this.isOnboarding,
    required this.totalScore,
    required this.categoryScores,
  });

  factory QuizSessionResponse.fromJson(Map<String, dynamic> json) {
    return QuizSessionResponse(
      id: json['id'],
      sessionDate: DateTime.parse(json['session_date']),
      isOnboarding: json['is_onboarding'] ?? false,
      totalScore: json['total_score'] ?? 0,
      categoryScores: Map<String, int>.from(json['category_scores'] ?? {}),
    );
  }
}

class QuizComparisonResult {
  final bool hasComparison;
  final String? message;
  final int? previousSessionId;
  final int? currentSessionId;
  final DateTime? previousDate;
  final DateTime? currentDate;
  final int? previousTotalScore;
  final int? currentTotalScore;
  final int? scoreChange;
  final double? scoreChangePercentage;
  final List<String> improvedCategories;
  final List<String> declinedCategories;
  final List<String> stableCategories;
  final List<Map<String, dynamic>> recommendations;

  QuizComparisonResult({
    required this.hasComparison,
    this.message,
    this.previousSessionId,
    this.currentSessionId,
    this.previousDate,
    this.currentDate,
    this.previousTotalScore,
    this.currentTotalScore,
    this.scoreChange,
    this.scoreChangePercentage,
    this.improvedCategories = const [],
    this.declinedCategories = const [],
    this.stableCategories = const [],
    this.recommendations = const [],
  });

  factory QuizComparisonResult.fromJson(Map<String, dynamic> json) {
    return QuizComparisonResult(
      hasComparison: json['has_comparison'] ?? false,
      message: json['message'],
      previousSessionId: json['previous_session_id'],
      currentSessionId: json['current_session_id'],
      previousDate: json['previous_date'] != null
          ? DateTime.parse(json['previous_date'])
          : null,
      currentDate: json['current_date'] != null
          ? DateTime.parse(json['current_date'])
          : null,
      previousTotalScore: json['previous_total_score'],
      currentTotalScore: json['current_total_score'],
      scoreChange: json['score_change'],
      scoreChangePercentage: (json['score_change_percentage'] as num?)
          ?.toDouble(),
      improvedCategories: List<String>.from(json['improved_categories'] ?? []),
      declinedCategories: List<String>.from(json['declined_categories'] ?? []),
      stableCategories: List<String>.from(json['stable_categories'] ?? []),
      recommendations: List<Map<String, dynamic>>.from(
        json['recommendations'] ?? [],
      ),
    );
  }
}

class QuizAnalysisResult {
  final bool hasAnalysis;
  final String? message;
  final int? sessionId;
  final DateTime? sessionDate;
  final int? totalScore;
  final Map<String, dynamic> categoriesAnalysis;
  final List<String> strengthAreas;
  final List<String> weaknessAreas;
  final Map<String, dynamic> overallRating;

  QuizAnalysisResult({
    required this.hasAnalysis,
    this.message,
    this.sessionId,
    this.sessionDate,
    this.totalScore,
    this.categoriesAnalysis = const {},
    this.strengthAreas = const [],
    this.weaknessAreas = const [],
    this.overallRating = const {},
  });

  factory QuizAnalysisResult.fromJson(Map<String, dynamic> json) {
    return QuizAnalysisResult(
      hasAnalysis: json['has_analysis'] ?? false,
      message: json['message'],
      sessionId: json['session_id'],
      sessionDate: json['session_date'] != null
          ? DateTime.parse(json['session_date'])
          : null,
      totalScore: json['total_score'],
      categoriesAnalysis: json['categories_analysis'] ?? {},
      strengthAreas: List<String>.from(json['strength_areas'] ?? []),
      weaknessAreas: List<String>.from(json['weakness_areas'] ?? []),
      overallRating: json['overall_rating'] ?? {},
    );
  }
}

// ============================================
// 🌅🌙 نماذج كويز الصباح والمساء (Daily Quiz)
// ============================================

enum QuizTimeOfDay { morning, evening, anytime }

class DailyQuizQuestion {
  final int id;
  final String questionText;
  final String category;
  final int defaultOrder;
  final bool isActive;
  final String timeOfDay;
  final List<DailyQuizOption> options;

  DailyQuizQuestion({
    required this.id,
    required this.questionText,
    required this.category,
    required this.defaultOrder,
    required this.isActive,
    required this.timeOfDay,
    required this.options,
  });

  factory DailyQuizQuestion.fromJson(Map<String, dynamic> json) {
    return DailyQuizQuestion(
      id: json['id'],
      questionText: json['question_text'],
      category: json['category'],
      defaultOrder: json['default_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      timeOfDay: json['time_of_day'] ?? 'both',
      options: (json['options'] as List? ?? [])
          .map((o) => DailyQuizOption.fromJson(o))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'category': category,
      'default_order': defaultOrder,
      'is_active': isActive,
      'time_of_day': timeOfDay,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

class DailyQuizOption {
  final int id;
  final String optionText;
  final int scoreValue;
  final int order;

  DailyQuizOption({
    required this.id,
    required this.optionText,
    required this.scoreValue,
    required this.order,
  });

  factory DailyQuizOption.fromJson(Map<String, dynamic> json) {
    return DailyQuizOption(
      id: json['id'],
      optionText: json['option_text'],
      scoreValue: json['score_value'] ?? 0,
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'option_text': optionText,
      'score_value': scoreValue,
      'order': order,
    };
  }
}

class DailyQuizSession {
  final int id;
  final DateTime sessionDate;
  final String timeOfDay;
  final int totalScore;
  final String? notes;
  final DateTime createdAt;

  DailyQuizSession({
    required this.id,
    required this.sessionDate,
    required this.timeOfDay,
    required this.totalScore,
    this.notes,
    required this.createdAt,
  });

  factory DailyQuizSession.fromJson(Map<String, dynamic> json) {
    return DailyQuizSession(
      id: json['id'],
      sessionDate: DateTime.parse(json['session_date']),
      timeOfDay: json['time_of_day'],
      totalScore: json['total_score'] ?? 0,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class DailyQuizStatus {
  final DateTime date;
  final bool morningCompleted;
  final bool eveningCompleted;
  final DateTime? morningCompletedAt;
  final DateTime? eveningCompletedAt;
  final int morningScore;
  final int eveningScore;

  DailyQuizStatus({
    required this.date,
    required this.morningCompleted,
    required this.eveningCompleted,
    this.morningCompletedAt,
    this.eveningCompletedAt,
    required this.morningScore,
    required this.eveningScore,
  });

  factory DailyQuizStatus.fromJson(Map<String, dynamic> json) {
    return DailyQuizStatus(
      date: DateTime.parse(json['date']),
      morningCompleted: json['morning_completed'] ?? false,
      eveningCompleted: json['evening_completed'] ?? false,
      morningCompletedAt: json['morning_completed_at'] != null
          ? DateTime.parse(json['morning_completed_at'])
          : null,
      eveningCompletedAt: json['evening_completed_at'] != null
          ? DateTime.parse(json['evening_completed_at'])
          : null,
      morningScore: json['morning_score'] ?? 0,
      eveningScore: json['evening_score'] ?? 0,
    );
  }

  bool get isFullyCompleted => morningCompleted && eveningCompleted;
  bool get isPartiallyCompleted => morningCompleted || eveningCompleted;
  double get completionPercentage {
    int completed = 0;
    if (morningCompleted) completed++;
    if (eveningCompleted) completed++;
    return (completed / 2) * 100;
  }
}
