import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../constants/colors.dart';
import '../../models/health_model.dart';
import 'add_pressure_reading.dart';
import 'pressure_history.dart';
import 'pressure_analysis.dart';

class PressureDashboard extends StatefulWidget {
  const PressureDashboard({Key? key}) : super(key: key);

  @override
  State<PressureDashboard> createState() => _PressureDashboardState();
}

class _PressureDashboardState extends State<PressureDashboard>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  // بيانات تجريبية
  final List<PressureReading> _recentReadings = [
    PressureReading(
      id: '1',
      systolic: 120,
      diastolic: 80,
      pulse: 72,
      position: 'جالس',
      arm: 'أيمن',
      dateTime: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PressureReading(
      id: '2',
      systolic: 135,
      diastolic: 85,
      pulse: 75,
      position: 'واقف',
      arm: 'أيسر',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PressureReading(
      id: '3',
      systolic: 115,
      diastolic: 75,
      pulse: 70,
      position: 'جالس',
      arm: 'أيمن',
      dateTime: DateTime.now().subtract(const Duration(days: 2)),
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
          title: const Text('💓 تتبع الضغط'),
          actions: [
            IconButton(
              icon: Icon(Icons.bar_chart, color: AppColors.danger),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PressureAnalysis(readings: _recentReadings),
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
              MaterialPageRoute(
                builder: (context) => const AddPressureReading(),
              ),
            );

            if (result != null) {
              // إضافة القراءة الجديدة للقائمة
              setState(() {
                // _recentReadings.insert(0, result);
              });
            }
          },
          backgroundColor: AppColors.danger,
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
          colors: [AppColors.danger, AppColors.danger.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withOpacity(0.3),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${latest.systolic}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '/',
                style: TextStyle(color: Colors.white, fontSize: 48),
              ),
              Text(
                '${latest.diastolic}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                'النبض: ${latest.pulse ?? '-'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
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
            'المدى الطبيعي للضغط',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRangeItem('طبيعي', 'أقل من 120/80', AppColors.success),
          _buildRangeItem('مرتفع طبيعي', '120-129/80-84', AppColors.success),
          _buildRangeItem('مرتفع قليلاً', '130-139/85-89', AppColors.warning),
          _buildRangeItem('مرتفع', '140-179/90-119', AppColors.danger),
          _buildRangeItem('مرتفع جداً', '180+/120+', AppColors.danger),
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
                  child: Icon(
                    Icons.favorite,
                    color: _getStatusColor(reading.status),
                    size: 20,
                  ),
                ),
              ),
              title: Text('${reading.systolic}/${reading.diastolic}'),
              subtitle: Text(
                '${reading.position} • ${_formatTime(reading.dateTime)}',
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
            AppColors.danger.withOpacity(0.05),
            AppColors.primary.withOpacity(0.05),
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
                'نصائح لمرضى الضغط',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('🧂', 'قلل الملح في الطعام (أقل من 5 جرام يومياً)'),
          _buildTipItem('🥦', 'تناول الخضروات والفواكه بكثرة'),
          _buildTipItem('🚶', 'مارس المشي 30 دقيقة يومياً'),
          _buildTipItem('☕', 'قلل من الكافيين (القهوة - الشاي)'),
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
      case 'مرتفع جداً':
        return AppColors.danger;
      case 'مرتفع قليلاً':
      case 'مرتفع طبيعي':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }
}
