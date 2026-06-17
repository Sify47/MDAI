// lib/services/community_api.dart

import 'dart:convert';
import '../models/community_models.dart';
import '../services/base_api_service.dart';

class CommunityApi {
  static const String _pathPrefix = 'api/community';

  // ============================================
  // 📝 1. المنشورات
  // ============================================

  static Future<List<CommunityPost>> getPosts({
    String? conditionTag,
    CommunityPostType? type,
    int? limit,
    int? offset,
    bool? featured,
  }) async {
    print('\n📋 [CommunityApi] جلب المنشورات');

    try {
      final queryParams = <String, String>{};

      if (conditionTag != null) {
        queryParams['condition_tag'] = conditionTag;
      }
      if (type != null) {
        queryParams['type'] = type.name;
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      if (offset != null) {
        queryParams['offset'] = offset.toString();
      }
      if (featured != null) {
        queryParams['featured'] = featured.toString();
      }

      final response = await BaseApiService.get(
        '$_pathPrefix/posts',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((p) => CommunityPost.fromJson(p)).toList();
      } else {
        print('❌ فشل جلب المنشورات: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  static Future<CommunityPost?> getPost(int postId) async {
    print('\n📋 [CommunityApi] جلب منشور محدد');

    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/posts/$postId',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CommunityPost.fromJson(data);
      } else {
        print('❌ فشل جلب المنشور: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  static Future<CommunityPost?> createPost(
    Map<String, dynamic> postData,
  ) async {
    print('\n📋 [CommunityApi] إنشاء منشور جديد');
    print('📦 البيانات: $postData');

    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/posts',
        body: postData,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      print('📄 محتوى الاستجابة: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return CommunityPost.fromJson(data);
      } else {
        print('❌ فشل إنشاء المنشور: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  static Future<bool> updatePost(
    int postId, {
    String? title,
    String? content,
    List<String>? tags,
    String? postType,
    String? category,
    bool? isAnonymous,
    int? groupId,
  }) async {
    print('\n📋 [CommunityApi] تحديث منشور');

    try {
      final body = {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (tags != null) 'tags': tags,
        if (postType != null) 'post_type': postType,
        if (category != null) 'category': category,
        if (isAnonymous != null) 'is_anonymous': isAnonymous,
        if (groupId != null) 'group_id': groupId,
      };

      final response = await BaseApiService.put(
        '$_pathPrefix/posts/$postId',
        body: body,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  static Future<bool> deletePost(int postId) async {
    print('\n📋 [CommunityApi] حذف منشور');

    try {
      final response = await BaseApiService.delete(
        '$_pathPrefix/posts/$postId',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================
  // 💬 2. التعليقات
  // ============================================

  static Future<List<CommunityComment>> getPostComments(int postId) async {
    print('\n📋 [CommunityApi] جلب تعليقات المنشور');

    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/posts/$postId/comments',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((c) => CommunityComment.fromJson(c)).toList();
      } else {
        print('❌ فشل جلب التعليقات: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  static Future<CommunityComment?> addComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    print('\n📋 [CommunityApi] إضافة تعليق');

    try {
      final body = {
        'content': content,
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
      };

      final response = await BaseApiService.post(
        '$_pathPrefix/posts/$postId/comments',
        body: body,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return CommunityComment.fromJson(data);
      } else {
        print('❌ فشل إضافة التعليق: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return null;
    }
  }

  static Future<bool> markCommentAsHelpful(int commentId) async {
    print('\n📋 [CommunityApi] تمييز التعليق كمساعد');

    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/comments/$commentId/helpful',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================
  // ❤️ 3. التفاعلات
  // ============================================

  static Future<bool> addReaction({
    required int postId,
    required CommunityReactionType reactionType,
  }) async {
    print('\n📋 [CommunityApi] إضافة تفاعل');

    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/posts/$postId/reactions',
        body: {'reaction_type': reactionType.name},
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  static Future<bool> removeReaction(int postId) async {
    print('\n📋 [CommunityApi] إزالة تفاعل');

    try {
      final response = await BaseApiService.delete(
        '$_pathPrefix/posts/$postId/reactions',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================
  // 👥 4. المجموعات
  // ============================================

  static Future<List<CommunityGroup>> getGroups({
    String? conditionTag,
    bool? joinedOnly,
  }) async {
    print('\n📋 [CommunityApi] جلب المجموعات');

    try {
      final queryParams = <String, String>{};

      if (conditionTag != null) {
        queryParams['condition_tag'] = conditionTag;
      }
      if (joinedOnly != null) {
        queryParams['joined_only'] = joinedOnly.toString();
      }

      final response = await BaseApiService.get(
        '$_pathPrefix/groups',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((g) => CommunityGroup.fromJson(g)).toList();
      } else {
        print('❌ فشل جلب المجموعات: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  // جلب تفاصيل مجموعة محددة
  static Future<Map<String, dynamic>> getGroup(int groupId) async {
    print('\n📋 [CommunityApi] جلب تفاصيل المجموعة $groupId');

    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/groups/$groupId',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ فشل جلب تفاصيل المجموعة: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return {};
    }
  }

  // جلب منشورات مجموعة محددة
  static Future<List<CommunityPost>> getGroupPosts(int groupId) async {
    print('\n📋 [CommunityApi] جلب منشورات المجموعة $groupId');

    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/groups/$groupId/posts',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((p) => CommunityPost.fromJson(p)).toList();
      } else {
        print('❌ فشل جلب منشورات المجموعة: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  static Future<bool> joinGroup(int groupId) async {
    print('\n📋 [CommunityApi] الانضمام لمجموعة');

    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/groups/$groupId/join',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  static Future<bool> leaveGroup(int groupId) async {
    print('\n📋 [CommunityApi] مغادرة مجموعة');

    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/groups/$groupId/leave',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================
  // 🔔 5. الإشعارات
  // ============================================

  static Future<List<CommunityNotification>> getNotifications({
    bool? unreadOnly,
    int? limit,
  }) async {
    print('\n📋 [CommunityApi] جلب الإشعارات');

    try {
      final queryParams = <String, String>{};

      if (unreadOnly != null) {
        queryParams['unread_only'] = unreadOnly.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final response = await BaseApiService.get(
        '$_pathPrefix/notifications',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((n) => CommunityNotification.fromJson(n)).toList();
      } else {
        print('❌ فشل جلب الإشعارات: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return [];
    }
  }

  static Future<bool> markNotificationAsRead(int notificationId) async {
    print('\n📋 [CommunityApi] تمييز الإشعار كمقروء');

    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/notifications/$notificationId/read',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  static Future<bool> markAllNotificationsAsRead() async {
    print('\n📋 [CommunityApi] تمييز جميع الإشعارات كمقروءة');

    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/notifications/read-all',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ============================================
  // 📊 6. الإحصائيات
  // ============================================

  static Future<Map<String, dynamic>> getUserStats() async {
    print('\n📋 [CommunityApi] جلب إحصائيات المستخدم');

    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/stats/user',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ فشل جلب الإحصائيات: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> getCommunityStats() async {
    print('\n📋 [CommunityApi] جلب إحصائيات المجتمع');

    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/stats/community',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ فشل جلب إحصائيات المجتمع: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return {};
    }
  }

  // ============================================
  // 🔄 7. التفاعلات (إضافية)
  // ============================================

  // التحقق من حالة التفاعل مع منشور
  static Future<bool> getReactionStatus(int postId) async {
    print('\n🔍 [CommunityApi] التحقق من حالة التفاعل للمنشور $postId');

    try {
      final response = await BaseApiService.get(
        '$_pathPrefix/posts/$postId/reaction-status',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['has_reacted'] ?? false;
      } else {
        print('❌ فشل جلب حالة التفاعل: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // تبديل حالة التفاعل (تضيف أو تزيل)
  static Future<Map<String, dynamic>> toggleReaction(int postId) async {
    print('\n🔄 [CommunityApi] تبديل حالة التفاعل للمنشور $postId');

    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/posts/$postId/toggle-reaction',
      );

      print('📥 حالة الاستجابة: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'likesCount': data['likes_count'] ?? 0,
          'hasReacted': data['has_reacted'] ?? false,
        };
      } else {
        print('❌ فشل تبديل التفاعل: ${response.statusCode}');
        return {'success': false, 'likesCount': 0, 'hasReacted': false};
      }
    } catch (e) {
      print('❌ خطأ: $e');
      return {'success': false, 'likesCount': 0, 'hasReacted': false};
    }
  }
}
