import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';

class ChatHistoryService {
  static const String _historyKey = 'chat_history';

  static final ChatHistoryService _instance = ChatHistoryService._internal();
  factory ChatHistoryService() => _instance;
  ChatHistoryService._internal();

  SharedPreferences? _prefs;

  // تهيئة الخدمة
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      print('✅ ChatHistoryService initialized');
    } catch (e) {
      print('🔥 خطأ في تهيئة ChatHistoryService: $e');
    }
  }

  // التأكد من أن الخدمة مهيأة
  Future<bool> _ensureInitialized() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs != null;
  }

  // حفظ محادثة جديدة
  Future<void> saveChatSession(ChatSession session) async {
    if (!await _ensureInitialized()) {
      print('❌ ChatHistoryService غير مهيأ');
      return;
    }

    try {
      // جلب المحادثات الحالية
      List<ChatSession> sessions = await getChatSessions();

      // البحث عن محادثة بنفس الـ id
      int index = sessions.indexWhere((s) => s.id == session.id);

      if (index >= 0) {
        // تحديث المحادثة الموجودة
        sessions[index] = session;
        print(
          '🔄 تحديث محادثة موجودة: ${session.title} (${session.messages.length} رسائل)',
        );
      } else {
        // إضافة محادثة جديدة
        sessions.add(session);
        print(
          '➕ إضافة محادثة جديدة: ${session.title} (${session.messages.length} رسائل)',
        );
      }

      // ترتيب المحادثات من الأحدث للأقدم
      sessions.sort((a, b) => b.lastMessageAt!.compareTo(a.lastMessageAt!));
      if (session.messages.length > 1){
        // حفظ في SharedPreferences
        List<Map<String, dynamic>> sessionsJson = sessions
            .map((s) => s.toJson())
            .toList();
        String jsonString = json.encode(sessionsJson);
        await _prefs!.setString(_historyKey, jsonString);

        // التحقق من الحفظ
        String? saved = _prefs!.getString(_historyKey);
        if (saved != null) {
          List<dynamic> test = json.decode(saved);
          print('✅ تم حفظ ${test.length} محادثة في SharedPreferences');
        }
      }else{
        print("لم يتم الحفظ");
      }
      
    } catch (e) {
      print('🔥 خطأ في حفظ المحادثة: $e');
    }
  }

  // جلب كل المحادثات
  Future<List<ChatSession>> getChatSessions() async {
    if (!await _ensureInitialized()) {
      print('❌ ChatHistoryService غير مهيأ');
      return [];
    }

    try {
      String? sessionsJson = _prefs!.getString(_historyKey);
      if (sessionsJson == null) {
        print('📭 لا توجد محادثات محفوظة');
        return [];
      }

      List<dynamic> decoded = json.decode(sessionsJson);
      List<ChatSession> sessions = decoded
          .map((s) => ChatSession.fromJson(s))
          .toList();

      // ترتيب من الأحدث للأقدم
      sessions.sort((a, b) => b.lastMessageAt!.compareTo(a.lastMessageAt!));

      print('📊 تم جلب ${sessions.length} محادثة من SharedPreferences');
      for (var s in sessions) {
        print('   - ${s.title}: ${s.messages.length} رسائل');
      }

      return sessions;
    } catch (e) {
      print('🔥 خطأ في جلب المحادثات: $e');
      return [];
    }
  }

  // جلب محادثة محددة
  Future<ChatSession?> getChatSession(String id) async {
    List<ChatSession> sessions = await getChatSessions();
    try {
      return sessions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  // حذف محادثة
  Future<void> deleteChatSession(String id) async {
    if (!await _ensureInitialized()) return;

    try {
      List<ChatSession> sessions = await getChatSessions();
      sessions.removeWhere((s) => s.id == id);

      List<Map<String, dynamic>> sessionsJson = sessions
          .map((s) => s.toJson())
          .toList();
      await _prefs!.setString(_historyKey, json.encode(sessionsJson));

      print('✅ تم حذف المحادثة: $id');
    } catch (e) {
      print('🔥 خطأ في حذف المحادثة: $e');
    }
  }

  // حذف كل المحادثات
  Future<void> clearAllChats() async {
    if (!await _ensureInitialized()) return;

    try {
      await _prefs!.remove(_historyKey);
      print('✅ تم حذف جميع المحادثات');
    } catch (e) {
      print('🔥 خطأ في حذف المحادثات: $e');
    }
  }

  // البحث في المحادثات
  Future<List<ChatSession>> searchChatSessions(String query) async {
    List<ChatSession> allSessions = await getChatSessions();
    if (query.isEmpty) return allSessions;

    return allSessions
        .where(
          (session) =>
              session.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // تحديث عنوان المحادثة
  String generateChatTitle(List<ChatMessage> messages) {
    if (messages.isEmpty) return 'محادثة جديدة';

    for (var message in messages) {
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
}
