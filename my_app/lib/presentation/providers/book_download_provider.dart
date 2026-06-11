import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DownloadStatus { idle, downloading, downloaded, error }

class BookDownloadState {
  final DownloadStatus status;
  final double progress;
  final String? localPath;
  final String? error;

  const BookDownloadState({
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.localPath,
    this.error,
  });
}

class BookDownloadNotifier
    extends StateNotifier<Map<String, BookDownloadState>> {
  BookDownloadNotifier() : super(const {});

  BookDownloadState stateFor(String bookId) =>
      state[bookId] ?? const BookDownloadState();

  Future<void> downloadAndOpen(String bookId, String storagePath) async {
    if (state[bookId]?.status == DownloadStatus.downloading) return;

    final localPath = await _localPath(bookId);

    // Open cached file without re-downloading
    if (await File(localPath).exists()) {
      _set(bookId, BookDownloadState(
        status: DownloadStatus.downloaded,
        localPath: localPath,
        progress: 1.0,
      ));
      await OpenFilex.open(localPath);
      return;
    }

    _set(bookId, const BookDownloadState(status: DownloadStatus.downloading));

    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('books')
          .createSignedUrl(storagePath, 3600);

      final file = File(localPath);
      await file.parent.create(recursive: true);

      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(signedUrl));
        final response = await request.close();

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }

        final total = response.contentLength;
        final sink = file.openWrite();
        var received = 0;

        await response.forEach((chunk) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0 && mounted) {
            _set(bookId, BookDownloadState(
              status: DownloadStatus.downloading,
              progress: received / total,
            ));
          }
        });

        await sink.close();
      } finally {
        client.close();
      }

      if (!mounted) return;
      _set(bookId, BookDownloadState(
        status: DownloadStatus.downloaded,
        localPath: localPath,
        progress: 1.0,
      ));

      await OpenFilex.open(localPath);
    } catch (e) {
      if (!mounted) return;
      _set(bookId, BookDownloadState(
        status: DownloadStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> openCached(String bookId) async {
    final localPath = await _localPath(bookId);
    if (await File(localPath).exists()) {
      await OpenFilex.open(localPath);
    }
  }

  static Future<String> _localPath(String bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/books/$bookId.pdf';
  }

  void _set(String bookId, BookDownloadState s) {
    state = {...state, bookId: s};
  }
}

final bookDownloadProvider =
    StateNotifierProvider<BookDownloadNotifier, Map<String, BookDownloadState>>(
  (_) => BookDownloadNotifier(),
);
