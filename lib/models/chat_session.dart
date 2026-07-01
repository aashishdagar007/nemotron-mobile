import 'message.dart';

class ChatSession {
  String id;
  String title;
  DateTime updatedAt;
  List<Message> messages;

  ChatSession({
    required this.id,
    required this.title,
    DateTime? updatedAt,
    List<Message>? messages,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        messages   = messages ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => {
      'role': m.role == Role.user ? 'user' : 'assistant',
      'content': m.content,
      'thinking': m.thinking,
    }).toList(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> j) {
    final msgs = (j['messages'] as List).map((m) {
      final msg = Message(
        role: m['role'] == 'user' ? Role.user : Role.assistant,
        content: m['content'] ?? '',
      );
      msg.thinking = m['thinking'] ?? '';
      return msg;
    }).toList();
    return ChatSession(
      id: j['id'],
      title: j['title'],
      updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now(),
      messages: msgs,
    );
  }
}
