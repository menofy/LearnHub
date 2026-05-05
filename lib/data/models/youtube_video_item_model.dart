import '../../domain/entities/youtube_video_item.dart';

class YoutubeVideoItemModel {
  const YoutubeVideoItemModel({
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

  factory YoutubeVideoItemModel.fromMap(Map<String, dynamic> map) {
    final snippet =
        map['snippet'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final contentDetails =
        map['contentDetails'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final resourceId =
        snippet['resourceId'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final thumbnails =
        snippet['thumbnails'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final highThumb =
        thumbnails['high'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final mediumThumb =
        thumbnails['medium'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final defaultThumb =
        thumbnails['default'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final videoId =
        (contentDetails['videoId'] as String?) ??
        (resourceId['videoId'] as String?) ??
        '';

    return YoutubeVideoItemModel(
      videoId: videoId,
      title: (snippet['title'] as String?) ?? 'Untitled Video',
      thumbnailUrl:
          (highThumb['url'] as String?) ??
          (mediumThumb['url'] as String?) ??
          (defaultThumb['url'] as String?) ??
          '',
      channelTitle: (snippet['channelTitle'] as String?) ?? 'YouTube',
    );
  }

  factory YoutubeVideoItemModel.fromCache(Map<String, dynamic> map) {
    return YoutubeVideoItemModel(
      videoId: map['videoId'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Video',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      channelTitle: map['channelTitle'] as String? ?? 'YouTube',
      duration: map['duration'] as String? ?? '',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  YoutubeVideoItemModel copyWith({
    String? videoId,
    String? title,
    String? thumbnailUrl,
    String? channelTitle,
    String? duration,
    int? durationSeconds,
  }) {
    return YoutubeVideoItemModel(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      channelTitle: channelTitle ?? this.channelTitle,
      duration: duration ?? this.duration,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toCacheMap() {
    return <String, dynamic>{
      'videoId': videoId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
      'duration': duration,
      'durationSeconds': durationSeconds,
    };
  }

  YoutubeVideoItem toEntity() {
    return YoutubeVideoItem(
      videoId: videoId,
      title: title,
      thumbnailUrl: thumbnailUrl,
      channelTitle: channelTitle,
      duration: duration,
      durationSeconds: durationSeconds,
    );
  }
}
