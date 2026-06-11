class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // course, live, announcement, payment, message
  final String? referenceId;
  final bool isRead;
  final DateTime sentAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.sentAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: json['type'] as String,
      referenceId: json['reference_id'] as String?,
      isRead: json['is_read'] as bool,
      sentAt: DateTime.parse(json['sent_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'reference_id': referenceId,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
