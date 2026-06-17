import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/theme_provider.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late ThemeProvider _themeProvider;

  // ✅ متغيرات محلية (الوضع الليلي فقط)
  late bool _localIsDarkMode;

  // ✅ خيارات اللغة (سيتم تطبيقها لاحقاً)
  late String _localLanguage;

  final List<Map<String, dynamic>> _languageOptions = [
    {'name': 'العربية', 'code': 'ar', 'flag': '🇸🇦'},
    {'name': 'English', 'code': 'en', 'flag': '🇬🇧'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      _loadCurrentSettings();
    });
  }

  void _loadCurrentSettings() {
    setState(() {
      _localIsDarkMode = _themeProvider.isDarkMode;
      _localLanguage = _themeProvider.language;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    await _themeProvider.updateSettings(
      isDarkMode: _localIsDarkMode,
      language: _localLanguage,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ تم حفظ الإعدادات بنجاح'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context, true);
  }

  void _cancelChanges() {
    _loadCurrentSettings();
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? Colors.white70
        : AppColors.textSecondary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('⚙️ الإعدادات'),
          actions: [
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'حفظ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _controller,
              child: Column(
                children: [
                  // ✅ معاينة حية مبسطة
                  _buildPreview(isDark, textColor),

                  const SizedBox(height: 20),

                  // ✅ الوضع الليلي
                  _buildDarkModeCard(
                    isDark,
                    cardColor!,
                    textColor,
                    textSecondaryColor,
                  ),

                  const SizedBox(height: 20),

                  // ✅ اللغة
                  _buildLanguageCard(
                    isDark,
                    cardColor,
                    textColor,
                    textSecondaryColor,
                  ),

                  const SizedBox(height: 30),

                  // ✅ أزرار الإجراءات
                  _buildActionButtons(isDark, cardColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // معاينة حية مبسطة
  // ============================================
  Widget _buildPreview(bool isDark, Color textColor) {
    final primaryColor = _getPrimaryColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'معاينة المظهر',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _localIsDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localIsDarkMode ? 'الوضع الليلي' : 'الوضع النهاري',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _localIsDarkMode
                            ? 'ألوان داكنة مريحة للعين'
                            : 'ألوان فاتحة مشرقة',
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'معاينة',
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
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

  // ============================================
  // كارد الوضع الليلي
  // ============================================
  Widget _buildDarkModeCard(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color textSecondaryColor,
  ) {
    final primaryColor = _getPrimaryColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _localIsDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'المظهر',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'اختر المظهر المناسب لعينيك',
                      style: TextStyle(fontSize: 12, color: textSecondaryColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _localIsDarkMode ? '🌙 داكن' : '☀️ فاتح',
                  style: TextStyle(
                    fontSize: 11,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _localIsDarkMode = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_localIsDarkMode
                          ? primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_localIsDarkMode
                            ? primaryColor
                            : Colors.grey.withOpacity(0.3),
                        width: !_localIsDarkMode ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          size: 32,
                          color: !_localIsDarkMode
                              ? primaryColor
                              : textSecondaryColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'فاتح',
                          style: TextStyle(
                            color: !_localIsDarkMode
                                ? primaryColor
                                : textSecondaryColor,
                            fontWeight: !_localIsDarkMode
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _localIsDarkMode = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _localIsDarkMode
                          ? primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _localIsDarkMode
                            ? primaryColor
                            : Colors.grey.withOpacity(0.3),
                        width: _localIsDarkMode ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          size: 32,
                          color: _localIsDarkMode
                              ? primaryColor
                              : textSecondaryColor,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'داكن',
                          style: TextStyle(
                            color: _localIsDarkMode
                                ? primaryColor
                                : textSecondaryColor,
                            fontWeight: _localIsDarkMode
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // كارد اللغة
  // ============================================
  Widget _buildLanguageCard(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color textSecondaryColor,
  ) {
    final primaryColor = _getPrimaryColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.language, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اللغة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'اختر اللغة المفضلة',
                      style: TextStyle(fontSize: 12, color: textSecondaryColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'قريباً',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: _languageOptions.map((lang) {
              final isSelected = _localLanguage == lang['code'];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    // ✅ سيتم تفعيل تغيير اللغة لاحقاً
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔧 سيتم إضافة دعم اللغة قريباً'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          lang['flag'],
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang['name'],
                          style: TextStyle(
                            color: isSelected
                                ? primaryColor
                                : textSecondaryColor,
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================
  // أزرار الإجراءات
  // ============================================
  Widget _buildActionButtons(bool isDark, Color cardColor) {
    final primaryColor = _getPrimaryColor();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelChanges,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: AppColors.textSecondary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('إلغاء', style: TextStyle(fontSize: 15)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'حفظ الإعدادات',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // دوال مساعدة
  // ============================================

  Color _getPrimaryColor() {
    return AppColors.primary;
  }
}
