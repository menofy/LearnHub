import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/course/widgets/course_curriculum_row.dart';
import 'package:learnhub/features/course/widgets/course_header_card.dart';
import 'package:learnhub/features/course/widgets/course_hero_image_header.dart';
import 'package:learnhub/features/course/widgets/course_instructor_card.dart';
import 'package:learnhub/features/course/widgets/course_reviews_section.dart';
import 'package:learnhub/features/course/widgets/course_what_you_get_section.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import '../../../core/config/youtube_playlist_catalog.dart';
import 'package:learnhub/core/navigation/app_routes.dart';
import '../../../core/navigation/route_args.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import '../../../data/services/firestore_service.dart';
import '../../../domain/entities/course.dart';
import '../../../domain/entities/lesson.dart';

class CourseDetailsScreen extends StatefulWidget {
  const CourseDetailsScreen({super.key, required this.course});

  final Course course;

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool _curriculumTab = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = context.read<CourseProvider>();
      final userId = context.read<AuthProvider>().currentUser?.id;

      courseProvider.loadLessons(widget.course.id, showLoading: false);
      courseProvider.loadCourseReviews(widget.course.id, showLoading: false);
      if (userId != null) {
        courseProvider.loadEnrolledCourses(userId, showLoading: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? colorScheme.surface : Colors.white;
    final softSurfaceColor = isDark
        ? const Color(0xFF15243A)
        : const Color(AppColors.bg);
    final outlineColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.85)
        : const Color(AppColors.line);

    final lessons = courseProvider.lessonsByCourse(widget.course.id);
    final reviews = courseProvider.reviewsByCourse(widget.course.id);
    final isEnrolled = courseProvider.isEnrolled(widget.course.id);
    final isInWishlist = courseProvider.isInWishlist(widget.course.id);
    final progress = courseProvider.progressForCourse(widget.course.id);
    final completedLessons = courseProvider.completedLessonsCountForCourse(
      widget.course.id,
    );
    final resumeLesson = courseProvider.resumeLessonForCourse(widget.course.id);
    final lastOpenedLessonId = courseProvider.lastLessonIdForCourse(
      widget.course.id,
    );
    final hasResumePoint =
        isEnrolled &&
        lastOpenedLessonId != null &&
        lastOpenedLessonId.trim().isNotEmpty;
    final hasRemoteMedia = widget.course.hasMedia;
    final classCountLabel = _classCountLabel(lessons);
    final totalDurationLabel = _totalDurationLabel(
      lessons,
      isPending: hasRemoteMedia && lessons.isEmpty,
    );
    final matchedInstructors = courseProvider.instructors
        .where((item) => item.name == widget.course.instructor)
        .toList();
    final playlistId = _playlistIdForCourse();
    final instructorAvatar = matchedInstructors.isEmpty
        ? 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80'
        : matchedInstructors.first.avatarUrl;
    final requirements = widget.course.requirements.isEmpty
        ? _fallbackRequirements()
        : widget.course.requirements;
    final outcomes = widget.course.outcomes.isEmpty
        ? _fallbackOutcomes()
        : widget.course.outcomes;
    final tags = widget.course.tags.isEmpty
        ? <String>[widget.course.category, widget.course.level]
        : widget.course.tags;
    final hasCurriculum = lessons.isNotEmpty;
    final ctaLabel = !isEnrolled
        ? 'Start Course'
        : hasCurriculum
        ? (hasResumePoint ? 'Resume Lesson' : 'Continue Course')
        : hasRemoteMedia
        ? 'Preparing Lessons'
        : 'Course Media Pending';
    final durationGetText = totalDurationLabel == 'Loading...'
        ? 'Duration syncing from source'
        : totalDurationLabel;
    final coursePathText = widget.course.usesUploadedVideos
        ? 'Managed Upload Library'
        : playlistId != null
        ? 'Structured Playlist Curriculum'
        : 'Focused Lesson Path';
    final accessText = widget.course.isFree
        ? 'Free Access'
        : '\$${widget.course.price.toStringAsFixed(2)} Premium Access';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  CourseHeroImageHeader(
                    imageUrl: widget.course.preferredPreviewImageUrl,
                    videoUrl: widget.course.primaryPlayableVideoUrl,
                    playlistId: widget.course.usesUploadedVideos
                        ? ''
                        : widget.course.playlistId,
                    onBack: () => Navigator.of(context).pop(),
                    onPlayFirst: () {
                      if (lessons.isNotEmpty) {
                        _openVideo(context, lessons.first);
                      }
                    },
                    hasLessons: lessons.isNotEmpty,
                  ),
                  CourseHeaderCard(
                    courseTitle: widget.course.title,
                    category: widget.course.category,
                    description: widget.course.description,
                    level: widget.course.level,
                    isEnrolled: isEnrolled,
                    isInWishlist: isInWishlist,
                    progress: progress,
                    completedLessons: completedLessons,
                    totalLessons: lessons.length,
                    classCountLabel: classCountLabel,
                    totalDurationLabel: totalDurationLabel,
                    hasResumePoint: hasResumePoint,
                    resumeLessonTitle: resumeLesson?.title,
                    curriculumTab: _curriculumTab,
                    onToggleWishlist: () =>
                        courseProvider.toggleWishlist(widget.course.id),
                    onToggleCurriculumTab: () =>
                        setState(() => _curriculumTab = true),
                    onToggleAboutTab: () =>
                        setState(() => _curriculumTab = false),
                    courseId: widget.course.id,
                    usesUploadedVideos: widget.course.usesUploadedVideos,
                    hasPlayableMedia: hasRemoteMedia,
                    playlistId: playlistId,
                    outcomes: outcomes,
                    requirements: requirements,
                    tags: tags,
                    surfaceColor: surfaceColor,
                    softSurfaceColor: softSurfaceColor,
                    outlineColor: outlineColor,
                    isDark: isDark,
                    courseRating: widget.course.rating,
                    studentCount: widget.course.studentCount,
                    curriculumWidgets: _buildCurriculum(
                      lessons: lessons.take(8).toList(growable: false),
                      isEnrolled: isEnrolled,
                      courseProvider: courseProvider,
                      context: context,
                      hasRemoteMedia: hasRemoteMedia,
                    ),
                  ),
                  CourseInstructorCard(
                    instructorName: widget.course.instructor,
                    category: widget.course.category,
                    instructorAvatarUrl: instructorAvatar,
                  ),
                  const SizedBox(height: 14),
                  CourseWhatYouGetSection(
                    classCountLabel: classCountLabel,
                    durationText: durationGetText,
                    level: widget.course.level,
                    category: widget.course.category,
                    coursePathText: coursePathText,
                    accessText: accessText,
                    isEnrolled: isEnrolled,
                    isFree: widget.course.isFree,
                  ),
                  const SizedBox(height: 14),
                  CourseReviewsSection(
                    reviews: reviews,
                    course: widget.course,
                    surfaceColor: surfaceColor,
                    outlineColor: outlineColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: EduPrimaryButton(
                label: ctaLabel,
                onPressed: authProvider.currentUser == null
                    ? null
                    : () => _handlePrimaryAction(
                        context: context,
                        userId: authProvider.currentUser!.id,
                        isEnrolled: isEnrolled,
                        resumeLesson: resumeLesson,
                        fallbackLessons: lessons,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enroll(
    BuildContext context,
    String userId,
    String courseId,
  ) async {
    await context.read<CourseProvider>().enrollCourse(
      userId: userId,
      courseId: courseId,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Course added to My Courses.')),
    );
  }

  Future<void> _handlePrimaryAction({
    required BuildContext context,
    required String userId,
    required bool isEnrolled,
    required Lesson? resumeLesson,
    required List<Lesson> fallbackLessons,
  }) async {
    if (!isEnrolled) {
      await _enroll(context, userId, widget.course.id);
      return;
    }
    if (!context.mounted) return;
    final lesson =
        resumeLesson ??
        (fallbackLessons.isEmpty ? null : fallbackLessons.first);
    if (lesson == null) {
      _showSnackBar(
        context,
        'This course does not have a ready lesson yet. Please try again shortly.',
      );
      return;
    }
    _openVideo(context, lesson);
  }

  void _openVideo(BuildContext context, Lesson lesson) {
    final playlistId = _playlistIdForCourse();
    final lowerDuration = lesson.duration.toLowerCase();
    final looksLikePlaylistEntry =
        lowerDuration.contains('playlist') || lesson.videoUrl.trim().isEmpty;
    if (looksLikePlaylistEntry && playlistId != null && playlistId.isNotEmpty) {
      Navigator.of(context).pushNamed(
        AppRoutes.youtubePlaylist,
        arguments: YoutubePlaylistArgs(
          courseTitle: widget.course.title,
          playlistId: playlistId,
          courseId: widget.course.id,
        ),
      );
      return;
    }

    if (lesson.videoUrl.trim().isEmpty) {
      _showSnackBar(
        context,
        'This lesson does not have a playable video yet. Please try another lesson or check back later.',
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.videoPlayer,
      arguments: VideoPlayerArgs(
        lesson: lesson,
        courseId: widget.course.id,
        courseTitle: widget.course.title,
        course: widget.course,
      ),
    );
  }

  String? _playlistIdForCourse() {
    if (widget.course.usesUploadedVideos) {
      return null;
    }
    final coursePlaylistId = widget.course.playlistId.trim();
    if (coursePlaylistId.isNotEmpty) return coursePlaylistId;
    final extracted = FirestoreService.instance.extractPlaylistId(
      widget.course.primaryPlayableVideoUrl,
    );
    if (extracted.isNotEmpty) return extracted;
    return YoutubePlaylistCatalog.playlistIdForCourse(widget.course);
  }

  String _classCountLabel(List<Lesson> lessons) {
    final lessonCount = _effectiveLessonCount(lessons);
    if (lessonCount <= 0) return '0 Classes';
    return lessonCount == 1 ? '1 Class' : '$lessonCount Classes';
  }

  int _effectiveLessonCount(List<Lesson> lessons) {
    final playableLessons = lessons
        .where((lesson) => lesson.videoUrl.trim().isNotEmpty)
        .length;
    if (playableLessons > 0) return playableLessons;
    if (widget.course.usesUploadedVideos &&
        widget.course.hasUploadedVideoUrls) {
      return widget.course.uploadedVideoUrls.length;
    }
    if (widget.course.lessonCount > 0) return widget.course.lessonCount;
    return widget.course.primaryPlayableVideoUrl.trim().isNotEmpty ? 1 : 0;
  }

  String _totalDurationLabel(List<Lesson> lessons, {bool isPending = false}) {
    final totalSeconds = lessons.fold<int>(
      0,
      (sum, lesson) => sum + _secondsFromDurationLabel(lesson.duration),
    );
    if (totalSeconds > 0) return _formatTotalDuration(totalSeconds);
    if (isPending) return 'Loading...';
    if (widget.course.totalHours > 0) {
      return widget.course.totalHours == 1
          ? '1 Hour'
          : '${widget.course.totalHours} Hours';
    }
    return 'N/A';
  }

  int _secondsFromDurationLabel(String value) {
    final trimmed = value.trim();
    final match = RegExp(
      r'^(\d+):([0-5]\d)(?::([0-5]\d))?$',
    ).firstMatch(trimmed);
    if (match == null) return 0;
    final thirdPart = match.group(3);
    if (thirdPart != null) {
      final hours = int.tryParse(match.group(1) ?? '') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
      final seconds = int.tryParse(thirdPart) ?? 0;
      return (hours * 3600) + (minutes * 60) + seconds;
    }
    final minutes = int.tryParse(match.group(1) ?? '') ?? 0;
    final seconds = int.tryParse(match.group(2) ?? '') ?? 0;
    return (minutes * 60) + seconds;
  }

  String _formatTotalDuration(int totalSeconds) {
    final totalMinutes = (totalSeconds / 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return hours == 1 ? '1 Hour' : '$hours Hours';
    return '$totalMinutes min';
  }

  List<Widget> _buildCurriculum({
    required List<Lesson> lessons,
    required bool isEnrolled,
    required CourseProvider courseProvider,
    required BuildContext context,
    required bool hasRemoteMedia,
  }) {
    if (lessons.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      final message = !hasRemoteMedia
          ? 'No lesson curriculum is available for this course yet.'
          : widget.course.usesUploadedVideos
          ? 'We are preparing the uploaded lesson navigator. If this stays empty, the instructor may need to republish the course videos.'
          : 'We are loading the lesson curriculum from the course media source. If it stays empty, the external link may need to be refreshed.';
      return <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(AppColors.bg),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(AppColors.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.auto_stories_outlined,
                  color: Color(AppColors.primary),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    color: colorScheme.onSurface.withValues(alpha: 0.74),
                  ),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    String? currentSection;

    for (final lesson in lessons) {
      if (lesson.sectionTitle.isNotEmpty &&
          lesson.sectionTitle != currentSection) {
        currentSection = lesson.sectionTitle;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 6),
            child: Text(
              currentSection,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }

      widgets.add(
        CourseCurriculumRow(
          index: lesson.order <= 0 ? (widgets.length + 1) : lesson.order,
          lesson: lesson,
          onTap: () => _openVideo(context, lesson),
          locked: !isEnrolled && !lesson.isPreview,
          completed: courseProvider.isLessonCompleted(
            widget.course.id,
            lesson.id,
          ),
        ),
      );
    }

    return widgets;
  }

  void _showSnackBar(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> _fallbackOutcomes() {
    return <String>[
      'Understand the core workflow of ${widget.course.title}.',
      'Apply ${widget.course.category} concepts in a practical project.',
      'Move through a structured learning path with clear lesson sequencing.',
    ];
  }

  List<String> _fallbackRequirements() {
    return <String>[
      'Interest in ${widget.course.category}.',
      'Basic comfort using mobile or desktop apps for video-based learning.',
    ];
  }
}
