import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'answer_details_screen.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> with TickerProviderStateMixin {
  // ✅ تغيير إلى TickerProviderStateMixin
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allFAQs = [
    {
      'category': 'السكري',
      'icon': '🩸',
      'color': AppColors.calories,
      'questions': [
        {
          'q': 'ما هو المعدل الطبيعي للسكر؟',
          'a':
              'يختلف المعدل الطبيعي حسب الحالة: للشخص السليم: صائم 70-100، بعد الأكل أقل من 140. لمريض السكري: صائم 80-130، بعد الأكل أقل من 180.',
        },
        {
          'q': 'كم مرة يجب قياس السكر؟',
          'a':
              'لمرضى السكري: قبل كل وجبة وقبل النوم (3-4 مرات يومياً). للشخص السليم: حسب إرشادات الطبيب.',
        },
        {
          'q': 'ما هي أعراض ارتفاع السكر؟',
          'a':
              'العطش الشديد، كثرة التبول، الجوع المستمر، جفاف الفم، زغللة العين، تعب عام.',
        },
        {
          'q': 'ما هي أعراض انخفاض السكر؟',
          'a': 'دوخة، عرق غزير، رعشة، جوع شديد، تسارع ضربات القلب، تشوش ذهني.',
        },
        {
          'q': 'هل المشي مفيد لمرضى السكر؟',
          'a': 'نعم، المشي المنتظم يساعد في خفض السكر وتحسين حساسية الأنسولين.',
        },
      ],
    },
    {
      'category': 'الضغط',
      'icon': '💓',
      'color': AppColors.danger,
      'questions': [
        {
          'q': 'ما هو ضغط الدم الطبيعي؟',
          'a': 'الضغط الطبيعي أقل من 120/80. الضغط المرتفع 130-139/80-89.',
        },
        {
          'q': 'ما هي أعراض ارتفاع الضغط؟',
          'a': 'صداع، دوخة، زغللة، طنين في الأذن، نزيف أنف، خفقان.',
        },
        {
          'q': 'هل القهوة ترفع الضغط؟',
          'a':
              'نعم، الكافيين قد يرفع الضغط مؤقتاً. يفضل تقليل الكافيين لمرضى الضغط.',
        },
        {
          'q': 'كيف أخفض ضغط الدم بسرعة؟',
          'a':
              'استرخِ في مكان هادئ، تنفس بعمق، تجنب الملح، استشر طبيبك فوراً إذا كان مرتفع جداً.',
        },
      ],
    },
    {
      'category': 'الأدوية',
      'icon': '💊',
      'color': AppColors.medications,
      'questions': [
        {
          'q': 'ما هي استخدامات دواء جلوكوفاج؟',
          'a':
              'علاج السكري من النوع الثاني، خفض السكر، تحسين حساسية الأنسولين.',
        },
        {
          'q': 'ما هي الآثار الجانبية للستاتين؟',
          'a':
              'آلام عضلات، صداع، غثيان، اضطرابات هضمية. استشر طبيبك إذا استمرت.',
        },
        {
          'q': 'ماذا أفعل إذا نسيت جرعة الدواء؟',
          'a':
              'خذها فور تذكرك إلا إذا كان موعد الجرعة التالية قريباً. لا تضاعف الجرعة.',
        },
      ],
    },
    {
      'category': 'التغذية',
      'icon': '🍎',
      'color': AppColors.success,
      'questions': [
        {
          'q': 'ما هي الأكلات الممنوعة لمرضى الضغط؟',
          'a': 'الأطعمة المالحة، المخللات، الأطعمة المعلبة، الوجبات السريعة.',
        },
        {
          'q': 'ما هي الأكلات المفيدة للسكري؟',
          'a': 'الخضروات، الحبوب الكاملة، البقوليات، الأسماك، المكسرات.',
        },
        {
          'q': 'هل الموز مفيد لمرضى الضغط؟',
          'a': 'نعم، الموز غني بالبوتاسيوم المفيد لخفض الضغط، لكن باعتدال.',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFAQs {
    if (_searchQuery.isEmpty) {
      return _allFAQs;
    }

    return _allFAQs
        .map((category) {
          final filteredQuestions = (category['questions'] as List).where((q) {
            return q['q'].contains(_searchQuery) ||
                q['a'].contains(_searchQuery);
          }).toList();

          return {
            'category': category['category'],
            'icon': category['icon'],
            'color': category['color'],
            'questions': filteredQuestions,
          };
        })
        .where((category) => (category['questions'] as List).isNotEmpty)
        .toList();
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
          title: Text('📋 الأسئلة الشائعة'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'السكري'),
              Tab(text: 'الضغط'),
              Tab(text: 'الأدوية'),
              Tab(text: 'التغذية'),
            ],
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: theme.textTheme.bodyMedium,
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // شريط البحث
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.08),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن سؤال...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.primary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.5,
                                ),
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
                        vertical: 12,
                      ),
                    ),
                    style: theme.textTheme.bodyMedium,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),

              // قائمة الأسئلة
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _searchQuery.isEmpty
                      ? TabBarView(
                          controller: _tabController,
                          children: [
                            _buildFAQCategory(_allFAQs[0], theme),
                            _buildFAQCategory(_allFAQs[1], theme),
                            _buildFAQCategory(_allFAQs[2], theme),
                            _buildFAQCategory(_allFAQs[3], theme),
                          ],
                        )
                      : _filteredFAQs.isEmpty
                      ? _buildEmptySearchState(theme)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredFAQs.length,
                          itemBuilder: (context, index) {
                            return _buildFAQCategory(
                              _filteredFAQs[index],
                              theme,
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لم نعثر على أي سؤال مطابق لبحثك',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('مسح البحث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCategory(Map<String, dynamic> category, ThemeData theme) {
    final categoryColor =
        category['color'] as Color? ?? theme.colorScheme.primary;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: category['questions'].length,
      itemBuilder: (context, index) {
        final question = category['questions'][index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, opacity, child) {
            return FadeTransition(
              opacity: AlwaysStoppedAnimation(opacity),
              child: Transform.translate(
                offset: Offset(0, 15 * (1 - opacity)),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnswerDetailsScreen(
                            question: question['q'],
                            answer: question['a'],
                            category: category['category'],
                            icon: category['icon'],
                            categoryColor: categoryColor,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                category['icon'],
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  question['q'],
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  question['a'].length > 70
                                      ? '${question['a'].substring(0, 70)}...'
                                      : question['a'],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
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
          },
        );
      },
    );
  }
}
