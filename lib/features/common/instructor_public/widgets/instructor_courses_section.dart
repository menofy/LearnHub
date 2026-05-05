import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';
import 'package:learnhub/core/shared_widgets/empty_state.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/route_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/firestore_service.dart';
import '../../../../domain/entities/course.dart';

/// Courses Section
class InstructorCoursesSection extends StatelessWidget {
  const InstructorCoursesSection({super.key, required this.instructorId});

  final String instructorId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? colorScheme.surface : Colors.white;
    final borderColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.55)
        : const Color(AppColors.line);
    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurface.withValues(alpha: 0.64);
    final iconColor = colorScheme.onSurface.withValues(alpha: 0.7);

    return StreamBuilder<List<Course>>(
      stream: FirestoreService.instance.streamInstructorCourses(instructorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: ContentLoadingSkeleton(
              showHeader: false,
              itemCount: 2,
              tileHeight: 84,
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final courses = snapshot.data ?? [];

        if (courses.isEmpty) {
          return const SizedBox(
            height: 200,
            child: EmptyState(
              icon: Icons.auto_stories_outlined,
              title: 'No courses yet',
              subtitle:
                  'This instructor has not published any visible courses yet.',
            ),
          );
        }

        return Column(
          children: courses
              .map(
                (course) => InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.courseDetails,
                      arguments: CourseDetailsArgs(course: course),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.16 : 0.05,
                          ),
                          blurRadius: isDark ? 18 : 8,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: EduCourseThumb(
                            imageUrl: course.preferredPreviewImageUrl,
                            videoUrl: course.primaryPlayableVideoUrl,
                            playlistId: course.usesUploadedVideos
                                ? ''
                                : course.playlistId,
                            width: 60,
                            height: 60,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                course.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: iconColor,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
