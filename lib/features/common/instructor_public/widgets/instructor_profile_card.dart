import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/firestore_service.dart';
import '../../../../domain/entities/instructor.dart';
import 'instructor_stat_item.dart';

/// Profile Card - displays instructor info and statistics
class InstructorProfileCard extends StatelessWidget {
  const InstructorProfileCard({
    super.key,
    required this.instructor,
    required this.followersCount,
    required this.isLoadingFollowersCount,
    this.onShowFollowersList,
  });

  final Instructor instructor;
  final int followersCount;
  final bool isLoadingFollowersCount;
  final VoidCallback? onShowFollowersList;

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
    final subtitleColor = colorScheme.onSurface.withValues(alpha: 0.62);
    final subtitle = instructor.title.trim().isEmpty
        ? 'Course Instructor'
        : instructor.title;

    return StreamBuilder<int>(
      stream: _coursesCountStream(),
      builder: (context, snapshot) {
        final coursesCount = snapshot.data ?? 0;

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.05),
                blurRadius: isDark ? 18 : 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              InstructorAvatar(
                imageUrl: instructor.avatarUrl,
                instructorName: instructor.name,
                size: 92,
              ),
              const SizedBox(height: 12),
              Text(
                instructor.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: subtitleColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InstructorStatItem(
                      value: coursesCount.toString(),
                      label: 'Courses',
                    ),
                  ),
                  Expanded(
                    child: InstructorStatItem(
                      value: isLoadingFollowersCount
                          ? '...'
                          : followersCount.toString(),
                      label: 'Followers',
                      onTap: onShowFollowersList,
                    ),
                  ),
                  Expanded(
                    child: InstructorStatItem(
                      value: instructor.rating.toStringAsFixed(1),
                      label: 'Rating',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<int> _coursesCountStream() {
    return FirestoreService.instance
        .streamInstructorCourses(instructor.id)
        .map((courses) => courses.length);
  }
}
