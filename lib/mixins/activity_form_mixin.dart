// lib/mixins/activity_form_mixin.dart
/// Mixin مشترك بين شاشات إضافة وتعديل النشاط
/// يقلل تكرار الكود بنسبة ~60% ويوحّد منطق النماذج

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/activity_model.dart';
import '../models/activity_plan_model.dart';
import '../services/activity_plan_api.dart';

/// Mixin لمشاركة حالة النموذج ومنطق العرض بين شاشات إضافة/تعديل النشاط
///
/// يجب على الشاشة المستخدمة أن تمزج مع TickerProviderStateMixin لتوفير vsync.
mixin ActivityFormMixin<T extends StatefulWidget> on State<T> {
  // ──────────────────────────────────────────────
  // 📦 الحالة المشتركة (Shared State)
  // ──────────────────────────────────────────────
  late AnimationController animationController;
  late Animation<double> fadeAnimation;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final notesController = TextEditingController();

  ActivityCategory? selectedCategory;
  DateTime startDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  DateTime endDate = DateTime.now().add(const Duration(hours: 1));
  late TimeOfDay endTime;

  bool hasReminder = true;
  int reminderMinutes = 15;
  bool isSaving = false;

  // 🆕 Plan linking
  List<ActivityPlan> plans = [];
  ActivityPlan? selectedPlan;
  bool isLoadingPlans = false;

  // ──────────────────────────────────────────────
  // 🧩 خصائص وهمية يجب أن توفرها الشاشة المستخدمة
  // ──────────────────────────────────────────────

  /// فئات الأنشطة (تأتي من Widget الخاص بكل شاشة)
  List<ActivityCategory> get categories;

  /// تنفيذ حفظ النشاط (يختلف بين الإضافة والتعديل)
  Future<void> onSave();

  /// دالة اختيارية تُستدعى بعد تحميل الخطط (بعد أول build).
  /// يمكن للشاشات تجاوزها لتهيئة حقول إضافية تعتمد على البيانات المحملة.
  void onFormReady() {}

  // ──────────────────────────────────────────────
  // 🚀 التهيئة المشتركة
  // ──────────────────────────────────────────────
  void initActivityForm(TickerProvider vsync) {
    // ملاحظة: لا تستدعي super.initState() هنا - الشاشة تفعل ذلك
    endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);

    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 500),
    );
    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    );

    if (categories.isNotEmpty) {
      selectedCategory = categories.first;
    }

    // ⚠️ مهم: كل ما يستدعي setState() أو يعتمد على build يُؤجَّل لما بعد أول
    //    إطار (post-frame) لتجنب خطأ:
    //    "setState() or markNeedsBuild() called during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      animationController.forward();

      loadPlans().then((_) {
        if (!mounted) return;
        onFormReady();
      });
    });
  }

  // ──────────────────────────────────────────────
  // 🧹 التنظيف المشترك
  // ──────────────────────────────────────────────
  void disposeActivityForm() {
    animationController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    notesController.dispose();
  }

  // ──────────────────────────────────────────────
  // ⚙️ دوال مساعدة مشتركة
  // ──────────────────────────────────────────────
  DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> loadPlans() async {
    setState(() => isLoadingPlans = true);
    try {
      plans = await ActivityPlanService.getPlans(isActive: true);
    } catch (e) {
      // silent
    }
    if (mounted) {
      setState(() => isLoadingPlans = false);
    }
  }

  /// بناء بيانات النشاط المشتركة (خريطة JSON)
  Map<String, dynamic> buildActivityData() {
    return {
      'category_id': selectedCategory!.id,
      'title': titleController.text,
      'description': descriptionController.text,
      'start_time': combineDateAndTime(startDate, startTime).toIso8601String(),
      'end_time': combineDateAndTime(endDate, endTime).toIso8601String(),
      'has_reminder': hasReminder,
      'reminder_minutes': reminderMinutes,
      'notes': notesController.text,
      // Plan linking
      if (selectedPlan != null) 'plan_id': selectedPlan!.id,
      if (selectedPlan != null) 'plan_name': selectedPlan!.name,
    };
  }

  // ──────────────────────────────────────────────
  // 🧱 دوال بناء الويدجت المشتركة
  // ──────────────────────────────────────────────

  /// التحقق من صحة النموذج قبل الحفظ
  bool validateForm() {
    if (!formKey.currentState!.validate()) return false;

    if (selectedCategory == null) {
      showSnackBar('❌ الرجاء اختيار تصنيف النشاط', AppColors.danger);
      return false;
    }

    final startDT = combineDateAndTime(startDate, startTime);
    final endDT = combineDateAndTime(endDate, endTime);

    if (endDT.isBefore(startDT)) {
      showSnackBar(
        '❌ وقت النهاية يجب أن يكون بعد وقت البداية',
        AppColors.danger,
      );
      return false;
    }

    return true;
  }

  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 🏗️ ويدجت بناء التصنيف
  // ══════════════════════════════════════════════
  Widget buildCategorySelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'تصنيف النشاط',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory?.id == category.id;
              final catColor = category.color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? catColor.withOpacity(0.15)
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(
                            0.5,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? catColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        color: isSelected
                            ? catColor
                            : catColor.withOpacity(0.6),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected
                              ? catColor
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 🏗️ ويدجت منتقي الخطة
  // ══════════════════════════════════════════════
  Widget buildPlanSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'ربط بخطة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isLoadingPlans
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : DropdownButtonFormField<ActivityPlan>(
                  value: selectedPlan,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_month, size: 20),
                    hintText: 'اختر خطة (اختياري)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<ActivityPlan>(
                      value: null,
                      child: Text(
                        'بدون خطة',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    ...plans.map((plan) {
                      return DropdownMenuItem<ActivityPlan>(
                        value: plan,
                        child: Row(
                          children: [
                            Icon(
                              plan.planType.icon,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                plan.name,
                                style: theme.textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (plan) {
                    setState(() => selectedPlan = plan);
                  },
                ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 🏗️ ويدجت حقل النص
  // ══════════════════════════════════════════════
  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: theme.colorScheme.primary),
          border: InputBorder.none,
          labelStyle: theme.textTheme.bodyMedium,
          hintStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        style: theme.textTheme.bodyMedium,
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                return null;
              }
            : null,
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 🏗️ ويدجت قسم التاريخ والوقت
  // ══════════════════════════════════════════════
  Widget buildDateTimeSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: const Icon(Icons.play_arrow, color: AppColors.primary),
            ),
            title: Text('بداية النشاط', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              '${startDate.year}/${startDate.month}/${startDate.day} - '
              '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Icon(
              Icons.edit,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: startTime,
                );
                if (time != null && mounted) {
                  setState(() {
                    startDate = date;
                    startTime = time;
                  });
                }
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.warning.withOpacity(0.1),
              child: const Icon(Icons.stop, color: AppColors.warning),
            ),
            title: Text('نهاية النشاط', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              '${endDate.year}/${endDate.month}/${endDate.day} - '
              '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Icon(
              Icons.edit,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: endDate,
                firstDate: startDate,
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null && mounted) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: endTime,
                );
                if (time != null && mounted) {
                  setState(() {
                    endDate = date;
                    endTime = time;
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 🏗️ ويدجت قسم التذكير
  // ══════════════════════════════════════════════
  Widget buildReminderSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('تفعيل التذكير', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              'احصل على إشعار قبل النشاط',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            value: hasReminder,
            activeColor: AppColors.warning,
            onChanged: (value) {
              setState(() {
                hasReminder = value;
              });
            },
          ),
          if (hasReminder) ...[
            const Divider(),
            ListTile(
              title: Text('وقت التذكير', style: theme.textTheme.bodyMedium),
              subtitle: Text(
                'قبل النشاط ب $reminderMinutes دقيقة',
                style: theme.textTheme.bodySmall,
              ),
              trailing: DropdownButton<int>(
                value: reminderMinutes,
                dropdownColor: theme.cardColor,
                style: theme.textTheme.bodyMedium,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 دقائق')),
                  DropdownMenuItem(value: 10, child: Text('10 دقائق')),
                  DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                  DropdownMenuItem(value: 30, child: Text('30 دقيقة')),
                  DropdownMenuItem(value: 60, child: Text('ساعة')),
                ],
                onChanged: (value) {
                  setState(() {
                    reminderMinutes = value!;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // 🏗️ ويدجت أزرار الإجراءات
  // ══════════════════════════════════════════════
  Widget buildActionButtons(
    ThemeData theme, {
    String saveLabel = 'حفظ النشاط',
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    saveLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('إلغاء'),
          ),
        ),
      ],
    );
  }
}
