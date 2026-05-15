import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/route_args.dart';
import '../../../../core/theme/app_colors.dart';
import 'course_bullet_text.dart';
import 'course_meta_pill.dart';
import 'course_tab_button.dart';

class CourseHeaderCard extends StatelessWidget {
  const CourseHeaderCard({
    super.key,
    required this.courseTitle,
    required this.category,
    required this.description,
    required this.level,
    required this.isEnrolled,
    required this.isInWishlist,
    required this.progress,
    required this.completedLessons,
    required this.totalLessons,
    required this.classCountLabel,
    required this.totalDurationLabel,
    required this.hasResumePoint,
    required this.resumeLessonTitle,
    required this.curriculumTab,
    required this.onToggleWishlist,
    required this.onToggleCurriculumTab,
    required this.onToggleAboutTab,
    required this.courseId,
    required this.usesUploadedVideos,
    required this.hasPlayableMedia,
    required this.playlistId,
    required this.outcomes,
    required this.requirements,
    required this.tags,
    required this.surfaceColor,
    required this.softSurfaceColor,
    required this.outlineColor,
    required this.isDark,
    required this.curriculumWidgets,
    required this.courseRating,
    required this.studentCount,
  });

  final String courseTitle;
  final String category;
  final String description;
  final String level;
  final bool isEnrolled;
  final bool isInWishlist;
  final double progress;
  final int completedLessons;
  final int totalLessons;
  final String classCountLabel;
  final String totalDurationLabel;
  final bool hasResumePoint;
  final String? resumeLessonTitle;
  final bool curriculumTab;
  final VoidCallback onToggleWishlist;
  final VoidCallback onToggleCurriculumTab;
  final VoidCallback onToggleAboutTab;
  final String courseId;
  final bool usesUploadedVideos;
  final bool hasPlayableMedia;
  final String? playlistId;
  final List<String> outcomes;
  final List<String> requirements;
  final List<String> tags;
  final Color surfaceColor;
  final Color softSurfaceColor;
  final Color outlineColor;
  final bool isDark;
  final List<Widget> curriculumWidgets;
  final double courseRating;
  final int studentCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.72);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: outlineColor) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: Color(0xFFFF8A00),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFC83D),
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                courseRating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onToggleWishlist,
                child: Icon(
                  isInWishlist
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: const Color(AppColors.primary),
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            courseTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.groups_outlined, size: 18, color: secondaryText),
              const SizedBox(width: 4),
              Text(
                classCountLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.schedule_rounded, size: 14, color: secondaryText),
              const SizedBox(width: 4),
              Text(
                totalDurationLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              isEnrolled ? 'Enrolled' : '$studentCount enrolled',
              style: const TextStyle(
                color: Color(AppColors.primary),
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CourseMetaPill(icon: Icons.school_outlined, label: level),
              CourseMetaPill(
                icon: Icons.menu_book_outlined,
                label: '$completedLessons/$totalLessons done',
              ),
              CourseMetaPill(
                icon: Icons.trending_up_rounded,
                label: '${(progress * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: softSurfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Color(AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasResumePoint && resumeLessonTitle != null
                            ? 'Resume $resumeLessonTitle'
                            : 'Ready to start this course',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEnrolled
                            ? '${(progress * 100).toStringAsFixed(0)}% completed'
                            : 'Enroll once and your progress will sync.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: softSurfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CourseTabButton(
                    label: 'About',
                    active: !curriculumTab,
                    onTap: onToggleAboutTab,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CourseTabButton(
                    label: 'Curriculum',
                    active: curriculumTab,
                    onTap: onToggleCurriculumTab,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (playlistId != null && playlistId!.trim().isNotEmpty)
            Material(
              color: isDark
                  ? const Color(0xFF11353B)
                  : const Color(0xFFE9FFFC),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.youtubePlaylist,
                    arguments: YoutubePlaylistArgs(
                      courseTitle: courseTitle,
                      playlistId: playlistId!.trim(),
                      courseId: courseId,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.ondemand_video_rounded,
                        color: Color(AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Open YouTube Playlist',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (usesUploadedVideos)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: softSurfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: outlineColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.video_library_rounded,
                    color: Color(AppColors.primary),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasPlayableMedia
                          ? 'This course uses hosted lesson videos with a structured lesson navigator.'
                          : 'Hosted lesson videos are still syncing for this course.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: softSurfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: outlineColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: secondaryText,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasPlayableMedia
                          ? 'This course opens as a focused lesson player instead of a playlist.'
                          : 'Course media is still being prepared for this lesson.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (!curriculumTab)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'What you will learn',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...outcomes.map((item) => CourseBulletText(text: item)),
                const SizedBox(height: 14),
                Text(
                  'Requirements',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...requirements.map((item) => CourseBulletText(text: item)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map((tag) => CourseMetaPill(
                            icon: Icons.sell_outlined,
                            label: tag,
                          ))
                      .toList(growable: false),
                ),
              ],
            )
          else
            ...curriculumWidgets,
        ],
      ),
    );
  }
}
