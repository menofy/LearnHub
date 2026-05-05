class YoutubeConfig {
  YoutubeConfig._();

  /// YouTube Data API key with quota-controlled fallback.
  ///
  /// Priority:
  /// 1. Custom YOUTUBE_API_KEY via --dart-define (if provided)
  /// 2. Dedicated Google Cloud YouTube Data API key (permanent, quota-controlled)
  ///
  /// This enables permanent YouTube functionality without requiring manual
  /// --dart-define=YOUTUBE_API_KEY=... on every build/run.
  static const String apiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: 'AIzaSyBySASnrDP0BnDlC4v0YYrimdlz3tT0-eo',
  );

  static const String defaultPlaylistId = String.fromEnvironment(
    'YOUTUBE_PLAYLIST_ID',
    defaultValue: 'PLb6ZzJ93PVwpsrq-WMPzdHzoI5BXfMoIj',
  );

  static const int maxResultsPerPage = 10;
  static const Duration cacheDuration = Duration(minutes: 15);
}
