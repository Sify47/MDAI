// lib/screens/initial_setup.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../constants/colors.dart';
import '../utils/prefs_helper.dart';
import '../utils/nutrition_calculator.dart';
import '../services/nutrition_api.dart';
import '../models/user_model.dart';
import 'quiz/onboarding_quiz.dart';

class InitialSetup extends StatefulWidget {
  const InitialSetup({super.key});

  @override
  State<InitialSetup> createState() => _InitialSetupState();
}

class _InitialSetupState extends State<InitialSetup>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  int _currentPage = 0;
  final int _totalPages = 3;

  User? _currentUser;
  int _userAge = 30;
  String _userGender = 'ذكر';

  // ✅ الصفحة 1: المعلومات الأساسية + الهدف
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  String _selectedGoal = 'تخسيس';
  String _selectedActivityLevel = 'متوسط';

  // ✅ الصفحة 2: المدة والمعدل الأسبوعي
  int _selectedMonths = 3;
  double _weeklyRate = 0.5;
  String _goalError = '';

  // الصفحة 3: الأمراض
  final List<String> _selectedDiseases = [];

  final List<Map<String, dynamic>> _diseases = [
    {'name': 'السكري', 'icon': '🩸', 'color': AppColors.calories},
    {'name': 'ضغط الدم', 'icon': '💓', 'color': AppColors.danger},
    {'name': 'الكوليسترول', 'icon': '🧪', 'color': AppColors.warning},
    {'name': 'القلب', 'icon': '❤️', 'color': AppColors.danger},
    {'name': 'الربو', 'icon': '🌬️', 'color': AppColors.primary},
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    _targetWeightController.addListener(_validateGoal);
    _weightController.addListener(_validateGoal);
  }

  void _validateGoal() {
    setState(() {
      _goalError = '';
    });

    double currentWeight = double.tryParse(_weightController.text) ?? 0;
    double targetWeight = double.tryParse(_targetWeightController.text) ?? 0;

    if (currentWeight > 0 && targetWeight > 0) {
      if (_selectedGoal == 'تخسيس' && targetWeight >= currentWeight) {
        setState(() {
          _goalError =
              '⚠️ في تخسيس، الوزن المستهدف يجب أن يكون أقل من الوزن الحالي';
        });
      } else if (_selectedGoal == 'زيادة' && targetWeight <= currentWeight) {
        setState(() {
          _goalError =
              '⚠️ في زيادة الوزن، الوزن المستهدف يجب أن يكون أكبر من الوزن الحالي';
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    final user = await PrefsHelper.getUser();
    if (user != null && mounted) {
      setState(() {
        _currentUser = user;
        _userGender = user.gender;

        final today = DateTime.now();
        final birthDate = user.birthDate;
        _userAge = today.year - birthDate.year;
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          _userAge--;
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      double currentWeight = double.tryParse(_weightController.text) ?? 0;
      double height = double.tryParse(_heightController.text) ?? 0;
      double targetWeight = double.tryParse(_targetWeightController.text) ?? 0;

      if (currentWeight <= 0) {
        _showError('الرجاء إدخال الوزن الحالي');
        return;
      }
      if (height <= 0) {
        _showError('الرجاء إدخال الطول');
        return;
      }
      if (targetWeight <= 0) {
        _showError('الرجاء إدخال الوزن المستهدف');
        return;
      }
      if (_goalError.isNotEmpty) {
        _showError(_goalError);
        return;
      }
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _completeSetup() async {
    double weight = double.tryParse(_weightController.text) ?? 0;
    double height = double.tryParse(_heightController.text) ?? 0;
    double targetWeight = double.tryParse(_targetWeightController.text) ?? 0;

    setState(() => _isSaving = true);

    try {
      int targetWeeks = _selectedMonths * 4;
      double weightDifference = (weight - targetWeight).abs();
      double calculatedRate = weightDifference / targetWeeks;
      double finalRate = _weeklyRate > 0 ? _weeklyRate : calculatedRate;
      finalRate = finalRate.clamp(0.3, 1.5);

      double bmr = NutritionCalculator.calculateBMR(
        weight: weight,
        height: height,
        age: _userAge,
        gender: _userGender,
      );

      double tdee = NutritionCalculator.calculateTDEE(
        bmr: bmr,
        activityLevel: _selectedActivityLevel,
      );

      double targetCalories = NutritionCalculator.calculateTargetCalories(
        tdee: tdee,
        goal: _selectedGoal,
        weightLossRate: finalRate.toString(),
      );

      Map<String, dynamic> userData = {
        'user_id': _currentUser?.id ?? PrefsHelper.getUserId() ?? 1,
        'weight': weight,
        'height': height,
        'age': _userAge,
        'gender': _userGender,
        'goal': _selectedGoal,
        'activity_level': _selectedActivityLevel,
        'weight_loss_rate': finalRate,
        'target_weight': targetWeight,
        'diseases': _selectedDiseases,
        'initial_weight': weight,
        'target_weeks': targetWeeks,
      };

      await PrefsHelper.saveUserData({
        ...userData,
        'targetCalories': targetCalories,
        'bmr': bmr,
        'tdee': tdee,
      });

      await NutritionService.saveUserNutritionData(userData);
      await PrefsHelper.setFirstTimeUser(false);

      if (!mounted) return;

      // ✅ الانتقال إلى الكويز بدلاً من الشاشة الرئيسية مباشرة
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingQuiz(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildProgressBar(isDark),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicInfoPage(isDark),
                        _buildGoalSettingsPage(isDark),
                        _buildMedicalInfoPage(isDark),
                      ],
                    ),
                  ),
                  _buildNavigationButtons(isDark),
                ],
              ),
              if (_isSaving)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'جاري حفظ البيانات...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // شريط التقدم
  // ============================================
  Widget _buildProgressBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'الإعداد الأولي',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1}/$_totalPages',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // الصفحة الأولى: المعلومات الأساسية + الهدف
  // ============================================
  Widget _buildBasicInfoPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الترحيب
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.success],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً ${_currentUser?.name ?? "مستخدم"}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'العمر: $_userAge سنة • الجنس: $_userGender',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ✅ اختيار الهدف (جديد)
          _buildSectionHeader('🎯 هدفك', 'ماذا تريد أن تحقق؟'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildGoalCard(
                  emoji: '⚖️',
                  title: 'تخسيس',
                  description: 'إنقاص الوزن',
                  isSelected: _selectedGoal == 'تخسيس',
                  onTap: () => setState(() {
                    _selectedGoal = 'تخسيس';
                    _validateGoal();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGoalCard(
                  emoji: '🎯',
                  title: 'تثبيت',
                  description: 'المحافظة على الوزن',
                  isSelected: _selectedGoal == 'تثبيت',
                  onTap: () => setState(() {
                    _selectedGoal = 'تثبيت';
                    _validateGoal();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGoalCard(
                  emoji: '💪',
                  title: 'زيادة',
                  description: 'زيادة الكتلة العضلية',
                  isSelected: _selectedGoal == 'زيادة',
                  onTap: () => setState(() {
                    _selectedGoal = 'زيادة';
                    _validateGoal();
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // معلومات الجسم
          _buildSectionHeader('⚖️ معلومات جسمك', 'أدخل قياساتك الحالية'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSimpleInputCard(
                  title: 'الوزن الحالي',
                  controller: _weightController,
                  hint: 'مثال: 70',
                  unit: 'كجم',
                  icon: Icons.monitor_weight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleInputCard(
                  title: 'الطول',
                  controller: _heightController,
                  hint: 'مثال: 170',
                  unit: 'سم',
                  icon: Icons.height,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildSimpleInputCard(
            title: 'الوزن المستهدف',
            controller: _targetWeightController,
            hint: 'مثال: 65',
            unit: 'كجم',
            icon: Icons.flag,
          ),

          // رسالة خطأ الهدف
          if (_goalError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_goalError)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // مستوى النشاط
          _buildSectionHeader('🏃 مستوى نشاطك', 'اختر ما يناسب يومك'),
          const SizedBox(height: 12),

          _buildActivityCard(
            value: 'قليل',
            emoji: '🪑',
            title: 'قليل الحركة',
            description: 'عمل مكتبي، قلة حركة',
          ),
          const SizedBox(height: 8),
          _buildActivityCard(
            value: 'متوسط',
            emoji: '🚶',
            title: 'نشاط متوسط',
            description: 'مشي خفيف، رياضة 1-2 مرات أسبوعياً',
          ),
          const SizedBox(height: 8),
          _buildActivityCard(
            value: 'عالي',
            emoji: '🏃',
            title: 'نشاط عالي',
            description: 'عمل حركي، رياضة 3-5 مرات أسبوعياً',
          ),
          const SizedBox(height: 8),
          _buildActivityCard(
            value: 'مكثف',
            emoji: '⚡',
            title: 'نشاط مكثف',
            description: 'رياضة يومية، عمل بدني شاق',
          ),
        ],
      ),
    );
  }

  // ============================================
  // الصفحة الثانية: المدة والمعدل الأسبوعي
  // ============================================
  Widget _buildGoalSettingsPage(bool isDark) {
    double currentWeight = double.tryParse(_weightController.text) ?? 0;
    double targetWeight = double.tryParse(_targetWeightController.text) ?? 0;
    double weightDifference = (currentWeight - targetWeight).abs();
    int targetWeeks = _selectedMonths * 4;
    double suggestedRate = weightDifference / targetWeeks;

    double minRate = 0.3;
    double maxRate = 1.5;
    double displayRate = _weeklyRate > 0
        ? _weeklyRate
        : suggestedRate.clamp(minRate, maxRate);

    int calculatedWeeks = (weightDifference / displayRate).ceil();
    int calculatedMonths = (calculatedWeeks / 4).ceil();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('📅 المدة المستهدفة', 'كم شهر تريد لتحقيق هدفك؟'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المدة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_selectedMonths شهر',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _selectedMonths.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  activeColor: AppColors.primary,
                  label: '$_selectedMonths شهر',
                  onChanged: (value) {
                    setState(() {
                      _selectedMonths = value.round();
                      double newSuggestedRate =
                          weightDifference / (_selectedMonths * 4);
                      if (newSuggestedRate >= minRate &&
                          newSuggestedRate <= maxRate) {
                        _weeklyRate = newSuggestedRate;
                      }
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('شهر', style: TextStyle(fontSize: 12)),
                    Text('3 شهور', style: TextStyle(fontSize: 12)),
                    Text('6 شهور', style: TextStyle(fontSize: 12)),
                    Text('12 شهر', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionHeader('⚡ المعدل الأسبوعي', 'اختر السرعة المناسبة لك'),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المعدل المطلوب',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${displayRate.toStringAsFixed(1)} كجم/أسبوع',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Slider(
                  value: displayRate,
                  min: minRate,
                  max: maxRate,
                  divisions: 12,
                  activeColor: AppColors.primary,
                  label: '${displayRate.toStringAsFixed(1)} كجم/أسبوع',
                  onChanged: (value) {
                    setState(() {
                      _weeklyRate = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$minRate كجم', style: TextStyle(fontSize: 12)),
                    Text('0.8 كجم', style: TextStyle(fontSize: 12)),
                    Text('$maxRate كجم', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.info),
                    const SizedBox(width: 12),
                    const Text(
                      'معلومات مهمة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• المعدل الصحي الآمن هو 0.5-1 كجم في الأسبوع',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '• بناءً على هدفك، المدة المتبقية المتوقعة: $calculatedMonths شهر ($calculatedWeeks أسبوع)',
                  style: TextStyle(fontSize: 12),
                ),
                if (displayRate > 1.0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '⚠️ ملاحظة: المعدل ${displayRate.toStringAsFixed(1)} كجم/أسبوع سريع جداً، قد يكون صعب الالتزام',
                      style: TextStyle(fontSize: 11, color: AppColors.warning),
                    ),
                  ),
                if (displayRate < 0.5 && displayRate > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '💡 المعدل ${displayRate.toStringAsFixed(1)} كجم/أسبوع بطيء جداً، يمكنك زيادته قليلاً',
                      style: TextStyle(fontSize: 11, color: AppColors.info),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // الصفحة الثالثة: المعلومات الطبية
  // ============================================
  Widget _buildMedicalInfoPage(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '🩺 حالتك الصحية',
            'أخبرنا عن حالتك الصحية (اختياري)',
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _diseases.map((disease) {
                final isSelected = _selectedDiseases.contains(disease['name']);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(disease['icon']),
                      const SizedBox(width: 6),
                      Text(disease['name']),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDiseases.add(disease['name']);
                      } else {
                        _selectedDiseases.remove(disease['name']);
                      }
                    });
                  },
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[100],
                  selectedColor: disease['color'].withOpacity(0.2),
                  checkmarkColor: disease['color'],
                  labelStyle: TextStyle(
                    color: isSelected ? disease['color'] : null,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.shield, color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'معلوماتك آمنة ومشفرة، تستخدم فقط لتخصيص التوصيات الغذائية',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // أزرار التنقل
  // ============================================
  Widget _buildNavigationButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('السابق'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentPage == 0 ? 2 : 1,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentPage == _totalPages - 1 ? '✨ إكمال' : 'التالي',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // واجهات مساعدة
  // ============================================

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildGoalCard({
    required String emoji,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInputCard({
    required String title,
    required TextEditingController controller,
    required String hint,
    required String unit,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[700] : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String value,
    required String emoji,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedActivityLevel == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedActivityLevel = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
