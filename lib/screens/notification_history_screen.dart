// lib/screens/notifications/notification_history_screen.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../services/notification_api.dart';
import '../../constants/colors.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _notifications = [];
  String _selectedFilter = 'الكل';

  // ✅ قائمة الأنواع المدعومة (بما فيها summary)
  final List<Map<String, String>> _filters = [
    {'value': 'الكل', 'icon': '📋', 'label': 'الكل'},
    {'value': 'medication', 'icon': '💊', 'label': 'أدوية'},
    {'value': 'water', 'icon': '💧', 'label': 'ماء'},
    {'value': 'activity', 'icon': '🏃', 'label': 'أنشطة'},
    {'value': 'summary', 'icon': '📊', 'label': 'ملخص يومي'}, // ✅ إضافة summary
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // جلب الإحصائيات وقائمة الإشعارات معًا
      final results = await Future.wait([
        NotificationApi.getNotificationStats(daysBack: 30),
        NotificationApi.getNotificationsList(limit: 50, offset: 0),
      ]);

      final stats = results[0] as Map<String, dynamic>?;
      final notificationsData = results[1] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _stats = stats ?? {};
          // استخدام قائمة الإشعارات من endpoint /list بدلاً من /stats
          _notifications = List<Map<String, dynamic>>.from(
            notificationsData?['notifications'] ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل الإشعارات: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحميل البيانات';
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'الكل') {
      return _notifications;
    }
    return _notifications
        .where((n) => n['notification_type'] == _selectedFilter)
        .toList();
  }

  String _getTypeIcon(String type) {
    switch (type) {
      case 'medication':
        return '💊';
      case 'water':
        return '💧';
      case 'activity':
        return '🏃';
      case 'summary':
        return '📊';
      case 'general':
        return '📢';
      default:
        return '📢';
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'medication':
        return 'أدوية';
      case 'water':
        return 'ماء';
      case 'activity':
        return 'أنشطة';
      case 'summary':
        return 'ملخص يومي';
      case 'general':
        return 'عام';
      default:
        return 'عام';
    }
  }

  Color _getTypeColor(String type, ThemeData theme) {
    switch (type) {
      case 'medication':
        return AppColors.medications;
      case 'water':
        return Colors.blue;
      case 'activity':
        return AppColors.walking;
      case 'summary':
        return Colors.purple;
      case 'general':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getActionIcon(String? action) {
    switch (action) {
      case 'taken':
        return '✅';
      case 'completed':
        return '✅';
      case 'snoozed':
        return '⏰';
      case 'dismissed':
        return '❌';
      case 'ignored':
        return '👻';
      default:
        return '⏳';
    }
  }

  String _getActionText(String? action) {
    switch (action) {
      case 'taken':
        return 'تم التفاعل';
      case 'completed':
        return 'تم الإكمال';
      case 'snoozed':
        return 'تم التأجيل';
      case 'dismissed':
        return 'تم التجاهل';
      case 'ignored':
        return 'لم يتم الرد';
      default:
        return 'في الانتظار';
    }
  }

  Color _getActionColor(String? action, ThemeData theme) {
    switch (action) {
      case 'taken':
      case 'completed':
        return AppColors.success;
      case 'snoozed':
        return AppColors.warning;
      case 'dismissed':
      case 'ignored':
        return AppColors.danger;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final responseRate = _getResponseRateAsDouble();
    final totalNotifications = _getTotalNotificationsAsInt();
    final respondedCount = _getRespondedCountAsInt();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('📋 سجل الإشعارات'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoading(theme)
            : _errorMessage != null
            ? _buildError(theme)
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildStatsCard(
                      theme,
                      totalNotifications,
                      respondedCount,
                      responseRate,
                    ),
                    const SizedBox(height: 16),
                    _buildFilterBar(theme),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _filteredNotifications.isEmpty
                          ? _buildEmptyState(theme)
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredNotifications.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationCard(
                                  _filteredNotifications[index],
                                  theme,
                                  index,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  double _getResponseRateAsDouble() {
    final rate = _stats['response_rate'];
    if (rate == null) return 0.0;
    if (rate is double) return rate;
    if (rate is int) return rate.toDouble();
    if (rate is String) return double.tryParse(rate) ?? 0.0;
    return 0.0;
  }

  int _getTotalNotificationsAsInt() {
    final total = _stats['total_notifications'];
    if (total == null) return 0;
    if (total is int) return total;
    if (total is double) return total.toInt();
    if (total is String) return int.tryParse(total) ?? 0;
    return 0;
  }

  int _getRespondedCountAsInt() {
    final responded = _stats['responded_count'];
    if (responded == null) return 0;
    if (responded is int) return responded;
    if (responded is double) return responded.toInt();
    if (responded is String) return int.tryParse(responded) ?? 0;
    return 0;
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الإشعارات...',
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

  Widget _buildStatsCard(
    ThemeData theme,
    int total,
    int responded,
    double rate,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, AppColors.success],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '📊 إحصائيات الإشعارات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('إجمالي', '$total', 'إشعار', theme),
              _buildStatItem('تم الرد', '$responded', 'إشعار', theme),
              _buildStatItem('نسبة الاستجابة', '${rate.toInt()}', '%', theme),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 100.0) / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
      ],
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['value'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter['value']!;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(30),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(filter['icon']!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    filter['label']!,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد إشعارات',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم يتم تسجيل أي إشعارات حتى الآن',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('تحديث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    ThemeData theme,
    int index,
  ) {
    final type = notification['notification_type'] ?? 'general';
    final typeName = _getTypeName(type);
    final typeIcon = _getTypeIcon(type);
    final typeColor = _getTypeColor(type, theme);
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final action = notification['action_taken'];
    final scheduledTime = notification['scheduled_time'] != null
        ? DateTime.tryParse(notification['scheduled_time'])
        : null;
    final isRead = notification['is_read'] ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return FadeTransition(
          opacity: AlwaysStoppedAnimation(opacity),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacity)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.06),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _showNotificationDetails(notification, theme);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // أيقونة النوع
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [typeColor, typeColor.withOpacity(0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              typeIcon,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // المحتوى
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    scheduledTime != null
                                        ? _formatDateTime(scheduledTime)
                                        : 'غير محدد',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getActionColor(
                                        action,
                                        theme,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _getActionIcon(action),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getActionText(action),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontSize: 10,
                                                color: _getActionColor(
                                                  action,
                                                  theme,
                                                ),
                                                fontWeight: FontWeight.w500,
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
                        // السهم
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.arrow_forward_ios, size: 14),
                          ),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (notificationDate == today) {
      return 'اليوم ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      return 'أمس ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
    }
  }

  void _showNotificationDetails(
    Map<String, dynamic> notification,
    ThemeData theme,
  ) {
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final type = notification['notification_type'] ?? 'general';
    final action = notification['action_taken'];
    final extraData = notification['extra_data'] as Map? ?? {};
    final scheduledTime = notification['scheduled_time'] != null
        ? DateTime.tryParse(notification['scheduled_time'])
        : null;
    final actionTime = notification['action_time'] != null
        ? DateTime.tryParse(notification['action_time'])
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getTypeColor(type, theme),
                                    _getTypeColor(type, theme).withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _getTypeIcon(type),
                                  style: const TextStyle(fontSize: 30),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(
                                        type,
                                        theme,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getTypeName(type),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: _getTypeColor(type, theme),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(body, style: theme.textTheme.bodyMedium),
                        ),
                        const SizedBox(height: 16),
                        // Details
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailItem(
                                '⏰ وقت الإرسال',
                                scheduledTime != null
                                    ? _formatDateTime(scheduledTime)
                                    : 'غير محدد',
                                theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailItem(
                                '📝 الحالة',
                                _getActionText(action),
                                theme,
                                color: _getActionColor(action, theme),
                              ),
                            ),
                          ],
                        ),
                        if (actionTime != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailItem(
                            '⏱️ وقت التفاعل',
                            _formatDateTime(actionTime),
                            theme,
                          ),
                        ],
                        if (extraData.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 12),
                          Text(
                            '📦 معلومات إضافية',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...extraData.entries.map((entry) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        entry.key == 'water_amount'
                                            ? '💧'
                                            : entry.key == 'steps'
                                            ? '👣'
                                            : '📌',
                                        style: const TextStyle(fontSize: 14),
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
                                          _getExtraDataLabel(entry.key),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        Text(
                                          entry.value.toString(),
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  // Close Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('إغلاق'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getExtraDataLabel(String key) {
    switch (key) {
      case 'water_amount':
        return 'كمية الماء';
      case 'steps':
        return 'عدد الخطوات';
      case 'calories':
        return 'السعرات';
      case 'medication_name':
        return 'اسم الدواء';
      case 'activity_name':
        return 'اسم النشاط';
      default:
        return key;
    }
  }

  Widget _buildDetailItem(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
