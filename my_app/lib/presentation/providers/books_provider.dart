import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/book.dart';

// All Active Books
final booksProvider = FutureProvider<List<Book>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('books')
      .select()
      .eq('is_active', true)
      .order('created_at', ascending: false);

  return (response as List).map((json) => Book.fromJson(json)).toList();
});

// Books by Subject
final booksBySubjectProvider = FutureProvider.family<List<Book>, String>(
  (ref, subjectId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('books')
        .select()
        .eq('is_active', true)
        .eq('subject_id', subjectId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Book.fromJson(json)).toList();
  },
);

// Single Book
final bookProvider = FutureProvider.family<Book, String>(
  (ref, bookId) async {
    final supabase = Supabase.instance.client;

    final response =
        await supabase.from('books').select().eq('id', bookId).single();

    return Book.fromJson(response);
  },
);
