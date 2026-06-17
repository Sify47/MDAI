import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/health_model.dart';

class AddSugarReading extends StatefulWidget {
  const AddSugarReading({Key? key}) : super(key: key);

  @override
  State<AddSugarReading> createState() => _AddSugarReadingState();
}

class _AddSugarReadingState extends State<AddSugarReading>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _mealController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedType = 'صائم';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _carbs;

  final List<String> _readingTypes = ['صائم', 'فاطر', 'عشوائي', 'قبل النوم'];

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
    _valueController.dispose();
    _mealController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('➕ إضافة قراءة سكر'),
        ),
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
                    // قيمة السكر
                    _buildValueField(),

                    const SizedBox(height: 16),

                    // نوع القراءة
                    _buildTypeSelector(),

                    const SizedBox(height: 16),

                    // وصف الوجبة (يظهر فقط للفاطر)
                    if (_selectedType == 'فاطر') _buildMealField(),

                    const SizedBox(height: 16),

                    // التاريخ والوقت
                    _buildDateTimePicker(),

                    const SizedBox(height: 16),

                    // ملاحظات
                    _buildNotesField(),

                    const SizedBox(height: 16),

                    // تحليل سريع
                    if (_valueController.text.isNotEmpty) _buildQuickAnalysis(),

                    const SizedBox(height: 32),

                    // أزرار الحفظ
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'قراءة السكر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'أدخل القيمة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.calories),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال القيمة';
                    }
                    if (double.tryParse(value) == null) {
                      return 'قيمة غير صالحة';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'mg/dL',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نوع القراءة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _readingTypes.map((type) {
              bool isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.calories.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.calories
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.calories
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMealField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'وصف الوجبة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mealController,
            decoration: InputDecoration(
              hintText: 'مثال: غداء - أرز ودجاج',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              backgroundColor: AppColors.calories.withOpacity(0.1),
              child: Icon(Icons.calendar_today, color: AppColors.calories),
            ),
            title: const Text('التاريخ'),
            subtitle: Text(
              '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.calories.withOpacity(0.1),
              child: Icon(Icons.access_time, color: AppColors.calories),
            ),
            title: const Text('الوقت'),
            subtitle: Text('${_selectedTime.hour}:${_selectedTime.minute}'),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
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

  Widget _buildNotesField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
          hintText: 'أضف أي ملاحظات...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildQuickAnalysis() {
    double value = double.parse(_valueController.text);
    String status;
    Color color;

    if (_selectedType == 'صائم') {
      if (value < 70) {
        status = 'منخفض';
        color = AppColors.danger;
      } else if (value > 100) {
        status = 'مرتفع';
        color = AppColors.danger;
      } else {
        status = 'طبيعي';
        color = AppColors.success;
      }
    } else if (_selectedType == 'فاطر') {
      if (value < 140) {
        status = 'طبيعي';
        color = AppColors.success;
      } else if (value < 180) {
        status = 'مرتفع قليلاً';
        color = AppColors.warning;
      } else {
        status = 'مرتفع';
        color = AppColors.danger;
      }
    } else {
      if (value < 140) {
        status = 'طبيعي';
        color = AppColors.success;
      } else if (value < 200) {
        status = 'مرتفع قليلاً';
        color = AppColors.warning;
      } else {
        status = 'مرتفع';
        color = AppColors.danger;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            status == 'طبيعي' ? Icons.check_circle : Icons.warning,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القراءة $status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getAnalysisMessage(status, _selectedType),
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAnalysisMessage(String status, String type) {
    if (status == 'طبيعي') {
      return 'ممتاز! استمر في الحفاظ على نمط حياتك الصحي.';
    } else if (status == 'مرتفع') {
      return 'ننصح بمراجعة طبيبك وتجنب السكريات.';
    } else if (status == 'منخفض') {
      return 'تناول مصدر سكر سريع وراجع طبيبك.';
    } else {
      return 'راقب قراءاتك وتجنب الأطعمة عالية السكر.';
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.textSecondary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // إنشاء قراءة جديدة
                final reading = SugarReading(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  value: double.parse(_valueController.text),
                  type: _selectedType,
                  dateTime: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  ),
                  notes: _notesController.text.isNotEmpty
                      ? _notesController.text
                      : null,
                  mealDescription: _mealController.text.isNotEmpty
                      ? _mealController.text
                      : null,
                );

                Navigator.pop(context, reading);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.calories,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'حفظ القراءة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
