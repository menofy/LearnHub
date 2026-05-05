import 'package:flutter/material.dart';

import 'course_get_row.dart';

class CourseWhatYouGetSection extends StatelessWidget {
  const CourseWhatYouGetSection({
    super.key,
    required this.classCountLabel,
    required this.durationText,
    required this.level,
    required this.category,
    required this.coursePathText,
    required this.accessText,
    required this.isEnrolled,
    required this.isFree,
  });

  final String classCountLabel;
  final String durationText;
  final String level;
  final String category;
  final String coursePathText;
  final String accessText;
  final bool isEnrolled;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What You\'ll Get',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          CourseGetRow(icon: Icons.menu_book_outlined, text: classCountLabel),
          CourseGetRow(icon: Icons.schedule_rounded, text: durationText),
          CourseGetRow(
            icon: Icons.bar_chart_rounded,
            text: '$level Level',
          ),
          CourseGetRow(
            icon: Icons.category_outlined,
            text: '$category Track',
          ),
          CourseGetRow(
            icon: Icons.video_library_outlined,
            text: coursePathText,
          ),
          CourseGetRow(
            icon: Icons.sync_rounded,
            text: isEnrolled
                ? 'Progress Sync Enabled'
                : 'Enroll to sync your progress',
          ),
          CourseGetRow(
            icon: isFree
                ? Icons.lock_open_rounded
                : Icons.workspace_premium_outlined,
            text: accessText,
          ),
        ],
      ),
    );
  }
}
