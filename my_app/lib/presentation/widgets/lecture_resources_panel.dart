import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/session_resources_provider.dart';

// ── Panel ─────────────────────────────────────────────────────────────────────

class LectureResourcesPanel extends ConsumerWidget {
  final String sessionId;
  final String? teacherId; // non-null for teacher (enables upload/delete)
  final VoidCallback onClose;

  const LectureResourcesPanel({
    super.key,
    required this.sessionId,
    required this.onClose,
    this.teacherId,
  });

  bool get isTeacher => teacherId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resources = ref.watch(sessionResourcesStreamProvider(sessionId));
    final isUploading = isTeacher
        ? ref.watch(sessionResourcesNotifierProvider(
            (sessionId: sessionId, teacherId: teacherId!)))
        : false;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle + header
          _Header(
            isTeacher: isTeacher,
            isUploading: isUploading,
            onClose: onClose,
            onUpload: isTeacher ? () => _pickAndUpload(context, ref) : null,
          ),

          // Content
          Expanded(
            child: resources.when(
              data: (list) => list.isEmpty
                  ? _EmptyState(isTeacher: isTeacher)
                  : _ResourceList(
                      resources: list,
                      isTeacher: isTeacher,
                      onDelete: isTeacher
                          ? (r) => ref
                              .read(sessionResourcesNotifierProvider(
                                (sessionId: sessionId, teacherId: teacherId!)).notifier)
                              .delete(r.id)
                          : null,
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF6264A7)),
              ),
              error: (_, __) => const Center(
                child: Text('تعذر تحميل الملفات',
                    style: TextStyle(color: Colors.white38, fontFamily: 'Cairo')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'ppt', 'pptx', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;

    final notifier = ref.read(
      sessionResourcesNotifierProvider(
              (sessionId: sessionId, teacherId: teacherId!))
          .notifier,
    );
    final ok = await notifier.upload(File(picked.path!), picked.name);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok ? 'تم رفع الملف بنجاح' : 'تعذر رفع الملف',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: ok ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
      ));
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isTeacher;
  final bool isUploading;
  final VoidCallback onClose;
  final VoidCallback? onUpload;

  const _Header({
    required this.isTeacher,
    required this.isUploading,
    required this.onClose,
    this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.folder_open_rounded, color: Color(0xFF6264A7), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('ملفات الحصة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo')),
              ),
              if (isTeacher && onUpload != null)
                isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Color(0xFF6264A7), strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.upload_file_rounded,
                            color: Color(0xFF6264A7), size: 22),
                        onPressed: onUpload,
                        tooltip: 'رفع ملف',
                      ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }
}

// ── Resource List ─────────────────────────────────────────────────────────────

class _ResourceList extends StatelessWidget {
  final List<SessionResource> resources;
  final bool isTeacher;
  final void Function(SessionResource)? onDelete;

  const _ResourceList({
    required this.resources,
    required this.isTeacher,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: resources.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ResourceTile(
        resource: resources[i],
        isTeacher: isTeacher,
        onDelete: onDelete != null ? () => onDelete!(resources[i]) : null,
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final SessionResource resource;
  final bool isTeacher;
  final VoidCallback? onDelete;

  const _ResourceTile({
    required this.resource,
    required this.isTeacher,
    this.onDelete,
  });

  IconData get _icon {
    if (resource.isPdf) return Icons.picture_as_pdf_rounded;
    if (resource.isImage) return Icons.image_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color get _iconColor {
    if (resource.isPdf) return const Color(0xFFEF4444);
    if (resource.isImage) return const Color(0xFF22C55E);
    return const Color(0xFF6264A7);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.fileName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(resource.uploadedAt),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            ),
            // Open button
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white38, size: 18),
              onPressed: () => _open(context),
            ),
            // Delete (teacher only)
            if (isTeacher && onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(resource.fileUrl);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تعذر فتح الملف', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Color(0xFFEF4444),
      ));
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isTeacher;

  const _EmptyState({required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_off_outlined, color: Colors.white24, size: 52),
          const SizedBox(height: 12),
          Text(
            isTeacher ? 'لم تُرفع ملفات بعد\nاضغط على زر الرفع لإضافة ملف'
                      : 'لم يرفع الأستاذ ملفات بعد',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white38, fontSize: 13, fontFamily: 'Cairo', height: 1.5),
          ),
        ],
      ),
    );
  }
}
