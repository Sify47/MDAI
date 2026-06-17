import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../constants/colors.dart';
import '../../models/health_model.dart';
import 'add_sugar_reading.dart';
import 'sugar_history.dart';
import 'sugar_analysis.dart';

class SugarDashboard extends StatefulWidget {
  const SugarDashboard({Key? key}) : super(key: key);

  @override
  State<SugarDashboard> createState() => _SugarDashboardState();
}

class _SugarDashboardState extends State<SugarDashboard>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  // بيانات تجريبية
  final List<SugarReading> _recentReadings = [
    SugarReading(
      id: '1',
      value: 95,
      type: 'صائم',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    SugarReading(
      id: '2',
      value: 145,
      type: 'فاطر',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      mealDescription: 'غداء',
    ),
    SugarReading(
      id: '3',
      value: 110,
      type: 'قبل النوم',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🩸 تتبع السكر'),
          actions: [
            IconButton(
              icon: Icon(Icons.bar_chart, color: AppColors.calories),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SugarAnalysis(readings: _recentReadings),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FadeTransition(
              opacity: _controller,
              child: Column(
                children: [
                  // آخر قراءة
                  _buildLatestReading(),

                  const SizedBox(height: 16),

                  // إحصائيات سريعة
                  _buildQuickStats(),

                  const SizedBox(height: 16),

                  // المدى الطبيعي
                  _buildNormalRanges(),

                  const SizedBox(height: 16),

                  // قراءات اليوم
                  _buildTodayReadings(),

                  const SizedBox(height: 16),

                  // نصائح سريعة
                  _buildTips(),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddSugarReading()),
            );

            if (result != null) {
              // إضافة القراءة الجديدة للقائمة
              setState(() {
                // _recentReadings.insert(0, result);
              });
            }
          },
          backgroundColor: AppColors.calories,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLatestReading() {
    if (_recentReadings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('لا توجد قراءات بعد'),
            SizedBox(height: 4),
            Text('أضف أول قراءة لك'),
          ],
        ),
      );
    }

    final latest = _recentReadings.first;
    Color statusColor = latest.statusColor == 'danger'
        ? AppColors.danger
        : latest.statusColor == 'warning'
        ? AppColors.warning
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.calories, AppColors.calories.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.calories.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'آخر قراءة',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${latest.value.toStringAsFixed(0)} mg/dL',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  latest.status,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${latest.type} • ${_formatTime(latest.dateTime)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    // حساب الإحصائيات من البيانات
    int total = _recentReadings.length;
    int normal = _recentReadings.where((r) => r.status == 'طبيعي').length;
    int high = _recentReadings.where((r) => r.status.contains('مرتفع')).length;
    int low = _recentReadings.where((r) => r.status == 'منخفض').length;

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
            'إحصائيات سريعة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('إجمالي', total.toString(), AppColors.primary),
              _buildStatItem('طبيعي', normal.toString(), AppColors.success),
              _buildStatItem('مرتفع', high.toString(), AppColors.warning),
              _buildStatItem('منخفض', low.toString(), AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildNormalRanges() {
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
            'المدى الطبيعي للسكر',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRangeItem('صائم', '70-100 mg/dL', AppColors.success),
          _buildRangeItem(
            'فاطر (بعد ساعتين)',
            'أقل من 140 mg/dL',
            AppColors.success,
          ),
          _buildRangeItem('عشوائي', 'أقل من 200 mg/dL', AppColors.warning),
          _buildRangeItem('قبل النوم', '100-140 mg/dL', AppColors.success),
        ],
      ),
    );
  }

  Widget _buildRangeItem(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            range,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayReadings() {
    final today = DateTime.now();
    final todayReadings = _recentReadings
        .where(
          (r) =>
              r.dateTime.year == today.year &&
              r.dateTime.month == today.month &&
              r.dateTime.day == today.day,
        )
        .toList();

    if (todayReadings.isEmpty) {
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
        child: const Center(child: Text('لا توجد قراءات اليوم')),
      );
    }

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
            'قراءات اليوم',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...todayReadings.map(
            (reading) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(reading.status).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getStatusIcon(reading.status),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              title: Text('${reading.value.toStringAsFixed(0)} mg/dL'),
              subtitle: Text(
                '${reading.type} • ${_formatTime(reading.dateTime)}',
              ),
              trailing: Text(
                reading.status,
                style: TextStyle(
                  color: _getStatusColor(reading.status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.calories.withOpacity(0.05),
            AppColors.primary.withOpacity(0.05),
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
                'نصائح لمتابعة السكر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('⏰', 'قس السكر في نفس الوقت يومياً'),
          _buildTipItem('📝', 'سجل نوع وكمية الطعام مع القراءة'),
          _buildTipItem('💧', 'اشرب كمية كافية من الماء'),
          _buildTipItem('🚶', 'المشي بعد الأكل يساعد في خفض السكر'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String icon, String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
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
