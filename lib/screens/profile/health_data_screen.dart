// lib/screens/profile/health_data_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../constants/colors.dart';
import '../../models/nutrition_model.dart';
import '../../services/nutrition_api.dart';
import '../../utils/prefs_helper.dart';

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});

  @override
  State<HealthDataScreen> createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  UserNutritionData? _healthData;
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _ageController;
  late String _selectedGender;
  late String _selectedGoal;
  late String _selectedActivityLevel;
  late List<String> _selectedDiseases;

  final List<String> _genders = ['ذكر', 'أنثى'];
  final List<String> _goals = [
    'تخسيس',
    'تثبيت الوزن',
    'زيادة الوزن',
    'بناء عضلات',
  ];
  final List<String> _activityLevels = [
    'قليل',
    'خفيف',
    'متوسط',
    'نشيط',
    'نشيط جداً',
  ];
  final List<Map<String, dynamic>> _diseasesList = [
    {'name': 'السكري', 'icon': Icons.bloodtype},
    {'name': 'ضغط الدم', 'icon': Icons.favorite},
    {'name': 'أمراض القلب', 'icon': Icons.favorite_border},
    {'name': 'الغدة الدرقية', 'icon': Icons.medical_services},
    {'name': 'فقر الدم', 'icon': Icons.water_drop},
    {'name': 'حساسية الطعام', 'icon': Icons.restaurant},
    {'name': 'الربو', 'icon': Icons.air},
    {'name': 'أمراض الكلى', 'icon': Icons.science},
  ];

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthData() async {
    setState(() => _isLoading = true);

    try {
      final data = await NutritionService.getUserNutritionData();
      final localData = PrefsHelper.getUserData();

      if (data != null) {
        _healthData = data;
        _initializeControllers(data);
      } else if (localData.isNotEmpty) {
        _healthData = UserNutritionData(
          id: localData['id'] ?? 1,
          weight: (localData['weight'] ?? 70.0).toDouble(),
          height: (localData['height'] ?? 170.0).toDouble(),
          age: localData['age'] ?? 30,
          gender: localData['gender'] ?? 'ذكر',
          goal: localData['goal'] ?? 'تخسيس',
          activityLevel: localData['activityLevel'] ?? 'متوسط',
          weightLossRate: localData['weightLossRate'] ?? '0.5',
          targetWeight: (localData['targetWeight'] ?? 70.0).toDouble(),
          diseases: List<String>.from(localData['diseases'] ?? []),
          targetCalories: (localData['targetCalories'] ?? 2000.0).toDouble(),
          bmr: (localData['bmr'] ?? 1500.0).toDouble(),
          tdee: (localData['tdee'] ?? 2000.0).toDouble(),
          createdAt: DateTime.now(),
          waterIntake: (localData['waterIntake'] ?? 2.5).toDouble(),
        );
        _initializeControllers(_healthData!);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('خطأ في تحميل البيانات الصحية: $e');
      setState(() => _isLoading = false);
    }
  }

  void _initializeControllers(UserNutritionData data) {
    _weightController = TextEditingController(text: data.weight.toString());
    _heightController = TextEditingController(text: data.height.toString());
    _targetWeightController = TextEditingController(
      text: data.targetWeight.toString(),
    );
    _ageController = TextEditingController(text: data.age.toString());
    _selectedGender = data.gender;
    _selectedGoal = data.goal;
    _selectedActivityLevel = data.activityLevel;
    _selectedDiseases = List.from(data.diseases);
  }

  Future<void> _saveHealthData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updatedData = UserNutritionData(
          id: _healthData?.id ?? 1,
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          age: int.parse(_ageController.text),
          gender: _selectedGender,
          goal: _selectedGoal,
          activityLevel: _selectedActivityLevel,
          weightLossRate: _healthData?.weightLossRate ?? '0.5',
          targetWeight: double.parse(_targetWeightController.text),
          diseases: _selectedDiseases,
          targetCalories: _healthData?.targetCalories ?? 2000,
          bmr: _healthData?.bmr ?? 1500,
          tdee: _healthData?.tdee ?? 2000,
          createdAt: DateTime.now(),
          waterIntake: _healthData?.waterIntake ?? 2.5,
        );

        // TODO: حفظ البيانات في API
        await PrefsHelper.saveUserNutritionData(updatedData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم تحديث البيانات الصحية بنجاح'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _isEditing = false;
            _healthData = updatedData;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('خطأ في حفظ البيانات: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('فشل في تحديث البيانات'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  double get _bmi {
    if (_healthData == null) return 0;
    double heightInMeters = _healthData!.height / 100;
    return _healthData!.weight / (heightInMeters * heightInMeters);
  }

  String get _bmiStatus {
    double bmi = _bmi;
    if (bmi < 18.5) return 'نقص وزن';
    if (bmi < 25) return 'وزن طبيعي';
    if (bmi < 30) return 'زيادة وزن';
    return 'سمنة';
  }

  Color get _bmiColor {
    double bmi = _bmi;
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('البيانات الصحية'),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditing = true),
              ),
            if (_isEditing)
              TextButton(
                onPressed: _saveHealthData,
                child: const Text(
                  'حفظ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _healthData == null
            ? _buildEmptyState()
            : AnimationLimiter(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildBMICard(theme),
                      const SizedBox(height: 16),
                      _buildHealthForm(theme),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('لا توجد بيانات صحية'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => setState(() => _isEditing = true),
            child: const Text('إضافة بيانات'),
          ),
        ],
      ),
    );
  }

  Widget _buildBMICard(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bmiColor.withOpacity(0.1), _bmiColor.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text(
              'مؤشر كتلة الجسم (BMI)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _bmi.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: _bmiColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _bmiColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _bmiStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthForm(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                theme,
                'الوزن (كجم)',
                _weightController,
                Icons.monitor_weight,
                'كجم',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                theme,
                'الطول (سم)',
                _heightController,
                Icons.straighten,
                'سم',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                theme,
                'الوزن المستهدف (كجم)',
                _targetWeightController,
                Icons.flag,
                'كجم',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                theme,
                'العمر',
                _ageController,
                Icons.cake,
                'سنة',
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                theme,
                'الجنس',
                _genders,
                _selectedGender,
                (value) => setState(() => _selectedGender = value!),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                theme,
                'الهدف',
                _goals,
                _selectedGoal,
                (value) => setState(() => _selectedGoal = value!),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                theme,
                'مستوى النشاط',
                _activityLevels,
                _selectedActivityLevel,
                (value) => setState(() => _selectedActivityLevel = value!),
              ),
              const SizedBox(height: 16),
              _buildDiseasesSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  // في دالة _buildTextField - غير enabled إلى readOnly
  Widget _buildTextField(
    ThemeData theme,
    String label,
    TextEditingController controller,
    IconData icon,
    String suffix,
  ) {
    return TextFormField(
      controller: controller,
      readOnly: !_isEditing, // ✅ تغيير من enabled: _isEditing
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value?.isEmpty ?? true ? '$label مطلوب' : null,
    );
  }

  Widget _buildDropdown(
    ThemeData theme,
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    // ✅ تأكد من أن القيمة موجودة في القائمة
    final isValidValue = items.contains(value);
    final selectedValue = isValidValue ? value : items.first;

    return DropdownButtonFormField<String>(
      value: selectedValue, // ✅ استخدام قيمة صالحة دائماً
      isExpanded: true,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          Icons.arrow_drop_down,
          color: theme.colorScheme.primary,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: _isEditing
          ? (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            }
          : null,
    );
  }
  Widget _buildDiseasesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأمراض المزمنة',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _diseasesList.map((disease) {
            final isSelected = _selectedDiseases.contains(disease['name']);
            return FilterChip(
              label: Text(disease['name']),
              selected: isSelected,
              onSelected: _isEditing
                  ? (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDiseases.add(disease['name']);
                        } else {
                          _selectedDiseases.remove(disease['name']);
                        }
                      });
                    }
                  : null,
              avatar: Icon(disease['icon'], size: 18),
              backgroundColor: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : null,
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
            );
          }).toList(),
        ),
      ],
    );
  }
}
