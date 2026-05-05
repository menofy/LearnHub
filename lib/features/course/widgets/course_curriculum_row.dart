import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/lesson.dart';

class CourseCurriculumRow extends StatelessWidget {
  const CourseCurriculumRow({
    super.key,
    required this.index,
    required this.lesson,
    required this.onTap,
    required this.locked,
    required this.completed,
  });

  final int index;
  final Lesson lesson;
  final VoidCallback onTap;
  final bool locked;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF15243A) : const Color(AppColors.bg),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isDark ? colorScheme.surface : Colors.white,
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      lesson.duration,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : locked
                        ? Icons.lock_outline_rounded
                        : Icons.play_circle_fill_rounded,
                color: completed
                    ? const Color(0xFF1FA56D)
                    : locked
                        ? const Color(AppColors.muted)
                        : const Color(AppColors.primary),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
