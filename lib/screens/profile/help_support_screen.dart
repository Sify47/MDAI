// lib/screens/profile/help_support_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FaqItem> _faqs = [
    FaqItem(
      question: 'كيف يمكنني تسجيل قراءاتي الحيوية؟',
      answer:
          'يمكنك تسجيل القراءات الحيوية من خلال الذهاب إلى قسم "الخدمات" ثم اختيار "تتبع القراءات الحيوية". ستتمكن من إدخال قراءات ضغط الدم، نسبة السكر، درجة الحرارة، ونبضات القلب.',
      category: 'القراءات الحيوية',
    ),
    FaqItem(
      question: 'كيف يحسب التطبيق السعرات الحرارية المناسبة لي؟',
      answer:
          'يستخدم التطبيق معادلة Mifflin-St Jeor لحساب معدل الأيض الأساسي (BMR) ثم يضربه في عامل النشاط اليومي، مع مراعاة هدفك (تخسيس/تثبيت/زيادة) والأمراض المزمنة إن وجدت.',
      category: 'النظام الغذائي',
    ),
    FaqItem(
      question: 'هل يمكنني تذكير مواعيد الأدوية؟',
      answer:
          'نعم، يمكنك إضافة أدويتك في قسم "الأدوية" وتحديد مواعيد تناولها، وسيقوم التطبيق بإرسال إشعارات تذكيرية في الوقت المحدد.',
      category: 'الأدوية',
    ),
    FaqItem(
      question: 'كيف يتم حساب عدد الخطوات؟',
      answer:
          'يستخدم التطبيق مستشعرات الهاتف لحساب الخطوات تلقائياً. تأكد من منح التطبيق صلاحية الوصول إلى النشاط البدني في إعدادات الهاتف.',
      category: 'النشاط البدني',
    ),
    FaqItem(
      question: 'هل بياناتي آمنة؟',
      answer:
          'نعم، جميع بياناتك مشفرة ومخزنة بشكل آمن. نحن نلتزم بمعايير الخصوصية الطبية ولا نشارك بياناتك مع أي طرف ثالث دون موافقتك.',
      category: 'الخصوصية',
    ),
    FaqItem(
      question: 'كيف يمكنني التواصل مع الدعم الفني؟',
      answer:
          'يمكنك التواصل مع فريق الدعم عبر البريد الإلكتروني support@vitaapp.com أو عبر رقم الواتساب +966 5XXXXXX، أو من خلال نموذج التواصل الموجود في هذه الصفحة.',
      category: 'الدعم',
    ),
  ];

  final TextEditingController _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'عام';
  bool _isSending = false;

  final List<String> _contactCategories = [
    'عام',
    'مشكلة تقنية',
    'استفسار طبي',
    'اقتراح',
    'شكوى',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSending = true);

      // محاكاة إرسال الرسالة
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: const Text('تم إرسال رسالتك بنجاح، سنقوم بالرد عليك قريباً'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _messageController.clear();
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+201141117352');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا يمكن إجراء المكالمة')));
      }
    }
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@vitaapp.com',
      query: 'subject=${Uri.encodeComponent('استفسار من تطبيق VITA')}',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '201141117352',
    );
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مساعدة ودعم')),
        body: AnimationLimiter(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildContactCards(theme),
                const SizedBox(height: 24),
                _buildFaqSection(theme),
                const SizedBox(height: 24),
                _buildContactForm(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCards(ThemeData theme) {
    final contacts = [
      {
        'icon': Icons.phone,
        'title': 'اتصال',
        'color': Colors.green,
        'onTap': _makePhoneCall,
      },
      {
        'icon': Icons.email,
        'title': 'بريد إلكتروني',
        'color': Colors.blue,
        'onTap': _sendEmail,
      },
      {
        'icon': Icons.chat,
        'title': 'واتساب',
        'color': Colors.green,
        'onTap': _openWhatsApp,
      },
    ];

    return Row(
      children: List.generate(contacts.length, (index) {
        return Expanded(
          child: AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 500),
            columnCount: 3,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildContactCard(theme, contacts[index]),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContactCard(ThemeData theme, Map<String, dynamic> contact) {
    return GestureDetector(
      onTap: contact['onTap'] as VoidCallback,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (contact['color'] as Color).withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (contact['color'] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(contact['icon'], color: contact['color'], size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              contact['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionPanelList.radio(
        children: _faqs
            .map(
              (faq) => ExpansionPanelRadio(
                value: faq.question,
                headerBuilder: (context, isExpanded) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    faq.question,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    faq.category,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(faq.answer, style: const TextStyle(height: 1.5)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildContactForm(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.message, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'تواصل معنا',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'نوع الاستفسار',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _contactCategories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'رسالتك',
                  hintText: 'اكتب تفاصيل استفسارك هنا...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'الرجاء كتابة رسالتك' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSending ? 'جاري الإرسال...' : 'إرسال'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaqItem {
  final String question;
  final String answer;
  final String category;

  FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}
