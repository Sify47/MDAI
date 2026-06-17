// lib/screens/community/group_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/services/community_api.dart';
import 'package:vita/models/community_models.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  final String? groupName;

  const GroupDetailScreen({super.key, required this.groupId, this.groupName});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? _group;
  List<CommunityPost> _posts = [];
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isLoadingPosts = true;
  bool _isJoined = false;
  int? _currentUserId;
  String _selectedSort = 'new';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
    _loadGroupData();
    _loadGroupPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final userData = PrefsHelper.getUserData();
    setState(() {
      _currentUserId = userData['id'];
    });
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    try {
      final group = await CommunityApi.getGroup(widget.groupId);
      setState(() {
        _group = group;
        _isJoined = group['is_joined'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading group: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGroupPosts() async {
    setState(() => _isLoadingPosts = true);
    try {
      final posts = await CommunityApi.getGroupPosts(widget.groupId);
      setState(() {
        _posts = posts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      print('Error loading group posts: $e');
      setState(() => _isLoadingPosts = false);
    }
  }

  Future<void> _loadGroupMembers() async {
    try {
      // مؤقتاً نستخدم بيانات وهمية
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _members = [
          {'id': 1, 'name': 'أحمد', 'avatar': 'A', 'role': 'admin'},
          {'id': 2, 'name': 'سارة', 'avatar': 'S', 'role': 'moderator'},
          {'id': 3, 'name': 'محمد', 'avatar': 'M', 'role': 'member'},
          {'id': 4, 'name': 'فاطمة', 'avatar': 'F', 'role': 'member'},
          {'id': 5, 'name': 'علي', 'avatar': 'A', 'role': 'member'},
        ];
      });
    } catch (e) {
      print('Error loading members: $e');
    }
  }

  Future<void> _joinGroup() async {
    final success = await CommunityApi.joinGroup(widget.groupId);
    if (success && mounted) {
      setState(() {
        _isJoined = true;
        if (_group != null) {
          _group!['members_count'] = (_group!['members_count'] ?? 0) + 1;
          _group!['is_joined'] = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ انضممت إلى ${_group?['name'] ?? 'المجموعة'}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مغادرة المجموعة'),
        content: Text(
          'هل أنت متأكد من مغادرة مجموعة ${_group?['name'] ?? ''}؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await CommunityApi.leaveGroup(widget.groupId);
      if (success && mounted) {
        setState(() {
          _isJoined = false;
          if (_group != null) {
            _group!['members_count'] = (_group!['members_count'] ?? 0) - 1;
            _group!['is_joined'] = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('👋 غادرت مجموعة ${_group?['name'] ?? ''}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  List<CommunityPost> get _sortedPosts {
    final List<CommunityPost> filtered = _posts;
    switch (_selectedSort) {
      case 'hot':
        return [...filtered]..sort(
          (a, b) => (b.reactionsCount + b.commentsCount).compareTo(
            a.reactionsCount + a.commentsCount,
          ),
        );
      case 'top':
        return [...filtered]
          ..sort((a, b) => b.reactionsCount.compareTo(a.reactionsCount));
      default:
        return [...filtered]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  Widget _buildPostCard(CommunityPost post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final author = post.author;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
        _loadGroupPosts();
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
                    radius: 16,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    child: Text(
                      author.name.isNotEmpty
                          ? author.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              author.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (author.isVerified)
                              Icon(
                                Icons.verified,
                                size: 14,
                                color: Colors.blue[600],
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
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
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
                              const SizedBox(width: 2),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                post.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.arrow_upward, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatCount(post.reactionsCount),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = member['role'] == 'admin';
    final isModerator = member['role'] == 'moderator';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              member['avatar'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (isAdmin)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'مدير',
                      style: TextStyle(fontSize: 9, color: Colors.amber),
                    ),
                  )
                else if (isModerator)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'مشرف',
                      style: TextStyle(fontSize: 9, color: Colors.blue),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_group?['name'] ?? 'المجموعة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم نسخ رابط المجموعة'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // رأس المجموعة
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _group?['icon'] ?? '👥',
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _group?['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _group?['description'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatCount(_group?['members_count'] ?? 0)} عضو',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.description,
                              size: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatCount(_group?['posts_count'] ?? 0)} منشور',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isJoined ? _leaveGroup : _joinGroup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              _isJoined
                                  ? 'مغادرة المجموعة'
                                  : 'انضمام إلى المجموعة',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // القواعد
                if (_group?['rules'] != null &&
                    (_group?['rules'] as List).isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gavel, size: 18, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text(
                                'قواعد المجموعة',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(_group?['rules'] as List).map(
                            (rule) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  Expanded(
                                    child: Text(
                                      rule,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // التبويبات
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: isDark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'المنشورات'),
                        Tab(text: 'الأعضاء'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),

                // محتوى التبويبات
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // المنشورات
                      _isLoadingPosts
                          ? const Center(child: CircularProgressIndicator())
                          : _posts.isEmpty
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
                                  if (_isJoined) const SizedBox(height: 8),
                                  if (_isJoined)
                                    Text(
                                      'كن أول من ينشر في هذه المجموعة!',
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
                              itemCount: _sortedPosts.length,
                              itemBuilder: (context, index) {
                                return _buildPostCard(_sortedPosts[index]);
                              },
                            ),

                      // الأعضاء
                      FutureBuilder(
                        future: _loadGroupMembers(),
                        builder: (context, snapshot) {
                          if (_members.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _members.length,
                            itemBuilder: (context, index) {
                              return _buildMemberCard(_members[index]);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _isJoined
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreatePostScreen(selectedGroupId: widget.groupId),
                  ),
                );
                if (result == true) {
                  _loadGroupPosts();
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// كلاس مساعد للـ SliverPersistentHeader
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
