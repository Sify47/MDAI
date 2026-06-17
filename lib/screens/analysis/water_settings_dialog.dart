// lib/screens/water/water_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:vita/services/water_service.dart';
import '../../constants/colors.dart';

class WaterSettingsDialog extends StatefulWidget {
  final Map<String, dynamic> currentSettings;

  const WaterSettingsDialog({Key? key, required this.currentSettings})
    : super(key: key);

  @override
  State<WaterSettingsDialog> createState() => _WaterSettingsDialogState();
}

class _WaterSettingsDialogState extends State<WaterSettingsDialog> {
  late TextEditingController _dailyGoalController;
  late TextEditingController _cupSizeController;
  late TextEditingController _reminderIntervalController;
  late TextEditingController _reminderStartController;
  late TextEditingController _reminderEndController;
  late bool _enableNotifications;

  @override
  void initState() {
    super.initState();
    _dailyGoalController = TextEditingController(
      text: (widget.currentSettings['daily_goal'] ?? 2.5).toString(),
    );
    _cupSizeController = TextEditingController(
      text: (widget.currentSettings['cup_size'] ?? 0.25).toString(),
    );
    _reminderIntervalController = TextEditingController(
      text: (widget.currentSettings['reminder_interval'] ?? 60).toString(),
    );
    _reminderStartController = TextEditingController(
      text: widget.currentSettings['reminder_start'] ?? '08:00',
    );
    _reminderEndController = TextEditingController(
      text: widget.currentSettings['reminder_end'] ?? '22:00',
    );
    _enableNotifications =
        widget.currentSettings['enable_notifications'] ?? true;
  }

  @override
  void dispose() {
    _dailyGoalController.dispose();
    _cupSizeController.dispose();
    _reminderIntervalController.dispose();
    _reminderStartController.dispose();
    _reminderEndController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final result = await WaterService.updateWaterSettings(
      dailyGoal: double.tryParse(_dailyGoalController.text),
      cupSize: double.tryParse(_cupSizeController.text),
      reminderInterval: int.tryParse(_reminderIntervalController.text),
      reminderStart: _reminderStartController.text,
      reminderEnd: _reminderEndController.text,
      enableNotifications: _enableNotifications,
    );

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تحديث الإعدادات'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['message'] ?? 'فشل في تحديث الإعدادات'}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '⚙️ إعدادات شرب الماء',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // الهدف اليومي
            TextField(
              controller: _dailyGoalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الهدف اليومي (لتر)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // حجم الكوب
            TextField(
              controller: _cupSizeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'حجم الكوب (لتر)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // تفعيل الإشعارات
            SwitchListTile(
              title: const Text('تفعيل تذكيرات شرب الماء'),
              value: _enableNotifications,
              onChanged: (value) {
                setState(() => _enableNotifications = value);
              },
              activeColor: theme.colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),

            if (_enableNotifications) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reminderIntervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'فترة التذكير (دقائق)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reminderStartController,
                decoration: const InputDecoration(
                  labelText: 'وقت بدء التذكير (HH:MM)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reminderEndController,
                decoration: const InputDecoration(
                  labelText: 'وقت انتهاء التذكير (HH:MM)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
