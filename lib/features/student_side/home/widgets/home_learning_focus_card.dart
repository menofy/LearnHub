import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/course.dart';

class HomeLearningFocusCard extends StatelessWidget {
  const HomeLearningFocusCard({
    super.key,
    required this.course,
    required this.progress,
    required this.onTap,
    this.resumeLessonTitle,
  });

  final Course course;
  final double progress;
  final String? resumeLessonTitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.72);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? colorScheme.outline.withValues(alpha: 0.85)
                  : const Color(AppColors.line),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              EduCourseThumb(
                imageUrl: course.preferredPreviewImageUrl,
                videoUrl: course.primaryPlayableVideoUrl,
                playlistId: course.usesUploadedVideos ? '' : course.playlistId,
                width: 96,
                height: 104,
                borderRadius: BorderRadius.circular(14),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.category,
                      style: const TextStyle(
                        color: Color(0xFFFF8A00),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      resumeLessonTitle == null ||
                              resumeLessonTitle!.trim().isEmpty
                          ? 'Ready to continue'
                          : 'Resume: $resumeLessonTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: isDark
                          ? colorScheme.outline.withValues(alpha: 0.45)
                          : const Color(AppColors.line),
                      color: const Color(AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% completed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
