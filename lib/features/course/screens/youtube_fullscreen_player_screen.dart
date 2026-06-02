import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeFullscreenPlayerScreen extends StatefulWidget {
  const YoutubeFullscreenPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    this.courseId,
    this.lessonId,
    this.lessonIndex,
    this.watchedPercent,
  });

  final String videoId;
  final String title;
  final String? courseId;
  final String? lessonId;
  final int? lessonIndex;
  final double? watchedPercent;

  @override
  State<YoutubeFullscreenPlayerScreen> createState() =>
      _YoutubeFullscreenPlayerScreenState();
}

class _YoutubeFullscreenPlayerScreenState
    extends State<YoutubeFullscreenPlayerScreen> {
  late final YoutubePlayerController _controller;
  bool _hasMarkedComplete = false;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
    _controller.addListener(_handleYoutubePlayerState);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final courseId = widget.courseId?.trim() ?? '';
      if (!mounted || courseId.isEmpty) {
        return;
      }
      final provider = context.read<CourseProvider>();
      await provider.loadLessons(courseId, showLoading: false);
      if (!mounted) {
        return;
      }
      provider.saveCoursePlaybackState(
        courseId: courseId,
        currentLessonIndex: _resolvedLessonIndex(provider, courseId),
        lessonId: _resolvedLessonId(provider, courseId),
        watchedPercent: _startedWatchedPercent(provider, courseId),
      );
    });
  }

  @override
  void dispose() {
    _isDisposing = true;
    _controller.removeListener(_handleYoutubePlayerState);
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  int _resolvedLessonIndex(CourseProvider provider, String courseId) {
    final lessons = provider.lessonsByCourse(courseId);
    final requestedIndex = widget.lessonIndex ?? 0;
    if (lessons.isEmpty) {
      return requestedIndex < 0 ? 0 : requestedIndex;
    }
    if (requestedIndex < 0) {
      return 0;
    }
    if (requestedIndex >= lessons.length) {
      return lessons.length - 1;
    }
    return requestedIndex;
  }

  String? _resolvedLessonId(CourseProvider provider, String courseId) {
    final explicitLessonId = widget.lessonId?.trim() ?? '';
    final lessons = provider.lessonsByCourse(courseId);
    if (explicitLessonId.isNotEmpty &&
        lessons.any((lesson) => lesson.id == explicitLessonId)) {
      return explicitLessonId;
    }

    final lessonIndex = _resolvedLessonIndex(provider, courseId);
    if (lessonIndex >= 0 && lessonIndex < lessons.length) {
      return lessons[lessonIndex].id;
    }

    return explicitLessonId.isEmpty ? null : explicitLessonId;
  }

  int _resolvedTotalLessons(CourseProvider provider, String courseId) {
    final lessons = provider.lessonsByCourse(courseId);
    if (lessons.isNotEmpty) {
      return lessons.length;
    }
    final fallbackIndex = widget.lessonIndex ?? 0;
    return fallbackIndex >= 0 ? fallbackIndex + 1 : 1;
  }

  double _startedWatchedPercent(CourseProvider provider, String courseId) {
    final totalLessons = _resolvedTotalLessons(provider, courseId);
    if (totalLessons <= 0) {
      return (widget.watchedPercent ?? 0.35).clamp(0, 1).toDouble();
    }
    final fallbackPercent =
        ((_resolvedLessonIndex(provider, courseId) + 0.35) / totalLessons)
            .clamp(0, 0.98)
            .toDouble();
    return (widget.watchedPercent ?? fallbackPercent).clamp(0, 0.98).toDouble();
  }

  double _completedWatchedPercent(CourseProvider provider, String courseId) {
    final totalLessons = _resolvedTotalLessons(provider, courseId);
    if (totalLessons <= 0) {
      return 1.0;
    }
    return ((_resolvedLessonIndex(provider, courseId) + 1) / totalLessons)
        .clamp(0, 1)
        .toDouble();
  }

  void _handleYoutubePlayerState() {
    if (!mounted || _isDisposing || _hasMarkedComplete) {
      return;
    }

    final courseId = widget.courseId?.trim() ?? '';
    if (courseId.isEmpty) {
      return;
    }

    final playerValue = _controller.value;
    final duration = playerValue.metaData.duration;
    final hasDuration = duration.inMilliseconds > 0;
    final remaining = hasDuration ? duration - playerValue.position : null;
    final reachedEnd =
        playerValue.playerState == PlayerState.ended ||
        (remaining != null &&
            !remaining.isNegative &&
            remaining <= const Duration(seconds: 2));

    if (!reachedEnd) {
      return;
    }

    _hasMarkedComplete = true;
    _markYoutubeLessonCompleted(courseId);
  }

  Future<void> _markYoutubeLessonCompleted(String courseId) async {
    final provider = context.read<CourseProvider>();
    if (provider.lessonsByCourse(courseId).isEmpty) {
      await provider.loadLessons(courseId, showLoading: false);
      if (!mounted) {
        return;
      }
    }

    final lessonId = _resolvedLessonId(provider, courseId);
    final lessonIndex = _resolvedLessonIndex(provider, courseId);
    if (lessonId == null || lessonId.isEmpty) {
      _hasMarkedComplete = false;
      return;
    }

    try {
      await provider.markLessonCompleted(
        courseId: courseId,
        lessonId: lessonId,
      );
      if (!mounted) {
        return;
      }

      final completedIndexes = provider.completedLessonIndexesForCourse(
        courseId,
      )..add(lessonIndex);
      provider.saveCoursePlaybackState(
        courseId: courseId,
        currentLessonIndex: lessonIndex,
        lessonId: lessonId,
        completedLessonIndexes: completedIndexes,
        watchedPercent: _completedWatchedPercent(provider, courseId),
      );
    } catch (_) {
      _hasMarkedComplete = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.redAccent,
              ),
            ),
            Positioned(
              left: 16,
              top: 10,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
