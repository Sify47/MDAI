// lib/widgets/ai_dashboard/time_range_selector.dart
// 🕐 منتقي النطاق الزمني - يوم / أسبوع / شهر

import 'package:flutter/material.dart';

enum TimeRange { day, week, month }

class TimeRangeSelector extends StatelessWidget {
  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;

  const TimeRangeSelector({
    Key? key,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: TimeRange.values.map((range) {
          final isSelected = selected == range;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? theme.colorScheme.primary : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: GestureDetector(
                onTap: () => onChanged(range),
                child: Text(
                  _label(range),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? (isDark ? Colors.white : theme.colorScheme.primary)
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(TimeRange range) {
    switch (range) {
      case TimeRange.day:
        return 'يوم';
      case TimeRange.week:
        return 'أسبوع';
      case TimeRange.month:
        return 'شهر';
    }
  }
}
