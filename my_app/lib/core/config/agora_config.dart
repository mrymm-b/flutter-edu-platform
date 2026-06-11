class AgoraConfig {
  /// Agora App ID — keep this out of version control in production.
  // Get your App ID from https://console.agora.io
  static const String appId = 'YOUR_AGORA_APP_ID';

  /// Channel name is always the course ID.
  static String channelId(String courseId) => courseId;

  /// No token for now (testing mode project).
  /// Replace with a server-generated token before production.
  static const String token = '';
}
