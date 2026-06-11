class Book {
  final String id;
  final String title;
  final String? description;
  final String teacherId;
  final String? courseId;
  final String subjectId;
  final double price;
  final String pdfUrl;
  final String? thumbnailUrl;
  final int? pagesCount;
  final int? fileSize;
  final bool isActive;
  final int downloadsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    this.description,
    required this.teacherId,
    this.courseId,
    required this.subjectId,
    required this.price,
    required this.pdfUrl,
    this.thumbnailUrl,
    this.pagesCount,
    this.fileSize,
    required this.isActive,
    required this.downloadsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      teacherId: json['teacher_id'] as String,
      courseId: json['course_id'] as String?,
      subjectId: json['subject_id'] as String,
      price: ((json['price'] as num?) ?? 0).toDouble(),
      pdfUrl: (json['pdf_url'] as String?) ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      pagesCount: json['pages_count'] as int?,
      fileSize: json['file_size'] as int?,
      isActive: (json['is_active'] as bool?) ?? true,
      downloadsCount: (json['downloads_count'] as int?) ?? 0,
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
      'course_id': courseId,
      'subject_id': subjectId,
      'price': price,
      'pdf_url': pdfUrl,
      'thumbnail_url': thumbnailUrl,
      'pages_count': pagesCount,
      'file_size': fileSize,
      'is_active': isActive,
      'downloads_count': downloadsCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper: File size in MB
  String get fileSizeInMB {
    if (fileSize == null) return '0 MB';
    return '${(fileSize! / 1024).toStringAsFixed(1)} MB';
  }
}
