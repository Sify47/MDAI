// lib/screens/walking/walking_simulation_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/models/nutrition_model.dart';
import 'dart:async';
import '../../constants/colors.dart';
import '../../utils/prefs_helper.dart';
import '../../services/walking_api.dart';
import '../../models/walking_model.dart';

class WalkingSimulationScreen extends StatefulWidget {
  final UserNutritionData userData;

  const WalkingSimulationScreen({Key? key, required this.userData})
    : super(key: key);

  @override
  State<WalkingSimulationScreen> createState() =>
      _WalkingSimulationScreenState();
}

class _WalkingSimulationScreenState extends State<WalkingSimulationScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _stepsController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentSteps = 0;
  int _sessionSteps = 0;
  int _manualSteps = 0;
  int _dailyGoal = 8000;
  bool _isActive = false;
  bool _isManualMode = false;
  Timer? _simulationTimer;
  DateTime? _sessionStartTime;
  Duration _sessionDuration = Duration.zero;
  final TextEditingController _manualStepsController = TextEditingController();

  // ✅ تأثيرات الأعراض والأدوية
  Map<String, dynamic> _walkingImpact = {};
  int _adjustedGoal = 8000;
  int _totalImpactPercentage = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _stepsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _stepsController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _loadUserGoal();
    _loadWalkingImpact();
    _currentSteps = PrefsHelper.getTodaySteps();
    _stepsController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _stopSimulation();
    _pulseController.dispose();
    _stepsController.dispose();
    _slideController.dispose();
    _manualStepsController.dispose();
    super.dispose();
  }

  void _loadUserGoal() {
    final userData = PrefsHelper.getUserData();
    setState(() {
      _dailyGoal = userData['dailyStepsGoal'] ?? 8000;
    });
  }

  Future<void> _loadWalkingImpact() async {
    try {
      final impact = await WalkingService.calculateWalkingImpact();
      if (mounted) {
        setState(() {
          _walkingImpact = impact;
          _adjustedGoal = impact['adjusted_goal'] ?? _dailyGoal;
          _totalImpactPercentage = impact['total_impact_percentage'] ?? 0;
        });
      }
    } catch (e) {
      print('❌ خطأ في جلب تأثير المشي: $e');
    }
  }

  void _startSimulation() {
    setState(() {
      _isActive = true;
      _isManualMode = false;
      _sessionSteps = 0;
      _sessionStartTime = DateTime.now();
      _sessionDuration = Duration.zero;
    });

    // ✅ معدل خطوات أكثر منطقية (خطوة كل 0.4 ثانية = 150 خطوة/دقيقة)
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 400), (
      timer,
    ) {
      if (mounted && _isActive && !_isManualMode) {
        setState(() {
          _sessionSteps += 1;
          _sessionDuration = DateTime.now().difference(_sessionStartTime!);
        });
      }
    });
  }

  void _pauseSimulation() {
    setState(() {
      _isActive = false;
    });
  }

  void _resumeSimulation() {
    setState(() {
      _isActive = true;
      _sessionStartTime = DateTime.now().subtract(_sessionDuration);
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    setState(() {
      _isActive = false;
    });
  }

  void _endSimulation() {
    _simulationTimer?.cancel();

    int newTotal = _currentSteps + _sessionSteps;
    PrefsHelper.saveTodaySteps(newTotal);

    // ✅ حفظ الجلسة في API
    _saveWalkingSession();

    setState(() {
      _currentSteps = newTotal;
      _isActive = false;
      _sessionSteps = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ تم حفظ $_sessionSteps خطوة بنجاح',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _saveWalkingSession() async {
    if (_sessionSteps == 0) return;

    try {
      final activityData = {
        'steps': _sessionSteps,
        'duration_minutes': _sessionDuration.inMinutes,
        'activity_date': DateTime.now().toIso8601String(),
        'activity_time':
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      };

      await WalkingService.addActivity(activityData);
      print('✅ تم حفظ جلسة المشي: $_sessionSteps خطوة');
    } catch (e) {
      print('❌ خطأ في حفظ جلسة المشي: $e');
    }
  }

  void _resetSession() {
    setState(() {
      _sessionSteps = 0;
      _sessionDuration = Duration.zero;
      if (_isActive) {
        _sessionStartTime = DateTime.now();
      }
    });
  }

  void _toggleMode() {
    if (_isActive) {
      _pauseSimulation();
    }
    setState(() {
      _isManualMode = !_isManualMode;
      _sessionSteps = 0;
      _manualStepsController.clear();
    });
  }

  void _addManualSteps() {
    if (_manualStepsController.text.isEmpty) return;

    final steps = int.tryParse(_manualStepsController.text);
    if (steps == null || steps <= 0) return;

    setState(() {
      _sessionSteps += steps;
      _manualStepsController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '➕ تم إضافة $steps خطوة',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  double _calculateCaloriesBurned() {
    final weight = widget.userData.weight;
    // ✅ معادلة منطقية: (الوزن × 0.04) × (الخطوات / 1000)
    return (weight * 0.04) * (_sessionSteps / 1000);
  }

  double _calculateDistance() {
    // ✅ متوسط طول الخطوة 0.75 متر
    return (_sessionSteps * 0.75) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remainingGoal = (_adjustedGoal - _currentSteps).clamp(
      0,
      _adjustedGoal,
    );
    final caloriesBurned = _calculateCaloriesBurned();
    final distance = _calculateDistance();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          title: Text('🎮 وضع المحاكاة'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // ✅ تأثير الأعراض والأدوية
            if (_totalImpactPercentage != 0)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _totalImpactPercentage > 0
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _totalImpactPercentage > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 14,
                      color: _totalImpactPercentage > 0
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_totalImpactPercentage > 0 ? '+' : ''}$_totalImpactPercentage%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _totalImpactPercentage > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTodaySummary(theme, remainingGoal),
                    const SizedBox(height: 20),
                    _buildImpactCard(theme),
                    const SizedBox(height: 20),
                    _buildModeSelector(theme),
                    const SizedBox(height: 20),
                    _buildSimulationCard(theme, caloriesBurned, distance),
                    const SizedBox(height: 20),
                    _buildControlButtons(theme),
                    const SizedBox(height: 16),
                    _buildEndButton(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary(ThemeData theme, int remainingGoal) {
    final progress = _adjustedGoal > 0 ? _currentSteps / _adjustedGoal : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.walking, theme.colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي خطوات اليوم',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (_adjustedGoal != _dailyGoal)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'الهدف المعدل: $_adjustedGoal',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: _currentSteps),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                value.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'الهدف: $_adjustedGoal خطوة',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0.0,
                  end: progress.clamp(0.0, 1.0) as double,
                ),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'متبقي $remainingGoal خطوة',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(ThemeData theme) {
    if (_walkingImpact.isEmpty || _totalImpactPercentage == 0) {
      return const SizedBox.shrink();
    }

    final impactDetails = _walkingImpact['impact_details'] as List? ?? [];
    if (impactDetails.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.health_and_safety,
              size: 20,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تأثير صحتك على المشي',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: impactDetails.map<Widget>((detail) {
                    final isPositive = (detail['impact'] ?? 0) > 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isPositive ? Colors.green : Colors.red)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${detail['name']}: ${isPositive ? '+' : ''}${detail['impact']}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isActive) _pauseSimulation();
                setState(() => _isManualMode = false);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isManualMode
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 18,
                      color: !_isManualMode
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تلقائي',
                      style: TextStyle(
                        color: !_isManualMode
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: !_isManualMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _toggleMode,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isManualMode
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit,
                      size: 18,
                      color: _isManualMode
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'يدوي',
                      style: TextStyle(
                        color: _isManualMode
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: _isManualMode
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationCard(
    ThemeData theme,
    double caloriesBurned,
    double distance,
  ) {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isManualMode ? 'إضافة خطوات يدوياً' : 'جلسة المحاكاة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isActive && !_isManualMode
                      ? AppColors.success.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isActive && !_isManualMode
                              ? _pulseAnimation.value
                              : 1.0,
                          child: Icon(
                            _isActive && !_isManualMode
                                ? Icons.play_arrow
                                : Icons.pause,
                            size: 16,
                            color: _isActive && !_isManualMode
                                ? AppColors.success
                                : Colors.grey,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isActive && !_isManualMode ? 'نشط' : 'متوقف',
                      style: TextStyle(
                        color: _isActive && !_isManualMode
                            ? AppColors.success
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ✅ إحصائيات الجلسة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimulationStat(
                label: 'خطوات الجلسة',
                value: '$_sessionSteps',
                icon: Icons.directions_walk,
                color: AppColors.walking,
                theme: theme,
              ),
              _buildSimulationStat(
                label: 'المسافة',
                value: '${distance.toStringAsFixed(2)} كم',
                icon: Icons.straighten,
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              _buildSimulationStat(
                label: 'السعرات',
                value: '${caloriesBurned.toStringAsFixed(0)}',
                icon: Icons.local_fire_department,
                color: AppColors.calories,
                theme: theme,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ✅ الوقت
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'الوقت: ${_formatDuration(_sessionDuration)}',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),

          // ✅ وضع الإدخال اليدوي
          if (_isManualMode) ...[
            const SizedBox(height: 20),
            Divider(color: theme.colorScheme.outline.withOpacity(0.2)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualStepsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'عدد الخطوات',
                      hintText: 'مثال: 1000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.add),
                      suffixText: 'خطوة',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addManualSteps,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'إضافة',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // ✅ شريط التقدم
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _sessionSteps > 0 ? 1.0 : 0.0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
    if (_isManualMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!_isActive && _sessionSteps == 0)
            _buildControlButton(
              icon: Icons.play_arrow,
              label: 'بدء',
              color: AppColors.success,
              onPressed: _startSimulation,
              theme: theme,
            ),
          if (!_isActive && _sessionSteps > 0)
            _buildControlButton(
              icon: Icons.play_arrow,
              label: 'استئناف',
              color: AppColors.success,
              onPressed: _resumeSimulation,
              theme: theme,
            ),
          if (_isActive)
            _buildControlButton(
              icon: Icons.pause,
              label: 'إيقاف',
              color: AppColors.warning,
              onPressed: _pauseSimulation,
              theme: theme,
            ),
          if (_sessionSteps > 0)
            _buildControlButton(
              icon: Icons.refresh,
              label: 'إعادة',
              color: theme.colorScheme.primary,
              onPressed: _resetSession,
              theme: theme,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Column(
            children: [
              IconButton(
                onPressed: onPressed,
                icon: Icon(icon, color: color, size: 32),
                style: IconButton.styleFrom(
                  backgroundColor: color.withOpacity(0.1),
                  padding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEndButton(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return FadeTransition(
          opacity: AlwaysStoppedAnimation(opacity),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacity)),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sessionSteps > 0 ? _endSimulation : null,
                icon: const Icon(Icons.save),
                label: const Text(
                  'إنهاء وحفظ الجلسة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor:
                      theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
