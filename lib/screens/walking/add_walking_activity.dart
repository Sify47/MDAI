import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/walking_api.dart';
import '../../utils/nutrition_calculator.dart';
import '../../utils/prefs_helper.dart';

class AddWalkingActivity extends StatefulWidget {
  const AddWalkingActivity({Key? key}) : super(key: key);

  @override
  State<AddWalkingActivity> createState() => _AddWalkingActivityState();
}

class _AddWalkingActivityState extends State<AddWalkingActivity>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final _formKey = GlobalKey<FormState>();
  String _inputMethod = 'steps';
  String _activityType = 'walking';
  double _weight = 70.0;
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isSaving = false;

  // بيانات كل نوع نشاط
  static const Map<String, Map<String, dynamic>> _activityData = {
    'walking': {
      'icon': '🚶',
      'label': 'مشي',
      'color': AppColors.walking,
      'met': 3.5,
    },
    'running': {
      'icon': '🏃',
      'label': 'جري',
      'color': AppColors.calories,
      'met': 8.0,
    },
    'cycling': {
      'icon': '🚴',
      'label': 'دراجة',
      'color': AppColors.info,
      'met': 6.0,
    },
    'swimming': {
      'icon': '🏊',
      'label': 'سباحة',
      'color': AppColors.secondary,
      'met': 7.0,
    },
    'strength': {
      'icon': '🏋️',
      'label': 'تمارين قوة',
      'color': AppColors.medications,
      'met': 4.0,
    },
    'yoga': {
      'icon': '🧘',
      'label': 'يوجا',
      'color': AppColors.tertiary,
      'met': 2.5,
    },
  };

  Color get _currentColor =>
      (_activityData[_activityType]?['color'] as Color?) ?? AppColors.walking;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    _loadWeight();
  }

  void _loadWeight() {
    final userData = PrefsHelper.getUserData();
    _weight = (userData['weight'] as double?) ?? 70.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    _stepsController.dispose();
    _distanceController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int _calculateCalories() {
    int duration = 0;

    if (_stepsController.text.isNotEmpty) {
      duration = _calculateTimeFromSteps(int.parse(_stepsController.text));
    } else if (_distanceController.text.isNotEmpty) {
      final steps = (double.parse(_distanceController.text) * 1000 / 0.75).round();
      duration = _calculateTimeFromSteps(steps);
    } else if (_timeController.text.isNotEmpty) {
      duration = int.parse(_timeController.text);
    }

    if (duration <= 0) return 0;

    return NutritionCalculator.calculateActivityCalories(
      weight: _weight,
      durationMinutes: duration,
      activityType: _activityType,
    );
  }

  double _calculateDistanceFromSteps(int steps) {
    return (steps * 0.75 / 1000);
  }

  int _calculateTimeFromSteps(int steps) {
    return (steps / 100).round();
  }

  Future<void> _saveActivity() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      int steps = 0;
      double distance = 0;
      int duration = 0;

      switch (_inputMethod) {
        case 'steps':
          steps = int.parse(_stepsController.text);
          distance = _calculateDistanceFromSteps(steps);
          duration = _calculateTimeFromSteps(steps);
          break;
        case 'distance':
          distance = double.parse(_distanceController.text);
          steps = (distance * 1000 / 0.75).round();
          duration = _calculateTimeFromSteps(steps);
          break;
        case 'time':
          duration = int.parse(_timeController.text);
          steps = duration * 100;
          distance = _calculateDistanceFromSteps(steps);
          break;
      }

      final newActivity = {
        'steps': steps,
        'distance_km': distance,
        'duration_minutes': duration,
        'calories_burned': _calculateCalories(),
        'activity_date': _selectedDate.toIso8601String().split('T')[0],
        'activity_time': '${_selectedTime.hour}:${_selectedTime.minute}',
        'notes': _notesController.text,
        'activity_type': _activityType,
      };

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final savedActivity = await WalkingService.addActivity(newActivity);

      if (mounted) Navigator.pop(context);

      if (savedActivity != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ تم إضافة النشاط بنجاح'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, savedActivity);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ فشل في إضافة النشاط'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activityLabel = _activityData[_activityType]?['label'] ?? 'مشي';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          title: Text('➕ إضافة نشاط $activityLabel'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ScaleTransition(
              scale: _animation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActivityTypeSelector(theme),
                    const SizedBox(height: 24),
                    _buildInputMethodSelector(theme),
                    const SizedBox(height: 24),
                    _buildInputFields(theme),
                    const SizedBox(height: 24),
                    _buildDateTimePicker(theme),
                    const SizedBox(height: 24),
                    _buildCalorieCalculation(theme),
                    const SizedBox(height: 24),
                    _buildNotesField(theme),
                    const SizedBox(height: 32),
                    _buildActionButtons(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTypeSelector(ThemeData theme) {
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
              Text(
                'نوع النشاط',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _currentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'الوزن: ${_weight.toStringAsFixed(0)} كجم',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _currentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _activityData.entries.map((entry) {
              final isSelected = _activityType == entry.key;
              final color = entry.value['color'] as Color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _activityType = entry.key;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.value['icon'] as String,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.value['label'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? color
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputMethodSelector(ThemeData theme) {
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
          Text(
            'طريقة الإدخال',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMethodOption(
                  value: 'steps',
                  icon: '👣',
                  label: 'خطوات',
                  isSelected: _inputMethod == 'steps',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMethodOption(
                  value: 'distance',
                  icon: '📏',
                  label: 'مسافة',
                  isSelected: _inputMethod == 'distance',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMethodOption(
                  value: 'time',
                  icon: '⏱️',
                  label: 'وقت',
                  isSelected: _inputMethod == 'time',
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption({
    required String value,
    required String icon,
    required String label,
    required bool isSelected,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _inputMethod = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _currentColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _currentColor
                : theme.colorScheme.outline.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? _currentColor
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields(ThemeData theme) {
    switch (_inputMethod) {
      case 'steps':
        return _buildStepsInput(theme);
      case 'distance':
        return _buildDistanceInput(theme);
      case 'time':
        return _buildTimeInput(theme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStepsInput(ThemeData theme) {
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
          Text(
            'عدد الخطوات',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _stepsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'مثال: 5000',
              suffixText: 'خطوة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _currentColor),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            style: theme.textTheme.bodyMedium,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال عدد الخطوات';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceInput(ThemeData theme) {
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
          Text(
            'المسافة',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _distanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'مثال: 5.2',
              suffixText: 'كم',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _currentColor),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            style: theme.textTheme.bodyMedium,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال المسافة';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput(ThemeData theme) {
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
          Text(
            'الوقت',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _timeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'مثال: 30',
              suffixText: 'دقيقة',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _currentColor),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            style: theme.textTheme.bodyMedium,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'الرجاء إدخال الوقت';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker(ThemeData theme) {
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
              backgroundColor: _currentColor.withOpacity(0.1),
              child: Icon(Icons.calendar_today, color: _currentColor),
            ),
            title: Text('التاريخ', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null && mounted) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _currentColor.withOpacity(0.1),
              child: Icon(Icons.access_time, color: _currentColor),
            ),
            title: Text('الوقت', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null && mounted) {
                setState(() {
                  _selectedTime = time;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCalculation(ThemeData theme) {
    int estimatedCalories = _calculateCalories();
    final activityLabel = _activityData[_activityType]?['label'] ?? 'مشي';
    final met = _activityData[_activityType]?['met'] ?? 3.5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.calories.withOpacity(0.1),
            _currentColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السعرات المحروقة التقريبية:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.calories,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$estimatedCalories سعرة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$activityLabel • MET: $met • الوزن: ${_weight.toStringAsFixed(0)} كجم',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField(ThemeData theme) {
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
          Text(
            'ملاحظات',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'أضف ملاحظات عن النشاط...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _currentColor),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveActivity,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'حفظ النشاط',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
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
