import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

class AddCourseHeroBanner extends StatelessWidget {
  const AddCourseHeroBanner({
    super.key,
    required this.isEditing,
    required this.isPublished,
  });

  final bool isEditing;
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F3459), Color(0xFF1ACCBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17345D).withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InstructorPill(
            label: isPublished ? 'Ready for students' : 'Draft mode',
            icon: isPublished
                ? Icons.rocket_launch_outlined
                : Icons.edit_note_rounded,
            backgroundColor: const Color(0x1FFFFFFF),
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            isEditing
                ? 'Tighten the course your students already know.'
                : 'Build a course students can trust from the first glance.',
            style: const TextStyle(
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use metadata, level, outcomes, and pricing so discovery, recommendations, and curriculum screens feel complete.',
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
