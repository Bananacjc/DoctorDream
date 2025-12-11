class ChatMessage {
  final String id;
  final String sessionId;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? text,
    bool? isUser,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'text': text,
      'is_user': isUser ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      sessionId: map['session_id'],
      text: map['text'],
      isUser: (map['is_user'] as int) == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
