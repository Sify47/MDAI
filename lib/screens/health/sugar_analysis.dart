import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/health_model.dart';

class SugarAnalysis extends StatelessWidget {
  final List<SugarReading> readings;

  const SugarAnalysis({Key? key, required this.readings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('📊 تحليل السكر')),
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

                // تحليل حسب النوع
                _buildTypeAnalysis(),

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

    double average =
        readings.map((r) => r.value).reduce((a, b) => a + b) / readings.length;
    double max = readings.map((r) => r.value).reduce((a, b) => a > b ? a : b);
    double min = readings.map((r) => r.value).reduce((a, b) => a < b ? a : b);

    int normal = readings.where((r) => r.status == 'طبيعي').length;
    int high = readings.where((r) => r.status.contains('مرتفع')).length;
    int low = readings.where((r) => r.status == 'منخفض').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.calories, AppColors.calories.withOpacity(0.8)],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'المتوسط',
                '${average.toStringAsFixed(1)}',
                'mg/dL',
              ),
              _buildStatItem('الأعلى', max.toStringAsFixed(0), 'mg/dL'),
              _buildStatItem('الأدنى', min.toStringAsFixed(0), 'mg/dL'),
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
            fontSize: 24,
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
                double maxValue = readings
                    .map((r) => r.value)
                    .reduce((a, b) => a > b ? a : b);
                double height = (reading.value / maxValue) * 120;

                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor(reading.status),
                              _getStatusColor(reading.status).withOpacity(0.7),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
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
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeAnalysis() {
    if (readings.isEmpty) {
      return const SizedBox();
    }

    var fastingReadings = readings.where((r) => r.type == 'صائم').toList();
    var postMealReadings = readings.where((r) => r.type == 'فاطر').toList();
    var randomReadings = readings.where((r) => r.type == 'عشوائي').toList();
    var bedtimeReadings = readings.where((r) => r.type == 'قبل النوم').toList();

    double fastingAvg = fastingReadings.isNotEmpty
        ? fastingReadings.map((r) => r.value).reduce((a, b) => a + b) /
              fastingReadings.length
        : 0;

    double postMealAvg = postMealReadings.isNotEmpty
        ? postMealReadings.map((r) => r.value).reduce((a, b) => a + b) /
              postMealReadings.length
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
            'تحليل حسب النوع',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (fastingReadings.isNotEmpty)
            _buildTypeItem('صائم', fastingAvg, '70-100 mg/dL'),
          if (postMealReadings.isNotEmpty)
            _buildTypeItem('فاطر', postMealAvg, '< 140 mg/dL'),
          if (randomReadings.isNotEmpty)
            _buildTypeItem(
              'عشوائي',
              randomReadings.map((r) => r.value).reduce((a, b) => a + b) /
                  randomReadings.length,
              '< 200 mg/dL',
            ),
          if (bedtimeReadings.isNotEmpty)
            _buildTypeItem(
              'قبل النوم',
              bedtimeReadings.map((r) => r.value).reduce((a, b) => a + b) /
                  bedtimeReadings.length,
              '100-140 mg/dL',
            ),
        ],
      ),
    );
  }

  Widget _buildTypeItem(String type, double avg, String normal) {
    bool isNormal =
        (type == 'صائم' && avg <= 100) ||
        (type == 'فاطر' && avg < 140) ||
        (type == 'عشوائي' && avg < 200) ||
        (type == 'قبل النوم' && avg >= 100 && avg <= 140);

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
          Expanded(flex: 2, child: Text(type)),
          Expanded(
            child: Text(
              '${avg.toStringAsFixed(1)} mg/dL',
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
    double lowPercentage = (lowCount / readings.length) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.calories.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.calories.withOpacity(0.3)),
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
              '⚠️ ارتفاع متكرر في السكر',
              'ننصح بمراجعة طبيبك وتجنب السكريات.',
            ),
          if (lowPercentage > 10)
            _buildRecommendationItem(
              '⚠️ انخفاض متكرر في السكر',
              'احمل معك مصدر سكر سريع دائماً.',
            ),
          _buildRecommendationItem(
            '📊 انتظام القراءات',
            'حاول قياس السكر في نفس الأوقات يومياً.',
          ),
          _buildRecommendationItem(
            '💧 شرب الماء',
            'اشرب 8 أكواب ماء يومياً لتحسين القراءات.',
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
}
