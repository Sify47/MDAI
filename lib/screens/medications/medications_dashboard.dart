// lib/screens/medications/medications_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:vita/services/medication_api.dart';
import 'package:vita/services/notification_service.dart';
import 'package:vita/services/symptom_api.dart';
import 'package:vita/models/symptom_model.dart';
import '../../constants/colors.dart';
import '../../models/medication_model.dart';
import 'add_medication_screen.dart';
import 'medication_details_screen.dart';
import 'medication_statistics_screen.dart';

class MedicationsDashboard extends StatefulWidget {
  const MedicationsDashboard({super.key});

  @override
  State<MedicationsDashboard> createState() => _MedicationsDashboardState();
}

class _MedicationsDashboardState extends State<MedicationsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _missedDosesTimer;

  List<UserMedication> _medications = [];
  List<MedicationDose> _todayDoses = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  List<Symptom> _recentSymptoms = [];
  bool _symptomCorrelationLoading = false;

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
    _controller.forward();
    _loadMedications();
    _loadSymptomCorrelation();
    _requestNotificationPermissions();
    _startMissedDosesChecker();
  }

  Future<void> _requestNotificationPermissions() async {
    await NotificationService.requestPermissions();
  }

  @override
  void dispose() {
    _controller.dispose();
    _missedDosesTimer?.cancel();
    super.dispose();
  }

  void _startMissedDosesChecker() {
    _missedDosesTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkMissedDoses();
    });
  }

  Future<void> _checkMissedDoses() async {
    if (_isLoading || _isProcessing) return;

    try {
      final result = await MedicationService.updateMissedDoses();

      if (result['success'] == true && result['updated_count'] > 0) {
        await _loadMedications();
      }
    } catch (e) {
      print('🔥 خطأ في فحص الجرعات الفائتة: $e');
    }
  }

  Future<void> _loadSymptomCorrelation() async {
    try {
      setState(() => _symptomCorrelationLoading = true);
      final symptoms = await SymptomService.getSymptoms(limit: 10);
      if (mounted) {
        setState(() {
          _recentSymptoms = symptoms;
          _symptomCorrelationLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading symptoms for correlation: $e');
      if (mounted) {
        setState(() => _symptomCorrelationLoading = false);
      }
    }
  }

  Future<void> _loadMedications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        MedicationService.getMedications(),
        MedicationService.getTodayDoses(),
      ]);

      if (!mounted) return;

      final meds = results[0] as List<UserMedication>;
      final doses = results[1] as List<MedicationDose>;

      setState(() {
        _medications = meds;
        _todayDoses = doses;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'فشل في تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _canTakeDose(DateTime scheduledTime) {
    final now = DateTime.now();
    return scheduledTime.hour == now.hour;
  }

  Color _getMedicineColor(UserMedication medication, ThemeData theme) {
    final category = medication.medicineInfo?.category;
    switch (category) {
      case 'أدوية السكري':
        return AppColors.success;
      case 'أدوية الضغط':
      case 'أدوية القلب':
        return theme.colorScheme.primary;
      case 'مضادات حيوية':
        return AppColors.danger;
      case 'مسكنات':
        return AppColors.calories;
      case 'مضادات التهاب':
        return AppColors.medications;
      default:
        return AppColors.medications;
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
          title: Text('💊 الأدوية'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              onPressed: _isLoading ? null : _loadMedications,
            ),
            IconButton(
              icon: Icon(Icons.bar_chart, color: theme.colorScheme.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MedicationStatisticsScreen(medications: _medications),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.add, color: theme.colorScheme.primary),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddMedicationScreen(),
                  ),
                );
                if (result != null && mounted) {
                  _loadMedications();
                }
              },
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: AnimationLimiter(
                      child: Column(
                        children: [
                          _buildStatsCard(theme),
                          const SizedBox(height: 16),
                          _buildTodayDoses(theme),
                          const SizedBox(height: 16),
                          _buildMedicationsList(theme),
                          const SizedBox(height: 16),
                          _buildTipsCard(theme),
                          if (!_symptomCorrelationLoading && _recentSymptoms.isNotEmpty && _medications.isNotEmpty)
                            const SizedBox(height: 16),
                          _buildMedicationSymptomCorrelation(theme),
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
            'جاري تحميل الأدوية...',
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
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMedications,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة الإحصائيات
  Widget _buildStatsCard(ThemeData theme) {
    int taken = _todayDoses.where((d) => d.status == 'taken').length;
    int total = _todayDoses.length;
    int pending = _todayDoses.where((d) => d.status == 'pending').length;
    int missed = _todayDoses.where((d) => d.status == 'missed').length;
    double progress = total > 0 ? taken / total : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.medications, theme.colorScheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.medications.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'التزام اليوم',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('تم', taken.toString(), Colors.white),
              _buildStatItem('متبقي', pending.toString(), Colors.white70),
              _buildStatItem('فات', missed.toString(), Colors.white70),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% التزام',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  // جرعات اليوم
  Widget _buildTodayDoses(ThemeData theme) {
    if (_todayDoses.isEmpty) {
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
              Icon(
                Icons.medication_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'لا توجد جرعات لليوم',
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
            'جرعات اليوم',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todayDoses.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final dose = _todayDoses[index];
              return _buildDoseItem(dose, theme);
            },
          ),
        ],
      ),
    );
  }

  // عنصر جرعة واحدة
  Widget _buildDoseItem(MedicationDose dose, ThemeData theme) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    bool canTake = false;

    switch (dose.status) {
      case 'taken':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'تم';
        canTake = false;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time;
        statusText = 'متبقي';
        canTake = _canTakeDose(dose.scheduledTime);
        break;
      case 'missed':
        statusColor = AppColors.danger;
        statusIcon = Icons.cancel;
        statusText = 'فات';
        canTake = false;
        break;
      default:
        statusColor = theme.colorScheme.onSurface.withOpacity(0.5);
        statusIcon = Icons.help;
        statusText = '';
        canTake = false;
    }

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(statusIcon, color: statusColor, size: 22),
      ),
      title: Text(
        dose.medicationName,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${dose.dose} • ${_formatTime(dose.scheduledTime)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: dose.status == 'pending' && canTake
          ? _buildTakeButton(dose, statusColor, theme)
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  // زر "تم" مع منع التكرار
  Widget _buildTakeButton(
    MedicationDose dose,
    Color statusColor,
    ThemeData theme,
  ) {
    return ElevatedButton(
      onPressed: _isProcessing
          ? null
          : () async {
              setState(() => _isProcessing = true);

              try {
                final result = await MedicationService.markDoseAsTaken(
                  dose.medicationId,
                );

                if (!mounted) return;

                if (result['success'] == true) {
                  await _loadMedications();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ ${result['message'] ?? 'تم تسجيل الجرعة'}',
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ ${result['message']}'),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('❌ حدث خطأ غير متوقع'),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } finally {
                if (mounted) {
                  setState(() => _isProcessing = false);
                }
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: _isProcessing ? Colors.grey : statusColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(70, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: _isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('تم', style: TextStyle(fontSize: 13)),
    );
  }

  // قائمة الأدوية
  Widget _buildMedicationsList(ThemeData theme) {
    if (_medications.isEmpty) {
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
              Icon(
                Icons.medication_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'لا توجد أدوية',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أضف أول دواء الآن!',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
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
            'الأدوية',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _medications.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final medication = _medications[index];
              final medicineColor = _getMedicineColor(medication, theme);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, opacity, child) {
                  return FadeTransition(
                    opacity: AlwaysStoppedAnimation(opacity),
                    child: Transform.translate(
                      offset: Offset(20 * (1 - opacity), 0),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicationDetailsScreen(
                                medication: medication,
                              ),
                            ),
                          );
                        },
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: medicineColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '💊',
                              style: TextStyle(
                                fontSize: 24,
                                color: medicineColor,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          medication.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${medication.dosage} • ${medication.timesPerDay} مرات يومياً',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
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
                                color: medication.withFood
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                medication.withFood ? 'مع الأكل' : 'قبل الأكل',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: medication.withFood
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // بطاقة ارتباط الدواء بالأعراض
  Widget _buildMedicationSymptomCorrelation(ThemeData theme) {
    if (_symptomCorrelationLoading) {
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
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_recentSymptoms.isEmpty || _medications.isEmpty) {
      return const SizedBox.shrink();
    }

    // Build medication → symptom correlation pairs
    final correlations = <Map<String, dynamic>>[];

    // Check if any medication category suggests it could cause symptoms
    for (final med in _medications) {
      final category = med.medicineInfo?.category ?? '';
      final medSideEffects = med.medicineInfo?.sideEffects ?? <String>[];

      for (final symptom in _recentSymptoms) {
        bool matches = false;
        String matchReason = '';

        // Direct side effect match
        if (medSideEffects.any((effect) =>
            symptom.name.contains(effect) || effect.contains(symptom.name))) {
          matches = true;
          matchReason = 'من الآثار الجانبية المعروفة';
        }
        // Category-based heuristic match
        else if (_isCategorySymptomMatch(category, symptom.name)) {
          matches = true;
          matchReason = 'قد يكون مرتبطاً بنوع الدواء';
        }

        if (matches) {
          correlations.add({
            'medication': med.name,
            'symptom': symptom.name,
            'symptom_icon': symptom.icon ?? '🤒',
            'severity': symptom.severity,
            'reason': matchReason,
            'date': '${symptom.dateTime.month}/${symptom.dateTime.day}',
          });
        }
      }
    }

    if (correlations.isEmpty) {
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'لا توجد أعراض مرتبطة بأدويتك حالياً',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withOpacity(0.05),
            AppColors.danger.withOpacity(0.08),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link, color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                '🔗 ارتباط الدواء بالأعراض',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...correlations.take(5).map((corr) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    corr['symptom_icon'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${corr['symptom']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${corr['medication']} — ${corr['reason']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getCorrelationSeverityColor(corr['severity'] as String).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${corr['severity']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getCorrelationSeverityColor(corr['severity'] as String),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
          if (correlations.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Center(
                child: Text(
                  '+ ${correlations.length - 5} ارتباطات أخرى',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCorrelationSeverityColor(String severity) {
    switch (severity) {
      case 'شديد':
        return AppColors.danger;
      case 'متوسط':
        return AppColors.warning;
      case 'خفيف':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  bool _isCategorySymptomMatch(String category, String symptomName) {
    switch (category) {
      case 'أدوية السكري':
        return symptomName.contains('دوخة') || symptomName.contains('دوار') ||
            symptomName.contains('إرهاق') || symptomName.contains('تعب') ||
            symptomName.contains('جوع') || symptomName.contains('عطش');
      case 'أدوية الضغط':
        return symptomName.contains('دوخة') || symptomName.contains('دوار') ||
            symptomName.contains('صداع') || symptomName.contains('غثيان');
      case 'أدوية القلب':
        return symptomName.contains('خفقان') || symptomName.contains('ضيق') ||
            symptomName.contains('تعب') || symptomName.contains('إرهاق');
      case 'مضادات حيوية':
        return symptomName.contains('غثيان') || symptomName.contains('إسهال') ||
            symptomName.contains('معدة') || symptomName.contains('حساسية');
      case 'مسكنات':
        return symptomName.contains('معدة') || symptomName.contains('غثيان') ||
            symptomName.contains('نعاس') || symptomName.contains('دوار');
      case 'مضادات التهاب':
        return symptomName.contains('معدة') || symptomName.contains('حرقة') ||
            symptomName.contains('غثيان');
      default:
        return false;
    }
  }

  // بطاقة النصائح
  Widget _buildTipsCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            AppColors.medications.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'نصائح مهمة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('⏰', 'خذ أدويتك في نفس الوقت كل يوم', theme),
          _buildTipItem('💧', 'اشرب كمية كافية من الماء مع الأدوية', theme),
          _buildTipItem('📝', 'استخدم المنبه لتذكر مواعيد الأدوية', theme),
          _buildTipItem('🚫', 'لا تتوقف عن الدواء دون استشارة الطبيب', theme),
        ],
      ),
    );
  }

  Widget _buildTipItem(String icon, String tip, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
