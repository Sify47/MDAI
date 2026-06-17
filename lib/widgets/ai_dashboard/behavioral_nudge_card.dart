// lib/widgets/ai_dashboard/behavioral_nudge_card.dart
// 🧠 بطاقة التحفيزات السلوكية الذكية

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/behavioral_nudges_api.dart';

class BehavioralNudgeCard extends StatefulWidget {
  const BehavioralNudgeCard({Key? key}) : super(key: key);

  @override
  State<BehavioralNudgeCard> createState() => BehavioralNudgeCardState();
}

class BehavioralNudgeCardState extends State<BehavioralNudgeCard> {
  List<Map<String, dynamic>> _nudges = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadNudges();
  }

  Future<void> loadNudges() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await BehavioralNudgesApi.getPendingNudges();
      if (mounted) {
        setState(() {
          _nudges = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل تحميل التحفيزات';
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
              ? [
                  Colors.purple.shade900.withOpacity(0.3),
                  Colors.indigo.shade900.withOpacity(0.3),
                ]
              : [
                  Colors.purple.withOpacity(0.05),
                  Colors.indigo.withOpacity(0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
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
          else if (_nudges.isNotEmpty)
            ..._nudges
                .take(3)
                .map(
                  (nudge) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildNudgeItem(nudge, theme, isDark),
                  ),
                )
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
            color: Colors.purple.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.psychology, color: Colors.purple, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          '🧠 تحفيزات ذكية',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (_nudges.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_nudges.length} جديد',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
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
            onTap: loadNudges,
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
          'لا توجد تحفيزات جديدة الآن',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildNudgeItem(
    Map<String, dynamic> nudge,
    ThemeData theme,
    bool isDark,
  ) {
    final title = nudge['title'] as String? ?? 'تذكير';
    final message = nudge['message'] as String? ?? '';
    final nudgeType = nudge['nudge_type'] as String? ?? 'general';
    final priority = nudge['priority'] as String? ?? 'normal';

    IconData typeIcon;
    Color typeColor;
    switch (nudgeType) {
      case 'water':
        typeIcon = Icons.water_drop;
        typeColor = Colors.blue;
        break;
      case 'meal':
        typeIcon = Icons.restaurant;
        typeColor = Colors.orange;
        break;
      case 'activity':
        typeIcon = Icons.directions_walk;
        typeColor = Colors.green;
        break;
      case 'medication':
        typeIcon = Icons.medication;
        typeColor = Colors.red;
        break;
      default:
        typeIcon = Icons.notifications_active;
        typeColor = Colors.purple;
    }

    final isHighPriority = priority == 'high' || priority == 'critical';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isHighPriority
            ? Border.all(color: AppColors.danger.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isHighPriority)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'هام',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
