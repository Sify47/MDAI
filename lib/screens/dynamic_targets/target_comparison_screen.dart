// lib/screens/dynamic_targets/target_comparison_screen.dart
// شاشة مقارنة الأهداف - تعرض الفرق بين الأهداف الثابتة (من account creation) والديناميكية

import 'package:flutter/material.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/constants/design_constants.dart';
import 'package:vita/models/dynamic_target_model.dart';
import 'package:vita/services/dynamic_targets_service.dart';

class TargetComparisonScreen extends StatefulWidget {
  const TargetComparisonScreen({Key? key}) : super(key: key);

  @override
  State<TargetComparisonScreen> createState() => _TargetComparisonScreenState();
}

class _TargetComparisonScreenState extends State<TargetComparisonScreen> {
  DynamicTargetComparison? _comparison;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await DynamicTargetsService.getTargetComparison();
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _comparison = result['data'] as DynamicTargetComparison;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مقارنة الأهداف'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadData,
            ),
          ],
        ),
        body: _buildBody(theme, isDark),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final comparison = _comparison;
    if (comparison == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text('لا توجد بيانات للمقارنة', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'قم بحساب الأهداف الديناميكية أولاً',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ شرح المقارنة
            _buildInfoCard(theme),
            const SizedBox(height: 16),

            // ✅ مقارنة السعرات
            _buildComparisonRow(
              theme: theme,
              icon: '🔥',
              label: 'السعرات الحرارية',
              unit: 'سعرة',
              staticValue: comparison.staticCalories,
              dynamicValue: comparison.dynamicCalories,
              changePct: comparison.caloriesChangePct,
              color: AppColors.calories,
            ),
            const SizedBox(height: 12),

            // ✅ مقارنة الخطوات
            _buildComparisonRow(
              theme: theme,
              icon: '🚶',
              label: 'الخطوات',
              unit: 'خطوة',
              staticValue: comparison.staticSteps?.toDouble(),
              dynamicValue: comparison.dynamicSteps,
              changePct: comparison.stepsChangePct,
              color: AppColors.walking,
            ),
            const SizedBox(height: 12),

            // ✅ مقارنة الماء
            _buildComparisonRow(
              theme: theme,
              icon: '💧',
              label: 'الماء',
              unit: 'لتر',
              staticValue: comparison.staticWater,
              dynamicValue: comparison.dynamicWater,
              changePct: comparison.waterChangePct,
              color: AppColors.info,
            ),
            const SizedBox(height: 12),

            // ✅ مقارنة البروتين
            if (comparison.staticProtein != null ||
                comparison.dynamicProtein != null)
              _buildComparisonRow(
                theme: theme,
                icon: '🥩',
                label: 'البروتين',
                unit: 'جم',
                staticValue: comparison.staticProtein,
                dynamicValue: comparison.dynamicProtein,
                changePct: null,
                color: AppColors.nutrition,
              ),
            if (comparison.staticProtein != null ||
                comparison.dynamicProtein != null)
              const SizedBox(height: 12),

            // ✅ مقارنة الكربوهيدرات
            if (comparison.staticCarbs != null ||
                comparison.dynamicCarbs != null)
              _buildComparisonRow(
                theme: theme,
                icon: '🍚',
                label: 'الكربوهيدرات',
                unit: 'جم',
                staticValue: comparison.staticCarbs,
                dynamicValue: comparison.dynamicCarbs,
                changePct: null,
                color: AppColors.warning,
              ),
            if (comparison.staticCarbs != null ||
                comparison.dynamicCarbs != null)
              const SizedBox(height: 12),

            // ✅ مقارنة الدهون
            if (comparison.staticFat != null || comparison.dynamicFat != null)
              _buildComparisonRow(
                theme: theme,
                icon: '🧈',
                label: 'الدهون',
                unit: 'جم',
                staticValue: comparison.staticFat,
                dynamicValue: comparison.dynamicFat,
                changePct: null,
                color: AppColors.danger,
              ),
            if (comparison.staticFat != null || comparison.dynamicFat != null)
              const SizedBox(height: 16),

            // ✅ أسباب التغيير
            if (comparison.changeReasons.isNotEmpty) ...[
              _buildChangeReasonsCard(theme, comparison.changeReasons),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      color: theme.colorScheme.primary.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'الأهداف الديناميكية تتغير يومياً بناءً على حالتك الصحية وأدائك، بينما الأهداف الثابتة تحسب مرة واحدة عند إنشاء الحساب',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required ThemeData theme,
    required String icon,
    required String label,
    required String unit,
    required double? staticValue,
    required double? dynamicValue,
    required double? changePct,
    required Color color,
  }) {
    final hasChange = changePct != null && changePct != 0.0;
    final changeSign = hasChange && changePct > 0 ? '+' : '';
    final changeColor = hasChange
        ? (changePct > 0 ? AppColors.success : AppColors.danger)
        : theme.colorScheme.onSurface.withOpacity(0.5);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (hasChange) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$changeSign${changePct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: changeColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // الثابت
                Expanded(
                  child: _buildValueBox(
                    theme: theme,
                    label: 'ثابت',
                    value: staticValue != null
                        ? '${staticValue.toStringAsFixed(0)} $unit'
                        : '—',
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                // السهم
                Icon(
                  Icons.arrow_forward,
                  color: hasChange ? changeColor : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                // الديناميكي
                Expanded(
                  child: _buildValueBox(
                    theme: theme,
                    label: 'ديناميكي',
                    value: dynamicValue != null
                        ? '${dynamicValue.toStringAsFixed(0)} $unit'
                        : '—',
                    color: color,
                    backgroundColor: color.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueBox({
    required ThemeData theme,
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeReasonsCard(
    ThemeData theme,
    List<Map<String, dynamic>> reasons,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'أسباب التغيير',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...reasons.map((reason) {
              final factorName = reason['factor_name'] ?? reason['type'] ?? '';
              final impact = reason['impact'] ?? reason['adjustment'] ?? 0;
              final impactNum = (impact as num).toDouble();
              final impactColor = impactNum > 0
                  ? AppColors.success
                  : AppColors.danger;
              final impactSign = impactNum > 0 ? '+' : '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      impactNum > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: impactColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        factorName,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                    Text(
                      '$impactSign${impactNum.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: impactColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
