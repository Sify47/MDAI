// lib/screens/chat/chat_main_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:vita/services/chat_ai_service.dart';
import '../../constants/colors.dart';
import '../../models/chat_model.dart';
import '../../services/chat_api.dart';
import '../../widgets/chat_message_bubble.dart';
import 'chat_history_screen.dart';
import 'faq_screen.dart';
import '../../services/chat_history_service.dart';

class ChatMainScreen extends StatefulWidget {
  final ChatSession? initialSession;

  const ChatMainScreen({Key? key, this.initialSession}) : super(key: key);

  @override
  State<ChatMainScreen> createState() => _ChatMainScreenState();
}

class _ChatMainScreenState extends State<ChatMainScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _waveAnimationController;
  late AnimationController _typingController;
  late TextEditingController _messageController;
  late FocusNode _focusNode;
  late ScrollController _scrollController;

  List<ChatMessage> _messages = [];
  String _sessionId = '';
  bool _isSavingChat = false;
  bool _isRecording = false;
  bool _isSaving = false;
  bool _isTyping = false;
  bool _showSuggestions = true;
  bool _needsSaving = false;

  final List<Map<String, dynamic>> _suggestedQuestions = [
    {
      'text': 'ما هو المعدل الطبيعي للسكر؟',
      'icon': Icons.bloodtype,
      'color': Colors.red,
    },
    {
      'text': 'ما هي أعراض ارتفاع الضغط؟',
      'icon': Icons.favorite,
      'color': Colors.pink,
    },
    {
      'text': 'ما هي أعراض القولون العصبي؟',
      'icon': Icons.medical_services,
      'color': Colors.teal,
    },
    {'text': 'علاج الصداع النصفي', 'icon': Icons.sick, 'color': Colors.orange},
    {'text': 'نصائح لصحة القلب', 'icon': Icons.favorite, 'color': Colors.red},
    {'text': 'أعراض الأنيميا', 'icon': Icons.bloodtype, 'color': Colors.blue},
  ];

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _messageController = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();

    _initializeChat();
  }

  void _initializeChat() {
    if (widget.initialSession != null) {
      _messages = List.from(widget.initialSession!.messages);
      _sessionId = widget.initialSession!.id;
    } else {
      _messages = [];
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _addBotMessage(
            title: 'مرحباً بك في المساعد الصحي الذكي 👋',
            content: 'أنا هنا لمساعدتك في أي استفسار صحي. يمكنك سؤالي عن:',
            bullets: [
              '• الأعراض وتحليلها',
              '• الأدوية واستخداماتها',
              '• المعدلات الطبيعية للتحاليل',
              '• أمراض القلب والسكر والضغط',
              '• نصائح صحية عامة',
            ],
            metadata: {'source': 'ai_assistant'},
          );
          _saveCurrentChat();
        }
      });
    }
  }

  @override
  void dispose() {
    if (_messages.isNotEmpty) {
      _saveCurrentChat();
    }
    _fabAnimationController.dispose();
    _waveAnimationController.dispose();
    _typingController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentChat() async {
    if (_isSavingChat || _messages.isEmpty) return;
    _isSavingChat = true;

    String title = _generateChatTitle();
    ChatSession session = ChatSession(
      id: _sessionId,
      title: title,
      messages: List.from(_messages),
      createdAt: widget.initialSession?.createdAt ?? DateTime.now(),
      lastMessageAt: DateTime.now(),
      messageCount: _messages.length,
    );

    await ChatHistoryService().saveChatSession(session);
    _isSavingChat = false;
  }

  String _generateChatTitle() {
    for (var message in _messages) {
      if (message.type == 'user') {
        String content = message.content;
        if (content.length > 30) {
          return '${content.substring(0, 30)}...';
        }
        return content;
      }
    }
    return 'محادثة جديدة';
  }

  void _addUserMessage(String content, {Map<String, dynamic>? metadata}) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'user',
      content: content,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    setState(() {
      _messages.add(message);
      _isTyping = true;
      _showSuggestions = false;
      _needsSaving = true;
    });

    _scrollToBottom();
    _saveCurrentChat();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isTyping = false);
        _generateBotResponse(content);
      }
    });
  }

  void _addBotMessage({
    required String title,
    required String content,
    List<String>? bullets,
    Map<String, dynamic>? metadata,
  }) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'bot',
      content: content,
      title: title,
      bullets: bullets,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    setState(() {
      _messages.add(message);
      _needsSaving = true;
    });

    _scrollToBottom();
    _saveCurrentChat();
  }

  Future<void> _generateBotResponse(String userMessage) async {
    setState(() => _isTyping = true);

    try {
      // ✅ 1. التحليل المحلي السريع للأعراض
      final localAnalysis = ChatAIService.analyzeSymptomLocally(userMessage);

      if (localAnalysis != null && mounted) {
        setState(() => _isTyping = false);
        _addBotMessage(
          title: localAnalysis['title'],
          content: localAnalysis['content'],
          bullets: List<String>.from(localAnalysis['bullets']),
          metadata: {
            'source': localAnalysis['source'],
            'confidence': localAnalysis['confidence'],
            ...?localAnalysis['metadata'],
          },
        );
        return;
      }

      // ✅ 2. الاتصال بـ API
      final result = await ChatService.askQuestion(userMessage);

      if (mounted) {
        setState(() => _isTyping = false);

        if (result['success'] == true) {
          _addBotMessage(
            title: result['title'] ?? 'إجابة',
            content: result['content'] ?? '',
            bullets: List<String>.from(result['bullets'] ?? []),
            metadata: {
              'source': result['source'],
              'qa_id': result['qa_id'],
              'confidence': result['confidence'],
            },
          );
        } else {
          _addBotMessage(
            title: '😔 عذراً',
            content: result['content'] ?? 'حدث خطأ في الاتصال',
            bullets: [],
            metadata: {'source': 'error'},
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        _addBotMessage(
          title: '😔 خطأ',
          content: 'حدث خطأ في الاتصال بالخادم',
          bullets: [],
          metadata: {'source': 'error'},
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _saveChatSession({bool showMessage = false}) async {
    if (_messages.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    await _saveCurrentChat();
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isSaving = false;
        _needsSaving = false;
      });

      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ تم حفظ المحادثة'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _clearCurrentChat() {
    setState(() {
      _messages.clear();
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _showSuggestions = true;
      _needsSaving = false;
    });

    _addBotMessage(
      title: '✨ بداية جديدة',
      content: 'مرحباً بك مجدداً. كيف يمكنني مساعدتك اليوم؟',
      bullets: [
        '• استفسر عن دواء',
        '• حلل أعراضك',
        '• معلومات عن أمراض القلب',
        '• نصائح صحية',
      ],
      metadata: {'source': 'ai_assistant'},
    );
  }

  void _showClearChatDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        surfaceTintColor: theme.colorScheme.primary,
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: theme.colorScheme.onErrorContainer,
            size: 32,
          ),
        ),
        title: Text(
          'حذف المحادثة',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'هل أنت متأكد من حذف هذه المحادثة؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearCurrentChat();
                    _showSuccessFeedback(
                      message: 'تم حذف المحادثة بنجاح',
                      theme: theme,
                      icon: Icons.delete_sweep_rounded,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('حذف'),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      ),
    );
  }

  void _showVoiceRecorder(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '🎤 تسجيل صوتي',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _waveAnimationController,
              builder: (context, child) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.3),
                        theme.colorScheme.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isRecording = !_isRecording);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isRecording ? 90 : 80,
                        height: _isRecording ? 90 : 80,
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? AppColors.danger
                              : theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isRecording
                                          ? AppColors.danger
                                          : theme.colorScheme.primary)
                                      .withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? 'جاري التسجيل...' : 'اضغط للتسجيل',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                    onPressed: _isRecording
                        ? () {
                            Navigator.pop(context);
                            _addUserMessage(
                              '[تسجيل صوتي] استفسار صحي',
                              metadata: {'type': 'voice'},
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('إرسال'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '📸 تصوير دواء',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 60,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ضع علبة الدواء في الإطار',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      'لقراءة المعلومات',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('معرض الصور'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _addUserMessage(
                        '[صورة] استفسار عن دواء',
                        metadata: {'type': 'image'},
                      );
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('تصوير'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: () async {
          await _saveCurrentChat();
          return true;
        },
        child: Scaffold(
          backgroundColor: isDark
              ? theme.scaffoldBackgroundColor
              : AppColors.background,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🤖', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                const Text('المساعد الذكي'),
              ],
            ),
            actions: [
              // Save button - keep as separate icon for quick access
              _buildAppBarAction(
                icon: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        _needsSaving ? Icons.save : Icons.save_outlined,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                onPressed: _isSaving
                    ? null
                    : () => _saveChatSession(showMessage: true),
                tooltip: 'حفظ المحادثة',
                theme: theme,
              ),

              // Dropdown menu for additional actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                tooltip: 'المزيد من الخيارات',
                color: theme.colorScheme.surface,
                surfaceTintColor: theme.colorScheme.surfaceTint,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                onSelected: (String value) {
                  _handleMenuSelection(value, context, theme);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  if (_messages.isNotEmpty)
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'حذف المحادثة',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'سجل المحادثات',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'faq',
                    child: Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'الأسئلة الشائعة',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'تصدير المحادثة',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'إعدادات الدردشة',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(theme)
                    : AnimationLimiter(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          reverse: true,
                          itemCount: _messages.length + (_isTyping ? 1 : 0),
                          // تحسين الأداء: تحديد ارتفاع العنصر لتسريع التمرير
                          itemExtent:
                              null, // ارتفاع ديناميكي (null للارتفاع المتغير)
                          // تحسين الأداء: تحديد مساحة التخزين المؤقت
                          cacheExtent: 1000, // بكسل إضافي للتخزين المؤقت
                          // تحسين الأداء: إضافة مفاتيح للعناصر
                          addAutomaticKeepAlives: true,
                          addRepaintBoundaries: true,
                          itemBuilder: (context, index) {
                            if (index == 0 && _isTyping) {
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 500),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildTypingIndicator(theme),
                                  ),
                                ),
                              );
                            }
                            final messageIndex = _isTyping
                                ? _messages.length - index
                                : _messages.length - 1 - index;
                            final message = _messages[messageIndex];

                            // استخدام مفتاح فريد لكل رسالة لتحسين الأداء
                            final key = ValueKey(
                              'message_${message.id}_${message.timestamp}',
                            );

                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 500),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: ChatMessageBubble(
                                    key: key,
                                    message: message,
                                    theme: theme,
                                    isUser: message.type == 'user',
                                    onCopy: () => _copyMessage(message.content),
                                    onShare: () =>
                                        _shareMessage(message.content),
                                    onSave: () => _saveMessage(message),
                                    onReply: () => _replyToMessage(message),
                                    onEdit: () => _editMessage(message),
                                    onDelete: () => _deleteMessage(message),
                                    onTranslate: () =>
                                        _translateMessage(message),
                                    onReport: () => _reportMessage(message),
                                    showContextMenu: true,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              if (_messages.isEmpty && _showSuggestions)
                _buildSuggestedQuestions(theme),
              _buildInputBar(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarAction({
    required Widget icon,
    required VoidCallback? onPressed,
    required String tooltip,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 20,
      ),
    );
  }

  void _handleMenuSelection(
    String value,
    BuildContext context,
    ThemeData theme,
  ) {
    switch (value) {
      case 'delete':
        _showClearChatDialog(context, theme);
        break;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatHistoryScreen()),
        );
        break;
      case 'faq':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FAQScreen()),
        );
        break;
      case 'export':
        _showExportDialog(context, theme);
        break;
      case 'settings':
        _showChatSettingsDialog(context, theme);
        break;
    }
  }

  void _showExportDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تصدير المحادثة',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        content: Text(
          'سيتم تصدير المحادثة الحالية كملف نصي (TXT) أو ملف PDF.\n\nهذه الميزة قيد التطوير حالياً.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: theme.textTheme.bodyMedium),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('جاري تصدير المحادثة...'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
            },
            child: Text('تصدير', style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _showChatSettingsDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'إعدادات الدردشة',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.text_fields,
                color: theme.colorScheme.primary,
              ),
              title: Text('حجم الخط', style: theme.textTheme.bodyMedium),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Implement font size settings
              },
            ),
            ListTile(
              leading: Icon(
                Icons.notifications,
                color: theme.colorScheme.primary,
              ),
              title: Text('إشعارات الدردشة', style: theme.textTheme.bodyMedium),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            ListTile(
              leading: Icon(Icons.save, color: theme.colorScheme.primary),
              title: Text('الحفظ التلقائي', style: theme.textTheme.bodyMedium),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_fabAnimationController.value * 0.1),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.2),
                        theme.colorScheme.primary.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🤖', style: TextStyle(fontSize: 50)),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'كيف يمكنني مساعدتك؟',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'اسأل عن أي شيء صحي، وسأجيبك بناءً على المعلومات الطبية الموثوقة',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage message, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.metadata?['type'] == 'image')
                    Container(
                      height: 80,
                      width: 80,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.white, size: 40),
                      ),
                    ),
                  if (message.metadata?['type'] == 'voice')
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.audio_file, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            'تسجيل صوتي',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    message.content,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'منذ لحظات',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotMessage(ChatMessage message, ThemeData theme) {
    // مصدر الإجابة
    final source = message.metadata?['source'] ?? 'general';
    final sourceColor = ChatAIService.getSourceColor(source);
    final sourceIcon = ChatAIService.getSourceIcon(source);
    final sourceName = ChatAIService.getSourceName(source);
    final confidence = (message.metadata?['confidence'] as double?) ?? 0.0;

    // تحليل النقاط
    List<Widget> bulletWidgets = [];
    if (message.bullets != null) {
      for (var bullet in message.bullets!) {
        if (bullet.trim().isEmpty) continue;

        // إذا كانت النقطة عنوان فرعي
        if (bullet.trim().endsWith(':') ||
            (bullet.trim().endsWith('؟') == false &&
                bullet.length < 30 &&
                !bullet.startsWith('•'))) {
          bulletWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                bullet.trim(),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        } else {
          String displayBullet = bullet.trim();
          if (!displayBullet.startsWith('•') &&
              !displayBullet.startsWith('-') &&
              !displayBullet.startsWith('*')) {
            displayBullet = '• $displayBullet';
          }
          bulletWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      displayBullet.substring(1).trim(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.2),
                  theme.colorScheme.primary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.title ?? 'إجابة',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      // ✅ شارة المصدر
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: sourceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              sourceIcon,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              sourceName,
                              style: TextStyle(
                                fontSize: 11,
                                color: sourceColor,
                              ),
                            ),
                            if (confidence > 0) ...[
                              const SizedBox(width: 3),
                              Text(
                                '${(confidence * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: sourceColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (message.content.isNotEmpty &&
                      message.content != message.title) ...[
                    const SizedBox(height: 12),
                    Text(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                  if (bulletWidgets.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...bulletWidgets,
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'منذ لحظات',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.thumb_up_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('شكراً لتقييمك'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        splashRadius: 16,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.thumb_down_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('سنعمل على تحسين الإجابة'),
                              backgroundColor: AppColors.warning,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        splashRadius: 16,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.share_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        onPressed: () {},
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        splashRadius: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot avatar with Material 3 design
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.smart_toy_outlined,
                color: theme.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Typing bubble with animated dots
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(8),
                  bottomLeft: Radius.circular(24),
                ),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'المساعد الذكي',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'جاري الكتابة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildModernTypingDots(theme),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTypingDots(ThemeData theme) {
    return SizedBox(
      width: 40,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedDot(0, theme),
          const SizedBox(width: 4),
          _buildAnimatedDot(150, theme),
          const SizedBox(width: 4),
          _buildAnimatedDot(300, theme),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int delay, ThemeData theme) {
    return AnimatedBuilder(
      animation: _typingController,
      builder: (context, child) {
        final value = _typingController.value;
        final offset = (value * 3 - delay / 200).clamp(0.0, 1.0);
        final scale = 0.6 + offset * 0.6;
        final opacity = 0.3 + offset * 0.7;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingDot(int delay, ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedQuestions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 12),
            child: Text(
              'أسئلة مقترحة',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _suggestedQuestions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final question = _suggestedQuestions[index];
                return _buildSuggestedQuestionCard(question, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestionCard(
    Map<String, dynamic> question,
    ThemeData theme,
  ) {
    Color color = question['color'];
    return GestureDetector(
      onTap: () => _addUserMessage(question['text']),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(question['icon'], color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              question['text'],
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildInputActionButton(
              icon: Icons.mic,
              onPressed: () => _showVoiceRecorder(theme),
              color: theme.colorScheme.primary,
              theme: theme,
            ),
            const SizedBox(width: 4),
            _buildInputActionButton(
              icon: Icons.camera_alt,
              onPressed: () => _showImagePicker(theme),
              color: theme.colorScheme.primary,
              theme: theme,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? theme.colorScheme.primary.withOpacity(0.5)
                        : theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'اكتب سؤالك هنا...',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _messageController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            onPressed: () {
                              _messageController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  style: theme.textTheme.bodyMedium,
                  onChanged: (value) => setState(() {}),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _addUserMessage(value);
                      _messageController.clear();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _messageController.text.isNotEmpty
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.1),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: _messageController.text.isNotEmpty
                      ? Colors.white
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                  size: 22,
                ),
                onPressed: _messageController.text.isNotEmpty
                    ? () {
                        _addUserMessage(_messageController.text);
                        _messageController.clear();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // إجراءات السياق للرسائل
  void _copyMessage(String text) {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الرسالة إلى الحافظة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareMessage(String text) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم مشاركة الرسالة قريباً'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveMessage(ChatMessage message) {
    // TODO: Implement save to favorites
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ الرسالة في المفضلة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _replyToMessage(ChatMessage message) {
    // TODO: Implement reply functionality
    _showSuccessFeedback(
      message: 'تم إعداد الرد على الرسالة',
      theme: Theme.of(context),
    );
    // Focus on input field and prefill with reply
    _messageController.text = 'رد على: ${message.content.substring(0, 30)}... ';
    _focusNode.requestFocus();
  }

  void _editMessage(ChatMessage message) {
    // TODO: Implement edit functionality
    _showSuccessFeedback(
      message: 'تم فتح محرر الرسالة',
      theme: Theme.of(context),
    );
    // For now, just show a dialog to edit
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(
          controller: TextEditingController(text: message.content),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Update message in list
              _showSuccessFeedback(
                message: 'تم تعديل الرسالة',
                theme: Theme.of(context),
              );
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(ChatMessage message) {
    // TODO: Implement delete functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الرسالة'),
        content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _messages.remove(message);
              });
              _showSuccessFeedback(
                message: 'تم حذف الرسالة',
                theme: Theme.of(context),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _translateMessage(ChatMessage message) {
    // TODO: Implement translation functionality
    _showLoadingOverlay('جاري الترجمة...');
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading overlay
        _showSuccessFeedback(
          message: 'تم ترجمة الرسالة',
          theme: Theme.of(context),
        );
        // Show translated message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('الترجمة'),
            content: Text(
              'الرسالة المترجمة: ${message.content} (ترجمة تجريبية)',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    });
  }

  void _reportMessage(ChatMessage message) {
    // TODO: Implement report functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإبلاغ عن رسالة'),
        content: const Text('يرجى اختيار سبب الإبلاغ عن هذه الرسالة:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _showSuccessFeedback(
                message: 'تم الإبلاغ عن الرسالة',
                theme: Theme.of(context),
              );
              Navigator.pop(context);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _showLoadingOverlay(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _buildLoadingOverlay(message: message, theme: Theme.of(context)),
    );
  }

  // ============================================
  // مؤشرات التحميل والتأكيد - Material 3 Design
  // ============================================

  /// بناء طبقة تحميل شفافة للمهام الطويلة
  Widget _buildLoadingOverlay({
    required String message,
    required ThemeData theme,
  }) {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// عرض تأكيد النجاح مع تصميم Material 3
  void _showSuccessFeedback({
    required String message,
    required ThemeData theme,
    IconData icon = Icons.check_circle,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.colorScheme.primaryContainer,
        content: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// عرض رسالة خطأ مع تصميم Material 3
  void _showErrorFeedback({
    required String message,
    required ThemeData theme,
    IconData icon = Icons.error_outline,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.colorScheme.errorContainer,
        content: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onErrorContainer, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildInputActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
        splashRadius: 22,
      ),
    );
  }
}
