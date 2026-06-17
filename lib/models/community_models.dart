// lib/models/community_models.dart
import 'dart:convert';

enum CommunityPostType { question, experience, tip, support, achievement }

enum CommunityReactionType { like, love, support, insightful, celebrate }

class CommunityUser {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? healthCondition;
  final int memberSinceDays;
  final int postsCount;
  final int helpfulCount;
  final bool isVerified;

  CommunityUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.healthCondition,
    required this.memberSinceDays,
    required this.postsCount,
    required this.helpfulCount,
    this.isVerified = false,
  });

  factory CommunityUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CommunityUser(
        id: 0,
        name: 'مستخدم',
        memberSinceDays: 0,
        postsCount: 0,
        helpfulCount: 0,
        isVerified: false,
      );
    }
    return CommunityUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'مستخدم',
      avatarUrl: json['avatar_url'],
      healthCondition: json['health_condition'],
      memberSinceDays: json['member_since_days'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      helpfulCount: json['helpful_count'] ?? 0,
      isVerified: json['is_verified'] ?? false,
    );
  }

  String get memberSinceLabel {
    if (memberSinceDays < 30) return 'عضو جديد';
    if (memberSinceDays < 365) return 'عضو نشط';
    return 'عضو متمرس';
  }

  String get badge {
    if (helpfulCount > 100) return '💎 خبير';
    if (helpfulCount > 50) return '⭐ مساعد';
    if (helpfulCount > 10) return '👍 نشيط';
    return '👤 عضو';
  }
}

// lib/models/community_models.dart

// أضف هذا الكود بعد تعريف CommunityNotification

class CommunityGroup {
  final int id;
  final String name;
  final String description;
  final String? icon;
  final String conditionTag;
  final int membersCount;
  final int postsCount;
  final bool isJoined;
  final bool isPrivate;
  final List<String> tags;

  CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    required this.conditionTag,
    required this.membersCount,
    required this.postsCount,
    required this.isJoined,
    required this.isPrivate,
    required this.tags,
  });

  factory CommunityGroup.fromJson(Map<String, dynamic> json) {
    return CommunityGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
      conditionTag: json['condition_tag'] ?? 'general',
      membersCount: json['members_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      isJoined: json['is_joined'] ?? false,
      isPrivate: json['is_private'] ?? false,
      tags: _parseTags(json['tags']),
    );
  }

  static List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) {
      return tags.map((t) => t.toString()).toList();
    }
    if (tags is String) {
      try {
        final decoded = json.decode(tags);
        if (decoded is List) {
          return decoded.map((t) => t.toString()).toList();
        }
      } catch (_) {}
      return [];
    }
    return [];
  }

  String get conditionLabel {
    switch (conditionTag.toLowerCase()) {
      case 'diabetes':
        return 'السكري';
      case 'hypertension':
        return 'ضغط الدم';
      case 'obesity':
        return 'السمنة';
      case 'heart':
        return 'أمراض القلب';
      case 'general':
        return 'عام';
      default:
        return conditionTag;
    }
  }

  String get conditionIcon {
    switch (conditionTag.toLowerCase()) {
      case 'diabetes':
        return '🩸';
      case 'hypertension':
        return '💓';
      case 'obesity':
        return '⚖️';
      case 'heart':
        return '❤️';
      case 'general':
        return '👥';
      default:
        return '👤';
    }
  }
}

class CommunityPost {
  final int id;
  final CommunityUser author;
  final CommunityPostType type;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewsCount;
  final int commentsCount;
  final int reactionsCount;
  final Map<CommunityReactionType, int> reactions;
  final bool isPinned;
  final bool isFeatured;
  final bool isAnonymous;
  final String? conditionTag;
  final int? groupId;
  final String? groupName;
  final String? groupIcon;
  

  CommunityPost({
    required this.id,
    required this.author,
    required this.type,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
    required this.viewsCount,
    required this.commentsCount,
    required this.reactionsCount,
    required this.reactions,
    required this.isPinned,
    required this.isFeatured,
    required this.isAnonymous,
    this.conditionTag,
    this.groupId,
    this.groupName,
    this.groupIcon,
  });

