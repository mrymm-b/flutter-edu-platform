class LiveSession {
  final String id;
  final String courseId;
  final String teacherId;
  final String title;
  final String? description;
  final String status; // scheduled, live, ended
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? recordingUrl;
  final String agoraChannelName;
  final int viewersCount;
  final int? durationMinutes;
  final DateTime createdAt;

  LiveSession({
    required this.id,
    required this.courseId,
    required this.teacherId,
    required this.title,
    this.description,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    this.recordingUrl,
    required this.agoraChannelName,
    required this.viewersCount,
    this.durationMinutes,
    required this.createdAt,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      teacherId: json['teacher_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      recordingUrl: json['recording_url'] as String?,
      agoraChannelName: (json['agora_channel_name'] as String?) ?? '',
      viewersCount: (json['viewers_count'] as int?) ?? 0,
      durationMinutes: json['duration_minutes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'status': status,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'recording_url': recordingUrl,
      'agora_channel_name': agoraChannelName,
      'viewers_count': viewersCount,
      'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helpers
  bool get isLive => status == 'live';
  bool get isEnded => status == 'ended';
  bool get isScheduled => status == 'scheduled';
}
