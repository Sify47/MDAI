import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/health_model.dart';

class AddPressureReading extends StatefulWidget {
  const AddPressureReading({Key? key}) : super(key: key);

  @override
  State<AddPressureReading> createState() => _AddPressureReadingState();
}

class _AddPressureReadingState extends State<AddPressureReading>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedPosition = 'جالس';
  String _selectedArm = 'أيمن';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _positions = ['جالس', 'واقف', 'راقد'];
  final List<String> _arms = ['أيمن', 'أيسر'];

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
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('➕ إضافة قراءة ضغط'),
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
                    // قراءة الضغط
                    _buildPressureFields(),

                    const SizedBox(height: 16),

                    // النبض
                    _buildPulseField(),

                    const SizedBox(height: 16),

                    // وضعية القياس
                    _buildPositionSelector(),

                    const SizedBox(height: 16),

                    // الذراع
                    _buildArmSelector(),

                    const SizedBox(height: 16),

                    // التاريخ والوقت
                    _buildDateTimePicker(),

                    const SizedBox(height: 16),

                    // ملاحظات
                    _buildNotesField(),

                    const SizedBox(height: 16),

                    // تحليل سريع
                    if (_systolicController.text.isNotEmpty &&
                        _diastolicController.text.isNotEmpty)
                      _buildQuickAnalysis(),

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

  Widget _buildPressureFields() {
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
            'قراءة الضغط',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _systolicController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الانقباضي',
                    hintText: 'مثال: 120',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'مطلوب';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('/', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _diastolicController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الانبساطي',
                    hintText: 'مثال: 80',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'مطلوب';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulseField() {
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
            'النبض (اختياري)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pulseController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'مثال: 72',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionSelector() {
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
            'وضعية القياس',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: _positions.map((position) {
              bool isSelected = _selectedPosition == position;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPosition = position;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.danger.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.danger
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        position,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.danger
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
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

  Widget _buildArmSelector() {
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
            'الذراع',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: _arms.map((arm) {
              bool isSelected = _selectedArm == arm;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedArm = arm;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.danger.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.danger
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        arm,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.danger
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
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
              backgroundColor: AppColors.danger.withOpacity(0.1),
              child: Icon(Icons.calendar_today, color: AppColors.danger),
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
              backgroundColor: AppColors.danger.withOpacity(0.1),
              child: Icon(Icons.access_time, color: AppColors.danger),
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
    int systolic = int.parse(_systolicController.text);
    int diastolic = int.parse(_diastolicController.text);

    String status;
    Color color;

    if (systolic < 90 || diastolic < 60) {
      status = 'منخفض';
      color = AppColors.danger;
    } else if (systolic < 120 && diastolic < 80) {
      status = 'طبيعي';
      color = AppColors.success;
    } else if (systolic < 130 && diastolic < 80) {
      status = 'مرتفع طبيعي';
      color = AppColors.success;
    } else if (systolic < 140 || diastolic < 90) {
      status = 'مرتفع قليلاً';
      color = AppColors.warning;
    } else if (systolic < 180 || diastolic < 120) {
      status = 'مرتفع';
      color = AppColors.danger;
    } else {
      status = 'مرتفع جداً';
      color = AppColors.danger;
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
                  _getAnalysisMessage(status),
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAnalysisMessage(String status) {
    switch (status) {
      case 'طبيعي':
        return 'ممتاز! استمر في الحفاظ على نمط حياتك الصحي.';
      case 'مرتفع':
        return 'ننصح بمراجعة طبيبك وتجنب الملح.';
      case 'منخفض':
        return 'اشرب كمية كافية من الماء واستشر طبيبك.';
      default:
        return 'راقب قراءاتك بانتظام.';
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
                final reading = PressureReading(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  systolic: int.parse(_systolicController.text),
                  diastolic: int.parse(_diastolicController.text),
                  pulse: _pulseController.text.isNotEmpty
                      ? int.parse(_pulseController.text)
                      : null,
                  position: _selectedPosition,
                  arm: _selectedArm,
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
                );

                Navigator.pop(context, reading);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
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
