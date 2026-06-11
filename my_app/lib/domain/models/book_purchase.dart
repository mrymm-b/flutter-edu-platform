class BookPurchase {
  final String id;
  final String studentId;
  final String bookId;
  final DateTime purchasedAt;
  final double pricePaid;
  final String? paymentId;
  final int downloadCount;
  final DateTime createdAt;

  BookPurchase({
    required this.id,
    required this.studentId,
    required this.bookId,
    required this.purchasedAt,
    required this.pricePaid,
    this.paymentId,
    required this.downloadCount,
    required this.createdAt,
  });

  factory BookPurchase.fromJson(Map<String, dynamic> json) {
    return BookPurchase(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      bookId: json['book_id'] as String,
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      pricePaid: (json['price_paid'] as num).toDouble(),
      paymentId: json['payment_id'] as String?,
      downloadCount: json['download_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'book_id': bookId,
      'purchased_at': purchasedAt.toIso8601String(),
      'price_paid': pricePaid,
      'payment_id': paymentId,
      'download_count': downloadCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
