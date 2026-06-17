// lib/screens/settings/quiet_hours_settings.dart

import 'package:flutter/material.dart';
import '../../utils/prefs_helper.dart';
import '../../constants/colors.dart';
import '../../services/notification_service.dart';
import '../../services/medication_api.dart';

class QuietHoursSettings extends StatefulWidget {
  const QuietHoursSettings({Key? key}) : super(key: key);

  @override
  State<QuietHoursSettings> createState() => _QuietHoursSettingsState();
}

class _QuietHoursSettingsState extends State<QuietHoursSettings> {
  bool _enabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0); // 7 مساءً
  TimeOfDay _endTime = const TimeOfDay(hour: 7, minute: 0); // 7 صباحاً

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _enabled = PrefsHelper.getQuietHoursEnabled();
      final (startHour, startMinute) = PrefsHelper.getQuietStartTime();
      final (endHour, endMinute) = PrefsHelper.getQuietEndTime();
      _startTime = TimeOfDay(hour: startHour, minute: startMinute);
      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
    });
  }

  Future<void> _saveSettings() async {
    await PrefsHelper.setQuietHoursEnabled(_enabled);
    await PrefsHelper.setQuietStartTime(_startTime.hour, _startTime.minute);
    await PrefsHelper.setQuietEndTime(_endTime.hour, _endTime.minute);

    // إعادة جدولة الإشعارات بعد تغيير الإعدادات
    final medications = await MedicationService.getMedications();
    await NotificationService.rescheduleAllNotifications(medications);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ إعدادات ساعات الهدوء'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔇 ساعات الهدوء')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // تفعيل ساعات الهدوء
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔇 تفعيل ساعات الهدوء',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'لن يتم إرسال أي إشعارات خلال هذه الفترة',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    onChanged: (value) {
                      setState(() {
                        _enabled = value;
                      });
                      _saveSettings();
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_enabled) ...[
              // وقت البدء
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌙 وقت بدء الهدوء',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final newTime = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(
                                context,
                              ).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            );
                          },
                        );
                        if (newTime != null) {
                          setState(() {
                            _startTime = newTime;
                          });
                          _saveSettings();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 12),
                            Text(
                              '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // وقت الانتهاء
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '☀️ وقت انتهاء الهدوء',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final newTime = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                          builder: (context, child) {
                            return MediaQuery(
                              data: MediaQuery.of(
                                context,
                              ).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            );
                          },
                        );
                        if (newTime != null) {
                          setState(() {
                            _endTime = newTime;
                          });
                          _saveSettings();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 12),
                            Text(
                              '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'خلال ساعات الهدوء (من ${_startTime.format(context)} إلى ${_endTime.format(context)})، لن تتلقى أي إشعارات تذكير. سيتم تأجيلها إلى ما بعد فترة الهدوء.',
                        style: TextStyle(fontSize: 12, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
