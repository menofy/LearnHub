import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';

class CourseInstructorCard extends StatelessWidget {
  const CourseInstructorCard({
    super.key,
    required this.instructorName,
    required this.category,
    required this.instructorAvatarUrl,
  });

  final String instructorName;
  final String category;
  final String instructorAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.72);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              EduAvatar(imageUrl: instructorAvatarUrl, size: 46),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.message_outlined, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
