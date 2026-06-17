// lib/screens/community/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/services/community_api.dart';
import 'package:vita/models/community_models.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'create_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  final int? scrollToCommentId;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.scrollToCommentId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late CommunityPost _post;
  List<CommunityComment> _comments = [];
  bool _isLoadingComments = true;
  bool _isLoadingMoreComments = false;
  bool _isSubmittingComment = false;
  final TextEditingController _commentController = TextEditingController();
  int? _currentUserId;
  int? _replyingToCommentId;
  String? _replyingToUserName;
  final ScrollController _scrollController = ScrollController();
  int? _highlightedCommentId;
  int _currentCommentsOffset = 0;
  final int _commentsLimit = 20;
  bool _hasMoreComments = true;

  // حالة الإعجاب
  bool _hasReacted = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _likesCount = _post.reactionsCount;
    _loadCurrentUser();
    _loadComments();
    _checkReactionStatus();

    // التمرير إلى التعليق المحدد
    if (widget.scrollToCommentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToComment(widget.scrollToCommentId!);
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final userData = PrefsHelper.getUserData();
    setState(() {
      _currentUserId = PrefsHelper.getUserId();
    });
  }

  Future<void> _checkReactionStatus() async {
    final hasReacted = await CommunityApi.getReactionStatus(_post.id);
    if (mounted) {
      setState(() {
        _hasReacted = hasReacted;
      });
    }
  }

  Future<void> _toggleReaction() async {
    final result = await CommunityApi.toggleReaction(_post.id);

    if (result['success'] && mounted) {
      setState(() {
        _hasReacted = result['hasReacted'];
        _likesCount = result['likesCount'];
        _post = CommunityPost(
          id: _post.id,
          author: _post.author,
          type: _post.type,
          title: _post.title,
          content: _post.content,
          tags: _post.tags,
          createdAt: _post.createdAt,
          updatedAt: _post.updatedAt,
          viewsCount: _post.viewsCount,
          commentsCount: _post.commentsCount,
          reactionsCount: _likesCount,
          reactions: _post.reactions,
          isPinned: _post.isPinned,
          isFeatured: _post.isFeatured,
          isAnonymous: _post.isAnonymous,
          conditionTag: _post.conditionTag,
          groupId: _post.groupId,
          groupName: _post.groupName,
          groupIcon: _post.groupIcon,
        );
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

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
      _currentCommentsOffset = 0;
      _hasMoreComments = true;
    });

    try {
      final comments = await CommunityApi.getPostComments(_post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _currentCommentsOffset = comments.length;
          _hasMoreComments = comments.length == _commentsLimit;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('Error loading comments: $e');
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMoreComments || !_hasMoreComments) return;
    setState(() => _isLoadingMoreComments = true);

    try {
      final moreComments = await CommunityApi.getPostComments(_post.id);
      // ملاحظة: الـ API لا يدعم pagination حالياً، نضيف التعليقات الجديدة فقط
      final newComments = moreComments
          .where((c) => !_comments.any((existing) => existing.id == c.id))
          .toList();

      if (mounted) {
        setState(() {
          _comments.addAll(newComments);
          _currentCommentsOffset = _comments.length;
          _hasMoreComments = false; // مؤقتاً حتى يتم دعم pagination
          _isLoadingMoreComments = false;
        });
      }
    } catch (e) {
      print('Error loading more comments: $e');
      setState(() => _isLoadingMoreComments = false);
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      final comment = await CommunityApi.addComment(
        postId: _post.id,
        content: content,
        parentCommentId: _replyingToCommentId,
      );

      if (comment != null && mounted) {
        setState(() {
          _comments.insert(0, comment);
          _post = CommunityPost(
            id: _post.id,
            author: _post.author,
            type: _post.type,
            title: _post.title,
            content: _post.content,
            tags: _post.tags,
            createdAt: _post.createdAt,
            updatedAt: _post.updatedAt,
            viewsCount: _post.viewsCount,
            commentsCount: _post.commentsCount + 1,
            reactionsCount: _post.reactionsCount,
            reactions: _post.reactions,
            isPinned: _post.isPinned,
            isFeatured: _post.isFeatured,
            isAnonymous: _post.isAnonymous,
            conditionTag: _post.conditionTag,
            groupId: _post.groupId,
            groupName: _post.groupName,
            groupIcon: _post.groupIcon,
          );
          _commentController.clear();
          _cancelReply();
        });

        // التمرير إلى التعليق الجديد
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      print('Error adding comment: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ فشل في إضافة التعليق')));
    } finally {
      setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _markCommentAsHelpful(CommunityComment comment) async {
    final success = await CommunityApi.markCommentAsHelpful(comment.id);
    if (success && mounted) {
      setState(() {
        // تحديث في القائمة الرئيسية
        final index = _comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          _comments[index] = CommunityComment(
            id: comment.id,
            author: comment.author,
            content: comment.content,
            createdAt: comment.createdAt,
            updatedAt: comment.updatedAt,
            likesCount: comment.likesCount + 1,
            isHelpful: true,
            isAuthorResponse: comment.isAuthorResponse,
            replies: comment.replies,
          );
        } else {
          // البحث في الردود
          for (int i = 0; i < _comments.length; i++) {
            final replyIndex = _comments[i].replies.indexWhere(
              (r) => r.id == comment.id,
            );
            if (replyIndex != -1) {
              final updatedReplies = List<CommunityComment>.from(
                _comments[i].replies,
              );
              updatedReplies[replyIndex] = CommunityComment(
                id: comment.id,
                author: comment.author,
                content: comment.content,
                createdAt: comment.createdAt,
                updatedAt: comment.updatedAt,
                likesCount: comment.likesCount + 1,
                isHelpful: true,
                isAuthorResponse: comment.isAuthorResponse,
                replies: comment.replies,
              );
              _comments[i] = CommunityComment(
                id: _comments[i].id,
                author: _comments[i].author,
                content: _comments[i].content,
                createdAt: _comments[i].createdAt,
                updatedAt: _comments[i].updatedAt,
                likesCount: _comments[i].likesCount,
                isHelpful: _comments[i].isHelpful,
                isAuthorResponse: _comments[i].isAuthorResponse,
                replies: updatedReplies,
              );
              break;
            }
          }
        }
      });
    }
  }

  void _startReply(int commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    FocusScope.of(context).requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  void _scrollToComment(int commentId) {
    int index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) {
      // البحث في الردود
      for (int i = 0; i < _comments.length; i++) {
        final replyIndex = _comments[i].replies.indexWhere(
          (r) => r.id == commentId,
        );
        if (replyIndex != -1) {
          index = i;
          break;
        }
      }
    }

    if (index != -1 && mounted) {
      final double itemHeight = 140.0;
      _scrollController.animateTo(
        index * itemHeight,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

      setState(() {
        _highlightedCommentId = commentId;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedCommentId = null;
          });
        }
      });
    }
  }

  bool get _isOwnPost {
    return _currentUserId != null &&
        _post.author.id == _currentUserId &&
        !_post.isAnonymous;
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

  String _getParentCommentUserName(int? parentCommentId) {
    if (parentCommentId == null) return '';
    for (var comment in _comments) {
      if (comment.id == parentCommentId) {
        return comment.author.name;
      }
      for (var reply in comment.replies) {
        if (reply.id == parentCommentId) {
          return reply.author.name;
        }
      }
    }
    return '';
  }

  Widget _buildPostContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final author = _post.author;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس المنشور
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getPostTypeColor(_post.type).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getPostTypeColor(
                    _post.type,
                  ).withOpacity(0.15),
                  child: Text(
                    _post.isAnonymous
                        ? '👤'
                        : (author.name.isNotEmpty
                              ? author.name[0].toUpperCase()
                              : '?'),
                    style: TextStyle(
                      fontSize: 18,
                      color: _getPostTypeColor(_post.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _post.isAnonymous ? 'مستخدم مجهول' : author.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (!_post.isAnonymous && author.isVerified)
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.blue[600],
                            ),
                          const SizedBox(width: 4),
                          Text(
                            '· ${_post.timeAgo}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPostTypeColor(_post.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _post.typeIcon,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _post.typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: _getPostTypeColor(_post.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isOwnPost)
                  PopupMenuButton(
                    icon: Icon(Icons.more_horiz, color: Colors.grey[500]),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editPost();
                      } else if (value == 'delete') {
                        _deletePost();
                      }
                    },
                    itemBuilder: (context) => [
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
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _post.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (_post.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _post.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // زر التفاعل
                    InkWell(
                      onTap: _toggleReaction,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _hasReacted
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _hasReacted
                                  ? Icons.arrow_upward
                                  : Icons.arrow_upward_outlined,
                              size: 18,
                              color: _hasReacted
                                  ? Colors.orange
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatCount(_likesCount),
                              style: TextStyle(
                                fontSize: 14,
                                color: _hasReacted
                                    ? Colors.orange
                                    : Colors.grey[500],
                                fontWeight: _hasReacted
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // زر التعليقات
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: Colors.blue[400],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatCount(_post.commentsCount),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // عدد المشاهدات
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 18,
                            color: Colors.green[400],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatCount(_post.viewsCount),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(CommunityComment comment, {int depth = 0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHighlighted = _highlightedCommentId == comment.id;
    final maxDepth = 3; // الحد الأقصى لعمق الردود

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(
        left: depth > 0 ? (depth * 20).toDouble() : 0,
        top: 8,
        right: 12,
        bottom: 0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isHighlighted
            ? (isDark
                  ? Colors.blue.withOpacity(0.15)
                  : Colors.blue.withOpacity(0.08))
            : Colors.transparent,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? Colors.grey[850] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      comment.author.name.isNotEmpty
                          ? comment.author.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
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
                            Text(
                              comment.author.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (comment.author.isVerified)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                            if (comment.isHelpful)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '👍 مفيد',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            Text(
                              '· ${comment.timeAgo}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (depth > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'رد على @${_getParentCommentUserName(comment.id)}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.purple[400],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // زر الإعجاب بالتعليق
                  InkWell(
                    onTap: () => _markCommentAsHelpful(comment),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: comment.isHelpful
                            ? Colors.green.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            comment.isHelpful
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            size: 14,
                            color: comment.isHelpful
                                ? Colors.green
                                : Colors.grey[500],
                          ),
                          if (comment.likesCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              _formatCount(comment.likesCount),
                              style: TextStyle(
                                fontSize: 11,
                                color: comment.isHelpful
                                    ? Colors.green
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                comment.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // أزرار التفاعل للتعليق
              Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        _startReply(comment.id, comment.author.name),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'رد',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!comment.isHelpful)
                    TextButton(
                      onPressed: () => _markCommentAsHelpful(comment),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '👍 مفيد',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
              // الردود المتداخلة
              if (comment.replies.isNotEmpty && depth < maxDepth)
                ...comment.replies.map(
                  (reply) => _buildCommentCard(reply, depth: depth + 1),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatePostScreen(postToEdit: _post)),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deletePost() async {
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
      final success = await CommunityApi.deletePost(_post.id);
      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ تم حذف المنشور')));
      }
    }
  }

  Widget _buildCommentInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_replyingToCommentId != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الرد على @$_replyingToUserName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _cancelReply,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _replyingToCommentId != null
                        ? 'اكتب ردك...'
                        : 'أضف تعليقاً...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSubmittingComment ? null : _addComment,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isSubmittingComment
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 18, color: Colors.white),
                ),
              ),
            ],
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
        title: const Text('تفاصيل المنشور'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadComments(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadComments,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildPostContent(),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'التعليقات (${_post.commentsCount})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingComments)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_comments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'لا توجد تعليقات بعد',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              Text(
                                'كن أول من يعلق!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentCard(_comments[index]);
                        },
                      ),
                    if (_isLoadingMoreComments)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }
}
