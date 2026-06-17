// lib/screens/predictive_prevention/predictive_prevention_dashboard.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vita/services/predictive_prevention_api.dart';
import 'package:vita/constants/colors.dart';

class PredictivePreventionDashboard extends StatefulWidget {
  const PredictivePreventionDashboard({super.key});

  @override
  State<PredictivePreventionDashboard> createState() =>
      _PredictivePreventionDashboardState();
}

class _PredictivePreventionDashboardState
    extends State<PredictivePreventionDashboard> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _recentRisks = [];
  List<dynamic> _activePlans = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // تشغيل جميع الطلبات بالتوازي مع مهلة زمنية 60 ثانية
      final results = await Future.wait([
        PredictivePreventionApi.getPreventionDashboard(),
        PredictivePreventionApi.getHealthRisks(limit: 5),
        PredictivePreventionApi.getActivePreventionPlans(),
      ]).timeout(const Duration(seconds: 60));

      setState(() {
        _dashboardData = results[0] as Map<String, dynamic>?;
        _recentRisks = (results[1] as List<dynamic>?) ?? [];
        _activePlans = (results[2] as List<dynamic>?) ?? [];
        _isLoading = false;
      });
    } on TimeoutException {
      setState(() {
        _errorMessage =
            'انتهت مهلة التحميل. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل البيانات: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeRisks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await PredictivePreventionApi.analyzeAndCreatePlans();

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحليل المخاطر وإنشاء ${result['plans_created']} خطة وقائية',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadDashboardData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحليل المخاطر: $e';
        _isLoading = false;
      });
    }
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRiskLevelText(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return 'حرج';
      case 'high':
        return 'مرتفع';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
      default:
        return riskLevel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التنبؤ الوقائي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'تحديث',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _analyzeRisks,
            tooltip: 'تحليل المخاطر',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // إحصائيات سريعة
                    _buildQuickStats(theme, isDark),
                    const SizedBox(height: 24),

                    // المخاطر الحديثة
                    _buildRecentRisksSection(theme, isDark),
                    const SizedBox(height: 24),

                    // الخطط النشطة
                    _buildActivePlansSection(theme, isDark),
                    const SizedBox(height: 24),

                    // تحليل المخاطر حسب النوع
                    if (_dashboardData != null &&
                        _dashboardData!['risk_by_type'] != null &&
                        (_dashboardData!['risk_by_type'] as Map).isNotEmpty)
                      _buildRiskByTypeChart(theme, isDark),
                    const SizedBox(height: 24),

                    // تحليل المخاطر حسب المستوى
                    if (_dashboardData != null &&
                        _dashboardData!['risk_by_level'] != null &&
                        (_dashboardData!['risk_by_level'] as Map).isNotEmpty)
                      _buildRiskByLevelChart(theme, isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      floatingActionButton: _activePlans.isEmpty
          ? FloatingActionButton.extended(
              onPressed: _analyzeRisks,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('تحليل المخاطر'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  // ==================== حالات التحميل والفارغة ====================
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحليل بياناتك الصحية...',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== الإحصائيات السريعة (المُحسّنة) ====================
  Widget _buildQuickStats(ThemeData theme, bool isDark) {
    final totalRisks = _dashboardData?['total_risks'] ?? 0;
    final highRiskCount = _dashboardData?['high_risk_count'] ?? 0;
    final activePlans = _dashboardData?['active_plans'] ?? 0;
    final completedPlans = _dashboardData?['completed_plans'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2, // تغيير النسبة لتجنب التجاوز
      children: [
        _buildStatCard(
          title: 'إجمالي المخاطر',
          value: totalRisks.toString(),
          icon: Icons.warning_amber,
          color: AppColors.primary,
          theme: theme,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'مخاطر عالية',
          value: highRiskCount.toString(),
          icon: Icons.error,
          color: Colors.red,
          theme: theme,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'خطط نشطة',
          value: activePlans.toString(),
          icon: Icons.assignment_turned_in,
          color: Colors.green,
          theme: theme,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'خطط مكتملة',
          value: completedPlans.toString(),
          icon: Icons.check_circle,
          color: Colors.blue,
          theme: theme,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // تقليل padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 24, // حجم ثابت
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== قسم المخاطر الحديثة (المُحسّن) ====================
  Widget _buildRecentRisksSection(ThemeData theme, bool isDark) {
    if (_recentRisks.isEmpty) {
      return _buildEmptySection(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        title: 'لا توجد مخاطر صحية حديثة',
        subtitle: 'جميع مؤشراتك الصحية ضمن المعدلات الطبيعية',
        buttonText: 'تحليل بياناتي',
        onPressed: _analyzeRisks,
        theme: theme,
        isDark: isDark,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.red.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'المخاطر الصحية الحديثة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._recentRisks.map((risk) => _buildRiskItem(risk, theme, isDark)),
      ],
    );
  }

  Widget _buildRiskItem(
    Map<String, dynamic> risk,
    ThemeData theme,
    bool isDark,
  ) {
    final riskLevelColor = _getRiskLevelColor(risk['risk_level']);
    final riskLevelText = _getRiskLevelText(risk['risk_level']);
    final probability = (risk['probability'] as num?)?.toDouble() ?? 0.0;
    final percentage = (probability * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskLevelColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  risk['risk_type'] ?? 'غير محدد',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: riskLevelColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskLevelColor),
                ),
                child: Text(
                  riskLevelText,
                  style: TextStyle(
                    color: riskLevelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            risk['description'] ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: probability,
                    backgroundColor: isDark
                        ? Colors.grey[700]
                        : Colors.grey[200],
                    color: riskLevelColor,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: riskLevelColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentage%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: riskLevelColor,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== قسم الخطط الوقائية (المُحسّن) ====================
  Widget _buildActivePlansSection(ThemeData theme, bool isDark) {
    if (_activePlans.isEmpty) {
      return _buildEmptySection(
        icon: Icons.assignment_outlined,
        iconColor: Colors.blue,
        title: 'لا توجد خطط وقائية نشطة',
        subtitle: 'يمكنك إنشاء خطط وقائية جديدة من خلال تحليل المخاطر',
        buttonText: 'تحليل المخاطر',
        onPressed: _analyzeRisks,
        theme: theme,
        isDark: isDark,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.teal.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_turned_in,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الخطط الوقائية النشطة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._activePlans.map((plan) => _buildPlanItem(plan, theme, isDark)),
      ],
    );
  }

  Widget _buildPlanItem(
    Map<String, dynamic> plan,
    ThemeData theme,
    bool isDark,
  ) {
    final progress = (plan['progress_percentage'] as num?)?.toDouble() ?? 0.0;
    final progressPercentage = progress.toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan['plan_name'] ?? 'خطة وقائية',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor(plan['priority']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getPriorityColor(plan['priority']),
                  ),
                ),
                child: Text(
                  _getPriorityText(plan['priority']),
                  style: TextStyle(
                    color: _getPriorityColor(plan['priority']),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan['description'] ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'التقدم',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$progressPercentage%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(progress),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                  color: _getProgressColor(progress),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== الرسوم البيانية (المُحسّنة) ====================
  Widget _buildRiskByTypeChart(ThemeData theme, bool isDark) {
    final riskByType = _dashboardData!['risk_by_type'] as Map<String, dynamic>;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.purple.shade300],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'توزيع المخاطر حسب النوع',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...riskByType.entries.map((entry) {
              final riskType = entry.key;
              final count = entry.value as int;
              final total = riskByType.values.fold<int>(
                0,
                (sum, v) => sum + (v as int),
              );
              final percentage = total > 0 ? (count / total * 100).toInt() : 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getRiskTypeColor(riskType),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _getRiskTypeText(riskType),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '$count ($percentage%)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: count / total,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        color: _getRiskTypeColor(riskType),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskByLevelChart(ThemeData theme, bool isDark) {
    final riskByLevel =
        _dashboardData!['risk_by_level'] as Map<String, dynamic>;
    final levelOrder = ['critical', 'high', 'medium', 'low'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue.shade300],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'توزيع المخاطر حسب المستوى',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...levelOrder.map((level) {
              if (!riskByLevel.containsKey(level)) return const SizedBox();
              final count = riskByLevel[level] as int;
              final riskLevelColor = _getRiskLevelColor(level);
              final riskLevelText = _getRiskLevelText(level);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: riskLevelColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        riskLevelText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: riskLevelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: riskLevelColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ==================== قسم فارغ موحد ====================
  Widget _buildEmptySection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== دوال مساعدة ====================
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'عالي';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
      default:
        return priority;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 75) return Colors.green;
    if (progress >= 50) return Colors.orange;
    if (progress >= 25) return Colors.yellow[700]!;
    return Colors.red;
  }

  String _getRiskTypeText(String riskType) {
    switch (riskType.toLowerCase()) {
      case 'cardiovascular':
        return 'أمراض القلب والأوعية الدموية';
      case 'diabetes':
        return 'مرض السكري';
      case 'obesity':
        return 'السمنة';
      case 'hypertension':
        return 'ارتفاع ضغط الدم';
      case 'mental_health':
        return 'الصحة النفسية';
      case 'nutritional':
        return 'نقص التغذية';
      case 'physical_inactivity':
        return 'قلة النشاط البدني';
      default:
        return riskType;
    }
  }

  Color _getRiskTypeColor(String riskType) {
    switch (riskType.toLowerCase()) {
      case 'cardiovascular':
        return Colors.red;
      case 'diabetes':
        return Colors.orange;
      case 'obesity':
        return Colors.purple;
      case 'hypertension':
        return Colors.blue;
      case 'mental_health':
        return Colors.teal;
      case 'nutritional':
        return Colors.brown;
      case 'physical_inactivity':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
