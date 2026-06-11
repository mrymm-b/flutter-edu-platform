import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class SessionResource {
  final String id;
  final String sessionId;
  final String teacherId;
  final String fileName;
  final String fileUrl;
  final String fileType; // pdf, image, other
  final DateTime uploadedAt;

  const SessionResource({
    required this.id,
    required this.sessionId,
    required this.teacherId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.uploadedAt,
  });

  factory SessionResource.fromJson(Map<String, dynamic> j) => SessionResource(
        id: j['id'] as String,
        sessionId: j['session_id'] as String,
        teacherId: j['teacher_id'] as String,
        fileName: j['file_name'] as String,
        fileUrl: j['file_url'] as String,
        fileType: j['file_type'] as String? ?? 'other',
        uploadedAt: DateTime.parse(j['uploaded_at'] as String),
      );

  bool get isPdf => fileType == 'pdf';
  bool get isImage => fileType == 'image';
}

// ── Stream ─────────────────────────────────────────────────────────────────────

final sessionResourcesStreamProvider =
    StreamProvider.autoDispose.family<List<SessionResource>, String>((ref, sessionId) {
  return Supabase.instance.client
      .from('session_resources')
      .stream(primaryKey: ['id'])
      .eq('session_id', sessionId)
      .order('uploaded_at', ascending: false)
      .map((rows) => rows.map((r) => SessionResource.fromJson(r)).toList());
});

// ── Upload Notifier ────────────────────────────────────────────────────────────

class SessionResourcesNotifier extends StateNotifier<bool> {
  // state = isUploading
  final String _sessionId;
  final String _teacherId;
  final _db = Supabase.instance.client;

  SessionResourcesNotifier(this._sessionId, this._teacherId) : super(false);

  Future<bool> upload(File file, String fileName) async {
    if (state) return false; // already uploading
    state = true;
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final fileType = switch (ext) {
        'pdf' => 'pdf',
        'jpg' || 'jpeg' || 'png' || 'webp' => 'image',
        _ => 'other',
      };
      final contentType = switch (fileType) {
        'pdf' => 'application/pdf',
        'image' => 'image/jpeg',
        _ => 'application/octet-stream',
      };

      final storagePath =
          '$_sessionId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _db.storage.from('session-resources').uploadBinary(
            storagePath,
            await file.readAsBytes(),
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      final url = _db.storage.from('session-resources').getPublicUrl(storagePath);

      await _db.from('session_resources').insert({
        'session_id': _sessionId,
        'teacher_id': _teacherId,
        'file_name': fileName,
        'file_url': url,
        'file_type': fileType,
      });
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) state = false;
    }
  }

  Future<void> delete(String resourceId) async {
    try {
      await _db.from('session_resources').delete().eq('id', resourceId);
    } catch (_) {}
  }
}

typedef _ResourcesKey = ({String sessionId, String teacherId});

final sessionResourcesNotifierProvider =
    StateNotifierProvider.autoDispose.family<SessionResourcesNotifier, bool, _ResourcesKey>(
  (ref, args) => SessionResourcesNotifier(args.sessionId, args.teacherId),
);
