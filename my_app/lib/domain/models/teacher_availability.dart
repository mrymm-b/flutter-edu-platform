class TeacherAvailability {
  final String id;
  final String teacherId;
  final String subjectId;
  final double pricePerHour;
  final int dayOfWeek; // 0=Sunday, 1=Monday, ...
  final String startTime; // "14:00:00"
  final String endTime; // "18:00:00"
  final bool isAvailable;
  final DateTime createdAt;

  TeacherAvailability({
    required this.id,
    required this.teacherId,
    required this.subjectId,
    required this.pricePerHour,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.createdAt,
  });

  factory TeacherAvailability.fromJson(Map<String, dynamic> json) {
    return TeacherAvailability(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      subjectId: json['subject_id'] as String,
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      dayOfWeek: json['day_of_week'] as int,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isAvailable: json['is_available'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'subject_id': subjectId,
      'price_per_hour': pricePerHour,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper: Day name in Arabic
  String get dayNameAr {
    const days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    return days[dayOfWeek];
  }
}
