import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/book_purchase.dart';
import '../../domain/models/book.dart';
import 'auth_provider.dart';

// My Book Purchases
final myBookPurchasesProvider = FutureProvider<List<BookPurchase>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return [];

  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('book_purchases')
      .select()
      .eq('student_id', authState.user!.id)
      .order('purchased_at', ascending: false);

  return (response as List).map((json) => BookPurchase.fromJson(json)).toList();
});

// My Purchased Books (with book details)
final myPurchasedBooksProvider = FutureProvider<List<Book>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return [];

  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('book_purchases')
      .select('book_id, books(*)')
      .eq('student_id', authState.user!.id);

  return (response as List)
      .map((item) => Book.fromJson(item['books']))
      .toList();
});

// Check if book is purchased
final isBookPurchasedProvider = FutureProvider.family<bool, String>(
  (ref, bookId) async {
    final authState = ref.watch(authProvider);
    if (authState.user == null) return false;

    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('book_purchases')
        .select()
        .eq('student_id', authState.user!.id)
        .eq('book_id', bookId);

    return (response as List).isNotEmpty;
  },
);
