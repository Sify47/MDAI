// lib/screens/profile/personal_info_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../../constants/colors.dart';
import '../../models/user_model.dart';
import '../../utils/prefs_helper.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  User? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late DateTime _selectedDate;
  late String _selectedGender;

  final List<String> _genders = ['ذكر', 'أنثى'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _selectedDate = DateTime.now().subtract(const Duration(days: 365 * 30));
    _selectedGender = 'ذكر';
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await PrefsHelper.getUser();
      if (user != null) {
        setState(() {
          _user = user;
          if (user.birthDate != null) {
            _selectedDate = user.birthDate!;
          }
          _nameController.text = user.name;
          _emailController.text = user.email;
          _phoneController.text = user.phone ?? '';
          _selectedGender = user.gender ?? 'ذكر';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updatedUser = User(
          id: _user!.id,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          birthDate: _selectedDate,
          gender: _selectedGender,
        );

        await PrefsHelper.saveUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: const Text('تم تحديث المعلومات الشخصية بنجاح'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _isEditing = false;
            _user = updatedUser;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('خطأ في حفظ البيانات: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'SA'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المعلومات الشخصية'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'حفظ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? _buildEmptyState()
          : AnimationLimiter(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileImage(theme),
                    const SizedBox(height: 24),
                    _buildInfoCard(theme),
                  ],
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
          Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('لا توجد بيانات'),
        ],
      ),
    );
  }

  Widget _buildProfileImage(ThemeData theme) {
    return AnimationConfiguration.staggeredList(
      position: 0,
      child: SlideAnimation(
        child: FadeInAnimation(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, AppColors.success],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'م',
                style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
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
                icon: Icons.person_outline,
                label: 'الاسم الكامل',
                controller: _nameController,
                readOnly: !_isEditing,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الاسم مطلوب' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                theme,
                icon: Icons.email_outlined,
                label: 'البريد الإلكتروني',
                controller: _emailController,
                readOnly: !_isEditing,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'البريد الإلكتروني مطلوب';
                  if (!value!.contains('@')) return 'بريد إلكتروني غير صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                theme,
                icon: Icons.phone_outlined,
                label: 'رقم الهاتف',
                controller: _phoneController,
                readOnly: !_isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildDateField(theme),
              const SizedBox(height: 16),
              _buildGenderField(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool readOnly,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField(ThemeData theme) {
    // ✅ استخدام تنسيق التاريخ بدون Locale
    final String formattedDate =
        '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: _isEditing ? () => _selectDate(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'تاريخ الميلاد',
          prefixIcon: Icon(
            Icons.cake_outlined,
            color: theme.colorScheme.primary,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          formattedDate, // ✅ استخدام التنسيق المباشر بدلاً من DateFormat
          style: TextStyle(
            color: _isEditing ? theme.colorScheme.onSurface : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      isExpanded: true,
      isDense: true,
      items: _genders.map((gender) {
        return DropdownMenuItem<String>(value: gender, child: Text(gender));
      }).toList(),
      onChanged: _isEditing
          ? (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedGender = newValue;
                });
              }
            }
          : null,
      decoration: InputDecoration(
        labelText: 'الجنس',
        prefixIcon: Icon(
          Icons.person_outline,
          color: theme.colorScheme.primary,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
