import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/utils/cloudinary_video_thumbnail_helper.dart';
import '../../core/config/youtube_config.dart';
import 'youtube_thumbnail_service.dart';

class VideoThumbnailService {
  VideoThumbnailService._();

  static final VideoThumbnailService instance = VideoThumbnailService._();

  final Map<String, _ThumbnailCacheEntry> _cache =
      <String, _ThumbnailCacheEntry>{};
  final Map<String, Future<String?>> _pendingVimeoRequests =
      <String, Future<String?>>{};

  Future<String?> resolve({
    required String imageUrl,
    required String videoUrl,
    required String playlistId,
  }) async {
    final trimmedImageUrl = imageUrl.trim();
    if (trimmedImageUrl.isNotEmpty) {
      return trimmedImageUrl;
    }

    final trimmedPlaylistId = playlistId.trim();
    if (trimmedPlaylistId.isNotEmpty) {
      return YoutubeThumbnailService.instance.getPlaylistThumbnail(
        trimmedPlaylistId,
      );
    }

    final trimmedVideoUrl = videoUrl.trim();
    if (trimmedVideoUrl.isEmpty) {
      return null;
    }

    final cloudinaryThumb =
        CloudinaryVideoThumbnailHelper.thumbnailUrlFromVideoUrl(
          trimmedVideoUrl,
          second: 1,
        );
    if (cloudinaryThumb != null && cloudinaryThumb.isNotEmpty) {
      return cloudinaryThumb;
    }

    final youtubeThumb = youtubeThumbnailFromUrl(trimmedVideoUrl);
    if (youtubeThumb != null) {
      return youtubeThumb;
    }

    final vimeoId = _extractVimeoVideoId(trimmedVideoUrl);
    if (vimeoId == null) {
      return null;
    }

    return _getVimeoThumbnail(vimeoId);
  }

  static String? youtubeThumbnailFromUrl(String videoUrl) {
    final trimmedVideoUrl = videoUrl.trim();
    if (trimmedVideoUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmedVideoUrl);
    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final videoId = uri.pathSegments.isEmpty ? '' : uri.pathSegments.first;
      return videoId.isEmpty
          ? null
          : 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }

    if (!host.contains('youtube.com')) {
      return null;
    }

    final videoId =
        uri.queryParameters['v'] ??
        ((uri.pathSegments.length >= 2 &&
                (uri.pathSegments.first == 'embed' ||
                    uri.pathSegments.first == 'shorts'))
            ? uri.pathSegments[1]
            : '');

    return videoId.isEmpty
        ? null
        : 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  String? _extractVimeoVideoId(String videoUrl) {
    final uri = Uri.tryParse(videoUrl);
    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (!host.contains('vimeo.com')) {
      return null;
    }

    for (final segment in uri.pathSegments.reversed) {
      if (RegExp(r'^\d+$').hasMatch(segment)) {
        return segment;
      }
    }

    return null;
  }

  Future<String?> _getVimeoThumbnail(String videoId) async {
    final cached = _cache[videoId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <
            YoutubeConfig.cacheDuration) {
      return cached.url;
    }

    final pending = _pendingVimeoRequests[videoId];
    if (pending != null) {
      return pending;
    }

    final future = _getVimeoThumbnailInternal(videoId);
    _pendingVimeoRequests[videoId] = future;
    return future.whenComplete(() {
      if (identical(_pendingVimeoRequests[videoId], future)) {
        _pendingVimeoRequests.remove(videoId);
      }
    });
  }

  Future<String?> _getVimeoThumbnailInternal(String videoId) async {
    final uri = Uri.https('player.vimeo.com', '/video/$videoId/config');

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        _cache[videoId] = _ThumbnailCacheEntry(
          url: null,
          cachedAt: DateTime.now(),
        );
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final video =
          payload['video'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final thumbnailUrl = video['thumbnail_url'] as String?;
      _cache[videoId] = _ThumbnailCacheEntry(
        url: thumbnailUrl,
        cachedAt: DateTime.now(),
      );
      return thumbnailUrl;
    } catch (_) {
      _cache[videoId] = _ThumbnailCacheEntry(
        url: null,
        cachedAt: DateTime.now(),
      );
      return null;
    }
  }
}

class _ThumbnailCacheEntry {
  const _ThumbnailCacheEntry({required this.url, required this.cachedAt});

  final String? url;
  final DateTime cachedAt;
}
