// lib/screens/community/community_main_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/models/user_model.dart';
import 'package:vita/screens/community/groups_screen.dart';
import 'package:vita/screens/community/group_detail_screen.dart';
import 'package:vita/screens/community/saved_posts_screen.dart';
import 'profile_screen.dart';
import 'package:vita/services/community_api.dart';
import 'package:vita/models/community_models.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({super.key});

  @override
  State<CommunityMainScreen> createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends State<CommunityMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _currentUser;

  List<CommunityPost> _posts = [];
  List<CommunityPost> _popularPosts = [];
  List<ActivityItem> _activities = []; // تغيير من notifications إلى activities
  List<CommunityGroup> _groups = [];
  bool _isLoading = true;
  String _selectedSort = 'best';
  int? _selectedGroupId; // null means "All groups"
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _currentUserId;

  // تخزين حالة الإعجاب لكل منشور
  Map<int, bool> _reactionStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
    _loadData();
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final userData = PrefsHelper.getUserData();
    setState(() {
      _currentUserId = userData['id'];
    });
  }

  Future<void> _loadGroups() async {
    try {
      // جلب جميع المجموعات (للفلتر)
      final allGroups = await CommunityApi.getGroups();
      // جلب المجموعات المنضم إليها فقط (للعرض في الـ chips)
      final joinedGroups = await CommunityApi.getGroups(joinedOnly: true);
      setState(() {
        _groups = joinedGroups; // عرض المجموعات المنضم إليها فقط في الـ chips
      });
    } catch (e) {
      print('Error loading groups: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final posts = await CommunityApi.getPosts(limit: 50);
      // تحميل الأنشطة (التفاعلات) بدلاً من الإشعارات
      // final activities = await CommunityApi.getUserActivities(limit: 50);

      final popular = posts.where((p) => p.reactionsCount > 10).toList();

      // جلب حالة الإعجاب لكل منشور
      final reactionMap = <int, bool>{};
      for (var post in posts) {
        final hasReacted = await CommunityApi.getReactionStatus(post.id);
        reactionMap[post.id] = hasReacted;
      }

      setState(() {
        _posts = posts;
        _popularPosts = popular;
        // _activities = activities;
        _reactionStatus = reactionMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading community data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<CommunityPost> get _sortedPosts {
    List<CommunityPost> groupFiltered = _posts;
    if (_selectedGroupId != null) {
      groupFiltered = _posts.where((post) {
        if (post.groupId != null && post.groupId == _selectedGroupId) {
          return true;
        }
        final conditionTag = _getConditionTagForGroupId(_selectedGroupId!);
        if (conditionTag != null && post.conditionTag == conditionTag) {
          return true;
        }
        return false;
      }).toList();
    }

    final List<CommunityPost> filtered = _searchQuery.isEmpty
        ? groupFiltered
        : groupFiltered
              .where(
                (p) =>
                    p.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    p.content.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    p.tags.any(
                      (t) =>
                          t.toLowerCase().contains(_searchQuery.toLowerCase()),
                    ),
              )
              .toList();

    switch (_selectedSort) {
      case 'hot':
        return [...filtered]..sort(
          (a, b) => (b.reactionsCount + b.commentsCount).compareTo(
            a.reactionsCount + a.commentsCount,
          ),
        );
      case 'new':
        return [...filtered]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'top':
        return [...filtered]
          ..sort((a, b) => b.reactionsCount.compareTo(a.reactionsCount));
      default:
        return filtered;
    }
  }

  String? _getConditionTagForGroupId(int groupId) {
    if (_groups.isNotEmpty) {
      try {
        final group = _groups.firstWhere((g) => g.id == groupId);
        return group.conditionTag;
      } catch (e) {}
    }

    switch (groupId) {
      case 1:
        return 'diabetes';
      case 2:
        return 'heart';
      case 3:
        return 'nutrition';
      case 4:
        return 'fitness';
      case 5:
        return 'mental';
      default:
        return null;
    }
  }

  String _getGroupNameForPost(CommunityPost post) {
    if (post.groupId != null && _groups.isNotEmpty) {
      try {
        final group = _groups.firstWhere((g) => g.id == post.groupId);
        return 'r/${group.name}';
      } catch (e) {}
    }

    if (post.groupName != null && post.groupName!.isNotEmpty) {
      return 'r/${post.groupName!}';
    }

    final category = post.conditionTag ?? 'general';
    switch (category) {
      case 'diabetes':
        return 'r/دعم مرضى السكري';
      case 'heart':
        return 'r/صحة القلب';
      case 'nutrition':
        return 'r/التغذية الصحية';
      case 'fitness':
        return 'r/اللياقة والتمارين';
      case 'mental':
        return 'r/الصحة النفسية';
      default:
        return 'r/صحة';
    }
  }

  int? _getGroupIdForPost(CommunityPost post) {
    if (post.groupId != null && post.groupId! > 0) {
      return post.groupId;
    }

    final category = post.conditionTag ?? 'general';
    switch (category) {
      case 'diabetes':
        return 1;
      case 'heart':
        return 2;
      case 'nutrition':
        return 3;
      case 'fitness':
        return 4;
      case 'mental':
        return 5;
      default:
        return null;
    }
  }

  Future<void> _toggleReaction(CommunityPost post) async {
    final result = await CommunityApi.toggleReaction(post.id);

    if (result['success'] && mounted) {
      setState(() {
        _reactionStatus[post.id] = result['hasReacted'];
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = CommunityPost(
            id: post.id,
            author: post.author,
            type: post.type,
            title: post.title,
            content: post.content,
            tags: post.tags,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
            viewsCount: post.viewsCount,
            commentsCount: post.commentsCount,
            reactionsCount: result['likesCount'],
            reactions: post.reactions,
            isPinned: post.isPinned,
            isFeatured: post.isFeatured,
            isAnonymous: post.isAnonymous,
            conditionTag: post.conditionTag,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['hasReacted'] ? '👍 تم التقييم' : '👎 تم إزالة التقييم',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _deletePost(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنشور'),
        content: const Text(
          'هل أنت متأكد من حذف هذا المنشور؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await CommunityApi.deletePost(post.id);
      if (success && mounted) {
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
          _popularPosts.removeWhere((p) => p.id == post.id);
          _reactionStatus.remove(post.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حذف المنشور بنجاح'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editPost(CommunityPost post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen(postToEdit: post)),
    );
    if (result == true) {
      _loadData();
    }
  }

  bool _isOwnPost(CommunityPost post) {
    if (post.isAnonymous) return false;
    return _currentUserId != null && post.author.id == _currentUserId;
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  Color _getPostTypeColor(CommunityPostType type) {
    switch (type) {
      case CommunityPostType.question:
        return Colors.blue;
      case CommunityPostType.experience:
        return Colors.purple;
      case CommunityPostType.tip:
        return Colors.green;
      case CommunityPostType.support:
        return Colors.orange;
      case CommunityPostType.achievement:
        return Colors.amber;
    }
  }

  // ==================== بطاقة المنشور المحسنة ====================
  Widget _buildPostCard(CommunityPost post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final author = post.author;
    final isOwnPost = _isOwnPost(post);
    final hasReacted = _reactionStatus[post.id] ?? false;
    final groupName = _getGroupNameForPost(post);
    final groupId = _getGroupIdForPost(post);

    return InkWell(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
        if (shouldRefresh == true) {
          _loadData();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  // أيقونة/صورة المجموعة
                  GestureDetector(
                    onTap: () {
                      if (groupId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupDetailScreen(groupId: groupId),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.green.withOpacity(0.15),
                      child: Text(
                        groupName[2].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (groupId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          GroupDetailScreen(groupId: groupId),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                groupName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                // TODO: الانتقال إلى صفحة المستخدم
                              },
                              child: Text(
                                post.isAnonymous ? 'مستخدم مجهول' : author.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '· ${post.timeAgo}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // نوع المنشور
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPostTypeColor(
                              post.type,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                post.typeIcon,
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                post.typeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getPostTypeColor(post.type),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: Colors.grey[500],
                    ),
                    onSelected: (value) {
                      if (value == 'edit' && isOwnPost) {
                        _editPost(post);
                      } else if (value == 'delete' && isOwnPost) {
                        _deletePost(post);
                      } else if (value == 'save') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم حفظ المنشور'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      } else if (value == 'share') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ الرابط'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      if (isOwnPost) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('تعديل'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('حذف', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'save',
                        child: Row(
                          children: [
                            Icon(Icons.bookmark_border, size: 18),
                            SizedBox(width: 8),
                            Text('حفظ'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 18),
                            SizedBox(width: 8),
                            Text('مشاركة'),
                          ],
                        ),
                      ),
                    ],
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // عنوان المنشور
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // محتوى المنشور
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // الوسوم
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: post.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Divider(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              height: 1,
            ),

            // أزرار التفاعل المحسنة (تصغير المسافات)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  // زر التقييم
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleReaction(post),
                      borderRadius: BorderRadius.circular(20),
                      splashColor: Colors.orange.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasReacted
                                  ? Icons.arrow_upward
                                  : Icons.arrow_upward_outlined,
                              size: 18,
                              color: hasReacted
                                  ? Colors.orange
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatCount(post.reactionsCount),
                              style: TextStyle(
                                fontSize: 13,
                                color: hasReacted
                                    ? Colors.orange
                                    : Colors.grey[500],
                                fontWeight: hasReacted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زر التعليقات
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final shouldRefresh = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(post: post),
                          ),
                        );
                        if (shouldRefresh == true) {
                          _loadData();
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      splashColor: Colors.grey.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                            if (post.commentsCount > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                _formatCount(post.commentsCount),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // زر المشاركة
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ الرابط'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      splashColor: Colors.grey.withOpacity(0.2),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Icon(
                          Icons.share_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
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

  // ==================== بطاقة النشاط (التفاعلات) ====================
  Widget _buildActivityCard(ActivityItem activity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color iconColor;
    String actionText;

    switch (activity.type) {
      case ActivityType.reaction:
        icon = Icons.thumb_up_outlined;
        iconColor = Colors.orange;
        actionText = 'أعجب بمنشورك';
        break;
      case ActivityType.comment:
        icon = Icons.chat_bubble_outline;
        iconColor = Colors.blue;
        actionText = 'علق على منشورك';
        break;
      case ActivityType.reply:
        icon = Icons.reply_outlined;
        iconColor = Colors.green;
        actionText = 'رد على تعليقك';
        break;
      case ActivityType.mention:
        icon = Icons.alternate_email;
        iconColor = Colors.purple;
        actionText = 'أشار إليك';
        break;
    }

    return GestureDetector(
      onTap: () {
        // الانتقال إلى المنشور المرتبط
        if (activity.postId != null) {
          // TODO: الانتقال إلى تفاصيل المنشور
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activity.isRead
              ? (isDark ? Colors.grey[850] : Colors.white)
              : (isDark ? Colors.blue.withOpacity(0.1) : Colors.blue[50]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '${activity.actorName} $actionText',
                  style: TextStyle(
                    fontWeight: activity.isRead
                        ? FontWeight.normal
                        : FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activity.contentPreview != null)
                  Text(
                    '"${activity.contentPreview}"',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  activity.timeAgo,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          trailing: !activity.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ==================== قسم المنشورات الشائعة (Horizontal Carousel) ====================
  Widget _buildTrendingSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_popularPosts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.red.shade400],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.whatshot,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'شائع لديك 🔥',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _popularPosts.take(10).length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final post = _popularPosts[index];
                return _buildTrendingCard(post);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(CommunityPost post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
        if (shouldRefresh == true) _loadData();
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.red.shade400],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${post.reactionsCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          post.typeIcon,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_upward,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatCount(post.reactionsCount),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatCount(post.commentsCount),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== قائمة الفلاتر الثابتة (Sticky Header) ====================
  Widget _buildStickyFilters() {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Group filter chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildAllGroupsChip(),
                const SizedBox(width: 8),
                ..._groups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildGroupChip(group),
                  ),
                ),
              ],
            ),
          ),
          // Sort chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildSortChip('best', 'الأفضل'),
                _buildSortChip('hot', 'ساخن'),
                _buildSortChip('new', 'جديد'),
                _buildSortChip('top', 'الأعلى'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ويدجتات الفلاتر ====================
  Widget _buildSortChip(String value, String label) {
    final isSelected = _selectedSort == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedSort = value),
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.grey[400] : Colors.grey[700]),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildGroupChip(CommunityGroup group) {
    final isSelected = _selectedGroupId == group.id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(group.name),
        selected: isSelected,
        onSelected: (_) =>
            setState(() => _selectedGroupId = isSelected ? null : group.id),
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
        selectedColor: Colors.green.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.green
              : (isDark ? Colors.grey[400] : Colors.grey[700]),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        avatar: CircleAvatar(
          radius: 12,
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Text(
            group.icon ?? group.conditionIcon,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildAllGroupsChip() {
    final isSelected = _selectedGroupId == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: const Text('الكل'),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedGroupId = null),
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.grey[400] : Colors.grey[700]),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        avatar: const Icon(Icons.all_inclusive, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ==================== حالات التحميل والفارغة المحسنة ====================
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل المجتمع...',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String message, {
    VoidCallback? onAction,
    String? actionText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[600],
            ),
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== القائمة الجانبية ====================
  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userData = PrefsHelper.getUserData();
    final userName = _currentUser?.name ?? 'مستخدم';
    final userEmail = userData['email'] ?? '';

    return Drawer(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (userEmail.isNotEmpty)
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'عرض الملف الشخصي',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.home_outlined,
                    title: 'الرئيسية',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedGroupId = null;
                        _selectedSort = 'best';
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.trending_up,
                    title: 'الشائع',
                    onTap: () {
                      setState(() => _selectedSort = 'hot');
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.new_releases_outlined,
                    title: 'الأحدث',
                    onTap: () {
                      setState(() => _selectedSort = 'new');
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.group_outlined,
                    title: 'المجموعات',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GroupsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.bookmark_border,
                    title: 'المحفوظات',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedPostsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 32, thickness: 1),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'القواعد والإرشادات',
                    onTap: () {
                      Navigator.pop(context);
                      _showRulesDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'سياسة الخصوصية',
                    onTap: () {
                      Navigator.pop(context);
                      _showPrivacyPolicyDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'الإعدادات',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: فتح صفحة الإعدادات
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () => Navigator.pop(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'الإصدار 1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: isDark ? Colors.grey[500] : Colors.grey[400],
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: AppColors.primary.withOpacity(0.1),
      splashColor: AppColors.primary.withOpacity(0.2),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.orange),
            SizedBox(width: 8),
            Text('قواعد المجتمع'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleItem(
                '1',
                'احترم الجميع',
                'تعامل بأدب واحترام مع جميع الأعضاء',
              ),
              const Divider(),
              _buildRuleItem(
                '2',
                'لا تنشر محتوى مسيء',
                'تجنب نشر أي محتوى مسيء أو غير لائق',
              ),
              const Divider(),
              _buildRuleItem(
                '3',
                'لا تشارك معلومات شخصية',
                'حافظ على خصوصيتك وخصوصية الآخرين',
              ),
              const Divider(),
              _buildRuleItem(
                '4',
                'استخدم التصنيفات المناسبة',
                'اختر التصنيف الصحيح لمنشوراتك',
              ),
              const Divider(),
              _buildRuleItem(
                '5',
                'اتبع إرشادات المشرفين',
                'التزم بتعليمات فريق الإدارة',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('أفهم'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildRuleItem(String number, String title, String description) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.blue),
            SizedBox(width: 8),
            Text('سياسة الخصوصية'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نحن نلتزم بحماية خصوصية بياناتك:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPrivacyItem(
                '📊',
                'جمع البيانات',
                'نجمع فقط البيانات اللازمة لتحسين صحتك',
              ),
              const SizedBox(height: 8),
              _buildPrivacyItem(
                '🔒',
                'أمان البيانات',
                'نستخدم أحدث تقنيات التشفير لحماية بياناتك',
              ),
              const SizedBox(height: 8),
              _buildPrivacyItem(
                '🤝',
                'مشاركة البيانات',
                'لا نشارك بياناتك مع أطراف ثالثة بدون إذنك',
              ),
              const SizedBox(height: 8),
              _buildPrivacyItem(
                '🗑️',
                'حذف البيانات',
                'يمكنك طلب حذف بياناتك في أي وقت',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('أفهم'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildPrivacyItem(String icon, String title, String description) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await PrefsHelper.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('تسجيل الخروج'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // ==================== BUILD METHOD ====================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activityCount = _activities.where((a) => !a.isRead).length;

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'ابحث في المجتمع...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('المجتمع'),
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() => _isSearching = !_isSearching),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _tabController.animateTo(1),
              ),
              if (activityCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      activityCount > 9 ? '9+' : '$activityCount',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: _buildStickyFilters(), // استخدام الفلاتر الثابتة
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : TabBarView(
              controller: _tabController,
              children: [
                // تبويب المنشورات
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _sortedPosts.isEmpty
                      ? _buildEmptyState(
                          'لا توجد منشورات',
                          onAction: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreatePostScreen(),
                              ),
                            );
                            if (result == true) _loadData();
                          },
                          actionText: 'أنشئ أول منشور',
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                if (index == 3 && _popularPosts.isNotEmpty) {
                                  return Column(
                                    children: [
                                      _buildPostCard(_sortedPosts[index]),
                                      const SizedBox(height: 8),
                                      _buildTrendingSection(),
                                    ],
                                  );
                                }
                                return _buildPostCard(_sortedPosts[index]);
                              }, childCount: _sortedPosts.length),
                            ),
                          ],
                        ),
                ),
                // تبويب النشاطات (التفاعلات)
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: _activities.isEmpty
                      ? _buildEmptyState('لا توجد نشاطات بعد')
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, top: 8),
                          itemCount: _activities.length,
                          itemBuilder: (context, index) =>
                              _buildActivityCard(_activities[index]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (result == true) _loadData();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ==================== نموذج بيانات النشاط ====================
enum ActivityType { reaction, comment, reply, mention }

class ActivityItem {
  final String id;
  final ActivityType type;
  final String actorName;
  final int? actorId;
  final int? postId;
  final int? commentId;
  final String? contentPreview;
  final DateTime createdAt;
  final bool isRead;

  ActivityItem({
    required this.id,
    required this.type,
    required this.actorName,
    this.actorId,
    this.postId,
    this.commentId,
    this.contentPreview,
    required this.createdAt,
    this.isRead = false,
  });

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 7)
      return '${(difference.inDays / 7).floor()} أسابيع';
    if (difference.inDays > 0) return '${difference.inDays} أيام';
    if (difference.inHours > 0) return '${difference.inHours} ساعات';
    if (difference.inMinutes > 0) return '${difference.inMinutes} دقائق';
    return 'الآن';
  }
}
