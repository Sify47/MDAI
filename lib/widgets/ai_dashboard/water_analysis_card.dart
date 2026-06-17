// lib/widgets/ai_dashboard/water_analysis_card.dart
// 💧 بطاقة تحليل شرب الماء

import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class WaterAnalysisCard extends StatelessWidget {
  final double totalWater;
  final double dailyGoal;

  const WaterAnalysisCard({
    Key? key,
    required this.totalWater,
    required this.dailyGoal,
  }) : super(key: key);

  double get _progress =>
      dailyGoal > 0 ? (totalWater / dailyGoal).clamp(0.0, 1.0) : 0.0;

  double get _remaining => (dailyGoal - totalWater).clamp(0.0, dailyGoal);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (statusMessage, statusColor, statusIcon) = _getStatus();

    final cups = (totalWater / 0.25).round();
    final remainingCups = (_remaining / 0.25).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blue.shade800, Colors.cyan.shade900]
              : [Colors.blue.shade400, Colors.cyan.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 20),
          _buildStatsRow(cups, remainingCups),
          const SizedBox(height: 16),
          _buildProgressBar(),
          const SizedBox(height: 12),
          _buildStatusBanner(statusMessage, statusColor, statusIcon),
        ],
      ),
    );
  }

  (String, Color, IconData) _getStatus() {
    if (_progress >= 0.8) {
      return (
        'ممتاز! أنت ملتزم بشرب الماء',
        AppColors.success,
        Icons.emoji_events,
      );
    } else if (_progress >= 0.5) {
      return ('جيد، لكن يمكنك شرب المزيد', AppColors.warning, Icons.water_drop);
    } else {
      return (
        'تحتاج لشرب المزيد من الماء اليوم',
        AppColors.danger,
        Icons.warning,
      );
    }
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.water_drop, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '💧 تحليل شرب الماء',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${(_progress * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int cups, int remainingCups) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat(
          'شربت اليوم',
          '${totalWater.toStringAsFixed(1)} لتر',
          '$cups كوب',
          Colors.white,
        ),
        _buildStat(
          'الهدف اليومي',
          '${dailyGoal.toStringAsFixed(1)} لتر',
          '${(dailyGoal / 0.25).round()} كوب',
          Colors.white70,
        ),
        _buildStat(
          'المتبقي',
          '${_remaining.toStringAsFixed(1)} لتر',
          '$remainingCups كوب',
          Colors.white70,
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, String subtitle, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: 10,
        backgroundColor: Colors.white.withOpacity(0.3),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildStatusBanner(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
