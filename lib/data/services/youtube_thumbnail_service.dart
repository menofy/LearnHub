import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/youtube_config.dart';

class YoutubeThumbnailService {
  YoutubeThumbnailService._();

  static final YoutubeThumbnailService instance = YoutubeThumbnailService._();
  final Map<String, _ThumbnailCacheEntry> _cache =
      <String, _ThumbnailCacheEntry>{};
  final Map<String, Future<String?>> _pendingRequests =
      <String, Future<String?>>{};

  Future<String?> getPlaylistThumbnail(String playlistId) async {
    final key = playlistId.trim();
    if (key.isEmpty) {
      return null;
    }
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <
            YoutubeConfig.cacheDuration) {
      return cached.url;
    }

    final pending = _pendingRequests[key];
    if (pending != null) {
      return pending;
    }

    final future = _getPlaylistThumbnailInternal(key);
    _pendingRequests[key] = future;
    return future.whenComplete(() {
      if (identical(_pendingRequests[key], future)) {
        _pendingRequests.remove(key);
      }
    });
  }

  Future<String?> _getPlaylistThumbnailInternal(String key) async {
    final apiKey = YoutubeConfig.apiKey.trim();
    if (apiKey.isEmpty) {
      _cache[key] = _ThumbnailCacheEntry(url: null, cachedAt: DateTime.now());
      return null;
    }

    final uri = Uri.https(
      'www.googleapis.com',
      '/youtube/v3/playlistItems',
      <String, String>{
        'part': 'snippet',
        'playlistId': key,
        'maxResults': '1',
        'key': apiKey,
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        _cache[key] = _ThumbnailCacheEntry(url: null, cachedAt: DateTime.now());
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final items = payload['items'] as List<dynamic>? ?? <dynamic>[];
      if (items.isEmpty) {
        _cache[key] = _ThumbnailCacheEntry(url: null, cachedAt: DateTime.now());
        return null;
      }

      final first = items.first as Map<String, dynamic>;
      final snippet =
          first['snippet'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final thumbs =
          snippet['thumbnails'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final high =
          thumbs['high'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final medium =
          thumbs['medium'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final url = (high['url'] ?? medium['url']) as String?;
      _cache[key] = _ThumbnailCacheEntry(url: url, cachedAt: DateTime.now());
      return url;
    } catch (_) {
      _cache[key] = _ThumbnailCacheEntry(url: null, cachedAt: DateTime.now());
      return null;
    }
  }
}

class _ThumbnailCacheEntry {
  const _ThumbnailCacheEntry({required this.url, required this.cachedAt});

  final String? url;
  final DateTime cachedAt;
}
