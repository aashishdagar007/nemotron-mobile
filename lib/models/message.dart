enum Role { user, assistant }

class Message {
  final Role   role;
  String       content;
  String       thinking;
  final DateTime timestamp;
  bool         isStreaming;

  Message({
    required this.role,
    required this.content,
    this.thinking    = '',
    this.isStreaming = false,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toApiMap() => {
    'role':    role == Role.user ? 'user' : 'assistant',
    'content': content,
  };

  bool get isUser => role == Role.user;
}
