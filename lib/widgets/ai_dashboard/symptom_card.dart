// lib/widgets/ai_dashboard/symptom_card.dart
// 🤒 بطاقة تحليل الأعراض

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/symptom_model.dart';

class SymptomCard extends StatelessWidget {
  final List<Symptom> symptoms;
  final String mostFrequentSymptom;

  const SymptomCard({
    Key? key,
    required this.symptoms,
    required this.mostFrequentSymptom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDark),
          const SizedBox(height: 16),
          if (symptoms.isEmpty)
            _buildEmptyState(theme)
          else ...[
            _buildStatsRow(theme),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'آخر الأعراض المسجلة',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...symptoms.take(3).map((s) => _buildSymptomItem(s, theme)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sick, color: AppColors.warning, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          '🤒 تحليل الأعراض',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'لا توجد أعراض مسجلة',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildPatternStat(
            theme,
            label: 'إجمالي الأعراض',
            value: '${symptoms.length}',
            color: theme.colorScheme.primary,
          ),
        ),
        Expanded(
          child: _buildPatternStat(
            theme,
            label: 'الأكثر تكراراً',
            value: mostFrequentSymptom,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildPatternStat(
    ThemeData theme, {
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomItem(Symptom symptom, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: symptom.getSeverityColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(symptom.name, style: theme.textTheme.bodySmall)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: symptom.getSeverityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              symptom.severity,
              style: TextStyle(fontSize: 10, color: symptom.getSeverityColor()),
            ),
          ),
        ],
      ),
    );
  }
}
