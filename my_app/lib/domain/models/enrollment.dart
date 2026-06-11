class Enrollment {
  final String id;
  final String studentId;
  final String courseId;
  final DateTime purchasedAt;
  final double pricePaid;
  final String? paymentId;
  final DateTime createdAt;
  final double progress;

  Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.purchasedAt,
    required this.pricePaid,
    this.paymentId,
    required this.createdAt,
    this.progress = 0,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      courseId: json['course_id'] as String,
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      pricePaid: (json['price_paid'] as num).toDouble(),
      paymentId: json['payment_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      progress: (json['progress'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'course_id': courseId,
      'purchased_at': purchasedAt.toIso8601String(),
      'price_paid': pricePaid,
      'payment_id': paymentId,
      'created_at': createdAt.toIso8601String(),
      'progress': progress,
    };
  }
}
