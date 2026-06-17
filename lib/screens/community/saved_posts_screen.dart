// lib/screens/community/saved_posts_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/services/community_api.dart';
import 'package:vita/models/community_models.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'post_detail_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<CommunityPost> _savedPosts = [];
  bool _isLoading = true;
  Map<int, bool> _reactionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    setState(() => _isLoading = true);
    try {
      // جلب جميع المنشورات (المحفوظات ستأتي من API منفصل)
      final allPosts = await CommunityApi.getPosts(limit: 100);
      // مؤقتاً: نعتبر المنشورات التي تفاعل معها المستخدم كمحفوظات
      // في المستقبل: استخدم API مخصص للمحفوظات
      final saved = allPosts
          .where((p) => p.reactionsCount > 5)
          .take(20)
          .toList();

      final reactionMap = <int, bool>{};
      for (var post in saved) {
        final hasReacted = await CommunityApi.getReactionStatus(post.id);
        reactionMap[post.id] = hasReacted;
      }

      setState(() {
        _savedPosts = saved;
        _reactionStatus = reactionMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading saved posts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unsavePost(CommunityPost post) async {
    setState(() {
      _savedPosts.removeWhere((p) => p.id == post.id);
      _reactionStatus.remove(post.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📌 تمت إزالة المنشور من المحفوظات'),
        duration: Duration(seconds: 1),
      ),
    );
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

  Widget _buildSavedPostCard(CommunityPost post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final author = post.author;
    final hasReacted = _reactionStatus[post.id] ?? false;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
        _loadSavedPosts();
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _getPostTypeColor(
                      post.type,
                    ).withOpacity(0.15),
                    child: Text(
                      post.isAnonymous ? '👤' : (author.name[0].toUpperCase()),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getPostTypeColor(post.type),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.isAnonymous ? 'مستخدم مجهول' : author.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '· ${post.timeAgo}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.bookmark,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () => _unsavePost(post),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    hasReacted
                        ? Icons.arrow_upward
                        : Icons.arrow_upward_outlined,
                    size: 14,
                    color: hasReacted ? Colors.orange : Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(post.reactionsCount),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(post.commentsCount),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفوظات'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد منشورات محفوظة',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يمكنك حفظ المنشورات التي تعجبك لمشاهدتها لاحقاً',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSavedPosts,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: _savedPosts.length,
                itemBuilder: (context, index) {
                  return _buildSavedPostCard(_savedPosts[index]);
                },
              ),
            ),
    );
  }
}
