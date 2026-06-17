// lib/screens/activities/edit_activity_screen.dart
/// شاشة تعديل النشاط - تعاد هيكلتها باستخدام ActivityFormMixin لتقليل التكرار.

import 'package:flutter/material.dart';
import 'package:vita/services/notification_service.dart';
import '../../constants/colors.dart';
import '../../models/activity_model.dart';
import '../../mixins/activity_form_mixin.dart';
import '../../models/activity_plan_model.dart';
import '../../services/activity_api.dart';

class EditActivityScreen extends StatefulWidget {
  final Activity activity;
  final List<ActivityCategory> categories;

  const EditActivityScreen({
    Key? key,
    required this.activity,
    required this.categories,
  }) : super(key: key);

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen>
    with
        TickerProviderStateMixin<EditActivityScreen>,
        ActivityFormMixin<EditActivityScreen> {
  @override
  List<ActivityCategory> get categories => widget.categories;

  @override
  void initState() {
    super.initState();
    initActivityForm(this);

    // ✅ تعبئة الحقول بقيم النشاط الحالي
    titleController.text = widget.activity.title;
    descriptionController.text = widget.activity.description;
    notesController.text = widget.activity.notes ?? '';

    selectedCategory = widget.categories.isNotEmpty
        ? widget.categories.firstWhere(
            (cat) => cat.id == widget.activity.categoryId,
            orElse: () => widget.categories.first,
          )
        : null;

    startDate = widget.activity.startTime;
    startTime = TimeOfDay(
      hour: widget.activity.startTime.hour,
      minute: widget.activity.startTime.minute,
    );
    endDate = widget.activity.endTime;
    endTime = TimeOfDay(
      hour: widget.activity.endTime.hour,
      minute: widget.activity.endTime.minute,
    );

    hasReminder = widget.activity.hasReminder;
    reminderMinutes = widget.activity.reminderMinutes;
  }

  @override
  void onFormReady() {
    // ✅ تحديد الخطة إن وجدت - هنا لأن plans تُحمّل بشكل غير متزامن بعد أول build
    if (widget.activity.planId != null) {
      selectedPlan = plans.cast<ActivityPlan?>().firstWhere(
        (plan) => plan?.id == widget.activity.planId,
        orElse: () => null,
      );
    }
  }

  @override
  Future<void> onSave() async {
    if (!validateForm()) return;

    final startDateTime = combineDateAndTime(startDate, startTime);
    final endDateTime = combineDateAndTime(endDate, endTime);

    if (endDateTime.isBefore(startDateTime)) {
      showSnackBar(
        '❌ وقت النهاية يجب أن يكون بعد وقت البداية',
        AppColors.danger,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final activityData = buildActivityData();
      final result = await ActivityService.updateActivity(
        widget.activity.id,
        activityData,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // إلغاء الإشعار القديم وجدولة الجديد
        await NotificationService.cancelActivityNotifications(
          widget.activity.id,
        );
        if (hasReminder) {
          await NotificationService.scheduleActivityNotification(
            activityId: widget.activity.id,
            title: titleController.text,
            description: descriptionController.text,
            startTime: startDateTime,
            reminderMinutes: reminderMinutes,
          );
        }

        setState(() => isSaving = false);
        showSnackBar('✅ ${result['message']}', AppColors.success);

        if (mounted) {
          final updatedActivity = result['data'] as Activity;
          Navigator.pop(context, updatedActivity);
        }
      } else {
        setState(() => isSaving = false);
        showSnackBar('❌ ${result['message']}', AppColors.danger);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        showSnackBar('❌ حدث خطأ أثناء تعديل النشاط: $e', AppColors.danger);
      }
    }
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
          title: Text('✏️ تعديل النشاط'),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    buildCategorySelector(theme),
                    const SizedBox(height: 16),

                    if (plans.isNotEmpty) ...[
                      buildPlanSelector(theme),
                      const SizedBox(height: 16),
                    ],

                    buildTextField(
                      controller: titleController,
                      label: 'عنوان النشاط',
                      hint: 'مثال: دوام العمل',
                      icon: Icons.title,
                      theme: theme,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    buildTextField(
                      controller: descriptionController,
                      label: 'وصف النشاط',
                      hint: 'وصف مختصر',
                      icon: Icons.description,
                      theme: theme,
                    ),
                    const SizedBox(height: 16),

                    buildDateTimeSection(theme),
                    const SizedBox(height: 16),

                    buildReminderSection(theme),
                    const SizedBox(height: 16),

                    buildTextField(
                      controller: notesController,
                      label: 'ملاحظات',
                      hint: 'ملاحظات إضافية...',
                      icon: Icons.note,
                      maxLines: 3,
                      theme: theme,
                    ),
                    const SizedBox(height: 24),

                    buildActionButtons(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
