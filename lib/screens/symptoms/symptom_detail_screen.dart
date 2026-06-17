// lib/screens/symptoms/symptom_detail_screen.dart

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/symptom_model.dart';
import '../../services/symptom_api.dart';
import '../../services/integration/symptom_cause_analyzer.dart';
import '../../widgets/integration/ai_cause_breakdown_widget.dart';
import 'edit_symptom_screen.dart';
import 'symptom_analysis_screen.dart';

class SymptomDetailScreen extends StatefulWidget {
  final Symptom symptom;

  const SymptomDetailScreen({Key? key, required this.symptom})
    : super(key: key);

  @override
  State<SymptomDetailScreen> createState() => _SymptomDetailScreenState();
}

class _SymptomDetailScreenState extends State<SymptomDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  Symptom? _symptom;
  bool _isLoading = false;

  CauseAnalysisResult? _causeAnalysisResult;
  bool _causeAnalysisLoading = false;

  @override
  void initState() {
    super.initState();
    _symptom = widget.symptom;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
    _loadCauseAnalysis();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ThemeData get theme => Theme.of(context);

  Future<void> _deleteSymptom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmDialog(context),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    final result = await SymptomService.deleteSymptom(_symptom!.id);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🗑️ تم حذف العرض'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, 'deleted');
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['message']}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDeleteConfirmDialog(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'حذف العرض',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${_symptom!.name}"؟\nلا يمكن استرجاع العرض بعد الحذف.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSymptomScreen(symptom: _symptom!),
      ),
    );

    if (result != null && mounted) {
      if (result == 'deleted') {
        Navigator.pop(context, 'deleted');
      } else if (result is Symptom) {
        setState(() {
          _symptom = result;
        });
      } else {
        // Refresh from API
        final updated = await SymptomService.getSymptomById(_symptom!.id);
        if (updated != null && mounted) {
          setState(() {
            _symptom = updated;
          });
        }
      }
    }
  }

  Future<void> _navigateToAnalysis() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SymptomAnalysisScreen(
          symptomData: {
            'id': _symptom!.id,
            'symptom': _symptom!.name,
            'severity': _symptom!.severity,
            'date':
                '${_symptom!.dateTime.year}/${_symptom!.dateTime.month}/${_symptom!.dateTime.day}',
            'time':
                '${_symptom!.dateTime.hour}:${_symptom!.dateTime.minute.toString().padLeft(2, '0')}',
            'icon': _symptom!.icon ?? '🤒',
            'color': _symptom!.getSeverityColor(),
            'analysis': _symptom!.analysis,
            'possible_causes': _symptom!.possibleCauses,
            'suggested_actions': _symptom!.suggestedActions,
            'warning_signs': _symptom!.warningSigns,
            'food_recommendations': _symptom!.foodRecommendations,
          },
        ),
      ),
    );
  }

  Future<void> _loadCauseAnalysis() async {
    if (_symptom == null) return;
    try {
      setState(() => _causeAnalysisLoading = true);
      final result = await SymptomCauseAnalyzer.analyze(
        symptomName: _symptom!.name,
        severity: _symptom!.severity,
        occurredAt: _symptom!.dateTime,
      );
      if (mounted) {
        setState(() {
          _causeAnalysisResult = result;
          _causeAnalysisLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cause analysis: $e');
      if (mounted) {
        setState(() => _causeAnalysisLoading = false);
      }
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          title: Text('📋 تفاصيل العرض'),
          actions: [
            IconButton(
              icon: Icon(Icons.edit, color: theme.colorScheme.primary),
              onPressed: _isLoading ? null : _navigateToEdit,
              tooltip: 'تعديل',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _isLoading ? null : _deleteSymptom,
              tooltip: 'حذف',
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? _buildLoading()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSeverityHeader(),
                        const SizedBox(height: 16),
                        _buildSymptomTitleCard(),
                        const SizedBox(height: 16),
                        _buildDateTimeCard(),
                        const SizedBox(height: 16),
                        if (_symptom!.notes != null &&
                            _symptom!.notes!.isNotEmpty)
                          _buildNotesCard(),
                        if (_symptom!.notes != null &&
                            _symptom!.notes!.isNotEmpty)
                          const SizedBox(height: 16),
                        if (_symptom!.analysis != null &&
                            _symptom!.analysis!.isNotEmpty)
                          _buildAnalysisCard(),
                        if (_symptom!.analysis != null &&
                            _symptom!.analysis!.isNotEmpty)
                          const SizedBox(height: 16),
                        if (_symptom!.possibleCauses != null &&
                            _symptom!.possibleCauses!.isNotEmpty)
                          _buildPossibleCausesCard(),
                        if (_symptom!.possibleCauses != null &&
                            _symptom!.possibleCauses!.isNotEmpty)
                          const SizedBox(height: 16),
                        if (_symptom!.suggestedActions != null &&
                            _symptom!.suggestedActions!.isNotEmpty)
                          _buildSuggestedActionsCard(),
                        if (_symptom!.suggestedActions != null &&
                            _symptom!.suggestedActions!.isNotEmpty)
                          const SizedBox(height: 16),
                        if (_symptom!.warningSigns != null &&
                            _symptom!.warningSigns!.isNotEmpty)
                          _buildWarningSignsCard(),
                        if (_symptom!.warningSigns != null &&
                            _symptom!.warningSigns!.isNotEmpty)
                          const SizedBox(height: 16),
                        if (_symptom!.foodRecommendations != null &&
                            _symptom!.foodRecommendations!.isNotEmpty)
                          _buildFoodRecommendationsCard(),
                        if (_symptom!.foodRecommendations != null &&
                            _symptom!.foodRecommendations!.isNotEmpty)
                          const SizedBox(height: 16),
                        _buildAICauseBreakdownCard(),
                        if (!_causeAnalysisLoading &&
                            _causeAnalysisResult != null)
                          const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityHeader() {
    final severityColor = _symptom!.getSeverityColor();
    String severityText;
    IconData severityIcon;

    switch (_symptom!.severity) {
      case 'خفيف':
        severityText = 'خفيف - لا يستدعي القلق';
        severityIcon = Icons.check_circle_outline;
        break;
      case 'متوسط':
        severityText = 'متوسط - يستدعي المراقبة';
        severityIcon = Icons.warning_amber;
        break;
      case 'شديد':
        severityText = 'شديد - يستدعي العناية';
        severityIcon = Icons.error_outline;
        break;
      default:
        severityText = _symptom!.severity;
        severityIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(severityIcon, color: severityColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              severityText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: severityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomTitleCard() {
    final severityColor = _symptom!.getSeverityColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _symptom!.icon ?? '🤒',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _symptom!.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _symptom!.severity,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 الوقت والتاريخ',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateTimeItem(
                  icon: Icons.calendar_today,
                  color: AppColors.primary,
                  label: 'التاريخ',
                  value: _formatDate(_symptom!.dateTime),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTimeItem(
                  icon: Icons.access_time,
                  color: AppColors.warning,
                  label: 'الوقت',
                  value: _formatTime(_symptom!.dateTime),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '📝 ملاحظات',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _symptom!.notes!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '🔍 التحليل',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _symptom!.analysis!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPossibleCausesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                '🔎 الأسباب المحتملة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_symptom!.possibleCauses!.map(
            (cause) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      cause,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSuggestedActionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                '💡 الإجراءات الموصى بها',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_symptom!.suggestedActions!.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.success,
                      size: 12,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      action,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildWarningSignsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withOpacity(0.05),
            AppColors.danger.withOpacity(0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: AppColors.danger,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '⚠️ علامات التحذير',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_symptom!.warningSigns!.map(
            (sign) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.priority_high,
                      color: AppColors.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sign,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFoodRecommendationsCard() {
    final foodRecs = _symptom!.foodRecommendations!;
    final foodsToEat = (foodRecs['foods_to_eat'] as List?) ?? [];
    final foodsToAvoid = (foodRecs['foods_to_avoid'] as List?) ?? [];
    final drinksRecommended = (foodRecs['drinks_recommended'] as List?) ?? [];
    final drinksToAvoid = (foodRecs['drinks_to_avoid'] as List?) ?? [];
    final generalTips = foodRecs['general_tips'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.05),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '🍽️ التوصيات الغذائية',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (foodsToEat.isNotEmpty)
            _buildFoodSection(
              title: '🥗 أطعمة موصى بها',
              items: foodsToEat,
              color: AppColors.success,
              icon: Icons.check_circle_outline,
            ),
          if (foodsToEat.isNotEmpty && foodsToAvoid.isNotEmpty)
            const SizedBox(height: 12),
          if (foodsToAvoid.isNotEmpty)
            _buildFoodSection(
              title: '🚫 أطعمة يجب تجنبها',
              items: foodsToAvoid,
              color: AppColors.danger,
              icon: Icons.block,
            ),
          if ((foodsToEat.isNotEmpty || foodsToAvoid.isNotEmpty) &&
              drinksRecommended.isNotEmpty)
            const SizedBox(height: 12),
          if (drinksRecommended.isNotEmpty)
            _buildFoodSection(
              title: '🥤 مشروبات موصى بها',
              items: drinksRecommended,
              color: AppColors.primary,
              icon: Icons.local_drink,
            ),
          if (drinksRecommended.isNotEmpty && drinksToAvoid.isNotEmpty)
            const SizedBox(height: 12),
          if (drinksToAvoid.isNotEmpty)
            _buildFoodSection(
              title: '☕ مشروبات يجب تجنبها',
              items: drinksToAvoid,
              color: AppColors.danger,
              icon: Icons.no_drinks,
            ),
          if (generalTips != null && generalTips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        generalTips,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodSection({
    required String title,
    required List items,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        item.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAICauseBreakdownCard() {
    if (_causeAnalysisLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text(
              '🧠 جاري تحليل الأسباب المحتملة...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_causeAnalysisResult == null ||
        !_causeAnalysisResult!.hasSufficientData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology_outlined, color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '🧠 التحليل الذكي',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _causeAnalysisResult == null
                  ? 'تعذر تحليل الأسباب المحتملة حالياً. قد يكون ذلك بسبب نقص البيانات المتاحة.'
                  : 'البيانات المتاحة غير كافية لتحليل دقيق. يرجى إضافة المزيد من التفاصيل عن الأعراض.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_causeAnalysisResult != null && _causeAnalysisResult!.factors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'العوامل المتاحة: ${_causeAnalysisResult!.factors.where((f) => f.score >= 0).length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _causeAnalysisResult = null);
                  _loadCauseAnalysis();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('إعادة المحاولة'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.info,
                  side: BorderSide(color: AppColors.info.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AICauseBreakdownWidget(result: _causeAnalysisResult!);
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // View Full Analysis button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _navigateToAnalysis,
            icon: const Icon(Icons.analytics_outlined, size: 20),
            label: const Text('عرض التحليل الكامل'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Edit button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _navigateToEdit,
            icon: Icon(
              Icons.edit_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'تعديل العرض',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Delete button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _deleteSymptom,
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.danger,
            ),
            label: const Text(
              'حذف العرض',
              style: TextStyle(color: AppColors.danger),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
