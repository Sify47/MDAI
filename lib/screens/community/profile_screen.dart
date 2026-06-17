// lib/screens/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/services/community_api.dart';
import 'package:vita/models/community_models.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'package:vita/screens/community/post_detail_screen.dart';
import 'package:vita/screens/community/create_post_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> _userData = {};
  List<CommunityPost> _userPosts = [];
  List<Map<String, dynamic>> _userComments =
      []; // تخزين التعليقات مع معلومات المنشور
  List<CommunityPost> _allPosts = [];
  Map<String, dynamic> _userStats = {};
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  bool _isLoadingComments = true;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _isLoadingPosts = true;
      _isLoadingComments = true;
    });

    await _loadUserData();
    await _loadUserStats();
    await _loadAllPosts();
    await _loadUserPosts();
    await _loadUserComments();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    final userData = PrefsHelper.getUserData();
    setState(() {
      _userData = userData;
      _currentUserId = PrefsHelper.getUserId();
    });
    print('📱 بيانات المستخدم من PrefsHelper:');
    print('  - ID: $_currentUserId');
    print('  - الوزن: ${userData['weight']}');
    print('  - الطول: ${userData['height']}');
    print('  - الهدف: ${userData['goal']}');
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await CommunityApi.getUserStats();
      setState(() {
        _userStats = stats;
      });
      print('📊 إحصائيات المستخدم: $_userStats');
    } catch (e) {
      print('❌ خطأ في جلب الإحصائيات: $e');
      setState(() {
        _userStats = {};
      });
    }
  }

  Future<void> _loadAllPosts() async {
    try {
      _allPosts = await CommunityApi.getPosts(limit: 100);
      print('📝 عدد المنشورات الكلي: ${_allPosts.length}');
      for (var post in _allPosts) {
        print(
          '  - منشور ID: ${post.id}, Author ID: ${post.author.id}, الاسم: ${post.author.name}',
        );
      }
    } catch (e) {
      print('❌ خطأ في جلب المنشورات: $e');
    }
  }

  Future<void> _loadUserPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      if (_currentUserId != null && _currentUserId! > 0) {
        final userPosts = _allPosts.where((p) {
          if (p.isAnonymous) return false;
          return p.author.id == _currentUserId;
        }).toList();

        print('✅ منشورات المستخدم $_currentUserId: ${userPosts.length}');
        setState(() {
          _userPosts = userPosts;
        });
      } else {
        print('⚠️ لا يوجد userId، عرض جميع المنشورات مؤقتاً');
        setState(() {
          _userPosts = _allPosts;
        });
      }
      setState(() => _isLoadingPosts = false);
    } catch (e) {
      print('❌ خطأ في جلب منشورات المستخدم: $e');
      setState(() {
        _userPosts = [];
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadUserComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final allComments = <Map<String, dynamic>>[];

      // جلب تعليقات المستخدم من كل منشور
      for (var post in _allPosts) {
        try {
          final comments = await CommunityApi.getPostComments(post.id);
          for (var comment in comments) {
            if (comment.author.id == _currentUserId) {
              allComments.add({'comment': comment, 'post': post});
            }
            // جلب الردود أيضاً
            for (var reply in comment.replies) {
              if (reply.author.id == _currentUserId) {
                allComments.add({'comment': reply, 'post': post});
              }
            }
          }
        } catch (e) {
          print('⚠️ خطأ في جلب تعليقات المنشور ${post.id}: $e');
        }
      }

      // ترتيب التعليقات حسب التاريخ (الأحدث أولاً)
      allComments.sort((a, b) {
        final dateA = (a['comment'] as CommunityComment).createdAt;
        final dateB = (b['comment'] as CommunityComment).createdAt;
        return dateB.compareTo(dateA);
      });

      print('✅ تعليقات المستخدم $_currentUserId: ${allComments.length}');
      setState(() {
        _userComments = allComments;
        _isLoadingComments = false;
      });
    } catch (e) {
      print('❌ خطأ في جلب تعليقات المستخدم: $e');
      setState(() {
        _userComments = [];
        _isLoadingComments = false;
      });
    }
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

  String _getUserName() {
    if (_userData['name'] != null && _userData['name'].toString().isNotEmpty) {
      return _userData['name'];
    }
    if (_userPosts.isNotEmpty && !_userPosts.first.isAnonymous) {
      return _userPosts.first.author.name;
    }
    if (_userComments.isNotEmpty) {
      final comment = _userComments.first['comment'] as CommunityComment;
      return comment.author.name;
    }
    return 'مستخدم';
  }

  String _getUserEmail() {
    if (_userData['email'] != null &&
        _userData['email'].toString().isNotEmpty) {
      return _userData['email'];
    }
    return '';
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
        _loadAllData();
      },
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getPostTypeColor(post.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.typeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getPostTypeColor(post.type),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    post.timeAgo,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.arrow_upward, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(post.reactionsCount),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(post.commentsCount),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(post.viewsCount),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> commentData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final comment = commentData['comment'] as CommunityComment;
    final post = commentData['post'] as CommunityPost;
    final isReply = comment.replies != null;

    return GestureDetector(
      onTap: () async {
        // الانتقال إلى صفحة المنشور مع التمرير إلى التعليق
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PostDetailScreen(post: post, scrollToCommentId: comment.id),
          ),
        );
        _loadAllData();
      },
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان المنشور
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getPostTypeColor(post.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.typeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getPostTypeColor(post.type),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    comment.timeAgo,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // عنوان المنشور
              Text(
                post.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // بادئة للرد
              if (isReply)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'رد على تعليق',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),

              // محتوى التعليق
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        comment.author.name.isNotEmpty
                            ? comment.author.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.author.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.content,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // إحصائيات التفاعل
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(comment.likesCount),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.reply, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  const Text(
                    'رد',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = _getUserName();
    final userEmail = _getUserEmail();

    final postsCount = _userStats['userPostsCount'] ?? _userPosts.length;
    final commentsCount =
        _userStats['userCommentsCount'] ?? _userComments.length;
    final likesCount = _userStats['userLikesCount'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: CustomScrollView(
                slivers: [
                  // رأس البروفايل
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // الصورة الرمزية
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),

                        if (userEmail.isNotEmpty)
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),

                        if (_userData['weight'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'الوزن: ${_userData['weight']} كجم • الطول: ${_userData['height']} سم',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // إحصائيات
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'منشورات',
                                  _formatCount(postsCount),
                                  Icons.description,
                                  AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'تعليقات',
                                  _formatCount(commentsCount),
                                  Icons.chat_bubble_outline,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'إعجابات',
                                  _formatCount(likesCount),
                                  Icons.favorite_border,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // تبويب المنشورات والتعليقات
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'منشوراتي'),
                            Tab(text: 'تعليقاتي'),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // محتوى التبويبات
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // منشوراتي
                        _isLoadingPosts
                            ? const Center(child: CircularProgressIndicator())
                            : _userPosts.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد منشورات بعد',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'أنشئ منشورك الأول الآن!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CreatePostScreen(),
                                          ),
                                        );
                                        if (result == true) {
                                          _loadAllData();
                                        }
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text('إنشاء منشور'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _userPosts.length,
                                itemBuilder: (context, index) {
                                  return _buildPostCard(_userPosts[index]);
                                },
                              ),

                        // تعليقاتي
                        _isLoadingComments
                            ? const Center(child: CircularProgressIndicator())
                            : _userComments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد تعليقات بعد',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'كن أول من يعلق على المنشورات!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _userComments.length,
                                itemBuilder: (context, index) {
                                  return _buildCommentCard(
                                    _userComments[index],
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (result == true) {
            _loadAllData();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
