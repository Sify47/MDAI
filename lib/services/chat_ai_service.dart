// lib/services/chat_ai_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';

class ChatAIService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // للأندرويد
  // static const String baseUrl = 'http://127.0.0.1:8000'; // للويب
  // static const String baseUrl = 'http://65.75.201.173:8000'; // للسيرفر

  // ✅ قائمة الأعراض للتحليل السريع (بدون API)
  static final Map<String, Map<String, dynamic>> _quickSymptoms = {
    'صداع': {
      'severity': 'متوسط',
      'suggestion': 'خذ قسطاً من الراحة، اشرب ماء، استخدم كمادات باردة',
      'warning': 'إذا كان مفاجئاً وشديداً أو مصحوباً بزغللة، استشر طبيباً',
      'icon': '🤕',
      'color': 0xFFFF9800,
    },
    'حرارة': {
      'severity': 'متوسط',
      'suggestion': 'اشرب سوائل كثيرة، استخدم خافض حرارة، كمادات فاترة',
      'warning': 'إذا استمرت أكثر من 3 أيام أو تجاوزت 40°م، استشر طبيباً',
      'icon': '🌡️',
      'color': 0xFFF44336,
    },
    'سعال': {
      'severity': 'خفيف',
      'suggestion': 'اشرب مشروبات دافئة، عسل، تجنب المهيجات',
      'warning': 'إذا استمر أكثر من أسبوع أو كان مصحوباً بدم',
      'icon': '🤧',
      'color': 0xFF4CAF50,
    },
    'إسهال': {
      'severity': 'متوسط',
      'suggestion': 'اشرب سوائل كثيرة، تجنب الألبان، تناول أطعمة خفيفة',
      'warning': 'إذا كان دموياً أو استمر أكثر من 3 أيام',
      'icon': '💩',
      'color': 0xFF795548,
    },
    'إمساك': {
      'severity': 'خفيف',
      'suggestion': 'زد من الألياف، اشرب ماء كثيراً، مارس الرياضة',
      'warning': 'إذا استمر أكثر من أسبوع أو كان مصحوباً بألم شديد',
      'icon': '🚽',
      'color': 0xFF9C27B0,
    },
    'ألم بطن': {
      'severity': 'متوسط',
      'suggestion': 'تجنب الأطعمة الدسمة، اشرب يانسون أو نعناع',
      'warning': 'إذا كان شديداً أو مصحوباً بحرارة أو قيء',
      'icon': '🤢',
      'color': 0xFFFF5722,
    },
    'دوخة': {
      'severity': 'متوسط',
      'suggestion': 'اجلس أو استلق فوراً، اشرب ماء، تناول وجبة خفيفة',
      'warning': 'إذا تكررت أو صاحبتها زغللة أو إغماء',
      'icon': '😵',
      'color': 0xFF00BCD4,
    },
    'تعب': {
      'severity': 'خفيف',
      'suggestion': 'نم 7-8 ساعات، تناول غذاء متوازن، اشرب ماء',
      'warning': 'إذا استمر لأكثر من أسبوعين أو كان شديداً',
      'icon': '😴',
      'color': 0xFF607D8B,
    },
  };

  // ✅ تحليل سريع للأعراض (بدون اتصال بالإنترنت)
  static Map<String, dynamic>? analyzeSymptomLocally(String question) {
    final questionLower = question.toLowerCase();

    for (var entry in _quickSymptoms.entries) {
      if (questionLower.contains(entry.key)) {
        final symptom = entry.key;
        final info = entry.value;

        return {
          'success': true,
          'source': 'local',
          'title': '🔍 تحليل الأعراض',
          'content':
              'بناءً على الأعراض التي ذكرتها (${symptom})، إليك النصائح:',
          'bullets': [
            '💡 نصيحة: ${info['suggestion']}',
            '⚠️ متى تقلق: ${info['warning']}',
          ],
          'confidence': 0.85,
          'metadata': {
            'symptom': symptom,
            'severity': info['severity'],
            'icon': info['icon'],
            'color': info['color'],
          },
        };
      }
    }

    return null;
  }

  // ✅ إضافة ألوان جميلة للردود
  static Color getSourceColor(String source) {
    switch (source) {
      case 'local':
        return Colors.green;
      case 'database':
        return Colors.blue;
      case 'knowledge_base':
        return Colors.purple;
      case 'ai_analysis':
        return Colors.orange;
      case 'ai_assistant':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  static String getSourceIcon(String source) {
    switch (source) {
      case 'local':
        return '📱';
      case 'database':
        return '💾';
      case 'knowledge_base':
        return '📚';
      case 'ai_analysis':
        return '🧠';
      case 'ai_assistant':
        return '🤖';
      default:
        return '💬';
    }
  }

  static String getSourceName(String source) {
    switch (source) {
      case 'local':
        return 'محلي';
      case 'database':
        return 'مخزن';
      case 'knowledge_base':
        return 'موسوعة';
      case 'ai_analysis':
        return 'تحليل ذكي';
      case 'ai_assistant':
        return 'مساعد ذكي';
      default:
        return 'عام';
    }
  }
}
