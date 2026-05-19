import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import '../../../core/navigation/route_args.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import '../../../domain/entities/course.dart';
import '../../../domain/entities/lesson.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.lesson,
    required this.courseId,
    required this.courseTitle,
    this.course,
  });

  final Lesson lesson;
  final String courseId;
  final String courseTitle;
  final Course? course;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final BetterPlayerController _controller;

  int _currentLessonIndex = 0;
  Set<int> _completedLessonIndexes = <int>{};
  double _watchedProgressPercent = 0;
  String? _activeLessonId;
  String _lessonSignature = '';
  bool _completionDialogShown = false;
  bool _isLoadingLessons = true;
  bool _hasMarkedComplete = false;

  @override
  void initState() {
    super.initState();

    _controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableFullscreen: true,
        ),
      ),
    );

    _configurePlayerForLesson(widget.lesson);
    _setupPlayerListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<CourseProvider>();
      await provider.loadLessons(widget.courseId, showLoading: false);
      if (!mounted) {
        return;
      }

      final lessons = provider.lessonsByCourse(widget.courseId);
      setState(() {
        _isLoadingLessons = false;
      });
      if (lessons.isNotEmpty) {
        _syncNavigatorSessionState(
          provider: provider,
          lessons: lessons,
          forcePlayerRefresh: true,
        );
      } else if (widget.lesson.id.trim().isNotEmpty &&
          widget.lesson.videoUrl.trim().isNotEmpty) {
        provider.saveCoursePlaybackState(
          courseId: widget.courseId,
          currentLessonIndex: 0,
          lessonId: widget.lesson.id,
          watchedPercent: 0.05,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.videoPlayerController?.removeListener(_handleVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  String? _localVideoPath(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'file') {
      return uri.toFilePath();
    }
    if (trimmed.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(trimmed)) {
      return trimmed;
    }
    return null;
  }

  void _configurePlayerForLesson(Lesson lesson) {
    _hasMarkedComplete = false;
    final localVideoPath = _localVideoPath(lesson.videoUrl);
    final isLocalFile = localVideoPath != null && localVideoPath.isNotEmpty;
    final isLiveStream =
        !isLocalFile && lesson.videoUrl.toLowerCase().contains('.m3u8');

    _controller.setupDataSource(
      BetterPlayerDataSource(
        isLocalFile
            ? BetterPlayerDataSourceType.file
            : BetterPlayerDataSourceType.network,
        isLocalFile ? localVideoPath : lesson.videoUrl,
        liveStream: isLiveStream,
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _setupPositionListener();
    });
  }

  void _setupPlayerListeners() {
    _controller.addEventsListener((event) {
      debugPrint('🎬 Video Event: ${event.betterPlayerEventType}');
      if (_hasMarkedComplete) {
        return;
      }
      if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
        debugPrint('✅ BetterPlayer finished event detected');
        _hasMarkedComplete = true;
        _markCurrentLessonCompletedIfUnmarked();
      }
    });

    _setupPositionListener();
  }

  void _setupPositionListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final videoController = _controller.videoPlayerController;
      if (videoController != null) {
        videoController.addListener(_handleVideoProgress);
        debugPrint('📍 Position listener attached');
      } else {
        debugPrint('⚠️ VideoPlayerController not yet available, will retry');
        Future.delayed(const Duration(milliseconds: 500), _setupPositionListener);
      }
    });
  }

  void _handleVideoProgress() {
    if (!mounted || _hasMarkedComplete) return;

    final value = _controller.videoPlayerController?.value;
    if (value == null) return;

    final duration = value.duration;
    final position = value.position;

    if (duration == null || duration == Duration.zero) return;

    final remainingSeconds = (duration - position).inSeconds.toDouble();

    debugPrint(
      '📊 Video progress: ${position.inSeconds}/${duration.inSeconds}s '
      '(${(position.inMilliseconds / duration.inMilliseconds * 100).toStringAsFixed(1)}%)',
    );

    if (remainingSeconds <= 3 && remainingSeconds >= 0) {
      debugPrint(
        '✅ Video nearly finished! '
        '(${remainingSeconds.toStringAsFixed(1)}s remaining)',
      );
      _hasMarkedComplete = true;
      _markCurrentLessonCompletedIfUnmarked();
    }
  }

  Future<void> _markCurrentLessonCompletedIfUnmarked() async {
    debugPrint('🎯 _markCurrentLessonCompletedIfUnmarked called');
    final provider = context.read<CourseProvider>();
    final lessons = provider.lessonsByCourse(widget.courseId);
    if (lessons.isEmpty || _currentLessonIndex >= lessons.length) {
      debugPrint(
        '⚠️ Invalid lesson state: '
        'lessons=${lessons.length}, index=$_currentLessonIndex',
      );
      return;
    }

    if (_completedLessonIndexes.contains(_currentLessonIndex)) {
      debugPrint('ℹ️ Lesson already marked as complete');
      return;
    }

    final lesson = lessons[_currentLessonIndex];
    debugPrint('📝 Marking lesson ${lesson.title} as complete');
    await provider.markLessonCompleted(
      courseId: widget.courseId,
      lessonId: lesson.id,
    );
    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, returning');
      return;
    }

    final completedIndexes = <int>{
      ..._completedLessonIndexes,
      _currentLessonIndex,
    };
    final progress = _watchedProgressForState(
      completedIndexes,
      lessons.length,
      _currentLessonIndex,
    );

    debugPrint('✅ Progress updated: ${(progress * 100).toStringAsFixed(0)}%');

    setState(() {
      _completedLessonIndexes = completedIndexes;
      _watchedProgressPercent = progress;
      if (progress < 1) {
        _completionDialogShown = false;
      }
    });

    _persistPlaybackState(
      provider: provider,
      lessons: lessons,
      currentLessonIndex: _currentLessonIndex,
      completedIndexes: completedIndexes,
      activeLessonId: lesson.id,
    );

    if (progress >= 1 && !_completionDialogShown) {
      _completionDialogShown = true;
      debugPrint('🎉 Course completed! Showing dialog...');
      _showCourseCompletedDialog();
    }
  }

  Course? _resolveCourse(CourseProvider provider) {
    if (widget.course != null) {
      return widget.course;
    }
    for (final course in provider.courses) {
      if (course.id == widget.courseId) {
        return course;
      }
    }
    return null;
  }

  String _lessonIdsSignature(List<Lesson> lessons) {
    return lessons.map((lesson) => lesson.id).join('|');
  }

  int _preferredLessonIndex(List<Lesson> lessons, CourseProvider provider) {
    if (_activeLessonId != null) {
      final activeIndex = lessons.indexWhere(
        (lesson) => lesson.id == _activeLessonId,
      );
      if (activeIndex >= 0) {
        return activeIndex;
      }
    }

    final routeIndex = lessons.indexWhere(
      (lesson) => lesson.id == widget.lesson.id,
    );
    if (routeIndex >= 0) {
      return routeIndex;
    }

    final lastLessonId = provider.lastLessonIdForCourse(widget.courseId);
    if (lastLessonId != null) {
      final lastIndex = lessons.indexWhere(
        (lesson) => lesson.id == lastLessonId,
      );
      if (lastIndex >= 0) {
        return lastIndex;
      }
    }

    final lastWatchedIndex = provider.lastWatchedLessonIndexForCourse(
      widget.courseId,
    );
    if (lastWatchedIndex != null &&
        lastWatchedIndex >= 0 &&
        lastWatchedIndex < lessons.length) {
      return lastWatchedIndex;
    }

    final resumeLesson = provider.resumeLessonForCourse(widget.courseId);
    if (resumeLesson != null) {
      final resumeIndex = lessons.indexWhere(
        (lesson) => lesson.id == resumeLesson.id,
      );
      if (resumeIndex >= 0) {
        return resumeIndex;
      }
    }

    return 0;
  }

  Set<int> _completedIndexesFor(List<Lesson> lessons, CourseProvider provider) {
    final completed = provider.completedLessonIndexesForCourse(widget.courseId);
    for (var index = 0; index < lessons.length; index++) {
      if (provider.isLessonCompleted(widget.courseId, lessons[index].id)) {
        completed.add(index);
      }
    }
    return completed;
  }

  double _progressForCompleted(Set<int> completedIndexes, int totalLessons) {
    if (totalLessons <= 0) {
      return 0;
    }
    return (completedIndexes.length / totalLessons).clamp(0, 1).toDouble();
  }

  double _watchedProgressForState(
    Set<int> completedIndexes,
    int totalLessons,
    int currentLessonIndex,
  ) {
    if (totalLessons <= 0) {
      return 0;
    }

    final completionProgress = _progressForCompleted(
      completedIndexes,
      totalLessons,
    );
    final clampedIndex = currentLessonIndex < 0
        ? 0
        : (currentLessonIndex >= totalLessons
              ? totalLessons - 1
              : currentLessonIndex);
    final currentLessonCompleted = completedIndexes.contains(clampedIndex);
    final positionUnits = clampedIndex + (currentLessonCompleted ? 1.0 : 0.35);
    final positionProgress = (positionUnits / totalLessons).clamp(0, 1);
    final boundedPositionProgress =
        positionProgress >= 1 && completionProgress < 1
        ? 0.98
        : positionProgress.toDouble();
    return boundedPositionProgress > completionProgress
        ? boundedPositionProgress
        : completionProgress;
  }

  void _persistPlaybackState({
    required CourseProvider provider,
    required List<Lesson> lessons,
    required int currentLessonIndex,
    required Set<int> completedIndexes,
    required String activeLessonId,
  }) {
    if (lessons.isEmpty) {
      return;
    }

    provider.saveCoursePlaybackState(
      courseId: widget.courseId,
      currentLessonIndex: currentLessonIndex,
      lessonId: activeLessonId,
      completedLessonIndexes: completedIndexes,
      watchedPercent: _watchedProgressForState(
        completedIndexes,
        lessons.length,
        currentLessonIndex,
      ),
    );
  }

  void _scheduleNavigatorSyncIfNeeded(
    CourseProvider provider,
    List<Lesson> lessons,
  ) {
    if (lessons.isEmpty) {
      return;
    }

    final completedIndexes = _completedIndexesFor(lessons, provider);
    final targetIndex = _preferredLessonIndex(lessons, provider);
    final targetLessonId = lessons[targetIndex].id;
    final progress = _watchedProgressForState(
      completedIndexes,
      lessons.length,
      targetIndex,
    );
    final signature = _lessonIdsSignature(lessons);
    final shouldSync =
        signature != _lessonSignature ||
        _currentLessonIndex != targetIndex ||
        !setEquals(_completedLessonIndexes, completedIndexes) ||
        (_watchedProgressPercent - progress).abs() > 0.001 ||
        _activeLessonId != targetLessonId;

    if (!shouldSync) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncNavigatorSessionState(provider: provider, lessons: lessons);
    });
  }

  void _syncNavigatorSessionState({
    required CourseProvider provider,
    required List<Lesson> lessons,
    bool forcePlayerRefresh = false,
  }) {
    if (lessons.isEmpty) {
      return;
    }

    final completedIndexes = _completedIndexesFor(lessons, provider);
    final targetIndex = _preferredLessonIndex(lessons, provider);
    final targetLesson = lessons[targetIndex];
    final progress = _watchedProgressForState(
      completedIndexes,
      lessons.length,
      targetIndex,
    );
    final signature = _lessonIdsSignature(lessons);

    if (forcePlayerRefresh || _activeLessonId != targetLesson.id) {
      _configurePlayerForLesson(targetLesson);
    }

    setState(() {
      _lessonSignature = signature;
      _currentLessonIndex = targetIndex;
      _completedLessonIndexes = completedIndexes;
      _watchedProgressPercent = progress;
      _activeLessonId = targetLesson.id;
      if (progress < 1) {
        _completionDialogShown = false;
      }
    });

    _persistPlaybackState(
      provider: provider,
      lessons: lessons,
      currentLessonIndex: targetIndex,
      completedIndexes: completedIndexes,
      activeLessonId: targetLesson.id,
    );
  }

  void _selectLessonAt(int index) {
    final provider = context.read<CourseProvider>();
    final lessons = provider.lessonsByCourse(widget.courseId);
    if (index < 0 || index >= lessons.length) {
      return;
    }

    final targetLesson = lessons[index];
    final completedIndexes = _completedIndexesFor(lessons, provider);
    final progress = _watchedProgressForState(
      completedIndexes,
      lessons.length,
      index,
    );

    _configurePlayerForLesson(targetLesson);

    setState(() {
      _lessonSignature = _lessonIdsSignature(lessons);
      _currentLessonIndex = index;
      _completedLessonIndexes = completedIndexes;
      _watchedProgressPercent = progress;
      _activeLessonId = targetLesson.id;
    });

    _persistPlaybackState(
      provider: provider,
      lessons: lessons,
      currentLessonIndex: index,
      completedIndexes: completedIndexes,
      activeLessonId: targetLesson.id,
    );
  }

  Future<void> _markCurrentLessonCompleted() async {
    final provider = context.read<CourseProvider>();
    final lessons = provider.lessonsByCourse(widget.courseId);
    if (lessons.isEmpty || _currentLessonIndex >= lessons.length) {
      return;
    }

    if (_completedLessonIndexes.contains(_currentLessonIndex)) {
      _showSnackBar('This lesson is already marked as completed.');
      return;
    }

    final lesson = lessons[_currentLessonIndex];
    await provider.markLessonCompleted(
      courseId: widget.courseId,
      lessonId: lesson.id,
    );
    if (!mounted) {
      return;
    }

    final completedIndexes = <int>{
      ..._completedLessonIndexes,
      _currentLessonIndex,
    };
    final progress = _watchedProgressForState(
      completedIndexes,
      lessons.length,
      _currentLessonIndex,
    );

    setState(() {
      _completedLessonIndexes = completedIndexes;
      _watchedProgressPercent = progress;
      if (progress < 1) {
        _completionDialogShown = false;
      }
    });

    _persistPlaybackState(
      provider: provider,
      lessons: lessons,
      currentLessonIndex: _currentLessonIndex,
      completedIndexes: completedIndexes,
      activeLessonId: lesson.id,
    );

    _showSnackBar('Lesson marked as completed.');
    if (progress >= 1 && !_completionDialogShown) {
      _completionDialogShown = true;
      _showCourseCompletedDialog();
    }
  }

  void _openResources(Lesson lesson) {
    Navigator.of(context).pushNamed(
      AppRoutes.lessonResources,
      arguments: LessonModuleArgs(
        lesson: lesson,
        courseId: widget.courseId,
        courseTitle: widget.courseTitle,
      ),
    );
  }

  void _openNotes(Lesson lesson) {
    Navigator.of(context).pushNamed(
      AppRoutes.lessonNotes,
      arguments: LessonModuleArgs(
        lesson: lesson,
        courseId: widget.courseId,
        courseTitle: widget.courseTitle,
      ),
    );
  }

  void _toggleDownload(Lesson lesson) {
    context.read<CourseProvider>().toggleLessonDownload(lesson.id);
  }

  Lesson _resolvedCurrentLesson(List<Lesson> lessons) {
    if (lessons.isEmpty) {
      return widget.lesson;
    }

    if (_activeLessonId != null) {
      final activeIndex = lessons.indexWhere(
        (lesson) => lesson.id == _activeLessonId,
      );
      if (activeIndex >= 0) {
        return lessons[activeIndex];
      }
    }

    final clampedIndex = _currentLessonIndex.clamp(0, lessons.length - 1);
    return lessons[clampedIndex];
  }

  bool _usesUploadedNavigator(Course? course, List<Lesson> lessons) {
    return course?.usesUploadedVideos == true &&
        (course?.hasUploadedVideoUrls ?? false) &&
        lessons.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final lessons = courseProvider.lessonsByCourse(widget.courseId);
    if (lessons.isNotEmpty) {
      _scheduleNavigatorSyncIfNeeded(courseProvider, lessons);
    }

    final resolvedCourse = _resolveCourse(courseProvider);
    final currentLesson = _resolvedCurrentLesson(lessons);
    final currentLessonIndex = lessons.isEmpty
        ? 0
        : lessons.indexWhere((lesson) => lesson.id == currentLesson.id);
    final safeCurrentLessonIndex = currentLessonIndex < 0
        ? 0
        : currentLessonIndex;
    final completedLessons = lessons.isEmpty
        ? courseProvider.completedLessonsCountForCourse(widget.courseId)
        : _completedLessonIndexes.length;
    final progress = lessons.isEmpty
        ? courseProvider.progressForCourse(widget.courseId)
        : _watchedProgressPercent;
    final isDownloaded = courseProvider.isLessonDownloaded(currentLesson.id);
    final isUploadedCourse =
        resolvedCourse?.usesUploadedVideos == true &&
        (resolvedCourse?.hasUploadedVideoUrls ?? false);

    if (_usesUploadedNavigator(resolvedCourse, lessons)) {
      return _buildUploadedNavigator(
        course: resolvedCourse!,
        lessons: lessons,
        currentLesson: currentLesson,
        currentLessonIndex: safeCurrentLessonIndex,
        completedLessons: completedLessons,
        progress: progress,
        isDownloaded: isDownloaded,
      );
    }

    if (isUploadedCourse && lessons.isEmpty) {
      return _isLoadingLessons
          ? _buildUploadedNavigatorLoadingState()
          : _buildUnavailableMediaState(
              title: 'Uploaded lessons are not ready yet',
              message:
                  'We could not build the lesson curriculum for this upload course yet. Please try again shortly or ask the instructor to review the published videos.',
            );
    }

    if (!_isLoadingLessons &&
        lessons.isEmpty &&
        currentLesson.videoUrl.trim().isEmpty) {
      return _buildUnavailableMediaState(
        title: 'Lesson unavailable',
        message:
            'This course does not have a playable lesson right now. Please reopen it later after the media is updated.',
      );
    }

    return _buildDefaultPlayer(
      courseProvider: courseProvider,
      lessons: lessons,
      currentLesson: currentLesson,
      currentLessonIndex: safeCurrentLessonIndex,
      completedLessons: completedLessons,
      progress: progress,
      isDownloaded: isDownloaded,
    );
  }

  Widget _buildUploadedNavigatorLoadingState() {
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _controller),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Preparing your structured lesson navigator and syncing the course curriculum...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableMediaState({
    required String title,
    required String message,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(
                      AppColors.primary,
                    ).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.video_library_outlined,
                    color: Color(AppColors.primary),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadedNavigator({
    required Course course,
    required List<Lesson> lessons,
    required Lesson currentLesson,
    required int currentLessonIndex,
    required int completedLessons,
    required double progress,
    required bool isDownloaded,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? colorScheme.surface : Colors.white;
    final softSurface = isDark
        ? const Color(0xFF15243A)
        : const Color(AppColors.bg);
    final outlineColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.85)
        : const Color(AppColors.line);
    final completedCurrentLesson = _completedLessonIndexes.contains(
      currentLessonIndex,
    );
    final totalLessons = lessons.length;
    final remainingLessons = totalLessons - completedLessons;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.courseTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(AppColors.primary).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(progress * 100).round()}% done',
                  style: const TextStyle(
                    color: Color(AppColors.primary),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.08,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: BetterPlayer(controller: _controller),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: outlineColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _LessonBadge(
                            label:
                                'Lesson ${currentLessonIndex + 1} of $totalLessons',
                            icon: Icons.play_circle_outline_rounded,
                            backgroundColor: const Color(
                              AppColors.primary,
                            ).withValues(alpha: 0.14),
                            foregroundColor: const Color(AppColors.primary),
                          ),
                          _LessonBadge(
                            label: completedCurrentLesson
                                ? 'Completed'
                                : 'In Progress',
                            icon: completedCurrentLesson
                                ? Icons.check_circle_rounded
                                : Icons.timelapse_rounded,
                            backgroundColor: completedCurrentLesson
                                ? const Color(
                                    AppColors.success,
                                  ).withValues(alpha: 0.14)
                                : const Color(
                                    0xFFFF8A00,
                                  ).withValues(alpha: 0.14),
                            foregroundColor: completedCurrentLesson
                                ? const Color(AppColors.success)
                                : const Color(0xFFFF8A00),
                          ),
                          _LessonBadge(
                            label: currentLesson.duration,
                            icon: Icons.schedule_rounded,
                            backgroundColor: softSurface,
                            foregroundColor: colorScheme.onSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        currentLesson.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: outlineColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Watch Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: softSurface,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$completedLessons of $totalLessons lessons completed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withValues(alpha: 0.74),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ProgressStatCard(
                              label: 'Completed',
                              value: completedLessons.toString(),
                              icon: Icons.task_alt_rounded,
                              backgroundColor: const Color(
                                AppColors.success,
                              ).withValues(alpha: 0.12),
                              foregroundColor: const Color(AppColors.success),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ProgressStatCard(
                              label: 'Remaining',
                              value: remainingLessons.toString(),
                              icon: Icons.auto_stories_rounded,
                              backgroundColor: const Color(
                                AppColors.primary,
                              ).withValues(alpha: 0.12),
                              foregroundColor: const Color(AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ProgressStatCard(
                              label: 'Current',
                              value: '${currentLessonIndex + 1}',
                              icon: Icons.podcasts_rounded,
                              backgroundColor: const Color(
                                0xFFFF8A00,
                              ).withValues(alpha: 0.14),
                              foregroundColor: const Color(0xFFFF8A00),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: outlineColor),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _CompactActionChip(
                        icon: Icons.folder_open_rounded,
                        label: 'Resources',
                        onTap: () => _openResources(currentLesson),
                      ),
                      _CompactActionChip(
                        icon: Icons.note_alt_outlined,
                        label: 'Notes',
                        onTap: () => _openNotes(currentLesson),
                      ),
                      _CompactActionChip(
                        icon: isDownloaded
                            ? Icons.download_done_rounded
                            : Icons.download_rounded,
                        label: isDownloaded ? 'Downloaded' : 'Download',
                        onTap: () => _toggleDownload(currentLesson),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Lesson Curriculum',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Switch lessons instantly and keep your place as you move through the course.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                ...lessons.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lesson = entry.value;
                  return _UploadedLessonNavigatorTile(
                    index: index,
                    lesson: lesson,
                    isActive: index == currentLessonIndex,
                    isCompleted: _completedLessonIndexes.contains(index),
                    onTap: () => _selectLessonAt(index),
                  );
                }),
              ],
            ),
          ),
          _NavigatorBottomBar(
            canGoPrevious: currentLessonIndex > 0,
            canGoNext: currentLessonIndex + 1 < lessons.length,
            isCompleted: completedCurrentLesson,
            onPrevious: currentLessonIndex > 0
                ? () => _selectLessonAt(currentLessonIndex - 1)
                : null,
            onMarkCompleted: _markCurrentLessonCompleted,
            onNext: currentLessonIndex + 1 < lessons.length
                ? () => _selectLessonAt(currentLessonIndex + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPlayer({
    required CourseProvider courseProvider,
    required List<Lesson> lessons,
    required Lesson currentLesson,
    required int currentLessonIndex,
    required int completedLessons,
    required double progress,
    required bool isDownloaded,
  }) {
    final nextLesson = currentLessonIndex + 1 < lessons.length
        ? lessons[currentLessonIndex + 1]
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(currentLesson.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _controller),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.courseTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            currentLesson.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Duration: ${currentLesson.duration}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completedLessons of ${lessons.length} lessons completed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (nextLesson != null) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _selectLessonAt(currentLessonIndex + 1),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Next'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _markCurrentLessonCompleted,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _completedLessonIndexes.contains(currentLessonIndex)
                      ? 'Completed'
                      : 'Mark Complete',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openResources(currentLesson),
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Resources'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openNotes(currentLesson),
                icon: const Icon(Icons.note_alt_outlined),
                label: const Text('Notes'),
              ),
              OutlinedButton.icon(
                onPressed: () => _toggleDownload(currentLesson),
                icon: Icon(
                  isDownloaded
                      ? Icons.download_done_rounded
                      : Icons.download_rounded,
                ),
                label: Text(isDownloaded ? 'Downloaded' : 'Download'),
              ),
            ],
          ),
          if (lessons.length > 1) ...[
            const SizedBox(height: 18),
            Text(
              'Up Next',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...lessons
                .where((lesson) => lesson.id != currentLesson.id)
                .map(
                  (lesson) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: ListTile(
                        title: Text(lesson.title),
                        subtitle: Text('Duration: ${lesson.duration}'),
                        trailing: const Icon(Icons.play_arrow_rounded),
                        onTap: () {
                          final targetIndex = lessons.indexWhere(
                            (item) => item.id == lesson.id,
                          );
                          if (targetIndex >= 0) {
                            _selectLessonAt(targetIndex);
                          }
                        },
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCourseCompletedDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x8F2F3455),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.headset_rounded,
                  size: 70,
                  color: Color(AppColors.dark),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Course Completed',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(AppColors.dark),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Complete your Course. Please Write a\nReview',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(AppColors.muted),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Color(0xFFFFC83D)),
                    Icon(Icons.star_rounded, color: Color(0xFFFFC83D)),
                    Icon(Icons.star_rounded, color: Color(0xFFFFC83D)),
                    Icon(Icons.star_rounded, color: Color(0xFFFFC83D)),
                    Icon(Icons.star_border_rounded, color: Color(0xFFFFC83D)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openReviewFromVideo(context);
                    },
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Write a Review'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openReviewFromVideo(BuildContext context) {
    final provider = context.read<CourseProvider>();
    Course? course;
    for (final item in provider.courses) {
      if (item.id == widget.courseId) {
        course = item;
        break;
      }
    }

    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course data not found for review.')),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.courseReviews,
      arguments: CourseModuleArgs(course: course),
    );
  }
}

class _LessonBadge extends StatelessWidget {
  const _LessonBadge({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  const _ProgressStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: foregroundColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foregroundColor.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactActionChip extends StatelessWidget {
  const _CompactActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF15243A) : const Color(AppColors.bg),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: const Color(AppColors.primary)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadedLessonNavigatorTile extends StatelessWidget {
  const _UploadedLessonNavigatorTile({
    required this.index,
    required this.lesson,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  final int index;
  final Lesson lesson;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final foregroundColor = isActive
        ? const Color(AppColors.primary)
        : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(AppColors.primary).withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF15243A) : Colors.white),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isActive
                    ? const Color(AppColors.primary)
                    : (isDark
                          ? colorScheme.outline.withValues(alpha: 0.8)
                          : const Color(AppColors.line)),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(
                          AppColors.primary,
                        ).withValues(alpha: 0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(AppColors.success).withValues(alpha: 0.14)
                        : isActive
                        ? const Color(AppColors.primary).withValues(alpha: 0.14)
                        : (isDark
                              ? colorScheme.surface
                              : const Color(AppColors.bg)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isCompleted
                            ? const Color(AppColors.success)
                            : foregroundColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lesson.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.3,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  AppColors.primary,
                                ).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Now Playing',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lesson ${index + 1} • ${lesson.duration}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : isActive
                      ? Icons.graphic_eq_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 24,
                  color: isCompleted
                      ? const Color(AppColors.success)
                      : isActive
                      ? const Color(AppColors.primary)
                      : colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigatorBottomBar extends StatelessWidget {
  const _NavigatorBottomBar({
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isCompleted,
    required this.onPrevious,
    required this.onMarkCompleted,
    required this.onNext,
  });

  final bool canGoPrevious;
  final bool canGoNext;
  final bool isCompleted;
  final VoidCallback? onPrevious;
  final VoidCallback onMarkCompleted;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.85)
        : const Color(AppColors.line);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onMarkCompleted,
                style: FilledButton.styleFrom(
                  backgroundColor: isCompleted
                      ? const Color(AppColors.success)
                      : const Color(AppColors.primary),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.task_alt_rounded,
                ),
                label: Text(isCompleted ? 'Completed' : 'Mark Completed'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: canGoNext
                      ? const Color(AppColors.dark)
                      : const Color(AppColors.dark).withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
