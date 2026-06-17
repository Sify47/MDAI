// lib/screens/dynamic_targets/achievements_screen.dart
// شاشة الإنجازات - تعرض المكافآت والإنجازات مع نظام النقاط والاستمرارية

import 'package:flutter/material.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/constants/design_constants.dart';
import 'package:vita/models/dynamic_target_model.dart';
import 'package:vita/services/dynamic_targets_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  AchievementStats? _stats;
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
      final result = await DynamicTargetsService.getAchievements();
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _stats = result['data'] as AchievementStats;
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
          title: const Text('الإنجازات'),
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

    final stats = _stats;
    if (stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined,
                size: 64, color: theme.colorScheme.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'لا توجد إنجازات بعد',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'استمر في تحقيق أهدافك اليومية لتحصل على الإنجازات',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
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
            // ✅ بطاقة الإحصائيات
            _buildStatsCard(theme, stats),
            const SizedBox(height: 16),

            // ✅ شريط الاستمرارية
            if (stats.streakDays > 0) ...[
              _buildStreakCard(theme, stats.streakDays),
              const SizedBox(height: 16),
            ],

            // ✅ توزيع الإنجازات حسب النوع
            if (stats.milestonesByType.isNotEmpty) ...[
              _buildMilestonesByTypeCard(theme, stats),
              const SizedBox(height: 16),
            ],

            // ✅ أحدث الإنجازات
            if (stats.recentMilestones.isNotEmpty) ...[
              Text(
                'أحدث الإنجازات',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...stats.recentMilestones.map(
                (milestone) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildMilestoneCard(theme, milestone),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme, AchievementStats stats) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: DesignConstants.borderRadiusCard,
          gradient: LinearGradient(
            colors: [
              AppColors.warning.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: '🏆',
                    value: '${stats.totalMilestones}',
                    label: 'إنجاز',
                    color: AppColors.warning,
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                  ),
                  _buildStatItem(
                    icon: '⭐',
                    value: '${stats.totalPoints}',
                    label: 'نقطة',
                    color: AppColors.primary,
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                  ),
                  _buildStatItem(
                    icon: '🔥',
                    value: '${stats.streakDays}',
                    label: 'يوم متتالي',
                    color: AppColors.danger,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(ThemeData theme, int streakDays) {
    final streakEmoji = streakDays >= 21
        ? '🔥🔥🔥'
        : streakDays >= 14
            ? '🔥🔥'
            : streakDays >= 7
                ? '🔥'
                : '💪';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: DesignConstants.borderRadiusCard,
          gradient: LinearGradient(
            colors: [
              AppColors.danger.withOpacity(0.08),
              AppColors.warning.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: DesignConstants.borderRadiusItem,
                ),
                child: Text(streakEmoji, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سلسلة الاستمرارية',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$streakDays يوم متتالي من الالتزام',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStreakMessage(streakDays),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStreakMessage(int days) {
    if (days >= 30) return 'أنت بطل! استمر في هذا الأداء المذهل 🎉';
    if (days >= 21) return 'اقتربت من تحقيق إنجاز 30 يوم! استمر 🔥';
    if (days >= 14) return 'نصف الشهر! حافظ على الزخم 💪';
    if (days >= 7) return 'أسبوع كامل من الالتزام! أحسنت 👏';
    if (days >= 3) return 'بداية قوية! استمر في البناء على هذا 🔥';
    return 'كل يوم يعد إنجازاً، استمر!';
  }

  Widget _buildMilestonesByTypeCard(ThemeData theme, AchievementStats stats) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'توزيع الإنجازات',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.milestonesByType.entries.map((entry) {
              final type = entry.key;
              final count = entry.value;
              final icon = DynamicTargetsService.getMilestoneIcon(type);
              final color = _getMilestoneTypeColor(type);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getMilestoneTypeName(type),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
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

  Widget _buildMilestoneCard(ThemeData theme, AchievementMilestone milestone) {
    final icon = milestone.icon ?? DynamicTargetsService.getMilestoneIcon(milestone.milestoneType);
    final color = _getMilestoneTypeColor(milestone.milestoneType);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: DesignConstants.borderRadiusItem,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: DesignConstants.borderRadiusItem,
              ),
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMilestoneTypeName(milestone.milestoneType),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (milestone.description != null &&
                      milestone.description!.isNotEmpty)
                    Text(
                      milestone.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  if (milestone.achievedAt != null)
                    Text(
                      milestone.achievedAt!,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                ],
              ),
            ),
            if (milestone.points > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 2),
                    Text(
                      '+${milestone.points}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getMilestoneTypeColor(String type) {
    switch (type) {
      case 'streak':
        return AppColors.danger;
      case 'adherence':
        return AppColors.success;
      case 'calories':
        return AppColors.calories;
      case 'steps':
        return AppColors.walking;
      case 'water':
        return AppColors.info;
      case 'medication':
        return AppColors.medications;
      default:
        return AppColors.warning;
    }
  }

  String _getMilestoneTypeName(String type) {
    switch (type) {
      case 'streak':
        return 'الاستمرارية';
      case 'adherence':
        return 'الالتزام';
      case 'calories':
        return 'السعرات';
      case 'steps':
        return 'الخطوات';
      case 'water':
        return 'الماء';
      case 'medication':
        return 'الأدوية';
      default:
        return type;
    }
  }
}