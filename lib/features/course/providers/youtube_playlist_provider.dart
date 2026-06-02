import 'package:flutter/foundation.dart';
import 'package:learnhub/data/sources/youtube_playlist_data_source.dart';
import 'package:learnhub/domain/entities/youtube_video_item.dart';
import 'package:learnhub/features/course/providers/youtube_playlist_paginator.dart';

/// Provider for YouTube playlist functionality
///
/// Delegates pagination logic to [YoutubePlaylistPaginator] to maintain
/// separation of concerns. This class remains the public-facing API.
class YoutubePlaylistProvider extends ChangeNotifier {
  YoutubePlaylistProvider({YoutubePlaylistDataSource? dataSource})
    : _paginator = YoutubePlaylistPaginator(dataSource: dataSource);

  late final YoutubePlaylistPaginator _paginator;

  // Delegated getters
  List<YoutubeVideoItem> get videos => _paginator.videos;
  bool get isLoading => _paginator.isLoading;
  bool get isLoadingMore => _paginator.isLoadingMore;
  bool get hasMore => _paginator.hasMore;
  String? get errorMessage => _paginator.errorMessage;
  String get activePlaylistId => _paginator.activePlaylistId;

  /// Load initial playlist videos
  Future<void> loadInitial({required String playlistId}) async {
    await _paginator.loadInitial(playlistId: playlistId);
    notifyListeners();
  }

  /// Load additional videos (pagination)
  Future<void> loadMore() async {
    await _paginator.loadMore();
    notifyListeners();
  }
}
