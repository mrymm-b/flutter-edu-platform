import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/enrollment.dart';
import '../../domain/models/course.dart';
import 'auth_provider.dart';

// Student's Enrollments
final myEnrollmentsProvider = FutureProvider<List<Enrollment>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return [];

  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('enrollments')
      .select()
      .eq('student_id', authState.user!.id)
      .order('created_at', ascending: false);

  return (response as List).map((json) => Enrollment.fromJson(json)).toList();
});

// Student's Enrolled Courses (with course details)
final myCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return [];

  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('enrollments')
      .select('course_id, courses(*)')
      .eq('student_id', authState.user!.id);

  return (response as List)
      .map((item) => Course.fromJson(item['courses']))
      .toList();
});

// Check if enrolled in course
final isEnrolledProvider = FutureProvider.family<bool, String>(
  (ref, courseId) async {
    final authState = ref.watch(authProvider);
    if (authState.user == null) return false;

    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('enrollments')
        .select()
        .eq('student_id', authState.user!.id)
        .eq('course_id', courseId);

    return (response as List).isNotEmpty;
  },
);
