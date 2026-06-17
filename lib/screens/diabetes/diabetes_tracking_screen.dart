// lib/screens/diabetes/diabetes_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vita/services/diabetes_api.dart';
import 'package:vita/models/diabetes_models.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/utils/prefs_helper.dart';

class DiabetesTrackingScreen extends StatefulWidget {
  const DiabetesTrackingScreen({super.key});

  @override
  State<DiabetesTrackingScreen> createState() => _DiabetesTrackingScreenState();
}

class _DiabetesTrackingScreenState extends State<DiabetesTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DiabetesApi _diabetesApi = DiabetesApi();

  List<BloodSugarMeasurement> _measurements = [];
  List<DiabetesSymptom> _symptoms = [];
  bool _isLoading = true;

  // مُتحكمات حقول الإضافة للقياسات
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  final _mealDescriptionController = TextEditingController();

  // مُتحكمات حقول الإضافة للأعراض
  final _symptomNameController = TextEditingController();

  BloodSugarType _selectedSugarType = BloodSugarType.fasting;
  BloodSugarUnit _selectedUnit = BloodSugarUnit.mgdl;
  SymptomSeverity _selectedSeverity = SymptomSeverity.mild;
  String _selectedSymptomType = 'hypoglycemia';
  DateTime _selectedDateTime = DateTime.now();

  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    _mealDescriptionController.dispose();
    _symptomNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    _currentUserId = PrefsHelper.getUserId();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (_currentUserId != null) {
        _measurements = await _diabetesApi.getBloodSugarMeasurements(
          _currentUserId!,
        );
        _symptoms = await _diabetesApi.getDiabetesSymptoms(_currentUserId!);
      }
    } catch (e) {
      print('Error loading diabetes data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addMeasurement() async {
    if (_valueController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال قيمة السكر')));
      return;
    }

    final value = double.tryParse(_valueController.text);
    if (value == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('قيمة غير صحيحة')));
      return;
    }

    try {
      final result = await _diabetesApi.addBloodSugarMeasurement(
        _currentUserId!,
        value,
        _selectedSugarType,
        _selectedUnit,
        _selectedDateTime,
        MeasurementContext.home,
        _notesController.text.isEmpty ? null : _notesController.text,
        _mealDescriptionController.text.isEmpty
            ? null
            : _mealDescriptionController.text,
        null,
      );

      if (result != null) {
        await _loadData();
        if (mounted) Navigator.pop(context);
        _clearMeasurementForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تم إضافة القياس بنجاح')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ خطأ: $e')));
    }
  }

  Future<void> _addSymptom() async {
    if (_symptomNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسم العرض')));
      return;
    }

    try {
      final result = await _diabetesApi.addDiabetesSymptom(
        _currentUserId!,
        _selectedSymptomType,
        _symptomNameController.text,
        _selectedSeverity,
        _selectedDateTime,
        _notesController.text.isEmpty ? null : _notesController.text,
        null,
        null,
        0,
      );

      if (result != null) {
        await _loadData();
        if (mounted) Navigator.pop(context);
        _clearSymptomForm();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ تم إضافة العرض بنجاح')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ خطأ: $e')));
    }
  }

  void _clearMeasurementForm() {
    _valueController.clear();
    _notesController.clear();
    _mealDescriptionController.clear();
    _selectedSugarType = BloodSugarType.fasting;
    _selectedDateTime = DateTime.now();
  }

  void _clearSymptomForm() {
    _symptomNameController.clear();
    _notesController.clear();
    _selectedSymptomType = 'hypoglycemia';
    _selectedSeverity = SymptomSeverity.mild;
    _selectedDateTime = DateTime.now();
  }

  Future<void> _deleteMeasurement(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا القياس؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _diabetesApi.deleteBloodSugarMeasurement(id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حذف القياس بنجاح')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ في الحذف: $e')));
        }
      }
    }
  }

  Future<void> _deleteSymptom(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العرض؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _diabetesApi.deleteDiabetesSymptom(id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حذف العرض بنجاح')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('خطأ في الحذف: $e')));
        }
      }
    }
  }

  void _showAddMeasurementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة قياس سكر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'قيمة السكر',
                  hintText: 'مثال: 120',
                  prefixIcon: Icon(Icons.bloodtype),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<BloodSugarType>(
                value: _selectedSugarType,
                decoration: const InputDecoration(
                  labelText: 'نوع القياس',
                  prefixIcon: Icon(Icons.timer),
                ),
                items: BloodSugarType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getMeasurementTypeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedSugarType = value);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('التاريخ والوقت'),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDateTime,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                    );
                    if (time != null && mounted) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  prefixIcon: Icon(Icons.note_add),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _addMeasurement,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showAddSymptomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عرض'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _symptomNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم العرض',
                  hintText: 'مثال: دوخة، عطش شديد',
                  prefixIcon: Icon(Icons.sick),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSymptomType,
                decoration: const InputDecoration(
                  labelText: 'نوع العرض',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'hypoglycemia',
                    child: Text('نقص سكر'),
                  ),
                  DropdownMenuItem(
                    value: 'hyperglycemia',
                    child: Text('ارتفاع سكر'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                onChanged: (value) {
                  if (value != null)
                    setState(() => _selectedSymptomType = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SymptomSeverity>(
                value: _selectedSeverity,
                decoration: const InputDecoration(
                  labelText: 'الشدة',
                  prefixIcon: Icon(Icons.warning),
                ),
                items: SymptomSeverity.values.map((severity) {
                  return DropdownMenuItem(
                    value: severity,
                    child: Text(_getSeverityLabel(severity)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedSeverity = value);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('التاريخ والوقت'),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(_selectedDateTime),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDateTime,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                    );
                    if (time != null && mounted) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  prefixIcon: Icon(Icons.note_add),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _addSymptom,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  String _getMeasurementTypeLabel(BloodSugarType type) {
    switch (type) {
      case BloodSugarType.fasting:
        return 'صائم';
      case BloodSugarType.beforeMeal:
        return 'قبل الأكل';
      case BloodSugarType.afterMeal:
        return 'بعد الأكل';
      case BloodSugarType.random:
        return 'عشوائي';
      case BloodSugarType.bedtime:
        return 'قبل النوم';
    }
  }

  String _getSeverityLabel(SymptomSeverity severity) {
    switch (severity) {
      case SymptomSeverity.mild:
        return 'خفيف';
      case SymptomSeverity.moderate:
        return 'متوسط';
      case SymptomSeverity.severe:
        return 'شديد';
    }
  }

  String _getStatusText(double value) {
    if (value < 70) return '🟠 منخفض';
    if (value > 180) return '🔴 مرتفع';
    return '🟢 طبيعي';
  }

  Color _getStatusColor(double value) {
    if (value < 70) return Colors.orange;
    if (value > 180) return Colors.red;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع السكر'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          tabs: const [
            Tab(text: 'القياسات', icon: Icon(Icons.bloodtype)),
            Tab(text: 'الأعراض', icon: Icon(Icons.sick)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildMeasurementsTab(), _buildSymptomsTab()],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMeasurementsTab() {
    if (_measurements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bloodtype, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد قياسات مسجلة',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على زر + لإضافة قياس',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _measurements.length,
      itemBuilder: (context, index) {
        final measurement = _measurements[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(measurement.value).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getBloodSugarIcon(measurement.value),
                color: _getStatusColor(measurement.value),
                size: 28,
              ),
            ),
            title: Text(
              measurement.formattedValue,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${measurement.typeLabel} • ${measurement.formattedTime}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (measurement.notes != null && measurement.notes!.isNotEmpty)
                  Text(
                    '📝 ${measurement.notes}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(measurement.value).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(measurement.value),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(measurement.value),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteMeasurement(measurement.id!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymptomsTab() {
    if (_symptoms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sick, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد أعراض مسجلة',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على زر + لإضافة عرض',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _symptoms.length,
      itemBuilder: (context, index) {
        final symptom = _symptoms[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: symptom.severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _getSymptomIconWidget(symptom.symptomType),
            ),
            title: Text(
              symptom.symptomName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'الشدة: ${symptom.severityLabel}',
                  style: TextStyle(fontSize: 12, color: symptom.severityColor),
                ),
                Text(
                  'الوقت: ${symptom.formattedTime}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (symptom.notes != null && symptom.notes!.isNotEmpty)
                  Text(
                    '📝 ${symptom.notes}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteSymptom(symptom.id!),
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[850]
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'إضافة جديد',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildAddOption(
              icon: Icons.bloodtype,
              title: 'قياس سكر',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showAddMeasurementDialog();
              },
            ),
            _buildAddOption(
              icon: Icons.sick,
              title: 'عرض',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _showAddSymptomDialog();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  IconData _getBloodSugarIcon(double value) {
    if (value < 70) return Icons.warning_amber;
    if (value > 180) return Icons.error;
    return Icons.check_circle;
  }

  Widget _getSymptomIconWidget(String symptomType) {
    switch (symptomType) {
      case 'hypoglycemia':
        return const Icon(Icons.warning, color: Colors.orange, size: 28);
      case 'hyperglycemia':
        return const Icon(Icons.error, color: Colors.red, size: 28);
      default:
        return const Icon(Icons.sick, color: Colors.purple, size: 28);
    }
  }
}
