import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/course.dart';

class LearningCourseTile extends StatelessWidget {
  const LearningCourseTile({
    super.key,
    required this.course,
    required this.isCompleted,
    required this.progress,
    required this.onTap,
    this.resumeLessonTitle,
  });

  final Course course;
  final bool isCompleted;
  final double progress;
  final VoidCallback onTap;
  final String? resumeLessonTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.72);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isDark
              ? Border.all(color: colorScheme.outline.withValues(alpha: 0.85))
              : null,
        ),
        child: Row(
          children: [
            EduCourseThumb(
              imageUrl: course.preferredPreviewImageUrl,
              videoUrl: course.primaryPlayableVideoUrl,
              playlistId: course.usesUploadedVideos ? '' : course.playlistId,
              width: 95,
              height: 100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          course.category,
                          style: const TextStyle(
                            color: Color(0xFFFF8A00),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (isCompleted)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Color(0xFF4CAF50),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 12,
                          color: Color(AppColors.primary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted
                              ? 'Course completed'
                              : '${(progress * 100).toStringAsFixed(0)}% watched',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (!isCompleted) ...[
                      const SizedBox(height: 6),
                      Text(
                        resumeLessonTitle == null
                            ? 'Ready to continue'
                            : 'Resume: $resumeLessonTitle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: secondaryText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (isCompleted)
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'VIEW CERTIFICATE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A8C7F),
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(3),
                            backgroundColor: const Color(AppColors.line),
                            color: const Color(0xFFF5A623),
                          ),
                          const SizedBox(height: 3),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: secondaryText,
                              ),
                            ),
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
    );
  }
}
