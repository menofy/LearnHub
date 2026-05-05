import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/section_header.dart';
import 'package:learnhub/features/course/widgets/course_card.dart';

import '../../../../domain/entities/course.dart';

class HomeCourseStripSection extends StatelessWidget {
  const HomeCourseStripSection({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    required this.courses,
    required this.secondaryTextColor,
    required this.emptyMessage,
    required this.isBookmarked,
    required this.onBookmarkTap,
    required this.onCourseTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;
  final List<Course> courses;
  final Color secondaryTextColor;
  final String emptyMessage;
  final bool Function(String courseId) isBookmarked;
  final ValueChanged<String> onBookmarkTap;
  final ValueChanged<Course> onCourseTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: title,
          actionLabel: actionLabel,
          onActionTap: onActionTap,
        ),
        const SizedBox(height: 8),
        if (courses.isEmpty)
          SizedBox(
            height: 240,
            child: Center(
              child: Text(
                emptyMessage,
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final course = courses[index];
                return CourseCard(
                  course: course,
                  isBookmarked: isBookmarked(course.id),
                  onBookmarkTap: () => onBookmarkTap(course.id),
                  onTap: () => onCourseTap(course),
                );
              },
            ),
          ),
      ],
    );
  }
}
