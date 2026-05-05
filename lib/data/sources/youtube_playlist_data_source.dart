import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/youtube_config.dart';
import '../models/youtube_video_item_model.dart';

class YoutubePlaylistPageResult {
  const YoutubePlaylistPageResult({
    required this.items,
    required this.nextPageToken,
  });

  final List<YoutubeVideoItemModel> items;
  final String? nextPageToken;
}

class YoutubePlaylistDataSource {
  YoutubePlaylistDataSource({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<YoutubeVideoItemModel>> fetchAllPlaylistItems({
    required String playlistId,
  }) async {
    final items = <YoutubeVideoItemModel>[];
    String? nextPageToken;

    do {
      final page = await fetchPlaylistPage(
        playlistId: playlistId,
        pageToken: nextPageToken,
        maxResults: 50,
      );
      items.addAll(page.items);
      nextPageToken = page.nextPageToken;
    } while (nextPageToken != null && nextPageToken.isNotEmpty);

    return items;
  }

  Future<YoutubePlaylistPageResult> fetchPlaylistPage({
    required String playlistId,
    String? pageToken,
    int maxResults = YoutubeConfig.maxResultsPerPage,
  }) async {
    final cacheKey = _buildCacheKey(playlistId, pageToken);
    final prefs = await SharedPreferences.getInstance();

    final cachedRaw = prefs.getString(cacheKey);
    if (cachedRaw != null) {
      final cached = jsonDecode(cachedRaw) as Map<String, dynamic>;
      final cachedAtMillis = cached['cachedAt'] as int? ?? 0;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMillis);
      final isFresh =
          DateTime.now().difference(cachedAt) < YoutubeConfig.cacheDuration;
      if (isFresh) {
        final cachedResult = _resultFromCache(cached);
        final hasDurationData = cachedResult.items.every(
          (item) => item.duration.isNotEmpty,
        );
        if (hasDurationData) {
          return cachedResult;
        }
      }
    }

    final apiKey = YoutubeConfig.apiKey.trim();
    if (_isMissingOrPlaceholderApiKey(apiKey)) {
      throw Exception(
        'Invalid YouTube API key. Build with --dart-define=YOUTUBE_API_KEY=YOUR_ACTUAL_KEY',
      );
    }

    final uri = Uri.https(
      'www.googleapis.com',
      '/youtube/v3/playlistItems',
      <String, String>{
        'part': 'snippet,contentDetails',
        'playlistId': playlistId,
        'maxResults': '$maxResults',
        'key': apiKey,
        if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      final apiMessage = _extractApiErrorMessage(response.body);
      if (apiMessage != null && apiMessage.isNotEmpty) {
        throw Exception(
          'YouTube API error (${response.statusCode}): $apiMessage',
        );
      }
      throw Exception('YouTube API error (${response.statusCode}).');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final itemsRaw = payload['items'] as List<dynamic>? ?? <dynamic>[];
    final baseItems = itemsRaw
        .map(
          (item) => YoutubeVideoItemModel.fromMap(item as Map<String, dynamic>),
        )
        .where((item) => item.videoId.isNotEmpty)
        .toList();
    final durationsByVideoId = await _fetchDurationsByVideoId(
      videoIds: baseItems.map((item) => item.videoId).toList(growable: false),
      apiKey: apiKey,
    );
    final items = baseItems
        .map(
          (item) => item.copyWith(
            duration: durationsByVideoId[item.videoId]?.label ?? '',
            durationSeconds: durationsByVideoId[item.videoId]?.seconds ?? 0,
          ),
        )
        .toList(growable: false);

    final result = YoutubePlaylistPageResult(
      items: items,
      nextPageToken: payload['nextPageToken'] as String?,
    );

    await prefs.setString(
      cacheKey,
      jsonEncode(<String, dynamic>{
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'nextPageToken': result.nextPageToken,
        'items': result.items.map((item) => item.toCacheMap()).toList(),
      }),
    );

    return result;
  }

  YoutubePlaylistPageResult _resultFromCache(Map<String, dynamic> cacheMap) {
    final rawItems = cacheMap['items'] as List<dynamic>? ?? <dynamic>[];
    final items = rawItems
        .map(
          (item) =>
              YoutubeVideoItemModel.fromCache(item as Map<String, dynamic>),
        )
        .toList();

    return YoutubePlaylistPageResult(
      items: items,
      nextPageToken: cacheMap['nextPageToken'] as String?,
    );
  }

  String _buildCacheKey(String playlistId, String? pageToken) {
    final token = (pageToken == null || pageToken.isEmpty)
        ? 'first'
        : pageToken;
    return 'yt_playlist_cache_${playlistId}_$token';
  }

  bool _isMissingOrPlaceholderApiKey(String apiKey) {
    if (apiKey.isEmpty) return true;
    final normalized = apiKey.toUpperCase();
    return normalized == 'YOUR_KEY' ||
        normalized == 'YOUR_REAL_KEY' ||
        normalized.contains('YOUR_');
  }

  String? _extractApiErrorMessage(String responseBody) {
    try {
      final payload = jsonDecode(responseBody) as Map<String, dynamic>;
      final error = payload['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'] as String?;
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignore parsing failures and use fallback message.
    }
    return null;
  }

  Future<Map<String, _YoutubeVideoDuration>> _fetchDurationsByVideoId({
    required List<String> videoIds,
    required String apiKey,
  }) async {
    if (videoIds.isEmpty) {
      return const <String, _YoutubeVideoDuration>{};
    }

    final uri =
        Uri.https('www.googleapis.com', '/youtube/v3/videos', <String, String>{
          'part': 'contentDetails',
          'id': videoIds.join(','),
          'key': apiKey,
          'maxResults': '${videoIds.length}',
        });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      return <String, _YoutubeVideoDuration>{};
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = payload['items'] as List<dynamic>? ?? <dynamic>[];
    final durationsByVideoId = <String, _YoutubeVideoDuration>{};

    for (final item in items) {
      final data = item as Map<String, dynamic>;
      final videoId = data['id'] as String? ?? '';
      final contentDetails =
          data['contentDetails'] as Map<String, dynamic>? ??
          <String, dynamic>{};
      final rawDuration = contentDetails['duration'] as String? ?? '';
      final seconds = _parseIso8601DurationToSeconds(rawDuration);
      durationsByVideoId[videoId] = _YoutubeVideoDuration(
        seconds: seconds,
        label: _formatVideoDuration(seconds),
      );
    }

    return durationsByVideoId;
  }

  int _parseIso8601DurationToSeconds(String value) {
    final match = RegExp(
      r'^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$',
    ).firstMatch(value);
    if (match == null) {
      return 0;
    }

    final hours = int.tryParse(match.group(1) ?? '') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '') ?? 0;
    return (hours * 3600) + (minutes * 60) + seconds;
  }

  String _formatVideoDuration(int totalSeconds) {
    if (totalSeconds <= 0) {
      return '0:00';
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _YoutubeVideoDuration {
  const _YoutubeVideoDuration({required this.seconds, required this.label});

  final int seconds;
  final String label;
}
