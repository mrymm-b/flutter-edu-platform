import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_tokens.dart';
import '../../core/utils/toast.dart';
import '../providers/book_download_provider.dart';

/// Stateful 4-state download button for PDF books.
/// Pass [t] for token-aware outline style (used inside cards).
/// Without [t] falls back to the original solid-color style.
class PdfDownloadButton extends ConsumerStatefulWidget {
  final String bookId;
  final String storagePath;
  final Tok? t;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const PdfDownloadButton({
    super.key,
    required this.bookId,
    required this.storagePath,
    this.t,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.borderRadius = 12,
  });

  @override
  ConsumerState<PdfDownloadButton> createState() => _PdfDownloadButtonState();
}

class _PdfDownloadButtonState extends ConsumerState<PdfDownloadButton> {
  @override
  Widget build(BuildContext context) {
    ref.listen<Map<String, BookDownloadState>>(
      bookDownloadProvider,
      (prev, next) {
        if (!mounted) return;
        final prevStatus = prev?[widget.bookId]?.status;
        final nextStatus = next[widget.bookId]?.status;
        if (prevStatus != DownloadStatus.downloading) return;
        if (nextStatus == DownloadStatus.downloaded) {
          showAppToast(context,
              message: 'تم تنزيل الملف بنجاح', type: ToastType.success);
        } else if (nextStatus == DownloadStatus.error) {
          showAppToast(context,
              message: 'تعذر تنزيل الملف', type: ToastType.error);
        }
      },
    );

    final dlState =
        ref.watch(bookDownloadProvider)[widget.bookId] ?? const BookDownloadState();
    final t = widget.t;

    if (t != null) {
      // ── Token-aware outline style ──────────────────────────────────────────
      return switch (dlState.status) {
        DownloadStatus.downloading => _outlineBtn(
            t: t,
            icon: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: dlState.progress > 0 ? dlState.progress : null,
                strokeWidth: 2,
                color: t.accentFg,
              ),
            ),
            label: dlState.progress > 0
                ? '${(dlState.progress * 100).toInt()}%'
                : 'جاري التحميل...',
            bg: t.accentTint,
            fg: t.accentFg,
            border: t.accentLine,
            onPressed: null,
          ),
        DownloadStatus.downloaded => _outlineBtn(
            t: t,
            icon: Icon(Icons.open_in_new_rounded, size: 15, color: t.accentFg),
            label: 'فتح PDF',
            bg: t.accentTint,
            fg: t.accentFg,
            border: t.accentLine,
            onPressed: () =>
                ref.read(bookDownloadProvider.notifier).openCached(widget.bookId),
          ),
        DownloadStatus.error => _outlineBtn(
            t: t,
            icon: Icon(Icons.refresh_rounded, size: 15,
                color: const Color(0xFFDC2626)),
            label: 'إعادة المحاولة',
            bg: const Color(0xFFDC2626).withValues(alpha: t.isDark ? 0.15 : 0.08),
            fg: const Color(0xFFDC2626),
            border: const Color(0xFFDC2626).withValues(alpha: 0.35),
            onPressed: () => ref
                .read(bookDownloadProvider.notifier)
                .downloadAndOpen(widget.bookId, widget.storagePath),
          ),
        DownloadStatus.idle => _outlineBtn(
            t: t,
            icon: Icon(Icons.download_rounded, size: 15, color: t.accentFg),
            label: 'تحميل PDF',
            bg: t.accentTint,
            fg: t.accentFg,
            border: t.accentLine,
            onPressed: widget.storagePath.isEmpty
                ? null
                : () => ref
                    .read(bookDownloadProvider.notifier)
                    .downloadAndOpen(widget.bookId, widget.storagePath),
          ),
      };
    }

    // ── Legacy solid-color style (used standalone outside cards) ─────────────
    return switch (dlState.status) {
      DownloadStatus.downloading => _solidBtn(
          icon: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              value: dlState.progress > 0 ? dlState.progress : null,
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          label: dlState.progress > 0
              ? '${(dlState.progress * 100).toInt()}%'
              : 'جاري...',
          color: const Color(0xFF0D8A0D),
          onPressed: null,
        ),
      DownloadStatus.downloaded => _solidBtn(
          icon: const Icon(Icons.open_in_new_rounded, size: 16),
          label: 'فتح PDF',
          color: const Color(0xFF6264A7),
          onPressed: () =>
              ref.read(bookDownloadProvider.notifier).openCached(widget.bookId),
        ),
      DownloadStatus.error => _solidBtn(
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: 'إعادة المحاولة',
          color: const Color(0xFFDC2626),
          onPressed: () => ref
              .read(bookDownloadProvider.notifier)
              .downloadAndOpen(widget.bookId, widget.storagePath),
        ),
      DownloadStatus.idle => _solidBtn(
          icon: const Icon(Icons.download_rounded, size: 16),
          label: 'تحميل PDF',
          color: const Color(0xFF13A10E),
          onPressed: widget.storagePath.isEmpty
              ? null
              : () => ref
                  .read(bookDownloadProvider.notifier)
                  .downloadAndOpen(widget.bookId, widget.storagePath),
        ),
    };
  }

  Widget _outlineBtn({
    required Tok t,
    required Widget icon,
    required String label,
    required Color bg,
    required Color fg,
    required Color border,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: onPressed == null ? bg.withValues(alpha: 0.6) : bg,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    color: fg,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _solidBtn({
    required Widget icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.75),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        padding: widget.padding,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius)),
        elevation: 0,
      ),
    );
  }
}
