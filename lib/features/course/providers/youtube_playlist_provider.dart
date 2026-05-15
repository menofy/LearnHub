import 'package:flutter/foundation.dart';
import 'package:learnhub/core/config/youtube_config.dart';
import 'package:learnhub/core/utils/app_error_mapper.dart';
import 'package:learnhub/data/sources/youtube_playlist_data_source.dart';
import 'package:learnhub/domain/entities/youtube_video_item.dart';

class YoutubePlaylistProvider extends ChangeNotifier {
  YoutubePlaylistProvider({YoutubePlaylistDataSource? dataSource})
    : _dataSource = dataSource ?? YoutubePlaylistDataSource();

  final YoutubePlaylistDataSource _dataSource;

  final List<YoutubeVideoItem> _videos = <YoutubeVideoItem>[];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _playlistId;
  String? _nextPageToken;

  List<YoutubeVideoItem> get videos => _videos;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get activePlaylistId => _playlistId ?? YoutubeConfig.defaultPlaylistId;

  Future<void> loadInitial({required String playlistId}) async {
    final targetId = playlistId.trim().isEmpty
        ? YoutubeConfig.defaultPlaylistId
        : playlistId.trim();

    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    _playlistId = targetId;
    _nextPageToken = null;
    _hasMore = true;
    _videos.clear();
    notifyListeners();

    try {
      final result = await _dataSource.fetchPlaylistPage(
        playlistId: targetId,
        maxResults: YoutubeConfig.maxResultsPerPage,
      );
      _videos.addAll(result.items.map((item) => item.toEntity()));
      _nextPageToken = result.nextPageToken;
      _hasMore =
          result.nextPageToken != null && result.nextPageToken!.isNotEmpty;
    } catch (error) {
      _errorMessage = AppErrorMapper.external(
        error,
        fallback: 'Could not load playlist videos.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }
    final playlistId = _playlistId;
    final pageToken = _nextPageToken;
    if (playlistId == null || pageToken == null || pageToken.isEmpty) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _dataSource.fetchPlaylistPage(
        playlistId: playlistId,
        pageToken: pageToken,
        maxResults: YoutubeConfig.maxResultsPerPage,
      );

      final merged = <String>{..._videos.map((item) => item.videoId)};
      for (final item in result.items.map((model) => model.toEntity())) {
        if (merged.add(item.videoId)) {
          _videos.add(item);
        }
      }

      _nextPageToken = result.nextPageToken;
      _hasMore =
          result.nextPageToken != null && result.nextPageToken!.isNotEmpty;
    } catch (error) {
      _errorMessage = AppErrorMapper.external(
        error,
        fallback: 'Could not load more videos.',
      );
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
