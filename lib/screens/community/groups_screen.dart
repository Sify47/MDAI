// lib/screens/community/groups_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/services/community_api.dart';
import 'package:vita/models/community_models.dart';
import 'package:vita/constants/colors.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CommunityGroup> _allGroups = [];
  List<CommunityGroup> _joinedGroups = [];
  List<CommunityGroup> _recommendedGroups = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final allGroups = await CommunityApi.getGroups();
      final joined = allGroups.where((g) => g.isJoined).toList();
      final recommended = allGroups.where((g) => !g.isJoined).take(10).toList();

      setState(() {
        _allGroups = allGroups;
        _joinedGroups = joined;
        _recommendedGroups = recommended;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading groups: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroup(CommunityGroup group) async {
    final success = await CommunityApi.joinGroup(group.id);
    if (success && mounted) {
      setState(() {
        final index = _allGroups.indexWhere((g) => g.id == group.id);
        if (index != -1) {
          _allGroups[index] = CommunityGroup(
            id: group.id,
            name: group.name,
            description: group.description,
            icon: group.icon,
            conditionTag: group.conditionTag,
            membersCount: group.membersCount + 1,
            postsCount: group.postsCount,
            isJoined: true,
            isPrivate: group.isPrivate,
            tags: group.tags,
          );
        }
        _joinedGroups = _allGroups.where((g) => g.isJoined).toList();
        _recommendedGroups = _allGroups
            .where((g) => !g.isJoined)
            .take(10)
            .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ انضممت إلى ${group.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _leaveGroup(CommunityGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مغادرة المجموعة'),
        content: Text('هل أنت متأكد من مغادرة مجموعة ${group.name}؟'),
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
      final success = await CommunityApi.leaveGroup(group.id);
      if (success && mounted) {
        setState(() {
          final index = _allGroups.indexWhere((g) => g.id == group.id);
          if (index != -1) {
            _allGroups[index] = CommunityGroup(
              id: group.id,
              name: group.name,
              description: group.description,
              icon: group.icon,
              conditionTag: group.conditionTag,
              membersCount: group.membersCount - 1,
              postsCount: group.postsCount,
              isJoined: false,
              isPrivate: group.isPrivate,
              tags: group.tags,
            );
          }
          _joinedGroups = _allGroups.where((g) => g.isJoined).toList();
          _recommendedGroups = _allGroups
              .where((g) => !g.isJoined)
              .take(10)
              .toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('👋 غادرت مجموعة ${group.name}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  List<CommunityGroup> get _filteredAllGroups {
    if (_searchQuery.isEmpty) return _allGroups;
    return _allGroups
        .where(
          (g) =>
              g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              g.description.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<CommunityGroup> get _filteredJoinedGroups {
    if (_searchQuery.isEmpty) return _joinedGroups;
    return _joinedGroups
        .where((g) => g.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Widget _buildGroupCard(CommunityGroup group, {bool showJoinButton = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        child: Row(
          children: [
            // أيقونة المجموعة
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  group.icon ?? group.conditionIcon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // معلومات المجموعة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        group.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (group.isPrivate)
                        Icon(Icons.lock, size: 14, color: Colors.grey[500]),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text(
                        '${_formatCount(group.membersCount)} عضو',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.description,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${_formatCount(group.postsCount)} منشور',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // زر الانضمام/المغادرة
            if (showJoinButton)
              ElevatedButton(
                onPressed: () {
                  if (group.isJoined) {
                    _leaveGroup(group);
                  } else {
                    _joinGroup(group);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: group.isJoined
                      ? Colors.red
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(group.isJoined ? 'مغادرة' : 'انضمام'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المجموعات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'المجموعات'),
            Tab(text: 'انضممت'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // شريط البحث
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مجموعة...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // جميع المجموعات
                      RefreshIndicator(
                        onRefresh: _loadGroups,
                        child: _filteredAllGroups.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.group_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا توجد مجموعات',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _filteredAllGroups.length,
                                itemBuilder: (context, index) {
                                  return _buildGroupCard(
                                    _filteredAllGroups[index],
                                  );
                                },
                              ),
                      ),

                      // المجموعات المنضم إليها
                      RefreshIndicator(
                        onRefresh: _loadGroups,
                        child: _filteredJoinedGroups.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.group_add,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لم تنضم إلى أي مجموعة بعد',
                                      style: TextStyle(color: Colors.grey[500]),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () =>
                                          _tabController.animateTo(0),
                                      child: const Text('استكشف المجموعات'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _filteredJoinedGroups.length,
                                itemBuilder: (context, index) {
                                  return _buildGroupCard(
                                    _filteredJoinedGroups[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
