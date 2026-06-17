// lib/services/chat_api.dart

import 'dart:convert';
import 'package:vita/services/base_api_service.dart';
import 'package:vita/services/cache_manager.dart';

class ChatService {
  static const String _pathPrefix = 'chat';

  // POST /chat/ask - إرسال سؤال
  static Future<Map<String, dynamic>> askQuestion(String question) async {
    try {
      print('💬 إرسال سؤال: $question');

      final response = await BaseApiService.post(
        '$_pathPrefix/ask',
        body: {'question': question},
      );

      print('📥 استجابة: ${response.statusCode}');
      print('📄 محتوى: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'source': 'error',
          'title': 'خطأ',
          'content': 'فشل في الاتصال بالخادم',
          'bullets': [],
        };
      }
    } catch (e) {
      print('🔥 خطأ: $e');
      return {
        'success': false,
        'source': 'error',
        'title': 'خطأ',
        'content': 'حدث خطأ في الاتصال',
        'bullets': [],
      };
    }
  }

  // POST /chat/feedback - تسجيل تقييم
  static Future<bool> submitFeedback(int qaId, bool helpful) async {
    try {
      final response = await BaseApiService.post(
        '$_pathPrefix/feedback',
        body: {'qa_id': qaId, 'helpful': helpful},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('🔥 خطأ في إرسال التقييم: $e');
      return false;
    }
  }
}
