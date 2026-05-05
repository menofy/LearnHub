import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/course.dart';
import 'my_courses_library_meta_pill.dart';

class MyCourseManagementCard extends StatelessWidget {
  const MyCourseManagementCard({
    super.key,
    required this.course,
    required this.enrollmentCount,
    required this.onEdit,
    required this.onDelete,
  });

  final Course course;
  final int enrollmentCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final titleColor = instructorTitleColor(context);
    final secondaryText = instructorMutedColor(context);
    return InstructorSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InstructorPill(label: course.category, icon: Icons.sell_outlined),
              const SizedBox(width: 8),
              InstructorPill(
                label: instructorCourseSourceLabel(course),
                icon: Icons.smart_display_outlined,
                backgroundColor: const Color(0xFFEFF2FF),
                foregroundColor: const Color(0xFF4153F4),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Color(AppColors.primary),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(AppColors.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            course.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.description.trim().isEmpty
                ? 'No description was added for this course yet.'
                : course.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              fontWeight: FontWeight.w700,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MyCourseLibraryMetaPill(
                  icon: Icons.calendar_month_outlined,
                  label: instructorFormatDate(course.createdAt),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MyCourseLibraryMetaPill(
                  icon: course.isPublished
                      ? Icons.public_rounded
                      : Icons.edit_note_rounded,
                  label: course.isPublished ? 'Published' : 'Draft',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MyCourseLibraryMetaPill(
                  icon: Icons.groups_2_outlined,
                  label: '$enrollmentCount students',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MyCourseLibraryMetaPill(
                  icon: Icons.school_outlined,
                  label: course.level,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
