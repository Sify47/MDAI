import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/health_model.dart';

class PressureAnalysis extends StatelessWidget {
  final List<PressureReading> readings;

  const PressureAnalysis({Key? key, required this.readings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('📊 تحليل الضغط')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // إحصائيات عامة
                _buildStatsCard(),

                const SizedBox(height: 16),

                // رسم بياني
                _buildChart(),

                const SizedBox(height: 16),

                // تحليل حسب الوقت
                _buildTimeAnalysis(),

                const SizedBox(height: 16),

                // توصيات
                _buildRecommendations(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (readings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('لا توجد بيانات كافية للتحليل')),
      );
    }

    double avgSystolic =
        readings.map((r) => r.systolic).reduce((a, b) => a + b) /
        readings.length;
    double avgDiastolic =
        readings.map((r) => r.diastolic).reduce((a, b) => a + b) /
        readings.length;
    int maxSystolic = readings
        .map((r) => r.systolic)
        .reduce((a, b) => a > b ? a : b);
    int minSystolic = readings
        .map((r) => r.systolic)
        .reduce((a, b) => a < b ? a : b);

    int normal = readings.where((r) => r.status == 'طبيعي').length;
    int high = readings.where((r) => r.status.contains('مرتفع')).length;
    int low = readings.where((r) => r.status == 'منخفض').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.danger, AppColors.danger.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'إحصائيات عامة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${avgSystolic.toStringAsFixed(0)}/${avgDiastolic.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('الأعلى', '$maxSystolic', 'mmHg'),
              _buildStatItem('الأدنى', '$minSystolic', 'mmHg'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('طبيعي', normal.toString(), 'قراءة'),
              _buildStatItem('مرتفع', high.toString(), 'قراءة'),
              _buildStatItem('منخفض', low.toString(), 'قراءة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildChart() {
    if (readings.isEmpty) {
      return const SizedBox();
    }

    // آخر 7 قراءات
    var recent = readings.reversed.take(7).toList();
    double maxValue = readings
        .map((r) => r.systolic)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'آخر 7 قراءات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(recent.length, (index) {
                final reading = recent[index];
                double systolicHeight = (reading.systolic / maxValue) * 120;
                double diastolicHeight = (reading.diastolic / maxValue) * 80;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Container(
                          height: systolicHeight,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: diastolicHeight,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('الانقباضي', AppColors.danger),
              const SizedBox(width: 16),
              _buildLegendItem('الانبساطي', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTimeAnalysis() {
    if (readings.isEmpty) {
      return const SizedBox();
    }

    var morningReadings = readings.where((r) => r.dateTime.hour < 12).toList();
    var afternoonReadings = readings
        .where((r) => r.dateTime.hour >= 12 && r.dateTime.hour < 18)
        .toList();
    var eveningReadings = readings.where((r) => r.dateTime.hour >= 18).toList();

    double morningAvg = morningReadings.isNotEmpty
        ? morningReadings.map((r) => r.systolic).reduce((a, b) => a + b) /
              morningReadings.length
        : 0;

    double afternoonAvg = afternoonReadings.isNotEmpty
        ? afternoonReadings.map((r) => r.systolic).reduce((a, b) => a + b) /
              afternoonReadings.length
        : 0;

    double eveningAvg = eveningReadings.isNotEmpty
        ? eveningReadings.map((r) => r.systolic).reduce((a, b) => a + b) /
              eveningReadings.length
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تحليل حسب الوقت',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (morningReadings.isNotEmpty)
            _buildTimeItem('صباحاً', morningAvg, 'أقل من 120/80'),
          if (afternoonReadings.isNotEmpty)
            _buildTimeItem('ظهراً', afternoonAvg, 'أقل من 120/80'),
          if (eveningReadings.isNotEmpty)
            _buildTimeItem('مساءً', eveningAvg, 'أقل من 120/80'),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String time, double avg, String normal) {
    bool isNormal = avg < 120;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isNormal ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isNormal ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Text(time)),
          Expanded(
            child: Text(
              '${avg.toStringAsFixed(0)} mmHg',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isNormal ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          Expanded(
            child: Text(
              normal,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    if (readings.isEmpty) {
      return const SizedBox();
    }

    int highCount = readings.where((r) => r.status.contains('مرتفع')).length;
    int lowCount = readings.where((r) => r.status == 'منخفض').length;
    double highPercentage = (highCount / readings.length) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.danger.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'التوصيات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (highPercentage > 30)
            _buildRecommendationItem(
              '⚠️ ارتفاع متكرر في الضغط',
              'ننصح بمراجعة طبيبك وتقليل الملح.',
            ),
          if (lowCount > 0)
            _buildRecommendationItem(
              '⚠️ انخفاض في الضغط',
              'اشرب كمية كافية من الماء وتجنب الوقوف المفاجئ.',
            ),
          _buildRecommendationItem(
            '🧂 تقليل الملح',
            'قلل من الأطعمة المالحة والمخللات.',
          ),
          _buildRecommendationItem(
            '🚶 النشاط البدني',
            'مارس المشي 30 دقيقة يومياً.',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
