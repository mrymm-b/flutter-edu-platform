class Conversation {
  final String id;
  final String studentId;
  final String teacherId;
  final String? courseId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCountStudent;
  final int unreadCountTeacher;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.courseId,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCountStudent,
    required this.unreadCountTeacher,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      courseId: json['course_id'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCountStudent: (json['unread_count_student'] as int?) ?? 0,
      unreadCountTeacher: (json['unread_count_teacher'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'teacher_id': teacherId,
      'course_id': courseId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count_student': unreadCountStudent,
      'unread_count_teacher': unreadCountTeacher,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
