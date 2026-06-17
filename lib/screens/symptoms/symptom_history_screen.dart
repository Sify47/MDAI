// lib/screens/symptoms/symptom_history_screen.dart

import 'package:flutter/material.dart';
import 'package:vita/constants/colors.dart';
import 'package:vita/services/symptom_api.dart';
import 'package:vita/models/symptom_model.dart';
import 'package:vita/screens/symptoms/symptom_detail_screen.dart';

class SymptomHistoryScreen extends StatefulWidget {
  const SymptomHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SymptomHistoryScreen> createState() => _SymptomHistoryScreenState();
}

class _SymptomHistoryScreenState extends State<SymptomHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  List<Symptom> _allSymptoms = [];
  List<Symptom> _filteredSymptoms = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedSeverity = 'الكل';
  String _selectedPeriod = 'الكل';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
    _loadSymptoms();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSymptoms() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final symptoms = await SymptomService.getSymptoms(limit: 100);

      if (!mounted) return;

      setState(() {
        _allSymptoms = symptoms;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'فشل في تحميل الأعراض';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredSymptoms = List.from(_allSymptoms);

    if (_selectedSeverity != 'الكل') {
      _filteredSymptoms = _filteredSymptoms
          .where((s) => s.severity == _selectedSeverity)
          .toList();
    }

    if (_selectedPeriod != 'الكل') {
      final now = DateTime.now();
      _filteredSymptoms = _filteredSymptoms.where((s) {
        switch (_selectedPeriod) {
          case 'آخر أسبوع':
            return s.dateTime.isAfter(now.subtract(const Duration(days: 7)));
          case 'آخر شهر':
            return s.dateTime.isAfter(now.subtract(const Duration(days: 30)));
          case 'آخر 3 شهور':
            return s.dateTime.isAfter(now.subtract(const Duration(days: 90)));
          default:
            return true;
        }
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      _filteredSymptoms = _filteredSymptoms
          .where((s) => s.name.contains(_searchQuery))
          .toList();
    }

    _filteredSymptoms.sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  void _updateFilter(String severity, String period) {
    setState(() {
      _selectedSeverity = severity;
      _selectedPeriod = period;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? theme.scaffoldBackgroundColor
            : AppColors.background,
        appBar: AppBar(
          title: Text('📋 تاريخ الأعراض'),
          actions: [
            IconButton(
              icon: Icon(Icons.filter_list, color: theme.colorScheme.primary),
              onPressed: () => _showFilterDialog(context, theme),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              onPressed: _loadSymptoms,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(theme),
              _buildStatsBar(theme),
              Expanded(
                child: _isLoading
                    ? _buildLoading(theme)
                    : _errorMessage != null
                    ? _buildError(theme)
                    : _filteredSymptoms.isEmpty
                    ? _buildEmptyState(theme)
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildSymptomsList(theme),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
        decoration: InputDecoration(
          hintText: 'بحث عن عرض...',
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.06),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip(
            'إجمالي',
            '${_filteredSymptoms.length}',
            theme.colorScheme.primary,
            theme,
          ),
          _buildStatChip(
            'خفيف',
            '${_filteredSymptoms.where((s) => s.severity == 'خفيف').length}',
            AppColors.success,
            theme,
          ),
          _buildStatChip(
            'متوسط',
            '${_filteredSymptoms.where((s) => s.severity == 'متوسط').length}',
            AppColors.warning,
            theme,
          ),
          _buildStatChip(
            'شديد',
            '${_filteredSymptoms.where((s) => s.severity == 'شديد').length}',
            AppColors.danger,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String count,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الأعراض...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حدث خطأ',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSymptoms,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد أعراض مسجلة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'قم بإضافة أول عرض الآن',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة عرض جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSymptom(Symptom symptom, int index) async {
    try {
      await SymptomService.deleteSymptom(symptom.id);
      if (!mounted) return;
      setState(() {
        _allSymptoms.removeAt(index);
        _applyFilters();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حذف "${symptom.name}"'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ فشل في الحذف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSymptomsList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadSymptoms,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredSymptoms.length,
        itemBuilder: (context, index) {
          final symptom = _filteredSymptoms[index];
          return _buildSymptomCard(symptom, index, theme);
        },
      ),
    );
  }

  Widget _buildSymptomCard(Symptom symptom, int index, ThemeData theme) {
    Color severityColor = symptom.getSeverityColor();

    return Dismissible(
      key: ValueKey(symptom.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل تريد حذف "${symptom.name}"؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteSymptom(symptom, index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (index * 50)),
        curve: Curves.easeOutCubic,
        builder: (context, opacity, child) {
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - opacity)),
              child: child,
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: severityColor.withOpacity(0.2), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SymptomDetailScreen(symptom: symptom),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // أيقونة العرض
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        symptom.icon ?? '🤒',
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // المحتوى
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symptom.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.4,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${symptom.dateTime.year}/${symptom.dateTime.month.toString().padLeft(2, '0')}/${symptom.dateTime.day.toString().padLeft(2, '0')} • '
                              '${symptom.dateTime.hour.toString().padLeft(2, '0')}:${symptom.dateTime.minute.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (symptom.notes != null && symptom.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              symptom.notes!.length > 40
                                  ? '${symptom.notes!.substring(0, 40)}...'
                                  : symptom.notes!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // شارة الشدة
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
                      symptom.severity,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: severityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, ThemeData theme) {
    String tempSeverity = _selectedSeverity;
    String tempPeriod = _selectedPeriod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'تصفية حسب',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('شدة العرض'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('الكل', tempSeverity == 'الكل', (
                        selected,
                      ) {
                        setState(() => tempSeverity = 'الكل');
                      }, theme),
                      _buildFilterChip('خفيف', tempSeverity == 'خفيف', (
                        selected,
                      ) {
                        setState(() => tempSeverity = 'خفيف');
                      }, theme),
                      _buildFilterChip('متوسط', tempSeverity == 'متوسط', (
                        selected,
                      ) {
                        setState(() => tempSeverity = 'متوسط');
                      }, theme),
                      _buildFilterChip('شديد', tempSeverity == 'شديد', (
                        selected,
                      ) {
                        setState(() => tempSeverity = 'شديد');
                      }, theme),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text('الفترة'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('الكل', tempPeriod == 'الكل', (
                        selected,
                      ) {
                        setState(() => tempPeriod = 'الكل');
                      }, theme),
                      _buildFilterChip('آخر أسبوع', tempPeriod == 'آخر أسبوع', (
                        selected,
                      ) {
                        setState(() => tempPeriod = 'آخر أسبوع');
                      }, theme),
                      _buildFilterChip('آخر شهر', tempPeriod == 'آخر شهر', (
                        selected,
                      ) {
                        setState(() => tempPeriod = 'آخر شهر');
                      }, theme),
                      _buildFilterChip(
                        'آخر 3 شهور',
                        tempPeriod == 'آخر 3 شهور',
                        (selected) {
                          setState(() => tempPeriod = 'آخر 3 شهور');
                        },
                        theme,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(color: theme.colorScheme.outline),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _updateFilter(tempSeverity, tempPeriod);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('تطبيق'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    bool selected,
    Function(bool) onSelected,
    ThemeData theme,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(0.6),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
