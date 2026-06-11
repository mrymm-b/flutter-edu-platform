import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/models/conversation.dart';
import '../../../domain/models/message.dart';
import '../../providers/messages_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';

const _kPurple = Color(0xFF6264A7);
const _kDark = Color(0xFF464775);

class StudentConversationDetailPage extends ConsumerStatefulWidget {
  final Conversation conversation;
  const StudentConversationDetailPage({super.key, required this.conversation});

  @override
  ConsumerState<StudentConversationDetailPage> createState() =>
      _StudentConversationDetailPageState();
}

class _StudentConversationDetailPageState
    extends ConsumerState<StudentConversationDetailPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isUploading = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(messagesNotifierProvider.notifier)
          .resetUnread(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ref.read(messagesNotifierProvider.notifier).sendMessage(
          conversationId: widget.conversation.id,
          message: text,
        );
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    if (_isUploading) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked == null || !mounted) return;
    setState(() => _isUploading = true);
    await ref.read(messagesNotifierProvider.notifier).sendMediaMessage(
          conversationId: widget.conversation.id,
          filePath: picked.path,
          messageType: 'image',
        );
    if (mounted) setState(() => _isUploading = false);
    _scrollToBottom();
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });
    _recordingTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingDuration += const Duration(seconds: 1));
    });
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _recorder.cancel();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
      if (path != null) _isUploading = true;
    });
    if (path != null && mounted) {
      await ref.read(messagesNotifierProvider.notifier).sendMediaMessage(
            conversationId: widget.conversation.id,
            filePath: path,
            messageType: 'voice',
          );
      _scrollToBottom();
    }
    if (mounted) setState(() => _isUploading = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(messagesStreamProvider(widget.conversation.id));
    final myId = ref.watch(authProvider).user?.id ?? '';
    final teacherNameAsync =
        ref.watch(studentNameProvider(widget.conversation.teacherId));
    final teacherName = teacherNameAsync.when(
      data: (n) => n,
      loading: () => '...',
      error: (_, __) => 'أستاذ',
    );
    final firstLetter = teacherName.isNotEmpty ? teacherName[0] : 'أ';
    final hasText = _controller.text.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F2F1),
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [_kDark, _kPurple],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    children: [
                      Semantics(
                        label: 'رجوع',
                        identifier: 'conversation_btn_back',
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            firstLetter,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teacherName,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const Text('أستاذ',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFBFC0E0))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Messages ─────────────────────────────────────────────────────
            Expanded(
              child: messagesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: _kPurple)),
                error: (_, __) =>
                    const Center(child: Text('تعذر تحميل الرسائل')),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _kPurple.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 34,
                                color: _kPurple),
                          ),
                          const SizedBox(height: 14),
                          const Text('ابدأ المحادثة',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          const Text('أرسل أول رسالة للأستاذ',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8))),
                        ],
                      ),
                    );
                  }
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _MessageBubble(
                      message: messages[i],
                      isMe: messages[i].senderId == myId,
                    ),
                  );
                },
              ),
            ),

            // ── Upload progress ───────────────────────────────────────────────
            if (_isUploading)
              const LinearProgressIndicator(color: _kPurple, minHeight: 2),

            // ── Input Bar ────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -2)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: SafeArea(
                top: false,
                child: _isRecording
                    ? _buildRecordingBar()
                    : _buildNormalBar(hasText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalBar(bool hasText) {
    return Row(
      children: [
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.image_outlined,
                color: _isUploading ? Colors.grey : _kPurple, size: 22),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Semantics(
              identifier: 'conversation_field_message',
              child: TextField(
                controller: _controller,
                textDirection: TextDirection.rtl,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          identifier: 'conversation_btn_send',
          child: GestureDetector(
            onTap: hasText ? _send : _startRecording,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [_kPurple, _kDark],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasText ? Icons.send_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingBar() {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          _formatDuration(_recordingDuration),
          style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text('جاري التسجيل...',
            style: TextStyle(
                color: Colors.red.withValues(alpha: 0.8), fontSize: 13)),
        const Spacer(),
        Semantics(
          identifier: 'conversation_btn_cancel_recording',
          child: GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          identifier: 'conversation_btn_send_recording',
          child: GestureDetector(
            onTap: _stopAndSendRecording,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [_kPurple, _kDark],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isImage = message.messageType == 'image' && message.mediaUrl != null;
    final isVoice = message.messageType == 'voice' && message.mediaUrl != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: isImage
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [_kPurple, _kDark],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft)
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? _kPurple.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  width: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 200,
                    height: 140,
                    color: Colors.grey[200],
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 200,
                    height: 140,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image_outlined,
                        color: Colors.grey),
                  ),
                ),
              )
            else if (isVoice)
              _VoiceBubble(url: message.mediaUrl!, isMe: isMe)
            else
              Text(
                message.message,
                style: TextStyle(
                    color:
                        isMe ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    height: 1.4),
              ),
            const SizedBox(height: 4),
            Padding(
              padding: isImage
                  ? const EdgeInsets.symmetric(horizontal: 6)
                  : EdgeInsets.zero,
              child: Text(
                '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Voice Bubble ──────────────────────────────────────────────────────────────

class _VoiceBubble extends StatefulWidget {
  final String url;
  final bool isMe;
  const _VoiceBubble({required this.url, required this.isMe});

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged
        .listen((d) { if (mounted) setState(() => _duration = d); });
    _player.onPositionChanged
        .listen((p) { if (mounted) setState(() => _position = p); });
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _position = Duration.zero);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;
    final displayTime =
        (_isPlaying || _position.inSeconds > 0) ? _fmt(_position) : _fmt(_duration);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.isMe
                  ? Colors.white.withValues(alpha: 0.25)
                  : _kPurple.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: widget.isMe ? Colors.white : _kPurple,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  color: widget.isMe ? Colors.white : _kPurple,
                  backgroundColor: widget.isMe
                      ? Colors.white.withValues(alpha: 0.3)
                      : _kPurple.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayTime,
              style: TextStyle(
                fontSize: 11,
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.75)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
