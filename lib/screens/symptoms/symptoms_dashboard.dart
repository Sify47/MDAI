// lib/screens/symptoms/symptoms_dashboard.dart

import 'package:flutter/material.dart';
import 'package:vita/services/nutrition_api.dart';
import '../../../constants/colors.dart';
import '../../../services/symptom_api.dart';
import '../../../models/symptom_model.dart';
import '../../../models/nutrition_model.dart';
import 'add_symptom_screen.dart';
import 'symptom_history_screen.dart';
import 'symptom_detail_screen.dart';

class SymptomsDashboard extends StatefulWidget {
  const SymptomsDashboard({Key? key}) : super(key: key);

  @override
  State<SymptomsDashboard> createState() => _SymptomsDashboardState();
}

class _SymptomsDashboardState extends State<SymptomsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  List<Symptom> _recentSymptoms = [];
  bool _isLoading = true;
  String? _errorMessage;
  UserNutritionData? _userNutritionData;

  int _totalSymptoms = 0;
  int _mildCount = 0;
  int _moderateCount = 0;
  int _severeCount = 0;
  String _mostFrequentSymptom = 'لا يوجد';

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
    _loadUserData();
    _loadSymptoms();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await NutritionService.getUserNutritionData();
      if (userData != null && mounted) {
        setState(() {
          _userNutritionData = userData;
        });
      }
    } catch (e) {
      print('❌ خطأ في تحميل بيانات المستخدم: $e');
    }
  }

  Future<void> _loadSymptoms() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final symptoms = await SymptomService.getSymptoms(forceRefresh: true);

      if (!mounted) return;

      setState(() {
        _recentSymptoms = symptoms.take(5).toList();
        _calculateStats(symptoms);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'فشل في تحميل الأعراض';
        _isLoading = false;
      });
    }
  }

  void _calculateStats(List<Symptom> symptoms) {
    _totalSymptoms = symptoms.length;
    _mildCount = symptoms.where((s) => s.severity == 'خفيف').length;
    _moderateCount = symptoms.where((s) => s.severity == 'متوسط').length;
    _severeCount = symptoms.where((s) => s.severity == 'شديد').length;

    if (symptoms.isNotEmpty) {
      var symptomCounts = <String, int>{};
      for (var s in symptoms) {
        symptomCounts[s.name] = (symptomCounts[s.name] ?? 0) + 1;
      }
      var mostFrequent = symptomCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      _mostFrequentSymptom = mostFrequent.key;
    }
  }

  Future<void> _showSymptomDetails(Symptom symptom) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fullSymptom = await SymptomService.getSymptomById(symptom.id);

      if (!mounted) return;
      Navigator.pop(context);

      if (fullSymptom != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SymptomDetailScreen(symptom: fullSymptom),
          ),
        );
        // Refresh dashboard when returning (symptom may have been edited/deleted)
        if (mounted) {
          _loadSymptoms();
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فشل في تحميل تفاصيل العرض'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          title: Text('🤒 الأعراض'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              onPressed: _loadSymptoms,
            ),
            IconButton(
              icon: Icon(Icons.history, color: theme.colorScheme.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SymptomHistoryScreen(),
                  ),
                ).then((_) => _loadSymptoms());
              },
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? _buildLoading(theme)
              : _errorMessage != null
              ? _buildError(theme)
              : RefreshIndicator(
                  onRefresh: _loadSymptoms,
                  color: theme.colorScheme.primary,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildQuickAddCard(theme),
                          const SizedBox(height: 16),
                          _buildStatsCard(theme),
                          const SizedBox(height: 16),
                          _buildRecentSymptoms(theme),
                          const SizedBox(height: 16),
                          _buildQuickAnalysis(theme),
                          const SizedBox(height: 16),
                          _buildSymptomsTips(theme),
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
            'جاري تحميل الأعراض...',
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
              onPressed: _loadSymptoms,
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

  Widget _buildQuickAddCard(ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddSymptomScreen(
              userData: _userNutritionData, // ✅ تمرير بيانات المستخدم
            ),
          ),
        );
        if (result != null && mounted) {
          _loadSymptoms();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, AppColors.success],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'كيف تشعر اليوم؟',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سجل أي عرض تشعر به للحصول على تحليل سريع',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme) {
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
            'ملخص سريع',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'إجمالي',
                '$_totalSymptoms',
                Icons.sick,
                theme.colorScheme.primary,
                theme,
              ),
              _buildStatItem(
                'خفيف',
                '$_mildCount',
                Icons.sentiment_satisfied,
                AppColors.success,
                theme,
              ),
              _buildStatItem(
                'متوسط',
                '$_moderateCount',
                Icons.sentiment_neutral,
                AppColors.warning,
                theme,
              ),
              _buildStatItem(
                'شديد',
                '$_severeCount',
                Icons.sentiment_very_dissatisfied,
                AppColors.danger,
                theme,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'أكثر الأعراض تكراراً: ',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  _mostFrequentSymptom,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildRecentSymptoms(ThemeData theme) {
    if (_recentSymptoms.isEmpty) {
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
                Icons.inbox,
                size: 56,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'لا توجد أعراض مسجلة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أضف أول عرض الآن!',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الأعراض الأخيرة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SymptomHistoryScreen(),
                    ),
                  ).then((_) => _loadSymptoms());
                },
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentSymptoms.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final symptom = _recentSymptoms[index];
              Color severityColor = symptom.getSeverityColor();

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, opacity, child) {
                  return FadeTransition(
                    opacity: AlwaysStoppedAnimation(opacity),
                    child: Transform.translate(
                      offset: Offset(0, 15 * (1 - opacity)),
                      child: ListTile(
                        onTap: () => _showSymptomDetails(symptom),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              symptom.icon ?? '🤒',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        title: Text(
                          symptom.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${symptom.dateTime.year}/${symptom.dateTime.month}/${symptom.dateTime.day} • '
                          '${symptom.dateTime.hour}:${symptom.dateTime.minute.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                symptom.severity,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: severityColor,
                                  fontWeight: FontWeight.bold,
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

  Widget _buildQuickAnalysis(ThemeData theme) {
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
            'تحليل سريع',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisItem(
                  label: 'الأعراض المتكررة',
                  value: _mostFrequentSymptom,
                  icon: '🤕',
                  color: AppColors.warning,
                  theme: theme,
                ),
              ),
              Expanded(
                child: _buildAnalysisItem(
                  label: 'أكثر شدة',
                  value: _severeCount > 0 ? 'شديد ($_severeCount)' : 'لا يوجد',
                  icon: '🔴',
                  color: AppColors.danger,
                  theme: theme,
                ),
              ),
              Expanded(
                child: _buildAnalysisItem(
                  label: 'الأقل شدة',
                  value: _mildCount > 0 ? 'خفيف ($_mildCount)' : 'لا يوجد',
                  icon: '🟢',
                  color: AppColors.success,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem({
    required String label,
    required String value,
    required String icon,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSymptomsTips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            AppColors.success.withOpacity(0.05),
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
              Icon(Icons.lightbulb, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'متى تزور الطبيب؟',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            '🚨 ألم في الصدر أو ضيق في التنفس',
            'اطلب المساعدة فوراً',
            AppColors.danger,
            theme,
          ),
          _buildTipItem(
            '🌡️ حرارة مرتفعة أكثر من 3 أيام',
            'استشر طبيبك',
            AppColors.warning,
            theme,
          ),
          _buildTipItem(
            '🤕 صداع شديد ومفاجئ',
            'قد يكون علامة خطر',
            AppColors.warning,
            theme,
          ),
          _buildTipItem(
            '😵 دوخة مع فقدان توازن',
            'استشر طبيب أعصاب',
            theme.colorScheme.primary,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(
    String tip,
    String action,
    Color color,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  action,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
