import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterStatsChart extends StatelessWidget {
  final List<dynamic> stats;
  final double dailyGoal;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const WaterStatsChart({
    Key? key,
    required this.stats,
    required this.dailyGoal,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < stats.length; i++) {
      final stat = stats[i];
      final total = (stat['total'] ?? 0.0).toDouble();
      final goal = (stat['goal'] ?? dailyGoal).toDouble();

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: total,
              color: Colors.blue,
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: goal,
              color: Colors.grey.withOpacity(0.3),
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إحصائيات الماء',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'week', label: Text('أسبوع')),
                  ButtonSegment(value: 'month', label: Text('شهر')),
                  ButtonSegment(value: 'year', label: Text('سنة')),
                ],
                selected: {selectedPeriod},
                onSelectionChanged: (Set<String> selection) {
                  onPeriodChanged(selection.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: dailyGoal + 0.5,
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < stats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              stats[index]['date'] ?? '',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
