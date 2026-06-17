import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:vita/screens/activities/activities_dashboard.dart';
import 'package:vita/screens/analysis/ai_dashboard.dart';
import 'package:vita/screens/analysis/water_dashboard.dart';
import 'package:vita/screens/chat/chat_main_screen.dart';
import 'package:vita/screens/medications/medications_dashboard.dart';
import 'package:vita/screens/notification_history_screen.dart';
import 'package:vita/screens/nutrition/nutrition_dashboard.dart';
import 'package:vita/screens/walking/walking_dashboard.dart';
import 'package:vita/screens/symptoms/symptoms_dashboard.dart';
import 'package:vita/screens/weight_tracking_screen.dart';
import 'package:vita/screens/diabetes/diabetes_tracking_screen.dart';
import 'package:vita/screens/predictive_prevention/predictive_prevention_dashboard.dart';
import 'package:vita/screens/community/community_main_screen.dart';
import 'package:vita/screens/dynamic_targets/dynamic_targets_dashboard.dart';
import 'package:vita/utils/prefs_helper.dart';
import 'package:vita/models/nutrition_model.dart';
import 'package:vita/services/nutrition_api.dart';
import '../constants/colors.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with SingleTickerProviderStateMixin {
  UserNutritionData? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _headerController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await NutritionService.getUserNutritionData();

      if (!mounted) return;

      setState(() {
        _userData = userData;
        _isLoading = false;
      });

      if (userData == null) {
        _loadLocalUserData();
      }
    } catch (e) {
      print('❌ خطأ في تحميل البيانات من API: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'فشل في تحميل البيانات من الخادم';
        _isLoading = false;
      });
      _loadLocalUserData();
    }
  }

  void _loadLocalUserData() {
    if (!mounted) return;

    try {
      final localData = PrefsHelper.getUserData();

      if (!mounted) return;

      setState(() {
        _userData = UserNutritionData(
          id: localData['id'] ?? 1,
          weight: (localData['weight'] ?? 70.0).toDouble(),
          height: (localData['height'] ?? 170.0).toDouble(),
          age: localData['age'] ?? 30,
          gender: localData['gender'] ?? 'ذكر',
          goal: localData['goal'] ?? 'تخسيس',
          activityLevel: localData['activityLevel'] ?? 'متوسط',
          weightLossRate: localData['weightLossRate'] ?? '0.5',
          targetWeight: (localData['targetWeight'] ?? 70.0).toDouble(),
          diseases: List<String>.from(localData['diseases'] ?? []),
          targetCalories: (localData['targetCalories'] ?? 2000.0).toDouble(),
          bmr: (localData['bmr'] ?? 1500.0).toDouble(),
          tdee: (localData['tdee'] ?? 2000.0).toDouble(),
          createdAt: DateTime.now(),
          waterIntake: (localData['waterIntake'] ?? 2.5).toDouble(),
        );
        _isLoading = false;
      });
    } catch (e) {
      print('❌ خطأ في تحميل البيانات المحلية: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'فشل في تحميل البيانات المحلية';
        _isLoading = false;
      });
    }
  }

  void _openWalkingScreen() {
    if (_userData == null) {
      _showErrorSnackBar('بيانات المستخدم غير متوفرة، يرجى إعادة المحاولة');
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WalkingDashboard(userData: _userData!),
      ),
    );
  }

  void _openNutritionScreen() {
    if (_userData == null) {
      _showErrorSnackBar('بيانات المستخدم غير متوفرة، يرجى إعادة المحاولة');
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NutritionDashboard(userData: _userData!),
      ),
    );
  }

  void _openSymptomsScreen() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SymptomsDashboard()),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<ServiceItem> _getFilteredServices(List<ServiceItem> allServices) {
    if (_searchQuery.isEmpty) return allServices;

    final query = _searchQuery.toLowerCase();
    return allServices.where((service) {
      return service.title.toLowerCase().contains(query) ||
          service.description.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'ابحث عن خدمة...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid(List<ServiceItem> allServices, ThemeData theme) {
    final filteredServices = _getFilteredServices(allServices);

    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد خدمات تطابق البحث',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب كلمات بحث أخرى',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
        children: List.generate(
          filteredServices.length,
          (index) => AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 600),
            columnCount: 2,
            child: ScaleAnimation(
              scale: 0.95,
              child: FadeInAnimation(
                child: _buildServiceCard(
                  service: filteredServices[index],
                  index: index,
                  theme: theme,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✅ ترتيب الخدمات حسب الأولوية والأهمية - إصدار محسن ومنظم
    final services = [
      // الفئة 1: المراقبة الحرجة والطارئة
      ServiceItem(
        title: 'المساعد الذكي',
        description: 'اسأل عن أي شيء صحي',
        icon: Icons.smart_toy,
        color: const Color(0xFF9C27B0), // Purple
        gradientColors: [const Color(0xFF9C27B0), const Color(0xFFE040FB)],
        onTap: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatMainScreen()),
          );
        },
        priority: 1,
      ),
      ServiceItem(
        title: 'الأدوية',
        description: 'تذكير ومتابعة مواعيد الأدوية',
        icon: Icons.medication,
        color: const Color(0xFFEC407A), // Pink
        gradientColors: [const Color(0xFFEC407A), const Color(0xFFF06292)],
        onTap: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MedicationsDashboard()),
          );
        },
        priority: 2,
      ),

      // الفئة 2: الإدارة اليومية للصحة
      ServiceItem(
        title: 'الأهداف الديناميكية',
        description: 'أهداف يومية مخصصة حسب أدائك وصحتك',
        icon: Icons.trending_up,
        color: const Color(0xFF00897B), // Teal
        gradientColors: [const Color(0xFF00897B), const Color(0xFF26A69A)],
        onTap: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DynamicTargetsDashboard()),
          );
        },
        priority: 4,
      ),
      ServiceItem(
        title: 'تتبع الماء',
        description: 'سجل كمية الماء اليومية',
        icon: Icons.local_drink,
        color: const Color(0xFF1E88E5), // Blue
        gradientColors: [const Color(0xFF1E88E5), const Color(0xFF42A5F5)],
        onTap: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WaterDashboard()),
          );
        },
        priority: 3,
      ),
      ServiceItem(
        title: 'النظام الغذائي',
        description: 'حساب السعرات واقتراح وجبات صحية',
        icon: Icons.restaurant,
        color: const Color(0xFF43A047), // Green
        gradientColors: [const Color(0xFF43A047), const Color(0xFF66BB6A)],
        onTap: _openNutritionScreen,
        requiresData: true,
        priority: 5,
      ),
      ServiceItem(
        title: 'المشي',
        description: 'تتبع الخطوات والنشاط البدني',
        icon: Icons.directions_walk,
        color: const Color(0xFF7CB342), // Light Green
        gradientColors: [const Color(0xFF7CB342), const Color(0xFF9CCC65)],
        onTap: _openWalkingScreen,
        requiresData: true,
        priority: 6,
      ),
      ServiceItem(
        title: 'تتبع الوزن',
        description: 'سجل وزنك بانتظام',
        icon: Icons.scale,
        color: const Color(0xFFFB8C00), // Orange
        gradientColors: [const Color(0xFFFB8C00), const Color(0xFFFFA726)],
        onTap: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WeightTrackingScreen()),
          );
        },
        priority: 7,
      ),

      // الفئة 3: التتبع والتحليل
      ServiceItem(
        title: 'الأعراض',
        description: 'سجل الأعراض الصحية وتحليلها',
        icon: Icons.sick,
        color: const Color(0xFF8D6E63), // Brown
        gradientColors: [const Color(0xFF8D6E63), const Color(0xFFA1887F)],
        onTap: _openSymptomsScreen,
        priority: 8,
      ),
      ServiceItem(
        title: 'الأنشطة',
        description: 'تتبع الأنشطة والتمارين اليومية',
        icon: Icons.analytics,
        color: const Color(0xFF5C6BC0), // Indigo
        gradientColors: [const Color(0xFF5C6BC0), const Color(0xFF7986CB)],
        onTap: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActivitiesDashboard()),
          );
        },
        priority: 9,
      ),
      ServiceItem(
        title: 'توصيات الذكاء الاصطناعي',
        description: 'توصيات صحية مخصصة بناءً على بياناتك',
        icon: Icons.insights,
        color: const Color(0xFF00ACC1), // Cyan
        gradientColors: [const Color(0xFF00ACC1), const Color(0xFF26C6DA)],
        onTap: () {
          if (!mounted) return;
          if (_userData == null) {
            _showErrorSnackBar('يرجى انتظار تحميل البيانات');
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AIDashboard()),
          );
        },
        priority: 10,
      ),

      // الفئة 4: المجتمع والتفاعل
      ServiceItem(
        title: 'المجتمع',
        description: 'تفاعل مع مستخدمين آخرين وشارك تجاربك',
        icon: Icons.people,
        color: const Color(0xFF5D4037), // Brown
        gradientColors: [const Color(0xFF5D4037), const Color(0xFF8D6E63)],
        onTap: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CommunityMainScreen()),
          );
        },
        priority: 11,
      ),

      // الفئة 5: الوقاية والتخطيط طويل المدى
      ServiceItem(
        title: 'التنبؤ الوقائي',
        description: 'تحليل المخاطر الصحية والوقاية',
        icon: Icons.health_and_safety,
        color: const Color(0xFF388E3C), // Dark Green
        gradientColors: [const Color(0xFF388E3C), const Color(0xFF4CAF50)],
        onTap: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PredictivePreventionDashboard(),
            ),
          );
        },
        priority: 12,
      ),
      if (_userData != null && _userData!.diseases.contains('السكري'))
        ServiceItem(
          title: 'تتبع السكري',
          description: 'إدارة مرض السكري بشكل متكامل',
          icon: Icons.bloodtype,
          color: const Color(0xFFC2185B), // Pink Red
          gradientColors: [const Color(0xFFC2185B), const Color(0xFFE91E63)],
          onTap: () {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiabetesTrackingScreen()),
            );
          },
          priority: 13,
        ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: FadeTransition(
            opacity: _headerAnimation,
            child: const Text('الخدمات الصحية'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadUserData,
              tooltip: 'تحديث البيانات',
            ),
            IconButton(
              icon: const Icon(Icons.notifications_active_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'جاري تحميل الخدمات...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : _errorMessage != null
              ? _buildError(theme)
              : Column(
                  children: [
                    _buildSearchBar(theme),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildServicesGrid(services, theme),
                      ),
                    ),
                  ],
                ),
        ),
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
              _errorMessage ?? 'فشل في تحميل البيانات',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadUserData,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loadLocalUserData,
                  icon: const Icon(Icons.storage, size: 18),
                  label: const Text('استخدام المحلي'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required ServiceItem service,
    required int index,
    required ThemeData theme,
  }) {
    final isDisabled = service.requiresData && _userData == null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled
                  ? () => _showErrorSnackBar('يرجى انتظار تحميل البيانات')
                  : () {
                      if (service.onTap != null) {
                        service.onTap!();
                      }
                    },
              borderRadius: BorderRadius.circular(24),
              splashColor: service.color.withOpacity(0.2),
              highlightColor: service.color.withOpacity(0.05),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDisabled
                        ? [theme.cardColor, theme.cardColor]
                        : service.gradientColors != null
                        ? [
                            service.gradientColors![0].withOpacity(0.15),
                            service.gradientColors![1].withOpacity(0.05),
                          ]
                        : [theme.cardColor, service.color.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDisabled
                        ? theme.colorScheme.onSurface.withOpacity(0.1)
                        : service.color.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDisabled
                          ? Colors.transparent
                          : service.color.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDisabled
                              ? [Colors.grey.shade400, Colors.grey.shade300]
                              : service.gradientColors != null
                              ? [
                                  service.gradientColors![0],
                                  service.gradientColors![1],
                                ]
                              : [service.color, service.color.withOpacity(0.8)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isDisabled
                                ? Colors.transparent
                                : service.color.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(service.icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        service.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDisabled
                              ? theme.colorScheme.onSurface.withOpacity(0.5)
                              : theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        service.description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isDisabled
                              ? theme.colorScheme.onSurface.withOpacity(0.4)
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Service Item Model
class ServiceItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;
  final bool requiresData;
  final int priority;

  ServiceItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.gradientColors,
    this.onTap,
    this.requiresData = false,
    required this.priority,
  });
}

// Dummy classes - replace with actual imports
class DeviceDashboard extends StatelessWidget {
  const DeviceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('القراءات الحيوية')));
  }
}
