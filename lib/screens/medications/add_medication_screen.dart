import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/medicine_model.dart';
import '../../services/medication_api.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({Key? key}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _notesController = TextEditingController();

  // Variables
  int _timesPerDay = 2;
  List<TimeOfDay> _selectedTimes = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 20, minute: 0),
  ];
  bool _withFood = true;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // البحث عن الأدوية
  List<Medicine> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  // الدواء المختار
  Medicine? _selectedMedicine;

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
    _notesController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isSearching = true);

    final results = await MedicationService.searchMedicines(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectMedicine(Medicine medicine) {
    if (!mounted) return;

    setState(() {
      _selectedMedicine = medicine;
      _searchResults = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم اختيار ${medicine.nameAr}'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        appBar: AppBar(title: Text('➕ إضافة دواء جديد')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FadeTransition(
              opacity: _controller,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchField(theme),
                    const SizedBox(height: 16),
                    if (_selectedMedicine != null)
                      _buildSelectedMedicineCard(theme),
                    if (_selectedMedicine != null) const SizedBox(height: 16),
                    _buildTimesPerDay(theme),
                    const SizedBox(height: 16),
                    _buildTimesSelector(theme),
                    const SizedBox(height: 16),
                    _buildWithFoodOption(theme),
                    const SizedBox(height: 16),
                    _buildDatePickers(theme),
                    const SizedBox(height: 16),
                    _buildNotesField(theme),
                    const SizedBox(height: 32),
                    _buildSaveButton(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
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
            '🔍 البحث عن دواء في قاعدة البيانات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'اكتب اسم الدواء...',
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            style: theme.textTheme.bodyMedium,
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'نتائج البحث:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._searchResults.map(
              (medicine) => ListTile(
                onTap: () => _selectMedicine(medicine),
                leading: medicine.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          medicine.imageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.medications.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Text('💊')),
                      ),
                title: Text(medicine.nameAr),
                subtitle: Text(
                  medicine.genericName ?? medicine.category ?? '',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: const Icon(
                  Icons.add_circle,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedMedicineCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.medications.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.medications.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.medications.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('💊', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedMedicine!.nameAr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedMedicine!.genericName != null)
                  Text(
                    _selectedMedicine!.genericName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                if (_selectedMedicine!.category != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedMedicine!.category!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.danger),
            onPressed: () {
              setState(() {
                _selectedMedicine = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimesPerDay(ThemeData theme) {
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
            'عدد مرات التناول',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTimesOption(1, 'مرة واحدة', theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildTimesOption(2, 'مرتين', theme)),
              const SizedBox(width: 8),
              Expanded(child: _buildTimesOption(3, 'ثلاث مرات', theme)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimesOption(int value, String label, ThemeData theme) {
    bool isSelected = _timesPerDay == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _timesPerDay = value;
          _selectedTimes = List.generate(value, (index) {
            return TimeOfDay(hour: 8 + (index * 6), minute: 0);
          });
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.medications.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.medications
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.medications
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? AppColors.medications
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesSelector(ThemeData theme) {
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
            'أوقات التناول',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_timesPerDay, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'الجرعة ${index + 1}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTimes[index],
                      );
                      if (time != null && mounted) {
                        setState(() {
                          _selectedTimes[index] = time;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.medications.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _timeOfDayToString(_selectedTimes[index]),
                        style: TextStyle(
                          color: AppColors.medications,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWithFoodOption(ThemeData theme) {
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              'طريقة التناول',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              _buildFoodOption(true, 'مع الأكل', AppColors.success, theme),
              const SizedBox(width: 12),
              _buildFoodOption(false, 'قبل الأكل', AppColors.warning, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodOption(
    bool value,
    String label,
    Color color,
    ThemeData theme,
  ) {
    bool isSelected = _withFood == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _withFood = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? color
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickers(ThemeData theme) {
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
              backgroundColor: AppColors.medications.withOpacity(0.1),
              child: Icon(Icons.calendar_today, color: AppColors.medications),
            ),
            title: Text('تاريخ البدء', style: theme.textTheme.bodyMedium),
            subtitle: Text(
              '${_startDate.year}/${_startDate.month}/${_startDate.day}',
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
                initialDate: _startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (date != null && mounted) {
                setState(() {
                  _startDate = date;
                });
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.medications.withOpacity(0.1),
              child: Icon(Icons.calendar_today, color: AppColors.medications),
            ),
            title: Text(
              'تاريخ الانتهاء (اختياري)',
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Text(
              _endDate == null
                  ? 'غير محدد'
                  : '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_endDate != null)
                  IconButton(
                    icon: Icon(Icons.clear, color: AppColors.danger),
                    onPressed: () {
                      setState(() {
                        _endDate = null;
                      });
                    },
                  ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate:
                    _endDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: _startDate,
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (date != null && mounted) {
                setState(() {
                  _endDate = date;
                });
              }
            },
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
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'ملاحظات إضافية',
          hintText: 'أضف أي ملاحظات عن الدواء...',
          border: InputBorder.none,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          if (_selectedMedicine == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ الرجاء اختيار دواء من نتائج البحث'),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          List<String> timesStrings = _selectedTimes
              .map((time) => _timeOfDayToString(time))
              .toList();

          final newMedication = {
            'medicine_id': _selectedMedicine!.id,
            'times_per_day': _timesPerDay,
            'times': timesStrings,
            'with_food': _withFood,
            'start_date': _startDate.toIso8601String().split('T')[0],
            'end_date': _endDate?.toIso8601String().split('T')[0],
            'notes': _notesController.text.isNotEmpty
                ? _notesController.text
                : null,
          };

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );
          }

          final savedMedication = await MedicationService.addMedication(
            newMedication,
          );

          if (mounted) Navigator.pop(context);

          if (savedMedication != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✅ تم إضافة الدواء بنجاح'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context, savedMedication);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('❌ فشل في إضافة الدواء'),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.medications,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Text(
        '💾 حفظ الدواء',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
