import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/schedule_item.dart';
import 'auth_provider.dart';

const _kKey   = 'student_schedule_v1';
const _kTable = 'student_schedule';

class ScheduleNotifier extends StateNotifier<List<ScheduleItem>> {
  final Ref _ref;
  // Prevents _load() from overwriting state after the user makes any mutation.
  // Without this flag, a slow Supabase response arriving after remove() would
  // restore the deleted item — causing false conflict errors on the next save.
  bool _mutated = false;

  ScheduleNotifier(this._ref) : super(const []) {
    _load();
  }

  // ── Load ─────────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final userId = _ref.read(authProvider).user?.id;
    if (userId != null) {
      try {
        final rows = await Supabase.instance.client
            .from(_kTable)
            .select()
            .eq('student_id', userId)
            .order('day_of_week')
            .order('time');
        if (!_mutated) {
          state = (rows as List)
              .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
              .toList();
          await _saveToPrefs();
        }
        return;
      } catch (_) {}
    }
    if (!_mutated) {
      await _loadFromPrefs();
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null) return;
    try {
      state = (jsonDecode(raw) as List)
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kKey, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  // ── Mutations ────────────────────────────────────────────────────────────────

  Future<void> add(ScheduleItem item) async {
    _mutated = true;
    state = _normalized([...state, item]);
    await _upsertToSupabase([item]);
    await _saveToPrefs();
  }

  Future<void> addMany(List<ScheduleItem> items) async {
    if (items.isEmpty) return;
    _mutated = true;
    state = _normalized([...state, ...items]);
    await _upsertToSupabase(items);
    await _saveToPrefs();
  }

  Future<void> remove(String id) async {
    _mutated = true;
    state = state.where((e) => e.id != id).toList();
    await _deleteFromSupabase(id);
    await _saveToPrefs();
  }

  // ── Supabase helpers ─────────────────────────────────────────────────────────

  Future<void> _upsertToSupabase(List<ScheduleItem> items) async {
    final userId = _ref.read(authProvider).user?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from(_kTable).upsert(
        items
            .map((e) => {...e.toJson(), 'student_id': userId})
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> _deleteFromSupabase(String id) async {
    final userId = _ref.read(authProvider).user?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from(_kTable)
          .delete()
          .eq('id', id)
          .eq('student_id', userId);
    } catch (_) {}
  }

  // ── Normalise ────────────────────────────────────────────────────────────────

  List<ScheduleItem> _normalized(List<ScheduleItem> items) {
    final unique = <String, ScheduleItem>{};
    for (final item in items) {
      final key =
          '${item.subject}|${item.dayOfWeek}|${item.time}|${item.endTime}';
      unique[key] = item;
    }
    return unique.values.toList()
      ..sort((a, b) {
        final d = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (d != 0) return d;
        return a.time.compareTo(b.time);
      });
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, List<ScheduleItem>>(
  (ref) => ScheduleNotifier(ref),
);

// Today's items — derived synchronously
final todayScheduleProvider = Provider<List<ScheduleItem>>((ref) {
  final all = ref.watch(scheduleProvider);
  final today = DateTime.now().weekday;
  return all.where((item) => item.dayOfWeek == today).toList()
    ..sort((a, b) => a.time.compareTo(b.time));
});
