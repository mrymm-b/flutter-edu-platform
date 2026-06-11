class Payment {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String? stripePaymentId;
  final String status; // pending, completed, failed, refunded
  final String itemType; // course, book, private_lesson
  final String itemId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    this.stripePaymentId,
    required this.status,
    required this.itemType,
    required this.itemId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      stripePaymentId: json['stripe_payment_id'] as String?,
      status: json['status'] as String,
      itemType: json['item_type'] as String,
      itemId: json['item_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'stripe_payment_id': stripePaymentId,
      'status': status,
      'item_type': itemType,
      'item_id': itemId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helpers
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
}