  // في community_models.dart
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] ?? 0,
      author: CommunityUser.fromJson(json['author']),
      type: _parsePostType(json['post_type'] ?? 'question'),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      tags: _parseTags(json['tags']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTimeNullable(json['updated_at']),
      viewsCount: json['views_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      reactionsCount: json['likes_count'] ?? 0,
      reactions: {},
      isPinned: json['is_pinned'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      isAnonymous: json['is_anonymous'] ?? false,
      conditionTag: json['category'], // category هو conditionTag
      groupId: json['group_id'], // ✅ أضف هذا السطر
      groupName: json['group_name'], // ✅ أضف هذا السطر
    );
  }

  static List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) {
      return tags.map((t) => t.toString()).toList();
    }
    if (tags is String) {
      try {
        final decoded = json.decode(tags);
        if (decoded is List) {
          return decoded.map((t) => t.toString()).toList();
        }
      } catch (_) {}
      return [];
    }
    return [];
  }

  static final RegExp _tzRegex = RegExp(r'[+-]\d{2}:\d{2}$');

  static DateTime _parseDateTime(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      String normalized = dateStr.trim();
      // Backend sends UTC without timezone marker — assume UTC and convert to local
      if (!normalized.endsWith('Z') && !_tzRegex.hasMatch(normalized)) {
        normalized += 'Z';
      }
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseDateTimeNullable(String? dateStr) {
    if (dateStr == null) return null;
    try {
      String normalized = dateStr.trim();
      if (!normalized.endsWith('Z') && !_tzRegex.hasMatch(normalized)) {
        normalized += 'Z';
      }
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return null;
    }
  }

  static CommunityPostType _parsePostType(String value) {
    switch (value.toLowerCase()) {
      case 'question':
        return CommunityPostType.question;
      case 'experience':
        return CommunityPostType.experience;
      case 'tip':
        return CommunityPostType.tip;
      case 'support':
        return CommunityPostType.support;
      case 'achievement':
        return CommunityPostType.achievement;
      default:
        return CommunityPostType.question;
    }
  }

  String get typeLabel {
    switch (type) {
      case CommunityPostType.question:
        return 'سؤال';
      case CommunityPostType.experience:
        return 'تجربة';
      case CommunityPostType.tip:
        return 'نصيحة';
      case CommunityPostType.support:
        return 'دعم';
      case CommunityPostType.achievement:
        return 'إنجاز';
    }
  }

  String get typeIcon {
    switch (type) {
      case CommunityPostType.question:
        return '❓';
      case CommunityPostType.experience:
        return '📖';
      case CommunityPostType.tip:
        return '💡';
      case CommunityPostType.support:
        return '🤝';
      case CommunityPostType.achievement:
        return '🏆';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inMinutes < 60) return 'قبل ${difference.inMinutes} دقيقة';
    if (difference.inHours < 24) return 'قبل ${difference.inHours} ساعة';
    if (difference.inDays < 7) return 'قبل ${difference.inDays} يوم';
    if (difference.inDays < 30) return 'قبل ${difference.inDays ~/ 7} أسبوع';
    if (difference.inDays < 365) return 'قبل ${difference.inDays ~/ 30} شهر';
    return 'قبل ${difference.inDays ~/ 365} سنة';
  }
}

class CommunityComment {
  final int id;
  final CommunityUser author;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final bool isHelpful;
  final bool isAuthorResponse;
  final List<CommunityComment> replies;

  CommunityComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    required this.likesCount,
    required this.isHelpful,
    required this.isAuthorResponse,
    required this.replies,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] ?? 0,
      author: CommunityUser.fromJson(json['author']),
      content: json['content'] ?? '',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTimeNullable(json['updated_at']),
      likesCount: json['likes_count'] ?? 0,
      isHelpful: json['is_helpful'] ?? false,
      isAuthorResponse: json['is_author_response'] ?? false,
      replies: (json['replies'] as List? ?? [])
          .map((r) => CommunityComment.fromJson(r))
          .toList(),
    );
  }

  static final RegExp _tzRegex = RegExp(r'[+-]\d{2}:\d{2}$');

  static DateTime _parseDateTime(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      String normalized = dateStr.trim();
      if (!normalized.endsWith('Z') && !_tzRegex.hasMatch(normalized)) {
        normalized += 'Z';
      }
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static DateTime? _parseDateTimeNullable(String? dateStr) {
    if (dateStr == null) return null;
    try {
      String normalized = dateStr.trim();
      if (!normalized.endsWith('Z') && !_tzRegex.hasMatch(normalized)) {
        normalized += 'Z';
      }
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return null;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inMinutes < 60) return 'قبل ${difference.inMinutes} دقيقة';
    if (difference.inHours < 24) return 'قبل ${difference.inHours} ساعة';
    if (difference.inDays < 7) return 'قبل ${difference.inDays} يوم';
    if (difference.inDays < 30) return 'قبل ${difference.inDays ~/ 7} أسبوع';
    if (difference.inDays < 365) return 'قبل ${difference.inDays ~/ 30} شهر';
    return 'قبل ${difference.inDays ~/ 365} سنة';
  }
}

class CommunityNotification {
  final int id;
  final String type;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  CommunityNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.data,
  });

  factory CommunityNotification.fromJson(Map<String, dynamic> json) {
    return CommunityNotification(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'general',
      message: json['message'] ?? '',
      createdAt: _parseDateTime(json['created_at']),
      isRead: json['is_read'] ?? false,
      data: json['data'],
    );
  }

  static final RegExp _tzRegex = RegExp(r'[+-]\d{2}:\d{2}$');

  static DateTime _parseDateTime(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      String normalized = dateStr.trim();
      if (!normalized.endsWith('Z') && !_tzRegex.hasMatch(normalized)) {
        normalized += 'Z';
      }
      return DateTime.parse(normalized).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'الآن';
    if (difference.inMinutes < 60) return 'قبل ${difference.inMinutes} دقيقة';
    if (difference.inHours < 24) return 'قبل ${difference.inHours} ساعة';
    if (difference.inDays < 7) return 'قبل ${difference.inDays} يوم';
    if (difference.inDays < 30) return 'قبل ${difference.inDays ~/ 7} أسبوع';
    if (difference.inDays < 365) return 'قبل ${difference.inDays ~/ 30} شهر';
    return 'قبل ${difference.inDays ~/ 365} سنة';
  }
}

// دالة مساعدة لتحميل JSON (تأكد من import 'dart:convert')
