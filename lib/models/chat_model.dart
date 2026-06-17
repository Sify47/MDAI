class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final int messageCount;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    this.lastMessageAt,
    required this.messageCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'messageCount': messageCount,
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      messageCount: json['messageCount'],
    );
  }
}

class ChatMessage {
  final String id;
  final String type; // 'user' or 'bot'
  final String content;
  final String? title;
  final List<String>? bullets;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata; // للربط مع الأنظمة الأخرى

  ChatMessage({
    required this.id,
    required this.type,
    required this.content,
    this.title,
    this.bullets,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'title': title,
      'bullets': bullets,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      type: json['type'],
      content: json['content'],
      title: json['title'],
      bullets: json['bullets']?.cast<String>(),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'],
    );
  }
}
