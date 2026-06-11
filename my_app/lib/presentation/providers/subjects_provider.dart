import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/subject.dart';

// Subjects Provider
final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('subjects')
      .select()
      .eq('is_active', true)
      .order('name_ar');

  return (response as List).map((json) => Subject.fromJson(json)).toList();
});
