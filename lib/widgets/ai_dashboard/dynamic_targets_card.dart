// lib/widgets/ai_dashboard/dynamic_targets_card.dart
// 🎯 بطاقة الأهداف الديناميكية

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/dynamic_targets_service.dart';
import '../../models/dynamic_target_model.dart';

class DynamicTargetsCard extends StatefulWidget {
  const DynamicTargetsCard({Key? key}) : super(key: key);

  @override
  State<DynamicTargetsCard> createState() => DynamicTargetsCardState();
}

class DynamicTargetsCardState extends State<DynamicTargetsCard> {
  Map<String, dynamic>? _targetsData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadTargets();
  }

  Future<void> loadTargets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await DynamicTargetsService.getTodayTargets();
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            _targetsData = result;
          } else {
            _error = result['message'] ?? 'لا توجد أهداف متاحة';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل الأهداف';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.teal.shade900.withOpacity(0.3), Colors.green.shade900.withOpacity(0.3)]
              : [AppColors.success.withOpacity(0.05), AppColors.info.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDark),
          const SizedBox(height: 16),
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_targetsData != null && _targetsData!['data'] != null)
            _buildTargetsContent(theme, isDark)
          else
            _buildEmptyState(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.track_changes, color: AppColors.success, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          '🎯 أهدافك اليومية',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (_targetsData?['data'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ديناميكي',
              style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? '',
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: loadTargets,
            child: const Icon(Icons.refresh, color: AppColors.danger, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          'لا توجد أهداف محددة لهذا اليوم',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetsContent(ThemeData theme, bool isDark) {
    final data = _targetsData!['data'] as DynamicDailyTarget;

    final targets = <_TargetItem>[];
    if (data.targetCalories != null) {
      targets.add(_TargetItem(
        icon: Icons.local_fire_department,
        label: 'السعرات',
        value: data.targetCalories!,
        unit: 'سعرة',
        color: AppColors.danger,
      ));
    }
    if (data.targetProtein != null) {
      targets.add(_TargetItem(
        icon: Icons.fitness_center,
        label: 'البروتين',
        value: data.targetProtein!,
        unit: 'جم',
        color: AppColors.info,
      ));
    }
    if (data.targetCarbs != null) {
      targets.add(_TargetItem(
        icon: Icons.grain,
        label: 'الكربوهيدرات',
        value: data.targetCarbs!,
        unit: 'جم',
        color: AppColors.warning,
      ));
    }
    if (data.targetFat != null) {
      targets.add(_TargetItem(
        icon: Icons.water_drop,
        label: 'الدهون',
        value: data.targetFat!,
        unit: 'جم',
        color: Colors.orange,
      ));
    }
    if (data.targetSteps != null) {
      targets.add(_TargetItem(
        icon: Icons.directions_walk,
        label: 'الخطوات',
        value: data.targetSteps!,
        unit: 'خطوة',
        color: Colors.cyan,
      ));
    }
    if (data.targetWater != null) {
      targets.add(_TargetItem(
        icon: Icons.water,
        label: 'الماء',
        value: data.targetWater!,
        unit: 'لتر',
        color: Colors.blue,
      ));
    }

    if (targets.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: targets.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _buildSingleTargetRow(t, isDark),
      )).toList(),
    );
  }

  Widget _buildSingleTargetRow(_TargetItem item, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          Text(
            '${item.value == item.value.roundToDouble() ? item.value.toInt().toString() : item.value.toStringAsFixed(1)} ${item.unit}',
            style: TextStyle(fontSize: 14, color: item.color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TargetItem {
  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final Color color;

  _TargetItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });
}
