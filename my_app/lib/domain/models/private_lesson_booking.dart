class PrivateLessonBooking {
  final String id;
  final String studentId;
  final String teacherId;
  final String subjectId;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final int durationHours;
  final double pricePerHour;
  final double totalPrice;
  final String status; // pending, confirmed, completed, cancelled
  final String? paymentId;
  final String? meetingUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrivateLessonBooking({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.subjectId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.pricePerHour,
    required this.totalPrice,
    required this.status,
    this.paymentId,
    this.meetingUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrivateLessonBooking.fromJson(Map<String, dynamic> json) {
    return PrivateLessonBooking(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      subjectId: json['subject_id'] as String,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      durationHours: json['duration_hours'] as int,
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
      paymentId: json['payment_id'] as String?,
      meetingUrl: json['meeting_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'teacher_id': teacherId,
      'subject_id': subjectId,
      'booking_date': bookingDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'duration_hours': durationHours,
      'price_per_hour': pricePerHour,
      'total_price': totalPrice,
      'status': status,
      'payment_id': paymentId,
      'meeting_url': meetingUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helpers
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}
