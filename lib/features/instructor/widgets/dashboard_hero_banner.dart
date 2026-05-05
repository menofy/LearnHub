import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

import '../../../../core/theme/app_colors.dart';

class DashboardHeroBanner extends StatelessWidget {
  const DashboardHeroBanner({
    super.key,
    required this.userName,
    required this.courseCount,
    required this.latestPublishedLabel,
    required this.onCreateCourse,
    required this.onOpenCourses,
  });

  final String userName;
  final int courseCount;
  final String latestPublishedLabel;
  final VoidCallback onCreateCourse;
  final VoidCallback onOpenCourses;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
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
          Row(
            children: [
              const InstructorPill(
                label: 'Premium teaching hub',
                icon: Icons.workspace_premium_rounded,
                backgroundColor: Color(0x1FFFFFFF),
                foregroundColor: Colors.white,
              ),
              const Spacer(),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Welcome back, $userName',
            style: const TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$courseCount course${courseCount == 1 ? '' : 's'} published. $latestPublishedLabel',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE7FFFC),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroActionButton(
                  label: 'Create Course',
                  filled: true,
                  onTap: onCreateCourse,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroActionButton(
                  label: 'Manage Library',
                  filled: false,
                  onTap: onOpenCourses,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: filled ? Colors.white : Colors.white.withValues(alpha: 0.24),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: filled ? const Color(AppColors.dark) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
