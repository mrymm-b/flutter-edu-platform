import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_provider.dart';

// Enriched cart item (cart row joined with course/book details)
class CartItemDetail {
  final String cartId;
  final String itemType; // course, book
  final String title;
  final double price;
  final String? courseId;
  final String? bookId;

  CartItemDetail({
    required this.cartId,
    required this.itemType,
    required this.title,
    required this.price,
    this.courseId,
    this.bookId,
  });

  String get typeLabel => itemType == 'course' ? 'دورة أونلاين' : 'ملزمة PDF';
}

// Cart State
class CartState {
  final List<CartItemDetail> items;
  final bool isLoading;
  final String? error;

  CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  CartState copyWith({
    List<CartItemDetail>? items,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.price);
  int get itemCount => items.length;
}

// Cart Notifier
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this.ref) : super(CartState());

  final Ref ref;
  final _supabase = Supabase.instance.client;

  Future<void> loadCart() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final response = await _supabase
          .from('cart')
          .select('id, item_type, course_id, book_id, courses(id, title, price), books(id, title, price)')
          .eq('user_id', authState.user!.id);

      final items = (response as List).map((json) {
        final itemType = json['item_type'] as String;
        String title = '';
        double price = 0.0;
        String? courseId;
        String? bookId;

        if (itemType == 'course' && json['courses'] != null) {
          title = json['courses']['title'] as String? ?? '';
          price = (json['courses']['price'] as num?)?.toDouble() ?? 0.0;
          courseId = json['course_id'] as String?;
        } else if (itemType == 'book' && json['books'] != null) {
          title = json['books']['title'] as String? ?? '';
          price = (json['books']['price'] as num?)?.toDouble() ?? 0.0;
          bookId = json['book_id'] as String?;
        }

        return CartItemDetail(
          cartId: json['id'] as String,
          itemType: itemType,
          title: title,
          price: price,
          courseId: courseId,
          bookId: bookId,
        );
      }).toList();

      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'فشل تحميل السلة');
    }
  }

  Future<bool> addToCart({
    required String itemType,
    String? courseId,
    String? bookId,
  }) async {
    final authState = ref.read(authProvider);
    if (authState.user == null) {
      debugPrint('[Cart] addToCart: user is null — not logged in');
      return false;
    }

    try {
      debugPrint('[Cart] addToCart: inserting itemType=$itemType courseId=$courseId bookId=$bookId for userId=${authState.user!.id}');
      await _supabase.from('cart').insert({
        'user_id': authState.user!.id,
        'item_type': itemType,
        'course_id': courseId,
        'book_id': bookId,
      });
      await loadCart();
      return true;
    } on PostgrestException catch (e) {
      debugPrint('[Cart] addToCart PostgrestException: code=${e.code} message=${e.message} details=${e.details} hint=${e.hint}');
      state = state.copyWith(error: 'فشل إضافة العنصر للسلة');
      return false;
    } catch (e) {
      debugPrint('[Cart] addToCart error: $e');
      state = state.copyWith(error: 'فشل إضافة العنصر للسلة');
      return false;
    }
  }

  Future<void> removeFromCart(String cartId) async {
    try {
      await _supabase.from('cart').delete().eq('id', cartId);
      await loadCart();
    } catch (e) {
      state = state.copyWith(error: 'فشل حذف العنصر');
    }
  }

  Future<void> clearCart() async {
    final authState = ref.read(authProvider);
    if (authState.user == null) return;

    try {
      await _supabase.from('cart').delete().eq('user_id', authState.user!.id);
      state = state.copyWith(items: []);
    } catch (e) {
      state = state.copyWith(error: 'فشل تفريغ السلة');
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});
