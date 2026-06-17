import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/health_model.dart';
import 'sugar_analysis.dart';

class SugarHistory extends StatelessWidget {
  final List<SugarReading> readings;

  const SugarHistory({Key? key, required this.readings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📋 سجل قراءات السكر'),
          actions: [
            IconButton(
              icon: Icon(Icons.analytics, color: AppColors.calories),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SugarAnalysis(readings: readings),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: readings.isEmpty ? _buildEmptyState() : _buildHistoryList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد قراءات بعد',
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف أول قراءة لك',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    // تجميع القراءات حسب التاريخ
    Map<String, List<SugarReading>> groupedReadings = {};
    for (var reading in readings) {
      String dateKey =
          '${reading.dateTime.year}/${reading.dateTime.month}/${reading.dateTime.day}';
      if (!groupedReadings.containsKey(dateKey)) {
        groupedReadings[dateKey] = [];
      }
      groupedReadings[dateKey]!.add(reading);
    }

    // ترتيب التواريخ تنازلياً
    var sortedDates = groupedReadings.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        String date = sortedDates[index];
        List<SugarReading> dayReadings = groupedReadings[date]!;

        // ترتيب القراءات تنازلياً حسب الوقت
        dayReadings.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // التاريخ
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.calories,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // قائمة القراءات
                ...dayReadings.map(
                  (reading) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              reading.status,
                            ).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getStatusIcon(reading.status),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${reading.value.toStringAsFixed(0)} mg/dL',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${reading.type} • ${_formatTime(reading.dateTime)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              reading.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reading.status,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getStatusColor(reading.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateKey) {
    var parts = dateKey.split('/');
    return '${parts[0]}/${parts[1]}/${parts[2]}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'منخفض':
      case 'مرتفع':
        return AppColors.danger;
      case 'مرتفع قليلاً':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'منخفض':
        return '⬇️';
      case 'مرتفع':
      case 'مرتفع قليلاً':
        return '⬆️';
      default:
        return '✅';
    }
  }
}
