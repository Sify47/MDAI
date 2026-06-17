// lib/screens/symptoms/add_symptom_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/models/nutrition_model.dart';
import 'package:vita/services/nutrition_api.dart';
import '../../../constants/colors.dart';
import '../../../services/symptom_api.dart';
import 'symptom_analysis_screen.dart';
import '../../../services/advanced_symptom_analysis.dart';

class AddSymptomScreen extends StatefulWidget {
  final UserNutritionData? userData;

  const AddSymptomScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends State<AddSymptomScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _commonSymptoms = [
    {'name': 'صداع', 'icon': '🤕', 'color': AppColors.warning},
    {'name': 'دوخة', 'icon': '😵', 'color': AppColors.primary},
    {'name': 'غثيان', 'icon': '🤢', 'color': AppColors.warning},
    {'name': 'تعب', 'icon': '😴', 'color': AppColors.textSecondary},
    {'name': 'إرهاق', 'icon': '😩', 'color': AppColors.textSecondary},
    {'name': 'ألم صدر', 'icon': '💔', 'color': AppColors.danger},
    {'name': 'ضيق تنفس', 'icon': '😮‍💨', 'color': AppColors.danger},
    {'name': 'حرارة', 'icon': '🌡️', 'color': AppColors.calories},
    {'name': 'ألم بطن', 'icon': '🫄', 'color': AppColors.calories},
    {'name': 'إسهال', 'icon': '🚽', 'color': AppColors.warning},
    {'name': 'إمساك', 'icon': '💩', 'color': AppColors.warning},
    {'name': 'زغللة العين', 'icon': '👁️', 'color': AppColors.medications},
    {'name': 'تنميل الأطراف', 'icon': '🫨', 'color': AppColors.warning},
  ];

  String _selectedSeverity = 'متوسط';
  final TextEditingController _customSymptomController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedSymptom = '';
  String _selectedIcon = '';
  Color _selectedColor = AppColors.primary;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _customSymptomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<UserNutritionData?> _loadUserDataIfNeeded() async {
    if (widget.userData != null) {
      return widget.userData;
    }
    try {
      return await NutritionService.getUserNutritionData();
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
      return null;
    }
  }

  Future<void> _analyzeBeforeAdd() async {
    if (_selectedSymptom.isEmpty && _customSymptomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ الرجاء اختيار أو كتابة عرض'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final symptomName = _selectedSymptom.isNotEmpty
        ? _selectedSymptom
        : _customSymptomController.text;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      final userData = await _loadUserDataIfNeeded();
      Map<String, dynamic> analysisResult;

      if (userData != null) {
        final advancedAnalysis = AdvancedSymptomAnalysis(
          userData: userData,
          symptomName: symptomName,
          severity: _selectedSeverity,
        );
        analysisResult = await advancedAnalysis.analyze();
      } else {
        final apiAnalysis = await SymptomService.analyzeSymptom({
          'name': symptomName,
          'severity': _selectedSeverity,
        });
        analysisResult = apiAnalysis;
      }

      final symptomData = {
        'symptom': symptomName,
        'icon': _selectedIcon.isNotEmpty ? _selectedIcon : '🤒',
        'severity': _selectedSeverity,
        'date': '${dateTime.year}/${dateTime.month}/${dateTime.day}',
        'time': '${dateTime.hour}:${dateTime.minute}',
        'color': _selectedColor,
        'notes': _notesController.text,
        'analysis': analysisResult['analysis'] ?? '',
        'possible_causes': analysisResult['possible_causes'] ?? [],
        'suggested_actions': analysisResult['suggested_actions'] ?? [],
        'warning_signs': analysisResult['warning_signs'] ?? [],
        'food_recommendations': analysisResult['food_recommendations'],
        'nutritional_deficiencies': analysisResult['nutritional_deficiencies'],
        'medication_effects': analysisResult['medication_effects'],
        'lifestyle_factors': analysisResult['lifestyle_factors'],
      };

      final shouldSave = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SymptomAnalysisScreen(
            symptomData: symptomData,
            onSave: () => _saveSymptom(symptomData),
          ),
        ),
      );

      if (shouldSave == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSymptom(Map<String, dynamic> symptomData) async {
    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final result = await SymptomService.addSymptom({
        'name': symptomData['symptom'],
        'icon': symptomData['icon'],
        'severity': symptomData['severity'],
        'date_time': dateTime.toIso8601String(),
        'notes': _notesController.text,
        'analysis': symptomData['analysis'],
        'possible_causes': symptomData['possible_causes'],
        'suggested_actions': symptomData['suggested_actions'],
        'warning_signs': symptomData['warning_signs'],
      });

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
        return; // ✅ منع الوصول إلى finally بعد الـ pop
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        // ✅ التأكد من أن الويدجت لا يزال نشطاً قبل استدعاء setState
        setState(() => _isLoading = false);
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
          title: Text('➕ تسجيل عرض جديد'),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSymptomSelector(theme),
                      const SizedBox(height: 24),
                      _buildSeveritySelector(theme),
                      const SizedBox(height: 24),
                      _buildDateTimePicker(theme),
                      const SizedBox(height: 24),
                      _buildCustomSymptom(theme),
                      const SizedBox(height: 24),
                      _buildNotes(theme),
                      const SizedBox(height: 32),
                      _buildActionButtons(theme),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر العرض',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: _commonSymptoms.length,
          itemBuilder: (context, index) {
            final symptom = _commonSymptoms[index];
            bool isSelected = _selectedSymptom == symptom['name'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSymptom = symptom['name'];
                  _selectedIcon = symptom['icon'];
                  _selectedColor = symptom['color'];
                  _customSymptomController.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (symptom['color'] as Color).withOpacity(0.15)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? symptom['color']
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(symptom['icon'], style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(
                      symptom['name'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: isSelected
                            ? symptom['color']
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeveritySelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'شدة العرض',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSeverityOption(
                label: 'خفيف',
                color: AppColors.success,
                icon: '🟢',
                value: 'خفيف',
                theme: theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSeverityOption(
                label: 'متوسط',
                color: AppColors.warning,
                icon: '🟡',
                value: 'متوسط',
                theme: theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSeverityOption(
                label: 'شديد',
                color: AppColors.danger,
                icon: '🔴',
                value: 'شديد',
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeverityOption({
    required String label,
    required Color color,
    required String icon,
    required String value,
    required ThemeData theme,
  }) {
    bool isSelected = _selectedSeverity == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSeverity = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? color
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
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
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.calendar_today,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text('تاريخ بداية العرض', style: theme.textTheme.bodyMedium),
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
                setState(() => _selectedDate = date);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.access_time, color: theme.colorScheme.primary),
            ),
            title: Text('وقت بداية العرض', style: theme.textTheme.bodyMedium),
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
                setState(() => _selectedTime = time);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSymptom(ThemeData theme) {
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
            'أو اكتب عرض مخصص',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customSymptomController,
            decoration: InputDecoration(
              hintText: 'مثال: ألم في الركبة اليمنى',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            style: theme.textTheme.bodyMedium,
            onChanged: (value) {
              if (value.isNotEmpty && mounted) {
                setState(() {
                  _selectedSymptom = '';
                  _selectedIcon = '🤒';
                  _selectedColor = theme.colorScheme.primary;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(ThemeData theme) {
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
            'ملاحظات إضافية',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'أضف تفاصيل أكثر عن العرض...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
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
            onPressed: _isLoading ? null : _analyzeBeforeAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'تحليل العرض',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
