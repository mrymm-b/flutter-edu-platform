import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/teacher_availability.dart';
import '../../domain/models/private_lesson_booking.dart';
import 'auth_provider.dart';

// Teacher Availability
final teacherAvailabilityProvider =
    FutureProvider.family<List<TeacherAvailability>, String>(
  (ref, subjectId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('teacher_availability')
        .select()
        .eq('subject_id', subjectId)
        .eq('is_available', true)
        .order('day_of_week');

    return (response as List)
        .map((json) => TeacherAvailability.fromJson(json))
        .toList();
  },
);

// My Private Lesson Bookings
final myPrivateLessonBookingsProvider =
    FutureProvider<List<PrivateLessonBooking>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null) return [];

  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('private_lesson_bookings')
      .select()
      .eq('student_id', authState.user!.id)
      .order('booking_date', ascending: false);

  return (response as List)
      .map((json) => PrivateLessonBooking.fromJson(json))
      .toList();
});

// Teacher's Bookings (for teacher view)
final teacherBookingsProvider =
    FutureProvider<List<PrivateLessonBooking>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.user == null || !authState.user!.isTeacher) return [];

  final supabase = Supabase.instance.client;

  final response = await supabase
      .from('private_lesson_bookings')
      .select()
      .eq('teacher_id', authState.user!.id)
      .order('booking_date', ascending: false);

  return (response as List)
      .map((json) => PrivateLessonBooking.fromJson(json))
      .toList();
});

// Single Booking
final privateLessonBookingProvider =
    FutureProvider.family<PrivateLessonBooking, String>(
  (ref, bookingId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('private_lesson_bookings')
        .select()
        .eq('id', bookingId)
        .single();

    return PrivateLessonBooking.fromJson(response);
  },
);
