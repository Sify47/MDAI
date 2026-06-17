// lib/screens/activities/add_activity_screen.dart
/// شاشة إضافة نشاط - تعاد هيكلتها باستخدام ActivityFormMixin لتقليل التكرار.

import 'package:flutter/material.dart';
import 'package:vita/services/notification_service.dart';
import '../../constants/colors.dart';
import '../../models/activity_model.dart';
import '../../mixins/activity_form_mixin.dart';
import '../../services/activity_api.dart';

class AddActivityScreen extends StatefulWidget {
  final List<ActivityCategory> categories;

  const AddActivityScreen({Key? key, required this.categories})
    : super(key: key);

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen>
    with
        TickerProviderStateMixin<AddActivityScreen>,
        ActivityFormMixin<AddActivityScreen> {
  @override
  List<ActivityCategory> get categories => widget.categories;

  @override
  void initState() {
    super.initState();
    initActivityForm(this);
  }

  @override
  void dispose() {
    disposeActivityForm();
    super.dispose();
  }

  @override
  Future<void> onSave() async {
    if (!validateForm()) return;

    setState(() => isSaving = true);

    try {
      final activityData = buildActivityData();
      final result = await ActivityService.addActivity(activityData);

      if (!mounted) return;

      if (result['success'] == true) {
        final savedData = result['data'];
        final activityId = savedData['id'] is int
            ? savedData['id'] as int
            : int.tryParse(savedData['id']?.toString() ?? '') ?? 0;
        final activityTitle = savedData['title']?.toString() ?? '';
        final activityDescription = savedData['description']?.toString() ?? '';

        if (activityId == 0) {
          setState(() => isSaving = false);
          if (mounted) {
            showSnackBar(
              '❌ فشل في استلام معرف النشاط من السيرفر',
              AppColors.danger,
            );
          }
          return;
        }

        // جدولة الإشعارات
        if (hasReminder) {
          await NotificationService.scheduleActivityNotification(
            activityId: activityId,
            title: activityTitle,
            description: activityDescription,
            startTime: combineDateAndTime(startDate, startTime),
            reminderMinutes: reminderMinutes,
          );
        }

        setState(() => isSaving = false);
        showSnackBar('✅ ${result['message']}', AppColors.success);
        if (mounted) Navigator.pop(context, result['data']);
      } else {
        setState(() => isSaving = false);
        showSnackBar('❌ ${result['message']}', AppColors.danger);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        showSnackBar('❌ حدث خطأ أثناء حفظ النشاط: $e', AppColors.danger);
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
          title: Text('➕ إضافة نشاط'),
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
