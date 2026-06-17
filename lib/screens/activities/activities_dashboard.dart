// lib/screens/activities/activities_dashboard.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/colors.dart';
import '../../models/activity_model.dart';
import '../../services/activity_api.dart';
import 'add_activity_screen.dart';
import 'activity_statistics.dart';
import 'activity_detail_screen.dart';

class ActivitiesDashboard extends StatefulWidget {
  const ActivitiesDashboard({Key? key}) : super(key: key);

  @override
  State<ActivitiesDashboard> createState() => _ActivitiesDashboardState();
}

class _ActivitiesDashboardState extends State<ActivitiesDashboard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  List<Activity> _activities = [];
  List<ActivityCategory> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search & Filter state
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ActivityCategory? _filterCategory;
  ActivityStatusFilter _statusFilter = ActivityStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
    _selectedDay = _focusedDay;
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ActivityService.getCategories(),
        ActivityService.getActivities(),
      ]);

      if (!mounted) return;

      setState(() {
        _categories = List<ActivityCategory>.from(results[0]);
        _activities = List<Activity>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'فشل في تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  List<Activity> _getActivitiesForDay(DateTime day) {
    var dayActivities = _activities.where((activity) {
      return activity.startTime.year == day.year &&
          activity.startTime.month == day.month &&
          activity.startTime.day == day.day;
    }).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      dayActivities = dayActivities.where((activity) {
        return activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            activity.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply category filter
    if (_filterCategory != null) {
      dayActivities = dayActivities.where((activity) {
        return activity.categoryId == _filterCategory!.id;
      }).toList();
    }

    // Apply status filter
    final now = DateTime.now();
    switch (_statusFilter) {
      case ActivityStatusFilter.completed:
        dayActivities = dayActivities.where((a) => a.isCompleted).toList();
        break;
      case ActivityStatusFilter.ongoing:
        dayActivities = dayActivities.where((a) =>
            a.startTime.isBefore(now) && a.endTime.isAfter(now) && !a.isCompleted).toList();
        break;
      case ActivityStatusFilter.upcoming:
        dayActivities = dayActivities.where((a) => a.startTime.isAfter(now) && !a.isCompleted).toList();
        break;
      case ActivityStatusFilter.all:
        break;
    }

    return dayActivities;
  }

  Future<void> _navigateToDetail(Activity activity) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(
          activity: activity,
          categories: _categories,
        ),
      ),
    );

    if (result != null && mounted) {
      _refreshData();
    }
  }

  Future<void> _deleteActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmDialog(context, activity),
    );

    if (confirmed != true || !mounted) return;

    final result = await ActivityService.deleteActivity(activity.id);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🗑️ تم حذف النشاط'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      _refreshData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['message']}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDeleteConfirmDialog(BuildContext context, Activity activity) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'حذف النشاط',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${activity.title}"؟\nلا يمكن استرجاع النشاط بعد الحذف.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          title: Text('📋 أنشطتي'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              onPressed: _refreshData,
            ),
            IconButton(
              icon: Icon(Icons.bar_chart, color: theme.colorScheme.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityStatistics(),
                  ),
                ).then((_) => _refreshData());
              },
            ),
            IconButton(
              icon: Icon(Icons.add, color: theme.colorScheme.primary),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddActivityScreen(categories: _categories),
                  ),
                );
                if (result != null && mounted) {
                  _refreshData();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? _buildLoading(theme)
              : _errorMessage != null
              ? _buildError(theme)
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: theme.colorScheme.primary,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildCalendar(theme),
                        _buildSearchAndFilter(theme),
                        Expanded(child: _buildActivitiesList(theme)),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الأنشطة...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.walking,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: theme.textTheme.bodyMedium!,
          weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          outsideTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: true,
          titleTextStyle: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: theme.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.bold,
          ),
          weekendStyle: theme.textTheme.bodySmall!.copyWith(
            color: AppColors.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
        eventLoader: (day) {
          // Show markers for days that have activities (unfiltered)
          return _activities.where((activity) {
            return activity.startTime.year == day.year &&
                activity.startTime.month == day.month &&
                activity.startTime.day == day.day;
          }).toList();
        },
      ),
    );
  }

  Widget _buildSearchAndFilter(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.06),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '🔍 بحث في الأنشطة...',
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            style: theme.textTheme.bodyMedium,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const Divider(height: 1),
          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Status filters
                _buildStatusFilterChip('الكل', ActivityStatusFilter.all, theme),
                _buildStatusFilterChip('جاري', ActivityStatusFilter.ongoing, theme),
                _buildStatusFilterChip('قادم', ActivityStatusFilter.upcoming, theme),
                _buildStatusFilterChip('مكتمل', ActivityStatusFilter.completed, theme),
                const SizedBox(width: 8),
                // Vertical divider
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                // Category filters
                ..._categories.map((category) {
                  return _buildCategoryFilterChip(category, theme);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, ActivityStatusFilter status, ThemeData theme) {
    final isSelected = _statusFilter == status;
    Color chipColor;
    switch (status) {
      case ActivityStatusFilter.all:
        chipColor = theme.colorScheme.primary;
        break;
      case ActivityStatusFilter.ongoing:
        chipColor = AppColors.success;
        break;
      case ActivityStatusFilter.upcoming:
        chipColor = theme.colorScheme.primary;
        break;
      case ActivityStatusFilter.completed:
        chipColor = AppColors.warning;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _statusFilter = status;
          });
        },
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        selectedColor: chipColor.withOpacity(0.2),
        checkmarkColor: chipColor,
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: isSelected ? chipColor : theme.colorScheme.onSurface.withOpacity(0.6),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildCategoryFilterChip(ActivityCategory category, ThemeData theme) {
    final isSelected = _filterCategory?.id == category.id;
    final categoryColor = category.color;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilterChip(
        label: Text(category.name),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterCategory = selected ? category : null;
          });
        },
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        selectedColor: categoryColor.withOpacity(0.2),
        checkmarkColor: categoryColor,
        avatar: Icon(category.icon, size: 14, color: isSelected ? categoryColor : theme.colorScheme.onSurface.withOpacity(0.5)),
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: isSelected ? categoryColor : theme.colorScheme.onSurface.withOpacity(0.6),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildActivitiesList(ThemeData theme) {
    final dayActivities = _getActivitiesForDay(_selectedDay ?? _focusedDay);

    if (dayActivities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                size: 80,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty || _filterCategory != null || _statusFilter != ActivityStatusFilter.all
                    ? 'لا توجد أنشطة مطابقة للفلتر'
                    : 'لا توجد أنشطة في هذا اليوم',
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty || _filterCategory != null || _statusFilter != ActivityStatusFilter.all)
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filterCategory = null;
                      _statusFilter = ActivityStatusFilter.all;
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('إزالة الفلاتر'),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddActivityScreen(categories: _categories),
                    ),
                  );
                  if (result != null && mounted) {
                    _refreshData();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة نشاط'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayActivities.length,
      itemBuilder: (context, index) {
        final activity = dayActivities[index];
        return _buildActivityCard(activity, theme);
      },
    );
  }

  Widget _buildActivityCard(Activity activity, ThemeData theme) {
    final isPast = activity.endTime.isBefore(DateTime.now());
    final isOngoing =
        activity.startTime.isBefore(DateTime.now()) &&
        activity.endTime.isAfter(DateTime.now());

    Color statusColor = isPast
        ? theme.colorScheme.onSurface.withOpacity(0.5)
        : isOngoing
        ? AppColors.success
        : theme.colorScheme.primary;

    final category = activity.category;
    final icon = category?.icon ?? Icons.category;
    final color = category?.color ?? theme.colorScheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return FadeTransition(
          opacity: AlwaysStoppedAnimation(opacity),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacity)),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: isOngoing
                      ? Border.all(color: AppColors.success, width: 2)
                      : null,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _navigateToDetail(activity),
                  onLongPress: () => _showActivityContextMenu(activity, theme),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      activity.title,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (activity.hasReminder)
                                    Icon(
                                      Icons.notifications,
                                      size: 16,
                                      color: AppColors.warning,
                                    ),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      activity.isCompleted ? 'مكتمل' : isOngoing ? 'جاري' : isPast ? 'منتهي' : 'قادم',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (activity.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    activity.description,
                                    style: theme.textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              // Exercise info row
                              if (activity.isExercise && activity.exerciseName != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.fitness_center, size: 14, color: AppColors.walking),
                                      const SizedBox(width: 4),
                                      Text(
                                        activity.exerciseName!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.walking,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (activity.sets != null && activity.reps != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '${activity.sets}×${activity.reps}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.walking,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                      // Calories badge
                                      if (activity.caloriesBurned != null && activity.caloriesBurned! > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '🔥 ${activity.caloriesBurned}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              // Plan badge
                              if (activity.planId != null && activity.planName != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.assignment, size: 12, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        activity.planName!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${activity.startTime.hour}:${activity.startTime.minute.toString().padLeft(2, '0')} - '
                                    '${activity.endTime.hour}:${activity.endTime.minute.toString().padLeft(2, '0')}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (activity.durationMinutes > 0) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      'المدة: ${activity.durationMinutes} دقيقة',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: activity.isCompleted,
                          onChanged: (value) async {
                            if (value == true && mounted) {
                              final result = await ActivityService.completeActivity(
                                activity.id,
                              );
                              if (result['success'] == true && mounted) {
                                _refreshData();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('✅ تم إكمال النشاط'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          activeColor: AppColors.success,
                          checkColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showActivityContextMenu(Activity activity, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (activity.category?.color ?? theme.colorScheme.primary).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          activity.category?.icon ?? Icons.category,
                          color: activity.category?.color ?? theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          activity.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (!activity.isCompleted)
                  ListTile(
                    leading: Icon(Icons.check_circle_outline, color: AppColors.success),
                    title: Text('إكمال النشاط', style: theme.textTheme.bodyMedium),
                    onTap: () {
                      Navigator.pop(context);
                      _completeActivityFromContext(activity);
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.visibility, color: theme.colorScheme.primary),
                  title: Text('عرض التفاصيل', style: theme.textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDetail(activity);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                  title: Text('تعديل النشاط', style: theme.textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToEditFromContext(activity);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.danger),
                  title: Text('حذف النشاط', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteActivity(activity);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _completeActivityFromContext(Activity activity) async {
    final result = await ActivityService.completeActivity(activity.id);
    if (result['success'] == true && mounted) {
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ تم إكمال النشاط'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _navigateToEditFromContext(Activity activity) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityDetailScreen(
          activity: activity,
          categories: _categories,
        ),
      ),
    );
    if (result != null && mounted) {
      _refreshData();
    }
  }
}

enum ActivityStatusFilter { all, ongoing, upcoming, completed }
