class Course {
  final String id;
  final String title;
  final String? description;
  final String teacherId;
  final String subjectId;
  final double price;
  final String? thumbnailUrl;
  final bool isActive;
  final int studentsCount;
  final String? createdByAdminId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.title,
    this.description,
    required this.teacherId,
    required this.subjectId,
    required this.price,
    this.thumbnailUrl,
    required this.isActive,
    required this.studentsCount,
    this.createdByAdminId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      teacherId: json['teacher_id'] as String,
      subjectId: json['subject_id'] as String,
      price: (json['price'] as num).toDouble(),
      thumbnailUrl: json['thumbnail_url'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      studentsCount: (json['students_count'] as int?) ?? 0,
      createdByAdminId: json['created_by_admin_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'teacher_id': teacherId,
      'subject_id': subjectId,
      'price': price,
      'thumbnail_url': thumbnailUrl,
      'is_active': isActive,
      'students_count': studentsCount,
      'created_by_admin_id': createdByAdminId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
