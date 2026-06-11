class CartItem {
  final String id;
  final String userId;
  final String itemType; // course, book, private_lesson
  final String? courseId;
  final String? bookId;
  final String? privateLessonBookingId;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.userId,
    required this.itemType,
    this.courseId,
    this.bookId,
    this.privateLessonBookingId,
    required this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      itemType: json['item_type'] as String,
      courseId: json['course_id'] as String?,
      bookId: json['book_id'] as String?,
      privateLessonBookingId: json['private_lesson_booking_id'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_type': itemType,
      'course_id': courseId,
      'book_id': bookId,
      'private_lesson_booking_id': privateLessonBookingId,
      'added_at': addedAt.toIso8601String(),
    };
  }

  // Helper
  String get itemId {
    if (itemType == 'course') return courseId!;
    if (itemType == 'book') return bookId!;
    return privateLessonBookingId!;
  }
}
