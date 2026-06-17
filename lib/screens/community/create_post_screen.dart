// lib/screens/community/create_post_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/services/community_api.dart';
import 'package:vita/models/community_models.dart';
import 'package:vita/constants/colors.dart';

class CreatePostScreen extends StatefulWidget {
  final CommunityPost? postToEdit;
  final int? selectedGroupId;

  const CreatePostScreen({super.key, this.postToEdit, this.selectedGroupId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();

  String _selectedType = 'tip';
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  String? _category;

  // متغيرات المجموعة
  List<Map<String, dynamic>> _joinedGroups = [];
  Map<String, dynamic>? _selectedGroup;
  Map<String, dynamic>? _originalGroup; // حفظ المجموعة الأصلية للتعديل
  bool _isLoadingGroups = true;

  final List<Map<String, dynamic>> _postTypes = [
    {'type': 'tip', 'label': 'نصيحة', 'icon': '💡', 'color': Colors.green},
    {
      'type': 'experience',
      'label': 'تجربة',
      'icon': '📝',
      'color': Colors.purple,
    },
    {'type': 'question', 'label': 'سؤال', 'icon': '❓', 'color': Colors.blue},
    {'type': 'support', 'label': 'دعم', 'icon': '🤝', 'color': Colors.orange},
    {
      'type': 'achievement',
      'label': 'إنجاز',
      'icon': '🏆',
      'color': Colors.amber,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadJoinedGroups();

    // إذا كان في وضع التعديل، قم بملء البيانات
    if (widget.postToEdit != null) {
      _titleController.text = widget.postToEdit!.title;
      _contentController.text = widget.postToEdit!.content;
      _selectedType = widget.postToEdit!.type.name;
      _tags.addAll(widget.postToEdit!.tags);
      _isAnonymous = widget.postToEdit!.isAnonymous;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadJoinedGroups() async {
    setState(() => _isLoadingGroups = true);
    try {
      final groups = await CommunityApi.getGroups(joinedOnly: true);
      final List<Map<String, dynamic>> groupList = [];

      for (var group in groups) {
        groupList.add({
          'id': group.id,
          'name': group.name,
          'icon': group.icon,
          'conditionTag': group.conditionTag,
        });
      }

      setState(() {
        _joinedGroups = groupList;
        _isLoadingGroups = false;

        // في وضع التعديل: البحث عن المجموعة الأصلية للمنشور
        if (widget.postToEdit != null && widget.postToEdit!.groupId != null) {
          final originalGroup = _joinedGroups.firstWhere(
            (g) => g['id'] == widget.postToEdit!.groupId,
            orElse: () => _joinedGroups.first,
          );
          _selectedGroup = originalGroup;
          _originalGroup = originalGroup;
        }
        // في وضع الإنشاء الجديد: اختيار أول مجموعة أو المجموعة المحددة
        else if (_joinedGroups.isNotEmpty && widget.selectedGroupId != null) {
          _selectedGroup = _joinedGroups.firstWhere(
            (g) => g['id'] == widget.selectedGroupId,
            orElse: () => _joinedGroups.first,
          );
        } else if (_joinedGroups.isNotEmpty && _selectedGroup == null) {
          _selectedGroup = _joinedGroups.first;
        }
      });
    } catch (e) {
      print('❌ خطأ في جلب المجموعات: $e');
      setState(() => _isLoadingGroups = false);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submitPost() async {
    if (_selectedGroup == null) {
      _showError('الرجاء اختيار المجموعة');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showError('الرجاء إدخال عنوان المنشور');
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      _showError('الرجاء إدخال محتوى المنشور');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final postData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'post_type': _selectedType,
        'category': _selectedGroup!['conditionTag'] ?? 'general',
        'is_anonymous': _isAnonymous,
        'tags': _tags,
        'group_id': _selectedGroup!['id'],
      };

      print('📤 إرسال البيانات: $postData');

      CommunityPost? post;

      if (widget.postToEdit != null) {
        // وضع التعديل - استخدام updatePost مع البيانات الكاملة
        final success = await CommunityApi.updatePost(
          widget.postToEdit!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tags: _tags,
          postType: _selectedType,
          category: _selectedGroup!['conditionTag'] ?? 'general',
          isAnonymous: _isAnonymous,
          groupId: _selectedGroup!['id'],
        );
        if (success) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم تعديل المنشور بنجاح'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          _showError('فشل في تعديل المنشور');
        }
      } else {
        // وضع الإنشاء الجديد
        post = await CommunityApi.createPost(postData);
        if (post != null) {
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ تم نشر منشورك بنجاح في ${_selectedGroup!['name']}',
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          _showError('فشل في نشر المنشور، حاول مرة أخرى');
        }
      }
    } catch (e) {
      print('❌ خطأ: $e');
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.postToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل المنشور' : 'منشور جديد',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSubmitting ? null : _submitPost,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditing ? 'تحديث' : 'نشر',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اختيار المجموعة - مع إمكانية التعديل
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.group,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'المجموعة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoadingGroups)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_joinedGroups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.group_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'لم تنضم إلى أي مجموعة بعد',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'انضم إلى مجموعة أولاً لتتمكن من النشر',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.explore),
                            label: const Text('استكشاف المجموعات'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        ..._joinedGroups.map((group) {
                          final isSelected =
                              _selectedGroup?['id'] == group['id'];
                          return RadioListTile<Map<String, dynamic>>(
                            value: group,
                            groupValue: _selectedGroup,
                            onChanged: (value) {
                              setState(() {
                                _selectedGroup = value;
                              });
                            },
                            title: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      group['icon'] ?? '👥',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        'انشر في هذه المجموعة',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // اختيار نوع المنشور
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'نوع المنشور',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _postTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final typeData = _postTypes[index];
                        final isSelected = _selectedType == typeData['type'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = typeData['type'];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (typeData['color'] as Color).withOpacity(
                                      0.15,
                                    )
                                  : (isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? typeData['color']
                                    : (isDark
                                          ? Colors.grey[700]!
                                          : Colors.grey[300]!),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  typeData['icon'],
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  typeData['label'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? typeData['color']
                                        : (isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // عنوان المنشور
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.calories.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.title,
                            size: 18,
                            color: AppColors.calories,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'العنوان',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'اكتب عنواناً واضحاً...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // محتوى المنشور
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description,
                            size: 18,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'المحتوى',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contentController,
                      maxLines: 8,
                      minLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب محتوى منشورك هنا...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // الوسوم
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.tag,
                                size: 18,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'الوسوم',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_tags.length}/5',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            enabled: _tags.length < 5,
                            decoration: InputDecoration(
                              hintText: 'أضف وسماً...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _tags.length < 5 ? _addTag : null,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _tags.length < 5
                                  ? AppColors.primary
                                  : Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '#$tag',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _removeTag(tag),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // خيار النشر بشكل مجهول
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.visibility_off,
                        size: 22,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'نشر بشكل مجهول',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'لن يظهر اسمك للآخرين',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAnonymous,
                      onChanged: (value) =>
                          setState(() => _isAnonymous = value),
                      activeColor: AppColors.primary,
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
}
