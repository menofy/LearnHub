import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';
import 'package:learnhub/core/shared_widgets/error_retry_state.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:learnhub/features/course/providers/youtube_playlist_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import '../../../core/navigation/route_args.dart';
import 'package:learnhub/core/theme/app_colors.dart';

class YoutubePlaylistScreen extends StatefulWidget {
  const YoutubePlaylistScreen({
    super.key,
    required this.courseTitle,
    required this.playlistId,
    this.courseId,
  });

  final String courseTitle;
  final String playlistId;
  final String? courseId;

  @override
  State<YoutubePlaylistScreen> createState() => _YoutubePlaylistScreenState();
}

class _YoutubePlaylistScreenState extends State<YoutubePlaylistScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<YoutubePlaylistProvider>().loadInitial(
        playlistId: widget.playlistId,
      );
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<YoutubePlaylistProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<YoutubePlaylistProvider>();

    if (provider.isLoading && provider.videos.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: ContentLoadingSkeleton(itemCount: 7, tileHeight: 94),
        ),
      );
    }

    if (provider.errorMessage != null && provider.videos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Course Videos',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: ErrorRetryState(
          message: provider.errorMessage!,
          onRetry: () => provider.loadInitial(playlistId: widget.playlistId),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.courseTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'YouTube Playlist',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.65) ??
                    const Color(AppColors.dark).withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: provider.videos.length + (provider.isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= provider.videos.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          final video = provider.videos[index];
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final cardColor = isDarkMode
              ? Theme.of(context).colorScheme.surface
              : Colors.white;
          final textColor = isDarkMode
              ? Theme.of(context).colorScheme.onSurface
              : const Color(AppColors.dark);
          final mutedColor = isDarkMode
              ? const Color(0xFF9AA6BE)
              : const Color(AppColors.muted);
          final borderColor = isDarkMode
              ? Theme.of(context).colorScheme.outline
              : const Color(AppColors.line);

          return Material(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                final normalizedCourseId = widget.courseId?.trim() ?? '';
                if (normalizedCourseId.isNotEmpty) {
                  context.read<CourseProvider>().saveCoursePlaybackState(
                    courseId: normalizedCourseId,
                    currentLessonIndex: index,
                    lessonId: '${normalizedCourseId}_${video.videoId}',
                    watchedPercent: ((index + 0.35) / provider.videos.length)
                        .clamp(0, 0.98),
                  );
                }
                Navigator.of(context).pushNamed(
                  AppRoutes.youtubeFullscreen,
                  arguments: YoutubeFullscreenArgs(
                    videoId: video.videoId,
                    title: video.title,
                    courseId: normalizedCourseId.isEmpty
                        ? null
                        : normalizedCourseId,
                    lessonId: normalizedCourseId.isEmpty
                        ? null
                        : '${normalizedCourseId}_${video.videoId}',
                    lessonIndex: index,
                    watchedPercent: ((index + 0.35) / provider.videos.length)
                        .clamp(0, 0.98),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        EduCourseThumb(
                          imageUrl: video.thumbnailUrl,
                          width: 110,
                          height: 78,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xCC000000),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            video.channelTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.fullscreen_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
