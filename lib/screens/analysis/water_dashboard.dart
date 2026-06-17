// lib/screens/water/water_dashboard.dart

import 'package:flutter/material.dart';
import 'package:vita/services/water_service.dart';
import 'package:vita/widgets/water_dashboard/water_progress_card.dart';
import 'package:vita/widgets/water_dashboard/water_quick_add_card.dart';
import 'package:vita/widgets/water_dashboard/water_today_intakes.dart';
import 'package:vita/widgets/water_dashboard/water_stats_chart.dart';
import 'package:vita/widgets/water_dashboard/water_tips_card.dart';
import '../../constants/colors.dart';

class WaterDashboard extends StatefulWidget {
  const WaterDashboard({Key? key}) : super(key: key);

  @override
  State<WaterDashboard> createState() => _WaterDashboardState();
}

class _WaterDashboardState extends State<WaterDashboard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _waterAnimation;

  Map<String, dynamic> _todayData = {};
  Map<String, dynamic> _statsData = {};
  List<Map<String, dynamic>> _intakes = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week';
  double _cupSize = 0.25;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _waterAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadTodayData(), _loadStatsData()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadTodayData() async {
    final data = await WaterService.getTodayWater();
    if (data != null && mounted) {
      setState(() {
        _todayData = data;
        _intakes = List<Map<String, dynamic>>.from(data['intakes'] ?? []);
        _cupSize = (data['cup_size'] ?? 0.25).toDouble();
      });
    }
  }

  Future<void> _loadStatsData() async {
    final data = await WaterService.getWaterStats(_selectedPeriod);
    if (data != null && mounted) {
      setState(() => _statsData = data);
    }
  }

  Future<void> _logWater(double amount) async {
    final result = await WaterService.logWater(amount);
    if (result['success'] == true) {
      await _loadTodayData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم تسجيل ${amount.toStringAsFixed(1)} لتر'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    _loadStatsData();
  }

  void _showCustomAmountDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('كمية الماء'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'أدخل الكمية باللتر',
            suffixText: 'لتر',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                _logWater(amount);
                Navigator.pop(context);
              }
            },
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIntake(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التسجيل'),
        content: const Text('هل أنت متأكد من حذف هذا التسجيل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await WaterService.deleteWaterIntake(id);
      if (result['success'] == true) {
        await _loadTodayData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم حذف التسجيل'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = (_todayData['total'] ?? 0.0).toDouble();
    final goal = (_todayData['daily_goal'] ?? 2.5).toDouble();
    final progress = goal > 0 ? (total / goal).clamp(0.0, 1.0) : 0.0;
    final recommendationReason = _todayData['recommendation_reason'] ?? '';
    final stats = _statsData['stats'] ?? [];
    final dailyGoal = (_statsData['daily_goal'] ?? 2.5).toDouble();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('💧 شرب الماء'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    WaterProgressCard(
                      total: total,
                      goal: goal,
                      progress: progress,
                      reason: recommendationReason,
                    ),
                    const SizedBox(height: 16),
                    WaterQuickAddCard(
                      cupSize: _cupSize,
                      onLogWater: _logWater,
                      onShowCustomDialog: _showCustomAmountDialog,
                    ),
                    const SizedBox(height: 16),
                    WaterTodayIntakes(
                      intakes: _intakes,
                      onDeleteIntake: _deleteIntake,
                    ),
                    const SizedBox(height: 16),
                    WaterStatsChart(
                      stats: stats,
                      dailyGoal: dailyGoal,
                      selectedPeriod: _selectedPeriod,
                      onPeriodChanged: _onPeriodChanged,
                    ),
                    const SizedBox(height: 16),
                    const WaterTipsCard(),
                  ],
                ),
              ),
      ),
    );
  }
}
