class YoutubeVideoItem {
  const YoutubeVideoItem({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    this.duration = '',
    this.durationSeconds = 0,
  });

  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final String duration;
  final int durationSeconds;
}
