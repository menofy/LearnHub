import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/route_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/firestore_service.dart';
import '../../../../domain/entities/course.dart';
import '../../../../domain/entities/lesson.dart';

class StudentCourseTile extends StatelessWidget {
  const StudentCourseTile({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.72);

    final usesUploadedVideos = course.usesUploadedVideos;
    final playlistId = usesUploadedVideos ? '' : course.playlistId.trim();
    final primaryVideoUrl = course.primaryPlayableVideoUrl.trim();
    final videoId = usesUploadedVideos
        ? ''
        : FirestoreService.instance.extractYoutubeVideoId(primaryVideoUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.85)
              : const Color(AppColors.line),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final courseProvider = context.read<CourseProvider>();
            if (playlistId.isNotEmpty) {
              Navigator.of(context).pushNamed(
                AppRoutes.youtubePlaylist,
                arguments: YoutubePlaylistArgs(
                  courseTitle: course.title,
                  playlistId: playlistId,
                  courseId: course.id,
                ),
              );
              return;
            }

            if (videoId.isNotEmpty) {
              if (courseProvider.lessonsByCourse(course.id).isEmpty) {
                await courseProvider.loadLessons(course.id, showLoading: false);
                if (!context.mounted) {
                  return;
                }
              }
              final lesson =
                  courseProvider.resumeLessonForCourse(course.id) ??
                  Lesson(
                    id: '${course.id}_intro',
                    courseId: course.id,
                    title: course.title,
                    videoUrl: primaryVideoUrl,
                    duration: 'On-demand',
                    order: 1,
                  );
              Navigator.of(context).pushNamed(
                AppRoutes.youtubeFullscreen,
                arguments: YoutubeFullscreenArgs(
                  videoId: videoId,
                  title: course.title,
                  courseId: course.id,
                  lessonId: lesson.id,
                  lessonIndex: lesson.order <= 0 ? 0 : lesson.order - 1,
                  watchedPercent: 0.35,
                ),
              );
              return;
            }

            if (primaryVideoUrl.isNotEmpty) {
              if (courseProvider.lessonsByCourse(course.id).isEmpty) {
                await courseProvider.loadLessons(course.id, showLoading: false);
                if (!context.mounted) {
                  return;
                }
              }
              final lesson =
                  courseProvider.resumeLessonForCourse(course.id) ??
                  Lesson(
                    id: 'single_${course.id}',
                    courseId: course.id,
                    title: course.title,
                    videoUrl: primaryVideoUrl,
                    duration: 'N/A',
                  );
              Navigator.of(context).pushNamed(
                AppRoutes.videoPlayer,
                arguments: VideoPlayerArgs(
                  lesson: lesson,
                  courseId: course.id,
                  courseTitle: course.title,
                  course: course,
                ),
              );
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This course does not have a playable lesson yet. Please try again later.',
                ),
              ),
            );
          },
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 120,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      EduCourseThumb(
                        imageUrl: course.preferredPreviewImageUrl,
                        videoUrl: primaryVideoUrl,
                        playlistId: playlistId,
                        width: 120,
                        height: 100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                      // Play button overlay
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF8A00,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              course.category,
                              style: const TextStyle(
                                color: Color(0xFFFF8A00),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            course.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.instructorName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Color(0xFFFF8A00),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.people_outline,
                                size: 14,
                                color: secondaryText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '1.2K',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
