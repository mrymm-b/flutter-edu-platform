import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_tokens.dart';
import '../../../core/utils/toast.dart';
import '../../../domain/models/book.dart';
import '../../../domain/models/live_session.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/atmosphere_background.dart';
import '../../widgets/glass_card.dart';
import 'upload_material_page.dart';

class CourseMaterialsPage extends ConsumerWidget {
  final String courseId;
  final String courseTitle;

  const CourseMaterialsPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Tok.of(context);
    final booksAsync = ref.watch(teacherCourseBooksProvider(courseId));
    final recordingsAsync =
        ref.watch(teacherCourseRecordingsProvider(courseId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppTokens.screenPad, 16, AppTokens.screenPad, 12),
                    child: Row(
                      children: [
                        Semantics(
                          label: 'رجوع',
                          identifier: 'materials_btn_back',
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: t.isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : t.bg2,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.rSm),
                                border: Border.all(color: t.line),
                              ),
                              child: Icon(Icons.arrow_back_ios_new,
                                  color: t.ink2, size: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                courseTitle,
                                style: TextStyle(
                                  fontSize: AppTokens.tsAppBar,
                                  fontWeight: FontWeight.w700,
                                  color: t.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'إدارة المحتوى',
                                style:
                                    TextStyle(fontSize: 12, color: t.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppTokens.screenPad, 0,
                    AppTokens.screenPad, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Upload CTA ───────────────────────────────────────
                    Semantics(
                      identifier: 'materials_btn_upload_book',
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UploadMaterialPage(courseId: courseId),
                          ),
                        ).then((_) => ref
                            .invalidate(teacherCourseBooksProvider(courseId))),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius:
                                BorderRadius.circular(AppTokens.rLg),
                            border: Border.all(
                                color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF16A34A),
                                      Color(0xFF15803D)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.upload_file_rounded,
                                    color: Colors.white,
                                    size: 24),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'رفع ملزمة جديدة',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'PDF • يصل للطلاب فوراً',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF4ADE80)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_left,
                                  color: Color(0xFF16A34A), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Books Section header ──────────────────────────────
                    _SectionHeader(
                      icon: Icons.description_rounded,
                      iconColor: const Color(0xFF16A34A),
                      title: 'الملازم',
                      t: t,
                    ),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),

              // ── Books List ───────────────────────────────────────────────
              booksAsync.when(
                loading: () => SliverToBoxAdapter(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: t.accentFg)),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppTokens.screenPad),
                    child: Text('تعذر تحميل الملازم',
                        style: TextStyle(color: t.muted)),
                  ),
                ),
                data: (books) {
                  if (books.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyState(
                        icon: Icons.description_outlined,
                        text: 'لا توجد ملازم بعد',
                        t: t,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.screenPad),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _BookItem(
                          book: books[i],
                          t: t,
                          onDelete: () =>
                              _confirmDelete(context, ref, books[i]),
                        ),
                        childCount: books.length,
                      ),
                    ),
                  );
                },
              ),

              // ── Recordings Section ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.screenPad, 20, AppTokens.screenPad, 12),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(
                    icon: Icons.play_circle_rounded,
                    iconColor: t.accentFg,
                    title: 'التسجيلات',
                    t: t,
                  ),
                ),
              ),

              recordingsAsync.when(
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppTokens.screenPad),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: t.accentFg)),
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(AppTokens.screenPad),
                    child: Text('تعذر تحميل التسجيلات',
                        style: TextStyle(color: t.muted)),
                  ),
                ),
                data: (recordings) {
                  if (recordings.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _EmptyState(
                        icon: Icons.videocam_off_outlined,
                        text: 'لا توجد تسجيلات بعد',
                        t: t,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppTokens.screenPad, 0, AppTokens.screenPad, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _RecordingItem(
                          session: recordings[i],
                          courseId: courseId,
                        ),
                        childCount: recordings.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Book book) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444), size: 28),
                ),
                const SizedBox(height: 16),
                const Text('حذف الملزمة',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'هل تريد حذف "${book.title}"؟\nلا يمكن التراجع عن هذا الإجراء.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.5),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(
                              color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء',
                            style:
                                TextStyle(color: Color(0xFF64748B))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await Supabase.instance.client
                                .from('books')
                                .delete()
                                .eq('id', book.id);
                            ref.invalidate(
                                teacherCourseBooksProvider(courseId));
                            if (context.mounted) {
                              showAppToast(context,
                                  message: 'تم حذف "${book.title}"',
                                  color: const Color(0xFF6264A7));
                            }
                          } catch (_) {
                            if (context.mounted) {
                              showAppToast(context,
                                  message: 'فشل الحذف، حاول مجدداً',
                                  type: ToastType.error);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        child: const Text('حذف',
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Tok t;
  const _SectionHeader(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: t.ink)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Tok t;
  const _EmptyState(
      {required this.icon, required this.text, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTokens.screenPad, 0, AppTokens.screenPad, 8),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: t.faint),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: t.muted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _BookItem extends StatelessWidget {
  final Book book;
  final Tok t;
  final VoidCallback onDelete;

  const _BookItem(
      {required this.book, required this.t, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: t.ink,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 3),
                  Text(book.fileSizeInMB,
                      style: TextStyle(
                          color: t.muted, fontSize: 12)),
                ],
              ),
            ),
            Semantics(
              label: 'حذف',
              identifier:
                  'materials_btn_delete_book_${book.id.substring(0, 8)}',
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 44, minWidth: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('حذف',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingItem extends ConsumerStatefulWidget {
  final LiveSession session;
  final String courseId;
  const _RecordingItem({required this.session, required this.courseId});

  @override
  ConsumerState<_RecordingItem> createState() => _RecordingItemState();
}

class _RecordingItemState extends ConsumerState<_RecordingItem> {
  bool _uploading = false;

  Future<void> _uploadRecording() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null || result.files.single.path == null || !mounted) {
      return;
    }

    setState(() => _uploading = true);
    try {
      final bytes =
          await File(result.files.single.path!).readAsBytes();
      final fileName =
          '${widget.session.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await Supabase.instance.client.storage
          .from('recordings')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions:
                const FileOptions(contentType: 'video/mp4'),
          );

      await Supabase.instance.client
          .from('live_sessions')
          .update({'recording_url': fileName}).eq('id', widget.session.id);

      ref.invalidate(
          teacherCourseRecordingsProvider(widget.courseId));
      if (mounted) {
        showAppToast(context,
            message: 'تم رفع التسجيل بنجاح',
            color: const Color(0xFF6264A7));
      }
    } catch (_) {
      if (mounted) {
        showAppToast(context,
            message: 'تعذّر رفع التسجيل، حاول مجدداً',
            type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    final hasRecording = widget.session.recordingUrl != null;
    final duration = widget.session.durationMinutes != null
        ? '${widget.session.durationMinutes} دقيقة'
        : _formatDate(widget.session.endedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6264A7), Color(0xFF464775)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_circle_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.session.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: t.ink,
                            fontSize: 14,
                          )),
                      const SizedBox(height: 3),
                      Text(duration,
                          style: TextStyle(
                              color: t.muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (hasRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: t.accentTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('مسجّل',
                        style: TextStyle(
                          color: t.accentFg,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        )),
                  )
                else
                  Semantics(
                    identifier:
                        'materials_btn_upload_recording_${widget.session.id.substring(0, 8)}',
                    child: GestureDetector(
                      onTap: _uploading ? null : _uploadRecording,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF86EFAC)),
                        ),
                        child: _uploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF16A34A)),
                              )
                            : const Text('رفع تسجيل',
                                style: TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                )),
                      ),
                    ),
                  ),
              ],
            ),
            if (_uploading) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                  color: t.accentFg, minHeight: 2),
              const SizedBox(height: 4),
              Text('جاري رفع التسجيل...',
                  style: TextStyle(color: t.muted, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}
