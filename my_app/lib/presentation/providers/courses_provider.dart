import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/course.dart';

// All Active Courses
final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('courses')
      .select()
      .eq('is_active', true)
      .order('created_at', ascending: false);

  return (response as List).map((json) => Course.fromJson(json)).toList();
});

// Courses by Subject
final coursesBySubjectProvider = FutureProvider.family<List<Course>, String>(
  (ref, subjectId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('courses')
        .select()
        .eq('is_active', true)
        .eq('subject_id', subjectId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Course.fromJson(json)).toList();
  },
);

// Single Course
final courseProvider = FutureProvider.family<Course, String>(
  (ref, courseId) async {
    final supabase = Supabase.instance.client;

    final response =
        await supabase.from('courses').select().eq('id', courseId).single();

    return Course.fromJson(response);
  },
);
