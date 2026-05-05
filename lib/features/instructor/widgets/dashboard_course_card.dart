import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/course.dart';

class DashboardCourseCard extends StatelessWidget {
  const DashboardCourseCard({
    super.key,
    required this.course,
    required this.enrollmentCount,
    required this.onManage,
  });

  final Course course;
  final int enrollmentCount;
  final VoidCallback onManage;

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
                label: course.isPublished ? 'Published' : 'Draft',
                icon: course.isPublished
                    ? Icons.public_rounded
                    : Icons.edit_note_rounded,
                backgroundColor: course.isPublished
                    ? const Color(0xFFEAF8F7)
                    : const Color(0xFFFFF4E8),
                foregroundColor: course.isPublished
                    ? const Color(AppColors.primary)
                    : const Color(0xFFEF8F00),
              ),
              const Spacer(),
              Text(
                instructorFormatDate(course.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                ? 'A streamlined course entry ready for students to open and start learning.'
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: instructorInsetColor(context),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    '$enrollmentCount learners • ${course.level}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: onManage,
                child: const Text(
                  'Manage',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
