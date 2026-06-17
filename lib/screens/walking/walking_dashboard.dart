// lib/screens/walking/walking_dashboard.dart

import 'package:flutter/material.dart';
import 'package:vita/models/nutrition_model.dart';
import 'package:vita/models/walking_model.dart';
import 'package:vita/screens/walking/add_walking_activity.dart';
import 'package:vita/screens/walking/walking_simulation_screen.dart';
import 'package:vita/screens/walking/walking_challenges.dart';
import 'package:vita/screens/walking/walking_statistics.dart';
import 'package:vita/services/walking_api.dart';
import 'package:vita/services/medication_api.dart';
import 'package:vita/services/symptom_api.dart';
import 'package:vita/models/medication_model.dart';
import 'package:vita/models/symptom_model.dart';
import 'package:vita/utils/nutrition_calculator.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../constants/colors.dart';
import '../../utils/prefs_helper.dart';

class WalkingDashboard extends StatefulWidget {
  final UserNutritionData userData;

  const WalkingDashboard({Key? key, required this.userData}) : super(key: key);

  @override
  State<WalkingDashboard> createState() => _WalkingDashboardState();
}

class _WalkingDashboardState extends State<WalkingDashboard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  int _currentSteps = 0;
  int _baseGoal = 8000;
  int _adjustedGoal = 8000;
  int _caloriesBurned = 0;
  double _distanceKm = 0.0;
  int _durationMin = 0;
  bool _isLoading = true;
  String? _errorMessage;

  String _impactMessage = '';
  List<Symptom> _activeSymptoms = [];
  List<UserMedication> _userMedications = [];
  final userData = PrefsHelper.getUserData();

  // 📊 Statistics state
  String _selectedPeriod = 'week'; // week, month, year
  List<WalkingActivity> _activities = [];
  WalkingStats? _stats;

  // 🏃 بيانات أنواع الأنشطة
  static const Map<String, Map<String, dynamic>> _activityData = {
    'walking': {
      'icon': Icons.directions_walk,
      'label': 'مشي',
      'emoji': '🚶',
      'color': Color(0xFF4A90D9),
    },
    'running': {
      'icon': Icons.directions_run,
      'label': 'جري',
      'emoji': '🏃',
      'color': Color(0xFFE53935),
    },
    'cycling': {
      'icon': Icons.directions_bike,
      'label': 'دراجة',
      'emoji': '🚴',
      'color': Color(0xFFFB8C00),
    },
    'swimming': {
      'icon': Icons.pool,
      'label': 'سباحة',
      'emoji': '🏊',
      'color': Color(0xFF00ACC1),
    },
    'strength': {
      'icon': Icons.fitness_center,
      'label': 'تمارين قوة',
      'emoji': '🏋️',
      'color': Color(0xFF8E24AA),
    },
    'yoga': {
      'icon': Icons.self_improvement,
      'label': 'يوجا',
      'emoji': '🧘',
      'color': Color(0xFF7CB342),
    },
  };

  // 🔥 حساب السعرات حسب نوع النشاط (MET-based لجميع الأنشطة)
  int _calculateActivityCalories(WalkingActivity activity, double weight) {
    // 🟢 استخدام MET values لجميع الأنشطة بشكل موحد (توحيداً مع add_walking_activity.dart)
    if (activity.durationMinutes > 0) {
      return NutritionCalculator.calculateActivityCalories(
        weight: weight,
        durationMinutes: activity.durationMinutes,
        activityType: activity.activityType,
      );
    }
    // fallback: إذا كانت المدة 0، استخدم الصيغة المبسطة من الخطوات كحل احتياطي
    if (activity.steps > 0) {
      return NutritionCalculator.calculateWalkingCalories(
        weight: weight,
        steps: activity.steps,
      );
    }
    return 0;
  }

  // 🎨 لون النشاط
  Color _getActivityColor(String type) {
    return _activityData[type]?['color'] as Color? ?? AppColors.walking;
  }

  // 🔤 اسم النشاط
  String _getActivityLabel(String type) {
    return _activityData[type]?['label'] as String? ?? 'مشي';
  }

  // ℹ️ إيموجي النشاط
  String _getActivityEmoji(String type) {
    return _activityData[type]?['emoji'] as String? ?? '🚶';
  }

  // ℹ️ أيقونة النشاط
  IconData _getActivityIcon(String type) {
    return _activityData[type]?['icon'] as IconData? ?? Icons.directions_walk;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
    _progressController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    _loadUserGoal();
    await _loadTodayStats();
    await _loadStatisticsData();
    await _loadActiveSymptoms();
    await _loadUserMedications();

    await _calculateImpactFromAPI();
    await _calculateAdjustedGoal();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatisticsData() async {
    try {
      final results = await Future.wait([
        WalkingService.getAllActivities(),
        WalkingService.getWalkingStats(),
      ]);

      if (!mounted) return;

      final activities = results[0] as List<WalkingActivity>;
      final stats = results[1] as WalkingStats?;

      setState(() {
        _activities = activities;
        _stats = stats;
      });
    } catch (e) {
      print('❌ خطأ في تحميل إحصائيات المشي: $e');
    }
  }

  Future<void> _calculateImpactFromAPI() async {
    try {
      final impactData = await WalkingService.calculateWalkingImpact();

      if (impactData['success'] == true) {
        _baseGoal = impactData['base_goal'];
        _adjustedGoal = impactData['adjusted_goal'];

        if (impactData['impact_details'] != null &&
            impactData['impact_details'].isNotEmpty) {
          List<String> impactMessages = [];
          for (var detail in impactData['impact_details']) {
            if (detail['impact'] < 0) {
              impactMessages.add(
                '⚠️ ${detail['name']}: -${detail['impact'].abs()}%',
              );
            } else if (detail['impact'] > 0) {
              impactMessages.add('✅ ${detail['name']}: +${detail['impact']}%');
            }
          }

          if (impactMessages.isNotEmpty) {
            setState(() {
              _impactMessage = impactMessages.take(2).join(' • ');
              if (impactMessages.length > 2) {
                _impactMessage +=
                    ' • و ${impactMessages.length - 2} عوامل أخرى';
              }
            });
          }
        }
      }
    } catch (e) {
      print('❌ خطأ في حساب التأثير من API: $e');
    }
  }

  void _loadUserGoal() {
    setState(() {
      _baseGoal = (userData['dailyStepsGoal'] as int?) ?? 8000;
      _adjustedGoal = _baseGoal;
    });
  }

  Future<void> _loadActiveSymptoms() async {
    try {
      final symptoms = await SymptomService.getSymptoms(limit: 20);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      if (mounted) {
        setState(() {
          _activeSymptoms = symptoms
              .where((s) => s.dateTime.isAfter(sevenDaysAgo))
              .toList();
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل الأعراض: $e');
    }
  }

  Future<void> _loadUserMedications() async {
    try {
      final medications = await MedicationService.getMedications();
      if (mounted) {
        setState(() {
          _userMedications = medications;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل الأدوية: $e');
    }
  }

  Future<void> _calculateAdjustedGoal() async {
    double totalImpact = 0;
    List<String> impactReasons = [];

    for (var disease in widget.userData.diseases) {
      final impact = await _getDiseaseImpact(disease);
      totalImpact += impact['impact'];
      if (impact['impact'] != 0) {
        impactReasons.add(
          '${impact['reason']} (${impact['impact'] > 0 ? "+${impact['impact']}" : impact['impact']}%)',
        );
      }
    }

    for (var symptom in _activeSymptoms) {
      final impact = await _getSymptomImpact(symptom.name, symptom.severity);
      totalImpact += impact['impact'];
      if (impact['impact'] != 0) {
        impactReasons.add(
          '${symptom.name} (${impact['impact'] > 0 ? "+${impact['impact']}" : impact['impact']}%)',
        );
      }
    }

    for (var med in _userMedications) {
      final impact = await _getMedicineImpact(med.medicineId ?? 0);
      totalImpact += impact['impact'];
      if (impact['impact'] != 0) {
        impactReasons.add(
          '${med.name} (${impact['impact'] > 0 ? "+${impact['impact']}" : impact['impact']}%)',
        );
      }
    }

    int newGoal = (_baseGoal * (1 + totalImpact / 100)).round();
    _adjustedGoal = newGoal.clamp(3000, 15000);

    if (mounted) {
      setState(() {
        _impactMessage = impactReasons.isNotEmpty
            ? 'تم تعديل الهدف بسبب: ${impactReasons.take(2).join(", ")}${impactReasons.length > 2 ? " وغيرها" : ""}'
            : '';
      });
    }
  }

  Future<Map<String, dynamic>> _getDiseaseImpact(String disease) async {
    final impacts = {
      'السكري': {'impact': 10, 'reason': 'مرضى السكري يحتاجون حركة أكثر'},
      'ضغط الدم': {'impact': 5, 'reason': 'المشي مفيد لمرضى الضغط'},
      'القلب': {'impact': -20, 'reason': 'مرضى القلب يحتاجون مشي معتدل'},
      'الكوليسترول': {'impact': 15, 'reason': 'المشي يساعد في خفض الكوليسترول'},
      'الربو': {'impact': -10, 'reason': 'الربو قد يحد من النشاط'},
      'الروماتيزم': {'impact': -30, 'reason': 'آلام المفاصل تحد من النشاط'},
      'الأنيميا': {'impact': -40, 'reason': 'الأنيميا تسبب تعباً وإرهاقاً'},
    };
    final impact = impacts[disease] ?? {'impact': 0, 'reason': ''};
    return {'impact': impact['impact'], 'reason': impact['reason']};
  }

  Future<Map<String, dynamic>> _getSymptomImpact(
    String symptomName,
    String severity,
  ) async {
    final impacts = {
      'صداع': {'خفيف': -20, 'متوسط': -40, 'شديد': -70},
      'دوخة': {'كل': -50},
      'ألم صدر': {'كل': -90},
      'ضيق تنفس': {'كل': -80},
      'حمى': {'كل': -60},
      'تعب وإرهاق': {'خفيف': -40, 'متوسط': -60, 'شديد': -80},
      'غثيان': {'كل': -30},
      'ألم بطن': {'كل': -40},
      'إسهال': {'كل': -50},
      'إمساك': {'كل': -20},
      'زغللة العين': {'كل': -70},
      'تنميل الأطراف': {'كل': -50},
      'آلام العضلات': {'خفيف': -30, 'متوسط': -50, 'شديد': -70},
    };

    var symptomImpacts = impacts[symptomName];
    if (symptomImpacts == null) return {'impact': 0};

    int impact;
    if (symptomImpacts.containsKey(severity)) {
      impact = symptomImpacts[severity]!;
    } else {
      impact = symptomImpacts['كل'] ?? 0;
    }
    return {'impact': impact};
  }

  Future<Map<String, dynamic>> _getMedicineImpact(int medicineId) async {
    final impacts = {
      1: {'impact': 5, 'name': 'جلوكوفاج'},
      8: {'impact': -20, 'name': 'كونكور'},
      5: {'impact': -10, 'name': 'فولتارين'},
      6: {'impact': 10, 'name': 'أوميغا 3'},
      4: {'impact': 5, 'name': 'باراسيتامول'},
    };
    final impact = impacts[medicineId] ?? {'impact': 0, 'name': ''};
    return {'impact': impact['impact']};
  }

  Future<void> _loadTodayStats() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ forceRefresh: true لضمان جلب أحدث البيانات من API وتجاوز الكاش
      final activities = await WalkingService.getTodayActivities(forceRefresh: true);

      int totalSteps = 0;
      int totalCalories = 0;
      double totalDistance = 0.0;
      int totalDuration = 0;

      // ✅ استخدام وزن المستخدم الفعلي لحساب السعرات
      final userWeight = widget.userData.weight;

      for (var activity in activities) {
        totalSteps += activity.steps;
        // ✅ حساب السعرات حسب نوع النشاط (نفس منطق home_screen_with_animations.dart للمشي)
        totalCalories += _calculateActivityCalories(activity, userWeight);
        totalDistance += activity.distanceKm;
        totalDuration += activity.durationMinutes;
      }

      if (mounted) {
        setState(() {
          _currentSteps = totalSteps;
          _caloriesBurned = totalCalories;
          _distanceKm = totalDistance;
          _durationMin = totalDuration;
          _isLoading = false;
        });
      }

      PrefsHelper.saveTodaySteps(_currentSteps);
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentSteps = PrefsHelper.getTodaySteps();
          _isLoading = false;
          _errorMessage = 'تم تحميل البيانات المحلية';
        });
      }
    }
  }

  double get _progress => _adjustedGoal > 0 ? _currentSteps / _adjustedGoal : 0;

  void _openSimulationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WalkingSimulationScreen(userData: widget.userData),
      ),
    ).then((_) => _loadTodayStats());
  }

  void _openAddActivityScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddWalkingActivity()),
    ).then((_) => _loadTodayStats());
  }

  void _openChallengesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalkingChallenges()),
    );
  }

  void _openStatisticsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalkingStatistics()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showImpactMessage =
        _impactMessage.isNotEmpty && (_adjustedGoal != _baseGoal);
    final remainingSteps = (_adjustedGoal - _currentSteps).clamp(
      0,
      _adjustedGoal,
    );
    final progressPercent = (_progress * 100).round();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🏃 الأنشطة'),
          actions: [
            IconButton(
              icon: const Icon(Icons.emoji_events),
              onPressed: _openChallengesScreen,
              tooltip: 'التحديات',
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: _openStatisticsScreen,
              tooltip: 'الإحصائيات',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _openAddActivityScreen,
              tooltip: 'إضافة نشاط',
            ),
            IconButton(
              icon: const Icon(Icons.sim_card),
              onPressed: _openSimulationScreen,
              tooltip: 'وضع المحاكاة',
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? _buildLoading(theme)
              : _errorMessage != null
              ? _buildError(theme)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.walking,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // ✅ دائرة التقدم الحديثة (Circular Progress)
                          _buildCircularProgressCard(
                            theme,
                            progressPercent,
                            remainingSteps,
                          ),
                          const SizedBox(height: 20),

                          // رسالة التأثير
                          if (showImpactMessage) _buildImpactMessage(theme),
                          if (showImpactMessage) const SizedBox(height: 20),

                          // ✅ إحصائيات سريعة
                          _buildWalkingStats(theme),
                          const SizedBox(height: 20),

                          // ✅ إحصائيات الفترة (مدمجة من صفحة الإحصائيات)
                          _buildPeriodSelector(theme),
                          const SizedBox(height: 24),
                          _buildStatsSummary(theme),
                          const SizedBox(height: 24),
                          // ✅ تحليل حسب نوع النشاط
                          _buildActivityTypeBreakdown(theme),
                          const SizedBox(height: 24),
                          _buildChart(theme),
                          const SizedBox(height: 24),
                          _buildAchievements(theme),
                          const SizedBox(height: 24),
                          _buildActivityLog(theme),
                          const SizedBox(height: 20),

                          // نصائح وتوعية
                          _buildMotivationCard(theme),
                          const SizedBox(height: 16),

                          // معلومات المستخدم
                          _buildUserInfoCard(theme),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل البيانات...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'فشل في تحميل البيانات',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ دائرة التقدم الحديثة - التصميم الجديد
  Widget _buildCircularProgressCard(
    ThemeData theme,
    int progressPercent,
    int remainingSteps,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.walking, theme.colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.walking.withOpacity(0.4),
            spreadRadius: 2,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // العنوان
          const Text(
            'عدد خطوات اليوم',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // دائرة التقدم
          SizedBox(
            width: 220,
            height: 220,
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CircularProgressPainter(
                    progress:
                        _progress.clamp(0.0, 1.0) * _progressAnimation.value,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    progressColor: Colors.white,
                    strokeWidth: 14,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Text(
                            '$_currentSteps',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'من $_adjustedGoal خطوة',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$progressPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // الخطوات المتبقية
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flag, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'متبقي $remainingSteps خطوة لتحقيق الهدف',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),

          if (_adjustedGoal != _baseGoal) ...[
            const SizedBox(height: 4),
            Text(
              'الهدف الأساسي: $_baseGoal خطوة',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImpactMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _impactMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkingStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.walking.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics,
                  color: AppColors.walking,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إحصائيات المشي',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department,
                  value: '$_caloriesBurned',
                  label: 'سعرة محروقة',
                  color: AppColors.calories,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.straighten,
                  value: '${_distanceKm.toStringAsFixed(1)} كم',
                  label: 'المسافة',
                  color: theme.colorScheme.primary,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer,
                  value: '$_durationMin د',
                  label: 'الوقت',
                  color: AppColors.warning,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 📊 Statistics Methods (integrated from walking_statistics.dart) ==========

  List<WalkingActivity> _getFilteredActivities() {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _activities
            .where((a) => a.activityDate.isAfter(weekAgo))
            .toList();
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return _activities
            .where((a) => a.activityDate.isAfter(monthAgo))
            .toList();
      case 'year':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        return _activities
            .where((a) => a.activityDate.isAfter(yearAgo))
            .toList();
      default:
        return _activities;
    }
  }

  Map<String, dynamic> _getPeriodStats() {
    final filtered = _getFilteredActivities();
    final userWeight = widget.userData.weight;

    int totalSteps = filtered.fold(0, (sum, a) => sum + a.steps);
    double totalDistance = filtered.fold(0.0, (sum, a) => sum + a.distanceKm);
    // ✅ حساب السعرات حسب نوع النشاط (نفس منطق home_screen_with_animations.dart)
    int totalCalories = filtered.fold(
      0,
      (sum, a) => sum + _calculateActivityCalories(a, userWeight),
    );
    int avgSteps = filtered.isNotEmpty
        ? (totalSteps / filtered.length).round()
        : 0;

    Map<DateTime, int> stepsByDay = {};
    for (var activity in filtered) {
      final date = DateTime(
        activity.activityDate.year,
        activity.activityDate.month,
        activity.activityDate.day,
      );
      stepsByDay[date] = (stepsByDay[date] ?? 0) + activity.steps;
    }

    final sortedDays = stepsByDay.keys.toList()..sort();

    // ✅ تحليل حسب نوع النشاط
    Map<String, Map<String, dynamic>> typeBreakdown = {};
    for (var a in filtered) {
      final type = a.activityType;
      if (!typeBreakdown.containsKey(type)) {
        typeBreakdown[type] = {
          'steps': 0,
          'calories': 0,
          'duration': 0,
          'count': 0,
        };
      }
      typeBreakdown[type]!['steps'] += a.steps;
      typeBreakdown[type]!['calories'] += _calculateActivityCalories(
        a,
        userWeight,
      );
      typeBreakdown[type]!['duration'] += a.durationMinutes;
      typeBreakdown[type]!['count'] += 1;
    }

    return {
      'totalSteps': totalSteps,
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'avgSteps': avgSteps,
      'stepsByDay': stepsByDay,
      'sortedDays': sortedDays,
      'typeBreakdown': typeBreakdown,
    };
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(40),
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
          _buildPeriodButton('أسبوع', 'week', theme),
          _buildPeriodButton('شهر', 'month', theme),
          _buildPeriodButton('سنة', 'year', theme),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value, ThemeData theme) {
    bool isSelected = _selectedPeriod == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(36),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(ThemeData theme) {
    final stats = _getPeriodStats();
    final totalSteps = stats['totalSteps'] as int;
    final totalDistance = stats['totalDistance'] as double;
    final totalCalories = stats['totalCalories'] as int;
    final avgSteps = stats['avgSteps'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.walking, theme.colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.walking.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'إجمالي الخطوات',
                _formatNumber(totalSteps),
                'خطوة',
                Colors.white,
                theme,
              ),
              _buildStatItem(
                'إجمالي المسافة',
                totalDistance.toStringAsFixed(1),
                'كم',
                Colors.white,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white30, height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'السعرات المحروقة',
                _formatNumber(totalCalories),
                'سعرة',
                Colors.white,
                theme,
              ),
              _buildStatItem(
                'متوسط يومي',
                _formatNumber(avgSteps),
                'خطوة',
                Colors.white,
                theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ تحليل النشاطات حسب النوع
  Widget _buildActivityTypeBreakdown(ThemeData theme) {
    final stats = _getPeriodStats();
    final typeBreakdown =
        stats['typeBreakdown'] as Map<String, Map<String, dynamic>>;

    if (typeBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '📊 تحليل النشاطات',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...typeBreakdown.entries.map((entry) {
            final type = entry.key;
            final data = entry.value;
            final color = _getActivityColor(type);
            final emoji = _getActivityEmoji(type);
            final label = _getActivityLabel(type);
            final steps = data['steps'] as int;
            final calories = data['calories'] as int;
            final duration = data['duration'] as int;
            final count = data['count'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_formatNumber(steps) خطوة • $calories سعرة • $duration دقيقة',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    final stats = _getPeriodStats();
    final stepsByDay = stats['stepsByDay'] as Map<DateTime, int>;
    final sortedDays = stats['sortedDays'] as List<DateTime>;

    if (sortedDays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
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
        child: Center(
          child: Text(
            'لا توجد بيانات كافية للرسم البياني',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    final maxSteps = stepsByDay.values.reduce((a, b) => a > b ? a : b);
    final maxHeight = 140.0;

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
            'توزيع الخطوات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(sortedDays.length, (index) {
                final day = sortedDays[index];
                final steps = stepsByDay[day] ?? 0;
                final height = maxSteps > 0
                    ? (steps / maxSteps) * maxHeight
                    : 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: height as double),
                          duration: Duration(milliseconds: 800 + (index * 50)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Container(
                              height: value,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    steps >= 6000
                                        ? AppColors.success
                                        : steps >= 4000
                                        ? AppColors.warning
                                        : AppColors.danger,
                                    AppColors.walking,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getDayLabel(day, theme),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          '${(steps / 1000).toStringAsFixed(1)}k',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: steps >= 6000
                                ? AppColors.success
                                : steps >= 4000
                                ? AppColors.warning
                                : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(DateTime date, ThemeData theme) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'اليوم';
    }
    return '${date.day}/${date.month}';
  }

  Widget _buildAchievements(ThemeData theme) {
    final stats = _getPeriodStats();
    final totalSteps = stats['totalSteps'] as int;
    final totalDistance = stats['totalDistance'] as double;

    List<Map<String, String>> achievements = [
      {'icon': '🏆', 'title': 'أفضل يوم', 'value': _getBestDay(), 'date': ''},
      {
        'icon': '🔥',
        'title': 'إجمالي الخطوات',
        'value': _formatNumber(totalSteps),
        'date': 'هذه الفترة',
      },
      {
        'icon': '⭐',
        'title': 'المسافة المقطوعة',
        'value': '${totalDistance.toStringAsFixed(1)} كم',
        'date': 'هذه الفترة',
      },
    ];

    if (_stats != null) {
      achievements.add({
        'icon': '🎯',
        'title': 'أفضل يوم',
        'value': '${_formatNumber(_stats!.bestDaySteps)} خطوة',
        'date': _formatDate(_stats!.bestDay),
      });
    }

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
            '🏆 إنجازاتك',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: achievements.take(4).map((achievement) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.walking.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.walking.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      achievement['icon']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      achievement['title']!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      achievement['value']!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (achievement['date']!.isNotEmpty)
                      Text(
                        achievement['date']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getBestDay() {
    if (_activities.isEmpty) return 'لا يوجد';

    final stepsByDay = <DateTime, int>{};
    for (var activity in _activities) {
      final date = DateTime(
        activity.activityDate.year,
        activity.activityDate.month,
        activity.activityDate.day,
      );
      stepsByDay[date] = (stepsByDay[date] ?? 0) + activity.steps;
    }

    if (stepsByDay.isEmpty) return 'لا يوجد';

    final bestDay = stepsByDay.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return '${_formatNumber(bestDay.value)} خطوة';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildActivityLog(ThemeData theme) {
    final filtered = _getFilteredActivities().take(10).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
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
        child: Center(
          child: Column(
            children: [
              Icon(Icons.directions_walk, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'لا توجد نشاطات في هذه الفترة',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            '📋 آخر النشاطات',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) =>
                Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
            itemBuilder: (context, index) {
              final activity = filtered[index];
              final date = activity.activityDate;
              final today = DateTime.now();

              String dateLabel;
              if (date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day) {
                dateLabel = 'اليوم';
              } else if (date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day - 1) {
                dateLabel = 'أمس';
              } else {
                dateLabel = '${date.day}/${date.month}';
              }

              final activityType = activity.activityType;
              final actColor = _getActivityColor(activityType);
              final actEmoji = _getActivityEmoji(activityType);
              final actLabel = _getActivityLabel(activityType);

              return ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: actColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(actEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: actColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        actLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: actColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${_formatNumber(activity.steps)} خطوة • ${activity.distanceKm.toStringAsFixed(1)} كم',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: actColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${activity.durationMinutes} د',
                    style: TextStyle(
                      fontSize: 12,
                      color: actColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withOpacity(0.1),
            AppColors.success.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.warning,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💪 استمر في المشي!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كل خطوة تقربك من هدفك الصحي',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(ThemeData theme) {
    String goal = widget.userData.goal;
    String message;
    Color color;

    switch (goal) {
      case 'تخسيس':
        message = '🔥 المشي اليومي يساعدك على حرق الدهون والوصول لهدفك';
        color = AppColors.success;
        break;
      case 'تثبيت':
        message = '⚖️ المشي يساعد في الحفاظ على وزنك ونشاطك';
        color = theme.colorScheme.primary;
        break;
      case 'زيادة':
        message = '💪 المشي يحسن شهيتك ويساعد في بناء العضلات';
        color = AppColors.warning;
        break;
      default:
        message = '🚶 المشي مفيد لصحتك العامة';
        color = AppColors.walking;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ رسام دائرة التقدم المخصص
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // الخلفية
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // التقدم
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // يبدأ من الأعلى
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
