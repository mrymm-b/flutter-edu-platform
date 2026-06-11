class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String message;
  final bool isRead;
  final DateTime sentAt;
  final DateTime createdAt;
  final String messageType; // 'text' | 'image' | 'voice'
  final String? mediaUrl;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    required this.isRead,
    required this.sentAt,
    required this.createdAt,
    this.messageType = 'text',
    this.mediaUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String,
      isRead: (json['is_read'] as bool?) ?? false,
      sentAt: DateTime.parse(
          (json['sent_at'] ?? json['created_at']) as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      messageType: (json['message_type'] as String?) ?? 'text',
      mediaUrl: json['media_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message': message,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'message_type': messageType,
      if (mediaUrl != null) 'media_url': mediaUrl,
    };
  }
}
