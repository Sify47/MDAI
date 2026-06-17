// lib/screens/activities/activity_detail_screen.dart

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/activity_model.dart';
import '../../services/activity_api.dart';
import 'edit_activity_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;
  final List<ActivityCategory> categories;

  const ActivityDetailScreen({
    Key? key,
    required this.activity,
    required this.categories,
  }) : super(key: key);

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Activity? _activity;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeActivity() async {
    if (_activity!.isCompleted) return;

    setState(() => _isLoading = true);

    final result = await ActivityService.completeActivity(_activity!.id);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _activity = Activity(
          id: _activity!.id,
          title: _activity!.title,
          description: _activity!.description,
          categoryId: _activity!.categoryId,
          category: _activity!.category,
          startTime: _activity!.startTime,
          endTime: _activity!.endTime,
          isCompleted: true,
          hasReminder: _activity!.hasReminder,
          reminderMinutes: _activity!.reminderMinutes,
          notes: _activity!.notes,
          // Exercise fields
          isExercise: _activity!.isExercise,
          exerciseName: _activity!.exerciseName,
          sets: _activity!.sets,
          reps: _activity!.reps,
          weightKg: _activity!.weightKg,
          restSeconds: _activity!.restSeconds,
          caloriesBurned: _activity!.caloriesBurned,
          // Plan fields
          planId: _activity!.planId,
          planName: _activity!.planName,
        );
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ تم إكمال النشاط'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['message']}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteActivity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmDialog(context),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    final result = await ActivityService.deleteActivity(_activity!.id);

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
      Navigator.pop(context, 'deleted');
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['message']}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDeleteConfirmDialog(BuildContext context) {
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
          'هل أنت متأكد من حذف "${_activity!.title}"؟\nلا يمكن استرجاع النشاط بعد الحذف.',
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

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditActivityScreen(
          activity: _activity!,
          categories: widget.categories,
        ),
      ),
    );

    if (result != null && mounted) {
      if (result == 'deleted') {
        Navigator.pop(context, 'deleted');
      } else if (result is Activity) {
        setState(() {
          _activity = result;
        });
      } else {
        // Refresh from API
        final updated = await ActivityService.getActivityById(_activity!.id);
        if (updated != null && mounted) {
          setState(() {
            _activity = updated;
          });
        }
      }
    }
  }

  String _getStatusText() {
    final now = DateTime.now();
    if (_activity!.isCompleted) return 'مكتمل';
    if (_activity!.startTime.isAfter(now)) return 'قادم';
    if (_activity!.endTime.isBefore(now)) return 'منتهي';
    return 'جاري';
  }

  Color _getStatusColor() {
    final now = DateTime.now();
    if (_activity!.isCompleted) return AppColors.success;
    if (_activity!.startTime.isAfter(now)) return theme.colorScheme.primary;
    if (_activity!.endTime.isBefore(now)) return AppColors.danger;
    return AppColors.warning;
  }

  IconData _getStatusIcon() {
    final now = DateTime.now();
    if (_activity!.isCompleted) return Icons.check_circle;
    if (_activity!.startTime.isAfter(now)) return Icons.schedule;
    if (_activity!.endTime.isBefore(now)) return Icons.event_busy;
    return Icons.play_circle_filled;
  }

  ThemeData get theme => Theme.of(context);

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : AppColors.background,
        appBar: AppBar(
          title: Text('📋 تفاصيل النشاط'),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: theme.colorScheme.primary),
              onPressed: _isLoading ? null : _navigateToEdit,
              tooltip: 'تعديل',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _isLoading ? null : _deleteActivity,
              tooltip: 'حذف',
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? _buildLoading()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusHeader(),
                        const SizedBox(height: 16),
                        _buildTitleCard(),
                        const SizedBox(height: 16),
                        _buildTimeCard(),
                        const SizedBox(height: 16),
                        if (_activity!.description.isNotEmpty)
                          _buildDescriptionCard(),
                        if (_activity!.description.isNotEmpty)
                          const SizedBox(height: 16),
                        _buildCategoryCard(),
                        const SizedBox(height: 16),
                        // Exercise card - show if activity is exercise
                        if (_activity!.isExercise)
                          _buildExerciseCard(),
                        if (_activity!.isExercise)
                          const SizedBox(height: 16),
                        // Plan card - show if linked to a plan
                        if (_activity!.planId != null)
                          _buildPlanCard(),
                        if (_activity!.planId != null)
                          const SizedBox(height: 16),
                        _buildReminderCard(),
                        const SizedBox(height: 16),
                        if (_activity!.notes != null && _activity!.notes!.isNotEmpty)
                          _buildNotesCard(),
                        if (_activity!.notes != null && _activity!.notes!.isNotEmpty)
                          const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusText = _getStatusText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_activity!.isCompleted)
            Icon(Icons.verified, color: AppColors.success, size: 28),
        ],
      ),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (_activity!.category?.color ?? theme.colorScheme.primary).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _activity!.category?.icon ?? Icons.category,
              color: _activity!.category?.color ?? theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activity!.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _activity!.category?.name ?? 'غير مصنف',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _activity!.category?.color ?? theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    final now = DateTime.now();
    final isOngoing = _activity!.startTime.isBefore(now) && _activity!.endTime.isAfter(now);
    final durationMinutes = _activity!.durationMinutes;

    String formatTime(DateTime dt) {
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    String formatDate(DateTime dt) {
      return '${dt.year}/${dt.month}/${dt.day}';
    }

    // Calculate progress if ongoing
    double progress = 0;
    if (isOngoing) {
      final totalDuration = _activity!.endTime.difference(_activity!.startTime).inMinutes;
      final elapsed = now.difference(_activity!.startTime).inMinutes;
      progress = totalDuration > 0 ? elapsed / totalDuration : 0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⏰ الوقت والمدة',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeItem(
                  icon: Icons.play_arrow,
                  color: AppColors.primary,
                  label: 'البداية',
                  date: formatDate(_activity!.startTime),
                  time: formatTime(_activity!.startTime),
                ),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Icon(Icons.arrow_forward, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ),
              Expanded(
                child: _buildTimeItem(
                  icon: Icons.stop,
                  color: AppColors.warning,
                  label: 'النهاية',
                  date: formatDate(_activity!.endTime),
                  time: formatTime(_activity!.endTime),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'المدة: ${durationMinutes >= 60 ? '${durationMinutes ~/ 60} ساعة ${durationMinutes % 60} دقيقة' : '$durationMinutes دقيقة'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isOngoing) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'النشاط جاري - ${progress.toStringAsFixed(0)}% مكتمل',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeItem({
    required IconData icon,
    required Color color,
    required String label,
    required String date,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'الوصف',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _activity!.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard() {
    final category = _activity!.category;
    final categoryColor = category?.color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(category?.icon ?? Icons.category, color: categoryColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التصنيف',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category?.name ?? 'غير مصنف',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category?.nameEn ?? 'Other',
              style: theme.textTheme.bodySmall?.copyWith(
                color: categoryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard() {
    final exerciseColor = AppColors.walking;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: exerciseColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.fitness_center, color: exerciseColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                '🏋️ تفاصيل التمرين',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Exercise name
          if (_activity!.exerciseName != null && _activity!.exerciseName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 18, color: exerciseColor),
                  const SizedBox(width: 8),
                  Text(
                    _activity!.exerciseName!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: exerciseColor,
                    ),
                  ),
                ],
              ),
            ),
          // Sets × Reps
          if (_activity!.sets != null && _activity!.reps != null)
            _buildExerciseDetailRow(
              icon: Icons.repeat,
              label: 'المجموعات × العدات',
              value: '${_activity!.sets} مجموعات × ${_activity!.reps} عدات',
              color: exerciseColor,
            ),
          // Total reps
          if (_activity!.sets != null && _activity!.reps != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildExerciseDetailRow(
                icon: Icons.format_list_numbered,
                label: 'إجمالي العدات',
                value: '${_activity!.totalReps} عدة',
                color: theme.colorScheme.primary,
              ),
            ),
          // Weight
          if (_activity!.weightKg != null && _activity!.weightKg! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildExerciseDetailRow(
                icon: Icons.monitor_weight,
                label: 'الوزن المستخدم',
                value: '${_activity!.weightKg} كجم',
                color: AppColors.warning,
              ),
            ),
          // Total volume
          if (_activity!.weightKg != null && _activity!.weightKg! > 0 &&
              _activity!.sets != null && _activity!.reps != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildExerciseDetailRow(
                icon: Icons.trending_up,
                label: 'الحجم الكلي',
                value: '${_activity!.totalVolume} كجم',
                color: AppColors.success,
              ),
            ),
          // Rest seconds
          if (_activity!.restSeconds != null && _activity!.restSeconds! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildExerciseDetailRow(
                icon: Icons.timer_outlined,
                label: 'الراحة بين المجموعات',
                value: '${_activity!.restSeconds} ثانية',
                color: theme.colorScheme.primary,
              ),
            ),
          // Calories burned
          if (_activity!.caloriesBurned != null && _activity!.caloriesBurned! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '🔥 السعرات المحروقة: ${_activity!.caloriesBurned} سعرة حرارية',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard() {
    final planColor = AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: planColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.assignment, color: planColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📋 جزء من خطة',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _activity!.planName ?? 'خطة',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: planColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: planColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.check_circle, color: planColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    final reminderColor = _activity!.hasReminder ? AppColors.warning : theme.colorScheme.onSurface.withOpacity(0.4);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: reminderColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _activity!.hasReminder ? Icons.notifications_active : Icons.notifications_off,
              color: reminderColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التذكير',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _activity!.hasReminder
                      ? 'مفعّل - قبل ${_activity!.reminderMinutes} دقيقة'
                      : 'غير مفعّل',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: reminderColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'ملاحظات',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _activity!.notes!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final now = DateTime.now();
    final canComplete = !_activity!.isCompleted && _activity!.startTime.isBefore(now);

    return Column(
      children: [
        if (canComplete)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _completeActivity,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('إكمال النشاط'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        if (canComplete) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _navigateToEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('تعديل النشاط'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _deleteActivity,
            icon: const Icon(Icons.delete_outline),
            label: const Text('حذف النشاط'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}