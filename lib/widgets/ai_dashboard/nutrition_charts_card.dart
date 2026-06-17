// lib/widgets/ai_dashboard/nutrition_charts_card.dart
// 📊 بطاقة الرسوم البيانية للتغذية - باستخدام fl_chart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../constants/colors.dart';

class NutritionChartsCard extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final List<double>? weeklyCalories;
  final List<double>? weeklyWeight;
  final List<String>? weekLabels;

  const NutritionChartsCard({
    Key? key,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.weeklyCalories,
    this.weeklyWeight,
    this.weekLabels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = protein + carbs + fat;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blue.shade900.withOpacity(0.3), Colors.cyan.shade900.withOpacity(0.3)]
              : [Colors.blue.withOpacity(0.05), Colors.cyan.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDark, total),
          const SizedBox(height: 20),
          if (total > 0) _buildMacroPieChart(theme, isDark) else _buildEmptyChart(theme, 'لا توجد بيانات غذائية'),
          const SizedBox(height: 20),
          if (weeklyCalories != null && weeklyCalories!.isNotEmpty)
            _buildCalorieLineChart(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, double total) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(isDark ? 0.15 : 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bar_chart, color: Colors.blue, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          '📊 تحليل التغذية',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (total > 0)
          Text(
            '${total.toStringAsFixed(0)} غرام',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
      ],
    );
  }

  Widget _buildMacroPieChart(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildPieSections(),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('بروتين', protein, const Color(0xFF4CAF50)),
              const SizedBox(height: 8),
              _buildLegendItem('كربوهيدرات', carbs, const Color(0xFFFF9800)),
              const SizedBox(height: 8),
              _buildLegendItem('دهون', fat, const Color(0xFFF44336)),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = protein + carbs + fat;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        value: protein,
        title: '${(protein / total * 100).toStringAsFixed(0)}%',
        color: const Color(0xFF4CAF50),
        radius: 50,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: carbs,
        title: '${(carbs / total * 100).toStringAsFixed(0)}%',
        color: const Color(0xFFFF9800),
        radius: 50,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: fat,
        title: '${(fat / total * 100).toStringAsFixed(0)}%',
        color: const Color(0xFFF44336),
        radius: 50,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  Widget _buildLegendItem(String label, double value, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text('$label ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        Text('${value.toStringAsFixed(0)}غ', style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildCalorieLineChart(ThemeData theme, bool isDark) {
    final data = weeklyCalories!;
    final labels = weekLabels ?? List.generate(data.length, (i) => '${i + 1}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text('اتجاه السعرات', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (data.length >= 2) ...[
              const Spacer(),
              Icon(
                data.last >= data.first ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: data.last >= data.first ? Colors.red : Colors.green,
              ),
              Text(
                '${((data.last - data.first) / (data.first == 0 ? 1 : data.first) * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, color: data.last >= data.first ? Colors.red : Colors.green),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                horizontalInterval: 200,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < labels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(labels[idx], style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: (data.reduce((a, b) => a < b ? a : b) * 0.8).clamp(0, double.infinity),
              maxY: data.reduce((a, b) => a > b ? a : b) * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3,
                      color: theme.colorScheme.primary,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart(ThemeData theme, String message) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
